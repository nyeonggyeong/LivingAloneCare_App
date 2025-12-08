import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:livingalonecare_app/screens/login_screen.dart';
import 'package:livingalonecare_app/screens/profile_edit_screen.dart';
import 'package:livingalonecare_app/screens/saved_recipes_screen.dart';
import 'package:livingalonecare_app/screens/notification_setting_screen.dart';
import 'package:livingalonecare_app/screens/settings_screen.dart';
import 'package:livingalonecare_app/screens/help_screen.dart';
import 'package:livingalonecare_app/screens/saved_money_screen.dart';
import 'package:livingalonecare_app/screens/goal_history_screen.dart';

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  // 💡 등급별 스타일(색상, 아이콘)을 가져오는 함수
  Map<String, dynamic> _getLevelStyle(String level) {
    switch (level) {
      case '요리 마스터':
        return {
          'color': const Color(0xFFFF5252), // 빨간색
          'icon': Icons.workspace_premium, // 훈장
          'bg': const Color(0xFFFFEBEE), // 연한 빨강 배경
        };
      case '고수 요리사':
        return {
          'color': const Color(0xFFFFA36A), // 주황색 (앱 테마)
          'icon': Icons.whatshot, // 불꽃
          'bg': const Color(0xFFFFF3E0), // 연한 주황 배경
        };
      case '중수 요리사':
        return {
          'color': const Color(0xFF689F38), // 진한 초록
          'icon': Icons.restaurant, // 수저/포크
          'bg': const Color(0xFFF1F8E9), // 연한 초록 배경
        };
      default: // 초보 요리사
        return {
          'color': const Color(0xFF99D279), // 연두색
          'icon': Icons.spa, // 새싹
          'bg': const Color(0xFFF9FBE7), // 아주 연한 연두 배경
        };
    }
  }

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
              const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.black87, size: 24),
                  SizedBox(width: 8),
                  Text(
                    "등급 안내",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // 💡 팝업 내부 아이템도 스타일 함수 적용
              _buildLevelItem(
                "초보 요리사",
                "레시피 저장 0~9개",
                _getLevelStyle("초보 요리사"),
              ),
              _buildLevelItem(
                "중수 요리사",
                "레시피 저장 10개 이상",
                _getLevelStyle("중수 요리사"),
              ),
              _buildLevelItem(
                "고수 요리사",
                "레시피 저장 30개 이상",
                _getLevelStyle("고수 요리사"),
              ),
              _buildLevelItem(
                "요리 마스터",
                "레시피 저장 50개 이상",
                _getLevelStyle("요리 마스터"),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLevelItem(
    String title,
    String condition,
    Map<String, dynamic> style,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: style['bg'],
              shape: BoxShape.circle,
            ),
            child: Icon(style['icon'], color: style['color'], size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: style['color'], // 등급 색상 적용
                ),
              ),
              const SizedBox(height: 2),
              Text(
                condition,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ... (이용 일수 팝업, 목표 설정 팝업 등은 기존 코드 유지) ...
  // (코드 길이 절약을 위해 생략하지 않고 아래에 전체 포함합니다)

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
  // 3. 목표 설정 팝업
  // ==========================================
  void _showGoalSettingDialog(
    BuildContext context,
    Map<String, dynamic> currentGoal,
    int currentSaved,
  ) {
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
                width: constraints.maxWidth,
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
                      final String currentMonth = DateFormat(
                        'yyyy-MM',
                      ).format(DateTime.now());

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

                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .collection('goals')
                            .doc(DateFormat('yyyy-MM').format(DateTime.now()))
                            .snapshots(),
                        builder: (context, goalSnapshot) {
                          Map<String, dynamic> currentGoal = {};
                          if (goalSnapshot.hasData &&
                              goalSnapshot.data!.exists) {
                            currentGoal =
                                goalSnapshot.data!.data()
                                    as Map<String, dynamic>;
                            // 현재 금액 동기화
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

  // 💡 [수정됨] 목표 카드 위젯 (디자인)
  Widget _buildGoalCard(
    BuildContext context,
    int totalSavedAmount,
    Map<String, dynamic> goalData,
  ) {
    final String title = goalData['title'] ?? '첫 목표를 설정해주세요';
    final int targetAmount = goalData['targetAmount'] ?? 0;

    double progress = 0.0;
    if (targetAmount > 0) {
      progress = totalSavedAmount / targetAmount;
      if (progress > 1.0) progress = 1.0;
    }
    final int percentText = (progress * 100).toInt();

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "이번 달 달성률",
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 6),
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
                          const SizedBox(width: 12),
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
                                color: Colors.white.withOpacity(0.15),
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
                                    "기록",
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
                if (targetAmount > 0)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "$percentText%",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
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

  // 💡 [수정됨] 헤더 (등급별 아이콘/색상 적용)
  Widget _buildHeader(
    BuildContext context,
    String nickname,
    String email,
    String level,
    String? imageUrl,
  ) {
    // 등급 정보 가져오기
    final levelStyle = _getLevelStyle(level);

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

                      // 💡 등급 표시 (스타일 적용)
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
                            color: levelStyle['bg'], // 등급별 배경색
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                levelStyle['icon'], // 등급별 아이콘
                                color: levelStyle['color'],
                                size: 22,
                              ),
                              const SizedBox(width: 10),
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
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: levelStyle['color'], // 등급 이름 색상
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

  // ... (buildStatCard, buildMenuOption 등 기존 함수 유지)

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
