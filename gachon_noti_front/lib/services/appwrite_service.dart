import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart';
import 'package:appwrite/models.dart' as models;
import 'package:flutter/foundation.dart';
import '../models/notification_item.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class AppwriteService {
  static final AppwriteService _instance = AppwriteService._internal();
  factory AppwriteService() => _instance;

  late Client client;
  late Account account;
  late Databases databases;

  AppwriteService._internal() {
    print('AppwriteService 초기화 중...');
    print('Endpoint: ${AppConstants.appwriteEndpoint}');
    print('Project ID: ${AppConstants.appwriteProjectId}');

    try {
      client =
          Client()
            ..setEndpoint(AppConstants.appwriteEndpoint)
            ..setProject(AppConstants.appwriteProjectId)
            ..setSelfSigned(status: true); // 개발 환경에서만 사용

      account = Account(client);
      databases = Databases(client);
      print('AppwriteService 초기화 완료');
    } catch (e) {
      print('AppwriteService 초기화 오류: $e');
    }
  }

  // 로그인 상태 확인
  Future<bool> isLoggedIn() async {
    try {
      print('Appwrite 로그인 상태 확인 중...');
      final result = await account.get();
      print('Appwrite 세션 확인 성공: ${result.email}');
      return true;
    } catch (e) {
      if (e is AppwriteException) {
        print('Appwrite 세션 확인 실패: ${e.message}, 코드: ${e.code}');
      } else {
        print('Appwrite 세션 확인 중 알 수 없는 오류: $e');
      }
      return false;
    }
  }

  // 구글 OAuth 로그인 URL 생성
  Future<void> createOAuthSession() async {
    try {
      String redirectUrl =
          kIsWeb ? Uri.base.toString() : 'gachonnoti://login-callback';

      print('OAuth 세션 생성 시도: $redirectUrl');

      await account.createOAuth2Session(
        provider: OAuthProvider.google,
        success: redirectUrl,
        failure: redirectUrl,
      );

      print('OAuth 세션 생성 완료');
    } catch (e) {
      if (e is AppwriteException) {
        print('OAuth 세션 생성 실패: ${e.message}, 코드: ${e.code}');
      } else {
        print('OAuth 세션 생성 중 알 수 없는 오류: $e');
      }
      rethrow;
    }
  }

  // 세션 정보 가져오기
  Future<models.Session> getSession() async {
    try {
      print('현재 세션 정보 요청 중...');
      final session = await account.getSession(sessionId: 'current');
      print('세션 정보 불러오기 성공: ${session.$id}');
      return session;
    } catch (e) {
      if (e is AppwriteException) {
        print('세션 정보 불러오기 실패: ${e.message}, 코드: ${e.code}');
      } else {
        print('세션 정보 불러오기 중 알 수 없는 오류: $e');
      }
      rethrow;
    }
  }

  // 현재 사용자 정보 가져오기
  Future<UserModel> getCurrentUser() async {
    try {
      print('Appwrite에서 사용자 정보 불러오기 시도 중...');
      final user = await account.get();
      print('기본 사용자 정보 불러오기 성공: ${user.name}, ${user.email}');

      try {
        // Appwrite 데이터베이스에서 추가 정보 가져오기
        print('데이터베이스에서 추가 사용자 정보 가져오기 시도...');
        print('Database ID: ${AppConstants.databaseId}');
        print('Collection ID: ${AppConstants.usersCollectionId}');
        print('User ID: ${user.$id}');

        final userData = await databases.getDocument(
          databaseId: AppConstants.databaseId,
          collectionId: AppConstants.usersCollectionId,
          documentId: user.$id,
        );

        print('추가 사용자 정보 가져오기 성공');
        return UserModel.fromJson({...user.toMap(), ...userData.data});
      } catch (e) {
        // 사용자가 아직 데이터베이스에 없는 경우
        if (e is AppwriteException) {
          print('추가 사용자 정보 가져오기 실패: ${e.message}, 코드: ${e.code}');
          if (e.code == 404) {
            print('사용자 데이터가 없습니다. 기본 모델 사용');
          }
        } else {
          print('추가 사용자 정보 가져오기 중 알 수 없는 오류: $e');
        }

        return UserModel(
          id: user.$id,
          name: user.name,
          email: user.email,
          photoUrl: null,
          subscribedBoards: [],
          fcmToken: null,
        );
      }
    } catch (e) {
      if (e is AppwriteException) {
        print('사용자 정보 불러오기 실패: ${e.message}, 코드: ${e.code}');
      } else {
        print('사용자 정보 불러오기 중 알 수 없는 오류: $e');
      }
      rethrow;
    }
  }

  // 사용자 정보 업데이트
  Future<void> updateUserData(UserModel user) async {
    try {
      await databases.updateDocument(
        databaseId: AppConstants.databaseId,
        collectionId: AppConstants.usersCollectionId,
        documentId: user.id,
        data: user.toJson(),
      );
    } catch (e) {
      // document가 없으면 생성
      if (e is AppwriteException && e.code == 404) {
        await databases.createDocument(
          databaseId: AppConstants.databaseId,
          collectionId: AppConstants.usersCollectionId,
          documentId: user.id,
          data: user.toJson(),
        );
      } else {
        rethrow;
      }
    }
  }

  // FCM 토큰 업데이트
  Future<void> updateFcmToken(String userId, String token) async {
    try {
      await databases.updateDocument(
        databaseId: AppConstants.databaseId,
        collectionId: AppConstants.usersCollectionId,
        documentId: userId,
        data: {'fcmToken': token},
      );
    } catch (e) {
      if (e is AppwriteException && e.code == 404) {
        // 사용자 정보 가져오기 시도
        try {
          final user = await account.get();
          await databases.createDocument(
            databaseId: AppConstants.databaseId,
            collectionId: AppConstants.usersCollectionId,
            documentId: userId,
            data: {
              'fcmToken': token,
              'subscribedBoards': [],
              'name': user.name, // 필수 필드 name 추가
              'email': user.email, // 이메일도 추가
              'photoUrl': null,
            },
          );
        } catch (accountError) {
          print('사용자 계정 정보 가져오기 실패: $accountError');
          // 최소한의 필수 필드만 포함
          await databases.createDocument(
            databaseId: AppConstants.databaseId,
            collectionId: AppConstants.usersCollectionId,
            documentId: userId,
            data: {
              'fcmToken': token,
              'subscribedBoards': [],
              'name': '사용자', // 기본 이름 제공
              'email': '', // 빈 이메일
            },
          );
        }
      } else {
        rethrow;
      }
    }
  }

  // 게시글 목록 가져오기
  Future<List<NotificationItem>> getNotifications({
    int limit = 20,
    int offset = 0,
    String? boardId,
  }) async {
    try {
      List<String> queries = [
        Query.orderDesc('createdAt'),
        Query.limit(limit),
        Query.offset(offset),
      ];

      if (boardId != null && boardId.isNotEmpty) {
        queries.add(Query.equal('boardId', boardId));
      }

      final response = await databases.listDocuments(
        databaseId: AppConstants.databaseId,
        collectionId: AppConstants.notificationsCollectionId,
        queries: queries,
      );

      return response.documents
          .map(
            (doc) =>
                NotificationItem.fromJson(doc.data..addAll({'\$id': doc.$id})),
          )
          .toList();
    } catch (e) {
      print('게시글 목록 가져오기 오류: $e');
      return [];
    }
  }

  // 로그아웃
  Future<void> logout() async {
    try {
      print('로그아웃 시도 중...');
      await account.deleteSession(sessionId: 'current');
      print('로그아웃 성공');
    } catch (e) {
      if (e is AppwriteException) {
        print('로그아웃 실패: ${e.message}, 코드: ${e.code}');
      } else {
        print('로그아웃 중 알 수 없는 오류: $e');
      }
      rethrow;
    }
  }
}
