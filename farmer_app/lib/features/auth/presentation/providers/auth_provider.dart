import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:farmer_app/core/network/dio_client.dart';
import 'package:farmer_app/features/auth/data/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:farmer_app/core/constants/app_constants.dart';
import 'package:farmer_app/features/auth/data/auth_models.dart';

final dioClientProvider = Provider((ref) => DioClient());

final authRepositoryProvider = Provider((ref) {
  final dio = ref.watch(dioClientProvider).dio;
  return AuthRepository(dio);
});

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthResponse?>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});

class AuthNotifier extends StateNotifier<AuthResponse?> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(null);

  Future<OtpResponse> sendOtp(String phone) async {
    return await _repository.sendOtp(phone);
  }

  Future<AuthResponse> verifyOtp(String phone, String otp) async {
    final response = await _repository.verifyOtp(phone, otp);
    if (response.success && response.token != null) {
      state = response;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.tokenKey, response.token!);
      if (response.refreshToken != null) {
        await prefs.setString(AppConstants.refreshTokenKey, response.refreshToken!);
      }
    }
    return response;
  }
  
  Future<void> logout() async {
    state = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.refreshTokenKey);
  }
}
