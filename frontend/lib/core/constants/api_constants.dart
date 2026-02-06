class ApiConstants {
  ApiConstants._();

  // ── Base URLs ──────────────────────────────────────────────
  static const String baseUrl = 'http://localhost:8080';
  static const String wsUrl = 'ws://localhost:8080/ws';

  // ── Auth ───────────────────────────────────────────────────
  static const String login = '/api/v1/auth/login';
  static const String register = '/api/v1/auth/register';
  static const String refresh = '/api/v1/auth/refresh';
  static const String logout = '/api/v1/auth/logout';

  // ── Users ──────────────────────────────────────────────────
  static const String users = '/api/v1/users';
  static const String userSearch = '/api/v1/users/search';
  static const String me = '/api/v1/users/me';

  // ── Friends ────────────────────────────────────────────────
  static const String friends = '/api/v1/friends';
  static const String friendRequests = '/api/v1/friends/requests';

  // ── Chat ───────────────────────────────────────────────────
  static const String chatRooms = '/api/v1/chat/rooms';
  static String chatRoom(int roomId) => '/api/v1/chat/rooms/$roomId';
  static String messages(int roomId) => '/api/v1/chat/rooms/$roomId/messages';
  static String readReceipt(int roomId) =>
      '/api/v1/chat/rooms/$roomId/read';

  // ── STOMP Destinations ─────────────────────────────────────
  static String topicChat(int roomId) => '/topic/chat/$roomId';
  static String queueUser(int userId) => '/queue/user/$userId';
  static const String appChatSend = '/app/chat/send';

  // ── Storage Keys ───────────────────────────────────────────
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  static const String userNicknameKey = 'user_nickname';
}
