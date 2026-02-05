import 'package:dio/dio.dart';
import 'verification_models.dart';

class VerificationRepository {
  final Dio _dio;

  VerificationRepository(this._dio);

  Future<List<VerificationModel>> getPendingVerifications() async {
    try {
      final response = await _dio.get('patwari/verifications/pending');
      if (response.data['success']) {
        return (response.data['data'] as List)
            .map((e) => VerificationModel.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<SensorModel>> getAvailableSensors() async {
    try {
      final response = await _dio.get('patwari/sensors/available');
      if (response.data['success']) {
        return (response.data['data'] as List)
            .map((e) => SensorModel.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final response = await _dio.get('patwari/dashboard');
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  Future<bool> processVerification({
    required String verificationId,
    required String action, // APPROVE, REJECT
    required String remarks,
    String? sensorCode,
  }) async {
    try {
      final response = await _dio.post('patwari/verifications/action', data: {
        'verificationId': verificationId,
        'action': action,
        'remarks': remarks,
        'sensorCode': sensorCode,
      });
      return response.data['success'];
    } catch (e) {
      return false;
    }
  }
}
