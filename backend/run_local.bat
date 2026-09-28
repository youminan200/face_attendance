@echo off
chcp 65001 > nul
echo ===================================================
echo [FacePass] 24/7 스마트 출결 백엔드 서버 기동 스크립트
echo ===================================================

cd /d "%~dp0"

set "PYTHON_EXE=python"
set "PIP_EXE=pip"

rem 1. Anaconda 기본 환경 감지
if exist "E:\Anaconda\python.exe" (
    set "PYTHON_EXE=E:\Anaconda\python.exe"
    set "PIP_EXE=E:\Anaconda\Scripts\pip.exe"
    goto :found
)

rem 2. Anaconda python39 가상환경 감지
if exist "E:\Anaconda\envs\python39\python.exe" (
    set "PYTHON_EXE=E:\Anaconda\envs\python39\python.exe"
    set "PIP_EXE=E:\Anaconda\envs\python39\Scripts\pip.exe"
    goto :found
)

:found
echo [감지된 Python 경로] %PYTHON_EXE%

echo [1/3] 파이썬 패키지 의존성 설치 중...
"%PYTHON_EXE%" -m pip install -r requirements.txt

echo [2/3] 데이터베이스 자동 초기화 및 테이블 점검...

echo [3/3] FastAPI 백엔드 서버 시작 (포트: 8080)...
echo 브라우저에서 확인: http://localhost:8080/docs
"%PYTHON_EXE%" -m uvicorn server:app --host 0.0.0.0 --port 8080 --reload
pause
