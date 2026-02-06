class ClaimModel {
  final String id;
  final String insuranceId;
  final String policyNumber;
  final double latitude;
  final double longitude;
  final String status;
  final double? damagePercentage;
  final double? estimatedPayout;
  final List<String> imageUrls;
  final String? diseaseDetected;
  final String? remarks;
  final String createdAt;

  ClaimModel({
    required this.id,
    required this.insuranceId,
    required this.policyNumber,
    required this.latitude,
    required this.longitude,
    required this.status,
    this.damagePercentage,
    this.estimatedPayout,
    required this.imageUrls,
    this.diseaseDetected,
    this.remarks,
    required this.createdAt,
  });

  factory ClaimModel.fromJson(Map<String, dynamic> json) {
    return ClaimModel(
      id: json['id']?.toString() ?? '',
      insuranceId: json['insuranceId']?.toString() ?? '',
      policyNumber: json['policyNumber']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      status: json['status']?.toString() ?? 'PENDING',
      damagePercentage: json['damagePercentage'] != null ? (json['damagePercentage'] as num).toDouble() : null,
      estimatedPayout: json['claimAmount'] != null ? (json['claimAmount'] as num).toDouble() : null,
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      diseaseDetected: json['diseaseDetected']?.toString(),
      remarks: json['remarks']?.toString(),
      createdAt: json['filedAt']?.toString() ?? '',
    );
  }
}
