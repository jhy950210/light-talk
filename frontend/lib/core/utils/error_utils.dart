import 'package:dio/dio.dart';

/// Common error parser for all providers.
/// Returns a user-facing Korean error message.
String parseApiError(dynamic e) {
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
    if (status == 409) return '이미 처리된 요청입니다.';
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
