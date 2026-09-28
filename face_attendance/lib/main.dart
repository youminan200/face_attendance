import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/controllers/auth_controller.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/dashboard/controllers/dashboard_controller.dart';
import 'features/dashboard/screens/main_navigation_screen.dart';

/// 글로벌 내비게이션 키 (컨텍스트 없는 다이얼로그/스낵바 등 지원)
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 한국어 날짜 로케일 초기화
  try {
    await initializeDateFormatting('ko_KR', null);
  } catch (e) {
    debugPrint('로케일 초기화 폴백: $e');
  }

  // 기기 카메라 목록 초기화 (타임아웃 1.5초 가드로 브라우저 무한 로딩 원천 방어)
  List<CameraDescription> cameras = [];
  try {
    cameras = await availableCameras().timeout(
      const Duration(milliseconds: 1500),
      onTimeout: () {
        debugPrint('카메라 장치 탐색 타임아웃 -> UI 즉시 표시');
        return [];
      },
    );
  } catch (e) {
    debugPrint('카메라 장치 초기화 생략/미지원: $e');
  }

  runApp(FaceAttendanceApp(cameras: cameras));
}

/// 앱 최상위 루트 위젯
class FaceAttendanceApp extends StatefulWidget {
  final List<CameraDescription> cameras;

  const FaceAttendanceApp({super.key, required this.cameras});

  @override
  State<FaceAttendanceApp> createState() => _FaceAttendanceAppState();
}

class _FaceAttendanceAppState extends State<FaceAttendanceApp> {
  late final AuthController _authController;
  late final DashboardController _dashboardController;
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _authController = AuthController();
    _dashboardController = DashboardController();
  }

  @override
  void dispose() {
    _authController.dispose();
    _dashboardController.dispose();
    super.dispose();
  }

  void _handleThemeChanged(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Face Pass - 스마트 출결 관리',
      navigatorKey: rootNavigatorKey,
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      builder: (context, child) {
        // iOS Dynamic Type 및 Android 디스플레이 글자 크기 확대 시 UI 깨짐/오버플로우 방지 (0.85x ~ 1.25x 클램핑)
        final clampedMediaQuery = MediaQuery.of(context).copyWith(
          textScaler: MediaQuery.textScalerOf(context).clamp(
            minScaleFactor: 0.85,
            maxScaleFactor: 1.25,
          ),
        );
        return MediaQuery(
          data: clampedMediaQuery,
          child: ScrollConfiguration(
            behavior: const ScrollBehavior().copyWith(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            ),
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      home: AnimatedBuilder(
        animation: _authController,
        builder: (context, _) {
          // 로그인 여부 및 사용자 프로필 완성 여부에 따른 화면 라우팅
          if (_authController.isLoggedIn && _authController.currentUser.name.isNotEmpty) {
            return MainNavigationScreen(
              cameras: widget.cameras,
              authController: _authController,
              dashboardController: _dashboardController,
              currentThemeMode: _themeMode,
              onThemeChanged: _handleThemeChanged,
            );
          }

          return LoginScreen(
            cameras: widget.cameras,
            authController: _authController,
          );
        },
      ),
    );
  }
}
