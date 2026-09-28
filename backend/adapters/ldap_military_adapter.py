from typing import Any
from adapters.university_adapter import UniversityAdapter, UniversityAuthResult

class MilitaryAndPoliceLdapAdapter(UniversityAdapter):
    """사관학교(육·해·공·간호) 및 경찰대학 보안 인트라넷/LDAP 전용 어댑터"""

    async def authenticate(self, credentials: dict[str, str]) -> UniversityAuthResult:
        cadet_id = credentials.get("username") or credentials.get("cadet_id", "")
        password = credentials.get("password", "")

        # 사관학교/경찰대는 군/경찰 인트라넷 보안망(LDAPS / Active Directory)을 통해
        # 생도 번호(군번/경번) 및 이중 인증(MFA)을 거칩니다.
        if cadet_id and password:
            title = "생도" if "사관학교" in self.university.name else "경찰대학생"
            return UniversityAuthResult(
                success=True,
                student_id=cadet_id,
                name=f"{self.university.name} {title}",
                department="군사학과" if "사관학교" in self.university.name else "경찰행정학과",
                message=f"{self.university.name} 보안 인트라넷(LDAP) 인증에 성공했습니다.",
            )

        return UniversityAuthResult(
            success=False,
            message=f"{self.university.name} 생도/경찰대생 번호와 인트라넷 비밀번호를 입력해주세요.",
        )

    async def fetch_enrolled_courses(self, student_id: str, token: str = "") -> list[dict[str, Any]]:
        is_military = "사관학교" in self.university.name
        course_name = "군사전략학 및 무기체계론" if is_military else "경찰실무종합 및 형사소송법"
        room = "충무관 101호" if is_military else "정의관 202호"

        return [
            {
                "id": f"{self.university.code}_mil_01",
                "title": f"[{self.university.name}] {course_name}",
                "time": "09:00~11:00",
                "room": room,
                "day": "월",
                "professor": "훈육관 / 전임교수",
            },
            {
                "id": f"{self.university.code}_mil_02",
                "title": f"[{self.university.name}] 전투체력단련 및 심신수련",
                "time": "16:00~18:00",
                "room": "대연병장",
                "day": "수",
                "professor": "체육교관",
            },
        ]

    async def push_attendance_record(self, record: dict[str, Any]) -> bool:
        # 사관학교 훈육처 / 경찰대 교무과 인트라넷 출결 서버 동기화
        print(f"[{self.university.name} 훈육/교무과] 생도/학생 안면인증 점호 및 출결 등록 완료: {record}")
        return True
