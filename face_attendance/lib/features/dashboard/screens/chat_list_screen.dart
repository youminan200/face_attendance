import 'package:flutter/material.dart';
import '../controllers/dashboard_controller.dart';
import 'chat_detail_screen.dart';

/// 채팅방 목록 화면
class ChatListScreen extends StatelessWidget {
  final DashboardController dashboardController;

  const ChatListScreen({
    super.key,
    required this.dashboardController,
  });

  void _showCreateChatDialog(BuildContext context) {
    final titleController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('새 채팅방 개설'),
        content: TextField(
          controller: titleController,
          autofocus: true,
          decoration: const InputDecoration(hintText: '채팅방 제목을 입력하세요'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              final title = titleController.text.trim();
              if (title.isNotEmpty) {
                dashboardController.addChat(title);
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('개설'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('채팅 목록'),
        actions: [
          IconButton(
            tooltip: '채팅방 생성',
            icon: const Icon(Icons.add_comment_outlined),
            onPressed: () => _showCreateChatDialog(context),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: dashboardController,
        builder: (context, _) {
          final chats = dashboardController.chats;

          if (chats.isEmpty) {
            return const Center(
              child: Text('개설된 채팅방이 없습니다.\n우상단 버튼으로 새 대화를 시작하세요.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: chats.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final chat = chats[index];

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(25),
                  child: Icon(Icons.chat_bubble_outline, color: Theme.of(context).colorScheme.primary),
                ),
                title: Text(chat.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  chat.lastMsg,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.grey),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatDetailScreen(title: chat.title),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
