/// 강의 정보 및 출결 현황 모델
class Lecture {
  String id;
  String title;
  String time;
  String room;
  String day;
  String professor;
  String professorId;
  String professorDept;
  String professorOffice;
  String notice;
  String noticeUpdatedAt;
  int enrolledCount;
  int att;
  int late;
  int abs;
  String lastAttendanceDate;
  String lastAttendanceStatus;
  String category;
  String courseCode;

  Lecture({
    required this.id,
    required this.title,
    required this.time,
    required this.room,
    required this.day,
    required this.professor,
    this.professorId = '',
    this.professorDept = '',
    this.professorOffice = '',
    this.notice = '',
    this.noticeUpdatedAt = '',
    this.enrolledCount = 0,
    this.att = 0,
    this.late = 0,
    this.abs = 0,
    this.lastAttendanceDate = '',
    this.lastAttendanceStatus = '',
    this.category = '전공선택',
    this.courseCode = '',
  });

  Lecture copyWith({
    String? id,
    String? title,
    String? time,
    String? room,
    String? day,
    String? professor,
    String? professorId,
    String? professorDept,
    String? professorOffice,
    String? notice,
    String? noticeUpdatedAt,
    int? enrolledCount,
    int? att,
    int? late,
    int? abs,
    String? lastAttendanceDate,
    String? lastAttendanceStatus,
    String? category,
    String? courseCode,
  }) {
    return Lecture(
      id: id ?? this.id,
      title: title ?? this.title,
      time: time ?? this.time,
      room: room ?? this.room,
      day: day ?? this.day,
      professor: professor ?? this.professor,
      professorId: professorId ?? this.professorId,
      professorDept: professorDept ?? this.professorDept,
      professorOffice: professorOffice ?? this.professorOffice,
      notice: notice ?? this.notice,
      noticeUpdatedAt: noticeUpdatedAt ?? this.noticeUpdatedAt,
      enrolledCount: enrolledCount ?? this.enrolledCount,
      att: att ?? this.att,
      late: late ?? this.late,
      abs: abs ?? this.abs,
      lastAttendanceDate: lastAttendanceDate ?? this.lastAttendanceDate,
      lastAttendanceStatus: lastAttendanceStatus ?? this.lastAttendanceStatus,
      category: category ?? this.category,
      courseCode: courseCode ?? this.courseCode,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'time': time,
      'room': room,
      'day': day,
      'professor': professor,
      'professor_id': professorId,
      'professor_dept': professorDept,
      'professor_office': professorOffice,
      'notice': notice,
      'notice_updated_at': noticeUpdatedAt,
      'enrolled_count': enrolledCount,
      'att': att,
      'late': late,
      'abs': abs,
      'last_attendance_date': lastAttendanceDate,
      'last_attendance_status': lastAttendanceStatus,
      'category': category,
      'course_code': courseCode,
    };
  }

  factory Lecture.fromMap(Map<String, dynamic> map) {
    return Lecture(
      id: map['id']?.toString() ?? '',
      title: map['title'] ?? map['course_name'] ?? '',
      time: map['time'] ?? '13:00~15:00',
      room: map['room'] ?? '공학관 101호',
      day: map['day'] ?? '월',
      professor: map['professor'] ?? map['professor_name'] ?? '',
      professorId: (map['professor_id'] ?? map['professorId'] ?? '').toString(),
      professorDept: map['professor_dept'] ?? map['professorDept'] ?? '',
      professorOffice: map['professor_office'] ?? map['professorOffice'] ?? '',
      notice: map['notice'] ?? '',
      noticeUpdatedAt: map['notice_updated_at'] ?? map['noticeUpdatedAt'] ?? '',
      enrolledCount: (map['enrolled_count'] as num?)?.toInt() ?? 0,
      att: (map['att'] as num?)?.toInt() ?? 0,
      late: (map['late'] as num?)?.toInt() ?? 0,
      abs: (map['abs'] as num?)?.toInt() ?? 0,
      lastAttendanceDate: map['last_attendance_date'] ?? '',
      lastAttendanceStatus: map['last_attendance_status'] ?? '',
      category: map['category'] ?? '전공선택',
      courseCode: map['course_code'] ?? map['courseCode'] ?? '',
    );
  }
}
