import 'package:flutter/foundation.dart';

/// API 네트워크 환경설정 및 엔드포인트 상수
class ApiConfig {
  ApiConfig._();

  /// 백엔드 서버 기본 URL (아이폰/외부기기 브라우저, Android 에뮬레이터, PC 로컬 자동 판별)
  static String get baseUrl {
    const envUrl = String.fromEnvironment('API_BASE_URL');
    if (envUrl.isNotEmpty) return envUrl;
    if (kIsWeb) {
      final origin = Uri.base.origin;
      if (origin.isNotEmpty && origin != 'null') {
        return origin;
      }
      return 'http://127.0.0.1:8080';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080';
    }
    return 'http://127.0.0.1:8080';
  }

  /// HTTP 요청 타임아웃 (초 단위)
  static const Duration requestTimeout = Duration(seconds: 10);

  // 엔드포인트 정의
  static const String loginEndpoint = '/api/login';
  static const String signUpEndpoint = '/api/signup';
  static const String attendanceEndpoint = '/api/attendance';
  static const String coursesEndpoint = '/api/courses';
  static String profCoursesEndpoint(String profId) => '/api/professors/$profId/courses';
  static String studentCoursesEndpoint(String studentId) => '/api/students/$studentId/courses';
  static String courseNoticeEndpoint(String courseId) => '/api/courses/$courseId/notice';
  static String courseEnrollEndpoint(String courseId) => '/api/courses/$courseId/enroll';
  static String courseStudentsEndpoint(String courseId) => '/api/courses/$courseId/students';
  static const String universityCoursesEndpoint = '/api/university/courses';
  static const String universitySyncEndpoint = '/api/university/sync-student-courses';
  static const String universitiesEndpoint = '/api/universities';
  static const String universityCampusMapEndpoint = '/api/university/campus-map';

  /// URL 생성 유틸리티
  static Uri buildUri(String endpoint) {
    final sanitizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final sanitizedEndpoint = endpoint.startsWith('/')
        ? endpoint
        : '/$endpoint';
    return Uri.parse('$sanitizedBase$sanitizedEndpoint');
  }
}
