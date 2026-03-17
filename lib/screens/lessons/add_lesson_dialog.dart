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
  DateTime? _expiresAt;

  String _formatDateTime(DateTime? value) {
    if (value == null) return 'Not set';
    final d = value;
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '${d.day}/${d.month}/${d.year} at $h:$m';
  }

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.lesson?.title ?? '');
    _isTimerEnabled = widget.lesson?.durationMinutes != null;
    _shuffleQuestions = widget.lesson?.shuffleQuestions ?? true;
    _isPublished = widget.lesson?.isPublished ?? false;
    _scheduledAt = widget.lesson?.scheduledAt;
    _expiresAt = widget.lesson?.expiresAt;
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

  Future<void> _pickExpiryDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _expiresAt ?? _scheduledAt ?? DateTime.now(),
      firstDate: _scheduledAt ?? DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        _expiresAt ?? _scheduledAt ?? DateTime.now(),
      ),
    );
    if (time == null || !mounted) return;

    setState(() {
      _expiresAt = DateTime(
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
    final assignment = context.read<TeacherProvider>().currentAssignment;
    final subjectName = assignment?['subjects']?['name'];
    final className = assignment?['classes']?['name'];
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
          if (subjectName != null || className != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Row(
                children: [
                  Icon(Icons.school_rounded, color: scheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${subjectName ?? 'Subject'} • ${className ?? 'Class'}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Quiz Title',
              hintText: 'e.g. Algebra Basics - Unit 3',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
            validator: (v) {
              final value = v?.trim() ?? '';
              if (value.isEmpty) return 'Required';
              if (value.length < 3) return 'Title is too short';
              return null;
            },
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Enable Timer'),
            subtitle: const Text('Limit the exam duration in minutes'),
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
              onChanged: (_) => setState(() {}),
              validator: (v) {
                if (_isTimerEnabled && (v == null || v.isEmpty)) {
                  return 'Required';
                }
                final parsed = int.tryParse(v ?? '');
                if (v != null && v.isNotEmpty && parsed == null) {
                  return 'Invalid number';
                }
                if (parsed != null && (parsed < 1 || parsed > 300)) {
                  return 'Duration must be between 1 and 300';
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
                  : _formatDateTime(_scheduledAt),
            ),
            trailing: _scheduledAt != null
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () => setState(() => _scheduledAt = null),
                  )
                : null,
            onTap: _pickDateTime,
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.timer_off_outlined,
              color: Colors.orange.shade700,
            ),
            title: const Text('Hide After (Deadline)'),
            subtitle: Text(
              _expiresAt == null
                  ? 'Optionally set an end time'
                  : _formatDateTime(_expiresAt),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_scheduledAt != null && _isTimerEnabled)
                  IconButton(
                    icon: const Icon(Icons.auto_fix_high, size: 20),
                    tooltip: 'Set automatically (Start + Duration)',
                    onPressed: () {
                      final duration =
                          int.tryParse(_durationController.text) ?? 0;
                      setState(() {
                        _expiresAt = _scheduledAt!.add(
                          Duration(minutes: duration),
                        );
                      });
                    },
                  ),
                if (_expiresAt != null)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () => setState(() => _expiresAt = null),
                  ),
              ],
            ),
            onTap: _pickExpiryDateTime,
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
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Summary',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  'Title: ${_titleController.text.trim().isEmpty ? 'Untitled' : _titleController.text.trim()}',
                ),
                Text(
                  'Timer: ${_isTimerEnabled ? '${_durationController.text.trim()} min' : 'Off'}',
                ),
                Text('Shuffle: ${_shuffleQuestions ? 'On' : 'Off'}'),
                Text('Publish: ${_isPublished ? 'Yes' : 'No'}'),
                Text('Start: ${_formatDateTime(_scheduledAt)}'),
                Text('Deadline: ${_formatDateTime(_expiresAt)}'),
              ],
            ),
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
      final assignment = context.read<TeacherProvider>().currentAssignment;
      if (assignment == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No class/subject assigned to this teacher.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      final duration = _isTimerEnabled
          ? int.tryParse(_durationController.text)
          : null;
      if (_scheduledAt != null &&
          _expiresAt != null &&
          _expiresAt!.isBefore(_scheduledAt!)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Deadline must be after the scheduled start.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      if (widget.lesson == null) {
        final created = await context.read<TeacherProvider>().addLesson(
          _titleController.text,
          duration,
          shuffleQuestions: _shuffleQuestions,
          isPublished: _isPublished,
          scheduledAt: _scheduledAt,
          expiresAt: _expiresAt,
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
          expiresAt: _expiresAt,
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
