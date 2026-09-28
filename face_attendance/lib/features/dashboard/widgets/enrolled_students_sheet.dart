import 'package:flutter/material.dart';
import '../../../models/enrolled_student.dart';
import '../../../models/lecture.dart';
import '../controllers/dashboard_controller.dart';

/// 교수님 전용: 수강생 명단 및 출결 현황 조회 바텀시트
class EnrolledStudentsSheet extends StatefulWidget {
  final Lecture lecture;
  final DashboardController dashboardController;

  const EnrolledStudentsSheet({
    super.key,
    required this.lecture,
    required this.dashboardController,
  });

  static Future<void> show(
    BuildContext context, {
    required Lecture lecture,
    required DashboardController dashboardController,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EnrolledStudentsSheet(
        lecture: lecture,
        dashboardController: dashboardController,
      ),
    );
  }

  @override
  State<EnrolledStudentsSheet> createState() => _EnrolledStudentsSheetState();
}

class _EnrolledStudentsSheetState extends State<EnrolledStudentsSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<EnrolledStudent> _students = [];
  bool _isLoading = true;
  String _filter = '';

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    final list = await widget.dashboardController.fetchEnrolledStudents(widget.lecture.id);
    if (mounted) {
      setState(() {
        _students = list;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    final filtered = _students.where((s) {
      if (_filter.isEmpty) return true;
      final q = _filter.toLowerCase();
      return s.name.toLowerCase().contains(q) ||
          s.studentId.contains(q) ||
          s.major.toLowerCase().contains(q);
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // 상단 핸들 바
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(100),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // 헤더 타이틀
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.people_alt_rounded, color: theme.colorScheme.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.lecture.title} 수강생 명단',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '총 ${_students.length}명 등록됨 · ${widget.lecture.day}요일 ${widget.lecture.time}',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // 검색 필터
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '학생 이름, 학번 또는 학과 검색...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _filter.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _filter = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (val) => setState(() => _filter = val.trim()),
            ),
          ),

          const Divider(height: 16),

          // 수강생 리스트
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person_off_outlined, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            Text(
                              _filter.isEmpty
                                  ? '아직 이 수업에 등록된 학생이 없습니다.'
                                  : '검색 조건과 일치하는 학생이 없습니다.',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPadding + 16),
                        physics: const BouncingScrollPhysics(),
                        itemCount: filtered.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (context, idx) {
                          final student = filtered[idx];
                          final rate = student.attendanceRate;

                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF282828) : Colors.grey[50],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: theme.colorScheme.primary.withAlpha(25),
                                      child: Text(
                                        student.name.isNotEmpty ? student.name[0] : '학',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                student.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: student.hasFaceRegistered
                                                      ? Colors.green.withAlpha(25)
                                                      : Colors.orange.withAlpha(25),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  student.hasFaceRegistered ? '얼굴등록완료' : '얼굴미등록',
                                                  style: TextStyle(
                                                    fontSize: 10.5,
                                                    fontWeight: FontWeight.bold,
                                                    color: student.hasFaceRegistered
                                                        ? Colors.green[700]
                                                        : Colors.orange[800],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${student.studentId} · ${student.major.isNotEmpty ? student.major : student.school}',
                                            style: TextStyle(fontSize: 12.5, color: Colors.grey[600]),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // 1:1 상담 채팅 버튼
                                    IconButton(
                                      tooltip: '1:1 상담 채팅',
                                      icon: const Icon(Icons.chat_bubble_outline, size: 20),
                                      onPressed: () {
                                        widget.dashboardController.addChat('${student.name} 학생 상담');
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('[${student.name}] 학생과의 1:1 상담 채팅방이 개설되었습니다.'),
                                            backgroundColor: Colors.blue[700],
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                const Divider(height: 1),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        _statBadge('출석 ${student.attCount}', Colors.green),
                                        const SizedBox(width: 6),
                                        _statBadge('지각 ${student.lateCount}', Colors.orange),
                                        const SizedBox(width: 6),
                                        _statBadge('결석 ${student.absCount}', Colors.red),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        const Text('출석률 ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                        Text(
                                          '${rate.toStringAsFixed(0)}%',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: rate >= 80 ? Colors.green[700] : Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _statBadge(String label, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(70)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color[800]),
      ),
    );
  }
}
