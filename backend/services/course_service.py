import datetime
from config.database import get_connection

def create_course(
    course_name: str,
    professor_id: str,
    professor_name: str,
    professor_dept: str = "",
    professor_office: str = "",
    day: str = "월",
    time: str = "13:00~15:00",
    room: str = "공학관 101호",
    course_code: str = "",
    notice: str = "",
) -> dict | None:
    """교수님의 새 강의 개설"""
    conn = get_connection()
    if not conn:
        return None

    if not course_code:
        course_code = f"CRS-{int(datetime.datetime.now().timestamp())}"

    try:
        cur = conn.cursor()
        now_str = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        if conn.is_sqlite:
            sql = """
                INSERT INTO courses (
                    course_code, course_name, professor_id, professor_name,
                    professor_dept, professor_office, day, time, room, notice, notice_updated_at
                )
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """
            cur.execute(sql, (
                course_code, course_name, professor_id, professor_name,
                professor_dept, professor_office, day, time, room, notice, now_str
            ))
            course_id = cur.lastrowid
        else:
            sql = """
                INSERT INTO courses (
                    course_code, course_name, professor_id, professor_name,
                    professor_dept, professor_office, day, time, room, notice, notice_updated_at
                )
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            """
            cur.execute(sql, (
                course_code, course_name, professor_id, professor_name,
                professor_dept, professor_office, day, time, room, notice, now_str
            ))
            course_id = cur.lastrowid

        conn.commit()
        return get_course_detail(course_id)
    except Exception as e:
        print(f"[강의 개설 오류] {e}")
        return None
    finally:
        conn.close()

def get_course_detail(course_id: int) -> dict | None:
    """강의 상세 및 수강생 수 조회"""
    conn = get_connection()
    if not conn:
        return None

    try:
        cur = conn.cursor()
        sql = """
            SELECT c.*,
                   (SELECT COUNT(*) FROM course_enrollments e WHERE e.course_id = c.id) as enrolled_count
            FROM courses c
            WHERE c.id = ?
        """ if conn.is_sqlite else """
            SELECT c.*,
                   (SELECT COUNT(*) FROM course_enrollments e WHERE e.course_id = c.id) as enrolled_count
            FROM courses c
            WHERE c.id = %s
        """
        cur.execute(sql, (course_id,))
        row = cur.fetchone()
        if row:
            d = dict(row)
            d["id"] = str(d["id"])
            return d
        return None
    except Exception as e:
        print(f"[강의 상세 조회 오류] {e}")
        return None
    finally:
        conn.close()

def get_courses(query: str = None, professor_id: str = None) -> list:
    """전체 또는 교수별 강의 목록 조회"""
    conn = get_connection()
    if not conn:
        return []

    try:
        cur = conn.cursor()
        clauses = []
        params = []

        if professor_id:
            clauses.append("c.professor_id = ?")
            params.append(professor_id)

        if query:
            clean_q = query.strip()
            q_like = f"%{clean_q}%"
            clauses.append("(c.course_name LIKE ? OR c.professor_name LIKE ? OR c.course_code LIKE ? OR c.professor_dept LIKE ? OR c.room LIKE ? OR c.category LIKE ?)")
            params.extend([q_like, q_like, q_like, q_like, q_like, q_like])

        where_stmt = "WHERE " + " AND ".join(clauses) if clauses else ""

        if not conn.is_sqlite:
            where_stmt = where_stmt.replace("?", "%s")

        sql = f"""
            SELECT c.*,
                   (SELECT COUNT(*) FROM course_enrollments e WHERE e.course_id = c.id) as enrolled_count
            FROM courses c
            {where_stmt}
            ORDER BY c.id DESC
        """
        cur.execute(sql, params)
        rows = cur.fetchall()
        result = []
        for r in rows:
            d = dict(r)
            d["id"] = str(d["id"])
            result.append(d)
        return result
    except Exception as e:
        print(f"[강의 목록 조회 오류] {e}")
        return []
    finally:
        conn.close()

