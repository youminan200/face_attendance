import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../../core/utils/responsive.dart';
import '../../attendance/screens/attendance_camera_screen.dart';
import '../controllers/auth_controller.dart';
import 'sign_up_screen.dart';

/// 로그인 및 본인 확인 화면
class LoginScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  final AuthController authController;

  const LoginScreen({
    super.key,
    required this.cameras,
    required this.authController,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _idController = TextEditingController();
  final _passController = TextEditingController();
  String _role = '학생';

  @override
  void dispose() {
    _idController.dispose();
    _passController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final id = _idController.text.trim();
    final pass = _passController.text.trim();

    if (id.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID와 비밀번호를 모두 입력해주세요.')),
      );
      return;
    }

    final success = await widget.authController.login(
      id: id,
      password: pass,
      role: _role,
    );

    if (!mounted) return;

    if (success) {
      final user = widget.authController.currentUser;

      // 2차 본인 얼굴 인증 진행
      final authResult = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AttendanceCameraScreen(
            cameras: widget.cameras,
            lectureTitle: '본인 얼굴 확인',
            isSignUp: false,
            referenceFaceTemplate: user.faceTemplate,
            referenceImagePath: user.imagePath,
          ),
        ),
      );

      if (!mounted) return;

      if (authResult == 'SUCCESS') {
        widget.authController.completeLogin();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('얼굴 본인 확인에 실패하여 로그인이 취소되었습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      final error = widget.authController.authError ?? '로그인에 실패했습니다.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = Responsive.contentMaxWidth(context);
    final iconSize = math.min(MediaQuery.sizeOf(context).width * 0.18, 80.0);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final form = Padding(
              padding: EdgeInsets.all(Responsive.padding(context)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.face_unlock_rounded,
                    size: iconSize,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'FACE PASS',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '얼굴 인식 기반 스마트 출결 관리 시스템',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  DropdownButtonFormField<String>(
                    initialValue: _role,
                    decoration: const InputDecoration(
                      labelText: '구분',
                      prefixIcon: Icon(Icons.school_outlined),
                    ),
                    items: ['학생', '교수']
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: (v) => setState(() => _role = v ?? '학생'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _idController,
                    decoration: const InputDecoration(
                      labelText: 'ID (학번 / 교번)',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: '비밀번호',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedBuilder(
                    animation: widget.authController,
                    builder: (context, _) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Checkbox(
                            value: widget.authController.isStayLoggedIn,
                            onChanged: (v) => widget.authController.setStayLoggedIn(v ?? false),
                          ),
                          const Text('로그인 상태 유지'),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  AnimatedBuilder(
                    animation: widget.authController,
                    builder: (context, _) {
                      final isLoading = widget.authController.isLoading;
                      return SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('인증 후 로그인', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SignUpScreen(
                            cameras: widget.cameras,
                            authController: widget.authController,
                          ),
                        ),
                      );
                    },
                    child: const Text('신규 계정 만들기 (회원가입)'),
                  ),
                ],
              ),
            );

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: maxWidth.isFinite
                      ? ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxWidth),
                          child: form,
                        )
                      : form,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
