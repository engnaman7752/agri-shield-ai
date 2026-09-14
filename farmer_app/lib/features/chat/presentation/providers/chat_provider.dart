import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:farmer_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:farmer_app/features/chat/data/chat_repository.dart';
import 'package:farmer_app/features/chat/data/chat_model.dart';

final chatRepositoryProvider = Provider((ref) {
  final dio = ref.watch(dioClientProvider).dio;
  return ChatRepository(dio);
});

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(ref.watch(chatRepositoryProvider));
});

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;

  ChatState({required this.messages, this.isLoading = false});

  ChatState copyWith({List<ChatMessage>? messages, bool? isLoading}) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final ChatRepository _repository;

  ChatNotifier(this._repository) : super(ChatState(
    messages: [
      ChatMessage.fromAI('Hello! I am your Farmer Shield AI Assistant. I can help you check your policy, analyze your field sensors, or explain PMFBY rules. How can I help today?', [])
    ]
  ));

  Future<void> sendMessage(String text, {String? insuranceId, String? sensorCode}) async {
    if (text.trim().isEmpty) return;

    // Add user message
    final userMsg = ChatMessage.fromUser(text);
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
    );

    // Build history string
    final historyStr = state.messages.map((m) => '${m.isUser ? "User" : "AI"}: ${m.text}').join('\n');
    final combinedMessage = 'Previous Conversation:\n$historyStr\n\nCurrent Question: $text';

    // Get AI response
    final aiResponse = await _repository.sendMessage(
      message: combinedMessage,
      insuranceId: insuranceId,
      sensorCode: sensorCode,
    );

    state = state.copyWith(
      messages: [...state.messages, aiResponse],
      isLoading: false,
    );
  }
}
