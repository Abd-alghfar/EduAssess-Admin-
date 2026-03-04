import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/message_model.dart';
import '../models/profile_model.dart';
import '../services/supabase_service.dart';

class ChatProvider with ChangeNotifier {
  final SupabaseService _service = SupabaseService();
  final _supabase = Supabase.instance.client;

  List<Profile> _chatStudents = [];
  Map<String, ChatMessage> _lastMessages = {};
  List<ChatMessage> _currentMessages = [];
  bool _isLoading = false;

  List<Profile> get chatStudents => _chatStudents;
  Map<String, ChatMessage> get lastMessages => _lastMessages;
  List<ChatMessage> get currentMessages => _currentMessages;
  bool get isLoading => _isLoading;

  RealtimeChannel? _msgSubscription;

  void initChatListListener() {
    _supabase
        .channel('public:messages:list')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'messages',
          callback: (payload) {
            fetchChatList();
          },
        )
        .subscribe();
    fetchChatList();
  }

  Future<void> fetchChatList() async {
    _isLoading = true;
    notifyListeners();
    try {
      _lastMessages = await _service.getLastMessages();
      final students = await _service.getStudents();

      // Filter students who have messages or identify with whom we have chats
      _chatStudents = students
          .where((s) => _lastMessages.containsKey(s.id))
          .toList();

      // Sort by last message time
      _chatStudents.sort((a, b) {
        final timeA = _lastMessages[a.id]?.createdAt ?? DateTime(2000);
        final timeB = _lastMessages[b.id]?.createdAt ?? DateTime(2000);
        return timeB.compareTo(timeA);
      });
    } catch (e) {
      debugPrint('Error fetching chat list: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void subscribeToMessages(String studentId) {
    _msgSubscription?.unsubscribe();
    _msgSubscription = _supabase
        .channel('public:messages:room')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'messages',
          callback: (payload) {
            fetchMessages(studentId);
          },
        )
        .subscribe();
    fetchMessages(studentId);
  }

  Future<void> fetchMessages(String studentId) async {
    try {
      _currentMessages = await _service.getMessagesWithStudent(studentId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching messages: $e');
    }
  }

  Future<void> sendMessage(
    String studentId,
    String content, {
    String? imageUrl,
  }) async {
    try {
      await _service.sendMessage(
        studentId: studentId,
        content: content.isEmpty ? null : content,
        imageUrl: imageUrl,
      );
    } catch (e) {
      debugPrint('Error sending message: $e');
    }
  }

  Future<void> editMessage(String messageId, String content) async {
    try {
      await _service.updateMessage(messageId, content);
    } catch (e) {
      debugPrint('Error updating message: $e');
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      await _service.deleteMessage(messageId);
    } catch (e) {
      debugPrint('Error deleting message: $e');
    }
  }

  Future<void> markAsRead(String studentId) async {
    try {
      await _service.markAsRead(studentId);
    } catch (e) {
      debugPrint('Error marking as read: $e');
    }
  }

  @override
  void dispose() {
    _msgSubscription?.unsubscribe();
    super.dispose();
  }
}