def update_course_notice(course_id: int, notice: str) -> bool:
    """교수님의 수업 공지사항 업데이트"""
    conn = get_connection()
    if not conn:
        return False

    try:
        cur = conn.cursor()
        now_str = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        sql = """
            UPDATE courses
            SET notice = ?, notice_updated_at = ?
            WHERE id = ?
        """ if conn.is_sqlite else """
            UPDATE courses
            SET notice = %s, notice_updated_at = %s
            WHERE id = %s
        """
        cur.execute(sql, (notice, now_str, course_id))
        conn.commit()
        return cur.rowcount > 0
    except Exception as e:
        print(f"[수업 공지 업데이트 오류] {e}")
        return False
    finally:
        conn.close()

def update_course(course_id: int, data: dict) -> bool:
    """수업 정보 수정"""
    conn = get_connection()
    if not conn:
        return False

    try:
        cur = conn.cursor()
        fields = []
        params = []
        for key in ["course_name", "day", "time", "room", "professor_dept", "professor_office"]:
            if key in data:
                fields.append(f"{key} = ?")
                params.append(data[key])

        if not fields:
            return True

        params.append(course_id)
        set_clause = ", ".join(fields)
        if not conn.is_sqlite:
            set_clause = set_clause.replace("?", "%s")

        sql = f"UPDATE courses SET {set_clause} WHERE id = ?"
        if not conn.is_sqlite:
            sql = f"UPDATE courses SET {set_clause} WHERE id = %s"

        cur.execute(sql, params)
        conn.commit()
        return True
    except Exception as e:
        print(f"[강의 정보 수정 오류] {e}")
        return False
    finally:
        conn.close()

def delete_course(course_id: int) -> bool:
    """강의 삭제 및 수강생 매핑 삭제"""
    conn = get_connection()
    if not conn:
        return False

    try:
        cur = conn.cursor()
        if conn.is_sqlite:
            cur.execute("DELETE FROM course_enrollments WHERE course_id = ?", (course_id,))
            cur.execute("DELETE FROM courses WHERE id = ?", (course_id,))
        else:
            cur.execute("DELETE FROM course_enrollments WHERE course_id = %s", (course_id,))
            cur.execute("DELETE FROM courses WHERE id = %s", (course_id,))
        conn.commit()
        return True
    except Exception as e:
        print(f"[강의 삭제 오류] {e}")
        return False
    finally:
        conn.close()

def enroll_student(course_id: int, student_id: str) -> bool:
    """학생의 수업 수강 등록 (교수님 수업 추가)"""
    conn = get_connection()
    if not conn:
        return False

    try:
        cur = conn.cursor()
        # 학생 정보 조회
        student_sql = "SELECT name, major FROM students WHERE student_id = ?" if conn.is_sqlite else "SELECT name, major FROM students WHERE student_id = %s"
        cur.execute(student_sql, (student_id,))
        s_row = cur.fetchone()
        name = s_row["name"] if s_row else ""
        major = s_row["major"] if s_row else ""

        # 수강 등록 (중복 무시)
        insert_sql = """
            INSERT OR IGNORE INTO course_enrollments (course_id, student_id, student_name, student_major)
            VALUES (?, ?, ?, ?)
        """ if conn.is_sqlite else """
            INSERT IGNORE INTO course_enrollments (course_id, student_id, student_name, student_major)
            VALUES (%s, %s, %s, %s)
        """
        cur.execute(insert_sql, (course_id, student_id, name, major))
        conn.commit()
        return True
    except Exception as e:
        print(f"[수강 등록 오류] {e}")
        return False
    finally:
        conn.close()

def unenroll_student(course_id: int, student_id: str) -> bool:
    """학생 수강 취소"""
    conn = get_connection()
    if not conn:
        return False

    try:
        cur = conn.cursor()
        sql = "DELETE FROM course_enrollments WHERE course_id = ? AND student_id = ?" if conn.is_sqlite else "DELETE FROM course_enrollments WHERE course_id = %s AND student_id = %s"
        cur.execute(sql, (course_id, student_id))
        conn.commit()
        return True
    except Exception as e:
        print(f"[수강 취소 오류] {e}")
        return False
    finally:
        conn.close()

