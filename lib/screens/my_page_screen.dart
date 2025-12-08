import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:livingalonecare_app/screens/login_screen.dart';
import 'package:livingalonecare_app/screens/profile_edit_screen.dart';

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  // 💡 1. 등급 안내 팝업 함수 (새로 추가됨)
  void _showLevelGuide(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.verified,
                    color: Color(0xFF99D279),
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "등급 안내",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildLevelItem("초보 요리사", "레시피 저장 0~9개", Colors.grey),
              _buildLevelItem("중수 요리사", "레시피 저장 10개 이상", Colors.green),
              _buildLevelItem("고수 요리사", "레시피 저장 30개 이상", Colors.orange),
              _buildLevelItem("요리 마스터", "레시피 저장 50개 이상", Colors.redAccent),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // 등급 안내 아이템 위젯
  Widget _buildLevelItem(String title, String condition, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          Text(
            condition,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text("로그인이 필요합니다."));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SingleChildScrollView(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return SizedBox(
                height: MediaQuery.of(context).size.height,
                child: const Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return SizedBox(
                height: MediaQuery.of(context).size.height,
                child: Center(child: Text('오류 발생: ${snapshot.error}')),
              );
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return SizedBox(
                height: MediaQuery.of(context).size.height,
                child: const Center(child: Text("사용자 정보를 찾을 수 없습니다.")),
              );
            }

            final data = snapshot.data!.data() as Map<String, dynamic>;

            final String nickname = data['nickname'] ?? '이름 없음';
            final String email = data['email'] ?? user.email ?? '';
            final String level = data['level'] ?? '초보 요리사';
            final String? profileImage = data['profileImage'];

            final int savedRecipeCount = data['savedRecipeCount'] ?? 0;
            final int totalSavedAmount = data['totalSavedAmount'] ?? 0;

            final Timestamp? registeredAt = data['registeredAt'];
            final int usageDays = registeredAt != null
                ? DateTime.now().difference(registeredAt.toDate()).inDays + 1
                : 1;

            final Map<String, dynamic> goal = data['monthlyGoal'] ?? {};
            final String goalTitle = goal['title'] ?? '목표를 설정해보세요';
            final String goalDesc = goal['description'] ?? '설정 > 목표 관리에서 설정 가능';
            final double progress = (goal['progress'] ?? 0.0).toDouble();

            return Column(
              children: [
                // 💡 context를 인자로 전달하도록 수정
                _buildHeader(context, nickname, email, level, profileImage),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              "저장한\n레시피",
                              "$savedRecipeCount",
                              Icons.bookmark_border,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              "절약한\n금액",
                              "${_formatCurrency(totalSavedAmount)}원",
                              Icons.trending_up,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              "이용 일수",
                              "$usageDays일",
                              Icons.calendar_today,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildGoalCard(goalTitle, goalDesc, progress),
                      const SizedBox(height: 20),
                      _buildMenuOption(context, Icons.settings, "설정"),
                      _buildMenuOption(
                        context,
                        Icons.notifications_none,
                        "알림 설정",
                      ),
                      _buildMenuOption(context, Icons.help_outline, "도움말"),
                      _buildMenuOption(
                        context,
                        Icons.logout,
                        "로그아웃",
                        isRed: true,
                        onTap: () async {
                          await FirebaseAuth.instance.signOut();
                          if (context.mounted) {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                              (route) => false,
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 40),
                      const Text(
                        "Recipe Finder v1.0.0",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  // 💡 Header 함수 수정: BuildContext context 추가
  Widget _buildHeader(
    BuildContext context, // 👈 context 추가됨
    String nickname,
    String email,
    String level,
    String? imageUrl,
  ) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 300,
          width: double.infinity,
          color: Colors.transparent,
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 220,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFA36A), Color(0xFF99D279)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            padding: const EdgeInsets.only(top: 60, left: 24, right: 24),
            child: const Text(
              "마이페이지",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        Positioned(
          top: 110,
          left: 20,
          right: 20,
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileEditScreen(),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: imageUrl != null
                            ? NetworkImage(imageUrl)
                            : null,
                        child: imageUrl == null
                            ? const Icon(
                                Icons.person,
                                size: 30,
                                color: Colors.grey,
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nickname,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              email,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 💡 2. 등급 부분 클릭 가능하게 수정 (GestureDetector 추가)
                  GestureDetector(
                    onTap: () {
                      _showLevelGuide(context); // 팝업 띄우기 함수 호출
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F8E9),
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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Text(
                                    "현재 등급",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(
                                    Icons.info_outline,
                                    size: 12,
                                    color: Colors.grey,
                                  ), // 안내 아이콘 추가
                                ],
                              ),
                              Text(
                                level,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      height: 130,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFFFFA36A), size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(String title, String desc, double progress) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFA36A), Color(0xFF99D279)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF99D279).withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "이번 달 달성률",
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuOption(
    BuildContext context,
    IconData icon,
    String title, {
    bool isRed = false,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: isRed ? Colors.red : Colors.black87),
        title: Text(
          title,
          style: TextStyle(
            color: isRed ? Colors.red : Colors.black87,
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
