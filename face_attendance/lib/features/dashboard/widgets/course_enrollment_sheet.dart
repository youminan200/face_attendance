import 'package:flutter/material.dart';
import '../../../models/lecture.dart';
import '../../../models/user_profile.dart';
import '../controllers/dashboard_controller.dart';
import 'campus_map_picker_sheet.dart';

/// 학생 전용: 진학사 기반 전국 468개 대학교 수강정보 시스템 실시간 연동 & 수강 신청 바텀시트
class CourseEnrollmentSheet extends StatefulWidget {
  final UserProfile student;
  final DashboardController dashboardController;

  const CourseEnrollmentSheet({
    super.key,
    required this.student,
    required this.dashboardController,
  });

  static Future<void> show(
    BuildContext context, {
    required UserProfile student,
    required DashboardController dashboardController,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CourseEnrollmentSheet(
        student: student,
        dashboardController: dashboardController,
      ),
    );
  }

  @override
  State<CourseEnrollmentSheet> createState() => _CourseEnrollmentSheetState();
}

class _CourseEnrollmentSheetState extends State<CourseEnrollmentSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<Lecture> _availableCourses = [];
  bool _isLoading = true;
  bool _isSyncing = false;
  String _filter = '';
  String _selectedCategory = '전체';
  late String _selectedSchool;

  final List<String> _categories = [
    '전체',
    '전공필수',
    '전공선택',
    '교양',
    '인공지능/AI',
    '데이터베이스',
    '스마트 모바일',
    '자료구조/알고리즘',
    '운영체제/시스템',
    '보안/네트워크',
    '클라우드/빅데이터',
    '타전공(경영/전자/미디어/간호)',
  ];

  @override
  void initState() {
    super.initState();
    _selectedSchool = widget.student.school.isNotEmpty ? widget.student.school : '배재대학교';
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    setState(() => _isLoading = true);
    final list = await widget.dashboardController.searchAvailableCourses(query: _filter);
    if (mounted) {
      setState(() {
        _availableCourses = list;
        _isLoading = false;
      });
    }
  }

  /// 진학사 기반 전국 468개 대학교 선택 바텀시트
  void _showUniversityPicker() {
    final searchCtrl = TextEditingController();
    List<Map<String, dynamic>> univList = [];
    bool isSearching = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetCtx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          void loadUnivs(String q) async {
            setModalState(() => isSearching = true);
            final results = await widget.dashboardController.searchUniversities(query: q);
            if (ctx.mounted) {
              setModalState(() {
                univList = results;
                isSearching = false;
              });
            }
          }

          if (univList.isEmpty && isSearching) {
            loadUnivs('');
          }

          final isDark = Theme.of(context).brightness == Brightness.dark;

          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(100),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.account_balance, color: Colors.blue),
                      const SizedBox(width: 8),
                      const Text(
                        '전국 대학교 선택 (진학사 공식 연동)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(bottomSheetCtx),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: TextField(
                    controller: searchCtrl,
                    decoration: InputDecoration(
                      hintText: '대학교명 또는 지역 검색 (예: 배재대, 서울대, 충남대)...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF282828) : Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    onChanged: (v) => loadUnivs(v),
                  ),
                ),
                const Divider(height: 8),
                Expanded(
                  child: isSearching
                      ? const Center(child: CircularProgressIndicator())
                      : univList.isEmpty
                          ? Center(
                              child: Text(
                                '검색된 대학교가 없습니다.',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(12),
                              itemCount: univList.length,
                              separatorBuilder: (context, index) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final u = univList[index];
                                final name = u['name'] ?? '';
                                final display = u['display_name'] ?? name;
                                final campus = u['campus'] ?? '';
                                final address = u['address'] ?? '';
                                final isCurrent = _selectedSchool == name || _selectedSchool == display;

                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: isCurrent ? Colors.blue : Colors.grey.withAlpha(50),
                                    foregroundColor: isCurrent ? Colors.white : Colors.blue,
                                    child: const Icon(Icons.school, size: 20),
                                  ),
                                  title: Row(
                                    children: [
                                      Text(
                                        display,
                                        style: TextStyle(
                                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                                          color: isCurrent ? Colors.blue : null,
                                        ),
                                      ),
                                      if (campus.isNotEmpty) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withAlpha(25),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            campus,
                                            style: const TextStyle(fontSize: 10, color: Colors.blue),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  subtitle: Text(
                                    address,
                                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.map_rounded, color: Colors.blue, size: 20),
                                        tooltip: '$display 캠퍼스 지도 보기',
                                        onPressed: () {
                                          CampusMapPickerSheet.show(
                                            context,
                                            universityName: name,
                                          );
                                        },
                                      ),
                                      if (isCurrent)
                                        const Icon(Icons.check_circle, color: Colors.blue)
                                      else
                                        const Icon(Icons.chevron_right, color: Colors.grey),
                                    ],
                                  ),
                                  onTap: () {
                                    setState(() {
                                      _selectedSchool = name;
                                    });
                                    Navigator.pop(bottomSheetCtx);
                                    _handleSyncUniversityCourses();
                                  },
                                );
                              },
                            ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 대학교 종합정보시스템 실시간 동기화
  Future<void> _handleSyncUniversityCourses() async {
    setState(() => _isSyncing = true);
    final count = await widget.dashboardController.syncUniversityCourses(
      widget.student,
      schoolOverride: _selectedSchool,
    );
    if (mounted) {
      setState(() => _isSyncing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  count > 0
                      ? '$_selectedSchool 학사정보시스템에서 $count개 실제 수강 과목을 불러왔습니다!'
                      : '$_selectedSchool 수강정보 시스템의 최신 수업 정보가 동기화되어 있습니다.',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.blue[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadCourses();
    }
  }

  /// 학생이 실제 수강 중인 수업을 직접 등록하는 다이얼로그
  void _showCustomCourseDialog() {
    final titleCtrl = TextEditingController(text: _filter.isNotEmpty ? _filter : '');
    final profCtrl = TextEditingController();
    final roomCtrl = TextEditingController(text: '스마트ICT관 301호');
    final timeCtrl = TextEditingController(text: '10:00~12:00');
    final noticeCtrl = TextEditingController();
    String selectedDay = '월';

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              const Icon(Icons.edit_calendar_rounded, color: Colors.blue),
              const SizedBox(width: 8),
              const Text('실제 수강 과목 직접 등록', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '현재 실제로 수강 중인 수업 정보를 입력하면 내 시간표와 출결 목록에 즉시 등록됩니다.',
                  style: TextStyle(fontSize: 12.5, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: '과목명 (예: 데이터베이스, 웹프로그래밍)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.book),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: profCtrl,
                  decoration: const InputDecoration(
                    labelText: '담당 교수님 성함 (예:홍길동)',
                    hintText: '예:홍길동',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
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
                          labelText: '요일',
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
                        controller: timeCtrl,
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
                  controller: roomCtrl,
                  decoration: InputDecoration(
                    labelText: '강의실 (예: 스마트ICT관 SP-302호)',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.meeting_room),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.map_rounded, color: Colors.blue),
                      tooltip: '실제 캠퍼스 지도에서 강의실 선택',
                      onPressed: () async {
                        final selected = await CampusMapPickerSheet.show(
                          context,
                          universityName: _selectedSchool,
                          initialRoom: roomCtrl.text,
                        );
                        if (selected != null) {
                          setDialogState(() {
                            roomCtrl.text = selected;
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noticeCtrl,
                  decoration: const InputDecoration(
                    labelText: '수업 공지/메모 (선택)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.note),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final title = titleCtrl.text.trim();
                final prof = profCtrl.text.trim();
                if (title.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('과목명을 입력해주세요.')),
                  );
                  return;
                }

                final customCourse = Lecture(
                  id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                  title: title,
                  day: selectedDay,
                  time: timeCtrl.text.trim().isNotEmpty ? timeCtrl.text.trim() : '10:00~12:00',
                  room: roomCtrl.text.trim().isNotEmpty ? roomCtrl.text.trim() : '강의실',
                  professor: prof.isNotEmpty ? prof : '교수님',
                  professorDept: widget.student.major,
                  professorOffice: '$_selectedSchool ${widget.student.major}',
                  notice: noticeCtrl.text.trim(),
                  enrolledCount: 1,
                );

                await widget.dashboardController.enrollCourse(customCourse, widget.student);
                if (dialogCtx.mounted) {
                  Navigator.pop(dialogCtx);
                }
                if (mounted) {
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('실제 수강 과목 [$title]이 내 시간표에 성공적으로 등록되었습니다!'),
                      backgroundColor: Colors.blue[700],
                    ),
                  );
                  _loadCourses();
                }
              },
              child: const Text('내 시간표에 등록'),
            ),
          ],
        ),
      ),
    );
  }

  void _onCategorySelected(String cat) {
    setState(() {
      _selectedCategory = cat;
      if (cat == '전체') {
        _filter = '';
        _searchController.clear();
      } else if (cat == '인공지능/AI') {
        _filter = '인공지능';
        _searchController.text = '인공지능';
      } else if (cat == '자료구조/알고리즘') {
        _filter = '알고리즘';
        _searchController.text = '알고리즘';
      } else if (cat == '운영체제/시스템') {
        _filter = '운영체제';
        _searchController.text = '운영체제';
      } else if (cat == '보안/네트워크') {
        _filter = '보안';
        _searchController.text = '보안';
      } else if (cat == '클라우드/빅데이터') {
        _filter = '클라우드';
        _searchController.text = '클라우드';
      } else if (cat.startsWith('타전공')) {
        _filter = '타전공';
        _searchController.text = '타전공';
      } else {
        _filter = cat;
        _searchController.text = cat;
      }
    });
    _loadCourses();
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
    final deptName = widget.student.major.isNotEmpty ? widget.student.major : 'AI소프트웨어공학부 컴퓨터공학전공';

    final myLectureIds = widget.dashboardController.lectures.map((l) => l.id).toSet();
    final myLectureTitles = widget.dashboardController.lectures.map((l) => l.title).toSet();

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.school_rounded, color: Colors.blue, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              '$_selectedSchool 수강정보 연동',
                              style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: _showUniversityPicker,
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.withAlpha(30),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.swap_horiz, size: 14, color: Colors.blue),
                                  SizedBox(width: 2),
                                  Text(
                                    '학교 변경',
                                    style: TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '$deptName 실제 개설 강좌를 검색하거나 직접 등록하세요.',
                        style: TextStyle(fontSize: 11.5, color: Colors.grey[600]),
                        overflow: TextOverflow.ellipsis,
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

          // 🎓 실시간 대학교 종합정보시스템 수강내역 일괄 불러오기 배너
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1A2E40), const Color(0xFF233B52)]
                      : [const Color(0xFFEBF4FF), const Color(0xFFE1EFFF)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.withAlpha(80)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withAlpha(40),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.cloud_download_rounded, color: Colors.blue, size: 22),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    '$_selectedSchool 학사 전산망 연동',
                                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: const Text(
                                    '진학사 468개교',
                                    style: TextStyle(fontSize: 9.5, color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '학번: ${widget.student.id} / $deptName',
                              style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[300] : Colors.grey[700]),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _isSyncing ? null : _handleSyncUniversityCourses,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        child: _isSyncing
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text(
                                '수강정보 불러오기',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 직접 등록 & 캠퍼스 지도 바로가기 버튼 Row
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _showCustomCourseDialog,
                          icon: const Icon(Icons.add_circle_outline, size: 15),
                          label: const Text('수업 직접 등록 (+)', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue[700],
                            side: BorderSide(color: Colors.blue.withAlpha(120)),
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => CampusMapPickerSheet.show(
                            context,
                            universityName: _selectedSchool,
                          ),
                          icon: const Icon(Icons.map_rounded, size: 15),
                          label: const Text('캠퍼스 지도 🗺️', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),

                ],
              ),
            ),
          ),

          // 실시간 검색창
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '실제 과목명(데이터베이스, 알고리즘...), 교수님, 강의실 검색...',
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey[500]),
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _filter.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _filter = '';
                            _selectedCategory = '전체';
                          });
                          _loadCourses();
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? const Color(0xFF282828) : Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) {
                setState(() => _filter = val.trim());
                _loadCourses();
              },
            ),
          ),

          // 카테고리 빠른 탐색 칩 리스트
          SizedBox(
            height: 36,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                final cat = _categories[idx];
                final isSelected = _selectedCategory == cat;
                return ChoiceChip(
                  label: Text(
                    cat,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : (isDark ? Colors.grey[300] : Colors.grey[800]),
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: Colors.blue,
                  backgroundColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey[200],
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  onSelected: (_) => _onCategorySelected(cat),
                );
              },
            ),
          ),

          const Divider(height: 10),

          // 개설 강좌 통계 및 상태 헤더
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            child: Row(
              children: [
                Text(
                  '개설 강좌 ${_availableCourses.length}개',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.grey[200] : Colors.grey[800],
                  ),
                ),
                if (_filter.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.withAlpha(30),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '\'$_filter\' 검색 결과',
                      style: const TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  '$_selectedSchool 학사과정',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // 수업 리스트
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _availableCourses.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_off_rounded, size: 44, color: Colors.grey[400]),
                            const SizedBox(height: 10),
                            Text(
                              _filter.isEmpty
                                   ? '$_selectedSchool 개설 수업을 불러오는 중입니다.'
                                   : '[$_filter] 검색된 실제 수업이 없습니다.',
                              style: TextStyle(color: Colors.grey[600], fontSize: 13.5),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: _showCustomCourseDialog,
                              icon: const Icon(Icons.add, size: 18),
                              label: Text('$_filter 직접 등록하기'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: EdgeInsets.fromLTRB(16, 4, 16, bottomPadding + 16),
                        physics: const BouncingScrollPhysics(),
                        itemCount: _availableCourses.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (context, idx) {
                          final course = _availableCourses[idx];
                          final isAlreadyEnrolled =
                              myLectureIds.contains(course.id) || myLectureTitles.contains(course.title);

                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF282828) : Colors.grey[50],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isAlreadyEnrolled
                                    ? Colors.blue.withAlpha(120)
                                    : (isDark ? Colors.grey[800]! : Colors.grey[300]!),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (course.courseCode.isNotEmpty) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                        margin: const EdgeInsets.only(right: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.withAlpha(40),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          course.courseCode,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? Colors.grey[300] : Colors.grey[700],
                                          ),
                                        ),
                                      ),
                                    ],
                                    if (course.category.isNotEmpty) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                        margin: const EdgeInsets.only(right: 6),
                                        decoration: BoxDecoration(
                                          color: course.category.contains('필수')
                                              ? Colors.red.withAlpha(30)
                                              : course.category.contains('교양')
                                                  ? Colors.green.withAlpha(30)
                                                  : course.category.contains('타전공')
                                                      ? Colors.purple.withAlpha(30)
                                                      : Colors.blue.withAlpha(30),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          course.category,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: course.category.contains('필수')
                                                ? Colors.red[700]
                                                : course.category.contains('교양')
                                                    ? Colors.green[800]
                                                    : course.category.contains('타전공')
                                                        ? Colors.purple[700]
                                                        : Colors.blue[800],
                                          ),
                                        ),
                                      ),
                                    ],
                                    Expanded(
                                      child: Text(
                                        course.title,
                                        style: const TextStyle(
                                          fontSize: 15.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withAlpha(20),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${course.day}요일 ${course.time}',
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // 교수님 상세 정보 영역 (실제 교수님 실명 및 연구실/학과)
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isDark ? Colors.grey[850]! : Colors.grey[200]!,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.person, size: 16, color: Colors.blueAccent),
                                          const SizedBox(width: 6),
                                          Text(
                                            '담당: ${course.professor.isNotEmpty ? course.professor : "교수님"} (${course.professorDept.isNotEmpty ? course.professorDept : deptName})',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (course.professorOffice.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.location_on_outlined, size: 15, color: Colors.grey),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                '연구실/연락처: ${course.professorOffice}',
                                                style: TextStyle(fontSize: 11.5, color: Colors.grey[600]),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.meeting_room_outlined, size: 15, color: Colors.grey),
                                          const SizedBox(width: 6),
                                          Text(
                                            '강의실: ${course.room}',
                                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                          ),
                                          const Spacer(),
                                          Text(
                                            '수강 인원: ${course.enrolledCount}명',
                                            style: TextStyle(fontSize: 11.5, color: Colors.blue[600], fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // 교수님 공지사항
                                if (course.notice.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withAlpha(25),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.amber.withAlpha(60)),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(Icons.campaign, size: 16, color: Colors.orange),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            course.notice,
                                            style: const TextStyle(fontSize: 11.5, color: Colors.orange),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 10),

                                // 하단 액션 버튼
                                Row(
                                  children: [
                                    if (isAlreadyEnrolled) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withAlpha(30),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Row(
                                          children: [
                                            Icon(Icons.check, size: 16, color: Colors.green),
                                            SizedBox(width: 4),
                                            Text(
                                              '현재 수강 중',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Spacer(),
                                      OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.red,
                                          side: const BorderSide(color: Colors.red),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          minimumSize: Size.zero,
                                        ),
                                        onPressed: () async {
                                          await widget.dashboardController.unenrollCourse(
                                            course.id,
                                            widget.student.id,
                                          );
                                          if (context.mounted) {
                                            setState(() {});
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('${course.title} 수강이 취소되었습니다.')),
                                            );
                                          }
                                        },
                                        child: const Text('수강 취소', style: TextStyle(fontSize: 12)),
                                      ),
                                    ] else ...[
                                      const Spacer(),
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                        icon: const Icon(Icons.add, size: 16),
                                        label: const Text(
                                          '수업 신청 (시간표 추가)',
                                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                                        ),
                                        onPressed: () async {
                                          final ok = await widget.dashboardController.enrollCourse(
                                            course,
                                            widget.student,
                                          );
                                          if (context.mounted) {
                                            setState(() {});
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  ok
                                                      ? '${course.title} 수업이 내 시간표에 추가되었습니다!'
                                                      : '수강 신청에 실패했습니다.',
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    ],
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
}
