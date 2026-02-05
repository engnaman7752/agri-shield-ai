import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:farmer_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:farmer_app/features/claims/data/claim_repository.dart';
import 'package:farmer_app/features/claims/data/claim_model.dart';
import 'package:image_picker/image_picker.dart';

final claimRepositoryProvider = Provider((ref) {
  final dio = ref.watch(dioClientProvider).dio;
  return ClaimRepository(dio);
});

final myClaimsProvider = FutureProvider<List<ClaimModel>>((ref) async {
  return ref.watch(claimRepositoryProvider).getMyClaims();
});

final claimSubmissionProvider = StateNotifierProvider<ClaimNotifier, AsyncValue<ClaimModel?>>((ref) {
  return ClaimNotifier(ref.watch(claimRepositoryProvider), ref);
});

class ClaimNotifier extends StateNotifier<AsyncValue<ClaimModel?>> {
  final ClaimRepository _repository;
  final Ref _ref;

  ClaimNotifier(this._repository, this._ref) : super(const AsyncValue.data(null));

  Future<void> fileClaim({
    required String insuranceId,
    required double latitude,
    required double longitude,
    required List<XFile> images,
  }) async {
    state = const AsyncValue.loading();
    try {
      final response = await _repository.fileClaim(
        insuranceId: insuranceId,
        latitude: latitude,
        longitude: longitude,
        images: images,
      );
      if (response != null) {
        state = AsyncValue.data(response);
        // Refresh claims list
        _ref.invalidate(myClaimsProvider);
      } else {
        state = AsyncValue.error('Claim filing failed', StackTrace.current);
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}
