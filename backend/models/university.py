from enum import Enum
from pydantic import BaseModel

class AuthProtocol(str, Enum):
    OAUTH2 = "OAUTH2"       # 차세대 포털 및 구글/MS 연동 (OAuth 2.0 / OIDC)
    SAML2 = "SAML2"         # 전통 대학 포털 및 연합 인증 (SAML 2.0 / Shibboleth)
    MILITARY_LDAP = "LDAP"  # 사관학교, 경찰대, 교내 폐쇄망 보안 LDAP/AD
    REST_API = "REST"       # 학사 ERP 전용 REST/SOAP API

class Region(str, Enum):
    SEOUL_PUBLIC = "서울(국·공립)"
    SEOUL_PRIVATE = "서울(사립)"
    SEOUL_WOMEN = "서울(여대)"
    GYEONGGI_INCHEON = "경기·인천"
    CHUNGCHEONG = "대전·충청·세종"
    YEONGNAM = "부산·울산·경남"
    DAEGU_GYEONGBUK = "대구·경북"
    HONAM_JEJU = "광주·전라·제주"
    TECH_INSTITUTE = "과학기술원"
    SPECIAL_ACADEMY = "사관학교·경찰대"

class University(BaseModel):
    code: str                  # 고유 식별 코드 (예: SNU, KAIST, KMA, KNPU 등)
    name: str                  # 학교명
    region: Region             # 권역
    domain: str                # 학교 도메인 (예: snu.ac.kr, kaist.ac.kr)
    protocol: AuthProtocol     # 연동 프로토콜
    portal_url: str            # 포털/SSO 로그인 URL
    api_endpoint: str = ""     # 학사 정보 API 엔드포인트
