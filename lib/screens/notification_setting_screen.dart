import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationSettingScreen extends StatefulWidget {
  const NotificationSettingScreen({super.key});

  @override
  State<NotificationSettingScreen> createState() =>
      _NotificationSettingScreenState();
}

class _NotificationSettingScreenState extends State<NotificationSettingScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  bool _isLoading = true;

  // 설정값 (기본값)
  bool _expiryAlert = true;
  bool _recommendAlert = true;
  bool _communityAlert = true;
  bool _marketingAlert = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // 설정 불러오기
  Future<void> _loadSettings() async {
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      if (doc.exists && doc.data()!.containsKey('notificationSettings')) {
        final data =
            doc.data()!['notificationSettings'] as Map<String, dynamic>;
        setState(() {
          _expiryAlert = data['expiryAlert'] ?? true;
          _recommendAlert = data['recommendAlert'] ?? true;
          _communityAlert = data['communityAlert'] ?? true;
          _marketingAlert = data['marketingAlert'] ?? false;
        });
      }
    } catch (e) {
      print("설정 로드 오류: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 설정 저장
  Future<void> _updateSetting(String key, bool value) async {
    if (user == null) return;

    setState(() {
      if (key == 'expiryAlert') _expiryAlert = value;
      if (key == 'recommendAlert') _recommendAlert = value;
      if (key == 'communityAlert') _communityAlert = value;
      if (key == 'marketingAlert') _marketingAlert = value;
    });

    try {
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
        'notificationSettings': {
          'expiryAlert': _expiryAlert,
          'recommendAlert': _recommendAlert,
          'communityAlert': _communityAlert,
          'marketingAlert': _marketingAlert,
        },
      }, SetOptions(merge: true));
    } catch (e) {
      print("설정 저장 오류: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text(
          "알림 설정",
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
                _buildSectionHeader("기본 알림"),
                _buildSwitchTile(
                  title: "유통기한 임박 알림",
                  subtitle: "식재료 유통기한 3일 전, 1일 전에 알려드려요.",
                  value: _expiryAlert,
                  onChanged: (v) => _updateSetting('expiryAlert', v),
                ),
                _buildSwitchTile(
                  title: "식사/레시피 추천",
                  subtitle: "식사 시간에 맞춰 메뉴를 추천해드려요.",
                  value: _recommendAlert,
                  onChanged: (v) => _updateSetting('recommendAlert', v),
                ),
                const SizedBox(height: 24),
                _buildSectionHeader("활동 및 혜택"),
                _buildSwitchTile(
                  title: "커뮤니티 활동 알림",
                  subtitle: "내 글에 댓글이나 좋아요가 달리면 알려드려요.",
                  value: _communityAlert,
                  onChanged: (v) => _updateSetting('communityAlert', v),
                ),
                _buildSwitchTile(
                  title: "이벤트 및 혜택 정보",
                  subtitle: "공동구매 특가나 이벤트 소식을 받아보세요.",
                  value: _marketingAlert,
                  onChanged: (v) => _updateSetting('marketingAlert', v),
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

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
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
      child: SwitchListTile(
        activeColor: const Color(0xFFFFA36A),
        activeTrackColor: const Color(0xFFFFA36A).withOpacity(0.4),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
