import 'package:flutter/material.dart';
import '../../models/question_model.dart';
import '../../services/supabase_service.dart';

class QuestionEditorScreen extends StatefulWidget {
  final String lessonId;
  final Question? question;
  const QuestionEditorScreen({
    super.key,
    required this.lessonId,
    this.question,
  });

  @override
  State<QuestionEditorScreen> createState() => _QuestionEditorScreenState();
}

class _QuestionEditorScreenState extends State<QuestionEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = SupabaseService();

  late TextEditingController _textController;
  late QuestionType _type;
  late int _points;

  // MCQ state
  List<TextEditingController> _optionControllers = [];
  int? _mcqCorrectIndex;

  // Completion state
  late TextEditingController _snippetController;
  late TextEditingController _placeholderController;
  late TextEditingController _codeCorrectAnswerController;

  // Multi-select state
  List<int> _multiSelectCorrectIndexes = [];

  // Matching state
  List<TextEditingController> _matchingLeftControllers = [];
  List<TextEditingController> _matchingRightControllers = [];

  // Ordering state
  List<TextEditingController> _orderingControllers = [];

  // True/False state
  bool _tfCorrectAnswer = true;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(
      text: widget.question?.questionText ?? '',
    );
    _type = widget.question?.questionType ?? QuestionType.mcq;
    _points = widget.question?.points ?? 1;
    _snippetController = TextEditingController();
    _placeholderController = TextEditingController();
    _codeCorrectAnswerController = TextEditingController();

    // Initialize based on type
    if (widget.question != null) {
      final config = widget.question!.config;
      if (_type == QuestionType.mcq) {
        final options = List<String>.from(config['options'] ?? []);
        _optionControllers = options
            .map((e) => TextEditingController(text: e))
            .toList();
        final correct = config['correct_answer']?.toString();
        _mcqCorrectIndex =
            correct != null ? options.indexOf(correct) : null;
        if (_mcqCorrectIndex != null && _mcqCorrectIndex! < 0) {
          _mcqCorrectIndex = null;
        }
      } else if (_type == QuestionType.completion) {
        _snippetController.text = config['code_snippet'] ?? '';
        _placeholderController.text = config['placeholder'] ?? '';
        _codeCorrectAnswerController.text = config['correct_answer'] ?? '';
      } else if (_type == QuestionType.true_false) {
        _tfCorrectAnswer = config['correct_answer'] ?? true;
      } else if (_type == QuestionType.multi_select) {
        final options = List<String>.from(config['options'] ?? []);
        _optionControllers = options
            .map((e) => TextEditingController(text: e))
            .toList();
        final correctAnswers = List<String>.from(
          config['correct_answers'] ?? [],
        );
        _multiSelectCorrectIndexes = [];
        for (int i = 0; i < options.length; i++) {
          if (correctAnswers.contains(options[i])) {
            _multiSelectCorrectIndexes.add(i);
          }
        }
      } else if (_type == QuestionType.matching) {
        final left = List<String>.from(config['left_side'] ?? []);
        final right = List<String>.from(config['right_side'] ?? []);
        _matchingLeftControllers = left
            .map((e) => TextEditingController(text: e))
            .toList();
        _matchingRightControllers = right
            .map((e) => TextEditingController(text: e))
            .toList();
      } else if (_type == QuestionType.ordering) {
        final items = List<String>.from(config['items'] ?? []);
        _orderingControllers = items
            .map((e) => TextEditingController(text: e))
            .toList();
      }
    } else {
      // Defaults for new question
      _optionControllers = [TextEditingController(), TextEditingController()];
      _mcqCorrectIndex = 0;
      _matchingLeftControllers = [
        TextEditingController(),
        TextEditingController(),
      ];
      _matchingRightControllers = [
        TextEditingController(),
        TextEditingController(),
      ];
      _orderingControllers = [TextEditingController(), TextEditingController()];
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    for (var c in _optionControllers) {
      c.dispose();
    }
    _snippetController.dispose();
    _placeholderController.dispose();
    for (var c in _matchingLeftControllers) {
      c.dispose();
    }
    for (var c in _matchingRightControllers) {
      c.dispose();
    }
    for (var c in _orderingControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom + 96;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.question == null ? 'New Question' : 'Edit Question'),
        actions: [
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: FilledButton(
                onPressed: _save,
                child: const Text('Save Question'),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24, 24, 24, bottomInset),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTypeSelector(),
                    const SizedBox(height: 24),
                    _buildQuestionTextField(),
                    const SizedBox(height: 24),
                    _buildPointsField(),
                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 16),
                    Text(
                      'Question Configuration',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDynamicConfig(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTypeSelector() {
    return DropdownButtonFormField<QuestionType>(
      value: _type,
      decoration: const InputDecoration(
        labelText: 'Question Type',
        border: OutlineInputBorder(),
      ),
      items: QuestionType.values.map((t) {
        String label = t.toString().split('.').last.toUpperCase();
        if (t == QuestionType.completion) label = 'FILL IN BLANKS';
        if (t == QuestionType.mcq) label = 'MULTIPLE CHOICE';
        if (t == QuestionType.true_false) label = 'TRUE / FALSE';
        if (t == QuestionType.multi_select) label = 'MULTI-SELECT';
        if (t == QuestionType.matching) label = 'MATCHING';
        if (t == QuestionType.ordering) label = 'ORDERING';
        return DropdownMenuItem(value: t, child: Text(label));
      }).toList(),
      onChanged: (val) {
        if (val != null) setState(() => _type = val);
      },
    );
  }

  Widget _buildQuestionTextField() {
    return TextFormField(
      controller: _textController,
      maxLines: 3,
      decoration: const InputDecoration(
        labelText: 'Question Text',
        hintText: 'Enter the question text here...',
        border: OutlineInputBorder(),
        alignLabelWithHint: true,
      ),
      validator: (v) => v!.isEmpty ? 'Required' : null,
    );
  }

  Widget _buildPointsField() {
    return SizedBox(
      width: 150,
      child: TextFormField(
        initialValue: _points.toString(),
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: 'Points',
          border: OutlineInputBorder(),
        ),
        onChanged: (v) => _points = int.tryParse(v) ?? 1,
      ),
    );
  }

  Widget _buildDynamicConfig() {
    switch (_type) {
      case QuestionType.mcq:
        return _buildMCQConfig();
      case QuestionType.true_false:
        return _buildTFConfig();
      case QuestionType.completion:
        return _buildCodeConfig();
      case QuestionType.multi_select:
        return _buildMultiSelectConfig();
      case QuestionType.matching:
        return _buildMatchingConfig();
      case QuestionType.ordering:
        return _buildOrderingConfig();
    }
  }

  Widget _buildCodeConfig() {
    return Column(
      children: [
        TextFormField(
          controller: _codeCorrectAnswerController,
          decoration: const InputDecoration(
            labelText: 'Answer',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildMCQConfig() {
    return Column(
      children: [
        ...List.generate(_optionControllers.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Radio<int>(
                  value: index,
                  groupValue: _mcqCorrectIndex,
                  onChanged: (val) {
                    setState(() => _mcqCorrectIndex = val);
                  },
                ),
                Expanded(
                  child: TextFormField(
                    controller: _optionControllers[index],
                    decoration: InputDecoration(
                      labelText: 'Option ${index + 1}',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      _optionControllers.removeAt(index);
                      if (_mcqCorrectIndex == index) {
                        _mcqCorrectIndex = null;
                      } else if (_mcqCorrectIndex != null &&
                          _mcqCorrectIndex! > index) {
                        _mcqCorrectIndex = _mcqCorrectIndex! - 1;
                      }
                    });
                  },
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () {
            setState(() {
              _optionControllers.add(TextEditingController());
            });
          },
          icon: const Icon(Icons.add),
          label: const Text('Add Option'),
        ),
        if (_mcqCorrectIndex == null && _optionControllers.isNotEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Please select the correct answer',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildTFConfig() {
    return Column(
      children: [
        RadioListTile<bool>(
          title: const Text('True'),
          value: true,
          groupValue: _tfCorrectAnswer,
          onChanged: (v) => setState(() => _tfCorrectAnswer = v!),
        ),
        RadioListTile<bool>(
          title: const Text('False'),
          value: false,
          groupValue: _tfCorrectAnswer,
          onChanged: (v) => setState(() => _tfCorrectAnswer = v!),
        ),
      ],
    );
  }

  Widget _buildMultiSelectConfig() {
    return Column(
      children: [
        ...List.generate(_optionControllers.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Checkbox(
                  value: _multiSelectCorrectIndexes.contains(index),
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _multiSelectCorrectIndexes.add(index);
                      } else {
                        _multiSelectCorrectIndexes.remove(index);
                      }
                    });
                  },
                ),
                Expanded(
                  child: TextFormField(
                    controller: _optionControllers[index],
                    decoration: InputDecoration(
                      labelText: 'Option ${index + 1}',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      _optionControllers.removeAt(index);
                      _multiSelectCorrectIndexes = _multiSelectCorrectIndexes
                          .where((i) => i != index)
                          .map((i) => i > index ? i - 1 : i)
                          .toList();
                    });
                  },
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () {
            setState(() {
              _optionControllers.add(TextEditingController());
            });
          },
          icon: const Icon(Icons.add),
          label: const Text('Add Option'),
        ),
      ],
    );
  }

  Widget _buildMatchingConfig() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Pairs (Left side matches Right side)'),
        const SizedBox(height: 12),
        ...List.generate(_matchingLeftControllers.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _matchingLeftControllers[index],
                    decoration: const InputDecoration(
                      labelText: 'Left Side',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.link),
                ),
                Expanded(
                  child: TextFormField(
                    controller: _matchingRightControllers[index],
                    decoration: const InputDecoration(
                      labelText: 'Right Side',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      _matchingLeftControllers.removeAt(index);
                      _matchingRightControllers.removeAt(index);
                    });
                  },
                ),
              ],
            ),
          );
        }),
        OutlinedButton.icon(
          onPressed: () {
            setState(() {
              _matchingLeftControllers.add(TextEditingController());
              _matchingRightControllers.add(TextEditingController());
            });
          },
          icon: const Icon(Icons.add),
          label: const Text('Add Pair'),
        ),
      ],
    );
  }

  Widget _buildOrderingConfig() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Items in the Correct Order'),
        const SizedBox(height: 12),
        ...List.generate(_orderingControllers.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _orderingControllers[index],
                    decoration: InputDecoration(
                      labelText: 'Item ${index + 1}',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      _orderingControllers.removeAt(index);
                    });
                  },
                ),
              ],
            ),
          );
        }),
        OutlinedButton.icon(
          onPressed: () {
            setState(() {
              _orderingControllers.add(TextEditingController());
            });
          },
          icon: const Icon(Icons.add),
          label: const Text('Add Item'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Validation for MCQ
    if (_type == QuestionType.mcq) {
      final options = _optionControllers
          .map((e) => e.text.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (options.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add at least one option')),
        );
        return;
      }
      if (_mcqCorrectIndex == null ||
          _mcqCorrectIndex! >= _optionControllers.length ||
          _optionControllers[_mcqCorrectIndex!].text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a valid correct answer')),
        );
        return;
      }
    }

    if (_type == QuestionType.completion &&
        _codeCorrectAnswerController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide the correct answer')),
      );
      return;
    }

    if (_type == QuestionType.multi_select) {
      final options = _optionControllers
          .map((e) => e.text.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (options.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add at least one option')),
        );
        return;
      }
      if (_multiSelectCorrectIndexes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select at least one correct answer')),
        );
        return;
      }
      if (_multiSelectCorrectIndexes.any(
        (i) =>
            i >= _optionControllers.length ||
            _optionControllers[i].text.trim().isEmpty,
      )) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Correct answers must be valid options')),
        );
        return;
      }
    }

    if (_type == QuestionType.matching) {
      if (_matchingLeftControllers.isEmpty ||
          _matchingRightControllers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add at least one pair')),
        );
        return;
      }
      if (_matchingLeftControllers.length != _matchingRightControllers.length) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pairs are not aligned')),
        );
        return;
      }
      final hasEmpty = _matchingLeftControllers.any(
            (e) => e.text.trim().isEmpty,
          ) ||
          _matchingRightControllers.any((e) => e.text.trim().isEmpty);
      if (hasEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All pairs must be filled')),
        );
        return;
      }
    }

    if (_type == QuestionType.ordering) {
      if (_orderingControllers.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add at least two items')),
        );
        return;
      }
      if (_orderingControllers.any((e) => e.text.trim().isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All items must be filled')),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    Map<String, dynamic> config = {};
    if (_type == QuestionType.mcq) {
      final correct = _optionControllers[_mcqCorrectIndex!].text.trim();
      config = {
        'options': _optionControllers.map((e) => e.text.trim()).toList(),
        'correct_answer': correct,
      };
    } else if (_type == QuestionType.true_false) {
      config = {'correct_answer': _tfCorrectAnswer};
    } else if (_type == QuestionType.completion) {
      config = {'correct_answer': _codeCorrectAnswerController.text.trim()};
    } else if (_type == QuestionType.multi_select) {
      final options =
          _optionControllers.map((e) => e.text.trim()).toList();
      final correct = _multiSelectCorrectIndexes
          .where((i) => i >= 0 && i < options.length)
          .map((i) => options[i])
          .toList();
      config = {
        'options': options,
        'correct_answers': correct,
      };
    } else if (_type == QuestionType.matching) {
      config = {
        'left_side': _matchingLeftControllers.map((e) => e.text.trim()).toList(),
        'right_side': _matchingRightControllers
            .map((e) => e.text.trim())
            .toList(),
      };
    } else if (_type == QuestionType.ordering) {
      config = {
        'items': _orderingControllers.map((e) => e.text.trim()).toList(),
      };
    }

    final question = Question(
      id: widget.question?.id ?? '',
      lessonId: widget.lessonId,
      questionText: _textController.text,
      questionType: _type,
      config: config,
      points: _points,
      createdAt: DateTime.now(),
    );

    try {
      if (widget.question == null) {
        await _service.createQuestion(question);
      } else {
        await _service.updateQuestion(widget.question!.id, question);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        String errorMsg = e.toString();
        if (errorMsg.contains('42501')) {
          errorMsg =
              'Permission Denied (RLS Error). Please check Supabase Policies.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $errorMsg'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
