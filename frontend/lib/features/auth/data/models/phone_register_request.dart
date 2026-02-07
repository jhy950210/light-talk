class PhoneRegisterRequest {
  final String verificationToken;
  final String password;
  final String nickname;

  const PhoneRegisterRequest({
    required this.verificationToken,
    required this.password,
    required this.nickname,
  });

  Map<String, dynamic> toJson() => {
        'verificationToken': verificationToken,
        'password': password,
        'nickname': nickname,
      };
}
