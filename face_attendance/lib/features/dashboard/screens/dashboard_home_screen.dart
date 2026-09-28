import 'dart:io' show File;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/utils/app_clock.dart';
import '../../../core/utils/attendance_time_judge.dart';
import '../../../core/utils/responsive.dart';
import '../../../models/lecture.dart';
import '../../../models/user_profile.dart';
import '../controllers/dashboard_controller.dart';
import '../widgets/course_enrollment_sheet.dart';
import '../widgets/enrolled_students_sheet.dart';
import '../widgets/real_time_clock_card.dart';

/// 메인 대시보드 홈 화면 (교수님 / 학생 역할별 맞춤형 UI)
class DashboardHomeScreen extends StatelessWidget {
  final UserProfile currentUser;
  final DashboardController dashboardController;
  final List<CameraDescription> cameras;

  const DashboardHomeScreen({
    super.key,
    required this.currentUser,
    required this.dashboardController,
    required this.cameras,
  });

  ImageProvider? _getSafeAvatarProvider(String path) {
    if (path.isEmpty) return null;
    if (kIsWeb) {
      if (path.startsWith('http') || path.startsWith('blob:')) {
        return NetworkImage(path);
      }
      return null;
    }
    try {
      final file = File(path);
      if (file.existsSync()) {
        return FileImage(file);
      }
    } catch (_) {}
    return null;
  }

