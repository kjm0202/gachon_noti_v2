class AppConstants {
  // Appwrite 설정
  static const String appwriteEndpoint = 'https://cloud.appwrite.io/v1';

  // TODO: 실제 프로젝트 배포 시 아래 값들을 실제 값으로 변경해야 합니다
  static const String appwriteProjectId = '67ec90dc0034d207cc20';
  static const String databaseId = '67ec90f700069e02f97e';
  static const String notificationsCollectionId = '67ec9109002279fa3f2f';
  static const String usersCollectionId = '67ec919e000f59c02385';

  // Firebase 설정
  static const String firebaseTopic = 'gachon_notifications';

  // 게시판 ID 및 이름
  static final Map<String, String> boardNames = {
    'bachelor': '학사공지',
    'scholarship': '장학공지',
    'student': '학생공지',
    'job': '취업공지',
    'extracurricular': '교외활동',
    'other': '기타공지',
    'dormGlobal': '글로벌 기숙사',
    'dormMedical': '메디컬 기숙사',
  };

  // 앱 URL 스키마
  static const String appUrlScheme = 'gachonnoti';
}
