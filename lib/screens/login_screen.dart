import 'package:flutter/material.dart';
import 'package:livingalonecare_app/screens/splash_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFE3CB), // 연오렌지
              Color(0xFFD7F7D4), // 연녹색 (본인 디자인에 맞춰 조정)
            ],
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ListView(
          children: [
            SizedBox(height: 32),
            // 뒤로가기 화살표
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.black, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            SizedBox(height: 16),
            // 말풍선 & 아이콘
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFFFA36A), // 오렌지
                    Color(0xFF99D279), // 옅은 녹색
                  ],
                ),
              ),
              child: Row(
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
            SizedBox(height: 24),
            Text(
              '다시 만나서\n반가워요',
              style: TextStyle(
                fontSize: 32,
                color: Color(0xFFB1B768), // 이미지 참고해서 배경과 어울리게
                fontWeight: FontWeight.w300, // 얇은 두께
              ),
            ),
            SizedBox(height: 12),
            Text(
              '맛있는 레시피가 기다리고 있어요',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
                fontWeight: FontWeight.w400,
              ),
            ),
            SizedBox(height: 28),
            // 이메일 입력 필드
            Text('이메일', style: TextStyle(fontSize: 16, color: Colors.black54)),
            SizedBox(height: 7),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(blurRadius: 5, color: Colors.black12)],
              ),
              child: TextField(
                decoration: InputDecoration(
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
            SizedBox(height: 20),
            Text('비밀번호', style: TextStyle(fontSize: 16, color: Colors.black54)),
            SizedBox(height: 7),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(blurRadius: 5, color: Colors.black12)],
              ),
              child: TextField(
                obscureText: true,
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    Icons.lock_outline,
                    color: Colors.grey,
                    size: 20,
                  ),
                  hintText: '',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 16,
                  ),
                ),
              ),
            ),
            SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '비밀번호를 잊으셨나요?',
                style: TextStyle(color: Color(0xFFFFA36A), fontSize: 13),
              ),
            ),
            SizedBox(height: 20),
            // 로그인 버튼
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  colors: [Color(0xFFFFA36A), Color(0xFF99D279)], // 오렌지~연녹
                ),
                boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black12)],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  padding: EdgeInsets.zero,
                  minimumSize: Size(double.infinity, 56),
                ),
                onPressed: () {
                  // TODO: 실제 로그인 기능 & 화면 이동 넣기
                },
                child: Text(
                  '로그인하기',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
            SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '아직 계정이 없으신가요? ',
                  style: TextStyle(fontSize: 15, color: Colors.black54),
                ),
                GestureDetector(
                  onTap: () {
                    // TODO: 회원가입 화면으로 이동
                  },
                  child: Text(
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
