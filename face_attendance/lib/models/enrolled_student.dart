/// 교수님 화면에서 확인 가능한 수강생 정보 및 출결 모델
class EnrolledStudent {
  final String studentId;
  final String name;
  final String school;
  final String major;
  final String enrolledAt;
  final int attCount;
  final int lateCount;
  final int absCount;
  final bool hasFaceRegistered;
  final String lastAttendanceDate;
  final String lastAttendanceStatus;

  const EnrolledStudent({
    required this.studentId,
    required this.name,
    this.school = '',
    this.major = '',
    this.enrolledAt = '',
    this.attCount = 0,
    this.lateCount = 0,
    this.absCount = 0,
    this.hasFaceRegistered = false,
    this.lastAttendanceDate = '',
    this.lastAttendanceStatus = '',
  });

  int get totalClasses => attCount + lateCount + absCount;

  double get attendanceRate {
    if (totalClasses == 0) return 100.0;
    // 출석 1.0, 지각 0.5 반영
    final score = (attCount * 1.0) + (lateCount * 0.5);
    return (score / totalClasses) * 100.0;
  }

  factory EnrolledStudent.fromMap(Map<String, dynamic> map) {
    return EnrolledStudent(
      studentId: (map['student_id'] ?? map['studentId'] ?? '').toString(),
      name: map['name'] ?? map['student_name'] ?? '익명 학생',
      school: map['school'] ?? '',
      major: map['major'] ?? map['student_major'] ?? '',
      enrolledAt: map['enrolled_at'] ?? map['enrolledAt'] ?? '',
      attCount: (map['att_count'] as num?)?.toInt() ?? 0,
      lateCount: (map['late_count'] as num?)?.toInt() ?? 0,
      absCount: (map['abs_count'] as num?)?.toInt() ?? 0,
      hasFaceRegistered: map['has_face_registered'] == true || map['hasFaceRegistered'] == true,
      lastAttendanceDate: map['last_attendance_date'] ?? '',
      lastAttendanceStatus: map['last_attendance_status'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'student_id': studentId,
      'name': name,
      'school': school,
      'major': major,
      'enrolled_at': enrolledAt,
      'att_count': attCount,
      'late_count': lateCount,
      'abs_count': absCount,
      'has_face_registered': hasFaceRegistered,
      'last_attendance_date': lastAttendanceDate,
      'last_attendance_status': lastAttendanceStatus,
    };
  }
}
