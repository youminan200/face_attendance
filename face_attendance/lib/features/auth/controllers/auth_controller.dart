import 'package:flutter/foundation.dart';
import '../../../core/constants/api_config.dart';
import '../../../core/network/api_client.dart';
import '../../../database_helper.dart';
import '../../../models/user_profile.dart';

/// 인증 및 사용자 세션 상태 관리자
class AuthController extends ChangeNotifier {
  final ApiClient _apiClient;
  final DatabaseHelper _dbHelper;

  UserProfile _currentUser = UserProfile();
  bool _isLoggedIn = false;
  bool _isStayLoggedIn = false;
  bool _isLoading = false;
  String? _authError;

  AuthController({ApiClient? apiClient, DatabaseHelper? dbHelper})
      : _apiClient = apiClient ?? ApiClient(),
        _dbHelper = dbHelper ?? DatabaseHelper();

  UserProfile get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;
  bool get isStayLoggedIn => _isStayLoggedIn;
  bool get isLoading => _isLoading;
  String? get authError => _authError;

  void setStayLoggedIn(bool value) {
    _isStayLoggedIn = value;
    notifyListeners();
  }

  void updateUser(UserProfile user) {
    _currentUser = user;
    notifyListeners();
  }

  /// 서버 로그인 처리 및 로컬 캐싱
  Future<bool> login({
    required String id,
    required String password,
    required String role,
  }) async {
    _isLoading = true;
    _authError = null;
    notifyListeners();

    try {
      final response = await _apiClient.post(
        ApiConfig.loginEndpoint,
        body: {
          'id': id,
          'password': password,
          'role': role,
        },
      );

      if (response.isSuccess && response.data != null) {
        final profileData = response.data!['profile'] as Map<String, dynamic>? ?? {};

        _currentUser = UserProfile(
          id: (profileData['id'] ?? id).toString(),
          name: profileData['name'] ?? '',
          school: profileData['school'] ?? '',
          major: profileData['major'] ?? '',
          role: role,
          faceTemplate: profileData['faceTemplate'] ?? profileData['face_template'] ?? '',
          imagePath: profileData['imagePath'] ?? profileData['image_path'] ?? '',
          password: password,
        );

        // 오프라인 대비 로컬 SQLite DB에도 저장
        await _saveUserToLocalDb(_currentUser);

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        // 서버 응답 실패 시 로컬 DB 오프라인 로그인 폴백 시도
        final localUser = await _dbHelper.loginUser(id, password, role);
        if (localUser != null) {
          _currentUser = UserProfile.fromMap(localUser);
          _isLoading = false;
          notifyListeners();
          return true;
        }

        _authError = response.errorMessage ?? '로그인에 실패했습니다.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      // 네트워크 예외 시 로컬 DB 검사
      final localUser = await _dbHelper.loginUser(id, password, role);
      if (localUser != null) {
        _currentUser = UserProfile.fromMap(localUser);
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _authError = '네트워크 연결 오류: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 회원가입 처리
  Future<bool> signUp(UserProfile user) async {
    _isLoading = true;
    _authError = null;
    notifyListeners();

    try {
      final response = await _apiClient.post(
        ApiConfig.signUpEndpoint,
        body: {
          'school': user.school,
          'major': user.major,
          'name': user.name,
          'id': user.id,
          'role': user.role,
          'password': user.password,
          'faceTemplate': user.faceTemplate,
        },
      );

      if (response.isSuccess) {
        _currentUser = user;
        await _saveUserToLocalDb(user);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _authError = response.errorMessage ?? '회원가입에 실패했습니다.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _authError = '회원가입 통신 오류: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 본인 인증(카메라) 성공 후 최종 로그인 세션 활성화
  void completeLogin() {
    _isLoggedIn = true;
    notifyListeners();
  }

  /// 로그아웃
  void logout() {
    _isLoggedIn = false;
    _currentUser = UserProfile();
    notifyListeners();
  }

  Future<void> _saveUserToLocalDb(UserProfile user) async {
    try {
      final Map<String, dynamic> localData = (user.role == '교수')
          ? {
              'login_id': user.id,
              'password': user.password,
              'name': user.name,
              'school': user.school,
              'department': user.major,
              'face_template': user.faceTemplate,
              'image_path': user.imagePath,
            }
          : {
              'student_id': user.id,
              'password': user.password,
              'name': user.name,
              'school': user.school,
              'major': user.major,
              'face_template': user.faceTemplate,
              'image_path': user.imagePath,
            };
      await _dbHelper.insertUser(localData, user.role);
    } catch (e) {
      debugPrint('로컬 DB 동기화 오류: $e');
    }
  }
}
