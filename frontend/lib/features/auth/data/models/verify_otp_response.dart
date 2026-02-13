class VerifyOtpResponse {
  final String verificationToken;
  final bool isNewUser;

  const VerifyOtpResponse({
    required this.verificationToken,
    required this.isNewUser,
  });

  factory VerifyOtpResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return VerifyOtpResponse(
      verificationToken: data['verificationToken'] as String,
      isNewUser: (data['isNewUser'] ?? data['newUser'] ?? false) as bool,
    );
  }
}
