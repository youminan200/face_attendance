import 'dart:convert';

/// 회원가입 시 생성되는 근거리/원거리 얼굴 특징 벡터 템플릿
class FaceAuthTemplate {
  final List<double> nearVector;
  final List<double> farVector;

  static const int expectedVectorSize = 1024; // 32x32

  const FaceAuthTemplate({
    required this.nearVector,
    required this.farVector,
  });

  /// JSON 문자열 직렬화
  String encode() {
    return jsonEncode({
      'version': 2,
      'near': nearVector,
      'far': farVector,
    });
  }

  /// JSON 문자열 역직렬화
  static FaceAuthTemplate? decode(String value) {
    if (value.trim().isEmpty) return null;

    try {
      final map = jsonDecode(value) as Map<String, dynamic>;
      final nearRaw = map['near'] as List?;
      final farRaw = map['far'] as List?;

      if (nearRaw == null || farRaw == null) return null;

      final near = nearRaw.map((v) => (v as num).toDouble()).toList();
      final far = farRaw.map((v) => (v as num).toDouble()).toList();

      if (near.length != expectedVectorSize || far.length != expectedVectorSize) {
        return null;
      }

      return FaceAuthTemplate(nearVector: near, farVector: far);
    } catch (_) {
      return null;
    }
  }
}

/// 얼굴 인증 결과 모델
class FaceAuthResult {
  final bool passed;
  final double score;
  final String reason;

  const FaceAuthResult({
    required this.passed,
    required this.score,
    required this.reason,
  });
}
