import 'package:dio/dio.dart';
import 'package:farmer_app/core/models/location_models.dart';

class LocationRepository {
  final Dio _dio;

  LocationRepository(this._dio);

  Future<List<StateModel>> getStates() async {
    try {
      final response = await _dio.get('location/states');
      if (response.data['success']) {
        return (response.data['data'] as List)
            .map((e) => StateModel.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<DistrictModel>> getDistricts(int stateId) async {
    try {
      final response = await _dio.get('location/districts/$stateId');
      if (response.data['success']) {
        return (response.data['data'] as List)
            .map((e) => DistrictModel.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<VillageModel>> getVillages(int districtId) async {
    try {
      final response = await _dio.get('location/villages/$districtId');
      if (response.data['success']) {
        return (response.data['data'] as List)
            .map((e) => VillageModel.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<KhasraModel>> getAvailableKhasra(String state, String district, String village) async {
    try {
      final response = await _dio.get('location/khasra/available', queryParameters: {
        'state': state,
        'district': district,
        'village': village,
      });
      if (response.data['success']) {
        return (response.data['data'] as List)
            .map((e) => KhasraModel.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
