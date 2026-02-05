import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:farmer_app/core/models/location_models.dart';
import 'package:farmer_app/core/network/location_repository.dart';
import 'package:farmer_app/features/auth/presentation/providers/auth_provider.dart';

final locationRepositoryProvider = Provider((ref) {
  final dio = ref.watch(dioClientProvider).dio;
  return LocationRepository(dio);
});

final statesProvider = FutureProvider<List<StateModel>>((ref) async {
  return ref.watch(locationRepositoryProvider).getStates();
});

final districtsProvider = FutureProvider.family<List<DistrictModel>, int>((ref, stateId) async {
  return ref.watch(locationRepositoryProvider).getDistricts(stateId);
});

final villagesProvider = FutureProvider.family<List<VillageModel>, int>((ref, districtId) async {
  return ref.watch(locationRepositoryProvider).getVillages(districtId);
});

final availableKhasraProvider = FutureProvider.family<List<KhasraModel>, ({String state, String district, String village})>((ref, loc) async {
  return ref.watch(locationRepositoryProvider).getAvailableKhasra(loc.state, loc.district, loc.village);
});
