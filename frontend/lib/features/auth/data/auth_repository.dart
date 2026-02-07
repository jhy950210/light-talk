import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import 'models/login_request.dart';
import 'models/phone_login_request.dart';
import 'models/phone_register_request.dart';
import 'models/register_request.dart';
import 'models/send_otp_request.dart';
import 'models/token_response.dart';
import 'models/verify_otp_request.dart';
import 'models/verify_otp_response.dart';

class AuthRepository {
  final DioClient _client;

  AuthRepository(this._client);

  Future<TokenResponse> login(LoginRequest request) async {
    final response = await _client.post(
      ApiConstants.login,
      data: request.toJson(),
    );
    return TokenResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<TokenResponse> register(RegisterRequest request) async {
    final response = await _client.post(
      ApiConstants.register,
      data: request.toJson(),
    );
    return TokenResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> logout(String refreshToken) async {
    try {
      await _client.post(
        ApiConstants.logout,
        data: {'refreshToken': refreshToken},
      );
    } on DioException {
      // Ignore logout failures – we clear local state regardless
    }
  }

  Future<TokenResponse> refreshToken(String refreshToken) async {
    final response = await _client.post(
      ApiConstants.refresh,
      data: {'refreshToken': refreshToken},
    );
    return TokenResponse.fromJson(response.data as Map<String, dynamic>);
  }

  // ── Phone Auth ────────────────────────────────────────────

  Future<int> sendOtp(SendOtpRequest request) async {
    final response = await _client.post(
      ApiConstants.sendOtp,
      data: request.toJson(),
    );
    final data = response.data as Map<String, dynamic>;
    final inner = data['data'] as Map<String, dynamic>? ?? data;
    return inner['expiresIn'] as int;
  }

  Future<VerifyOtpResponse> verifyOtp(VerifyOtpRequest request) async {
    final response = await _client.post(
      ApiConstants.verifyOtp,
      data: request.toJson(),
    );
    return VerifyOtpResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<TokenResponse> phoneRegister(PhoneRegisterRequest request) async {
    final response = await _client.post(
      ApiConstants.phoneRegister,
      data: request.toJson(),
    );
    return TokenResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<TokenResponse> phoneLogin(PhoneLoginRequest request) async {
    final response = await _client.post(
      ApiConstants.phoneLogin,
      data: request.toJson(),
    );
    return TokenResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> withdrawUser(String password) async {
    await _client.delete(
      ApiConstants.withdrawUser,
      data: {'password': password},
    );
  }
}
