import 'dart:io' show File;
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/utils/responsive.dart';
import '../../../models/user_profile.dart';
import '../../attendance/screens/attendance_camera_screen.dart';
import '../controllers/auth_controller.dart';
import '../widgets/university_search_sheet.dart';

/// 회원가입 화면 (2단계 얼굴 촬영 등록 포함)
class SignUpScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  final AuthController authController;

  const SignUpScreen({
    super.key,
    required this.cameras,
    required this.authController,
  });

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _schoolController = TextEditingController();
  final _majorController = TextEditingController();
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();

  String _role = '학생';
  String _imagePath = '';
  Uint8List? _imageBytes;
  String _faceTemplate = '';

  @override
  void dispose() {
    _nameController.dispose();
    _schoolController.dispose();
    _majorController.dispose();
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleCaptureFace() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AttendanceCameraScreen(
          cameras: widget.cameras,
          lectureTitle: '프로필 얼굴 등록',
          isSignUp: true,
        ),
      ),
    );

    if (!mounted) return;

    if (result is Map) {
      setState(() {
        _imagePath = result['path']?.toString() ?? '';
        if (result['bytes'] is Uint8List && (result['bytes'] as Uint8List).isNotEmpty) {
          _imageBytes = result['bytes'] as Uint8List;
        }
        _faceTemplate = result['template']?.toString() ?? '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('얼굴 등록이 완료되었습니다! 이제 회원 정보를 입력해주세요.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _handleSignUp() async {
    if (_imagePath.isEmpty || _faceTemplate.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('카메라 아이콘을 눌러 얼굴을 먼저 등록해주세요.')),
      );
      return;
    }

    if (_nameController.text.trim().isEmpty ||
        _idController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('필수 정보를 모두 입력해주세요.')),
      );
      return;
    }

    final newUser = UserProfile(
      name: _nameController.text.trim(),
      school: _schoolController.text.trim(),
      major: _majorController.text.trim(),
      id: _idController.text.trim(),
      role: _role,
      password: _passwordController.text.trim(),
      imagePath: _imagePath,
      faceTemplate: _faceTemplate,
    );

    final success = await widget.authController.signUp(newUser);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('회원가입이 완료되었습니다. 로그인해주세요.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      final error = widget.authController.authError ?? '회원가입에 실패했습니다.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }
  }

  ImageProvider? _getAvatarProvider() {
    if (_imageBytes != null && _imageBytes!.isNotEmpty) {
      return MemoryImage(_imageBytes!);
    }
    if (_imagePath.isNotEmpty) {
      if (kIsWeb) {
        if (_imagePath.startsWith('http') || _imagePath.startsWith('blob:')) {
          return NetworkImage(_imagePath);
        }
      } else {
        try {
          final file = File(_imagePath);
          if (file.existsSync()) {
            return FileImage(file);
          }
        } catch (_) {}
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = Responsive.contentMaxWidth(context);
    final avatarRadius = math.min(MediaQuery.sizeOf(context).width * 0.16, 60.0);
    final avatarProvider = _getAvatarProvider();

    return Scaffold(
      appBar: AppBar(
        title: const Text('회원가입'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.all(Responsive.padding(context)),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth.isFinite ? maxWidth : double.infinity),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _handleCaptureFace,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: avatarRadius,
                          backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(30),
                          backgroundImage: avatarProvider,
                          child: avatarProvider == null
                              ? Icon(Icons.face, size: avatarRadius * 0.9, color: Colors.grey)
                              : null,
                        ),
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: _faceTemplate.isNotEmpty ? Colors.green : Theme.of(context).colorScheme.primary,
                          child: Icon(
                            _faceTemplate.isNotEmpty ? Icons.check : Icons.camera_alt,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: _handleCaptureFace,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: _faceTemplate.isEmpty
                            ? Colors.grey.withAlpha(25)
                            : Colors.green.withAlpha(30),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _faceTemplate.isEmpty ? Colors.grey.shade400 : Colors.green,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _faceTemplate.isEmpty ? Icons.camera_alt_outlined : Icons.check_circle,
                            size: 16,
                            color: _faceTemplate.isEmpty ? Colors.grey[700] : Colors.green[700],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _faceTemplate.isEmpty
                                ? '터치하여 얼굴 등록 (근거리 1장 + 원거리 1장)'
                                : '얼굴 등록 완료 (다시 촬영하려면 터치)',
                            style: TextStyle(
                              fontSize: 13,
                              color: _faceTemplate.isEmpty ? Colors.grey[800] : Colors.green[800],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<String>(
                    initialValue: _role,
                    decoration: const InputDecoration(labelText: '구분'),
                    items: ['학생', '교수']
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: (v) => setState(() => _role = v ?? '학생'),
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    onTap: () async {
                      final selected = await UniversitySearchSheet.show(context);
                      if (selected != null) {
                        setState(() {
                          _schoolController.text = selected.name;
                        });
                      }
                    },
                    child: IgnorePointer(
                      child: TextField(
                        controller: _schoolController,
                        decoration: const InputDecoration(
                          labelText: '대학교 / 사관학교 선택 *',
                          prefixIcon: Icon(Icons.account_balance_outlined),
                          suffixIcon: Icon(Icons.arrow_drop_down),
                          hintText: '터치하여 소속 학교 검색 및 선택',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _majorController,
                    decoration: const InputDecoration(labelText: '학과'),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: '이름 *'),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _idController,
                    decoration: const InputDecoration(labelText: '학번 / 교번 *'),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: '비밀번호 설정 *'),
                  ),
                  const SizedBox(height: 30),
                  AnimatedBuilder(
                    animation: widget.authController,
                    builder: (context, _) {
                      final isLoading = widget.authController.isLoading;
                      return SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _handleSignUp,
                          child: isLoading
                              ? const CircularProgressIndicator()
                              : const Text('가입 완료', style: TextStyle(fontSize: 16)),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
