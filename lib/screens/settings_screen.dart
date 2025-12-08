import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:livingalonecare_app/screens/login_screen.dart';
import 'package:url_launcher/url_launcher.dart'; // url_launcher 패키지 필요 (없으면 생략 가능)

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  bool _isLoading = false;

  // 1. 비밀번호 재설정 이메일 발송
  Future<void> _sendPasswordResetEmail() async {
    if (user?.email == null) return;

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: user!.email!);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('비밀번호 재설정 이메일을 보냈습니다.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이메일 전송 실패. 잠시 후 다시 시도해주세요.')),
        );
      }
    }
  }

  // 2. 로그아웃
  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  // 3. 회원 탈퇴 (핵심 기능)
  Future<void> _deleteAccount() async {
    if (user == null) return;

    // 재확인 다이얼로그
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("정말 떠나시나요? 😢"),
        content: const Text(
          "회원 탈퇴 시 저장된 레시피와 냉장고 재료 등\n모든 데이터가 영구적으로 삭제됩니다.",
          style: TextStyle(color: Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("취소", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("탈퇴하기", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      // 1) Firestore 유저 데이터 삭제
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .delete();

      // 2) Firebase Auth 계정 삭제
      await user!.delete();

      if (mounted) {
        // 로그인 화면으로 이동
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('계정이 안전하게 삭제되었습니다.')));
      }
    } on FirebaseAuthException catch (e) {
      // 보안상 재로그인이 필요한 경우 처리
      if (e.code == 'requires-recent-login') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('안전을 위해 다시 로그인 후 시도해주세요.')),
          );
          await _signOut(); // 로그아웃 시켜서 재로그인 유도
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('오류 발생: ${e.message}')));
        }
      }
    } catch (e) {
      print("탈퇴 오류: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 4. 이용약관 등 웹페이지 열기 (옵션)
  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('페이지를 열 수 없습니다.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text(
          "설정",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFA36A)),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildSectionHeader("계정"),
                _buildSettingItem(
                  icon: Icons.lock_reset,
                  title: "비밀번호 재설정",
                  onTap: _sendPasswordResetEmail,
                ),
                _buildSettingItem(
                  icon: Icons.logout,
                  title: "로그아웃",
                  onTap: _signOut,
                ),
                _buildSettingItem(
                  icon: Icons.person_off,
                  title: "회원 탈퇴",
                  textColor: Colors.red,
                  iconColor: Colors.red,
                  onTap: _deleteAccount,
                ),

                const SizedBox(height: 24),

                _buildSectionHeader("앱 정보"),
                _buildSettingItem(
                  icon: Icons.info_outline,
                  title: "현재 버전",
                  trailing: const Text(
                    "v1.0.0",
                    style: TextStyle(
                      color: Color(0xFFFFA36A),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildSettingItem(
                  icon: Icons.description_outlined,
                  title: "이용약관",
                  onTap: () {
                    // 실제 약관 URL이 있다면 연결, 없으면 스낵바
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('준비 중인 페이지입니다.')),
                    );
                  },
                ),
                _buildSettingItem(
                  icon: Icons.policy_outlined,
                  title: "개인정보 처리방침",
                  onTap: () {
                    // _launchUrl('https://your-privacy-policy-url.com');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('준비 중인 페이지입니다.')),
                    );
                  },
                ),
                _buildSettingItem(
                  icon: Icons.code,
                  title: "오픈소스 라이선스",
                  onTap: () {
                    // 플러터 내장 라이선스 페이지 호출
                    showLicensePage(
                      context: context,
                      applicationName: "자취생 키우기",
                      applicationVersion: "v1.0.0",
                      applicationIcon: const Icon(Icons.restaurant, size: 50),
                    );
                  },
                ),

                const SizedBox(height: 40),
                const Center(
                  child: Text(
                    "© 2025 Living Alone Care. All rights reserved.",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    Widget? trailing,
    Color textColor = Colors.black87,
    Color iconColor = Colors.black54,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(
          title,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
        ),
        trailing:
            trailing ??
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      ),
    );
  }
}
