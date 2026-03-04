import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/chat_provider.dart';
import 'chat_room_screen.dart';
import '../../widgets/shimmer_loader.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<ChatProvider>().initChatListListener();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).viewPadding.bottom + 96;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Conversations',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          if (chatProvider.isLoading && chatProvider.chatStudents.isEmpty) {
            return const ListShimmer();
          }

          if (chatProvider.chatStudents.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: scheme.primary.withValues(alpha: 0.35),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No conversations yet',
                    style: TextStyle(color: Colors.grey[700], fontSize: 18),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => chatProvider.fetchChatList(),
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(16, 12, 16, bottomInset),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: chatProvider.chatStudents.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final student = chatProvider.chatStudents[index];
                final lastMsg = chatProvider.lastMessages[student.id];
                final String studentName = student.fullName ?? 'Student';
                final String lastMsgText =
                    lastMsg?.displayContent ??
                    (lastMsg?.imageUrl != null ? 'Image' : 'No messages yet');
                final String time = lastMsg != null
                    ? DateFormat('jm').format(lastMsg.createdAt)
                    : '';

                return Card(
                  child: ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ChatRoomScreen(student: student),
                        ),
                      );
                    },
                    leading: CircleAvatar(
                      radius: 26,
                      backgroundColor: scheme.primary.withValues(alpha: 0.1),
                      child: Text(
                        studentName.isNotEmpty
                            ? studentName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: scheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    title: Text(
                      studentName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      lastMsgText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color:
                            (lastMsg != null &&
                                !lastMsg.isRead &&
                                !lastMsg.isFromTeacher)
                            ? Colors.black87
                            : Colors.grey[600],
                        fontWeight:
                            (lastMsg != null &&
                                !lastMsg.isRead &&
                                !lastMsg.isFromTeacher)
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          time,
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (lastMsg != null &&
                            !lastMsg.isRead &&
                            !lastMsg.isFromTeacher)
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: scheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
