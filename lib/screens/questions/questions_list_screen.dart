import 'package:flutter/material.dart';
import '../../models/lesson_model.dart';
import '../../models/question_model.dart';
import '../../services/supabase_service.dart';
import 'question_editor_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../widgets/shimmer_loader.dart';
import '../../services/question_import_service.dart';
import '../../models/question_bank_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuestionsListScreen extends StatefulWidget {
  final Lesson lesson;
  const QuestionsListScreen({super.key, required this.lesson});

  @override
  State<QuestionsListScreen> createState() => _QuestionsListScreenState();
}

class _QuestionsListScreenState extends State<QuestionsListScreen> {
  final SupabaseService _service = SupabaseService();
  List<Question> _questions = [];
  bool _isLoading = true;
  bool _selectionMode = false;
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() => _isLoading = true);
    try {
      _questions = await _service.getQuestions(widget.lesson.id);
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom + 96;
    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz Questions: ${widget.lesson.title}'),
        actions: [
          IconButton.outlined(
            onPressed: _bulkImport,
            icon: const Icon(Icons.upload_file_rounded),
            tooltip: 'Bulk Import from Excel',
          ),
          const SizedBox(width: 8),
          IconButton.outlined(
            onPressed: _openQuestionBank,
            icon: const Icon(Icons.collections_bookmark_rounded),
            tooltip: 'Question Bank',
          ),
          const SizedBox(width: 8),
          IconButton.outlined(
            onPressed: _questions.isEmpty
                ? null
                : () => setState(() {
                      _selectionMode = !_selectionMode;
                      _selectedIds.clear();
                    }),
            icon: Icon(_selectionMode ? Icons.close_rounded : Icons.checklist),
            tooltip: _selectionMode ? 'Exit Selection' : 'Select Multiple',
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        QuestionEditorScreen(lessonId: widget.lesson.id),
                  ),
                );
                if (result == true) _loadQuestions();
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Question'),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const ListShimmer()
          : RefreshIndicator(
              onRefresh: _loadQuestions,
              child: _questions.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.6,
                          child: _buildEmptyState(),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        if (_selectionMode)
                          _buildSelectionBar(context),
                        Expanded(
                          child: ListView.builder(
                            padding: EdgeInsets.fromLTRB(
                              16,
                              16,
                              16,
                              bottomInset,
                            ),
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: _questions.length,
                            itemBuilder: (context, index) {
                              final q = _questions[index];
                              final selected = _selectedIds.contains(q.id);
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  leading: _selectionMode
                                      ? Checkbox(
                                          value: selected,
                                          onChanged: (val) {
                                            setState(() {
                                              if (val == true) {
                                                _selectedIds.add(q.id);
                                              } else {
                                                _selectedIds.remove(q.id);
                                              }
                                            });
                                          },
                                        )
                                      : null,
                                  title: Text(
                                    q.questionText,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primaryContainer,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          _getQuestionTypeLabel(q.questionType),
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${q.points} Points',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (!_selectionMode)
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined),
                                          onPressed: () async {
                                            final result = await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    QuestionEditorScreen(
                                                      lessonId: widget.lesson.id,
                                                      question: q,
                                                    ),
                                              ),
                                            );
                                            if (result == true) _loadQuestions();
                                          },
                                        ),
                                      if (!_selectionMode)
                                        IconButton(
                                          icon: const Icon(
                                            Icons.bookmark_add_outlined,
                                          ),
                                          tooltip: 'Save to bank',
                                          onPressed: () async {
                                            final meta =
                                                await _promptBankMeta(context);
                                            await _saveToBank(
                                              q,
                                              difficulty: meta['difficulty'],
                                              unit: meta['unit'],
                                              topic: meta['topic'],
                                            );
                                          },
                                        ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.red,
                                        ),
                                        onPressed: () => _deleteQuestion(q.id),
                                      ),
                                    ],
                                  ),
                                  onTap: _selectionMode
                                      ? () {
                                          setState(() {
                                            if (selected) {
                                              _selectedIds.remove(q.id);
                                            } else {
                                              _selectedIds.add(q.id);
                                            }
                                          });
                                        }
                                      : null,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
            ),
    );
  }

  Future<void> _deleteQuestion(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Question?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _service.deleteQuestion(id);
      _loadQuestions();
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FontAwesomeIcons.circleQuestion,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          const Text('No questions in this quiz yet'),
        ],
      ),
    );
  }

  Future<void> _bulkImport() async {
    try {
      final questions = await QuestionImportService.importFromExcel(
        widget.lesson.id,
      );
      if (questions.isEmpty) return;

      setState(() => _isLoading = true);
      await _service.bulkCreateQuestions(questions);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully imported ${questions.length} questions!',
            ),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
      _loadQuestions();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing questions: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<String?> _getTeacherId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('teacher_id');
  }

  Future<void> _saveToBank(
    Question q, {
    String? difficulty,
    String? unit,
    String? topic,
  }) async {
    final teacherId = await _getTeacherId();
    if (teacherId == null) return;
    try {
      await _service.addQuestionToBank(
        QuestionBankItem(
          id: '',
          teacherId: teacherId,
          questionText: q.questionText,
          questionType: q.questionType,
          config: q.config,
          points: q.points,
          difficulty: difficulty,
          unit: unit,
          topic: topic,
          createdAt: DateTime.now(),
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Saved to question bank'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  Future<Map<String, String?>> _promptBankMeta(BuildContext context) async {
    final unitController = TextEditingController();
    final topicController = TextEditingController();
    String? selectedDifficulty;

    final result = await showDialog<Map<String, String?>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Bank Metadata'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedDifficulty,
                decoration: const InputDecoration(labelText: 'Difficulty'),
                items: const [
                  DropdownMenuItem(value: 'easy', child: Text('Easy')),
                  DropdownMenuItem(value: 'medium', child: Text('Medium')),
                  DropdownMenuItem(value: 'hard', child: Text('Hard')),
                ],
                onChanged: (val) => setState(() => selectedDifficulty = val),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: unitController,
                decoration: const InputDecoration(labelText: 'Unit'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: topicController,
                decoration: const InputDecoration(labelText: 'Topic'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Skip'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, {
                'difficulty': selectedDifficulty,
                'unit': unitController.text.trim().isEmpty
                    ? null
                    : unitController.text.trim(),
                'topic': topicController.text.trim().isEmpty
                    ? null
                    : topicController.text.trim(),
              }),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    return result ?? {'difficulty': null, 'unit': null, 'topic': null};
  }

  Widget _buildSelectionBar(BuildContext context) {
    final selectedCount = _selectedIds.length;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              selectedCount == 0
                  ? 'Select questions to save'
                  : '$selectedCount selected',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          TextButton.icon(
            onPressed: _questions.isEmpty ? null : _saveAllToBank,
            icon: const Icon(Icons.library_add_rounded),
            label: const Text('Save All'),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: selectedCount == 0 ? null : _saveSelectedToBank,
            icon: const Icon(Icons.bookmark_add_outlined),
            label: const Text('Save Selected'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAllToBank() async {
    final meta = await _promptBankMeta(context);
    for (final q in _questions) {
      await _saveToBank(
        q,
        difficulty: meta['difficulty'],
        unit: meta['unit'],
        topic: meta['topic'],
      );
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Saved all questions to bank'),
          backgroundColor: Colors.green.shade700,
        ),
      );
    }
  }

  Future<void> _saveSelectedToBank() async {
    final meta = await _promptBankMeta(context);
    final selected = _questions.where((q) => _selectedIds.contains(q.id));
    for (final q in selected) {
      await _saveToBank(
        q,
        difficulty: meta['difficulty'],
        unit: meta['unit'],
        topic: meta['topic'],
      );
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Saved selected questions to bank'),
          backgroundColor: Colors.green.shade700,
        ),
      );
    }
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  Future<void> _openQuestionBank() async {
    final teacherId = await _getTeacherId();
    if (teacherId == null || !mounted) return;

    showDialog(
      context: context,
      builder: (context) => _QuestionBankDialog(
        teacherId: teacherId,
        lessonId: widget.lesson.id,
        service: _service,
        onImported: _loadQuestions,
      ),
    );
  }

  String _getQuestionTypeLabel(QuestionType type) {
    switch (type) {
      case QuestionType.mcq:
        return 'MULTIPLE CHOICE';
      case QuestionType.true_false:
        return 'TRUE / FALSE';
      case QuestionType.essay:
        return 'ESSAY';
      case QuestionType.multi_select:
        return 'MULTI-SELECT';
      case QuestionType.matching:
      case QuestionType.ordering:
        return 'UNSUPPORTED';
    }
  }
}

class _QuestionBankDialog extends StatefulWidget {
  final String teacherId;
  final String lessonId;
  final SupabaseService service;
  final VoidCallback onImported;

  const _QuestionBankDialog({
    required this.teacherId,
    required this.lessonId,
    required this.service,
    required this.onImported,
  });

  @override
  State<_QuestionBankDialog> createState() => _QuestionBankDialogState();
}

class _QuestionBankDialogState extends State<_QuestionBankDialog> {
  List<QuestionBankItem> _items = [];
  bool _loading = true;
  final TextEditingController _searchController = TextEditingController();
  String? _difficultyFilter;
  String? _unitFilter;
  String? _topicFilter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _items = await widget.service.getQuestionBank(widget.teacherId);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addToLesson(QuestionBankItem item) async {
    await widget.service.createQuestion(
      Question(
        id: '',
        lessonId: widget.lessonId,
        questionText: item.questionText,
        questionType: item.questionType,
        config: item.config,
        points: item.points,
        createdAt: DateTime.now(),
      ),
    );
    widget.onImported();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Question added to this quiz'),
          backgroundColor: Colors.green.shade700,
        ),
      );
    }
  }

  Future<void> _removeFromBank(String id) async {
    await widget.service.deleteQuestionFromBank(id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _applyFilters(_items);
    final units = _collectDistinct(_items, (e) => e.unit);
    final topics = _collectDistinct(_items, (e) => e.topic);
    return AlertDialog(
      title: const Text('Question Bank'),
      content: SizedBox(
        width: 560,
        height: 520,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            hintText: 'Search questions, unit, topic...',
                            prefixIcon: Icon(Icons.search),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 150,
                        child: DropdownButtonFormField<String?>(
                          value: _difficultyFilter,
                          decoration:
                              const InputDecoration(labelText: 'Difficulty'),
                          items: const [
                            DropdownMenuItem<String?>(
                              value: null,
                              child: Text('All'),
                            ),
                            DropdownMenuItem<String?>(
                              value: 'easy',
                              child: Text('Easy'),
                            ),
                            DropdownMenuItem(
                              value: 'medium',
                              child: Text('Medium'),
                            ),
                            DropdownMenuItem<String?>(
                              value: 'hard',
                              child: Text('Hard'),
                            ),
                          ],
                          onChanged: (val) => setState(() {
                            _difficultyFilter = val;
                          }),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String?>(
                          value: _unitFilter,
                          decoration: const InputDecoration(labelText: 'Unit'),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('All'),
                            ),
                            ...units.map(
                              (u) => DropdownMenuItem<String?>(
                                value: u,
                                child: Text(u),
                              ),
                            ),
                          ],
                          onChanged: (val) => setState(() {
                            _unitFilter = val;
                          }),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String?>(
                          value: _topicFilter,
                          decoration: const InputDecoration(labelText: 'Topic'),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('All'),
                            ),
                            ...topics.map(
                              (t) => DropdownMenuItem<String?>(
                                value: t,
                                child: Text(t),
                              ),
                            ),
                          ],
                          onChanged: (val) => setState(() {
                            _topicFilter = val;
                          }),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(child: Text('No results'))
                        : ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final item = filtered[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  title: Text(
                                    item.questionText,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    '${_getTypeLabel(item.questionType)} • ${item.points} pts'
                                    '${item.unit != null ? ' • ${item.unit}' : ''}'
                                    '${item.topic != null ? ' • ${item.topic}' : ''}'
                                    '${item.difficulty != null ? ' • ${item.difficulty}' : ''}',
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.add_circle_outline,
                                        ),
                                        tooltip: 'Add to this quiz',
                                        onPressed: () => _addToLesson(item),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.redAccent,
                                        ),
                                        tooltip: 'Remove from bank',
                                        onPressed: () => _removeFromBank(
                                          item.id,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
      actions: [
        TextButton.icon(
          onPressed: _importToBank,
          icon: const Icon(Icons.upload_file_rounded),
          label: const Text('Import to Bank'),
        ),
        TextButton.icon(
          onPressed: filtered.isEmpty
              ? null
              : () => _addFilteredToLesson(filtered),
          icon: const Icon(Icons.playlist_add),
          label: const Text('Add Filtered'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  List<QuestionBankItem> _applyFilters(List<QuestionBankItem> items) {
    final q = _searchController.text.trim().toLowerCase();
    return items.where((item) {
      if (_difficultyFilter != null &&
          _difficultyFilter != item.difficulty) {
        return false;
      }
      if (_unitFilter != null && _unitFilter != item.unit) {
        return false;
      }
      if (_topicFilter != null && _topicFilter != item.topic) {
        return false;
      }
      if (q.isEmpty) return true;
      final text = [
        item.questionText,
        item.unit ?? '',
        item.topic ?? '',
      ].join(' ').toLowerCase();
      return text.contains(q);
    }).toList();
  }

  Future<void> _addFilteredToLesson(List<QuestionBankItem> items) async {
    for (final item in items) {
      await _addToLesson(item);
    }
  }

  List<String> _collectDistinct(
    List<QuestionBankItem> items,
    String? Function(QuestionBankItem) pick,
  ) {
    final set = <String>{};
    for (final item in items) {
      final v = pick(item);
      if (v != null && v.trim().isNotEmpty) {
        set.add(v.trim());
      }
    }
    final list = set.toList();
    list.sort();
    return list;
  }

  Future<Map<String, String?>> _promptBankMeta(BuildContext context) async {
    final unitController = TextEditingController();
    final topicController = TextEditingController();
    String? selectedDifficulty;

    final result = await showDialog<Map<String, String?>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Bank Metadata'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedDifficulty,
                decoration: const InputDecoration(labelText: 'Difficulty'),
                items: const [
                  DropdownMenuItem(value: 'easy', child: Text('Easy')),
                  DropdownMenuItem(value: 'medium', child: Text('Medium')),
                  DropdownMenuItem(value: 'hard', child: Text('Hard')),
                ],
                onChanged: (val) => setState(() => selectedDifficulty = val),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: unitController,
                decoration: const InputDecoration(labelText: 'Unit'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: topicController,
                decoration: const InputDecoration(labelText: 'Topic'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Skip'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, {
                'difficulty': selectedDifficulty,
                'unit': unitController.text.trim().isEmpty
                    ? null
                    : unitController.text.trim(),
                'topic': topicController.text.trim().isEmpty
                    ? null
                    : topicController.text.trim(),
              }),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    return result ?? {'difficulty': null, 'unit': null, 'topic': null};
  }

  Future<void> _importToBank() async {
    try {
      final meta = await _promptBankMeta(context);
      final questions = await QuestionImportService.importFromExcel(
        widget.lessonId,
      );
      if (questions.isEmpty) return;

      for (final q in questions) {
        await widget.service.addQuestionToBank(
          QuestionBankItem(
            id: '',
            teacherId: widget.teacherId,
            questionText: q.questionText,
            questionType: q.questionType,
            config: q.config,
            points: q.points,
            difficulty: meta['difficulty'],
            unit: meta['unit'],
            topic: meta['topic'],
            createdAt: DateTime.now(),
          ),
        );
      }

      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imported ${questions.length} questions to bank'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  String _getTypeLabel(QuestionType type) {
    switch (type) {
      case QuestionType.mcq:
        return 'MCQ';
      case QuestionType.true_false:
        return 'True/False';
      case QuestionType.essay:
        return 'Essay';
      case QuestionType.multi_select:
        return 'Multi-Select';
      case QuestionType.matching:
      case QuestionType.ordering:
        return 'Unsupported';
    }
  }
}
