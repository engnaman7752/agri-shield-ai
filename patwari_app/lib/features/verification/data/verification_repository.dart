import 'package:dio/dio.dart';
import 'verification_models.dart';

class VerificationRepository {
  final Dio _dio;

  VerificationRepository(this._dio);

  Future<List<VerificationModel>> getPendingVerifications() async {
    try {
      final response = await _dio.get('patwari/verifications/pending');
      if (response.data['success'] == true && response.data['data'] != null) {
        return (response.data['data'] as List)
            .map((e) => VerificationModel.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      print('Pending verifications error: $e');
      return [];
    }
  }

  Future<List<SensorModel>> getAvailableSensors() async {
    try {
      final response = await _dio.get('patwari/sensors/available');
      print('Available sensors response: ${response.data}');
      if (response.data['success'] == true && response.data['data'] != null) {
        return (response.data['data'] as List)
            .map((e) => SensorModel.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error fetching sensors: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final response = await _dio.get('patwari/dashboard');
      if (response.data['success'] == true && response.data['data'] != null) {
        return response.data['data'] as Map<String, dynamic>;
      }
      return {};
    } catch (e) {
      print('Dashboard stats error: $e');
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
      // Backend expects 'status' as APPROVED/REJECTED enum
      final status = action == 'APPROVE' ? 'APPROVED' : 'REJECTED';
      final response = await _dio.post('patwari/verifications/action', data: {
        'verificationId': verificationId,
        'status': status,
        'remarks': remarks,
        'sensorCode': sensorCode,
      });
      print('Verification action response: ${response.data}');
      return response.data['success'] == true;
    } catch (e) {
      print('Verification action error: $e');
      return false;
    }
  }
}
