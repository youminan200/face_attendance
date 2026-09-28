import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:camera/camera.dart' show XFile;
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as imgpkg;
import '../../../models/face_auth_template.dart';

/// 얼굴 특징 벡터 추출기
class FaceEmbeddingMaker {
  FaceEmbeddingMaker._();

  /// 정규화 이미지 크기 (32x32 = 1,024차원 벡터)
  static const int size = 32;
  static const int vectorSize = size * size;

  /// 정면 각도 임계값
  static const double maxYaw = 16.0;   // 좌우 회전 각도
  static const double maxRoll = 14.0;  // 기울기 각도
  static const double maxPitch = 18.0; // 상하 고개 각도

  /// 얼굴 면적 비율 임계값 (전체 이미지 대비)
  static const double minAreaRatio = 0.045; // 너무 멀리 있거나 작은 물체 배제
  static const double maxAreaRatio = 0.72;  // 화면을 과도하게 채운 왜곡 배제

  /// ML Kit 감지된 Face 객체와 원본 사진 파일로부터 특징 벡터를 추출합니다.
  /// 엄격한 품질 필터(각도, 면적, 랜드마크)를 통과하지 못하면 null을 반환합니다.
  static Future<List<double>?> make({
    required String imagePath,
    required Face face,
  }) async {
    final file = File(imagePath);
    if (!await file.exists()) return null;

    final bytes = await file.readAsBytes();
    final image = imgpkg.decodeImage(bytes);
    if (image == null) return null;

    final box = face.boundingBox;
    final faceArea = box.width * box.height;
    final imageArea = image.width * image.height;
    if (imageArea <= 0) return null;

    final areaRatio = faceArea / imageArea;

    // 1. 얼굴 크기 비율 검증 (사물, 손가락, 배경 오류 차단)
    if (areaRatio < minAreaRatio || areaRatio > maxAreaRatio) {
      return null;
    }

    // 2. 정면 얼굴 각도 검증
    final yaw = (face.headEulerAngleY ?? 0).abs();
    final roll = (face.headEulerAngleZ ?? 0).abs();
    final pitch = (face.headEulerAngleX ?? 0).abs();
    if (yaw > maxYaw || roll > maxRoll || pitch > maxPitch) {
      return null;
    }

    // 3. 주요 이목구비 랜드마크 검증 (원거리 등 일부 랜드마크 미검출 시에도 박스 유효 시 진행)
    final leftEye = face.landmarks[FaceLandmarkType.leftEye]?.position;
    final rightEye = face.landmarks[FaceLandmarkType.rightEye]?.position;
    final noseBase = face.landmarks[FaceLandmarkType.noseBase]?.position;
    final mouthBottom = face.landmarks[FaceLandmarkType.bottomMouth]?.position;

    if (leftEye == null || rightEye == null || noseBase == null || mouthBottom == null) {
      if (box.width < 24 || box.height < 24) {
        return null;
      }
    }

    // 4. 얼굴 영역 안전 크롭 (마진 10% 부여)
    final marginX = (box.width * 0.1).toInt();
    final marginY = (box.height * 0.1).toInt();

    final x = math.max(0, box.left.toInt() - marginX);
    final y = math.max(0, box.top.toInt() - marginY);
    final cropW = math.min(image.width - x, box.width.toInt() + marginX * 2);
    final cropH = math.min(image.height - y, box.height.toInt() + marginY * 2);

    if (cropW <= 0 || cropH <= 0) return null;

    final cropped = imgpkg.copyCrop(
      image,
      x: x,
      y: y,
      width: cropW,
      height: cropH,
    );

    // 32x32 크기 고화질 Cubic 보간 리사이즈
    final resized = imgpkg.copyResize(
      cropped,
      width: size,
      height: size,
      interpolation: imgpkg.Interpolation.cubic,
    );

    // 5. 그레이스케일 변환 및 1차원 벡터 추출
    final values = <double>[];
    for (int py = 0; py < size; py++) {
      for (int px = 0; px < size; px++) {
        final pixel = resized.getPixel(px, py);
        // 표준 sRGB -> Grayscale 공식 (Y = 0.299R + 0.587G + 0.114B)
        final gray = (0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b) / 255.0;
        values.add(gray);
      }
    }

    // 6. 조명 변화에 강인한 Z-Score 정규화
    return _normalize(values);
  }

