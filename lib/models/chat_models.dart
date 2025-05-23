class ChatMessage {
  final String type; // 'text' or 'image'
  String content; // text content or image file path
  final bool fromUser;

  ChatMessage({
    required this.type,
    required this.content,
    required this.fromUser,
  });

  Map<String, dynamic> toJson() => {
    'type': type,
    'content': content,
    'fromUser': fromUser,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    type: json['type'],
    content: json['content'],
    fromUser: json['fromUser'],
  );
}

class ChatConversation {
  final String id;
  final String userId;
  String title;
  final List<ChatMessage> messages;
  bool isPinned;

  ChatConversation({
    required this.id,
    required this.userId,
    required this.title,
    required this.messages,
    this.isPinned = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'title': title,
    'messages': messages.map((m) => m.toJson()).toList(),
    'isPinned': isPinned,
  };

  factory ChatConversation.fromJson(Map<String, dynamic> json) =>
      ChatConversation(
        id: json['id'],
        userId: json['userId'],
        title: json['title'],
        messages:
            (json['messages'] as List)
                .map((e) => ChatMessage.fromJson(e))
                .toList(),
        isPinned: json['isPinned'] ?? false,
      );
}
