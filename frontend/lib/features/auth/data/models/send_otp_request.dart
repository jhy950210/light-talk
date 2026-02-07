class SendOtpRequest {
  final String phoneNumber;

  const SendOtpRequest({required this.phoneNumber});

  Map<String, dynamic> toJson() => {'phoneNumber': phoneNumber};
}
