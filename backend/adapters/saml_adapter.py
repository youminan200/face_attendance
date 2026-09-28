from typing import Any
from adapters.university_adapter import UniversityAdapter, UniversityAuthResult

class SamlUniversityAdapter(UniversityAdapter):
    """SAML 2.0 / Shibboleth 기반 연합 인증 대학 어댑터 (서울대, 연세대, 성균관대 등)"""

    async def authenticate(self, credentials: dict[str, str]) -> UniversityAuthResult:
        username = credentials.get("username", "")
        password = credentials.get("password", "")
        saml_response = credentials.get("saml_response", "")

        # 실제 상용 연동 시:
        # SAML Assertion 파싱 및 XML 서명 검증 -> NameID / Attribute 추출
        if username and password:
            return UniversityAuthResult(
                success=True,
                student_id=username,
                name=f"{self.university.name} 학우",
                department="학부",
                message=f"{self.university.name} SAML 2.0 통합 로그인에 성공했습니다.",
            )
        elif saml_response:
            return UniversityAuthResult(
                success=True,
                student_id="20262002",
                name="SAML 인증 학생",
                department="자연과학대학",
                message="SAML Assertion 검증 성공",
            )
        return UniversityAuthResult(success=False, message="SAML 인증 자격 증명이 올바르지 않습니다.")

    async def fetch_enrolled_courses(self, student_id: str, token: str = "") -> list[dict[str, Any]]:
        return [
            {
                "id": f"{self.university.code}_201",
                "title": f"[{self.university.name}] 기초 인공지능",
                "time": "10:00~12:00",
                "room": "자연관 101호",
                "day": "화",
                "professor": "박교수",
            },
            {
                "id": f"{self.university.code}_202",
                "title": f"[{self.university.name}] 데이터베이스 시스템",
                "time": "14:00~16:00",
                "room": "IT관 402호",
                "day": "목",
                "professor": "최교수",
            },
        ]

    async def push_attendance_record(self, record: dict[str, Any]) -> bool:
        print(f"[{self.university.name}] SAML 기반 학사 시스템으로 출석 전송: {record}")
        return True
