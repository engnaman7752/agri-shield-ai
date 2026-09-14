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
        final list = (response.data['data'] as List)
            .map((e) => SensorModel.fromJson(e))
            .toList();
        if (list.isNotEmpty) return list;
      }
    } catch (e) {
      print('Error fetching sensors: $e');
    }
    // FALLBACK: Always return prototype sensors for demo
    print('Using fallback prototype sensors');
    return [
      SensorModel(id: 'proto-1', uniqueCode: 'SENS-001'),
      SensorModel(id: 'proto-2', uniqueCode: 'SENS-002'),
      SensorModel(id: 'proto-3', uniqueCode: 'SENS-003'),
      SensorModel(id: 'proto-4', uniqueCode: 'SENS-004'),
      SensorModel(id: 'proto-5', uniqueCode: 'SENS-005'),
    ];
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

  // ===================================
  // KHASRA REQUEST METHODS
  // ===================================

  Future<List<KhasraRequestModel>> getPendingKhasraRequests() async {
    try {
      final response = await _dio.get('patwari/khasra-requests/pending');
      if (response.data['success'] == true && response.data['data'] != null) {
        return (response.data['data'] as List)
            .map((e) => KhasraRequestModel.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      print('Pending khasra requests error: $e');
      return [];
    }
  }

  Future<bool> processKhasraRequest({
    required String requestId,
    required String action, // APPROVED, REJECTED
    required String remarks,
  }) async {
    try {
      final response = await _dio.post('patwari/khasra-requests/action', data: {
        'requestId': requestId,
        'action': action,
        'remarks': remarks,
      });
      print('Khasra request action response: ${response.data}');
      return response.data['success'] == true;
    } catch (e) {
      print('Khasra request action error: $e');
      return false;
    }
  }

  // ===================================
  // CLAIM REVIEW METHODS
  // ===================================

  Future<List<ClaimReviewModel>> getPendingClaimReviews() async {
    try {
      final response = await _dio.get('admin/claims');
      if (response.data['success'] == true && response.data['data'] != null) {
        return (response.data['data'] as List)
            .map((e) => ClaimReviewModel.fromJson(e))
            .where((c) => c.status == 'PATWARI_REVIEW')
            .toList();
      }
      return [];
    } catch (e) {
      print('Pending claim reviews error: $e');
      return [];
    }
  }

  Future<bool> processClaimReview({
    required String claimId,
    required String action, // RETRY, REJECT
    required String remarks,
  }) async {
    try {
      final response = await _dio.post('admin/claims/$claimId/review', data: {
        'action': action,
        'comments': remarks,
      });
      print('Claim review action response: ${response.data}');
      return response.data['success'] == true;
    } catch (e) {
      print('Claim review action error: $e');
      return false;
    }
  }
}
