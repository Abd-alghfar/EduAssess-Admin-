import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/teacher_provider.dart';
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
  late TextEditingController _durationController;
  bool _isLoading = false;
  bool _isTimerEnabled = false;
  bool _shuffleQuestions = true;
  bool _isPublished = false;
  DateTime? _scheduledAt;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.lesson?.title ?? '');
    _isTimerEnabled = widget.lesson?.durationMinutes != null;
    _shuffleQuestions = widget.lesson?.shuffleQuestions ?? true;
    _isPublished = widget.lesson?.isPublished ?? false;
    _scheduledAt = widget.lesson?.scheduledAt;
    _durationController = TextEditingController(
      text: widget.lesson?.durationMinutes?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledAt ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt ?? DateTime.now()),
    );
    if (time == null || !mounted) return;

    setState(() {
      _scheduledAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
          const Divider(height: 32),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.calendar_today, color: scheme.primary),
            title: const Text('Schedule Start (Optional)'),
            subtitle: Text(
              _scheduledAt == null
                  ? 'Click to set date and time'
                  : '${_scheduledAt!.day}/${_scheduledAt!.month}/${_scheduledAt!.year} at ${_scheduledAt!.hour}:${_scheduledAt!.minute.toString().padLeft(2, '0')}',
            ),
            trailing: _scheduledAt != null
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () => setState(() => _scheduledAt = null),
                  )
                : null,
            onTap: _pickDateTime,
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Shuffle Questions'),
            subtitle: const Text(
              'Randomize the order of questions for students',
            ),
            value: _shuffleQuestions,
            onChanged: (val) => setState(() => _shuffleQuestions = val),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Publish Exam'),
            subtitle: const Text('Make this exam visible to students'),
            value: _isPublished,
            onChanged: (val) => setState(() => _isPublished = val),
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
        final created = await context.read<TeacherProvider>().addLesson(
          _titleController.text,
          duration,
          shuffleQuestions: _shuffleQuestions,
          isPublished: _isPublished,
          scheduledAt: _scheduledAt,
        );
        if (mounted) Navigator.pop(context, created);
      } else {
        await context.read<TeacherProvider>().updateLesson(
          widget.lesson!.id,
          _titleController.text,
          duration,
          shuffleQuestions: _shuffleQuestions,
          isPublished: _isPublished,
          scheduledAt: _scheduledAt,
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
