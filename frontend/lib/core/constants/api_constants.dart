class ApiConstants {
  ApiConstants._();

  // ── Base URLs ──────────────────────────────────────────────
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://backend-production-4335.up.railway.app',
  );
  static const String wsUrl = String.fromEnvironment(
    'WS_URL',
    defaultValue: 'wss://backend-production-4335.up.railway.app/ws/raw',
  );
  static const String wsUrlSockJS = String.fromEnvironment(
    'WS_URL_SOCKJS',
    defaultValue: 'https://backend-production-4335.up.railway.app/ws',
  );

  // ── Auth ───────────────────────────────────────────────────
  static const String login = '/api/v1/auth/login';
  static const String register = '/api/v1/auth/register';
  static const String refresh = '/api/v1/auth/refresh';
  static const String logout = '/api/v1/auth/logout';

  // ── Phone Auth ────────────────────────────────────────────
  static const String sendOtp = '/api/v1/auth/send-otp';
  static const String verifyOtp = '/api/v1/auth/verify-otp';
  static const String phoneRegister = '/api/v1/auth/phone/register';
  static const String phoneLogin = '/api/v1/auth/phone/login';

  // ── Users ──────────────────────────────────────────────────
  static const String users = '/api/v1/users';
  static const String userSearch = '/api/v1/users/search';
  static const String me = '/api/v1/users/me';

  // ── Friends ────────────────────────────────────────────────
  static const String friends = '/api/v1/friends';
  static const String friendsPending = '/api/v1/friends/pending';

  // ── Chat ───────────────────────────────────────────────────
  static const String chats = '/api/v1/chats';
  static const String chatsGroup = '/api/v1/chats/group';
  static String chatRoom(int roomId) => '/api/v1/chats/$roomId';
  static String messages(int roomId) => '/api/v1/chats/$roomId/messages';
  static String readReceipt(int roomId) =>
      '/api/v1/chats/$roomId/read';
  static String deleteMessage(int roomId, int messageId) =>
      '/api/v1/chats/$roomId/messages/$messageId';

  // ── Chat Members (Group) ───────────────────────────────────────
  static String chatMembers(int roomId) => '/api/v1/chats/$roomId/members';
  static String chatMember(int roomId, int userId) =>
      '/api/v1/chats/$roomId/members/$userId';
  static String chatLeave(int roomId) => '/api/v1/chats/$roomId/leave';

  // ── FCM Token ────────────────────────────────────────────────
  static const String fcmToken = '/api/v1/users/me/fcm-token';

  // ── Upload ────────────────────────────────────────────────────
  static const String presignUpload = '/api/v1/upload/presign';

  // ── Users (account) ─────────────────────────────────────────
  static const String withdrawUser = '/api/v1/users/me';

  // ── STOMP Destinations ─────────────────────────────────────
  static String topicChat(int roomId) => '/topic/chat/$roomId';
  static String queueUser(int userId) => '/queue/user/$userId';
  static String appChatSend(int roomId) => '/app/chat/$roomId/send';

  // ── Storage Keys ───────────────────────────────────────────
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  static const String userNicknameKey = 'user_nickname';
  static const String userTagKey = 'user_tag';
}
