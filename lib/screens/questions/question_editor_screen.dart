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
  String? _mcqCorrectAnswer;

  // Code Completion state
  late TextEditingController _snippetController;
  late TextEditingController _placeholderController;
  late TextEditingController _codeCorrectAnswerController;

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
        _mcqCorrectAnswer = config['correct_answer'];
      } else if (_type == QuestionType.code_completion) {
        _snippetController.text = config['code_snippet'] ?? '';
        _placeholderController.text = config['placeholder'] ?? '';
        _codeCorrectAnswerController.text = config['correct_answer'] ?? '';
      } else if (_type == QuestionType.true_false) {
        _tfCorrectAnswer = config['correct_answer'] ?? true;
      }
    } else {
      // Defaults for new question
      _optionControllers = [TextEditingController(), TextEditingController()];
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
    _codeCorrectAnswerController.dispose();
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
        final label =
            t == QuestionType.code_completion ? 'COMPLETION' : t.toString().split('.').last.toUpperCase();
        return DropdownMenuItem(
          value: t,
          child: Text(label),
        );
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
      case QuestionType.code_completion:
        return _buildCodeConfig();
    }
  }

  Widget _buildMCQConfig() {
    return Column(
      children: [
        ...List.generate(_optionControllers.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Radio<String>(
                  value: _optionControllers[index].text,
                  groupValue: _mcqCorrectAnswer,
                  onChanged: (val) {
                    setState(
                      () => _mcqCorrectAnswer = _optionControllers[index].text,
                    );
                  },
                ),
                Expanded(
                  child: TextFormField(
                    controller: _optionControllers[index],
                    decoration: InputDecoration(
                      labelText: 'Option ${index + 1}',
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (v) {
                      // Update correct answer if it was this option
                      if (_mcqCorrectAnswer == null && index == 0) {
                        // just a placeholder
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      _optionControllers.removeAt(index);
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
        if (_mcqCorrectAnswer == null && _optionControllers.isNotEmpty)
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Validation for MCQ
    if (_type == QuestionType.mcq) {
      if (_optionControllers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add at least one option')),
        );
        return;
      }
      // Re-check correct answer match
      bool found = false;
      for (var c in _optionControllers) {
        if (c.text == _mcqCorrectAnswer && c.text.isNotEmpty) {
          found = true;
          break;
        }
      }
      if (!found) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a valid correct answer')),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    Map<String, dynamic> config = {};
    if (_type == QuestionType.mcq) {
      config = {
        'options': _optionControllers.map((e) => e.text).toList(),
        'correct_answer': _mcqCorrectAnswer,
      };
    } else if (_type == QuestionType.true_false) {
      config = {'correct_answer': _tfCorrectAnswer};
    } else if (_type == QuestionType.code_completion) {
      config = {
        'correct_answer': _codeCorrectAnswerController.text,
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
