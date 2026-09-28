from models.university import University, AuthProtocol
from adapters.university_adapter import UniversityAdapter
from adapters.oauth_adapter import OAuthUniversityAdapter
from adapters.saml_adapter import SamlUniversityAdapter
from adapters.ldap_military_adapter import MilitaryAndPoliceLdapAdapter
from adapters.rest_adapter import RestApiUniversityAdapter

class UniversityAdapterFactory:
    """대학 프로토콜에 적합한 전용 어댑터를 생성하는 팩토리"""

    @staticmethod
    def get_adapter(university: University) -> UniversityAdapter:
        if university.protocol == AuthProtocol.MILITARY_LDAP:
            return MilitaryAndPoliceLdapAdapter(university)
        elif university.protocol == AuthProtocol.SAML2:
            return SamlUniversityAdapter(university)
        elif university.protocol == AuthProtocol.OAUTH2:
            return OAuthUniversityAdapter(university)
        else:
            return RestApiUniversityAdapter(university)
