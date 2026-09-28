import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 반응형 화면 크기 대응 및 안전 마진 유틸리티
class Responsive {
  Responsive._();

  /// 기기 너비에 따른 컨텐츠 수평 패딩
  static double padding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 360) return 12.0;
    if (width < 600) return 18.0;
    return 28.0;
  }

  /// 소형 폰 여부 (iPhone SE, 360dp 미만)
  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.sizeOf(context).width < 360;
  }

  /// 태블릿 및 폴더블 대화면 여부 (600dp 이상)
  static bool isTablet(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= 600;
  }

  /// 태블릿 및 폴더블 대화면 대응 최대 너비 (중앙 정렬 가드)
  static double contentMaxWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1024) return 620.0;
    if (width >= 600) return 520.0;
    return double.infinity;
  }

  /// iOS 하단 홈 인디케이터 및 Android 제스처 바 대응 안전 바텀 패딩
  static double safeBottomPadding(BuildContext context, {double defaultPadding = 16.0}) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return math.max(defaultPadding, bottomInset + 8.0);
  }

  /// iOS Dynamic Island, 노치, Android 펀치홀 상단 안전 패딩
  static double safeTopPadding(BuildContext context, {double defaultPadding = 12.0}) {
    final topInset = MediaQuery.paddingOf(context).top;
    return math.max(defaultPadding, topInset);
  }

  /// 아바타 반경 반응형 크기
  static double avatarRadius(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 360) return 26.0;
    if (width < 600) return 34.0;
    return 42.0;
  }

  /// 카메라 얼굴 가이드 프레임 너비
  static double faceGuideWidth(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return math.min(size.width * 0.68, 280.0);
  }

  /// 카메라 얼굴 가이드 프레임 높이
  static double faceGuideHeight(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return math.min(size.height * 0.46, 380.0);
  }
}
