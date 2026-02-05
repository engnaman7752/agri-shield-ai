import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:farmer_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:farmer_app/features/profile/data/profile_repository.dart';
import 'package:farmer_app/features/auth/data/auth_models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:farmer_app/core/constants/app_constants.dart';

import 'package:farmer_app/features/profile/data/profile_model.dart';

final profileRepositoryProvider = Provider((ref) {
  final dio = ref.watch(dioClientProvider).dio;
  return ProfileRepository(dio);
});

final userProfileProvider = FutureProvider<FarmerProfileModel?>((ref) async {
  return ref.watch(profileRepositoryProvider).getProfile();
});

final profileProvider = StateNotifierProvider<ProfileNotifier, AsyncValue<AuthResponse?>>((ref) {
  return ProfileNotifier(ref.watch(profileRepositoryProvider), ref);
});

class ProfileNotifier extends StateNotifier<AsyncValue<AuthResponse?>> {
  final ProfileRepository _repository;
  final Ref _ref;

  ProfileNotifier(this._repository, this._ref) : super(const AsyncValue.data(null));

  Future<void> register({
    required String phone,
    required String name,
    required String address,
    required String stateRegion,
    required String district,
    required String village,
  }) async {
    state = const AsyncValue.loading();
    try {
      final response = await _repository.registerFarmer(
        phone: phone,
        name: name,
        address: address,
        state: stateRegion,
        district: district,
        village: village,
      );
      
      if (response.success && response.token != null) {
        state = AsyncValue.data(response);
        // Update global auth state
        _ref.read(authStateProvider.notifier).state = response;
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.tokenKey, response.token!);
      } else {
        state = AsyncValue.error(response.message ?? 'Registration failed', StackTrace.current);
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}
