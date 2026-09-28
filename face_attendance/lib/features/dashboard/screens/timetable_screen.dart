import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../../core/utils/responsive.dart';
import '../../../models/lecture.dart';
import '../../../models/user_profile.dart';
import '../controllers/dashboard_controller.dart';
import '../utils/timetable_color_palette.dart';
import '../widgets/campus_map_picker_sheet.dart';
import '../widgets/course_enrollment_sheet.dart';
import '../widgets/enrolled_students_sheet.dart';

/// 모던 파스텔 카드 & 주간 그리드 / 일별 타임라인 기반 프리미엄 시간표 화면
class TimetableScreen extends StatefulWidget {
  final DashboardController dashboardController;
  final UserProfile currentUser;
  final List<CameraDescription> cameras;

  const TimetableScreen({
    super.key,
    required this.dashboardController,
    required this.currentUser,
    required this.cameras,
  });

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  // 0: 주간 시간표 (Weekly Grid), 1: 일별 타임라인 (Daily Timeline), 2: 수업 관리 (Course List)
  int _selectedView = 0;
  String _selectedDay = '월';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  static const List<String> _weekdays = ['월', '화', '수', '목', '금'];
  static const double _hourRowHeight = 64.0;
  static const double _timeColWidth = 46.0;

  @override
  void initState() {
    super.initState();
    // 현재 요일 자동 감지
    final nowWeekday = DateTime.now().weekday; // 1: Mon ... 7: Sun
    const dayMap = {1: '월', 2: '화', 3: '수', 4: '목', 5: '금', 6: '토', 7: '일'};
    final detected = dayMap[nowWeekday] ?? '월';
    _selectedDay = (detected == '일' || detected == '토') ? '월' : detected;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // 시간 파싱 헬퍼 (예: "10:00~12:00" -> start: 10.0, duration: 2.0)
  // ===========================================================================
  ({double start, double duration}) _parseLectureTime(String timeStr) {
    try {
      final clean = timeStr.replaceAll(' ', '');
      final parts = clean.split(RegExp(r'[~-]'));
      if (parts.length >= 2) {
        final startParts = parts[0].split(':');
        final endParts = parts[1].split(':');
        final sH = double.tryParse(startParts[0]) ?? 10.0;
        final sM = startParts.length > 1 ? (double.tryParse(startParts[1]) ?? 0.0) / 60.0 : 0.0;
        final eH = double.tryParse(endParts[0]) ?? (sH + 2.0);
        final eM = endParts.length > 1 ? (double.tryParse(endParts[1]) ?? 0.0) / 60.0 : 0.0;
        final start = (sH + sM).clamp(9.0, 18.0);
        final end = (eH + eM).clamp(start + 1.0, 19.0);
        return (start: start, duration: (end - start).clamp(1.0, 4.0));
      }
    } catch (_) {}
    return (start: 10.0, duration: 2.0);
  }

  // ===========================================================================
  // 수업 등록/개설 모달 다이얼로그
  // ===========================================================================
  void _showLectureForm({Lecture? lecture, String? prefilledDay, int? prefilledHour}) {
    final isEdit = lecture != null;
    final isProfessor = widget.currentUser.role == '교수';
    final titleController = TextEditingController(text: lecture?.title ?? '');
    final timeController = TextEditingController(
      text: lecture?.time ??
          (prefilledHour != null
              ? '${prefilledHour.toString().padLeft(2, '0')}:00~${(prefilledHour + 2).toString().padLeft(2, '0')}:00'
              : '10:00~12:00'),
    );
    final roomController = TextEditingController(text: lecture?.room ?? '스마트ICT관 SP-302호');
    final profController = TextEditingController(
      text: lecture?.professor ?? (isProfessor ? widget.currentUser.name : ''),
    );
    final officeController = TextEditingController(
      text: lecture?.professorOffice ??
          (isProfessor ? '${widget.currentUser.major} 연구실 (${widget.currentUser.id})' : ''),
    );
    final noticeController = TextEditingController(text: lecture?.notice ?? '');
    String selectedDay = lecture?.day ?? prefilledDay ?? _selectedDay;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(isEdit ? Icons.edit_calendar_rounded : Icons.add_box_rounded, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  isEdit ? '수업 정보 수정' : (isProfessor ? '새 강의 개설' : '내 수업 등록'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
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
                      hintText: '예: 데이터베이스, 모바일앱개발',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedDay,
                          decoration: const InputDecoration(
                            labelText: '수업 요일',
                            border: OutlineInputBorder(),
                          ),
                          items: ['월', '화', '수', '목', '금', '토']
                              .map((d) => DropdownMenuItem(value: d, child: Text('$d요일')))
                              .toList(),
                          onChanged: (v) => setDialogState(() => selectedDay = v ?? '월'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: timeController,
                          decoration: const InputDecoration(
                            labelText: '수업 시간',
                            hintText: '10:00~12:00',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: roomController,
                    decoration: InputDecoration(
                      labelText: '강의실',
                      hintText: '예: 스마트ICT관 SP-302호',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.map_rounded, color: Colors.blue),
                        tooltip: '실제 캠퍼스 지도에서 강의실 선택',
                        onPressed: () async {
                          final selected = await CampusMapPickerSheet.show(
                            context,
                            universityName: widget.currentUser.school.isNotEmpty
                                ? widget.currentUser.school
                                : '배재대학교',
                            initialRoom: roomController.text,
                          );
                          if (selected != null) {
                            setDialogState(() => roomController.text = selected);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: profController,
                    decoration: const InputDecoration(
                      labelText: '담당 교수 (예:홍길동)',
                      hintText: '예:홍길동',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: officeController,
                    decoration: const InputDecoration(
                      labelText: '연구실 / 연락처 (선택)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (isProfessor) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: noticeController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: '수업 공지사항 (선택)',
                        hintText: '학생들에게 전달할 첫 공지사항',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('취소'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  final title = titleController.text.trim();
                  if (title.isEmpty) return;

                  if (isEdit) {
                    final updated = lecture.copyWith(
                      title: title,
                      day: selectedDay,
                      time: timeController.text.trim(),
                      room: roomController.text.trim(),
                      professor: profController.text.trim(),
                      professorOffice: officeController.text.trim(),
                      notice: noticeController.text.trim().isNotEmpty
                          ? noticeController.text.trim()
                          : lecture.notice,
                    );
                    widget.dashboardController.updateLecture(updated);
                  } else {
                    final newLecture = Lecture(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: title,
                      day: selectedDay,
                      time: timeController.text.trim(),
                      room: roomController.text.trim(),
                      professor: profController.text.trim(),
                      professorId: isProfessor ? widget.currentUser.id : '',
                      professorDept: isProfessor ? widget.currentUser.major : '',
                      professorOffice: officeController.text.trim(),
                      notice: noticeController.text.trim(),
                    );
                    if (isProfessor) {
                      await widget.dashboardController.createCourse(newLecture, widget.currentUser);
                    } else {
                      widget.dashboardController.addLecture(newLecture);
                    }
                  }
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                  if (mounted) {
                    setState(() {});
                  }
                },
                child: Text(isEdit ? '수정 완료' : '등록 완료'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ===========================================================================
  // 강의 상세 바텀시트 (카드/그리드 블록 터치 시 열림)
  // ===========================================================================
  void _showLectureDetailSheet(Lecture lecture) {
    final isProfessor = widget.currentUser.role == '교수';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = TimetableColorPalette.getColor(lecture.title, isDark: isDark);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            MediaQuery.of(sheetCtx).padding.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상단 바 핸들
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(100),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // 헤더 카드 (파스텔 액센트)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: palette.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: palette.border, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (lecture.courseCode.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: palette.badgeBackground,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              lecture.courseCode,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: palette.badgeText,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: palette.badgeBackground,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            lecture.category,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: palette.badgeText,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: palette.border.withAlpha(120),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.schedule, size: 14, color: palette.text),
                              const SizedBox(width: 4),
                              Text(
                                '${lecture.day}요일 ${lecture.time}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: palette.text,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      lecture.title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // 강의실 & 캠퍼스 지도 바로가기 버튼
                    Row(
                      children: [
                        Icon(Icons.meeting_room_outlined, size: 16, color: palette.iconColor),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            lecture.room,
                            style: TextStyle(fontSize: 13, color: palette.text, fontWeight: FontWeight.w600),
                          ),
                        ),
                        InkWell(
                          onTap: () async {
                            Navigator.pop(sheetCtx);
                            await CampusMapPickerSheet.show(
                              context,
                              universityName: widget.currentUser.school.isNotEmpty
                                  ? widget.currentUser.school
                                  : '배재대학교',
                              initialRoom: lecture.room,
                            );
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.blue.withAlpha(30),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.map_rounded, size: 13, color: Colors.blue),
                                SizedBox(width: 4),
                                Text(
                                  '지도 보기 🗺️',
                                  style: TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // 교수님 정보
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF282828) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.blue.withAlpha(40),
                      child: const Icon(Icons.person, color: Colors.blue, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '담당 교수: ${lecture.professor.isNotEmpty ? lecture.professor : "교수님"}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            lecture.professorDept.isNotEmpty
                                ? lecture.professorDept
                                : (lecture.professorOffice.isNotEmpty ? lecture.professorOffice : '배재대학교'),
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    if (!isProfessor)
                      IconButton(
                        tooltip: '교수님께 1:1 문의 채팅',
                        icon: const Icon(Icons.chat_bubble_outline, color: Colors.blue),
                        onPressed: () {
                          Navigator.pop(sheetCtx);
                          widget.dashboardController.addChat('${lecture.professor} 교수님 상담');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('[${lecture.professor}] 교수님과의 1:1 상담 채팅방이 열렸습니다.'),
                              backgroundColor: Colors.blue[700],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),

              // 수업 공지사항
              if (lecture.notice.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withAlpha(80)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.campaign_rounded, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '수업 공지사항',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              lecture.notice,
                              style: const TextStyle(fontSize: 13, height: 1.3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // 하단 액션 버튼
              if (isProfessor) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetCtx);
                          EnrolledStudentsSheet.show(
                            context,
                            lecture: lecture,
                            dashboardController: widget.dashboardController,
                          );
                        },
                        icon: const Icon(Icons.group_outlined, size: 18),
                        label: Text('수강생 명단 (${lecture.enrolledCount}명)'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetCtx);
                          _showNoticeEditDialog(lecture);
                        },
                        icon: const Icon(Icons.campaign, size: 18),
                        label: const Text('공지 등록'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetCtx);
                          _showLectureForm(lecture: lecture);
                        },
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('수업 수정'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetCtx);
                          _confirmDeleteLecture(lecture);
                        },
                        icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                        label: const Text('강의 삭제', style: TextStyle(color: Colors.red)),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetCtx);
                          _confirmDeleteLecture(lecture);
                        },
                        icon: const Icon(Icons.remove_circle_outline, size: 16, color: Colors.redAccent),
                        label: const Text('수강 취소', style: TextStyle(color: Colors.redAccent)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetCtx);
                          widget.dashboardController.processAttendance(
                            context: context,
                            lecture: lecture,
                            cameras: widget.cameras,
                            user: widget.currentUser,
                          );
                        },
                        icon: const Icon(Icons.camera_alt_rounded, size: 18),
                        label: const Text('출석 인증하기'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showNoticeEditDialog(Lecture lecture) {
    final noticeCtrl = TextEditingController(text: lecture.notice);
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.campaign, color: Colors.orange),
            const SizedBox(width: 8),
            Expanded(child: Text('${lecture.title} 공지사항 업데이트')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '공지사항을 입력하면 이 수업을 수강 신청한 학생들의 화면에 즉시 표시됩니다.',
              style: TextStyle(fontSize: 12.5, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noticeCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: '공지사항 내용을 입력하세요 (예: 시험 범위, 휴강 안내, 과제 제출 등)',
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
              await widget.dashboardController.updateCourseNotice(lecture.id, newNotice);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('수업 공지사항이 성공적으로 업데이트되었습니다.'),
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

  void _confirmDeleteLecture(Lecture lecture) {
    final isProfessor = widget.currentUser.role == '교수';
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isProfessor ? '강의 삭제' : '수강 취소'),
        content: Text(
          isProfessor
              ? '[${lecture.title}] 강의를 삭제하시겠습니까?\n등록된 수강생 정보도 함께 삭제됩니다.'
              : '[${lecture.title}] 수업을 내 시간표에서 수강 취소하시겠습니까?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('닫기'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (isProfessor) {
                widget.dashboardController.deleteLecture(lecture.id);
              } else {
                await widget.dashboardController.unenrollCourse(lecture.id, widget.currentUser.id);
              }
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(isProfessor ? '강의가 삭제되었습니다.' : '수강이 취소되었습니다.')),
                );
              }
            },
            child: Text(isProfessor ? '삭제' : '수강 취소'),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 1. 주간 시간표 그리드 뷰 (Weekly Timetable Grid)
  // ===========================================================================
  Widget _buildWeeklyGridView(List<Lecture> lectures, bool isDark) {
    final Map<String, List<Lecture>> dayMap = {'월': [], '화': [], '수': [], '목': [], '금': []};
    for (final l in lectures) {
      if (dayMap.containsKey(l.day)) {
        dayMap[l.day]!.add(l);
      }
    }

    final todayWeekday = DateTime.now().weekday;
    const weekdayNames = {1: '월', 2: '화', 3: '수', 4: '목', 5: '금'};
    final currentDayName = weekdayNames[todayWeekday];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(8, 6, 12, 24),
      child: Column(
        children: [
          // 상단 요일 헤더 행
          Row(
            children: [
              const SizedBox(width: _timeColWidth),
              ..._weekdays.map((d) {
                final isToday = d == currentDayName;
                final count = dayMap[d]?.length ?? 0;
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isToday
                          ? (isDark ? Colors.blue.withAlpha(40) : Colors.blue.withAlpha(25))
                          : (isDark ? const Color(0xFF242424) : Colors.grey[100]),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isToday ? Colors.blue : (isDark ? Colors.grey[850]! : Colors.grey[300]!),
                        width: isToday ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$d요일',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: isToday ? FontWeight.bold : FontWeight.w600,
                            color: isToday ? Colors.blue : (isDark ? Colors.grey[300] : Colors.grey[700]),
                          ),
                        ),
                        if (count > 0)
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: isToday ? Colors.blue : Colors.grey.withAlpha(60),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$count강',
                              style: TextStyle(
                                fontSize: 9.5,
                                color: isToday ? Colors.white : (isDark ? Colors.grey[300] : Colors.grey[800]),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),

          const SizedBox(height: 6),

          // 시간표 메인 그리드 (09:00 ~ 18:00)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 좌측 시간 컬럼
              SizedBox(
                width: _timeColWidth,
                child: Column(
                  children: List.generate(10, (idx) {
                    final h = 9 + idx;
                    return SizedBox(
                      height: _hourRowHeight,
                      child: Text(
                        '${h.toString().padLeft(2, '0')}:00',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.grey[500] : Colors.grey[600],
                        ),
                      ),
                    );
                  }),
                ),
              ),

              // 5개 요일 컬럼 영역
              ..._weekdays.map((day) {
                final dayLectures = dayMap[day] ?? [];

                return Expanded(
                  child: Container(
                    height: _hourRowHeight * 10,
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(color: isDark ? Colors.grey[850]! : Colors.grey[200]!, width: 0.5),
                        right: BorderSide(color: isDark ? Colors.grey[850]! : Colors.grey[200]!, width: 0.5),
                      ),
                    ),
                    child: Stack(
                      children: [
                        // 배경 가로선 & 빈 시간대 터치 등록
                        ...List.generate(10, (hIdx) {
                          final hour = 9 + hIdx;
                          return Positioned(
                            top: hIdx * _hourRowHeight,
                            left: 0,
                            right: 0,
                            height: _hourRowHeight,
                            child: InkWell(
                              onTap: () => _showLectureForm(prefilledDay: day, prefilledHour: hour),
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: BorderSide(
                                      color: isDark ? Colors.grey[850]! : Colors.grey[200]!,
                                      width: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),

                        // 배치된 수업 블록 (파스텔 둥근 카드)
                        ...dayLectures.map((lec) {
                          final timeInfo = _parseLectureTime(lec.time);
                          final top = (timeInfo.start - 9.0) * _hourRowHeight;
                          final height = (timeInfo.duration * _hourRowHeight) - 3.0;
                          final palette = TimetableColorPalette.getColor(lec.title, isDark: isDark);

                          return Positioned(
                            top: top + 1.5,
                            left: 1,
                            right: 1,
                            height: height > 24 ? height : 24,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _showLectureDetailSheet(lec),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: palette.background,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: palette.border, width: 1.2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withAlpha(isDark ? 30 : 10),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        lec.title,
                                        maxLines: height > 70 ? 2 : 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: palette.text,
                                        ),
                                      ),
                                      if (height > 50) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          lec.room.replaceAll('스마트ICT관 ', '').replaceAll('자연과학관 ', ''),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w600,
                                            color: palette.text.withAlpha(210),
                                          ),
                                        ),
                                      ],
                                      if (height > 80 && lec.professor.isNotEmpty) ...[
                                        const Spacer(),
                                        Text(
                                          lec.professor.replaceAll(' 교수', ''),
                                          style: TextStyle(
                                            fontSize: 9,
                                            color: palette.text.withAlpha(180),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. 일별 타임라인 뷰 (Daily Timeline View)
  // ===========================================================================
  Widget _buildDailyTimelineView(List<Lecture> allLectures, bool isDark) {
    // 선택된 요일의 강의만 필터링 후 시간순 정렬
    final filtered = allLectures.where((l) => l.day == _selectedDay).toList()
      ..sort((a, b) {
        final tA = _parseLectureTime(a.time).start;
        final tB = _parseLectureTime(b.time).start;
        return tA.compareTo(tB);
      });

    return Column(
      children: [
        // 상단 요일 선택 칩 (참고 디자인의 탭 바 스타일)
        Container(
          height: 48,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _weekdays.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, idx) {
              final d = _weekdays[idx];
              final isSelected = d == _selectedDay;
              final dayCount = allLectures.where((l) => l.day == d).length;

              return ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$d요일',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : (isDark ? Colors.grey[300] : Colors.grey[800]),
                      ),
                    ),
                    if (dayCount > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white.withAlpha(60) : Colors.grey.withAlpha(60),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$dayCount',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : (isDark ? Colors.grey[300] : Colors.grey[800]),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                selected: isSelected,
                selectedColor: Colors.blue,
                backgroundColor: isDark ? const Color(0xFF282828) : Colors.grey[100],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                onSelected: (_) => setState(() => _selectedDay = d),
              );
            },
          ),
        ),

        // 일별 타임라인 본문
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.event_available_rounded, size: 54, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text(
                        '$_selectedDay요일에는 등록된 수업이 없습니다.',
                        style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () => _showLectureForm(prefilledDay: _selectedDay),
                        icon: const Icon(Icons.add, size: 18),
                        label: Text('$_selectedDay요일 수업 추가하기'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  physics: const BouncingScrollPhysics(),
                  itemCount: filtered.length,
                  itemBuilder: (context, idx) {
                    final lec = filtered[idx];
                    final palette = TimetableColorPalette.getColor(lec.title, isDark: isDark);
                    final isLast = idx == filtered.length - 1;

                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 타임라인 시간 & 트랙 인디케이터 (좌측)
                          SizedBox(
                            width: 68,
                            child: Column(
                              children: [
                                Text(
                                  lec.time.split('~').first,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  lec.time.contains('~') ? lec.time.split('~').last : '',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: palette.iconColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: palette.iconColor.withAlpha(100),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!isLast)
                                  Expanded(
                                    child: Container(
                                      width: 2,
                                      color: palette.border,
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 8),

                          // 타임라인 우측 파스텔 라운드 카드 (참고 디자인 레퍼런스 스타일)
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              decoration: BoxDecoration(
                                color: palette.background,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: palette.border, width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(isDark ? 40 : 12),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(18),
                                  onTap: () => _showLectureDetailSheet(lec),
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // 상단 뱃지 행
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: palette.badgeBackground,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                lec.category,
                                                style: TextStyle(
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: palette.badgeText,
                                                ),
                                              ),
                                            ),
                                            const Spacer(),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withAlpha(isDark ? 30 : 150),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.meeting_room, size: 12, color: palette.text),
                                                  const SizedBox(width: 3),
                                                  Text(
                                                    lec.room,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w600,
                                                      color: palette.text,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 8),

                                        // 과목명
                                        Text(
                                          lec.title,
                                          style: TextStyle(
                                            fontSize: 16.5,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? Colors.white : Colors.black87,
                                          ),
                                        ),

                                        const SizedBox(height: 6),

                                        // 교수님 성함 및 연구실
                                        Row(
                                          children: [
                                            Icon(Icons.person, size: 14, color: palette.iconColor),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${lec.professor.isNotEmpty ? lec.professor : "교수님"} (${lec.professorDept.isNotEmpty ? lec.professorDept : "배재대"})',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: palette.text.withAlpha(220),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),

                                        if (lec.notice.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.orange.withAlpha(20),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: Colors.orange.withAlpha(60)),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.campaign, size: 14, color: Colors.orange),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    lec.notice,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(fontSize: 11, color: Colors.orange),
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
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 3. 전체 목록 뷰 (Course Management List)
  // ===========================================================================
  Widget _buildCourseListView(List<Lecture> lectures, bool isDark) {
    final isProfessor = widget.currentUser.role == '교수';

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: Responsive.padding(context), vertical: 8),
      itemCount: lectures.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, idx) {
        final lec = lectures[idx];
        final palette = TimetableColorPalette.getColor(lec.title, isDark: isDark);

        return Container(
          decoration: BoxDecoration(
            color: palette.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.border, width: 1.2),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _showLectureDetailSheet(lec),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: palette.badgeBackground,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            lec.category,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: palette.badgeText,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            lec.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: palette.border.withAlpha(120),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${lec.day}요일 ${lec.time}',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: palette.text,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.person, size: 14, color: palette.iconColor),
                        const SizedBox(width: 4),
                        Text(
                          '${lec.professor.isNotEmpty ? lec.professor : "교수님"} (${lec.professorDept})',
                          style: TextStyle(fontSize: 12, color: palette.text.withAlpha(220)),
                        ),
                        const Spacer(),
                        Icon(Icons.meeting_room_outlined, size: 14, color: palette.iconColor),
                        const SizedBox(width: 4),
                        Text(
                          lec.room,
                          style: TextStyle(fontSize: 12, color: palette.text.withAlpha(220)),
                        ),
                      ],
                    ),
                    if (isProfessor) ...[
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () => EnrolledStudentsSheet.show(
                              context,
                              lecture: lec,
                              dashboardController: widget.dashboardController,
                            ),
                            icon: const Icon(Icons.group, size: 16),
                            label: Text('수강생 (${lec.enrolledCount}명)'),
                          ),
                          TextButton.icon(
                            onPressed: () => _showNoticeEditDialog(lec),
                            icon: const Icon(Icons.campaign, size: 16, color: Colors.orange),
                            label: const Text('공지', style: TextStyle(color: Colors.orange)),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // Build Main
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    final isProfessor = widget.currentUser.role == '교수';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: Responsive.contentMaxWidth(context)),
            child: AnimatedBuilder(
              animation: widget.dashboardController,
              builder: (context, _) {
                final allLectures = widget.dashboardController.lectures;
                final lectures = _searchQuery.isEmpty
                    ? allLectures
                    : allLectures
                        .where((l) =>
                            l.title.toLowerCase().contains(_searchQuery) ||
                            l.professor.toLowerCase().contains(_searchQuery) ||
                            l.room.toLowerCase().contains(_searchQuery) ||
                            l.category.toLowerCase().contains(_searchQuery))
                        .toList();

                return Column(
                  children: [
                    // 🌟 모던 탑 앱바 (프로필, 주간시간표 타이틀, 검색창, 액션)
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        Responsive.padding(context),
                        10,
                        Responsive.padding(context),
                        6,
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: isProfessor ? Colors.purple : Colors.blue,
                            child: Text(
                              widget.currentUser.name.isNotEmpty
                                  ? widget.currentUser.name.substring(0, 1)
                                  : 'U',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      _selectedView == 0
                                          ? 'Weekly Timetable'
                                          : (_selectedView == 1 ? 'Daily Timeline' : 'Class Courses'),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: (isProfessor ? Colors.purple : Colors.blue).withAlpha(30),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${lectures.length}과목',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.bold,
                                          color: isProfessor ? Colors.purple : Colors.blue,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '${widget.currentUser.school.isNotEmpty ? widget.currentUser.school : "배재대학교"} · ${widget.currentUser.name} ${widget.currentUser.role}',
                                  style: TextStyle(fontSize: 11.5, color: Colors.grey[600]),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          // 상단 캠퍼스 지도 버튼
                          IconButton(
                            tooltip: '캠퍼스 지도 열람 (강의실 위치 확인)',
                            icon: const Icon(Icons.map_rounded, color: Colors.blue),
                            onPressed: () => CampusMapPickerSheet.show(
                              context,
                              universityName: widget.currentUser.school.isNotEmpty
                                  ? widget.currentUser.school
                                  : '배재대학교',
                            ),
                          ),
                          // 상단 추가 버튼
                          IconButton(
                            tooltip: isProfessor ? '새 강의 개설' : '수업 직접 등록',
                            icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
                            onPressed: () => _showLectureForm(),
                          ),
                          if (!isProfessor)
                            IconButton(
                              tooltip: '대학교 57개 정규 강좌 수강 신청',
                              icon: const Icon(Icons.school_rounded, color: Colors.blue),
                              onPressed: () => CourseEnrollmentSheet.show(
                                context,
                                student: widget.currentUser,
                                dashboardController: widget.dashboardController,
                              ),
                            ),
                        ],
                      ),
                    ),

                    // 🔍 실시간 검색창 (참고 이미지 상단 서치바 스타일)
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.padding(context),
                        vertical: 4,
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search classes, professors, rooms...',
                          hintStyle: TextStyle(fontSize: 12.5, color: Colors.grey[500]),
                          prefixIcon: const Icon(Icons.search, size: 18),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 16),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: isDark ? const Color(0xFF262626) : Colors.grey[100],
                          contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
                      ),
                    ),

                    // 🔀 3단 뷰 전환 세그먼트 (주간 그리드 / 일별 타임라인 / 수업 관리)
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.padding(context),
                        vertical: 6,
                      ),
                      child: Container(
                        height: 38,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF262626) : Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            _buildSegmentItem(0, '주간 시간표', Icons.grid_view_rounded),
                            _buildSegmentItem(1, '일별 타임라인', Icons.view_timeline_rounded),
                            _buildSegmentItem(2, '수업 목록', Icons.view_list_rounded),
                          ],
                        ),
                      ),
                    ),

                    // 📱 메인 콘텐츠 뷰
                    Expanded(
                      child: lectures.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.class_outlined, size: 54, color: Colors.grey[400]),
                                  const SizedBox(height: 12),
                                  Text(
                                    _searchQuery.isNotEmpty
                                        ? '검색된 수업이 없습니다.'
                                        : (isProfessor
                                            ? '개설된 수업이 없습니다.\n[+] 버튼을 눌러 수업을 개설하세요.'
                                            : '수강 등록된 수업이 없습니다.\n아래 버튼을 눌러 대학 강좌를 불러오세요.'),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.grey[600], height: 1.4),
                                  ),
                                  if (!isProfessor && _searchQuery.isEmpty) ...[
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      onPressed: () => CourseEnrollmentSheet.show(
                                        context,
                                        student: widget.currentUser,
                                        dashboardController: widget.dashboardController,
                                      ),
                                      icon: const Icon(Icons.school, size: 18),
                                      label: const Text('대학교 57개 정규 강좌 수강 신청'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            )
                          : AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              child: _selectedView == 0
                                  ? _buildWeeklyGridView(lectures, isDark)
                                  : (_selectedView == 1
                                      ? _buildDailyTimelineView(lectures, isDark)
                                      : _buildCourseListView(lectures, isDark)),
                            ),
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

  Widget _buildSegmentItem(int index, String label, IconData icon) {
    final isSelected = _selectedView == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedView = index),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF383838) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withAlpha(isDark ? 50 : 15),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    )
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected
                    ? (isDark ? Colors.blue[300] : Colors.blue[700])
                    : (isDark ? Colors.grey[400] : Colors.grey[600]),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? (isDark ? Colors.white : Colors.black87)
                      : (isDark ? Colors.grey[400] : Colors.grey[600]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
