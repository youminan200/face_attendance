# 양대 마켓(App Store & Google Play) 프로덕션 배포 가이드

본 가이드는 얼굴 인식 기반 스마트 출결 관리 시스템(**FacePass**)을 Google Play Store 및 Apple App Store에 출시하기 위한 단계별 지침입니다.

---

## 1. 사전 필수 확인 사항

### 1) 버전 관리 (`pubspec.yaml`)
스토어에 새 버전을 업로드할 때마다 버전 코드와 버전 명세를 갱신해야 합니다.
```yaml
version: 1.0.0+1  # versionName: 1.0.0, versionCode: 1 (iOS: CFBundleVersion)
```

---

## 2. Google Play Store (Android) 배포 가이드

### 1) 릴리즈 키스토어(Keystore) 생성
터미널에서 아래 명령어를 실행하여 릴리즈 서명 키를 생성합니다. (키 파일은 절대 Git에 커밋하지 마세요.)
```bash
keytool -genkey -v -keystore android/app/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

### 2) `android/key.properties` 파일 생성
`android/key.properties.example`을 복사하여 `android/key.properties` 파일을 생성하고 키 정보를 입력합니다.
```properties
keyAlias=upload
keyPassword=생성한테스트키비밀번호
storeFile=app/upload-keystore.jks
storePassword=생성한테스트키비밀번호
```

### 3) Android App Bundle (AAB) 빌드
Google Play는 2021년 8월 이후 신규 앱에 대해 APK가 아닌 **AAB(Android App Bundle)** 형식을 의무화하고 있습니다.
```bash
flutter clean
flutter pub get
flutter build appbundle --release
```
- 생성 파일 위치: `build/app/outputs/bundle/release/app-release.aab`
- ProGuard/R8 난독화 매핑 파일: `build/app/outputs/mapping/release/mapping.txt` (크래시 로그 복호화용으로 Play Console에 함께 업로드)

### 4) Google Play Console 등록 시 체크포인트
1. **타겟 API 레벨:** Google Play 최신 정책(API 34/35) 준수 완료
2. **ML Kit 종속성:** `AndroidManifest.xml`에 `com.google.mlkit.vision.DEPENDENCIES` 태그 등록으로 앱 설치 시 얼굴 인식 모델 자동 다운로드 보장
3. **앱 접근 권한 안내:** 앱 심사 제출 시 카메라 사용 목적 설명 및 데모 테스트 계정(ID: `20260001`, PW: `password`) 제공

---

## 3. Apple App Store (iOS) 배포 가이드

### 1) iOS 빌드 요구사항
- macOS 환경 및 최신 Xcode
- Apple Developer 계정 (Individual 또는 Organization)
- `ios/Podfile`에 `platform :ios, '13.0'` 적용 완료

### 2) CocoaPods 의존성 설치
```bash
cd ios
pod install --repo-update
cd ..
```

### 3) IPA 빌드 및 아카이브
#### 방법 A: Flutter CLI를 통한 빌드
```bash
flutter build ipa --release
```
- 생성 파일 위치: `build/ios/archive/Runner.xcarchive` 및 `build/ios/ipa/*.ipa`

#### 방법 B: Xcode를 통한 수동 아카이브
1. `ios/Runner.xcworkspace`를 Xcode로 엽니다.
2. **Signing & Capabilities** 탭에서 **Team**을 본인의 Apple Developer 계정으로 선택합니다.
3. 상단 타겟 디바이스를 **Any iOS Device (arm64)** 로 지정합니다.
4. 상단 메뉴: **Product -> Archive** 실행
5. Organizer 창이 뜨면 **Distribute App** -> **App Store Connect** 선택 후 업로드

### 4) App Store 심사 체크포인트 (Guideline 5.1.1 대응)
1. **카메라 권한 문구 (`NSCameraUsageDescription`):** 
   - `수업 출결 확인 및 회원가입 시 본인 인증을 위한 얼굴 인식 촬영에 카메라 권한을 사용합니다.`로 상세 사유 명시 완료.
2. **수출 규정 준수 (`ITSAppUsesNonExemptEncryption`):**
   - `<false/>` 적용으로 App Store Connect 업로드 시 추가 설문 없이 즉시 심사 대기 처리.
3. **App Store 심사원용 데모 계정:**
   - Apple 심사원은 기기에서 직접 로그인과 카메라 동작을 확인하므로, 심사 정보 입력란에 **미리 등록된 테스트 계정(ID / PW)** 및 테스트 안내 메모를 필히 기재해야 합니다.

---

## 4. 백엔드 운영 배포 시 환경변수 주입 (Production Flavors)
사설 IP 대신 운영용 도메인으로 빌드할 때는 소스코드 수정 없이 빌드 명령어 파라미터로 주입할 수 있습니다:
```bash
# 운영 서버 대상 AAB 빌드
flutter build appbundle --release --dart-define=API_BASE_URL=https://api.yourdomain.com

# 운영 서버 대상 iOS IPA 빌드
flutter build ipa --release --dart-define=API_BASE_URL=https://api.yourdomain.com
```
