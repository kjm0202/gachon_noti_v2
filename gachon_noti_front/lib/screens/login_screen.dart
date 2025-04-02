import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

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
            // 로그인 버튼
            ElevatedButton.icon(
              onPressed: () => _signInWithGoogle(context),
              icon: const Icon(Icons.login),
              label: const Text('구글 계정으로 로그인'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.black87,
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _signInWithGoogle(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // 로딩 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 로그인 시도
      final success = await authProvider.signInWithGoogle();

      // 로딩 닫기
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // 로그인 결과 처리
      if (success && context.mounted) {
        // 성공 시 홈 화면으로 이동
        Navigator.of(context).pushReplacementNamed('/home');
      } else if (context.mounted) {
        // 실패 시 오류 메시지 표시
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('로그인에 실패했습니다. 다시 시도해주세요.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // 오류 처리
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그인 오류: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
