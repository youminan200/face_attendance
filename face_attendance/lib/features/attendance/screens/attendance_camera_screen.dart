import 'dart:async';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/utils/responsive.dart';
import '../../../models/face_auth_template.dart';
import '../services/face_auth_service.dart';
import 'face_verify_result_screen.dart';

/// 카메라 촬영 및 얼굴 인증 화면
class AttendanceCameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  final String lectureTitle;
  final bool isSignUp;
  final String referenceFaceTemplate;
  final String referenceImagePath;

  const AttendanceCameraScreen({
    super.key,
    required this.cameras,
    required this.lectureTitle,
    required this.isSignUp,
    this.referenceFaceTemplate = '',
    this.referenceImagePath = '',
  });

  @override
  State<AttendanceCameraScreen> createState() => _AttendanceCameraScreenState();
}

class _AttendanceCameraScreenState extends State<AttendanceCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  late final FaceAuthService _faceAuthService;

  bool _isCameraInitialized = false;
  bool _isChecking = false;
  String? _errorMessage;

  // 회원가입 전용 2단계 촬영 상태
  int _signUpStep = 0; // 0: 근거리, 1: 원거리
  String _nearImagePath = '';
  Uint8List? _nearImageBytes;
  List<double>? _nearVector;

  // 카메라 줌 및 뷰포트 크기 조절 상태
  double _zoomScale = 1.0;
  double _baseZoom = 1.0;
  bool _isCoverMode = false; // 기본값: 비율 유지 넓은 화각 (과도한 자동 확대 방지)
  double _minHardwareZoom = 1.0;
  double _maxHardwareZoom = 1.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _faceAuthService = FaceAuthService();
    _initCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraController;

    // 앱이 백그라운드로 전환될 때 카메라 리소스 명시적 해제 (OOM 및 크래시 방어)
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _cameraController = null;
      cameraController?.dispose();
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
        });
      }
    } else if (state == AppLifecycleState.resumed) {
      // 포그라운드 복귀 시 안전하게 재초기화
      _initCamera();
    }
  }

  /// 카메라 렌즈 탐색 및 컨트롤러 초기화
  Future<void> _initCamera() async {
    List<CameraDescription> available = List.from(widget.cameras);

    // 전달받은 카메라 목록이 비어있을 경우 런타임 동적 재탐색 시도
    if (available.isEmpty) {
      try {
        available = await availableCameras();
      } catch (e) {
        debugPrint('카메라 런타임 탐색 오류: $e');
      }
    }

    if (available.isEmpty) {
      if (!mounted) return;
      setState(() {
        _errorMessage = '사용 가능한 카메라 기기를 찾을 수 없습니다.\n브라우저 주소창 좌측의 [카메라 권한]을 허용하셨는지 확인해주세요.';
        _isCameraInitialized = false;
      });
      return;
    }

    // 전면 카메라 우선 선택
    final frontCamera = available.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => available.first,
    );

    // 웹 환경에서는 jpeg 포맷 지정 시 에러 방지를 위해 unknown/기본값 적용
    final controller = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: kIsWeb ? ImageFormatGroup.unknown : ImageFormatGroup.jpeg,
    );

    _cameraController = controller;

    try {
      await controller.initialize();
      try {
        _minHardwareZoom = await controller.getMinZoomLevel();
        _maxHardwareZoom = await controller.getMaxZoomLevel();
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _isCameraInitialized = true;
        _errorMessage = null;
      });
    } on CameraException catch (e) {
      if (!mounted) return;
      String message = '카메라를 시작할 수 없습니다.';
      if (e.code == 'CameraAccessDenied' || e.code == 'CameraAccessDeniedWithoutPrompt') {
        message = '카메라 접근 권한이 거부되었습니다.\n기기 설정에서 카메라 권한을 허용해주세요.';
      } else if (e.code == 'CameraAccessRestricted') {
        message = '기기 정책에 의해 카메라 사용이 제한되었습니다.';
      }
      setState(() {
        _errorMessage = message;
        _isCameraInitialized = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = '카메라 초기화 오류: $e';
        _isCameraInitialized = false;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _faceAuthService.dispose();
    super.dispose();
  }

  /// 회원가입 촬영 처리 (근거리 1장 + 원거리 1장)
  Future<void> _captureForSignUp() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    final image = await controller.takePicture();
    if (!mounted) return;

    final bytes = await image.readAsBytes();
    if (!mounted) return;

    final vector = await _faceAuthService.extractVectorFromBytes(bytes, path: image.path);
    if (!mounted) return;

    if (vector == null) {
      _showFeedbackSnackBar(
        '얼굴만 화면 중앙 가이드에 맞춰 다시 촬영해주세요.\n(손가락, 물건, 측면 얼굴은 제한됩니다)',
        isError: true,
      );
      return;
    }

    if (_signUpStep == 0) {
      setState(() {
        _nearImagePath = image.path;
        _nearImageBytes = bytes;
        _nearVector = vector;
        _signUpStep = 1;
      });

      _showFeedbackSnackBar('1단계(근거리) 등록 완료! 이제 조금 떨어져서 원거리 얼굴을 촬영하세요.');
      return;
    }

    final near = _nearVector;
    if (near == null || _nearImagePath.isEmpty) {
      setState(() => _signUpStep = 0);
      return;
    }

    final template = _faceAuthService.createTemplate(
      nearVector: near,
      farVector: vector,
    );

    if (!mounted) return;
    Navigator.pop(context, {
      'path': _nearImagePath,
      'bytes': _nearImageBytes ?? bytes,
      'template': template.encode(),
    });
  }

  /// 본인 인증 촬영 처리
  Future<void> _captureForVerify() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    final image = await controller.takePicture();
    if (!mounted) return;

    final bytes = await image.readAsBytes();
    if (!mounted) return;

    final vector = await _faceAuthService.extractVectorFromBytes(bytes, path: image.path);
    if (!mounted) return;

    if (vector == null) {
      _showFeedbackSnackBar(
        '얼굴만 화면 중앙에 맞춰주세요. (단 1명만 인식되어야 합니다)',
        isError: true,
      );
      return;
    }

    final template = FaceAuthTemplate.decode(widget.referenceFaceTemplate);
    if (template == null) {
      _showFeedbackSnackBar('등록된 얼굴 템플릿이 없습니다. 회원가입에서 얼굴을 등록해주세요.', isError: true);
      return;
    }

    final result = _faceAuthService.verifyFace(
      template: template,
      capturedVector: vector,
    );

    if (!result.passed) {
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FaceVerifyResultScreen(
            savedImagePath: widget.referenceImagePath,
            capturedImagePath: image.path,
            result: result,
          ),
        ),
      );
      return;
    }

    if (!mounted) return;
    Navigator.pop(context, 'SUCCESS');
  }

  /// 카메라 미지원/에러 시 가상 얼굴 시뮬레이션 성공 처리
  void _simulateCaptureSuccess() {
    if (widget.isSignUp) {
      final sampleVector = List<double>.generate(1024, (i) => (math.sin(i.toDouble()) * 0.5));
      final template = FaceAuthTemplate(nearVector: sampleVector, farVector: sampleVector);
      Navigator.pop(context, {
        'path': '',
        'bytes': Uint8List(0),
        'template': template.encode(),
      });
    } else {
      Navigator.pop(context, 'SUCCESS');
    }
  }

  /// 촬영 셔터 버튼 핸들러
  Future<void> _handleCapture() async {
    if (_isChecking || !_isCameraInitialized) return;

    setState(() => _isChecking = true);

    try {
      if (widget.isSignUp) {
        await _captureForSignUp();
      } else {
        await _captureForVerify();
      }
    } catch (e) {
      if (!mounted) return;
      _showFeedbackSnackBar('인증 처리 중 오류가 발생했습니다: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  void _showFeedbackSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green[700],
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _updateZoom(double newZoom) async {
    final clamped = newZoom.clamp(0.6, 3.0);
    setState(() {
      _zoomScale = clamped;
    });

    final controller = _cameraController;
    if (controller != null && controller.value.isInitialized) {
      if (_maxHardwareZoom > _minHardwareZoom) {
        final hardwareTarget = clamped.clamp(_minHardwareZoom, _maxHardwareZoom);
        try {
          await controller.setZoomLevel(hardwareTarget);
        } catch (_) {}
      }
    }
  }

  Widget _buildZoomChip(String label, double scale) {
    final isSelected = (_zoomScale - scale).abs() < 0.15;
    return InkWell(
      onTap: () => _updateZoom(scale),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  /// 카메라 프리뷰 종횡비 보정 및 화면 꽉 차게 렌더링 (핀치 투 줌 및 확대/축소 지원)
  Widget _buildCameraPreview() {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return Container(color: Colors.black);
    }

    final previewSize = controller.value.previewSize;
    if (previewSize == null) return CameraPreview(controller);

    final double targetWidth;
    final double targetHeight;
    if (kIsWeb) {
      targetWidth = previewSize.width;
      targetHeight = previewSize.height;
    } else {
      targetWidth = previewSize.height;
      targetHeight = previewSize.width;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onScaleStart: (details) {
        _baseZoom = _zoomScale;
      },
      onScaleUpdate: (details) {
        final newScale = (_baseZoom * details.scale).clamp(0.6, 3.0);
        _updateZoom(newScale);
      },
      child: Center(
        child: ClipRect(
          child: Transform.scale(
            scale: _zoomScale,
            child: FittedBox(
              fit: _isCoverMode ? BoxFit.cover : BoxFit.contain,
              child: SizedBox(
                width: targetWidth,
                height: targetHeight,
                child: CameraPreview(controller),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getGuideText() {
    if (!widget.isSignUp) {
      return '얼굴을 중앙 가이드 영역에 맞춰주세요';
    }
    if (_signUpStep == 0) {
      return '1단계: 얼굴을 가깝게 두고 촬영 (근거리)';
    }
    return '2단계: 상반신이 보이도록 조금 떨어져 촬영 (원거리)';
  }

  @override
  Widget build(BuildContext context) {
    final guideWidth = Responsive.faceGuideWidth(context);
    final guideHeight = Responsive.faceGuideHeight(context);
    final bottomPadding = math.max(24.0, MediaQuery.of(context).padding.bottom + 24.0);

    // 에러 또는 권한 거부 시 재시도 UI 제공 (블랙스크린 방지)
    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.lectureTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.videocam_off_rounded, size: 64, color: Colors.orange),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _initCamera,
                  icon: const Icon(Icons.refresh),
                  label: const Text('카메라 다시 연결'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _simulateCaptureSuccess,
                  icon: const Icon(Icons.verified_user_outlined),
                  label: const Text('테스트용 가상 얼굴로 진행 (시뮬레이션 모드)'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 카메라 로딩 중 인디케이터
    if (!_isCameraInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. 카메라 프리뷰
          _buildCameraPreview(),

          // 2. 상단 타이틀 및 가이드 안내 헤더
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(160),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.lectureTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getGuideText(),
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. 중앙 얼굴 가이드 프레임
          Center(
            child: Container(
              width: guideWidth,
              height: guideHeight,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withAlpha(220), width: 2.5),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),

          // 4. 하단 주의사항 안내 박스
          Positioned(
            bottom: bottomPadding + 130,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(140),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '단 1명의 정면 얼굴만 인식됩니다.\n손가락, 사진, 모자, 마스크 착용 시 인증이 제한됩니다.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 11.5, height: 1.35),
              ),
            ),
          ),

          // 5. 줌(확대/축소) 조절 칩 바
          Positioned(
            bottom: bottomPadding + 84,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(150),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildZoomChip('0.7x', 0.7),
                    const SizedBox(width: 4),
                    _buildZoomChip('1.0x', 1.0),
                    const SizedBox(width: 4),
                    _buildZoomChip('1.4x', 1.4),
                    const SizedBox(width: 4),
                    _buildZoomChip('2.0x', 2.0),
                  ],
                ),
              ),
            ),
          ),

          // 6. 하단 셔터 버튼
          Positioned(
            bottom: bottomPadding,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 72,
                height: 72,
                child: FloatingActionButton(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  elevation: 4,
                  shape: const CircleBorder(),
                  onPressed: _isChecking ? null : _handleCapture,
                  child: _isChecking
                      ? const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.black87,
                          ),
                        )
                      : const Icon(Icons.camera_alt_rounded, size: 36),
                ),
              ),
            ),
          ),

          // 7. 좌상단 닫기 버튼
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),

          // 8. 우상단 화면 비율(꽉 채우기 / 넓게 보기) 전환 버튼
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(130),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    tooltip: _isCoverMode ? '넓은 화면으로 축소' : '화면 꽉 채우기',
                    icon: Icon(
                      _isCoverMode ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                    onPressed: () {
                      setState(() {
                        _isCoverMode = !_isCoverMode;
                      });
                      _showFeedbackSnackBar(
                        _isCoverMode ? '화면 꽉 채우기 모드' : '비율 유지(넓게 보기) 모드',
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
