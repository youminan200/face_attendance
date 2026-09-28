import 'package:intl/intl.dart';

/// 앱 시계 및 날짜 포맷 유틸리티
class AppClock {
  AppClock._();

  static DateTime now() => DateTime.now();

  static String dateKey(DateTime value) {
    return DateFormat('yyyy-MM-dd').format(value);
  }

  static String koreanWeekday(DateTime value) {
    return DateFormat('E', 'ko_KR').format(value);
  }

  static String formatFullDate(DateTime value) {
    return DateFormat('yyyy년 MM월 dd일 EEEE', 'ko_KR').format(value);
  }

  static String formatTime(DateTime value) {
    return DateFormat('HH:mm:ss', 'ko_KR').format(value);
  }
}
