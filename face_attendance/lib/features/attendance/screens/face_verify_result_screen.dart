import 'dart:io' show File;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../models/face_auth_template.dart';

/// 얼굴 본인 확인 결과 상세 화면
class FaceVerifyResultScreen extends StatelessWidget {
  final String savedImagePath;
  final String capturedImagePath;
  final FaceAuthResult result;

  const FaceVerifyResultScreen({
    super.key,
    required this.savedImagePath,
    required this.capturedImagePath,
    required this.result,
  });

  Widget _buildPhotoWidget(String path) {
    if (path.isEmpty) {
      return const Center(child: Text('사진 없음', style: TextStyle(color: Colors.grey)));
    }
    if (kIsWeb) {
      if (path.startsWith('http') || path.startsWith('blob:')) {
        return Image.network(
          path,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const Center(child: Text('사진 없음', style: TextStyle(color: Colors.grey))),
        );
      }
      return const Center(child: Text('사진 없음', style: TextStyle(color: Colors.grey)));
    }
    try {
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover);
      }
    } catch (_) {}
    return const Center(child: Text('사진 없음', style: TextStyle(color: Colors.grey)));
  }

  Widget _imageBox(BuildContext context, String title, String path) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          AspectRatio(
            aspectRatio: 3 / 4,
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.grey[200],
                border: Border.all(color: Colors.grey.withAlpha(100)),
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: _buildPhotoWidget(path),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSuccess = result.passed;
    final statusColor = isSuccess ? Colors.green : Colors.red;

    return Scaffold(
      appBar: AppBar(
        title: const Text('얼굴 일치 확인'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  _imageBox(context, '등록된 얼굴', savedImagePath),
                  const SizedBox(width: 14),
                  _imageBox(context, '촬영된 얼굴', capturedImagePath),
                ],
              ),
              const SizedBox(height: 24),
              Icon(
                isSuccess ? Icons.verified_user_rounded : Icons.warning_amber_rounded,
                color: statusColor,
                size: 52,
              ),
              const SizedBox(height: 10),
              Text(
                isSuccess ? '본인 확인 성공' : '본인 확인 실패',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '일치도: ${(result.score * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                result.reason,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(120),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 20, color: Colors.grey),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '얼굴만 화면 중앙에 두고 밝은 조명에서 재촬영해주세요.\n손가락, 모자, 마스크, 측면 얼굴은 인증되지 않습니다.',
                        style: TextStyle(fontSize: 13, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.refresh),
                  label: const Text('다시 촬영하기', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
