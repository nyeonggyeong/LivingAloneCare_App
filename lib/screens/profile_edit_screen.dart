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
  final TextEditingController _bioController =
      TextEditingController(); // 한 줄 소개

  bool _isLoading = true;
  String _email = '';
  String? _profileImageUrl;

  // 식습관 태그 목록 (DB에 저장될 리스트)
  List<String> _selectedPreferences = [];

  // 선택 가능한 옵션들
  final List<String> _preferenceOptions = [
    '다이어트',
    '비건',
    '채식',
    '육류러버',
    '매운맛 고수',
    '맵찔이',
    '저염식',
    '키토제닉',
    '견과류 알러지',
    '유제품 알러지',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

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
            _bioController.text = data['bio'] ?? ''; // 한 줄 소개 불러오기
            _profileImageUrl = data['profileImage'];

            // 태그 불러오기
            if (data['preferences'] != null) {
              _selectedPreferences = List<String>.from(data['preferences']);
            }

            _isLoading = false;
          });
        }
      } catch (e) {
        print('Error: $e');
        setState(() => _isLoading = false);
      }
    }
  }

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
              'bio': _bioController.text.trim(), // 한 줄 소개 저장
              'preferences': _selectedPreferences, // 태그 저장
            });

        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('프로필이 업데이트되었습니다! ✨')));
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('오류 발생: $e')));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          '프로필 편집',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
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
              '완료',
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
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFA36A)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. 프로필 이미지 (기존 동일)
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
                                          as ImageProvider,
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // 2. 닉네임 & 이메일
                    _buildLabel('닉네임'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nicknameController,
                      decoration: _inputDecoration('닉네임을 입력하세요'),
                      validator: (v) => v!.isEmpty ? '닉네임을 입력해주세요.' : null,
                    ),
                    const SizedBox(height: 16),

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

                    // 3. 한 줄 소개 (New!)
                    _buildLabel('한 줄 소개'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _bioController,
                      maxLength: 50, // 글자수 제한
                      decoration: _inputDecoration('나만의 요리 스타일을 소개해주세요!'),
                    ),
                    const SizedBox(height: 24),

                    // 4. 식습관 태그 선택 (New!)
                    _buildLabel('나의 식습관 & 알레르기'),
                    const SizedBox(height: 4),
                    const Text(
                      "선택하신 정보를 바탕으로 레시피를 추천해드려요.",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _preferenceOptions.map((option) {
                        final isSelected = _selectedPreferences.contains(
                          option,
                        );
                        return FilterChip(
                          label: Text(option),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedPreferences.add(option);
                              } else {
                                _selectedPreferences.remove(option);
                              }
                            });
                          },
                          selectedColor: const Color(
                            0xFFFFA36A,
                          ).withOpacity(0.2),
                          checkmarkColor: const Color(0xFFFFA36A),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? const Color(0xFFFFA36A)
                                : Colors.black87,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected
                                  ? const Color(0xFFFFA36A)
                                  : Colors.grey[300]!,
                            ),
                          ),
                        );
                      }).toList(),
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