def get_enrolled_students(course_id: int) -> list:
    """특정 수업에 등록된 학생 목록 및 프로필/출결 현황 조회 (교수님 화면용)"""
    conn = get_connection()
    if not conn:
        return []

    try:
        cur = conn.cursor()
        sql = """
            SELECT e.student_id,
                   COALESCE(s.name, e.student_name) as name,
                   COALESCE(s.school, '') as school,
                   COALESCE(s.major, e.student_major) as major,
                   COALESCE(s.face_template, '') as face_template,
                   e.enrolled_at,
                   (SELECT COUNT(*) FROM attendance_records a WHERE a.course_id = e.course_id AND a.student_id = e.student_id AND a.status = '출석') as att_count,
                   (SELECT COUNT(*) FROM attendance_records a WHERE a.course_id = e.course_id AND a.student_id = e.student_id AND a.status = '지각') as late_count,
                   (SELECT COUNT(*) FROM attendance_records a WHERE a.course_id = e.course_id AND a.student_id = e.student_id AND a.status = '결석') as abs_count,
                   (SELECT a.attendance_date FROM attendance_records a WHERE a.course_id = e.course_id AND a.student_id = e.student_id ORDER BY a.id DESC LIMIT 1) as last_attendance_date,
                   (SELECT a.status FROM attendance_records a WHERE a.course_id = e.course_id AND a.student_id = e.student_id ORDER BY a.id DESC LIMIT 1) as last_attendance_status
            FROM course_enrollments e
            LEFT JOIN students s ON e.student_id = s.student_id
            WHERE e.course_id = ?
            ORDER BY name ASC
        """ if conn.is_sqlite else """
            SELECT e.student_id,
                   COALESCE(s.name, e.student_name) as name,
                   COALESCE(s.school, '') as school,
                   COALESCE(s.major, e.student_major) as major,
                   COALESCE(s.face_template, '') as face_template,
                   e.enrolled_at,
                   (SELECT COUNT(*) FROM attendance_records a WHERE a.course_id = e.course_id AND a.student_id = e.student_id AND a.status = '출석') as att_count,
                   (SELECT COUNT(*) FROM attendance_records a WHERE a.course_id = e.course_id AND a.student_id = e.student_id AND a.status = '지각') as late_count,
                   (SELECT COUNT(*) FROM attendance_records a WHERE a.course_id = e.course_id AND a.student_id = e.student_id AND a.status = '결석') as abs_count,
                   (SELECT a.attendance_date FROM attendance_records a WHERE a.course_id = e.course_id AND a.student_id = e.student_id ORDER BY a.id DESC LIMIT 1) as last_attendance_date,
                   (SELECT a.status FROM attendance_records a WHERE a.course_id = e.course_id AND a.student_id = e.student_id ORDER BY a.id DESC LIMIT 1) as last_attendance_status
            FROM course_enrollments e
            LEFT JOIN students s ON e.student_id = s.student_id
            WHERE e.course_id = %s
            ORDER BY name ASC
        """
        cur.execute(sql, (course_id,))
        rows = cur.fetchall()
        result = []
        for r in rows:
            d = dict(r)
            d["has_face_registered"] = bool(d.get("face_template"))
            d.pop("face_template", None)
            result.append(d)
        return result
    except Exception as e:
        print(f"[수강생 목록 조회 오류] {e}")
        return []
    finally:
        conn.close()

def get_student_courses(student_id: str) -> list:
    """학생이 수강 신청한 강의 목록 조회 (학생 화면용, 교수님 정보 및 최신 공지 포함)"""
    conn = get_connection()
    if not conn:
        return []

    try:
        cur = conn.cursor()
        sql = """
            SELECT c.*,
                   (SELECT COUNT(*) FROM course_enrollments ce WHERE ce.course_id = c.id) as enrolled_count
            FROM course_enrollments e
            JOIN courses c ON e.course_id = c.id
            WHERE e.student_id = ?
            ORDER BY c.day, c.time
        """ if conn.is_sqlite else """
            SELECT c.*,
                   (SELECT COUNT(*) FROM course_enrollments ce WHERE ce.course_id = c.id) as enrolled_count
            FROM course_enrollments e
            JOIN courses c ON e.course_id = c.id
            WHERE e.student_id = %s
            ORDER BY c.day, c.time
        """
        cur.execute(sql, (student_id,))
        rows = cur.fetchall()
        result = []
        for r in rows:
            d = dict(r)
            d["id"] = str(d["id"])
            result.append(d)
        return result
    except Exception as e:
        print(f"[학생 수강 과목 조회 오류] {e}")
        return []
    finally:
        conn.close()
