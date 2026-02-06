import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/providers/providers.dart';
import '../data/auth_repository.dart';
import '../data/models/login_request.dart';
import '../data/models/register_request.dart';
import '../data/models/token_response.dart';

// ── Auth State ───────────────────────────────────────────────
class AuthState {
  final bool isLoggedIn;
  final bool isLoading;
  final String? errorMessage;
  final int? userId;
  final String? nickname;

  const AuthState({
    this.isLoggedIn = false,
    this.isLoading = false,
    this.errorMessage,
    this.userId,
    this.nickname,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    bool? isLoading,
    String? errorMessage,
    int? userId,
    String? nickname,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      userId: userId ?? this.userId,
      nickname: nickname ?? this.nickname,
    );
  }
}

// ── Auth Notifier ────────────────────────────────────────────
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final SharedPreferences _prefs;

  AuthNotifier(this._repository, this._prefs) : super(const AuthState()) {
    _loadFromStorage();
  }

  void _loadFromStorage() {
    final token = _prefs.getString(ApiConstants.accessTokenKey);
    final userId = _prefs.getInt(ApiConstants.userIdKey);
    final nickname = _prefs.getString(ApiConstants.userNicknameKey);

    if (token != null && token.isNotEmpty) {
      state = AuthState(
        isLoggedIn: true,
        userId: userId,
        nickname: nickname,
      );
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _repository.login(
        LoginRequest(email: email, password: password),
      );
      await _saveTokens(response);
      state = AuthState(
        isLoggedIn: true,
        userId: response.userId,
        nickname: response.nickname,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _parseError(e),
      );
    }
  }

  Future<void> register(
      String email, String password, String nickname) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _repository.register(
        RegisterRequest(
            email: email, password: password, nickname: nickname),
      );
      await _saveTokens(response);
      state = AuthState(
        isLoggedIn: true,
        userId: response.userId,
        nickname: response.nickname,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _parseError(e),
      );
    }
  }

  Future<void> logout() async {
    final refreshToken = _prefs.getString(ApiConstants.refreshTokenKey) ?? '';
    await _repository.logout(refreshToken);
    await _clearStorage();
    state = const AuthState();
  }

  Future<void> _saveTokens(TokenResponse response) async {
    await _prefs.setString(
        ApiConstants.accessTokenKey, response.accessToken);
    await _prefs.setString(
        ApiConstants.refreshTokenKey, response.refreshToken);
    if (response.userId != 0) {
      await _prefs.setInt(ApiConstants.userIdKey, response.userId);
    }
    if (response.nickname.isNotEmpty) {
      await _prefs.setString(
          ApiConstants.userNicknameKey, response.nickname);
    }
  }

  Future<void> _clearStorage() async {
    await _prefs.remove(ApiConstants.accessTokenKey);
    await _prefs.remove(ApiConstants.refreshTokenKey);
    await _prefs.remove(ApiConstants.userIdKey);
    await _prefs.remove(ApiConstants.userNicknameKey);
  }

  String _parseError(dynamic e) {
    if (e is Exception) {
      final str = e.toString();
      if (str.contains('DioException')) {
        if (str.contains('401')) return 'Invalid email or password.';
        if (str.contains('409')) return 'Email already registered.';
        if (str.contains('connection')) return 'Cannot reach server.';
      }
      return str.replaceFirst('Exception: ', '');
    }
    return 'An unexpected error occurred.';
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

// ── Providers ────────────────────────────────────────────────
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(dioClientProvider));
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.watch(authRepositoryProvider),
    ref.watch(sharedPreferencesProvider),
  );
});
