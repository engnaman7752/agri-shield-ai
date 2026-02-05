class CropModel {
  final int id;
  final String name;
  final String nameHindi;
  final String season;
  final double premiumRate;
  final double maxCoverage;

  CropModel({
    required this.id,
    required this.name,
    required this.nameHindi,
    required this.season,
    required this.premiumRate,
    required this.maxCoverage,
  });

  factory CropModel.fromJson(Map<String, dynamic> json) {
    return CropModel(
      id: json['id'],
      name: json['name'],
      nameHindi: json['nameHindi'],
      season: json['season'],
      premiumRate: (json['premiumRate'] as num).toDouble(),
      maxCoverage: (json['maxCoverage'] as num).toDouble(),
    );
  }
}
