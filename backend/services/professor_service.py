import hashlib
from config.database import get_connection

def hash_password(password: str) -> str:
    """비밀번호 SHA-256 해시 생성"""
    return hashlib.sha256(password.encode("utf-8")).hexdigest()

def register_professor(login_id: str, password: str, name: str, school: str, department: str, face_template: str) -> bool:
    """교수 회원가입 및 얼굴 템플릿 저장"""
    conn = get_connection()
    if not conn:
        return False

    hashed = hash_password(password)
    try:
        cur = conn.cursor()
        if conn.is_sqlite:
            sql = """
                INSERT INTO professors (login_id, password, name, school, department, face_template)
                VALUES (?, ?, ?, ?, ?, ?)
            """
            cur.execute(sql, (login_id, hashed, name, school, department, face_template))
        else:
            sql = """
                INSERT INTO professors (login_id, password, name, school, department, face_template)
                VALUES (%s, %s, %s, %s, %s, %s)
            """
            cur.execute(sql, (login_id, hashed, name, school, department, face_template))

        conn.commit()
        return True
    except Exception as e:
        print(f"[교수 등록 오류] {e}")
        return False
    finally:
        conn.close()

def get_professor_profile(login_id: str, password: str) -> dict | None:
    """교수 로그인 검증 및 프로필 반환"""
    conn = get_connection()
    if not conn:
        return None

    hashed = hash_password(password)
    try:
        cur = conn.cursor()
        if conn.is_sqlite:
            sql = "SELECT * FROM professors WHERE login_id = ? AND (password = ? OR password = ?)"
            cur.execute(sql, (login_id, hashed, password))
        else:
            sql = "SELECT * FROM professors WHERE login_id = %s AND (password = %s OR password = %s)"
            cur.execute(sql, (login_id, hashed, password))

        row = cur.fetchone()
        if row:
            profile = dict(row)
            profile.pop("password", None)
            return {
                "id": profile.get("login_id"),
                "name": profile.get("name"),
                "school": profile.get("school", ""),
                "major": profile.get("department", ""),
                "faceTemplate": profile.get("face_template", ""),
                "imagePath": profile.get("image_path", ""),
                "role": "교수"
            }
        return None
    except Exception as e:
        print(f"[교수 조회 오류] {e}")
        return None
    finally:
        conn.close()
