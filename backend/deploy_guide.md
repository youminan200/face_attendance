# 24시간 상시 클라우드 서버 배포 가이드 (Always-On Cloud Server)

컴퓨터를 종료하더라도 모바일 앱이 언제 어디서나 정상 작동하도록 **24시간 365일 무중단 상시 클라우드 서버**를 배포하는 방법입니다.

---

## 옵션 1. Render.com 무료 클라우드 배포 (가장 추천 - 5분 완료)

Render는 GitHub 저장소와 연동하여 무료로 24시간 동작하는 웹 서비스와 **무료 HTTPS 도메인**(`https://your-api.onrender.com`)을 제공합니다.

### 배포 단계
1. **GitHub 저장소에 코드 푸시:**
   - 현재 `face_attendance` 프로젝트(또는 `backend` 폴더)를 GitHub 레포지토리에 커밋 & 푸시합니다.
2. **Render 가입 및 연동:**
   - [Render.com](https://render.com)에 접속하여 GitHub 계정으로 로그인합니다.
3. **새 웹 서비스(New Web Service) 생성:**
   - 대시보드 우측 상단 **[New +] -> [Web Service]** 클릭
   - 방금 푸시한 GitHub 레포지토리 선택
   - 설정값 확인:
     - **Name:** `face-attendance-api` (원하는 이름)
     - **Region:** `Singapore` (한국 접근 지연시간 최소화)
     - **Root Directory:** `backend` (저장소 루트에 backend 폴더가 있는 경우)
     - **Runtime:** `Python 3`
     - **Build Command:** `pip install -r requirements.txt`
     - **Start Command:** `uvicorn server:app --host 0.0.0.0 --port $PORT`
     - **Instance Type:** `Free`
4. **[Create Web Service] 클릭:**
   - 1~2분 내로 빌드가 완료되고 상단에 고유 도메인이 생성됩니다!
   - 예: `https://face-attendance-api.onrender.com`

---

## 옵션 2. Railway / Fly.io 배포 (Docker 기반)

이미 작성된 `backend/Dockerfile`을 통해 별도 설정 없이 원클릭 배포가 가능합니다.
1. [Railway.app](https://railway.app) 또는 [Fly.io](https://fly.io) 로그인
2. **Deploy from GitHub repo** 선택
3. 루트 경로를 `backend`로 지정하면 작성된 `Dockerfile`을 자동 감지하여 즉시 배포 완료

---

## 옵션 3. 개인 클라우드 VPS (Oracle Cloud Free Tier / AWS EC2)

오라클 클라우드 Always Free 인스턴스 또는 AWS EC2에서 `docker-compose`로 영구 상시 가동하는 방법입니다:
```bash
# 1. 서버에 코드 복사 또는 git clone
git clone <your-repo-url>
cd face_attendance/backend

# 2. 백그라운드 무중단 실행 (재부팅 시 자동 재시작 restart: always 적용 완료)
docker-compose up -d --build

# 3. 로그 및 상태 확인
docker-compose ps
docker-compose logs -f
```

---

## 3. Flutter 앱에 증설된 서버 연결하기

클라우드 서버가 배포되면 생성된 HTTPS URL을 Flutter 앱에 적용합니다.

### 방법 A. 빌드 시 파라미터로 주입 (코드 수정 불필요, 권장)
```bash
# Android App Bundle 빌드 시 배포 서버 URL 지정
flutter build appbundle --release --dart-define=API_BASE_URL=https://face-attendance-api.onrender.com

# iOS 빌드 시
flutter build ipa --release --dart-define=API_BASE_URL=https://face-attendance-api.onrender.com
```

### 방법 B. 소스코드 기본값 변경
`face_attendance/lib/core/constants/api_config.dart` 파일의 `defaultValue`를 배포된 주소로 변경:
```dart
static const String baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://face-attendance-api.onrender.com', // 배포된 주소 입력
);
```
이제 개발자 본인의 컴퓨터를 꺼도 전 세계 어디서든 앱의 회원가입, 본인 인증, 출결 관리가 24시간 멈추지 않고 동작합니다.