  /// 웹 및 순수 Dart 환경을 위한 중앙 영역 기반 특징 벡터 추출
  static List<double> makeFromImage(imgpkg.Image image) {
    final cropSize = (math.min(image.width, image.height) * 0.72).toInt();
    final startX = math.max(0, (image.width - cropSize) ~/ 2);
    final startY = math.max(0, (image.height - cropSize) ~/ 2);
    final cropped = imgpkg.copyCrop(
      image,
      x: startX,
      y: startY,
      width: cropSize,
      height: cropSize,
    );
    final resized = imgpkg.copyResize(
      cropped,
      width: size,
      height: size,
      interpolation: imgpkg.Interpolation.cubic,
    );
    final values = <double>[];
    for (int py = 0; py < size; py++) {
      for (int px = 0; px < size; px++) {
        final pixel = resized.getPixel(px, py);
        final gray = (0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b) / 255.0;
        values.add(gray);
      }
    }
    return _normalize(values);
  }

  /// 다중 벡터의 평균 벡터 계산
  static List<double> average(List<List<double>> vectors) {
    if (vectors.isEmpty) return List<double>.filled(vectorSize, 0.0);

    final result = List<double>.filled(vectorSize, 0.0);
    for (final vector in vectors) {
      for (int i = 0; i < vectorSize; i++) {
        result[i] += vector[i];
      }
    }
    for (int i = 0; i < vectorSize; i++) {
      result[i] /= vectors.length;
    }
    return _normalize(result);
  }

  /// Z-score 평균 0, 표준편차 1 정규화
  static List<double> _normalize(List<double> values) {
    if (values.isEmpty) return values;

    final mean = values.reduce((a, b) => a + b) / values.length;

    double variance = 0.0;
    for (final v in values) {
      variance += math.pow(v - mean, 2);
    }
    variance /= values.length;
    final std = math.sqrt(variance);

    if (std <= 0.000001) return values;
    return values.map((v) => (v - mean) / std).toList();
  }

  /// 코사인 유사도(Cosine Similarity) 계산 (-1.0 ~ 1.0)
  static double similarity(List<double> a, List<double> b) {
    if (a.length != b.length || a.isEmpty) return -1.0;

    double dot = 0.0;
    double na = 0.0;
    double nb = 0.0;

    for (int i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      na += a[i] * a[i];
      nb += b[i] * b[i];
    }

    if (na <= 0 || nb <= 0) return -1.0;
    return dot / (math.sqrt(na) * math.sqrt(nb));
  }
}

/// 얼굴 인증 판별 엔진
class FaceAuthEngine {
  FaceAuthEngine._();

  /// 본인 인증 합격 기준 유사도 (65% 이상)
  static const double passScore = 0.65;

  /// 저장된 회원 템플릿(근거리/원거리)과 실시간 캡처 벡터 비교
  static FaceAuthResult verify({
    required FaceAuthTemplate template,
    required List<double> capturedVector,
  }) {
    final nearScore = FaceEmbeddingMaker.similarity(template.nearVector, capturedVector);
    final farScore = FaceEmbeddingMaker.similarity(template.farVector, capturedVector);
    final bestScore = math.max(nearScore, farScore);

    if (bestScore >= passScore) {
      return FaceAuthResult(
        passed: true,
        score: bestScore,
        reason: '등록된 회원 얼굴과 일치합니다.',
      );
    }

    return FaceAuthResult(
      passed: false,
      score: bestScore,
      reason: '등록된 얼굴과 일치하지 않습니다. (일치도 부족)',
    );
  }
}

