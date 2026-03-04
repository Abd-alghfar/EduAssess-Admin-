import 'package:flutter/material.dart';
import '../models/lesson_model.dart';
import '../models/profile_model.dart';
import '../models/student_answer_model.dart';
import '../services/supabase_service.dart';

class AdminProvider with ChangeNotifier {
  final SupabaseService _service = SupabaseService();

  List<Profile> _students = [];
  List<Lesson> _lessons = [];
  bool _isLoading = false;
  // Map lesson ID to success rate percentage
  final Map<String, double> _lessonSuccessRates = {};
  final Map<String, int> _lessonCompletionCounts = {};
  final Map<DateTime, int> _completionTrend = {};

  List<Profile> get students => _students;
  List<Lesson> get lessons => _lessons;
  bool get isLoading => _isLoading;
  Map<String, double> get lessonSuccessRates => _lessonSuccessRates;
  Map<String, int> get lessonCompletionCounts => _lessonCompletionCounts;
  Map<DateTime, int> get completionTrend => _completionTrend;

  Future<void> fetchStudents() async {
    _isLoading = true;
    notifyListeners();
    try {
      _students = await _service.getStudents();
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
      _lessons = await _service.getLessons();
      // After fetching lessons, compute success rates and completion counts
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

  // Compute success rate for each lesson based on student answers
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

  Future<void> addStudent(
    String fullName,
    String username,
    String accessKey,
  ) async {
    await _service.createStudent(
      fullName: fullName,
      username: username,
      accessKey: accessKey,
    );
    await fetchStudents();
  }

  Future<void> updateStudent(
    String id,
    String fullName,
    String username,
    String accessKey,
  ) async {
    await _service.updateStudent(
      id: id,
      fullName: fullName,
      username: username,
      accessKey: accessKey,
    );
    await fetchStudents();
  }

  Future<Lesson> addLesson(
    String title,
    String description,
    int? durationMinutes,
    bool showCorrection,
  ) async {
    final lesson = Lesson(
      id: '', // Supabase generates this
      title: title,
      description: description,
      createdAt: DateTime.now(),
      showCorrection: showCorrection,
      durationMinutes: durationMinutes,
    );
    final created = await _service.createLesson(lesson);
    await fetchLessons();
    return created;
  }

  Future<void> updateLesson(
    String id,
    String title,
    String description,
    int? durationMinutes,
    bool showCorrection,
  ) async {
    final lesson = Lesson(
      id: id,
      title: title,
      description: description,
      createdAt: DateTime.now(), // This won't be updated in DB usually
      showCorrection: showCorrection,
      durationMinutes: durationMinutes,
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
