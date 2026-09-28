import hashlib
from config.database import get_connection

def hash_password(password: str) -> str:
    """비밀번호 SHA-256 해시 생성"""
    return hashlib.sha256(password.encode("utf-8")).hexdigest()

def register_student(student_id: str, password: str, name: str, school: str, major: str, face_template: str) -> bool:
    """학생 회원가입 및 얼굴 템플릿 저장"""
    conn = get_connection()
    if not conn:
        return False

    hashed = hash_password(password)
    try:
        cur = conn.cursor()
        if conn.is_sqlite:
            sql = """
                INSERT INTO students (student_id, password, name, school, major, face_template)
                VALUES (?, ?, ?, ?, ?, ?)
            """
            cur.execute(sql, (student_id, hashed, name, school, major, face_template))
        else:
            sql = """
                INSERT INTO students (student_id, password, name, school, major, face_template)
                VALUES (%s, %s, %s, %s, %s, %s)
            """
            cur.execute(sql, (student_id, hashed, name, school, major, face_template))

        conn.commit()
        return True
    except Exception as e:
        print(f"[학생 등록 오류] {e}")
        return False
    finally:
        conn.close()

def get_student_profile(student_id: str, password: str) -> dict | None:
    """학생 로그인 검증 및 프로필 반환"""
    conn = get_connection()
    if not conn:
        return None

    hashed = hash_password(password)
    try:
        cur = conn.cursor()
        if conn.is_sqlite:
            # 평문 또는 해시 비밀번호 호환
            sql = "SELECT * FROM students WHERE student_id = ? AND (password = ? OR password = ?)"
            cur.execute(sql, (student_id, hashed, password))
        else:
            sql = "SELECT * FROM students WHERE student_id = %s AND (password = %s OR password = %s)"
            cur.execute(sql, (student_id, hashed, password))

        row = cur.fetchone()
        if row:
            # dict 또는 sqlite Row 처리
            profile = dict(row)
            # 보안을 위해 패스워드는 응답에서 제거
            profile.pop("password", None)
            return {
                "id": profile.get("student_id"),
                "name": profile.get("name"),
                "school": profile.get("school", ""),
                "major": profile.get("major", ""),
                "faceTemplate": profile.get("face_template", ""),
                "imagePath": profile.get("image_path", ""),
                "role": "학생"
            }
        return None
    except Exception as e:
        print(f"[학생 조회 오류] {e}")
        return None
    finally:
        conn.close()
