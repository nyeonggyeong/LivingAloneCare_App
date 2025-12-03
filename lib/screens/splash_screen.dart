import 'package:flutter/material.dart';
import 'package:livingalonecare_app/screens/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 💡 Firebase Auth 추가
import 'package:livingalonecare_app/screens/home_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 248, 134, 41), // 위쪽 오렌지
              Color.fromARGB(
                255,
                144,
                188,
                79,
              ), // 아래쪽(약간의 연두~초록톤, 정확한 색상은 샘플 참고)
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 70),
            // 앱 아이콘 (흰 네모+프라이팬)
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(Icons.restaurant, color: Colors.orange, size: 48),
            ),
            SizedBox(height: 16),
            // AI 레시피 추천 말풍선
            Container(
              padding: EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                "AI 레시피 추천",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            SizedBox(height: 12),
            Text(
              "“자취생 키우기”",
              style: TextStyle(
                color: Colors.white,
                fontSize: 50,
                fontWeight: FontWeight.w300,
              ),
            ),
            SizedBox(height: 16),
            Text(
              "냉장고 재료만 입력하면\n딱 맞는 레시피를 추천해드려요",
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            // 샐러드 이미지
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                'assets/salad.jpg',
                width: 320,
                height: 250,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(height: 30),
            // 지금 시작하기 버튼
            ElevatedButton.icon(
              onPressed: () {
                // 1. 현재 사용자가 로그인되어 있는지 확인
                final user = FirebaseAuth.instance.currentUser;

                if (user != null) {
                  // ✅ 로그인 O -> 홈 화면으로 이동 (뒤로 가기 시 스플래시 안 나오게 교체)
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                  );
                } else {
                  // ❌ 로그인 X -> 로그인 화면으로 이동
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                minimumSize: const Size(360, 60),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 4,
              ),
              icon: const Icon(Icons.bolt, color: Colors.orange),
              label: const Text(
                "지금 시작하기",
                style: TextStyle(fontSize: 15, color: Colors.orange),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(height: 12),
            // 로그인 버튼
            OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.white30),
                minimumSize: Size(360, 60),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: Text(
                "로그인",
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
