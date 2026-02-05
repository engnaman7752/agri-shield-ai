class PatwariModel {
  final String id;
  final String governmentId;
  final String name;
  final String phone;
  final String assignedArea;

  PatwariModel({
    required this.id,
    required this.governmentId,
    required this.name,
    required this.phone,
    required this.assignedArea,
  });

  factory PatwariModel.fromJson(Map<String, dynamic> json) {
    return PatwariModel(
      id: json['id'],
      governmentId: json['governmentId'],
      name: json['name'],
      phone: json['phone'],
      assignedArea: json['assignedArea'] ?? '',
    );
  }
}
