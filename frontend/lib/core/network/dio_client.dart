import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class DioClient {
  late final Dio _dio;
  final SharedPreferences _prefs;

  DioClient(this._prefs) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        contentType: 'application/json',
        responseType: ResponseType.json,
      ),
    );

    _dio.interceptors.addAll([
      _AuthInterceptor(_prefs, _dio),
      _LoggingInterceptor(),
    ]);
  }

  Dio get dio => _dio;

  // ── Convenience Methods ────────────────────────────────────

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.get<T>(path, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.post<T>(path,
        data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Options? options,
  }) {
    return _dio.put<T>(path, data: data, options: options);
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Options? options,
  }) {
    return _dio.delete<T>(path, data: data, options: options);
  }
}

// ── Auth Interceptor ─────────────────────────────────────────
class _AuthInterceptor extends Interceptor {
  final SharedPreferences _prefs;
  final Dio _dio;
  bool _isRefreshing = false;
  final List<_RequestRetry> _pendingRequests = [];

  _AuthInterceptor(this._prefs, this._dio);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Skip auth header for login/register/refresh endpoints
    final noAuthPaths = [
      ApiConstants.login,
      ApiConstants.register,
      ApiConstants.refresh,
    ];
    if (!noAuthPaths.contains(options.path)) {
      final token = _prefs.getString(ApiConstants.accessTokenKey);
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 &&
        err.requestOptions.path != ApiConstants.refresh &&
        err.requestOptions.path != ApiConstants.login) {
      if (!_isRefreshing) {
        _isRefreshing = true;
        try {
          final refreshed = await _refreshToken();
          _isRefreshing = false;
          if (refreshed) {
            // Retry pending requests
            for (final pending in _pendingRequests) {
              final newToken = _prefs.getString(ApiConstants.accessTokenKey);
              pending.options.headers['Authorization'] = 'Bearer $newToken';
              try {
                final response = await _dio.fetch(pending.options);
                pending.handler.resolve(response);
              } on DioException catch (e) {
                pending.handler.reject(e);
              }
            }
            _pendingRequests.clear();

            // Retry original request
            final newToken = _prefs.getString(ApiConstants.accessTokenKey);
            err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
            try {
              final response = await _dio.fetch(err.requestOptions);
              handler.resolve(response);
              return;
            } on DioException catch (e) {
              handler.reject(e);
              return;
            }
          } else {
            // Refresh failed – clear tokens
            await _clearTokens();
            for (final pending in _pendingRequests) {
              pending.handler.reject(err);
            }
            _pendingRequests.clear();
          }
        } catch (_) {
          _isRefreshing = false;
          await _clearTokens();
          for (final pending in _pendingRequests) {
            pending.handler.reject(err);
          }
          _pendingRequests.clear();
        }
      } else {
        // Another refresh is in progress – queue this request
        _pendingRequests.add(_RequestRetry(err.requestOptions, handler));
        return;
      }
    }
    handler.next(err);
  }

  Future<bool> _refreshToken() async {
    final refreshToken = _prefs.getString(ApiConstants.refreshTokenKey);
    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      final response = await Dio(BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        contentType: 'application/json',
      )).post(
        ApiConstants.refresh,
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final newAccess = data['data']?['accessToken'] ?? data['accessToken'];
        final newRefresh =
            data['data']?['refreshToken'] ?? data['refreshToken'];
        if (newAccess != null) {
          await _prefs.setString(ApiConstants.accessTokenKey, newAccess);
        }
        if (newRefresh != null) {
          await _prefs.setString(ApiConstants.refreshTokenKey, newRefresh);
        }
        return true;
      }
    } catch (_) {
      // refresh failed
    }
    return false;
  }

  Future<void> _clearTokens() async {
    await _prefs.remove(ApiConstants.accessTokenKey);
    await _prefs.remove(ApiConstants.refreshTokenKey);
    await _prefs.remove(ApiConstants.userIdKey);
    await _prefs.remove(ApiConstants.userNicknameKey);
  }
}

class _RequestRetry {
  final RequestOptions options;
  final ErrorInterceptorHandler handler;
  _RequestRetry(this.options, this.handler);
}

// ── Logging Interceptor ──────────────────────────────────────
class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    print('[HTTP] --> ${options.method} ${options.uri}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    print(
        '[HTTP] <-- ${response.statusCode} ${response.requestOptions.uri}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    print(
        '[HTTP] <-- ERROR ${err.response?.statusCode} ${err.requestOptions.uri}');
    handler.next(err);
  }
}
