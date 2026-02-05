class StateModel {
  final int id;
  final String name;
  final String code;

  StateModel({required this.id, required this.name, required this.code});

  factory StateModel.fromJson(Map<String, dynamic> json) {
    return StateModel(
      id: json['id'],
      name: json['name'],
      code: json['code'],
    );
  }
}

class DistrictModel {
  final int id;
  final String name;

  DistrictModel({required this.id, required this.name});

  factory DistrictModel.fromJson(Map<String, dynamic> json) {
    return DistrictModel(
      id: json['id'],
      name: json['name'],
    );
  }
}

class VillageModel {
  final int id;
  final String name;
  final double centerLatitude;
  final double centerLongitude;

  VillageModel({
    required this.id, 
    required this.name, 
    required this.centerLatitude, 
    required this.centerLongitude
  });

  factory VillageModel.fromJson(Map<String, dynamic> json) {
    return VillageModel(
      id: json['id'],
      name: json['name'],
      centerLatitude: json['centerLatitude'] ?? 0.0,
      centerLongitude: json['centerLongitude'] ?? 0.0,
    );
  }
}

class KhasraModel {
  final String id;
  final String khasraNumber;
  final double areaAcres;
  final double latitude;
  final double longitude;
  final bool isAvailable;

  KhasraModel({
    required this.id,
    required this.khasraNumber,
    required this.areaAcres,
    required this.latitude,
    required this.longitude,
    required this.isAvailable,
  });

  factory KhasraModel.fromJson(Map<String, dynamic> json) {
    return KhasraModel(
      id: json['id'],
      khasraNumber: json['khasraNumber'],
      areaAcres: (json['areaAcres'] as num).toDouble(),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      isAvailable: json['isAvailable'] ?? true,
    );
  }
}
