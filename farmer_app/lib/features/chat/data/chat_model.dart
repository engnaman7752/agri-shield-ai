class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final List<String> reasoningSteps;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    this.reasoningSteps = const [],
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory ChatMessage.fromUser(String text) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: true,
    );
  }

  factory ChatMessage.fromAI(String text, List<String> reasoningSteps) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: false,
      reasoningSteps: reasoningSteps,
    );
  }
}
