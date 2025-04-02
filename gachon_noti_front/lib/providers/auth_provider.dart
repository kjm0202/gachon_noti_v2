import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/appwrite_service.dart';
import '../services/firebase_service.dart';

enum AuthStatus { initial, authenticated, unauthenticated }

class AuthProvider with ChangeNotifier {
  final AppwriteService _appwriteService = AppwriteService();
  final FirebaseService _firebaseService = FirebaseService();

  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;

  AuthStatus get status => _status;
  UserModel? get user => _user;

  AuthProvider() {
    _checkAuthStatus();
  }

  // 로그인 상태 확인
  Future<void> _checkAuthStatus() async {
    try {
      print('로그인 상태 확인 중...');
      final isLoggedIn = await _appwriteService.isLoggedIn();
      print('로그인 상태: $isLoggedIn');

      if (isLoggedIn) {
        try {
          _user = await _appwriteService.getCurrentUser();
          print('사용자 정보 로드 완료: ${_user?.name}');

          // FCM 토큰 업데이트
          if (_user != null) {
            await _firebaseService.updateToken(_user!.id);
          }

          _status = AuthStatus.authenticated;
        } catch (e) {
          print('사용자 정보 로드 실패: $e');
          _status = AuthStatus.unauthenticated;
        }
      } else {
        print('로그인되지 않은 상태');
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      print('로그인 상태 확인 중 오류 발생: $e');
      _status = AuthStatus.unauthenticated;
    } finally {
      print('최종 인증 상태: $_status');
      notifyListeners();
    }
  }

  // 구글 로그인
  Future<bool> signInWithGoogle() async {
    try {
      // 웹인 경우 Appwrite OAuth 사용
      await _appwriteService.createOAuthSession();

      // 사용자 정보 가져오기
      _user = await _appwriteService.getCurrentUser();

      // FCM 토큰 업데이트
      await _firebaseService.updateToken(_user!.id);

      // FCM 토픽 구독
      await _firebaseService.subscribeToTopic();

      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      print('구글 로그인 오류: $e');
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  // 구독 게시판 업데이트
  Future<void> updateSubscribedBoards(List<String> boardIds) async {
    try {
      if (_user != null) {
        final updatedUser = _user!.copyWith(subscribedBoards: boardIds);
        await _appwriteService.updateUserData(updatedUser);
        _user = updatedUser;
        notifyListeners();
      }
    } catch (e) {
      print('구독 게시판 업데이트 오류: $e');
    }
  }

  // 로그아웃
  Future<void> signOut() async {
    try {
      await _appwriteService.logout();
      _user = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    } catch (e) {
      print('로그아웃 오류: $e');
    }
  }
}
