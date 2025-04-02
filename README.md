# 가천대학교 게시판 크롤러

이 프로젝트는 가천대학교 홈페이지의 여러 게시판을 주기적으로 크롤링하여 Appwrite 데이터베이스에 저장하고, 새로운 게시글이 있을 경우 Firebase Cloud Messaging(FCM)을 통해 알림을 전송합니다.

## 기능

- 가천대학교 홈페이지 RSS 피드 파싱
- 게시글 데이터 Appwrite 데이터베이스 저장
- 새 게시글 발견 시 FCM 알림 전송
- GitHub Actions를 통한 주기적 실행 (15분마다)

## 설정 방법

### 필수 환경 변수

프로젝트를 실행하기 위해 다음 환경 변수를 설정해야 합니다:

1. Appwrite 설정:
   - `APPWRITE_ENDPOINT`: Appwrite API 엔드포인트
   - `APPWRITE_PROJECT_ID`: Appwrite 프로젝트 ID
   - `APPWRITE_API_KEY`: Appwrite API 키
   - `APPWRITE_DATABASE_ID`: Appwrite 데이터베이스 ID
   - `APPWRITE_COLLECTION_ID`: Appwrite 컬렉션 ID

2. Firebase 설정:
   - `FIREBASE_CREDENTIALS_PATH`: Firebase 서비스 계정 키 파일 경로
   - `FIREBASE_TOPIC`: FCM 알림을 위한 주제명

### 로컬에서 실행하기

```bash
# 의존성 설치
npm install

# .env 파일 설정
cp .env.example .env
# .env 파일 내용 편집

# 실행
npm start
```

### Appwrite 데이터베이스 설정

1. Appwrite 프로젝트 생성
2. 데이터베이스 생성
3. 게시글을 저장할 컬렉션 생성 (다음 속성 필요):
   - `boardId` (string): 게시판 ID
   - `articleId` (string): 게시글 ID
   - `title` (string): 게시글 제목
   - `link` (string): 게시글 링크
   - `pubDate` (string): 발행일
   - `author` (string): 작성자
   - `description` (string): 게시글 내용
   - `createdAt` (string): 크롤링 시간

### Firebase 설정

1. Firebase 프로젝트 생성
2. FCM 설정
3. 서비스 계정 키 발급 및 저장

## GitHub Actions 설정

GitHub 저장소에 다음 시크릿을 추가해야 합니다:

- `APPWRITE_ENDPOINT`
- `APPWRITE_PROJECT_ID`
- `APPWRITE_API_KEY`
- `APPWRITE_DATABASE_ID`
- `APPWRITE_COLLECTION_ID`
- `FIREBASE_SERVICE_ACCOUNT`: Firebase 서비스 계정 JSON 파일 내용
- `FIREBASE_TOPIC` 