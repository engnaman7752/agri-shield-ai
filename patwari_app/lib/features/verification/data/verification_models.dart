class VerificationModel {
  final String id;
  final String policyNumber;
  final String farmerName;
  final String farmerPhone;
  final String cropType;
  final double areaAcres;
  final String khasraNumber;
  final double latitude;
  final double longitude;
  final String status;
  final String? sensorCode;

  VerificationModel({
    required this.id,
    required this.policyNumber,
    required this.farmerName,
    required this.farmerPhone,
    required this.cropType,
    required this.areaAcres,
    required this.khasraNumber,
    required this.latitude,
    required this.longitude,
    required this.status,
    this.sensorCode,
  });

  factory VerificationModel.fromJson(Map<String, dynamic> json) {
    return VerificationModel(
      id: json['verificationId']?.toString() ?? json['id']?.toString() ?? '',
      policyNumber: json['policyNumber']?.toString() ?? '',
      farmerName: json['farmerName']?.toString() ?? 'Unknown',
      farmerPhone: json['farmerPhone']?.toString() ?? '',
      cropType: json['cropType']?.toString() ?? 'Unknown',
      areaAcres: (json['areaAcres'] as num?)?.toDouble() ?? 0.0,
      khasraNumber: json['khasraNumber']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      status: json['status']?.toString() ?? 'PENDING',
      sensorCode: json['sensorCode']?.toString(),
    );
  }
}

class SensorModel {
  final String id;
  final String uniqueCode;

  SensorModel({required this.id, required this.uniqueCode});

  factory SensorModel.fromJson(Map<String, dynamic> json) {
    return SensorModel(
      id: json['id']?.toString() ?? '',
      uniqueCode: json['uniqueCode']?.toString() ?? '',
    );
  }
}

class KhasraRequestModel {
  final String id;
  final String farmerName;
  final String farmerPhone;
  final String village;
  final String khasraNumber;
  final double areaAcres;
  final double latitude;
  final double longitude;
  final String status;
  final String? patwariRemarks;

  KhasraRequestModel({
    required this.id,
    required this.farmerName,
    required this.farmerPhone,
    required this.village,
    required this.khasraNumber,
    required this.areaAcres,
    required this.latitude,
    required this.longitude,
    required this.status,
    this.patwariRemarks,
  });

  factory KhasraRequestModel.fromJson(Map<String, dynamic> json) {
    return KhasraRequestModel(
      id: json['id']?.toString() ?? '',
      farmerName: json['farmerName']?.toString() ?? 'Unknown',
      farmerPhone: json['farmerPhone']?.toString() ?? '',
      village: json['village']?.toString() ?? '',
      khasraNumber: json['khasraNumber']?.toString() ?? '',
      areaAcres: (json['areaAcres'] as num?)?.toDouble() ?? 0.0,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      status: json['status']?.toString() ?? 'PENDING',
      patwariRemarks: json['patwariRemarks']?.toString(),
    );
  }
}

class ClaimReviewModel {
  final String id;
  final String policyNumber;
  final String farmerName;
  final String farmerPhone;
  final String village;
  final String khasraNumber;
  final String diseaseDetected;
  final double damagePercentage;
  final double claimAmount;
  final List<String> imageUrls;
  final String status;
  final DateTime filedAt;

  ClaimReviewModel({
    required this.id,
    required this.policyNumber,
    required this.farmerName,
    required this.farmerPhone,
    required this.village,
    required this.khasraNumber,
    required this.diseaseDetected,
    required this.damagePercentage,
    required this.claimAmount,
    required this.imageUrls,
    required this.status,
    required this.filedAt,
  });

  factory ClaimReviewModel.fromJson(Map<String, dynamic> json) {
    return ClaimReviewModel(
      id: json['id']?.toString() ?? '',
      policyNumber: json['policyNumber']?.toString() ?? '',
      farmerName: json['farmerName']?.toString() ?? 'Unknown',
      farmerPhone: json['farmerPhone']?.toString() ?? '',
      village: json['village']?.toString() ?? '',
      khasraNumber: json['khasraNumber']?.toString() ?? '',
      diseaseDetected: json['diseaseDetected']?.toString() ?? 'None',
      damagePercentage: (json['damagePercentage'] as num?)?.toDouble() ?? 0.0,
      claimAmount: (json['claimAmount'] as num?)?.toDouble() ?? 0.0,
      imageUrls: (json['imageUrls'] as List?)?.map((e) => e.toString()).toList() ?? [],
      status: json['status']?.toString() ?? '',
      filedAt: json['filedAt'] != null ? DateTime.parse(json['filedAt']) : DateTime.now(),
    );
  }
}
