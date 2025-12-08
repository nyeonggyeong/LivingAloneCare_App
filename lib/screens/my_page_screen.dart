import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // 날짜 포맷
import 'package:livingalonecare_app/screens/login_screen.dart';
import 'package:livingalonecare_app/screens/profile_edit_screen.dart';
import 'package:livingalonecare_app/screens/saved_recipes_screen.dart';
import 'package:livingalonecare_app/screens/notification_setting_screen.dart';
import 'package:livingalonecare_app/screens/settings_screen.dart';
import 'package:livingalonecare_app/screens/help_screen.dart';
import 'package:livingalonecare_app/screens/saved_money_screen.dart';
import 'package:livingalonecare_app/screens/goal_history_screen.dart'; // 💡 월별 기록 화면

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  // ==========================================
  // 1. 등급 안내 팝업
  // ==========================================
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
                children: const [
                  Icon(Icons.verified, color: Color(0xFF99D279), size: 28),
                  SizedBox(width: 8),
                  Text(
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

  // ==========================================
  // 2. 이용 일수 상세 팝업
  // ==========================================
  void _showUsageDetail(
    BuildContext context,
    int days,
    Timestamp? registeredAt,
  ) {
    String regDateStr = "정보 없음";
    if (registeredAt != null) {
      DateTime date = registeredAt.toDate();
      regDateStr =
          "${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}";
    }

    int nextMilestone = 100;
    if (days >= 100) nextMilestone = 200;
    if (days >= 200) nextMilestone = 300;
    if (days >= 300) nextMilestone = 365;
    if (days >= 365) nextMilestone = 730;

    int daysLeft = nextMilestone - days;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.calendar_month,
                  size: 50,
                  color: Color(0xFFFFA36A),
                ),
                const SizedBox(height: 16),
                const Text(
                  "함께한 지",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                Text(
                  "${days}일째",
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFA36A),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("가입일"),
                          Text(
                            regDateStr,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("$nextMilestone일 기념일까지"),
                          Text(
                            "$daysLeft일 남음",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF99D279),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFA36A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "닫기",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // 3. 목표 설정 팝업 (가로로 넓게 + 빈칸 처리)
  // ==========================================
  void _showGoalSettingDialog(
    BuildContext context,
    Map<String, dynamic> currentGoal,
    int currentSaved,
  ) {
    // 목표 금액이 0이거나 없으면 '초기 상태'로 판단 -> 빈칸으로 시작
    final bool isInitial = (currentGoal['targetAmount'] ?? 0) == 0;

    final TextEditingController titleController = TextEditingController(
      text: isInitial ? '' : currentGoal['title'],
    );
    final TextEditingController amountController = TextEditingController(
      text: isInitial ? '' : currentGoal['targetAmount'].toString(),
    );

    showDialog(
      context: context,
      builder: (context) {
        // LayoutBuilder를 써서 팝업 가로폭 확보
        return LayoutBuilder(
          builder: (context, constraints) {
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              insetPadding: const EdgeInsets.symmetric(horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                "🎯 이번 달 목표 설정",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: constraints.maxWidth, // 가로 꽉 채우기
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: "목표 이름 (예: 배달 줄이기)",
                        hintText: "목표를 입력해주세요",
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFFFA36A)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "목표 금액 (원)",
                        hintText: "금액을 입력해주세요",
                        prefixText: "₩ ",
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFFFA36A)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("취소", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final String title = titleController.text.trim();
                    final int? target = int.tryParse(amountController.text);
                    final user = FirebaseAuth.instance.currentUser;

                    if (title.isNotEmpty &&
                        target != null &&
                        target > 0 &&
                        user != null) {
                      // 이번 달 문서 ID (예: 2025-12)
                      final String currentMonth = DateFormat(
                        'yyyy-MM',
                      ).format(DateTime.now());

                      // goals 컬렉션에 저장 (월별 관리)
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .collection('goals')
                          .doc(currentMonth)
                          .set({
                            'title': title,
                            'targetAmount': target,
                            'currentSaved': currentSaved,
                            'updatedAt': FieldValue.serverTimestamp(),
                          }, SetOptions(merge: true));

                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFA36A),
                  ),
                  child: const Text(
                    "설정 완료",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ==========================================
  // 메인 빌드 함수
  // ==========================================
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

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return SizedBox(
                height: MediaQuery.of(context).size.height,
                child: const Center(child: Text("사용자 정보를 찾을 수 없습니다.")),
              );
            }

            // 기본 데이터 파싱
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

            return Column(
              children: [
                _buildHeader(context, nickname, email, level, profileImage),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      // 통계 카드 3종
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              "저장한\n레시피",
                              "$savedRecipeCount",
                              Icons.bookmark_border,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const SavedRecipesScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              "절약한\n금액",
                              "${_formatCurrency(totalSavedAmount)}원",
                              Icons.trending_up,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const SavedMoneyScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              "이용 일수",
                              "$usageDays일",
                              Icons.calendar_today,
                              onTap: () {
                                _showUsageDetail(
                                  context,
                                  usageDays,
                                  registeredAt,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // 💡 [목표 카드] 월별 데이터 구독
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .collection('goals')
                            .doc(
                              DateFormat('yyyy-MM').format(DateTime.now()),
                            ) // 이번 달 문서
                            .snapshots(),
                        builder: (context, goalSnapshot) {
                          Map<String, dynamic> currentGoal = {};

                          if (goalSnapshot.hasData &&
                              goalSnapshot.data!.exists) {
                            currentGoal =
                                goalSnapshot.data!.data()
                                    as Map<String, dynamic>;
                            // (선택) 현재 저장 금액 동기화
                            FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.uid)
                                .collection('goals')
                                .doc(
                                  DateFormat('yyyy-MM').format(DateTime.now()),
                                )
                                .update({'currentSaved': totalSavedAmount});
                          }

                          return _buildGoalCard(
                            context,
                            totalSavedAmount,
                            currentGoal,
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      // 메뉴 리스트
                      _buildMenuOption(
                        context,
                        Icons.settings,
                        "설정",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SettingsScreen(),
                            ),
                          );
                        },
                      ),
                      _buildMenuOption(
                        context,
                        Icons.notifications_none,
                        "알림 설정",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const NotificationSettingScreen(),
                            ),
                          );
                        },
                      ),
                      _buildMenuOption(
                        context,
                        Icons.help_outline,
                        "도움말",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HelpScreen(),
                            ),
                          );
                        },
                      ),
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
    return NumberFormat('#,###').format(amount);
  }

  // 💡 [디자인 수정됨] 목표 카드 위젯
  Widget _buildGoalCard(
    BuildContext context,
    int totalSavedAmount,
    Map<String, dynamic> goalData,
  ) {
    // 1. 데이터 파싱
    final String title = goalData['title'] ?? '첫 목표를 설정해주세요';
    final int targetAmount = goalData['targetAmount'] ?? 0;

    // 2. 달성률 계산
    double progress = 0.0;
    if (targetAmount > 0) {
      progress = totalSavedAmount / targetAmount;
      if (progress > 1.0) progress = 1.0;
    }
    final int percentText = (progress * 100).toInt();

    // 3. D-Day 계산
    final now = DateTime.now();
    final lastDay = DateTime(now.year, now.month + 1, 0);
    final daysLeft = lastDay.difference(now).inDays;

    return GestureDetector(
      onTap: () {
        _showGoalSettingDialog(context, goalData, totalSavedAmount);
      },
      child: Container(
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
            // 상단 영역 (텍스트 정보 vs 퍼센트 정보)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start, // 💡 우측 정보를 위쪽으로 올림
              children: [
                // 좌측: 라벨, 제목, 히스토리 버튼
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "이번 달 달성률",
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 6), // 간격 조정
                      // 제목 + 편집 아이콘 + 히스토리 버튼 줄
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.edit,
                            color: Colors.white54,
                            size: 14,
                          ),

                          const SizedBox(width: 12), // 제목과 히스토리 버튼 사이 간격
                          // 💡 히스토리 버튼 (아이콘 + 설명)
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const GoalHistoryScreen(),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(
                                  0.15,
                                ), // 살짝 배경을 줘서 버튼처럼 보이게
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(
                                    Icons.history,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    "기록", // 설명 추가
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),
                      Text(
                        targetAmount > 0
                            ? "목표: ${_formatCurrency(targetAmount)}원 / 현재: ${_formatCurrency(totalSavedAmount)}원"
                            : "목표 설정하고 식비 아끼기",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // 우측: 퍼센트 및 D-Day (위쪽 정렬됨)
                if (targetAmount > 0)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "$percentText%",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 24, // 숫자 크기 살짝 키움
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "D-$daysLeft",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // 진행 바
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
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
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
          child: Builder(
            builder: (context) {
              return GestureDetector(
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
                      GestureDetector(
                        onTap: () {
                          _showLevelGuide(context);
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
                                      ),
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
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
