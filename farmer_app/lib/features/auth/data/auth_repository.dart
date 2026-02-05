import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:farmer_app/core/network/dio_client.dart';
import 'auth_models.dart';

class AuthRepository {
  final Dio _dio;

  AuthRepository(this._dio);

  Future<OtpResponse> sendOtp(String phone) async {
    final url = '${_dio.options.baseUrl}auth/farmer/send-otp';
    debugPrint('Sending OTP to: $url with phone: $phone');
    try {
      final response = await _dio.post('auth/farmer/send-otp', data: {'phone': phone});
      debugPrint('OTP Response: ${response.data}');
      return OtpResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('ERROR sending OTP to $url: $e');
      if (e is DioException) {
        debugPrint('Dio Error details: ${e.message} - ${e.response?.data}');
      }
      return OtpResponse(success: false, message: 'Connection Error: $e');
    }
  }

  Future<AuthResponse> verifyOtp(String phone, String otp) async {
    try {
      final response = await _dio.post('auth/farmer/verify-otp', data: {
        'phone': phone,
        'otp': otp,
      });
      return AuthResponse.fromJson(response.data);
    } catch (e) {
      return AuthResponse(success: false, message: 'Authentication Failed');
    }
  }
}
