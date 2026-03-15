import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/lesson_model.dart';
import '../models/profile_model.dart';
import '../models/question_model.dart';
import '../models/student_answer_model.dart';
import '../models/exam_attempt_model.dart';

class SupabaseService {
  final _supabase = Supabase.instance.client;

  // --- Assignments ---
  Future<List<Map<String, dynamic>>> getTeacherAssignments(
    String teacherId,
  ) async {
    final response = await _supabase
        .from('teacher_assignments')
        .select('*, subjects(name), classes(name)')
        .eq('teacher_id', teacherId)
        .eq('is_active', true);
    return List<Map<String, dynamic>>.from(response);
  }

  // --- Students (Profiles) ---
  Future<List<Profile>> getStudents({String? classId}) async {
    if (classId != null) {
      final response = await _supabase
          .from('class_students')
          .select('profiles(*)')
          .eq('class_id', classId);
      return (response as List)
          .where((row) => row['profiles'] != null)
          .map((json) => Profile.fromJson(json['profiles']))
          .toList();
    }
    final response = await _supabase
        .from('profiles')
        .select()
        .eq('role', 'student');
    return (response as List).map((json) => Profile.fromJson(json)).toList();
  }

  // Future<List<Profile>> getProfilesByIds(List<String> studentIds) async {
  //   if (studentIds.isEmpty) return [];
  //   final response = await _supabase
  //       .from('profiles')
  //       .select()
  //       .inFilter('id', studentIds);
  //   return (response as List).map((json) => Profile.fromJson(json)).toList();
  // }

  Future<void> createStudent({
    required String fullName,
    required String username,
    required String accessKey,
  }) async {
    // Create a dummy email and use accessKey as password to satisfy Foreign Key constraint
    final dummyEmail =
        '${username.replaceAll(' ', '_').toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}@ubus.com';
    final dummyPassword = accessKey.length >= 6
        ? accessKey
        : '${accessKey}123456';

    final authResponse = await _supabase.auth.signUp(
      email: dummyEmail,
      password: dummyPassword,
    );

    if (authResponse.user != null) {
      await _supabase
          .from('profiles')
          .update({
            'full_name': fullName,
            'username': username,
            'access_key': accessKey,
          })
          .eq('id', authResponse.user!.id);
    }
  }

  Future<void> updateStudent({
    required String id,
    required String fullName,
    required String username,
    required String accessKey,
  }) async {
    await _supabase
        .from('profiles')
        .update({
          'full_name': fullName,
          'username': username,
          'access_key': accessKey,
        })
        .eq('id', id);
  }

  // --- Lessons ---
  Future<List<Lesson>> getLessons({String? assignmentId}) async {
    var query = _supabase.from('lessons').select();
    if (assignmentId != null) {
      query = query.eq('assignment_id', assignmentId);
    }
    final response = await query.order('created_at', ascending: false);
    return (response as List).map((json) => Lesson.fromJson(json)).toList();
  }

  Future<Lesson> createLesson(Lesson lesson, {String? assignmentId}) async {
    final data = lesson.toJson();
    if (assignmentId != null) {
      data['assignment_id'] = assignmentId;
    }
    final response = await _supabase
        .from('lessons')
        .insert(data)
        .select()
        .single();
    return Lesson.fromJson(response);
  }

  Future<void> updateLesson(String id, Lesson lesson) async {
    await _supabase.from('lessons').update(lesson.toJson()).eq('id', id);
  }

  Future<void> deleteLesson(String id) async {
    await _supabase.from('lessons').delete().eq('id', id);
  }

  // --- Questions ---
  Future<List<Question>> getQuestions(String lessonId) async {
    final response = await _supabase
        .from('questions')
        .select()
        .eq('lesson_id', lessonId)
        .order('created_at', ascending: true);
    return (response as List).map((json) => Question.fromJson(json)).toList();
  }

  Future<void> createQuestion(Question question) async {
    await _supabase.from('questions').insert(question.toJson());
  }

  Future<void> updateQuestion(String id, Question question) async {
    await _supabase.from('questions').update(question.toJson()).eq('id', id);
  }

  Future<void> deleteQuestion(String id) async {
    await _supabase.from('questions').delete().eq('id', id);
  }

