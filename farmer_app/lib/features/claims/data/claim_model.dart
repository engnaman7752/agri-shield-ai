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
    this.remarks,
    required this.createdAt,
  });

  factory ClaimModel.fromJson(Map<String, dynamic> json) {
    return ClaimModel(
      id: json['id'],
      insuranceId: json['insuranceId'],
      policyNumber: json['policyNumber'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      status: json['status'],
      damagePercentage: json['damagePercentage'] != null ? (json['damagePercentage'] as num).toDouble() : null,
      estimatedPayout: json['claimAmount'] != null ? (json['claimAmount'] as num).toDouble() : null,
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      remarks: json['diseaseDetected'],
      createdAt: json['filedAt'] ?? '',
    );
  }
}
