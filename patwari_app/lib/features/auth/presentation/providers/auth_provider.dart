import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patwari_app/core/providers.dart';
import 'package:patwari_app/features/auth/data/auth_repository.dart';

final authRepositoryProvider = Provider((ref) {
  final dio = ref.watch(dioClientProvider).dio;
  return AuthRepository(dio);
});

final authStateProvider = StateNotifierProvider<AuthNotifier, AsyncValue<bool>>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});

class AuthNotifier extends StateNotifier<AsyncValue<bool>> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AsyncValue.data(false));

  Future<bool> login(String governmentId, String password) async {
    state = const AsyncValue.loading();
    final result = await _repository.login(governmentId, password);
    if (result.$1) {
      state = const AsyncValue.data(true);
      return true;
    } else {
      state = AsyncValue.error(result.$2 ?? 'Login failed', StackTrace.current);
      return false;
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AsyncValue.data(false);
  }
}
