/// 채팅방 모델
class ChatRoom {
  String id;
  String title;
  String lastMsg;
  DateTime updatedAt;

  ChatRoom({
    String? id,
    required this.title,
    this.lastMsg = '대화를 시작해보세요.',
    DateTime? updatedAt,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'last_msg': lastMsg,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ChatRoom.fromMap(Map<String, dynamic> map) {
    return ChatRoom(
      id: map['id']?.toString(),
      title: map['title'] ?? '',
      lastMsg: map['last_msg'] ?? '대화를 시작해보세요.',
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at']) : null,
    );
  }
}
