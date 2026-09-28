import os
import sqlite3
import pymysql

# 환경 변수 기반 데이터베이스 타입 결정 ('mysql' 또는 'sqlite')
DB_TYPE = os.getenv("DB_TYPE", "sqlite").lower()

MYSQL_HOST = os.getenv("DB_HOST", "localhost")
MYSQL_PORT = int(os.getenv("DB_PORT", "3306"))
MYSQL_USER = os.getenv("DB_USER", "root")
MYSQL_PASSWORD = os.getenv("DB_PASSWORD", "1234")
MYSQL_DATABASE = os.getenv("DB_NAME", "face_attendance")

SQLITE_DB_PATH = os.getenv("SQLITE_PATH", os.path.join(os.path.dirname(__file__), "..", "face_attendance.db"))

class DatabaseConnection:
    """SQLite와 MySQL을 동일한 인터페이스로 다룰 수 있는 추상화 래퍼"""
    def __init__(self, conn, is_sqlite=True):
        self.conn = conn
        self.is_sqlite = is_sqlite

    def cursor(self):
        if self.is_sqlite:
            cur = self.conn.cursor()
            return cur
        else:
            return self.conn.cursor(pymysql.cursors.DictCursor)

    def commit(self):
        self.conn.commit()

    def close(self):
        self.conn.close()

def get_connection():
    """DB 연결 객체를 반환합니다."""
    if DB_TYPE == "mysql":
        try:
            raw_conn = pymysql.connect(
                host=MYSQL_HOST,
                port=MYSQL_PORT,
                user=MYSQL_USER,
                password=MYSQL_PASSWORD,
                database=MYSQL_DATABASE,
                charset="utf8mb4"
            )
            return DatabaseConnection(raw_conn, is_sqlite=False)
        except Exception as e:
            print(f"[경고] MySQL 연결 실패: {e}. 내장 SQLite로 자동 전환합니다.")
            return _get_sqlite_connection()
    else:
        return _get_sqlite_connection()

def _get_sqlite_connection():
    raw_conn = sqlite3.connect(SQLITE_DB_PATH, check_same_thread=False)
    # 딕셔너리 형태로 컬럼 접근 가능하게 설정
    raw_conn.row_factory = sqlite3.Row
    return DatabaseConnection(raw_conn, is_sqlite=True)

def init_db():
    """서버 시작 시 테이블이 없으면 자동으로 생성합니다."""
    conn = get_connection()
    try:
        cur = conn.cursor()
        
        # 학생 테이블
        cur.execute("""
            CREATE TABLE IF NOT EXISTS students (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                student_id TEXT UNIQUE NOT NULL,
                password TEXT NOT NULL,
                name TEXT NOT NULL,
                school TEXT,
                major TEXT,
                face_template TEXT,
                image_path TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)

        # 교수 테이블
        cur.execute("""
            CREATE TABLE IF NOT EXISTS professors (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                login_id TEXT UNIQUE NOT NULL,
                password TEXT NOT NULL,
                name TEXT NOT NULL,
                school TEXT,
                department TEXT,
                face_template TEXT,
                image_path TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)

        # 강의 테이블
        cur.execute("""
            CREATE TABLE IF NOT EXISTS courses (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                course_code TEXT,
                course_name TEXT NOT NULL,
                professor_id TEXT,
                professor_name TEXT,
                professor_dept TEXT,
                professor_office TEXT,
                day TEXT DEFAULT '월',
                time TEXT DEFAULT '13:00~15:00',
                room TEXT DEFAULT '공학관 101호',
                notice TEXT DEFAULT '',
                notice_updated_at TIMESTAMP,
                category TEXT DEFAULT '전공선택',
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)

        # 기존 courses 테이블 컬럼 마이그레이션 (SQLite 호환)
        if conn.is_sqlite:
            cur.execute("PRAGMA table_info(courses)")
            existing_cols = [row["name"] if isinstance(row, dict) or hasattr(row, "keys") else row[1] for row in cur.fetchall()]
            new_columns = [
                ("course_code", "TEXT"),
                ("professor_name", "TEXT"),
                ("professor_dept", "TEXT"),
                ("professor_office", "TEXT"),
                ("day", "TEXT DEFAULT '월'"),
                ("time", "TEXT DEFAULT '13:00~15:00'"),
                ("room", "TEXT DEFAULT '공학관 101호'"),
                ("notice", "TEXT DEFAULT ''"),
                ("notice_updated_at", "TIMESTAMP"),
                ("category", "TEXT DEFAULT '전공선택'"),
            ]
            for col_name, col_type in new_columns:
                if col_name not in existing_cols:
                    try:
                        cur.execute(f"ALTER TABLE courses ADD COLUMN {col_name} {col_type}")
                    except Exception as e:
                        print(f"[마이그레이션 안내] courses.{col_name} 추가 생략: {e}")

        # 수강생 등록 테이블 (학생이 교수님 수업에 등록/추가)
        cur.execute("""
            CREATE TABLE IF NOT EXISTS course_enrollments (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                course_id INTEGER NOT NULL,
                student_id TEXT NOT NULL,
                student_name TEXT,
                student_major TEXT,
                enrolled_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                UNIQUE(course_id, student_id)
            )
        """)

        # 출결 이력 테이블
        cur.execute("""
            CREATE TABLE IF NOT EXISTS attendance_records (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                course_id INTEGER NOT NULL,
                student_id TEXT NOT NULL,
                student_name TEXT,
                attendance_date TEXT NOT NULL,
                status TEXT NOT NULL DEFAULT '출석',
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)

        conn.commit()
        print("[DB 초기화] 데이터베이스 테이블 준비 및 마이그레이션 완료.")
        
        # 대학교 표준 개설 강좌 (데이터베이스 등) 자동 시딩
        try:
            from services.university_portal_service import seed_university_courses_if_needed
            seed_university_courses_if_needed()
        except Exception as se:
            print(f"[시딩 호출 안내] {se}")

    except Exception as e:
        print(f"[DB 초기화 오류] {e}")
    finally:
        conn.close()