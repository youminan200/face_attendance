import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/api_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/app_clock.dart';
import '../../../core/utils/attendance_time_judge.dart';
import '../../../models/chat_room.dart';
import '../../../models/enrolled_student.dart';
import '../../../models/lecture.dart';
import '../../../models/user_profile.dart';
import '../../attendance/screens/attendance_camera_screen.dart';

/// 대시보드 강의 목록 및 출결 자동 상태 관리자
class DashboardController extends ChangeNotifier {
  final List<Lecture> _lectures = [];
  final List<ChatRoom> _chats = [];
  final ApiClient _apiClient = ApiClient();
  Timer? _autoAbsentTimer;
  bool _isLoading = false;
  String? _errorMessage;

  DashboardController() {
    _initSampleData();
    _startAutoAbsentTimer();
  }

  List<Lecture> get lectures => List.unmodifiable(_lectures);
  List<ChatRoom> get chats => List.unmodifiable(_chats);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _initSampleData() {
    // 기본 초기 샘플 강의 데이터 (오프라인 폴백용)
    _lectures.addAll([
      Lecture(
        id: '1',
        title: '모바일 앱 프로그래밍',
        time: '13:00~15:00',
        room: '공학관 402호',
        day: '월',
        professor: '김교수',
        professorId: 'prof_kim',
        professorDept: '컴퓨터공학과',
        professorOffice: '공학관 402호 연구실 (010-3333-5555)',
        notice: '중간고사 프로젝트 주제 사전 승인이 다음 주 월요일까지 진행됩니다.',
        enrolledCount: 28,
      ),
      Lecture(
        id: '2',
        title: '인공지능 개론',
        time: '15:30~17:30',
        room: 'ICT관 201호',
        day: '수',
        professor: '이교수',
        professorId: 'prof_lee',
        professorDept: '인공지능학과',
        professorOffice: 'ICT관 705호 (010-7777-8888)',
        notice: '실습 환경(PyTorch/TensorFlow) 설정을 미리 완료해 오시기 바랍니다.',
        enrolledCount: 35,
      ),
      Lecture(
        id: '3',
        title: '컴퓨터 비전',
        time: '10:00~12:00',
        room: '융합관 501호',
        day: '금',
        professor: '박교수',
        professorId: 'prof_park',
        professorDept: '소프트웨어학부',
        professorOffice: '융합관 501호 (010-9999-1111)',
        notice: 'OpenCV와 ML Kit 얼굴 검출 파이프라인 과제가 게시되었습니다.',
        enrolledCount: 22,
      ),
    ]);

    _chats.addAll([
      ChatRoom(title: '모바일 앱 질의응답'),
      ChatRoom(title: '인공지능 스터디'),
    ]);
  }

  /// 사용자 역할에 따른 강의 목록 서버 동기화
  Future<void> loadCoursesForUser(UserProfile user) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final endpoint = (user.role == '교수')
          ? ApiConfig.profCoursesEndpoint(user.id)
          : ApiConfig.studentCoursesEndpoint(user.id);

