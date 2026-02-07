class PhoneLoginRequest {
  final String phoneNumber;
  final String password;

  const PhoneLoginRequest({
    required this.phoneNumber,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'phoneNumber': phoneNumber,
        'password': password,
      };
}
