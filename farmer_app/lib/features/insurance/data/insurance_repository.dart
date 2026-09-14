import 'package:dio/dio.dart';
import 'crop_model.dart';
import 'insurance_models.dart';

class InsuranceRepository {
  final Dio _dio;

  InsuranceRepository(this._dio);

  Future<List<CropModel>> getCrops() async {
    try {
      final response = await _dio.get('location/crops');
      if (response.data['success']) {
        return (response.data['data'] as List)
            .map((e) => CropModel.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<PaymentOrderResponse?> applyForInsurance(
    InsuranceApplicationRequest request,
  ) async {
    try {
      final response = await _dio.post(
        'insurance/apply',
        data: request.toJson(),
      );
      if (response.data['success']) {
        return PaymentOrderResponse.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Confirms payment with retry logic.
  /// Returns a record: (success: bool, errorMessage: String?)
  Future<({bool success, String? errorMessage})> confirmPayment({
    required String insuranceId,
    required String razorpayPaymentId,
    required String razorpayOrderId,
    required String razorpaySignature,
  }) async {
    const maxRetries = 3;
    const initialDelayMs = 800; // Wait for network readiness after Razorpay

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        // Small delay before first attempt to let network stabilize
        // after returning from Razorpay's native activity
        if (attempt == 1) {
          await Future.delayed(const Duration(milliseconds: initialDelayMs));
        } else {
          // Exponential backoff for retries
          await Future.delayed(Duration(milliseconds: initialDelayMs * attempt));
        }

        print('🔄 PAYMENT CONFIRMATION (Attempt $attempt/$maxRetries)');
        print('Insurance ID: $insuranceId');
        print('Order ID: $razorpayOrderId');
        print('Payment ID: $razorpayPaymentId');

        final response = await _dio.post(
          'insurance/payment/confirm',
          data: {
            'insuranceId': insuranceId,
            'razorpayPaymentId': razorpayPaymentId,
            'razorpayOrderId': razorpayOrderId,
            'razorpaySignature': razorpaySignature,
          },
        );

        print('✅ Response received');
        print('Status Code: ${response.statusCode}');
        print('Response Body: ${response.data}');

        final bool success = response.data['success'] ?? false;
        final String message = (response.data['message'] ?? '').toString();
        final String errorMsg = (response.data['error'] ?? '').toString();

        print('Success: $success');
        print('Message: $message');
        if (errorMsg.isNotEmpty) print('Error Details: $errorMsg');

        if (success) {
          print('✓ Payment confirmed successfully on attempt $attempt');
          return (success: true, errorMessage: null as String?);
        } else {
          print('❌ Confirmation failed: $errorMsg');
          if (attempt == maxRetries) {
            final String msg = errorMsg.isNotEmpty ? errorMsg : message;
            return (success: false, errorMessage: msg as String?);
          }
          // Retry on non-success response
        }
      } on DioException catch (e) {
        print('❌ DIO EXCEPTION (Attempt $attempt/$maxRetries)');
        print('Status Code: ${e.response?.statusCode}');
        print('Error Message: ${e.message}');
        print('Response Data: ${e.response?.data}');
        print('Request Path: ${e.requestOptions.path}');

        if (attempt == maxRetries) {
          final serverError = e.response?.data;
          String errMsg = e.message ?? 'Network error';
          if (serverError is Map) {
            errMsg = serverError['error']?.toString() ??
                serverError['message']?.toString() ??
                errMsg;
          }
          return (success: false, errorMessage: errMsg);
        }
        // Retry on DioException (network issues)
      } catch (e, stackTrace) {
        print('❌ UNEXPECTED ERROR (Attempt $attempt/$maxRetries): $e');
        print('Stack Trace: $stackTrace');
        if (attempt == maxRetries) {
          return (success: false, errorMessage: e.toString());
        }
      }
    }
    return (success: false, errorMessage: 'Max retries exceeded');
  }

  Future<List<InsuranceResponse>> getMyPolicies() async {
    try {
      final response = await _dio.get('insurance/my-policies');
      print('--- getMyPolicies Response: ${response.data}');
      if (response.data['success']) {
        return (response.data['data'] as List)
            .map((e) => InsuranceResponse.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      print('--- getMyPolicies ERROR: $e');
      if (e is DioException) {
         print('--- DIO ERROR DATA: ${e.response?.data}');
      }
      return [];
    }
  }

  Future<List<InsuranceResponse>> getActivePolicies() async {
    try {
      final response = await _dio.get('insurance/active');
      if (response.data['success']) {
        return (response.data['data'] as List)
            .map((e) => InsuranceResponse.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Submit a khasra request for Patwari verification
  Future<bool> submitKhasraRequest({
    required String village,
    required String khasraNumber,
    required double areaAcres,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _dio.post(
        'farmer/khasra-request',
        data: {
          'village': village,
          'khasraNumber': khasraNumber,
          'areaAcres': areaAcres,
          'latitude': latitude,
          'longitude': longitude,
        },
      );
      return response.data['success'] == true;
    } catch (e) {
      print('Khasra request error: $e');
      return false;
    }
  }

  /// Get payment order for retrying PENDING policy
  Future<PaymentOrderResponse?> retryPayment(String policyId) async {
    try {
      print('🔄 Requesting retry payment for policy: $policyId');
      final response = await _dio.post('insurance/$policyId/retry-payment');
      if (response.data['success']) {
        return PaymentOrderResponse.fromJson(response.data['data']);
      }
      print('❌ Retry failed: ${response.data['error']}');
      return null;
    } catch (e) {
      print('Retry payment error: $e');
      return null;
    }
  }

  /// Cancel a PENDING policy (payment failed)
  Future<bool> cancelPolicy(String policyId) async {
    try {
      final response = await _dio.delete('insurance/$policyId');
      return response.data['success'] == true;
    } catch (e) {
      print('Cancel policy error: $e');
      return false;
    }
  }
}
