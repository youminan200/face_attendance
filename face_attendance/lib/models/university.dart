/// 대학교 메타데이터 모델
class UniversityItem {
  final String code;
  final String name;
  final String region;
  final String domain;
  final String protocol;
  final String portalUrl;

  const UniversityItem({
    required this.code,
    required this.name,
    required this.region,
    required this.domain,
    required this.protocol,
    required this.portalUrl,
  });

  factory UniversityItem.fromJson(Map<String, dynamic> json) {
    return UniversityItem(
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      region: json['region'] ?? '',
      domain: json['domain'] ?? '',
      protocol: json['protocol'] ?? 'REST',
      portalUrl: json['portal_url'] ?? '',
    );
  }
}