  void _showCreateCourseDialog(BuildContext context) {
    final titleController = TextEditingController();
    final timeController = TextEditingController(text: '13:00~15:00');
    final roomController = TextEditingController(text: '공학관 201호');
    final officeController = TextEditingController(
      text: '${currentUser.major} 연구실 (${currentUser.id})',
    );
    final noticeController = TextEditingController();
    String selectedDay = '월';

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.add_circle_outline, color: Colors.blue),
                SizedBox(width: 8),
                Text('새 강의 개설'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: '과목명 *',
                      hintText: '예: 모바일 프로그래밍',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedDay,
                    decoration: const InputDecoration(labelText: '수업 요일'),
                    items: ['월', '화', '수', '목', '금', '토']
                        .map((d) => DropdownMenuItem(value: d, child: Text('$d요일')))
                        .toList(),
                    onChanged: (v) => setDialogState(() => selectedDay = v ?? '월'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: timeController,
                    decoration: const InputDecoration(
                      labelText: '수업 시간',
                      hintText: '예: 13:00~15:00',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: roomController,
                    decoration: const InputDecoration(
                      labelText: '강의실',
                      hintText: '예: 공학관 402호',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: officeController,
                    decoration: const InputDecoration(
                      labelText: '연구실 / 연락처',
                      hintText: '예: 융합관 301호 (010-1234-5678)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noticeController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: '첫 공지사항 (선택)',
                      hintText: '학생들에게 전달할 첫 강의 공지사항',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('취소'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final title = titleController.text.trim();
                  if (title.isEmpty) return;

                  final newLecture = Lecture(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: title,
                    day: selectedDay,
                    time: timeController.text.trim(),
                    room: roomController.text.trim(),
                    professor: currentUser.name,
                    professorId: currentUser.id,
                    professorDept: currentUser.major,
                    professorOffice: officeController.text.trim(),
                    notice: noticeController.text.trim(),
                  );

                  Navigator.pop(dialogCtx);
                  await dashboardController.createCourse(newLecture, currentUser);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('🎉 [${newLecture.title}] 강의가 성공적으로 개설되었습니다!'),
                        backgroundColor: Colors.green[700],
                      ),
                    );
                  }
                },
                child: const Text('개설하기'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showNoticeEditDialog(BuildContext context, Lecture lecture) {
    final noticeCtrl = TextEditingController(text: lecture.notice);
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.campaign, color: Colors.orange),
            const SizedBox(width: 8),
            Expanded(child: Text('${lecture.title} 공지 업데이트')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '공지사항을 작성하면 이 수업을 수강하는 모든 학생 화면에 즉시 노출됩니다.',
              style: TextStyle(fontSize: 12.5, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noticeCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: '예: 다음 주 과제 제출 기한 안내, 휴강 및 보강 공지 등',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newNotice = noticeCtrl.text.trim();
              Navigator.pop(dialogCtx);
              await dashboardController.updateCourseNotice(lecture.id, newNotice);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('수업 공지사항이 업데이트되었습니다.'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('공지 등록'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isProfessor = currentUser.role == '교수';
    final todayWeekday = AppClock.koreanWeekday(AppClock.now());
    final avatarRadius = Responsive.avatarRadius(context);
    final maxWidth = Responsive.contentMaxWidth(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(currentUser.school.isNotEmpty ? currentUser.school : '스마트 출결 대시보드'),
        actions: [
          if (isProfessor)
            IconButton(
              tooltip: '새 수업 개설',
              icon: const Icon(Icons.add_box_rounded),
              onPressed: () => _showCreateCourseDialog(context),
            )
          else
            IconButton(
              tooltip: '교수님 수업 찾기',
              icon: const Icon(Icons.search_rounded),
              onPressed: () => CourseEnrollmentSheet.show(
                context,
                student: currentUser,
                dashboardController: dashboardController,
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth.isFinite ? maxWidth : double.infinity),
            child: AnimatedBuilder(
              animation: dashboardController,
              builder: (context, _) {
                final allLectures = dashboardController.lectures;
                final todayLectures = allLectures.where((l) => l.day == todayWeekday).toList();
                final totalStudents = allLectures.fold<int>(0, (sum, l) => sum + l.enrolledCount);

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.all(Responsive.padding(context)),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          // 1. 사용자 프로필 요약 헤더
                          Row(
                            children: [
                              CircleAvatar(
                                radius: avatarRadius,
                                backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(30),
                                backgroundImage: _getSafeAvatarProvider(currentUser.imagePath),
                                child: _getSafeAvatarProvider(currentUser.imagePath) == null
                                    ? Icon(
                                        isProfessor ? Icons.school : Icons.person,
                                        size: avatarRadius,
                                        color: Colors.grey,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          '${currentUser.name} ${isProfessor ? "교수님" : "학생"}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isProfessor ? Colors.purple.withAlpha(25) : Colors.blue.withAlpha(25),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            isProfessor ? '교수 연구실' : '재학생',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: isProfessor ? Colors.purple : Colors.blue,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${currentUser.school} ${currentUser.major.isNotEmpty ? "${currentUser.major} · " : ""}${currentUser.id}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // 2. 교수님 전용 대시보드 요약 vs 학생 실시간 시계
                          if (isProfessor) ...[
                            // 교수님 3대 요약 통계 카드
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF242424) : Colors.blue[50],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark ? Colors.grey[800]! : Colors.blue.withAlpha(60),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _profMetric('개설 강좌', '${allLectures.length}개', Icons.class_outlined, Colors.blue),
                                  Container(width: 1, height: 40, color: Colors.grey.withAlpha(60)),
                                  _profMetric('총 수강생', '$totalStudents명', Icons.people_outline, Colors.teal),
                                  Container(width: 1, height: 40, color: Colors.grey.withAlpha(60)),
                                  _profMetric('오늘 강의', '${todayLectures.length}개', Icons.event_note, Colors.orange),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),

                            // 교수님 퀵 액션 버튼
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _showCreateCourseDialog(context),
                                    icon: const Icon(Icons.add_rounded, size: 20),
                                    label: const Text('새 수업 개설'),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            // 학생: 실시간 시계 & 수업 찾기 버튼
                            const RealTimeClockCard(),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: () => CourseEnrollmentSheet.show(
                                context,
                                student: currentUser,
                                dashboardController: dashboardController,
                              ),
                              icon: const Icon(Icons.search, size: 18),
                              label: const Text('교수님 수업 찾기 및 수강 등록 (+ 내 수업 추가)'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ],
                          const SizedBox(height: 22),

                          // 3. 오늘 수업 헤더
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isProfessor
                                    ? '오늘($todayWeekday요일) 예정된 강의 모니터링'
                                    : '오늘($todayWeekday요일)의 수업 (터치하여 출석)',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey),
                              ),
                              Text(
                                '${todayLectures.length}개',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          if (todayLectures.isEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 36),
                              alignment: Alignment.center,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.event_busy, size: 44, color: Colors.grey.withAlpha(120)),
                                  const SizedBox(height: 10),
                                  Text(
                                    isProfessor ? '오늘 예정된 강의 일정이 없습니다.' : '오늘 예정된 수업이 없습니다.',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                        ]),
                      ),
                    ),

                    // 4. 오늘의 수업 카드 리스트
                    if (todayLectures.isNotEmpty)
                      SliverPadding(
                        padding: EdgeInsets.symmetric(horizontal: Responsive.padding(context)),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final lecture = todayLectures[index];

                              if (isProfessor) {
                                // 교수님 뷰: 수강생 인원 + 명단 확인 + 공지 업데이트
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                lecture.title,
                                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: Colors.teal.withAlpha(20),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                '수강생 ${lecture.enrolledCount}명',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.teal,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '${lecture.time}  |  ${lecture.room}',
                                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                        ),

                                        // 공지사항 영역
                                        if (lecture.notice.isNotEmpty) ...[
                                          const SizedBox(height: 10),
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.amber.withAlpha(20),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: Colors.amber.withAlpha(80)),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.campaign, size: 16, color: Colors.orange),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    '공지: ${lecture.notice}',
                                                    style: const TextStyle(fontSize: 12),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],

                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: OutlinedButton.icon(
                                                onPressed: () => _showNoticeEditDialog(context, lecture),
                                                icon: const Icon(Icons.edit_note, size: 18),
                                                label: const Text('공지 업데이트'),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: ElevatedButton.icon(
                                                onPressed: () => EnrolledStudentsSheet.show(
                                                  context,
                                                  lecture: lecture,
                                                  dashboardController: dashboardController,
                                                ),
                                                icon: const Icon(Icons.people_outline, size: 18),
                                                label: const Text('수강생 명단 확인'),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              } else {
                                // 학생 뷰: 교수님 정보 + 공지 + 얼굴 출석
                                final status = AttendanceTimeJudge.displayStatus(lecture);
                                Color statusBgColor = Colors.grey.withAlpha(40);
                                Color statusTextColor = Colors.grey;

                                if (status == '출석') {
                                  statusBgColor = Colors.green.withAlpha(40);
                                  statusTextColor = Colors.green;
                                } else if (status == '지각') {
                                  statusBgColor = Colors.orange.withAlpha(40);
                                  statusTextColor = Colors.orange;
                                } else if (status == '결석') {
                                  statusBgColor = Colors.red.withAlpha(40);
                                  statusTextColor = Colors.red;
                                }

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () => dashboardController.processAttendance(
                                      context: context,
                                      lecture: lecture,
                                      cameras: cameras,
                                      user: currentUser,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context).colorScheme.primary.withAlpha(20),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.camera_alt_rounded,
                                                  color: Theme.of(context).colorScheme.primary,
                                                  size: 22,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      lecture.title,
                                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      '${lecture.time}  |  ${lecture.room}',
                                                      style: TextStyle(fontSize: 12.5, color: Colors.grey[600]),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                decoration: BoxDecoration(
                                                  color: statusBgColor,
                                                  borderRadius: BorderRadius.circular(14),
                                                ),
                                                child: Text(
                                                  status,
                                                  style: TextStyle(
                                                    color: statusTextColor,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12.5,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),

                                          // 교수님 정보 배지
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: isDark ? Colors.grey[850] : Colors.grey[200],
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.person, size: 14, color: Colors.blue),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    '담당: ${lecture.professor} 교수님 ${lecture.professorDept.isNotEmpty ? "(${lecture.professorDept})" : ""} · ${lecture.professorOffice}',
                                                    style: const TextStyle(fontSize: 11.5),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          // 교수님 공지사항
                                          if (lecture.notice.isNotEmpty) ...[
                                            const SizedBox(height: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.amber.withAlpha(20),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.campaign, size: 14, color: Colors.orange),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      '공지: ${lecture.notice}',
                                                      style: const TextStyle(fontSize: 11.5),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }
                            },
                            childCount: todayLectures.length,
                          ),
                        ),
                      ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 24),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _profMetric(String label, String value, IconData icon, MaterialColor color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color[800])),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}
