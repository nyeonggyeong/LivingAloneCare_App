import 'package:flutter/material.dart';
import 'package:livingalonecare_app/screens/splash_screen.dart';
//import 'package:livingalonecare_app/screens/login_screen.dart'; // 안씀
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart'; // 💡 폰트 패키지 임포트

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    // options: DefaultFirebaseOptions.currentPlatform, // FlutterFire CLI 사용 시 이 주석을 해제
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 💡 GoogleFonts 적용 시 const를 제거해야 합니다.
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // ✨ 앱 전체 테마에 폰트 적용
      theme: ThemeData(
        textTheme: GoogleFonts.notoSansKrTextTheme(Theme.of(context).textTheme),
      ),

      home: const SplashScreen(),
    );
  }
}
