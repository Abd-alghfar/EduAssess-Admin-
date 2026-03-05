import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../models/lesson_model.dart';
import '../../core/error/failure.dart';

class AddLessonDialog extends StatefulWidget {
  final Lesson? lesson;
  final bool fullScreen;
  const AddLessonDialog({super.key, this.lesson, this.fullScreen = false});

  @override
  State<AddLessonDialog> createState() => _AddLessonDialogState();
}

class _AddLessonDialogState extends State<AddLessonDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _durationController;
  bool _isLoading = false;
  bool _isTimerEnabled = false;
  bool _showCorrection = true;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.lesson?.title ?? '');
    _descController = TextEditingController(
      text: widget.lesson?.description ?? '',
    );
    _isTimerEnabled = widget.lesson?.durationMinutes != null;
    _showCorrection = widget.lesson?.showCorrection ?? true;
    _durationController = TextEditingController(
      text: widget.lesson?.durationMinutes?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.lesson == null ? 'Create New Quiz' : 'Edit Quiz';
    final actions = [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _isLoading ? null : _submit,
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(widget.lesson == null ? 'Create Quiz' : 'Save Changes'),
      ),
    ];

    final form = Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Quiz Title',
              border: OutlineInputBorder(),
            ),
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descController,
            decoration: const InputDecoration(
              labelText: 'Overview',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Enable Timer'),
            value: _isTimerEnabled,
            onChanged: (val) {
              setState(() {
                _isTimerEnabled = val;
                if (!val) _durationController.clear();
              });
            },
          ),
          if (_isTimerEnabled) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _durationController,
              decoration: const InputDecoration(
                labelText: 'Duration (minutes)',
                border: OutlineInputBorder(),
                suffixText: 'min',
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (_isTimerEnabled && (v == null || v.isEmpty)) {
                  return 'Required';
                }
                if (v != null && v.isNotEmpty && int.tryParse(v) == null) {
                  return 'Invalid number';
                }
                return null;
              },
            ),
          ],
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Show answers to students'),
            subtitle: const Text(
              'If enabled, students will see the correct answers after finishing',
            ),
            value: _showCorrection,
            onChanged: (val) {
              setState(() {
                _showCorrection = val;
              });
            },
          ),
        ],
      ),
    );

    if (widget.fullScreen) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: form,
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          minimum: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(child: actions[0]),
              const SizedBox(width: 12),
              Expanded(child: actions[1]),
            ],
          ),
        ),
      );
    }

    return AlertDialog(
      title: Text(title),
      content: SizedBox(width: 520, child: SingleChildScrollView(child: form)),
      actions: actions,
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final duration = _isTimerEnabled
          ? int.tryParse(_durationController.text)
          : null;

      if (widget.lesson == null) {
        final created = await context.read<AdminProvider>().addLesson(
          _titleController.text,
          _descController.text,
          duration,
          _showCorrection,
        );
        if (mounted) Navigator.pop(context, created);
      } else {
        await context.read<AdminProvider>().updateLesson(
          widget.lesson!.id,
          _titleController.text,
          _descController.text,
          duration,
          _showCorrection,
        );
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(Failure.getFriendlyMessage(e)),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
