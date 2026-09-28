/// 사용자 프로필 모델
class UserProfile {
  String name;
  String school;
  String id;
  String major;
  String imagePath;
  String password;
  String role;

  /// 회원가입 시 등록된 2차원(근거리+원거리) 얼굴 템플릿 JSON 문자열
  String faceTemplate;

  UserProfile({
    this.name = '',
    this.school = '',
    this.id = '',
    this.major = '',
    this.imagePath = '',
    this.password = '',
    this.role = '학생',
    this.faceTemplate = '',
  });

  UserProfile copyWith({
    String? name,
    String? school,
    String? id,
    String? major,
    String? imagePath,
    String? password,
    String? role,
    String? faceTemplate,
  }) {
    return UserProfile(
      name: name ?? this.name,
      school: school ?? this.school,
      id: id ?? this.id,
      major: major ?? this.major,
      imagePath: imagePath ?? this.imagePath,
      password: password ?? this.password,
      role: role ?? this.role,
      faceTemplate: faceTemplate ?? this.faceTemplate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'school': school,
      'id': id,
      'major': major,
      'image_path': imagePath,
      'password': password,
      'role': role,
      'face_template': faceTemplate,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      name: map['name'] ?? '',
      school: map['school'] ?? '',
      id: (map['id'] ?? map['student_id'] ?? map['login_id'] ?? '').toString(),
      major: map['major'] ?? map['department'] ?? '',
      imagePath: map['image_path'] ?? map['imagePath'] ?? '',
      password: map['password'] ?? '',
      role: map['role'] ?? '학생',
      faceTemplate: map['face_template'] ?? map['faceTemplate'] ?? '',
    );
  }
}
