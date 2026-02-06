class RegisterRequest {
  final String email;
  final String password;
  final String nickname;

  const RegisterRequest({
    required this.email,
    required this.password,
    required this.nickname,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
        'nickname': nickname,
      };
}
