import '../../models/lecture.dart';
import 'app_clock.dart';

/// 출결 판정 결과 구분자
enum AttendanceMark {
  attendance,     // 출석
  late,           // 지각
  absent,         // 결석
  alreadyChecked, // 이미 오늘 출결 완료
  notToday,       // 오늘 예정된 강의 아님
  invalidTime,    // 시간표 형식 오류
}

/// 출결 판정 결과 DTO
class AttendanceDecision {
  final AttendanceMark mark;
  final String message;

  const AttendanceDecision(this.mark, this.message);
}

/// 출결 시간 자동 판정 엔진
class AttendanceTimeJudge {
  AttendanceTimeJudge._();

  /// 정규식을 통한 강의 시간 문자열 파싱 (예: "13:00~15:00", "09:30 - 11:30", "14시 ~ 16시")
  static DateTime? _timeOfToday(String timeText, int index) {
    final now = AppClock.now();
    final matches = RegExp(r'(\d{1,2})\s*(?::|시)\s*(\d{1,2})?')
        .allMatches(timeText)
        .toList();

    if (matches.isEmpty) return null;

    final safeIndex = index < matches.length ? index : 0;
    final match = matches[safeIndex];
    final hour = int.tryParse(match.group(1) ?? '');
    final minute = int.tryParse(match.group(2) ?? '0') ?? 0;

    if (hour == null || hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return null;
    }

    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  /// 강의 시작 시간 계산
  static DateTime? startTime(Lecture lecture) {
    return _timeOfToday(lecture.time, 0);
  }

  /// 강의 종료 시간 계산 (종료 시간이 미표기된 경우 시작 + 50분)
  static DateTime? endTime(Lecture lecture) {
    final parsedEnd = _timeOfToday(lecture.time, 1);
    if (parsedEnd != null) return parsedEnd;

    final start = startTime(lecture);
    if (start == null) return null;
    return start.add(const Duration(minutes: 50));
  }

  /// 얼굴 인식 성공 시점의 현재 시각 기준 출결 상태 판정
  static AttendanceDecision judgeForFaceSuccess(Lecture lecture) {
    final now = AppClock.now();
    final todayKey = AppClock.dateKey(now);
    final todayDay = AppClock.koreanWeekday(now);

    // 1. 당일 수업 여부 검증
    if (lecture.day != todayDay) {
      return const AttendanceDecision(
        AttendanceMark.notToday,
        '오늘 예정된 수업이 아닙니다.',
      );
    }

    // 2. 이미 출결 처리 완료 여부 검증
    if (lecture.lastAttendanceDate == todayKey && lecture.lastAttendanceStatus.isNotEmpty) {
      return AttendanceDecision(
        AttendanceMark.alreadyChecked,
        '이미 오늘 [${lecture.lastAttendanceStatus}] 처리된 수업입니다.',
      );
    }

    // 3. 시간표 파싱 유효성 검증
    final start = startTime(lecture);
    final end = endTime(lecture);

    if (start == null || end == null) {
      return const AttendanceDecision(
        AttendanceMark.invalidTime,
        '수업 시간 형식이 올바르지 않습니다. (예: 13:00~15:00)',
      );
    }

    // 4. 시간대별 판정 (결석 -> 지각 -> 출석)
    if (now.isAfter(end)) {
      return const AttendanceDecision(
        AttendanceMark.absent,
        '수업 종료 시간이 지나 결석 처리되었습니다.',
      );
    }

    if (now.isAfter(start)) {
      return const AttendanceDecision(
        AttendanceMark.late,
        '수업 시작 시간이 지나 지각 처리되었습니다.',
      );
    }

    return const AttendanceDecision(
      AttendanceMark.attendance,
      '수업 시작 전 정상 출석 처리되었습니다.',
    );
  }

  /// 수업 종료 후 자동 결석 처리 대상 여부 판정
  static bool shouldAutoAbsent(Lecture lecture) {
    final now = AppClock.now();
    final todayKey = AppClock.dateKey(now);
    final todayDay = AppClock.koreanWeekday(now);

    if (lecture.day != todayDay) return false;
    if (lecture.lastAttendanceDate == todayKey) return false;

    final end = endTime(lecture);
    if (end == null) return false;

    return now.isAfter(end);
  }

  /// UI 표출용 출결 상태 문자열
  static String displayStatus(Lecture lecture) {
    final todayKey = AppClock.dateKey(AppClock.now());
    if (lecture.lastAttendanceDate != todayKey || lecture.lastAttendanceStatus.isEmpty) {
      return '미인증';
    }
    return lecture.lastAttendanceStatus;
  }
}
