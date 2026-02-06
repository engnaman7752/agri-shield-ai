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
