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
    required this.latitude,
    required this.longitude,
  });

  factory InsuranceResponse.fromJson(Map<String, dynamic> json) {
    return InsuranceResponse(
      id: json['id'],
      policyNumber: json['policyNumber'],
      khasraNumber: json['khasraNumber'],
      areaAcres: (json['areaAcres'] as num).toDouble(),
      cropType: json['cropType'],
      premiumAmount: (json['premiumAmount'] as num).toDouble(),
      coverageAmount: (json['coverageAmount'] as num).toDouble(),
      status: json['status'],
      verificationStatus: json['verificationStatus'] ?? 'PENDING',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }
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
