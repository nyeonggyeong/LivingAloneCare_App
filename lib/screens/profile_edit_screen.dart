import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nicknameController = TextEditingController();

  // 데이터 로딩 상태
  bool _isLoading = true;
  String _email = '';
  String _level = '';
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  // 사용자 정보 불러오기
  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          setState(() {
            _email = user.email ?? '';
            _nicknameController.text = data['nickname'] ?? '';
            _level = data['level'] ?? '초보 요리사';
            _profileImageUrl = data['profileImage'];
            _isLoading = false;
          });
        }
      } catch (e) {
        // 에러 처리
        print('Error loading user data: $e');
        setState(() => _isLoading = false);
      }
    }
  }

  // 정보 저장하기
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
              'nickname': _nicknameController.text.trim(),
              // 이미지는 추후 Storage 구현 시 업데이트 로직 추가
            });

        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('정보가 수정되었습니다.')));
        Navigator.pop(context); // 수정 후 뒤로가기
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('오류 발생: $e')));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  // 비밀번호 재설정 메일 발송
  Future<void> _sendPasswordResetEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email != null) {
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: user!.email!);
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('비밀번호 재설정 이메일을 보냈습니다.')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('메일 발송 실패. 잠시 후 다시 시도해주세요.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('내 정보 수정', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: const Text(
              '저장',
              style: TextStyle(
                color: Color(0xFFFFA36A),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. 프로필 이미지 섹션
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.grey[200]!,
                                width: 2,
                              ),
                              image: DecorationImage(
                                image: _profileImageUrl != null
                                    ? NetworkImage(_profileImageUrl!)
                                    : const AssetImage(
                                            'assets/images/profile_placeholder.png',
                                          )
                                          as ImageProvider, // 기본 이미지 에셋 필요 (없으면 Icon으로 대체 가능)
                                fit: BoxFit.cover,
                              ),
                            ),
                            child: _profileImageUrl == null
                                ? Icon(
                                    Icons.person,
                                    size: 50,
                                    color: Colors.grey[400],
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () {
                                // TODO: 이미지 피커(Image Picker) 기능 구현 필요
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('이미지 변경 기능은 추후 구현됩니다.'),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF99D279),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // 2. 닉네임 입력
                    _buildLabel('닉네임'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nicknameController,
                      decoration: _inputDecoration('닉네임을 입력하세요'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '닉네임을 입력해주세요.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // 3. 이메일 (수정 불가)
                    _buildLabel('이메일'),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: _email,
                      readOnly: true,
                      style: const TextStyle(color: Colors.grey),
                      decoration: _inputDecoration(
                        '',
                      ).copyWith(filled: true, fillColor: Colors.grey[100]),
                    ),
                    const SizedBox(height: 24),

                    // 4. 현재 등급 (수정 불가)
                    _buildLabel('현재 등급'),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.verified,
                            color: Color(0xFF99D279),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _level,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // 5. 계정 관리 버튼들
                    const Divider(),
                    ListTile(
                      leading: const Icon(
                        Icons.lock_reset,
                        color: Colors.black54,
                      ),
                      title: const Text('비밀번호 변경'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _sendPasswordResetEmail,
                    ),
                    ListTile(
                      leading: const Icon(Icons.person_off, color: Colors.red),
                      title: const Text(
                        '회원 탈퇴',
                        style: TextStyle(color: Colors.red),
                      ),
                      onTap: () {
                        // TODO: 회원 탈퇴 로직 구현 (재인증 필요)
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('회원 탈퇴 기능은 안전을 위해 재인증이 필요합니다.'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFFFA36A)),
      ),
    );
  }
}
