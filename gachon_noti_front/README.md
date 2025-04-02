# 가천알림 (가천대학교 공지사항 알림 서비스)

가천대학교 홈페이지의 여러 게시판을 주기적으로 크롤링하여 새로운 공지사항이 올라오면 알림을 제공하는 서비스입니다.

## 주요 기능

- 가천대학교 주요 게시판 공지사항 실시간 알림
- 게시판별 필터링 기능
- 구글 계정으로 간편 로그인
- 웹, 안드로이드, iOS 모두 지원

## 기술 스택

### 프론트엔드 (Flutter Web/App)

- Flutter (크로스플랫폼 앱 개발)
- Appwrite (인증, 데이터베이스)
- Firebase Cloud Messaging (알림)
- Provider (상태 관리)

### 백엔드 (크롤러)

- Node.js
- Appwrite API
- Firebase Admin SDK
- GitHub Actions (정기 실행)

## 설정 방법

### 필수 환경 설정

1. **Appwrite 설정**
   - Appwrite 프로젝트 생성
   - 데이터베이스 및 컬렉션 설정
   - API 키 발급

2. **Firebase 설정**
   - Firebase 프로젝트 생성
   - FCM 설정
   - 서비스 계정 키 발급

3. **GitHub Actions 설정**
   - 저장소 시크릿에 필요한 API 키 및 토큰 추가

### 앱 설정

1. `lib/utils/constants.dart` 파일에서 Appwrite 및 Firebase 관련 설정 값 업데이트
2. `web/index.html` 및 `web/firebase-messaging-sw.js` 파일에서 Firebase 설정 업데이트
3. Android 및 iOS 설정 완료

## 개발자 정보

이 앱은 가천대학교의 공식 앱이 아닙니다. 개인 프로젝트로 개발되었습니다.
