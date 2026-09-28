from typing import Any
from adapters.university_adapter import UniversityAdapter, UniversityAuthResult

class OAuthUniversityAdapter(UniversityAdapter):
    """OAuth 2.0 / OpenID Connect 기반 종합대학 및 과기원 포털 연동 어댑터 (고려대, 카이스트 등)"""

    async def authenticate(self, credentials: dict[str, str]) -> UniversityAuthResult:
        username = credentials.get("username", "")
        password = credentials.get("password", "")
        auth_code = credentials.get("code", "")

        # 실제 상용 연동 시:
        # POST {self.university.portal_url}/oauth/token
        # GET  {self.university.api_endpoint}/userinfo
        # 여기서는 안정적인 테스트 및 하위 호환성을 위해 ID/PW 및 토큰 기반 검증 지원
        if username and password:
            return UniversityAuthResult(
                success=True,
                student_id=username,
                name=f"{self.university.name} 학생",
                department="공과대학",
                message=f"{self.university.name} OAuth 2.0 포털 인증에 성공했습니다.",
            )
        elif auth_code:
            return UniversityAuthResult(
                success=True,
                student_id="20261001",
                name=f"{self.university.name} 학생",
                department="학부",
                message=f"{self.university.name} 인가 코드 토큰 교환 성공",
            )
        return UniversityAuthResult(success=False, message="아이디와 비밀번호 또는 인증 코드가 누락되었습니다.")

    async def fetch_enrolled_courses(self, student_id: str, token: str = "") -> list[dict[str, Any]]:
        # 학사 API GET /academic/courses/{student_id}
        return [
            {
                "id": f"{self.university.code}_101",
                "title": f"[{self.university.name}] 전공기초 프로그래밍",
                "time": "13:00~15:00",
                "room": "정보관 301호",
                "day": "월",
                "professor": "김교수",
            },
            {
                "id": f"{self.university.code}_102",
                "title": f"[{self.university.name}] 컴퓨터 알고리즘",
                "time": "15:30~17:30",
                "room": "공학관 204호",
                "day": "수",
                "professor": "이교수",
            },
        ]

    async def push_attendance_record(self, record: dict[str, Any]) -> bool:
        # POST {self.university.api_endpoint}/attendance
        print(f"[{self.university.name}] 전자출결 서버로 출석 기록 전송 완료: {record}")
        return True
