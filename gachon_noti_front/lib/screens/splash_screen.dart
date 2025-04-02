import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/firebase_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // 임의 지연 없이 바로 인증 체크 시작
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    print('스플래시 화면에서 인증 상태 확인 중...');

    // 상태가 변경될 때마다 화면 전환을 위해 리스너 등록
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      // AuthProvider의 _checkAuthStatus 메서드 완료를 기다림
      // 이 안에서 FCM 토큰 업데이트까지 수행됨
      await authProvider.checkAndUpdateAuthStatus();

      if (!mounted) return;

      // 인증 상태에 따라 화면 전환
      if (authProvider.status == AuthStatus.authenticated) {
        print('인증됨: 홈 화면으로 이동');
        _navigateToHome();
      } else {
        print('인증되지 않음: 로그인 화면으로 이동');
        _navigateToLogin();
      }
    } catch (e) {
      print('인증 프로세스 중 오류 발생: $e');
      if (!mounted) return;
      _navigateToLogin();
    }
  }

  void _navigateToHome() {
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
  }

  void _navigateToLogin() {
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF00539C), // 가천대학교 블루 색상
              Color(0xFF0072CE),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 로고 이미지
            Image.asset(
              'assets/images/logo.png',
              width: 120,
              height: 120,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.school, size: 120, color: Colors.white);
              },
            ),
            const SizedBox(height: 24),
            // 앱 이름
            const Text(
              '가천 알림',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            // 앱 설명
            const Text(
              '가천대학교 공지사항 알림 서비스',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 48),
            // 로딩 인디케이터
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
