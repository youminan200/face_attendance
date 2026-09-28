import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 3D 도넛 형태의 출석 통계 차트 페인터
class AttendanceStatsPainter extends CustomPainter {
  final int att;
  final int late;
  final int abs;

  AttendanceStatsPainter({
    required this.att,
    required this.late,
    required this.abs,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = (att + late + abs).toDouble();
    if (total <= 0) {
      // 데이터가 없을 때 회색 가이드 원
      final emptyPaint = Paint()
        ..color = Colors.grey.withAlpha(80)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 24;
      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        size.width / 2.6,
        emptyPaint,
      );
      return;
    }

    double start = -math.pi / 2;
    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: size.width / 2.5,
    );

    void drawSegment(int value, Color color) {
      if (value <= 0) return;
      final sweep = (value / total) * 2 * math.pi;

      // 3D 입체 그림자 효과 (Y축 하방 이동)
      final shadowPaint = Paint()
        ..color = color.withAlpha(90)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 28
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect.shift(const Offset(0, 8)), start, sweep, false, shadowPaint);

      // 전면 본체 아크
      final mainPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 28
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, start, sweep, false, mainPaint);

      start += sweep;
    }

    drawSegment(att, Colors.green);
    drawSegment(late, Colors.orange);
    drawSegment(abs, Colors.redAccent);
  }

  @override
  bool shouldRepaint(covariant AttendanceStatsPainter oldDelegate) {
    return oldDelegate.att != att ||
        oldDelegate.late != late ||
        oldDelegate.abs != abs;
  }
}
