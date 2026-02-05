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

  Future<PaymentOrderResponse?> applyForInsurance(InsuranceApplicationRequest request) async {
    try {
      final response = await _dio.post('insurance/apply', data: request.toJson());
      if (response.data['success']) {
        return PaymentOrderResponse.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> confirmPayment({
    required String razorpayPaymentId,
    required String razorpayOrderId,
    required String razorpaySignature,
  }) async {
    try {
      final response = await _dio.post('insurance/payment/confirm', data: {
        'razorpayPaymentId': razorpayPaymentId,
        'razorpayOrderId': razorpayOrderId,
        'razorpaySignature': razorpaySignature,
      });
      return response.data['success'];
    } catch (e) {
      return false;
    }
  }

  Future<List<InsuranceResponse>> getMyPolicies() async {
    try {
      final response = await _dio.get('insurance/my-policies');
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
}
