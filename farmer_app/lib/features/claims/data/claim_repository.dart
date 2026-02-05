import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:farmer_app/core/services/notification_service.dart';
import 'claim_model.dart';

class ClaimRepository {
  final Dio _dio;

  ClaimRepository(this._dio);

  Future<ClaimModel?> fileClaim({
    required String insuranceId,
    required double latitude,
    required double longitude,
    required List<XFile> images,
  }) async {
    try {
      final List<MultipartFile> multipartImages = [];
      for (var image in images) {
        multipartImages.add(await MultipartFile.fromFile(image.path, filename: image.name));
      }

      final formData = FormData.fromMap({
        'insuranceId': insuranceId,
        'latitude': latitude,
        'longitude': longitude,
        'images': multipartImages,
      });

      final response = await _dio.post(
        'claims',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      if (response.data['success']) {
        final claim = ClaimModel.fromJson(response.data['data']);
        
        // Trigger notification for claim status
        await NotificationService().showClaimStatusNotification(
          claimId: claim.id,
          status: claim.status,
          diseaseDetected: claim.diseaseDetected,
          damagePercentage: claim.damagePercentage,
        );
        
        return claim;
      }
      return null;
    } catch (e) {
      print('❌ ERROR filing claim: $e');
      if (e is DioException) {
        print('Dio error: ${e.response?.data}');
      }
      rethrow;
    }
  }

  Future<List<ClaimModel>> getMyClaims() async {
    try {
      final response = await _dio.get('claims/my-claims');
      if (response.data['success']) {
        return (response.data['data'] as List)
            .map((e) => ClaimModel.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      print('❌ ERROR fetching claims: $e');
      return [];
    }
  }
}