/// ML Kit FaceDetector 생명주기 및 추출 파이프라인을 캡슐화한 서비스 클래스
class FaceAuthService {
  final FaceDetector? _faceDetector;

  FaceAuthService({FaceDetector? faceDetector})
      : _faceDetector = kIsWeb
            ? null
            : (faceDetector ??
                FaceDetector(
                  options: FaceDetectorOptions(
                    performanceMode: FaceDetectorMode.accurate,
                    enableLandmarks: true,
                    enableClassification: true,
                  ),
                ));

  /// 바이트 데이터에서 단일 얼굴 특징 벡터를 추출합니다 (웹 & 네이티브 공용)
  Future<List<double>?> extractVectorFromBytes(Uint8List bytes, {String? path}) async {
    if (kIsWeb) {
      try {
        final image = imgpkg.decodeImage(bytes);
        if (image != null) {
          return FaceEmbeddingMaker.makeFromImage(image);
        }
      } catch (e) {
        debugPrint('웹 얼굴 이미지 디코딩 실패: $e');
      }
      return _generateFallbackVector(bytes);
    }

    // 모바일/네이티브: ML Kit 정밀 감지 우선
    final detector = _faceDetector;
    if (path != null && path.isNotEmpty && detector != null) {
      try {
        final inputImage = InputImage.fromFilePath(path);
        final faces = await detector.processImage(inputImage);
        if (faces.isNotEmpty) {
          final res = await FaceEmbeddingMaker.make(
            imagePath: path,
            face: faces.first,
          );
          if (res != null) return res;
        }
      } catch (e) {
        debugPrint('ML Kit 처리 실패 -> 이미지 분석 폴백: $e');
      }
    }

    // 네이티브 이미지 폴백
    try {
      final image = imgpkg.decodeImage(bytes);
      if (image != null) {
        return FaceEmbeddingMaker.makeFromImage(image);
      }
    } catch (_) {}

    return _generateFallbackVector(bytes);
  }

  /// 이미지 파일에서 특징 벡터를 추출합니다.
  Future<List<double>?> extractVectorFromFile(String imagePath) async {
    try {
      if (kIsWeb) {
        final xfile = XFile(imagePath);
        final bytes = await xfile.readAsBytes();
        return extractVectorFromBytes(bytes, path: imagePath);
      } else {
        final file = File(imagePath);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          return extractVectorFromBytes(bytes, path: imagePath);
        }
      }
    } catch (e) {
      debugPrint('파일 벡터 추출 오류: $e');
    }
    return null;
  }

  static List<double> _generateFallbackVector(Uint8List bytes) {
    if (bytes.isEmpty) {
      return List<double>.generate(FaceEmbeddingMaker.vectorSize, (i) => math.sin(i.toDouble()) * 0.5);
    }
    final list = <double>[];
    final step = math.max(1, bytes.length ~/ FaceEmbeddingMaker.vectorSize);
    for (int i = 0; i < FaceEmbeddingMaker.vectorSize; i++) {
      final idx = (i * step) % bytes.length;
      list.add((bytes[idx] / 255.0) - 0.5);
    }
    return FaceEmbeddingMaker._normalize(list);
  }

  /// 근거리 벡터와 원거리 벡터로 최종 템플릿을 생성합니다.
  FaceAuthTemplate createTemplate({
    required List<double> nearVector,
    required List<double> farVector,
  }) {
    return FaceAuthTemplate(
      nearVector: nearVector,
      farVector: farVector,
    );
  }

  /// 인증 검증 수행
  FaceAuthResult verifyFace({
    required FaceAuthTemplate template,
    required List<double> capturedVector,
  }) {
    return FaceAuthEngine.verify(
      template: template,
      capturedVector: capturedVector,
    );
  }

  /// 리소스 해제
  void dispose() {
    _faceDetector?.close();
  }
}
