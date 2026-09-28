import 'package:flutter/material.dart';
import '../../auth/controllers/auth_controller.dart';

/// 시스템 설정 및 계정 관리 화면
class SystemManagementScreen extends StatelessWidget {
  final ThemeMode currentThemeMode;
  final ValueChanged<ThemeMode> onThemeChanged;
  final AuthController authController;

  const SystemManagementScreen({
    super.key,
    required this.currentThemeMode,
    required this.onThemeChanged,
    required this.authController,
  });

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('현재 계정에서 로그아웃하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(dialogContext);
              authController.logout();
            },
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = currentThemeMode == ThemeMode.dark;
    final user = authController.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('시스템 설정'),
      ),
      body: ListView(
        children: [
          // 계정 정보 카드
          Container(
            padding: const EdgeInsets.all(20),
            color: Theme.of(context).cardColor,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(25),
                  child: Icon(Icons.person, size: 36, color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${user.name} (${user.role})',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${user.school} | ${user.major}',
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      Text(
                        'ID: ${user.id}',
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              '앱 설정',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),

          // 다크 모드 스위치
          SwitchListTile(
            secondary: Icon(
              isDarkMode ? Icons.dark_mode : Icons.light_mode,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('다크 모드'),
            subtitle: Text(isDarkMode ? '어두운 테마 사용 중' : '밝은 테마 사용 중'),
            value: isDarkMode,
            onChanged: (val) {
              onThemeChanged(val ? ThemeMode.dark : ThemeMode.light);
            },
          ),
          const Divider(height: 1),

          // 로그아웃
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('로그아웃', style: TextStyle(color: Colors.redAccent)),
            subtitle: const Text('현재 기기에서 계정 연결 해제'),
            onTap: () => _confirmLogout(context),
          ),
          const Divider(height: 1),

          const SizedBox(height: 32),
          const Center(
            child: Text(
              'Face Attendance System v1.0.0\nEnterprise Modular Architecture',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
