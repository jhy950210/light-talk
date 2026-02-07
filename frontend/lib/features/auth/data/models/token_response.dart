class TokenResponse {
  final String accessToken;
  final String refreshToken;
  final int userId;
  final String nickname;
  final String tag;

  const TokenResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.nickname,
    required this.tag,
  });

  factory TokenResponse.fromJson(Map<String, dynamic> json) {
    // Handle both wrapped {"data": {...}} and flat response
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return TokenResponse(
      accessToken: data['accessToken'] as String? ?? '',
      refreshToken: data['refreshToken'] as String? ?? '',
      userId: data['userId'] as int? ?? 0,
      nickname: data['nickname'] as String? ?? '',
      tag: data['tag'] as String? ?? '',
    );
  }
}
