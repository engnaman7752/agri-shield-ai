import 'package:dio/dio.dart';
import 'chat_model.dart';

class ChatRepository {
  final Dio _dio;

  ChatRepository(this._dio);

  Future<ChatMessage> sendMessage({
    required String message,
    String? insuranceId,
    String? sensorCode,
  }) async {
    try {
      final response = await _dio.post(
        'chat',
        data: {
          'message': message,
          'insurance_id': insuranceId,
          'sensor_code': sensorCode,
        },
      );

      if (response.data['success']) {
        final data = response.data['data'];
        final answer = data['answer'] as String;
        final steps = (data['reasoning_steps'] as List).map((e) => e.toString()).toList();
        
        return ChatMessage.fromAI(answer, steps);
      }
      
      throw Exception('Failed to get AI response');
    } catch (e) {
      print('Chat error: $e');
      return ChatMessage.fromAI('Sorry, I am having trouble connecting to my reasoning engine right now. Please try again later.', []);
    }
  }
}
