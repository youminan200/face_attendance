import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/utils/responsive.dart';
import '../controllers/dashboard_controller.dart';
import '../widgets/attendance_stats_painter.dart';

/// 출석 통계 및 누적 이력 화면
class AttendanceHistoryScreen extends StatelessWidget {
  final DashboardController dashboardController;

  const AttendanceHistoryScreen({
    super.key,
    required this.dashboardController,
  });

  Widget _buildStatBox(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          '$count회',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('출석 통계 현황'),
      ),
      body: AnimatedBuilder(
        animation: dashboardController,
        builder: (context, _) {
          final lectures = dashboardController.lectures;

          if (lectures.isEmpty) {
            return const Center(child: Text('출석 데이터가 없습니다.'));
          }

          final totalAtt = lectures.fold(0, (sum, l) => sum + l.att);
          final totalLate = lectures.fold(0, (sum, l) => sum + l.late);
          final totalAbs = lectures.fold(0, (sum, l) => sum + l.abs);

          return SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final chartDimension = math.min(constraints.maxWidth * 0.52, 220.0);

                return SingleChildScrollView(
                  padding: EdgeInsets.all(Responsive.padding(context)),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),

                      // 1. 3D 원형 통계 차트 (CustomPainter)
                      SizedBox.square(
                        dimension: chartDimension,
                        child: CustomPaint(
                          painter: AttendanceStatsPainter(
                            att: totalAtt,
                            late: totalLate,
                            abs: totalAbs,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // 2. 종합 출석 요약 수치
                      Card(
                        elevation: 0,
                        color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(80),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildStatBox('정상 출석', totalAtt, Colors.green),
                              Container(width: 1, height: 36, color: Colors.grey.withAlpha(60)),
                              _buildStatBox('지각', totalLate, Colors.orange),
                              Container(width: 1, height: 36, color: Colors.grey.withAlpha(60)),
                              _buildStatBox('결석', totalAbs, Colors.redAccent),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '과목별 출결 현황',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // 3. 과목별 상세 출결 목록
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: lectures.length,
                        itemBuilder: (context, index) {
                          final lecture = lectures[index];
                          final totalCourseClass = lecture.att + lecture.late + lecture.abs;
                          final attRate = totalCourseClass > 0
                              ? ((lecture.att / totalCourseClass) * 100).toStringAsFixed(0)
                              : '100';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          lecture.title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '담당: ${lecture.professor}  |  ${lecture.day}요일 ${lecture.time}',
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '출석률 $attRate%',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '출:${lecture.att}  지:${lecture.late}  결:${lecture.abs}',
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
