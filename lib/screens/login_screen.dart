import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:livingalonecare_app/screens/home_screen.dart';
import 'package:livingalonecare_app/screens/signup_screen.dart'; // 회원가입 화면 경로 (필요시 주석 해제)
import 'package:livingalonecare_app/screens/home_screen.dart'; // 로그인 성공 후 이동할 화면 경로 (필요시 주석 해제)
import 'package:livingalonecare_app/main.dart';
import 'package:livingalonecare_app/screens/splash_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithFirebase() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('이메일과 비밀번호를 모두 입력해주세요.');
      return;
    }

    try {
      // 💡 Firebase Auth API 호출
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // ✅ 로그인 성공 시: 다음 화면으로 이동
      _showSnackBar('로그인 성공!');
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false, // 모든 이전 화면 스택 제거 (뒤로 가기 누르면 앱 종료)
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage = '로그인에 실패했습니다. 다시 시도해주세요.';
      if (e.code == 'user-not-found') {
        errorMessage = '등록되지 않은 이메일입니다.';
      } else if (e.code == 'wrong-password') {
        errorMessage = '비밀번호가 일치하지 않습니다.';
      } else {
        errorMessage = '오류 코드: ${e.code}';
      }
      _showSnackBar(errorMessage);
    } catch (e) {
      _showSnackBar('알 수 없는 오류가 발생했습니다.');
      print(e);
    }
  }

  // 사용자에게 메시지를 보여주는 Helper 함수
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          // 그라데이션 배경
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0xFFFFE3CB), const Color(0xFFD7F7D4)],
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ListView(
          // ListView를 사용하여 스크롤 가능하게 함 (키보드가 올라왔을 때 오버플로우 방지)
          children: [
            const SizedBox(height: 32),
            // 뒤로가기 화살표
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.black,
                  size: 28,
                ),
                onPressed: () {
                  // 현재 화면 뒤에 돌아갈 페이지가 있는지 확인
                  if (Navigator.canPop(context)) {
                    // 돌아갈 곳이 있으면 정상적으로 뒤로가기
                    Navigator.pop(context);
                  } else {
                    // 돌아갈 곳이 없으면(로그아웃 직후 등) 시작 화면(스플래시)으로 이동
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SplashScreen(),
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 16),
            // 말풍선 & 아이콘 (기존 UI 요소)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFA36A), Color(0xFF99D279)],
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome, color: Colors.white, size: 22),
                  SizedBox(width: 6),
                  Text(
                    '반가워요!',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '다시 만나서\n반가워요',
              style: TextStyle(
                fontSize: 32,
                color: Color(0xFFB1B768),
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '맛있는 레시피가 기다리고 있어요',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 28),
            // 이메일 입력 필드
            const Text(
              '이메일',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 7),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(blurRadius: 5, color: Colors.black12),
                ],
              ),
              child: TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  prefixIcon: Icon(
                    Icons.email_outlined,
                    color: Colors.grey,
                    size: 20,
                  ),
                  hintText: 'your@email.com',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // 비밀번호 입력 필드
            const Text(
              '비밀번호',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 7),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(blurRadius: 5, color: Colors.black12),
                ],
              ),
              child: TextField(
                controller: _passwordController, // 💡 컨트롤러 연결
                obscureText: true, // 비밀번호 숨기기
                decoration: const InputDecoration(
                  prefixIcon: Icon(
                    Icons.lock_outline,
                    color: Colors.grey,
                    size: 20,
                  ),
                  hintText: '비밀번호 입력', // 힌트 텍스트 추가
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Align(
              alignment: Alignment.centerRight,
              child: Text(
                '비밀번호를 잊으셨나요?',
                style: TextStyle(color: Color(0xFFFFA36A), fontSize: 13),
              ),
            ),
            const SizedBox(height: 20),
            // 로그인 버튼
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFA36A), Color(0xFF99D279)],
                ),
                boxShadow: const [
                  BoxShadow(blurRadius: 10, color: Colors.black12),
                ],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(double.infinity, 56),
                ),
                onPressed: _signInWithFirebase, // 💡 Firebase 로그인 함수 연결
                child: const Text(
                  '로그인하기',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 18),
            // 회원가입 안내
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '아직 계정이 없으신가요? ',
                  style: TextStyle(fontSize: 15, color: Colors.black54),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SignupScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    '회원가입',
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFFFFA36A),
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
