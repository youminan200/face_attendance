from abc import ABC, abstractmethod
from typing import Any
from models.university import University

class UniversityAuthResult:
    def __init__(self, success: bool, student_id: str = "", name: str = "", department: str = "", message: str = ""):
        self.success = success
        self.student_id = student_id
        self.name = name
        self.department = department
        self.message = message

    def to_dict(self) -> dict[str, Any]:
        return {
            "success": self.success,
            "student_id": self.student_id,
            "name": self.name,
            "department": self.department,
            "message": self.message,
        }

class UniversityAdapter(ABC):
    """모든 대학교/특수목적대 학사 및 인증 연동을 위한 추상 어댑터"""
    def __init__(self, university: University):
        self.university = university

    @abstractmethod
    async def authenticate(self, credentials: dict[str, str]) -> UniversityAuthResult:
        """대학 포털/SSO 로그인 또는 토큰 검증"""
        pass

    @abstractmethod
    async def fetch_enrolled_courses(self, student_id: str, token: str = "") -> list[dict[str, Any]]:
        """대학 학사정보 시스템에서 학생의 당학기 수강 과목 목록 조회"""
        pass

    @abstractmethod
    async def push_attendance_record(self, record: dict[str, Any]) -> bool:
        """대학 전자출결/학사 서버로 안면인증 출결 결과 실시간 전송"""
        pass
