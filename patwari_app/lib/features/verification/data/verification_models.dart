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
      id: json['id'],
      policyNumber: json['policyNumber'],
      farmerName: json['farmerName'],
      farmerPhone: json['farmerPhone'],
      cropType: json['cropType'],
      areaAcres: (json['areaAcres'] as num).toDouble(),
      khasraNumber: json['khasraNumber'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      status: json['status'],
      sensorCode: json['sensorCode'],
    );
  }
}

class SensorModel {
  final String id;
  final String uniqueCode;

  SensorModel({required this.id, required this.uniqueCode});

  factory SensorModel.fromJson(Map<String, dynamic> json) {
    return SensorModel(
      id: json['id'].toString(),
      uniqueCode: json['uniqueCode'],
    );
  }
}