  // --- Exam Attempts (formerly Student Progress) ---
  Future<List<ExamAttempt>> getStudentProgress(String studentId) async {
    try {
      final response = await _supabase
          .from('exam_attempts')
          .select('*, lessons(title)')
          .eq('student_id', studentId);
      return (response as List)
          .map((json) => ExamAttempt.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching student progress: $e');
      return [];
    }
  }

  Future<List<StudentAnswer>> getStudentAnswers(
    String studentId,
    String lessonId,
  ) async {
    // 1. Get all question IDs for this lesson
    final questions = await getQuestions(lessonId);
    if (questions.isEmpty) return [];

    final questionIds = questions.map((q) => q.id).toList();

    // 2. Get the student's answers for these questions
    final response = await _supabase
        .from('student_answers')
        .select('*, exam_attempts!inner(*)')
        .eq('exam_attempts.student_id', studentId)
        .inFilter('question_id', questionIds);

    final List<StudentAnswer> answers = [];
    for (var json in (response as List)) {
      final answer = StudentAnswer.fromJson(json);
      // Manually attach the question object
      final question = questions.firstWhere((q) => q.id == answer.questionId);
      answers.add(
        StudentAnswer(
          id: answer.id,
          attemptId: answer.attemptId,
          questionId: answer.questionId,
          answerValue: answer.answerValue,
          isCorrect: answer.isCorrect,
          pointsEarned: answer.pointsEarned,
          question: question,
        ),
      );
    }

    return answers;
  }

  Future<Map<String, int>> getLessonCompletionCounts() async {
    try {
      final response = await _supabase
          .from('exam_attempts')
          .select('lesson_id')
          .eq('is_completed', true);
      final Map<String, int> counts = {};
      for (var row in (response as List)) {
        final lessonId = row['lesson_id'] as String;
        counts[lessonId] = (counts[lessonId] ?? 0) + 1;
      }
      return counts;
    } catch (e) {
      debugPrint('Error fetching completion counts: $e');
      return {};
    }
  }

  Future<Map<DateTime, int>> getCompletionTrend() async {
    try {
      final response = await _supabase
          .from('exam_attempts')
          .select('completed_at')
          .eq('is_completed', true)
          .not('completed_at', 'is', null);
      final Map<DateTime, int> trend = {};
      for (var row in (response as List)) {
        final date = DateTime.parse(row['completed_at']).toLocal();
        final day = DateTime(date.year, date.month, date.day);
        trend[day] = (trend[day] ?? 0) + 1;
      }
      return trend;
    } catch (e) {
      debugPrint('Error fetching completion trend: $e');
      return {};
    }
  }

  Future<List<Profile>> getStudentsWhoSolvedLesson(String lessonId) async {
    try {
      final progressResponse = await _supabase
          .from('exam_attempts')
          .select('student_id')
          .eq('lesson_id', lessonId)
          .eq('is_completed', true);

      final studentIds = (progressResponse as List)
          .map((row) => row['student_id'] as String)
          .toList();

      if (studentIds.isEmpty) return [];

      final profilesResponse = await _supabase
          .from('profiles')
          .select()
          .inFilter('id', studentIds);

      return (profilesResponse as List)
          .map((json) => Profile.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching students who solved lesson: $e');
      return [];
    }
  }

  Future<List<Profile>> getStudentsWhoAttemptedLesson(String lessonId) async {
    final questions = await getQuestions(lessonId);
    if (questions.isEmpty) return [];

    final questionIds = questions.map((q) => q.id).toList();
    final answersResponse = await _supabase
        .from('student_answers')
        .select('exam_attempts(student_id)')
        .inFilter('question_id', questionIds);

    final studentIds = (answersResponse as List)
        .where((row) => row['exam_attempts'] != null)
        .map((row) => row['exam_attempts']['student_id'] as String)
        .toSet()
        .toList();

    if (studentIds.isEmpty) return [];

    final profilesResponse = await _supabase
        .from('profiles')
        .select()
        .inFilter('id', studentIds);

    return (profilesResponse as List)
        .map((json) => Profile.fromJson(json))
        .toList();
  }

  // New method: fetch all student answers for a specific lesson across all students
  Future<List<StudentAnswer>> getLessonAnswers(String lessonId) async {
    // 1. Get all questions for this lesson
    final questions = await getQuestions(lessonId);
    if (questions.isEmpty) return [];

    final questionIds = questions.map((q) => q.id).toList();

    // 2. Get all student answers for these questions
    final response = await _supabase
        .from('student_answers')
        .select()
        .inFilter('question_id', questionIds);

    return (response as List).map((json) {
      final answer = StudentAnswer.fromJson(json);
      final question = questions.firstWhere((q) => q.id == answer.questionId);
      return StudentAnswer(
        id: answer.id,
        attemptId: answer.attemptId,
        questionId: answer.questionId,
        answerValue: answer.answerValue,
        isCorrect: answer.isCorrect,
        pointsEarned: answer.pointsEarned,
        question: question,
      );
    }).toList();
  }

  Future<void> updateStudentAnswer(
    String answerId, {
    dynamic answerValue,
    bool? isCorrect,
    int? score,
  }) async {
    final Map<String, dynamic> data = {};
    if (answerValue != null) data['student_answer'] = answerValue;
    if (isCorrect != null) data['is_correct'] = isCorrect;
    if (score != null) data['points_earned'] = score;

    await _supabase.from('student_answers').update(data).eq('id', answerId);
  }

  Future<List<StudentAnswer>> getIncorrectAnswers({String? studentId}) async {
    var query = _supabase
        .from('student_answers')
        .select('*, questions(*, lessons(*)), exam_attempts(profiles(*))')
        .eq('is_correct', false);

    if (studentId != null) {
      query = query.eq('exam_attempts.student_id', studentId);
    }

    final response = await query;
    return (response as List)
        .map((json) => StudentAnswer.fromJson(json))
        .toList();
  }
}
