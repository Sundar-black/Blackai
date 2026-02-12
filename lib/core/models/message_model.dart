enum MessageRole { user, ai }

class ChatMessage {
  final String id;
  String text;
  final bool isUser;
  final DateTime timestamp;
  final List<String> attachmentPaths;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.attachmentPaths = const [],
  });

  factory ChatMessage.user(String text, {List<String> attachments = const []}) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
      attachmentPaths: attachments,
    );
  }

  factory ChatMessage.ai(String text) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: false,
      timestamp: DateTime.now(),
      attachmentPaths: [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'attachmentPaths': attachmentPaths,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      text: json['text'],
      isUser: json['isUser'],
      timestamp: DateTime.parse(json['timestamp']),
      attachmentPaths:
          (json['attachmentPaths'] as List?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }
}
