import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _registerWithFirebase() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final name = _nameController.text.trim();
    final nickname = _nicknameController.text.trim();

    if (email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty ||
        name.isEmpty ||
        nickname.isEmpty) {
      // 닉네임 체크 추가
      _showSnackBar('모든 필드를 입력해주세요.');
      return;
    }

    if (password != confirmPassword) {
      _showSnackBar('비밀번호가 일치하지 않습니다.');
      return;
    }

    if (password.length < 6) {
      _showSnackBar('비밀번호는 6자리 이상이어야 합니다.');
      return;
    }

    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final user = userCredential.user;

      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': email,
          'name': name,
          'nickname': nickname,
          'level': '초보 요리사', // 기본 등급
          'profileImage': null,
          'savedRecipeCount': 0,
          'totalSavedAmount': 0,

          'registeredAt': FieldValue.serverTimestamp(),

          'monthlyGoal': {
            'title': '첫 목표를 설정해주세요',
            'description': '목표 설정하고 식비 아끼기',
            'progress': 0.0,
          },
        });
      }

      // 성공 시
      _showSnackBar('회원가입 성공! 로그인해주세요.');
      if (!mounted) return;
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String errorMessage = '회원가입 실패';
      if (e.code == 'weak-password') {
        errorMessage = '비밀번호가 너무 쉽습니다.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = '이미 사용 중인 이메일입니다.';
      } else if (e.code == 'invalid-email') {
        errorMessage = '잘못된 이메일 형식입니다.';
      }
      _showSnackBar(errorMessage);
    } catch (e) {
      _showSnackBar('오류가 발생했습니다: $e');
    }
  }

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
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0xFFFFE3CB), const Color(0xFFD7F7D4)],
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ListView(
          children: [
            const SizedBox(height: 32),
            // 뒤로가기 버튼
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.black,
                  size: 28,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(height: 10),

            // 상단 환영 메시지
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFA36A), Color(0xFF99D279)],
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      '환영해요!',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '새로운 여정의\n시작이에요',
              style: TextStyle(
                fontSize: 32,
                color: Color(0xFFB1B768),
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '나만의 레시피북을 만들어보세요',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 30),

            // 이름
            _buildLabel('이름'),
            const SizedBox(height: 8),
            _buildTextField(
              _nameController,
              '홍길동',
              Icons.person_outline,
              false,
            ),
            const SizedBox(height: 20),

            // 닉네임
            _buildLabel('닉네임'),
            const SizedBox(height: 8),
            _buildTextField(
              _nicknameController,
              '닉네임',
              Icons.person_pin_circle_outlined,
              false,
            ),
            const SizedBox(height: 20),

            // 이메일
            _buildLabel('이메일'),
            const SizedBox(height: 8),
            _buildTextField(
              _emailController,
              'your@email.com',
              Icons.email_outlined,
              false,
            ),
            const SizedBox(height: 20),

            // 비밀번호
            _buildLabel('비밀번호'),
            const SizedBox(height: 8),
            _buildTextField(
              _passwordController,
              '최소 6자 이상',
              Icons.lock_outline,
              true,
            ),
            const SizedBox(height: 20),

            // 비밀번호 확인
            _buildLabel('비밀번호 확인'),
            const SizedBox(height: 8),
            _buildTextField(
              _confirmPasswordController,
              '비밀번호를 다시 입력하세요',
              Icons.lock_reset,
              true,
            ),

            const SizedBox(height: 40),

            // 가입하기 버튼
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
                  minimumSize: const Size(double.infinity, 56),
                ),
                onPressed: _registerWithFirebase,
                child: const Text(
                  '가입하기',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '이미 계정이 있으신가요? ',
                  style: TextStyle(color: Colors.black54),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Text(
                    '로그인',
                    style: TextStyle(
                      color: Color(0xFF99D279),
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        color: Colors.black54,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon,
    bool isObscure,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(blurRadius: 5, color: Colors.black12)],
      ),
      child: TextField(
        controller: controller,
        obscureText: isObscure,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.grey[400], size: 22),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 18,
            horizontal: 16,
          ),
        ),
      ),
    );
  }
}
