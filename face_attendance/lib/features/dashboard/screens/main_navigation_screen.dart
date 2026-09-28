import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/dashboard_controller.dart';
import 'attendance_history_screen.dart';
import 'chat_list_screen.dart';
import 'dashboard_home_screen.dart';
import 'system_management_screen.dart';
import 'timetable_screen.dart';

/// 5단 하단 탭 내비게이션 래퍼 스크린
class MainNavigationScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  final AuthController authController;
  final DashboardController dashboardController;
  final ThemeMode currentThemeMode;
  final ValueChanged<ThemeMode> onThemeChanged;

  const MainNavigationScreen({
    super.key,
    required this.cameras,
    required this.authController,
    required this.dashboardController,
    required this.currentThemeMode,
    required this.onThemeChanged,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.dashboardController.loadCoursesForUser(widget.authController.currentUser);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isProfessor = widget.authController.currentUser.role == '교수';
    final screens = [
      DashboardHomeScreen(
        currentUser: widget.authController.currentUser,
        dashboardController: widget.dashboardController,
        cameras: widget.cameras,
      ),
      TimetableScreen(
        dashboardController: widget.dashboardController,
        currentUser: widget.authController.currentUser,
        cameras: widget.cameras,
      ),
      ChatListScreen(
        dashboardController: widget.dashboardController,
      ),
      AttendanceHistoryScreen(
        dashboardController: widget.dashboardController,
      ),
      SystemManagementScreen(
        currentThemeMode: widget.currentThemeMode,
        onThemeChanged: widget.onThemeChanged,
        authController: widget.authController,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_filled),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(isProfessor ? Icons.class_outlined : Icons.calendar_month_outlined),
            activeIcon: Icon(isProfessor ? Icons.class_rounded : Icons.calendar_month),
            label: isProfessor ? '수업 관리' : '시간표',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: '채팅',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart_outline),
            activeIcon: Icon(Icons.pie_chart),
            label: '통계',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: '설정',
          ),
        ],
      ),
    );
  }
}
