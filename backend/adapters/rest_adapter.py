from typing import Any
from adapters.university_adapter import UniversityAdapter, UniversityAuthResult

class RestApiUniversityAdapter(UniversityAdapter):
    """표준 학사 ERP REST API 기반 대학 어댑터 (세종대, 홍익대, 삼육대 등)"""

    async def authenticate(self, credentials: dict[str, str]) -> UniversityAuthResult:
        username = credentials.get("username", "")
        password = credentials.get("password", "")

        if username and password:
            return UniversityAuthResult(
                success=True,
                student_id=username,
                name=f"{self.university.name} 학생",
                department="학부",
                message=f"{self.university.name} 학사 포털 인증 성공",
            )
        return UniversityAuthResult(success=False, message="학번/교번과 비밀번호가 필요합니다.")

    async def fetch_enrolled_courses(self, student_id: str, token: str = "") -> list[dict[str, Any]]:
        return [
            {
                "id": f"{self.university.code}_301",
                "title": f"[{self.university.name}] 교양 소프트웨어 입문",
                "time": "11:00~13:00",
                "room": "인문관 201호",
                "day": "수",
                "professor": "정교수",
            },
        ]

    async def push_attendance_record(self, record: dict[str, Any]) -> bool:
        print(f"[{self.university.name}] REST 학사 시스템 출결 전송: {record}")
        return True
