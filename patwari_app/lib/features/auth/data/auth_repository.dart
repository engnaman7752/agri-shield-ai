import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:patwari_app/core/constants.dart';
import 'patwari_model.dart';

class AuthRepository {
  final Dio _dio;

  AuthRepository(this._dio);

  Future<(bool, String?)> login(String governmentId, String password) async {
    try {
      final response = await _dio.post('auth/patwari/login', data: {
        'governmentId': governmentId,
        'password': password,
      });

      print('Login response: ${response.data}');

      // AuthResponse is not wrapped in ApiResponse, token is directly in response
      if (response.data['success'] == true) {
        final token = response.data['token'];
        if (token != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(AppConstants.tokenKey, token as String);
          return (true, null);
        } else {
          return (false, 'Token not found in response');
        }
      }
      return (false, (response.data['message'] ?? 'Login failed') as String);
    } catch (e) {
      print('Login error: $e');
      return (false, e.toString());
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
  }

  Future<(bool, String?)> forgotPassword(String phone) async {
    try {
      final response = await _dio.post('auth/patwari/forgot-password', data: {
        'phone': phone,
        'method': 'SMS',
      });
      if (response.data['success'] == true) {
        return (true, null);
      }
      return (false, response.data['message'] as String? ?? 'Failed to send OTP');
    } catch (e) {
      return (false, e.toString());
    }
  }

  Future<(bool, String?)> resetPassword(String phone, String otp, String newPassword) async {
    try {
      final response = await _dio.post('auth/patwari/reset-password', data: {
        'phone': phone,
        'otp': otp,
        'newPassword': newPassword,
      });
      if (response.data['success'] == true) {
        return (true, null);
      }
      return (false, response.data['message'] as String? ?? 'Failed to reset password');
    } catch (e) {
      return (false, e.toString());
    }
  }
}
