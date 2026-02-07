import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/providers/providers.dart';
import '../data/auth_repository.dart';
import '../data/models/login_request.dart';
import '../data/models/phone_login_request.dart';
import '../data/models/phone_register_request.dart';
import '../data/models/register_request.dart';
import '../data/models/send_otp_request.dart';
import '../data/models/token_response.dart';
import '../data/models/verify_otp_request.dart';

// ── Auth State ───────────────────────────────────────────────
class AuthState {
  final bool isLoggedIn;
  final bool isLoading;
  final String? errorMessage;
  final int? userId;
  final String? nickname;
  final String? tag;
  // Phone auth flow state
  final String? phoneNumber;
  final bool otpSent;
  final int otpExpiresIn;
  final String? verificationToken;
  final bool isNewUser;

  const AuthState({
    this.isLoggedIn = false,
    this.isLoading = false,
    this.errorMessage,
    this.userId,
    this.nickname,
    this.tag,
    this.phoneNumber,
    this.otpSent = false,
    this.otpExpiresIn = 0,
    this.verificationToken,
    this.isNewUser = false,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    bool? isLoading,
    String? errorMessage,
    int? userId,
    String? nickname,
    String? tag,
    String? phoneNumber,
    bool? otpSent,
    int? otpExpiresIn,
    String? verificationToken,
    bool? isNewUser,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      userId: userId ?? this.userId,
      nickname: nickname ?? this.nickname,
      tag: tag ?? this.tag,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      otpSent: otpSent ?? this.otpSent,
      otpExpiresIn: otpExpiresIn ?? this.otpExpiresIn,
      verificationToken: verificationToken ?? this.verificationToken,
      isNewUser: isNewUser ?? this.isNewUser,
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
    final tag = _prefs.getString(ApiConstants.userTagKey);

    if (token != null && token.isNotEmpty) {
      state = AuthState(
        isLoggedIn: true,
        userId: userId,
        nickname: nickname,
        tag: tag,
      );
    }
  }

  // ── Legacy email login (kept for backward compat) ─────────

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _repository.login(
        LoginRequest(phoneNumber: email, password: password),
      );
      await _saveTokens(response);
      state = AuthState(
        isLoggedIn: true,
        userId: response.userId,
        nickname: response.nickname,
        tag: response.tag,
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
        tag: response.tag,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _parseError(e),
      );
    }
  }

  // ── Phone Auth Flow ───────────────────────────────────────

  Future<void> sendOtp(String phoneNumber) async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      phoneNumber: phoneNumber,
    );
    try {
      final expiresIn = await _repository.sendOtp(
        SendOtpRequest(phoneNumber: phoneNumber),
      );
      state = state.copyWith(
        isLoading: false,
        otpSent: true,
        otpExpiresIn: expiresIn,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _parseError(e),
      );
    }
  }

  Future<void> verifyOtp(String code) async {
    final phone = state.phoneNumber;
    if (phone == null) {
      state = state.copyWith(errorMessage: '전화번호 정보가 없습니다.');
      return;
    }
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _repository.verifyOtp(
        VerifyOtpRequest(phoneNumber: phone, code: code),
      );
      state = state.copyWith(
        isLoading: false,
        verificationToken: response.verificationToken,
        isNewUser: response.isNewUser,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _parseError(e),
      );
    }
  }

  Future<void> phoneRegister(String password, String nickname) async {
    final token = state.verificationToken;
    if (token == null) {
      state = state.copyWith(errorMessage: '인증 정보가 없습니다.');
      return;
    }
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _repository.phoneRegister(
        PhoneRegisterRequest(
          verificationToken: token,
          password: password,
          nickname: nickname,
        ),
      );
      await _saveTokens(response);
      state = AuthState(
        isLoggedIn: true,
        userId: response.userId,
        nickname: response.nickname,
        tag: response.tag,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _parseError(e),
      );
    }
  }

  Future<void> phoneLogin(String phoneNumber, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _repository.phoneLogin(
        PhoneLoginRequest(phoneNumber: phoneNumber, password: password),
      );
      await _saveTokens(response);
      state = AuthState(
        isLoggedIn: true,
        userId: response.userId,
        nickname: response.nickname,
        tag: response.tag,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _parseError(e),
      );
    }
  }

  /// Reset the phone auth flow state (e.g., when navigating back)
  void resetPhoneAuthFlow() {
    state = AuthState(
      isLoggedIn: state.isLoggedIn,
      userId: state.userId,
      nickname: state.nickname,
      tag: state.tag,
    );
  }

  // ── Common ────────────────────────────────────────────────

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
    if (response.tag.isNotEmpty) {
      await _prefs.setString(ApiConstants.userTagKey, response.tag);
    }
  }

  Future<void> _clearStorage() async {
    await _prefs.remove(ApiConstants.accessTokenKey);
    await _prefs.remove(ApiConstants.refreshTokenKey);
    await _prefs.remove(ApiConstants.userIdKey);
    await _prefs.remove(ApiConstants.userNicknameKey);
    await _prefs.remove(ApiConstants.userTagKey);
  }

  String _parseError(dynamic e) {
    if (e is DioException) {
      // Try to extract server error message from response body
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        final error = data['error'];
        if (error is Map<String, dynamic> && error['message'] != null) {
          return error['message'] as String;
        }
        if (data['message'] != null) {
          return data['message'] as String;
        }
      }
      final status = e.response?.statusCode;
      if (status == 400) return '입력 정보를 확인해주세요.';
      if (status == 401) return '인증에 실패했습니다.';
      if (status == 409) return '이미 등록된 전화번호입니다.';
      if (status == 429) return '요청이 너무 많습니다. 잠시 후 다시 시도해주세요.';
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        return '서버에 연결할 수 없습니다.';
      }
      return '서버 오류가 발생했습니다. 다시 시도해주세요.';
    }
    if (e is Exception) {
      return e.toString().replaceFirst('Exception: ', '');
    }
    return '알 수 없는 오류가 발생했습니다.';
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
