import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_config.dart';

/// 표준 API 응답 모델
class ApiResponse<T> {
  final bool isSuccess;
  final int statusCode;
  final T? data;
  final String? errorMessage;

  const ApiResponse({
    required this.isSuccess,
    required this.statusCode,
    this.data,
    this.errorMessage,
  });

  factory ApiResponse.success(T data, {int statusCode = 200}) {
    return ApiResponse(
      isSuccess: true,
      statusCode: statusCode,
      data: data,
    );
  }

  factory ApiResponse.failure(String message, {int statusCode = 500}) {
    return ApiResponse(
      isSuccess: false,
      statusCode: statusCode,
      errorMessage: message,
    );
  }
}

/// 프로덕션 레벨 안전한 HTTP 클라이언트
class ApiClient {
  final http.Client _client;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  /// POST 요청
  Future<ApiResponse<Map<String, dynamic>>> post(
    String endpoint, {
    required Map<String, dynamic> body,
    Map<String, String>? headers,
  }) async {
    final uri = ApiConfig.buildUri(endpoint);
    final defaultHeaders = {
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json',
      ...?headers,
    };

    try {
      final response = await _client
          .post(
            uri,
            headers: defaultHeaders,
            body: jsonEncode(body),
          )
          .timeout(ApiConfig.requestTimeout);

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final data = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{'data': decoded};

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse.success(data, statusCode: response.statusCode);
      } else {
        final errorMsg = data['detail'] ?? data['message'] ?? '서버 응답 오류 (${response.statusCode})';
        return ApiResponse.failure(errorMsg.toString(), statusCode: response.statusCode);
      }
    } catch (e) {
      return ApiResponse.failure('통신 중 오류가 발생했습니다: $e', statusCode: 500);
    }
  }

  /// GET 요청
  Future<ApiResponse<Map<String, dynamic>>> get(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, String>? queryParams,
  }) async {
    var uri = ApiConfig.buildUri(endpoint);
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: {...uri.queryParameters, ...queryParams});
    }

    try {
      final response = await _client
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              ...?headers,
            },
          )
          .timeout(ApiConfig.requestTimeout);

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final data = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{'data': decoded};

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse.success(data, statusCode: response.statusCode);
      } else {
        final errorMsg = data['detail'] ?? data['message'] ?? '서버 응답 오류 (${response.statusCode})';
        return ApiResponse.failure(errorMsg.toString(), statusCode: response.statusCode);
      }
    } catch (e) {
      return ApiResponse.failure('통신 오류: $e', statusCode: 500);
    }
  }

  /// PUT 요청
  Future<ApiResponse<Map<String, dynamic>>> put(
    String endpoint, {
    required Map<String, dynamic> body,
    Map<String, String>? headers,
  }) async {
    final uri = ApiConfig.buildUri(endpoint);
    final defaultHeaders = {
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json',
      ...?headers,
    };

    try {
      final response = await _client
          .put(
            uri,
            headers: defaultHeaders,
            body: jsonEncode(body),
          )
          .timeout(ApiConfig.requestTimeout);

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final data = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{'data': decoded};

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse.success(data, statusCode: response.statusCode);
      } else {
        final errorMsg = data['detail'] ?? data['message'] ?? '서버 응답 오류 (${response.statusCode})';
        return ApiResponse.failure(errorMsg.toString(), statusCode: response.statusCode);
      }
    } catch (e) {
      return ApiResponse.failure('통신 오류: $e', statusCode: 500);
    }
  }

  /// DELETE 요청
  Future<ApiResponse<Map<String, dynamic>>> delete(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, String>? queryParams,
  }) async {
    var uri = ApiConfig.buildUri(endpoint);
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: {...uri.queryParameters, ...queryParams});
    }

    try {
      final response = await _client
          .delete(
            uri,
            headers: {
              'Accept': 'application/json',
              ...?headers,
            },
          )
          .timeout(ApiConfig.requestTimeout);

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final data = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{'data': decoded};

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse.success(data, statusCode: response.statusCode);
      } else {
        final errorMsg = data['detail'] ?? data['message'] ?? '서버 응답 오류 (${response.statusCode})';
        return ApiResponse.failure(errorMsg.toString(), statusCode: response.statusCode);
      }
    } catch (e) {
      return ApiResponse.failure('통신 오류: $e', statusCode: 500);
    }
  }

  void close() {
    _client.close();
  }
}
