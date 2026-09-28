import 'package:flutter/material.dart';
import '../../../core/utils/responsive.dart';

/// 채팅방 대화 상세 화면
class ChatDetailScreen extends StatefulWidget {
  final String title;

  const ChatDetailScreen({super.key, required this.title});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<String> _messages = [];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(text);
    });

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final isKeyboardOpen = bottomInset > 0;
    final maxWidth = Responsive.contentMaxWidth(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SafeArea(
        bottom: !isKeyboardOpen, // 키보드가 열려있을 때는 키보드 높이에 맞춤
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth.isFinite ? maxWidth : double.infinity),
            child: Column(
              children: [
                Expanded(
                  child: _messages.isEmpty
                      ? Center(
                          child: Text(
                            '대화 내용이 없습니다.\n첫 메시지를 입력해보세요.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.withAlpha(150)),
                          ),
                        )
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            return Align(
                              alignment: Alignment.centerRight,
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  _messages[index],
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                Container(
                  padding: EdgeInsets.only(
                    left: 12,
                    right: 8,
                    top: 8,
                    bottom: isKeyboardOpen ? 8 : 12,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    border: Border(top: BorderSide(color: Colors.grey.withAlpha(50))),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: const InputDecoration(
                            hintText: '메시지를 입력하세요...',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 12),
                          ),
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.send_rounded, color: Theme.of(context).colorScheme.primary),
                        onPressed: _sendMessage,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
