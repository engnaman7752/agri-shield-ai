class AuthResponse {
  final bool success;
  final String? token;
  final String? refreshToken;
  final String? role;
  final String? message;
  final bool requiresRegistration;
  final String? phone;

  AuthResponse({
    required this.success,
    this.token,
    this.refreshToken,
    this.role,
    this.message,
    this.requiresRegistration = false,
    this.phone,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      success: json['success'] ?? false,
      token: json['token'],
      refreshToken: json['refreshToken'],
      role: json['role'],
      message: json['message'],
      requiresRegistration: json['requiresRegistration'] ?? false,
      phone: json['phone'],
    );
  }
}

class OtpResponse {
  final bool success;
  final String? message;
  final String? debugOtp; // For demo only

  OtpResponse({required this.success, this.message, this.debugOtp});

  factory OtpResponse.fromJson(Map<String, dynamic> json) {
    return OtpResponse(
      success: json['success'] ?? false,
      message: json['message'],
      debugOtp: json['debugOtp'],
    );
  }
}
