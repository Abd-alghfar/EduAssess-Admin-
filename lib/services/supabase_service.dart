import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/lesson_model.dart';
import '../models/profile_model.dart';
import '../models/question_model.dart';
import '../models/student_answer_model.dart';
import '../models/student_progress_model.dart';
import '../models/message_model.dart';

class SupabaseService {
  final _supabase = Supabase.instance.client;

  // --- Students (Profiles) ---
  Future<List<Profile>> getStudents() async {
    final response = await _supabase
        .from('profiles')
        .select()
        .order('updated_at', ascending: false);
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
  Future<List<Lesson>> getLessons() async {
    final response = await _supabase
        .from('lessons')
        .select()
        .order('created_at', ascending: false);
    return (response as List).map((json) => Lesson.fromJson(json)).toList();
  }

  Future<Lesson> createLesson(Lesson lesson) async {
    final response = await _supabase
        .from('lessons')
        .insert(lesson.toJson())
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

  // --- Student Progress & Answers ---
  Future<List<StudentProgress>> getStudentProgress(String studentId) async {
    final response = await _supabase
        .from('student_progress')
        .select('*, lessons(title)')
        .eq('student_id', studentId);
    return (response as List)
        .map((json) => StudentProgress.fromJson(json))
        .toList();
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
        .select()
        .eq('student_id', studentId)
        .inFilter('question_id', questionIds);

    final List<StudentAnswer> answers = [];
    for (var json in (response as List)) {
      final answer = StudentAnswer.fromJson(json);
      // Manually attach the question object
      final question = questions.firstWhere((q) => q.id == answer.questionId);
      answers.add(
        StudentAnswer(
          id: answer.id,
          studentId: answer.studentId,
          questionId: answer.questionId,
          answerValue: answer.answerValue,
          isCorrect: answer.isCorrect,
          scoreAttained: answer.scoreAttained,
          createdAt: answer.createdAt,
          question: question,
        ),
      );
    }

    return answers;
  }

  Future<Map<String, int>> getLessonCompletionCounts() async {
    final response = await _supabase
        .from('student_progress')
        .select('lesson_id');
    final Map<String, int> counts = {};
    for (var row in (response as List)) {
      final lessonId = row['lesson_id'] as String;
      counts[lessonId] = (counts[lessonId] ?? 0) + 1;
    }
    return counts;
  }

  Future<Map<DateTime, int>> getCompletionTrend() async {
    final response = await _supabase
        .from('student_progress')
        .select('completed_at');
    final Map<DateTime, int> trend = {};
    for (var row in (response as List)) {
      final date = DateTime.parse(row['completed_at']).toLocal();
      final day = DateTime(date.year, date.month, date.day);
      trend[day] = (trend[day] ?? 0) + 1;
    }
    return trend;
  }

  Future<List<Profile>> getStudentsWhoSolvedLesson(String lessonId) async {
    final progressResponse = await _supabase
        .from('student_progress')
        .select('student_id')
        .eq('lesson_id', lessonId);

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
  }

  Future<List<Profile>> getStudentsWhoAttemptedLesson(String lessonId) async {
    final questions = await getQuestions(lessonId);
    if (questions.isEmpty) return [];

    final questionIds = questions.map((q) => q.id).toList();
    final answersResponse = await _supabase
        .from('student_answers')
        .select('student_id')
        .inFilter('question_id', questionIds);

    final studentIds = (answersResponse as List)
        .map((row) => row['student_id'] as String)
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
        studentId: answer.studentId,
        questionId: answer.questionId,
        answerValue: answer.answerValue,
        isCorrect: answer.isCorrect,
        scoreAttained: answer.scoreAttained,
        createdAt: answer.createdAt,
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
    if (answerValue != null) data['answer_value'] = answerValue;
    if (isCorrect != null) data['is_correct'] = isCorrect;
    if (score != null) data['score_attained'] = score;

    await _supabase.from('student_answers').update(data).eq('id', answerId);
  }

  // --- Chat ---
  Future<List<ChatMessage>> getMessagesWithStudent(String studentId) async {
    final response = await _supabase
        .from('messages')
        .select()
        .eq('sender_id', studentId)
        .order('created_at', ascending: true);
    return (response as List)
        .map((json) => ChatMessage.fromJson(json))
        .toList();
  }

  Future<void> sendMessage({
    required String studentId,
    String? content,
    String? imageUrl,
  }) async {
    final prefix = '[INSTRUCTOR]\n';
    await _supabase.from('messages').insert({
      'sender_id': studentId,
      'content': content != null && content.isNotEmpty
          ? '$prefix$content'
          : prefix,
      'image_url': imageUrl,
      'is_read': false,
    });
  }

  Future<void> updateMessage(String messageId, String content) async {
    await _supabase
        .from('messages')
        .update({'content': '[INSTRUCTOR]\n$content'})
        .eq('id', messageId);
  }

  Future<void> deleteMessage(String messageId) async {
    await _supabase.from('messages').delete().eq('id', messageId);
  }

  Future<void> markAsRead(String studentId) async {
    final messages = await getMessagesWithStudent(studentId);
    for (final msg in messages) {
      if (!msg.isFromTeacher && !msg.isRead) {
        await _supabase
            .from('messages')
            .update({'is_read': true})
            .eq('id', msg.id);
      }
    }
  }

  // Get last message for each student to build the chat list
  Future<Map<String, ChatMessage>> getLastMessages() async {
    final response = await _supabase
        .from('messages')
        .select()
        .order('created_at', ascending: false);

    final Map<String, ChatMessage> lastMessages = {};

    for (var json in (response as List)) {
      final msg = ChatMessage.fromJson(json);
      if (!lastMessages.containsKey(msg.senderId)) {
        lastMessages[msg.senderId] = msg;
      }
    }
    return lastMessages;
  }

  Future<String?> uploadChatImage(File file) async {
    try {
      final fileName = 'chat_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = fileName; // Simplified path

      // Attempt to upload to 'chat_images' bucket
      await _supabase.storage.from('chat_images').upload(path, file);

      final imageUrl = _supabase.storage.from('chat_images').getPublicUrl(path);
      debugPrint('Generated Image URL: $imageUrl');
      return imageUrl;
    } catch (e) {
      debugPrint('Error uploading image to Supabase: $e');
      return null;
    }
  }

  Future<List<StudentAnswer>> getIncorrectAnswers({String? studentId}) async {
    var query = _supabase
        .from('student_answers')
        .select('*, questions(*, lessons(*))')
        .eq('is_correct', false);

    if (studentId != null) {
      query = query.eq('student_id', studentId);
    }

    final response = await query.order('created_at', ascending: false);
    return (response as List)
        .map((json) => StudentAnswer.fromJson(json))
        .toList();
  }
}