      final res = await _apiClient.get(endpoint);
      if (res.isSuccess && res.data != null && res.data!['courses'] is List) {
        final list = (res.data!['courses'] as List)
            .map((item) => Lecture.fromMap(Map<String, dynamic>.from(item)))
            .toList();

        if (list.isNotEmpty) {
          _lectures.clear();
          _lectures.addAll(list);
        }
      }
    } catch (e) {
      debugPrint('강의 목록 서버 동기화 실패 (로컬 캐시 유지): $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 교수님 새 수업 개설
  Future<bool> createCourse(Lecture lecture, UserProfile professor) async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _apiClient.post(
        ApiConfig.coursesEndpoint,
        body: {
          'course_name': lecture.title,
          'professor_id': professor.id,
          'professor_name': professor.name,
          'professor_dept': professor.major,
          'professor_office': lecture.professorOffice.isNotEmpty
              ? lecture.professorOffice
              : '${professor.school} ${professor.major} 연구실',
          'day': lecture.day,
          'time': lecture.time,
          'room': lecture.room,
          'notice': lecture.notice,
        },
      );

      if (res.isSuccess && res.data != null && res.data!['course'] != null) {
        final created = Lecture.fromMap(Map<String, dynamic>.from(res.data!['course']));
        _lectures.insert(0, created);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('수업 개설 API 통신 실패 -> 로컬 추가: $e');
    }

    // 오프라인/폴백 로컬 등록
    _lectures.insert(0, lecture);
    _isLoading = false;
    notifyListeners();
    return true;
  }

  /// 교수님 수업 공지사항 업데이트
  Future<bool> updateCourseNotice(String courseId, String newNotice) async {
    try {
      final res = await _apiClient.put(
        ApiConfig.courseNoticeEndpoint(courseId),
        body: {'notice': newNotice},
      );
      if (res.isSuccess) {
        final idx = _lectures.indexWhere((l) => l.id == courseId);
        if (idx != -1) {
          _lectures[idx].notice = newNotice;
          _lectures[idx].noticeUpdatedAt = DateTime.now().toString().substring(0, 19);
          notifyListeners();
        }
        return true;
      }
    } catch (e) {
      debugPrint('공지사항 서버 업데이트 실패 -> 로컬 반영: $e');
    }

    // 로컬 즉시 반영
    final idx = _lectures.indexWhere((l) => l.id == courseId);
    if (idx != -1) {
      _lectures[idx].notice = newNotice;
      _lectures[idx].noticeUpdatedAt = DateTime.now().toString().substring(0, 19);
      notifyListeners();
      return true;
    }
    return false;
  }

  /// 학생의 교수님 수업 수강 등록 (수업 추가)
  Future<bool> enrollCourse(Lecture course, UserProfile student) async {
    try {
      final res = await _apiClient.post(
        ApiConfig.courseEnrollEndpoint(course.id),
        body: {'student_id': student.id},
      );
      if (res.isSuccess) {
        if (!_lectures.any((l) => l.id == course.id)) {
          _lectures.add(course);
          notifyListeners();
        }
        return true;
      }
    } catch (e) {
      debugPrint('수강 등록 API 실패 -> 로컬 반영: $e');
    }

    if (!_lectures.any((l) => l.id == course.id)) {
      _lectures.add(course);
      notifyListeners();
    }
    return true;
  }

  /// 학생의 수업 수강 취소
  Future<bool> unenrollCourse(String courseId, String studentId) async {
    try {
      await _apiClient.delete(
        ApiConfig.courseEnrollEndpoint(courseId),
        queryParams: {'student_id': studentId},
      );
    } catch (_) {}

    _lectures.removeWhere((l) => l.id == courseId);
    notifyListeners();
    return true;
  }

  /// 교수님용: 특정 수업에 등록된 수강생 목록 가져오기
  Future<List<EnrolledStudent>> fetchEnrolledStudents(String courseId) async {
    try {
      final res = await _apiClient.get(ApiConfig.courseStudentsEndpoint(courseId));
      if (res.isSuccess && res.data != null && res.data!['students'] is List) {
        return (res.data!['students'] as List)
            .map((item) => EnrolledStudent.fromMap(Map<String, dynamic>.from(item)))
            .toList();
      }
    } catch (e) {
      debugPrint('수강생 명단 서버 조회 실패: $e');
    }

    // 오프라인 폴백 샘플 수강생 명단 반환
    return [
      const EnrolledStudent(
        studentId: '20261001',
        name: '김민준',
        school: '한국대학교',
        major: '컴퓨터공학과',
        attCount: 8,
        lateCount: 1,
        absCount: 0,
        hasFaceRegistered: true,
        lastAttendanceStatus: '출석',
      ),
      const EnrolledStudent(
        studentId: '20261002',
        name: '이지은',
        school: '한국대학교',
        major: '컴퓨터공학과',
        attCount: 9,
        lateCount: 0,
        absCount: 0,
        hasFaceRegistered: true,
        lastAttendanceStatus: '출석',
      ),
      const EnrolledStudent(
        studentId: '20261003',
        name: '박도현',
        school: '한국대학교',
        major: '인공지능학과',
        attCount: 6,
        lateCount: 2,
        absCount: 1,
        hasFaceRegistered: true,
        lastAttendanceStatus: '지각',
      ),
    ];
  }

  /// 실시간 대학교 종합정보시스템에서 수강신청 내역 일괄 불러오기 (동기화)
  Future<int> syncUniversityCourses(UserProfile student, {String? schoolOverride}) async {
    _isLoading = true;
    notifyListeners();

    int addedCount = 0;
    try {
      final res = await _apiClient.post(
        ApiConfig.universitySyncEndpoint,
        body: {
          'student_id': student.id,
          'student_name': student.name,
          'student_major': student.major,
          'school_name': schoolOverride ?? student.school,
        },
      );

      if (res.isSuccess && res.data != null && res.data!['courses'] is List) {
        final synced = (res.data!['courses'] as List)
            .map((c) => Lecture.fromMap(Map<String, dynamic>.from(c)))
            .toList();

        for (final item in synced) {
          final idx = _lectures.indexWhere((l) => l.id == item.id || l.title == item.title);
          if (idx < 0) {
            _lectures.add(item);
            addedCount++;
          } else {
            // 정보 최신화
            _lectures[idx] = item;
          }
        }
      }
    } catch (e) {
      debugPrint('대학교 수강정보 실시간 동기화 통신 예외: $e');
    }

    // 통신 장애 시 기본 대학 수강 정보 프리셋으로 오프라인 동기화 폴백
    if (addedCount == 0 && _lectures.isEmpty) {
      final fallbackDefaults = _getUniversityDefaultCatalog();
      for (final item in fallbackDefaults.take(3)) {
        if (!_lectures.any((l) => l.title == item.title)) {
          _lectures.add(item);
          addedCount++;
        }
      }
    }

    _isLoading = false;
    notifyListeners();
    return addedCount;
  }

  /// 진학사 기반 대한민국 전국 468개 대학교 실시간 검색
  Future<List<Map<String, dynamic>>> searchUniversities({String query = ''}) async {
    try {
      final res = await _apiClient.get(
        ApiConfig.universitiesEndpoint,
        queryParams: query.isNotEmpty ? {'q': query} : null,
      );
      if (res.isSuccess && res.data != null && res.data!['universities'] is List) {
        return (res.data!['universities'] as List)
            .map((u) => Map<String, dynamic>.from(u))
            .toList();
      }
    } catch (e) {
      debugPrint('대학교 목록 검색 실패: $e');
    }
    return [];
  }

  /// 대학교 실제 캠퍼스 지도 레이아웃 및 건물/강의실 데이터 실시간 조회
  Future<Map<String, dynamic>?> getUniversityCampusMap(String schoolName) async {
    try {
      final res = await _apiClient.get(
        ApiConfig.universityCampusMapEndpoint,
        queryParams: {'school_name': schoolName},
      );
      if (res.isSuccess && res.data != null && res.data!['campus_map'] is Map) {
        return Map<String, dynamic>.from(res.data!['campus_map']);
      }
    } catch (e) {
      debugPrint('대학교 캠퍼스 맵 조회 실패: $e');
    }
    return null;
  }

  /// 학생용: 전체 개설된 강의 검색 (서버 실시간 연동 + 대학교 카탈로그 폴백)
  Future<List<Lecture>> searchAvailableCourses({String query = ''}) async {
    final cleanQuery = query.trim().toLowerCase();
    try {
      final res = await _apiClient.get(
        ApiConfig.coursesEndpoint,
        queryParams: query.isNotEmpty ? {'q': query} : null,
      );
      if (res.isSuccess && res.data != null && res.data!['courses'] is List) {
        final courses = (res.data!['courses'] as List)
            .map((item) => Lecture.fromMap(Map<String, dynamic>.from(item)))
            .toList();
        if (courses.isNotEmpty) {
          return courses;
        }
      }
    } catch (e) {
      debugPrint('강의 검색 실패: $e');
    }

    // 서버에 강좌가 없거나 통신 실패 시 대학교 기본 개설 강좌 카탈로그에서 검색
    final catalog = _getUniversityDefaultCatalog();
    if (cleanQuery.isEmpty) {
      return catalog;
    }
    return catalog.where((l) {
      final title = l.title.toLowerCase();
      final prof = l.professor.toLowerCase();
      final room = l.room.toLowerCase();
      final dept = l.professorDept.toLowerCase();
      return title.contains(cleanQuery) ||
          prof.contains(cleanQuery) ||
          room.contains(cleanQuery) ||
          dept.contains(cleanQuery) ||
          (cleanQuery == 'db' && title.contains('데이터베이스'));
    }).toList();
  }

  /// 대학교 종합정보시스템 실제 개설 강좌 기본 카탈로그 (배재대학교 AI소프트웨어공학부 컴퓨터공학전공)
  List<Lecture> _getUniversityDefaultCatalog() {
    return [
      Lecture(
        id: 'pcu_cs_301',
        title: '데이터베이스',
        day: '수',
        time: '10:00~12:00',
        room: '스마트ICT관 SP-302호',
        professor: '정회경 교수',
        professorDept: 'AI소프트웨어공학부 컴퓨터공학전공',
        professorOffice: '스마트ICT관 SP-302호 (042-520-5405)',
        notice: '[공지] 관계형 데이터베이스(MySQL) 모델링 실습 및 SQL 환경 설정 준비 요망',
        enrolledCount: 42,
      ),
      Lecture(
        id: 'pcu_cs_302',
        title: '고급 데이터베이스 프로그래밍',
        day: '목',
        time: '13:00~15:00',
        room: '스마트ICT관 SP-405호',
        professor: '정회경 교수',
        professorDept: 'AI소프트웨어공학부 컴퓨터공학전공',
        professorOffice: '스마트ICT관 SP-405호 (042-520-5405)',
        notice: '[과제] 트랜잭션 동시성 제어 및 NoSQL 몽고DB 연동 실습 과제 안내',
        enrolledCount: 35,
      ),
      Lecture(
        id: 'pcu_cs_305',
        title: '스마트 모바일 앱 개발',
        day: '화',
        time: '14:00~16:00',
        room: '스마트ICT관 SP-201호',
        professor: '김창수 교수',
        professorDept: 'AI소프트웨어공학부 컴퓨터공학전공',
        professorOffice: '스마트ICT관 SP-201호 (042-520-5408)',
        notice: '[수업준비] Flutter 크로스플랫폼 모바일 앱 개발 환경 세팅 안내',
        enrolledCount: 38,
      ),
      Lecture(
        id: 'pcu_cs_201',
        title: '자료구조 및 알고리즘',
        day: '월',
        time: '09:00~11:00',
        room: '스마트ICT관 SP-301호',
        professor: '임선영 교수',
        professorDept: 'AI소프트웨어공학부 컴퓨터공학전공',
        professorOffice: '스마트ICT관 SP-301호 (042-520-5405)',
        notice: '[필독] 중간 프로젝트 팀 편성 및 알고리즘 구현 레포트 제출 기한 공지',
        enrolledCount: 45,
      ),
      Lecture(
        id: 'pcu_cs_204',
        title: '컴퓨터 구조 및 운영체제',
        day: '목',
        time: '10:00~12:00',
        room: '자연관 N-204호',
        professor: '차현종 교수',
        professorDept: 'AI소프트웨어공학부 컴퓨터공학전공',
        professorOffice: '자연관 N-204호 (042-520-5405)',
        notice: '[교안] CPU 스케줄링 및 가상 메모리 관리 교안 업로드 완료',
        enrolledCount: 40,
      ),
      Lecture(
        id: 'pcu_ai_201',
        title: '인공지능 및 딥러닝',
        day: '화',
        time: '15:00~17:00',
        room: '스마트ICT관 SP-402호',
        professor: '이경희 교수',
        professorDept: 'AI소프트웨어공학부 컴퓨터공학전공',
        professorOffice: '스마트ICT관 SP-402호 (042-520-5405)',
        notice: '[실습] 이번 주 실습은 PyTorch 딥러닝 모델 학습으로 진행됩니다.',
        enrolledCount: 48,
      ),
      Lecture(
        id: 'pcu_sec_301',
        title: '정보보안 및 네트워크',
        day: '금',
        time: '13:00~15:00',
        room: '스마트ICT관 SP-501호',
        professor: '이창훈 교수',
        professorDept: 'AI소프트웨어공학부 컴퓨터공학전공 (전공주임)',
        professorOffice: '스마트ICT관 SP-501호 (042-520-5405)',
        notice: '[공지] 네트워크 패킷 캡처 실습 및 암호 프로토콜 분석 가이드',
        enrolledCount: 36,
      ),
      Lecture(
        id: 'pcu_sw_308',
        title: '빅데이터 분석 및 클라우드',
        day: '금',
        time: '10:00~12:00',
        room: '스마트ICT관 SP-305호',
        professor: '송현옥 교수',
        professorDept: 'AI소프트웨어공학부 컴퓨터공학전공',
        professorOffice: '스마트ICT관 SP-305호 (042-520-5405)',
        notice: '[클라우드 실습] 하둡/스파크 빅데이터 분석 분산 환경 계정 발급',
        enrolledCount: 32,
      ),
    ];
  }

  void _startAutoAbsentTimer() {
    _autoAbsentTimer?.cancel();
    _autoAbsentTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      applyAutoAbsences();
    });
  }

  /// 종료 시간이 지난 미출결 수업 자동 결석 처리
  void applyAutoAbsences() {
    var changed = false;
    final todayKey = AppClock.dateKey(AppClock.now());

    for (final lecture in _lectures) {
      if (AttendanceTimeJudge.shouldAutoAbsent(lecture)) {
        lecture.abs += 1;
        lecture.lastAttendanceDate = todayKey;
        lecture.lastAttendanceStatus = '결석';
        changed = true;
      }
    }

    if (changed) {
      notifyListeners();
    }
  }

  void addLecture(Lecture lecture) {
    _lectures.add(lecture);
    notifyListeners();
  }

  void updateLecture(Lecture lecture) {
    final index = _lectures.indexWhere((l) => l.id == lecture.id);
    if (index != -1) {
      _lectures[index] = lecture;
      notifyListeners();
    }
  }

  void deleteLecture(String lectureId) {
    _lectures.removeWhere((l) => l.id == lectureId);
    notifyListeners();
  }

  void addChat(String title) {
    if (title.trim().isNotEmpty) {
      _chats.add(ChatRoom(title: title.trim()));
      notifyListeners();
    }
  }

  /// 얼굴 인식 기반 강의 출석 프로세스 실행
  Future<void> processAttendance({
    required BuildContext context,
    required Lecture lecture,
    required List<CameraDescription> cameras,
    required UserProfile user,
  }) async {
    applyAutoAbsences();

    final todayKey = AppClock.dateKey(AppClock.now());
    if (lecture.lastAttendanceDate == todayKey) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('이미 오늘 [${lecture.lastAttendanceStatus}] 처리된 수업입니다.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AttendanceCameraScreen(
          cameras: cameras,
          lectureTitle: '${lecture.title} 출석 인증',
          isSignUp: false,
          referenceFaceTemplate: user.faceTemplate,
          referenceImagePath: user.imagePath,
        ),
      ),
    );

    if (!context.mounted) return;

    if (result == 'SUCCESS') {
      final decision = AttendanceTimeJudge.judgeForFaceSuccess(lecture);
      final nowKey = AppClock.dateKey(AppClock.now());
      Color snackColor = Colors.blue;

      switch (decision.mark) {
        case AttendanceMark.attendance:
          lecture.att += 1;
          lecture.lastAttendanceDate = nowKey;
          lecture.lastAttendanceStatus = '출석';
          snackColor = Colors.green;
          break;
        case AttendanceMark.late:
          lecture.late += 1;
          lecture.lastAttendanceDate = nowKey;
          lecture.lastAttendanceStatus = '지각';
          snackColor = Colors.orange;
          break;
        case AttendanceMark.absent:
          lecture.abs += 1;
          lecture.lastAttendanceDate = nowKey;
          lecture.lastAttendanceStatus = '결석';
          snackColor = Colors.red;
          break;
        case AttendanceMark.alreadyChecked:
        case AttendanceMark.notToday:
        case AttendanceMark.invalidTime:
          snackColor = Colors.redAccent;
          break;
      }

      notifyListeners();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(decision.message),
          backgroundColor: snackColor,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  void dispose() {
    _autoAbsentTimer?.cancel();
    super.dispose();
  }
}
