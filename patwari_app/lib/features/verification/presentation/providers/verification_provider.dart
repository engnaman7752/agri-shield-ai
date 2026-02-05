import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patwari_app/core/providers.dart';
import 'package:patwari_app/features/verification/data/verification_models.dart';
import 'package:patwari_app/features/verification/data/verification_repository.dart';

final verificationRepositoryProvider = Provider((ref) {
  final dio = ref.watch(dioClientProvider).dio;
  return VerificationRepository(dio);
});

final pendingVerificationsProvider = FutureProvider<List<VerificationModel>>((ref) async {
  return ref.watch(verificationRepositoryProvider).getPendingVerifications();
});

final availableSensorsProvider = FutureProvider<List<SensorModel>>((ref) async {
  return ref.read(verificationRepositoryProvider).getAvailableSensors();
});

final patwariStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.read(verificationRepositoryProvider).getDashboardStats();
});
