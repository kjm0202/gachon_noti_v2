import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';
import 'appwrite_service.dart';

const vapidKey =
    'BDJL6cOYsJBmeK53vM3SBDchY-8PX62APrgUT7N1XjnYnrJ0pHsllkhO6b0499xCrpQf9G4OK3kniCilc_NgaI8';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;

  late FirebaseMessaging _messaging;
  final AppwriteService _appwriteService = AppwriteService();

  FirebaseService._internal();

  // Firebase 초기화
  Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // 안전하게 Firebase Messaging 인스턴스 초기화
      try {
        _messaging = FirebaseMessaging.instance;

        // 알림 권한 요청 (iOS, Web)
        NotificationSettings settings = await _messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );

        print('FCM 알림 권한 상태: ${settings.authorizationStatus}');

        // 포그라운드 메시지 처리
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

        // 메시지 클릭 처리
        FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

        // 로그인 후 토픽 구독
        if (await _appwriteService.isLoggedIn()) {
          subscribeToTopic();
        }
      } catch (e) {
        print('Firebase Messaging 초기화 오류: $e');
      }
    } catch (e) {
      print('Firebase 초기화 오류: $e');
    }
  }

  // FCM 토큰 가져오기
  Future<String?> getFcmToken() async {
    try {
      return await _messaging.getToken(vapidKey: vapidKey);
    } catch (e) {
      print('FCM 토큰 가져오기 오류: $e');
      return null;
    }
  }

  // 토큰 업데이트 및 Appwrite 저장
  Future<void> updateToken(String userId) async {
    try {
      final token = await getFcmToken();
      if (token != null) {
        await _appwriteService.updateFcmToken(userId, token);
        print('FCM 토큰 업데이트 완료: $token');
      }
    } catch (e) {
      print('FCM 토큰 업데이트 오류: $e');
    }
  }

  // FCM 토픽 구독
  Future<void> subscribeToTopic({String topic = 'gachon_notifications'}) async {
    try {
      await _messaging.subscribeToTopic(topic);
      print('토픽 구독 완료: $topic');
    } catch (e) {
      print('토픽 구독 오류: $e');
    }
  }

  // FCM 토픽 구독 해제
  Future<void> unsubscribeFromTopic({
    String topic = 'gachon_notifications',
  }) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      print('토픽 구독 해제 완료: $topic');
    } catch (e) {
      print('토픽 구독 해제 오류: $e');
    }
  }

  // 포그라운드 메시지 처리
  void _handleForegroundMessage(RemoteMessage message) {
    print('포그라운드 메시지 수신: ${message.notification?.title}');

    // TODO: 앱에서 인앱 알림 또는 토스트 메시지로 알림 표시
  }

  // 메시지 클릭 처리
  void _handleMessageOpenedApp(RemoteMessage message) {
    print('알림 클릭으로 앱 열림: ${message.notification?.title}');
    final String? link = message.data['link'];

    if (link != null && link.isNotEmpty) {
      // TODO: 링크 열기 또는 앱 내 라우팅
    }
  }
}
