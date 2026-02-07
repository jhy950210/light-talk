class VerifyOtpRequest {
  final String phoneNumber;
  final String code;

  const VerifyOtpRequest({required this.phoneNumber, required this.code});

  Map<String, dynamic> toJson() => {
        'phoneNumber': phoneNumber,
        'code': code,
      };
}
