@echo off
chcp 65001 > nul
echo ===================================================
echo [FacePass] 모바일 앱 실행 스크립트
echo ===================================================

cd /d "%~dp0"

echo [1/2] Flutter 패키지 의존성 확인 중...
flutter pub get

echo [2/2] Flutter 앱 실행...
flutter run

pause
