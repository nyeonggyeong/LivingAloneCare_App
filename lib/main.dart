import 'package:flutter/material.dart';
import 'package:livingalonecare_app/screens/splash_screen.dart'; // 패키지명/경로를 자기 프로젝트 구조에 맞게
import 'package:livingalonecare_app/screens/login_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(), // 시작화면(첫 화면)을 splash_screen.dart에서 가져와 연결
    );
  }
}
