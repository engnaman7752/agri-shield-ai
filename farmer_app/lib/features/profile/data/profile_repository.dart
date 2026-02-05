import 'package:dio/dio.dart';
import 'package:farmer_app/features/auth/data/auth_models.dart';
import 'package:farmer_app/features/profile/data/profile_model.dart';

class ProfileRepository {
  final Dio _dio;

  ProfileRepository(this._dio);

  Future<AuthResponse> registerFarmer({
    required String phone,
    required String name,
    required String address,
    required String state,
    required String district,
    required String village,
  }) async {
    try {
      final response = await _dio.post('auth/farmer/register', data: {
        'phone': phone,
        'name': name,
        'address': address,
        'state': state,
        'district': district,
        'village': village,
      });
      return AuthResponse.fromJson(response.data);
    } catch (e) {
      return AuthResponse(success: false, message: 'Registration failed');
    }
  }

  Future<FarmerProfileModel?> getProfile() async {
    try {
      final response = await _dio.get('farmer/profile');
      if (response.data['success']) {
        return FarmerProfileModel.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateProfile({
    required String name,
    required String address,
    required String state,
    required String district,
    required String village,
    String? accountHolderName,
    String? bankName,
    String? accountNumber,
    String? ifscCode,
  }) async {
    try {
      final response = await _dio.put('farmer/profile', data: {
        'name': name,
        'address': address,
        'state': state,
        'district': district,
        'village': village,
        'accountHolderName': accountHolderName,
        'bankName': bankName,
        'accountNumber': accountNumber,
        'ifscCode': ifscCode,
      });
      return response.data['success'];
    } catch (e) {
      return false;
    }
  }
}
