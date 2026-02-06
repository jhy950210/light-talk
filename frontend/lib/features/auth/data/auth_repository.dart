import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import 'models/login_request.dart';
import 'models/register_request.dart';
import 'models/token_response.dart';

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
}
