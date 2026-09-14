class InsuranceApplicationRequest {
  final String khasraNumber;
  final String cropType;
  final double areaAcres;
  final double latitude;
  final double longitude;

  InsuranceApplicationRequest({
    required this.khasraNumber,
    required this.cropType,
    required this.areaAcres,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toJson() => {
    'khasraNumber': khasraNumber,
    'cropType': cropType,
    'areaAcres': areaAcres,
    'latitude': latitude,
    'longitude': longitude,
  };
}

class InsuranceResponse {
  final String id;
  final String policyNumber;
  final String khasraNumber;
  final double areaAcres;
  final String cropType;
  final double premiumAmount;
  final double coverageAmount;
  final String status;
  final String verificationStatus;
  final String? verificationRemarks;
  final double latitude;
  final double longitude;

  InsuranceResponse({
    required this.id,
    required this.policyNumber,
    required this.khasraNumber,
    required this.areaAcres,
    required this.cropType,
    required this.premiumAmount,
    required this.coverageAmount,
    required this.status,
    required this.verificationStatus,
    this.verificationRemarks,
    required this.latitude,
    required this.longitude,
  });

  factory InsuranceResponse.fromJson(Map<String, dynamic> json) {
    return InsuranceResponse(
      id: json['id']?.toString() ?? '',
      policyNumber: json['policyNumber']?.toString() ?? '',
      khasraNumber: json['khasraNumber']?.toString() ?? '',
      areaAcres: (json['areaAcres'] as num?)?.toDouble() ?? 0.0,
      cropType: json['cropType']?.toString() ?? '',
      premiumAmount: (json['premiumAmount'] as num?)?.toDouble() ?? 0.0,
      coverageAmount: (json['coverageAmount'] as num?)?.toDouble() ?? 0.0,
      status: json['status']?.toString() ?? 'PENDING',
      verificationStatus: json['verificationStatus']?.toString() ?? 'PENDING',
      verificationRemarks: json['verificationRemarks']?.toString(),
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }

  bool get isRejected => verificationStatus == 'REJECTED';
  bool get isApproved => verificationStatus == 'APPROVED';
  bool get isPending => verificationStatus == 'PENDING';
}

class PaymentOrderResponse {
  final String orderId;
  final String insuranceId;
  final double amount;
  final String currency;
  final String razorpayKeyId;

  PaymentOrderResponse({
    required this.orderId,
    required this.insuranceId,
    required this.amount,
    required this.currency,
    required this.razorpayKeyId,
  });

  factory PaymentOrderResponse.fromJson(Map<String, dynamic> json) {
    return PaymentOrderResponse(
      orderId: json['orderId'],
      insuranceId: json['insuranceId'],
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'],
      razorpayKeyId: json['razorpayKeyId'],
    );
  }
}
