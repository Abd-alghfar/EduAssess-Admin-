import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/lesson_model.dart';
import '../models/profile_model.dart';
import '../models/student_answer_model.dart';
import '../services/supabase_service.dart';

class TeacherProvider with ChangeNotifier {
  final SupabaseService _service = SupabaseService();

  List<Profile> _students = [];
  List<Lesson> _lessons = [];
  List<Map<String, dynamic>> _assignments = [];
  Map<String, dynamic>? _currentAssignment;
  bool _isLoading = false;

  final Map<String, double> _lessonSuccessRates = {};
  final Map<String, int> _lessonCompletionCounts = {};
  final Map<DateTime, int> _completionTrend = {};

  List<Profile> get students => _students;
  List<Lesson> get lessons => _lessons;
  List<Map<String, dynamic>> get assignments => _assignments;
  Map<String, dynamic>? get currentAssignment => _currentAssignment;
  bool get isLoading => _isLoading;
  Map<String, double> get lessonSuccessRates => _lessonSuccessRates;
  Map<String, int> get lessonCompletionCounts => _lessonCompletionCounts;
  Map<DateTime, int> get completionTrend => _completionTrend;

  Future<void> fetchAssignments() async {
    _isLoading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final teacherId = prefs.getString('teacher_id');
      if (teacherId != null) {
        _assignments = await _service.getTeacherAssignments(teacherId);
        if (_assignments.isNotEmpty && _currentAssignment == null) {
          _currentAssignment = _assignments.first;
        }
      }
    } catch (e) {
      debugPrint('Error fetching assignments: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setCurrentAssignment(Map<String, dynamic> assignment) {
    _currentAssignment = assignment;
    fetchLessons();
    fetchStudents();
    notifyListeners();
  }

  Future<void> fetchStudents() async {
    if (_currentAssignment == null) return;
    _isLoading = true;
    notifyListeners();
    try {
      final classId = _currentAssignment!['class_id'];
      _students = await _service.getStudents(classId: classId);
    } catch (e) {
      debugPrint('Error fetching students: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchLessons() async {
    _isLoading = true;
    notifyListeners();
    try {
      _lessons = await _service.getLessons(
        assignmentId: _currentAssignment?['id'],
      );
      await _computeLessonSuccessRates();
      _lessonCompletionCounts.clear();
      _lessonCompletionCounts.addAll(
        await _service.getLessonCompletionCounts(),
      );
      _completionTrend.clear();
      _completionTrend.addAll(await _service.getCompletionTrend());
    } catch (e) {
      debugPrint('Error fetching lessons: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _computeLessonSuccessRates() async {
    _lessonSuccessRates.clear();
    for (final lesson in _lessons) {
      try {
        final answers = await _service.getLessonAnswers(lesson.id);
        final total = answers.length;
        final correct = answers.where((a) => a.isCorrect).length;
        final rate = total > 0 ? (correct / total) * 100 : 0.0;
        _lessonSuccessRates[lesson.id] = rate;
      } catch (e) {
        debugPrint('Error computing success rate for lesson ${lesson.id}: $e');
        _lessonSuccessRates[lesson.id] = 0.0;
      }
    }
  }

  Future<Lesson> addLesson(
    String title,
    int? durationMinutes, {
    bool shuffleQuestions = true,
    bool isPublished = false,
  }) async {
    final lesson = Lesson(
      id: '',
      title: title,
      createdAt: DateTime.now(),
      durationMinutes: durationMinutes,
      shuffleQuestions: shuffleQuestions,
      isPublished: isPublished,
    );
    final created = await _service.createLesson(
      lesson,
      assignmentId: _currentAssignment?['id'],
    );
    await fetchLessons();
    return created;
  }

  Future<void> updateLesson(
    String id,
    String title,
    int? durationMinutes, {
    bool shuffleQuestions = true,
    bool isPublished = false,
  }) async {
    final lesson = Lesson(
      id: id,
      title: title,
      createdAt: DateTime.now(),
      durationMinutes: durationMinutes,
      shuffleQuestions: shuffleQuestions,
      isPublished: isPublished,
    );
    await _service.updateLesson(id, lesson);
    await fetchLessons();
  }

  Future<void> deleteLesson(String id) async {
    await _service.deleteLesson(id);
    await fetchLessons();
  }

  List<StudentAnswer> _incorrectAnswers = [];
  List<StudentAnswer> get incorrectAnswers => _incorrectAnswers;

  Future<void> fetchIncorrectAnswers({String? studentId}) async {
    _isLoading = true;
    notifyListeners();
    try {
      if (_students.isEmpty) {
        await fetchStudents();
      }
      _incorrectAnswers = await _service.getIncorrectAnswers(
        studentId: studentId,
      );
    } catch (e) {
      debugPrint('Error fetching incorrect answers: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
