class FarmerProfileModel {
  final String id;
  final String name;
  final String phone;
  final String address;
  final String state;
  final String district;
  final String village;
  final String? profileImage;
  final int totalLands;
  final int activeInsurances;
  final int pendingClaims;
  final int unreadNotifications;
  final String? accountHolderName;
  final String? bankName;
  final String? accountNumber;
  final String? ifscCode;

  FarmerProfileModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.state,
    required this.district,
    required this.village,
    this.profileImage,
    this.totalLands = 0,
    this.activeInsurances = 0,
    this.pendingClaims = 0,
    this.unreadNotifications = 0,
    this.accountHolderName,
    this.bankName,
    this.accountNumber,
    this.ifscCode,
  });

  factory FarmerProfileModel.fromJson(Map<String, dynamic> json) {
    return FarmerProfileModel(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      address: json['address'],
      state: json['state'],
      district: json['district'],
      village: json['village'],
      profileImage: json['profileImage'],
      totalLands: json['totalLands'] ?? 0,
      activeInsurances: json['activeInsurances'] ?? 0,
      pendingClaims: json['pendingClaims'] ?? 0,
      unreadNotifications: json['unreadNotifications'] ?? 0,
      accountHolderName: json['accountHolderName'],
      bankName: json['bankName'],
      accountNumber: json['accountNumber'],
      ifscCode: json['ifscCode'],
    );
  }
}
