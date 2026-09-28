import 'package:flutter/material.dart';

/// 시간표 과목별 파스텔 색상 테마 정의 (업로드 레퍼런스 디자인 완벽 매핑)
class TimetableColorSet {
  final Color background;
  final Color border;
  final Color text;
  final Color badgeBackground;
  final Color badgeText;
  final Color iconColor;

  const TimetableColorSet({
    required this.background,
    required this.border,
    required this.text,
    required this.badgeBackground,
    required this.badgeText,
    required this.iconColor,
  });
}

class TimetableColorPalette {
  // 6종 모던 파스텔 팔레트 (라이트 모드)
  static const List<TimetableColorSet> _lightPalette = [
    // 0: Soft Honey Yellow
    TimetableColorSet(
      background: Color(0xFFFFF9E8),
      border: Color(0xFFFFE599),
      text: Color(0xFF8A6200),
      badgeBackground: Color(0xFFFFECB3),
      badgeText: Color(0xFF704E00),
      iconColor: Color(0xFFB38600),
    ),
    // 1: Pastel Mint Green
    TimetableColorSet(
      background: Color(0xFFEAF8F1),
      border: Color(0xFFA7E5C4),
      text: Color(0xFF1B6E41),
      badgeBackground: Color(0xFFC7EED8),
      badgeText: Color(0xFF145632),
      iconColor: Color(0xFF228B53),
    ),
    // 2: Soft Lavender Purple
    TimetableColorSet(
      background: Color(0xFFF5EEFC),
      border: Color(0xFFD6B5F5),
      text: Color(0xFF6B2CA8),
      badgeBackground: Color(0xFFE7D1FA),
      badgeText: Color(0xFF532185),
      iconColor: Color(0xFF853DC9),
    ),
    // 3: Pastel Sky Blue
    TimetableColorSet(
      background: Color(0xFFEBF4FE),
      border: Color(0xFFA9D0FD),
      text: Color(0xFF1757A6),
      badgeBackground: Color(0xFFCBE2FD),
      badgeText: Color(0xFF104380),
      iconColor: Color(0xFF206DCF),
    ),
    // 4: Pastel Coral / Peach Pink
    TimetableColorSet(
      background: Color(0xFFFFEEF1),
      border: Color(0xFFFFBCC7),
      text: Color(0xFFA61E38),
      badgeBackground: Color(0xFFFFD5DD),
      badgeText: Color(0xFF85152A),
      iconColor: Color(0xFFCF2E4E),
    ),
    // 5: Soft Tangerine Orange
    TimetableColorSet(
      background: Color(0xFFFFF3E8),
      border: Color(0xFFFFCDA1),
      text: Color(0xFFA84E08),
      badgeBackground: Color(0xFFFFDFBF),
      badgeText: Color(0xFF853B03),
      iconColor: Color(0xFFD46813),
    ),
  ];

  // 6종 모던 파스텔 팔레트 (다크 모드 - 서피스 조화형 다크 카드 + 파스텔 틴트)
  static const List<TimetableColorSet> _darkPalette = [
    // 0: Dark Honey Yellow
    TimetableColorSet(
      background: Color(0xFF2E2A1E),
      border: Color(0xFF6B5826),
      text: Color(0xFFFFE082),
      badgeBackground: Color(0xFF423719),
      badgeText: Color(0xFFFFECB3),
      iconColor: Color(0xFFFFD54F),
    ),
    // 1: Dark Mint Green
    TimetableColorSet(
      background: Color(0xFF1B2E24),
      border: Color(0xFF2D6144),
      text: Color(0xFFA5D6A7),
      badgeBackground: Color(0xFF1A452D),
      badgeText: Color(0xFFC8E6C9),
      iconColor: Color(0xFF81C784),
    ),
    // 2: Dark Lavender Purple
    TimetableColorSet(
      background: Color(0xFF2B2038),
      border: Color(0xFF563678),
      text: Color(0xFFCE93D8),
      badgeBackground: Color(0xFF3F225E),
      badgeText: Color(0xFFE1BEE7),
      iconColor: Color(0xFFBA68C8),
    ),
    // 3: Dark Sky Blue
    TimetableColorSet(
      background: Color(0xFF1C2838),
      border: Color(0xFF2F4E75),
      text: Color(0xFF90CAF9),
      badgeBackground: Color(0xFF203C61),
      badgeText: Color(0xFFBBDEFB),
      iconColor: Color(0xFF64B5F6),
    ),
    // 4: Dark Coral Pink
    TimetableColorSet(
      background: Color(0xFF332024),
      border: Color(0xFF70333E),
      text: Color(0xFFFFAB91),
      badgeBackground: Color(0xFF54202A),
      badgeText: Color(0xFFFFCDD2),
      iconColor: Color(0xFFE57373),
    ),
    // 5: Dark Tangerine Orange
    TimetableColorSet(
      background: Color(0xFF33261C),
      border: Color(0xFF6E4826),
      text: Color(0xFFFFCC80),
      badgeBackground: Color(0xFF543314),
      badgeText: Color(0xFFFFE0B2),
      iconColor: Color(0xFFFFB74D),
    ),
  ];

  /// 과목명 또는 ID의 해시코드를 기반으로 고유 파스텔 컬러셋 반환
  static TimetableColorSet getColor(String key, {bool isDark = false}) {
    final int hash = key.codeUnits.fold(0, (prev, elem) => prev + elem);
    final int index = (hash.abs()) % _lightPalette.length;
    return isDark ? _darkPalette[index] : _lightPalette[index];
  }

  /// 인덱스 기반 파스텔 컬러셋 반환
  static TimetableColorSet getByIndex(int index, {bool isDark = false}) {
    final int safeIndex = index % _lightPalette.length;
    return isDark ? _darkPalette[safeIndex] : _lightPalette[safeIndex];
  }
}
