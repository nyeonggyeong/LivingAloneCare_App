import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final User? user = FirebaseAuth.instance.currentUser;
  // 하단 탭 선택 시 호출되는 함수
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // TODO: 탭별 화면 이동 로직 (레시피, 등록, 커뮤니티, 마이페이지)
    if (index == 2) {
      print("재료 등록 카메라 실행!");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // 전체 배경색 (연한 회색)
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildTopSection(),

            const SizedBox(height: 20),

            _buildSectionTitle('유통기한 임박', onTap: () {}),
            _buildExpiringList(),

            const SizedBox(height: 20),

            _buildSectionTitle('최근 추가한 재료', onTap: () {}),
            _buildRecentList(),

            const SizedBox(height: 80),
          ],
        ),
      ),

      floatingActionButton: Container(
        width: 70,
        height: 90,
        margin: const EdgeInsets.only(top: 35),
        child: Column(
          children: [
            Container(
              width: 65,
              height: 65,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFE8C889), // 밝은 금색
                    Color(0xFFD2AC6E), // 어두운 금색
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD2AC6E).withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: FloatingActionButton(
                onPressed: () => _onItemTapped(2),
                backgroundColor: Colors.transparent,
                elevation: 0,
                shape: const CircleBorder(),
                child: const Icon(
                  Icons.camera_alt,
                  size: 28,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 4),

            const Text(
              '등록',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFA36A),
              ),
            ),
          ],
        ),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        elevation: 10,
        height: 70,
        padding: EdgeInsets.zero,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 1. 홈 (가장 왼쪽)
            _buildTabItem(
              index: 0,
              icon: Icons.home_outlined,
              activeIcon: Icons.home,
              label: '홈',
            ),

            const SizedBox(width: 45),

            _buildTabItem(
              index: 1,
              icon: Icons.menu_book_outlined,
              activeIcon: Icons.menu_book,
              label: '레시피',
            ),

            const SizedBox(width: 120),

            _buildTabItem(
              index: 3,
              icon: Icons.people_outline,
              activeIcon: Icons.people,
              label: '커뮤니티',
            ),

            const SizedBox(width: 45),

            _buildTabItem(
              index: 4,
              icon: Icons.person_outline,
              activeIcon: Icons.person,
              label: '마이',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSelected ? activeIcon : icon,
            color: isSelected ? const Color(0xFFFFA36A) : Colors.grey,
            size: 26,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFFFFA36A) : Colors.grey,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // --- 위젯 분리 메서드 ---

  // 1. 상단 그라데이션 및 요약 정보
  Widget _buildTopSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 30), // 상단 여백 확보
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFA36A), Color(0xFF99D279)], // 오렌지 -> 녹색
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 인사말 & 알림 아이콘
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '안녕하세요!',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '오늘은 뭐 먹을까요?', // 닉네임 연동 시: '${user?.displayName}님,\n오늘은...'
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.notifications,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          GestureDetector(
            onTap: () {
              // 탭 인덱스 2번(등록/카메라)으로 변경!
              _onItemTapped(2);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              // ... (기존 스타일 코드)
              child: const Row(
                // ... (기존 Row 코드)
              ),
            ),
          ),

          // 요약 카드 2개 (보유 재료, 이번 달 절약)
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  icon: Icons.kitchen,
                  title: '보유 재료',
                  value: '24개',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  icon: Icons.trending_down,
                  title: '이번 달 절약',
                  value: '32%',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 재료 스캔 버튼 (그라데이션 버튼 모양)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2), // 반투명 배경
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white30),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  '재료 스캔하고 레시피 추천받기',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 요약 카드 위젯
  Widget _buildSummaryCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // 섹션 타이틀 위젯 ("전체보기 >" 포함)
  Widget _buildSectionTitle(String title, {required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          GestureDetector(
            onTap: onTap,
            child: const Row(
              children: [
                Text(
                  '전체보기',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                Icon(Icons.chevron_right, size: 18, color: Colors.grey),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 2. 유통기한 임박 리스트 (세로 리스트)
  Widget _buildExpiringList() {
    // 💡 쿼리 수정: users -> UID -> inventory 접근
    final Query query = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('inventory')
        .orderBy('expiryDate'); // 오름차순 (임박한 것부터)

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text('데이터 로드 오류'));
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            alignment: Alignment.center,
            child: const Text(
              '냉장고가 비었어요!\n재료를 등록해보세요.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length > 3 ? 3 : docs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;

            String name = data['name'] ?? '알 수 없음';
            String category = data['category'] ?? '기타';

            // D-Day 계산
            String dDayText = '';
            Color tagColor = Colors.grey;
            Color textColor = Colors.black54;

            if (data['expiryDate'] != null) {
              final expiryDate = (data['expiryDate'] as Timestamp).toDate();
              final now = DateTime.now();
              final difference = DateTime(
                expiryDate.year,
                expiryDate.month,
                expiryDate.day,
              ).difference(DateTime(now.year, now.month, now.day)).inDays;

              if (difference < 0) {
                dDayText = '만료됨';
                tagColor = Colors.grey[300]!;
              } else if (difference == 0) {
                dDayText = 'D-Day';
                tagColor = const Color(0xFFFFEAEA);
                textColor = Colors.red;
              } else {
                dDayText = 'D-$difference';
                tagColor = difference <= 3
                    ? const Color(0xFFFFEAEA)
                    : Colors.grey[100]!;
                textColor = difference <= 3 ? Colors.red : Colors.black54;
              }
            }

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: IngredientImageHelper.getImage(name, category),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${data['storageLocation'] ?? '냉장'} · $category",
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (dDayText.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: tagColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        dDayText,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 3. 최근 추가한 재료 (수정된 쿼리)
  Widget _buildRecentList() {
    // 💡 참고: DB에 'registeredAt' 필드가 없다면 정렬이 안 될 수 있습니다.
    // 만약 없다면 .orderBy('expiryDate') 등을 사용하거나 필드를 추가해야 합니다.
    final Query query = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('inventory')
        // .orderBy('registeredAt', descending: true); // ⚠️ 이 필드가 DB에 있는지 확인 필요
        .orderBy('expiryDate', descending: true); // 임시로 소비기한 역순 사용

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final docs = snapshot.data!.docs;

        if (docs.isEmpty) return const SizedBox();

        return SizedBox(
          height: 140,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            scrollDirection: Axis.horizontal,
            itemCount: docs.length > 5 ? 5 : docs.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              String name = data['name'] ?? '알 수 없음';
              String category = data['category'] ?? '기타';

              return Column(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: IngredientImageHelper.getImage(name, category),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${data['quantity']}${data['unit']}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class IngredientImageHelper {
  static Widget getImage(String name, String category) {
    String? imagePath;

    // 자주 쓰는 식재료 매핑
    if (name.contains('우유'))
      imagePath = 'assets/images/milk.png';
    else if (name.contains('계란') || name.contains('달걀'))
      imagePath = 'assets/images/egg.png';
    else if (name.contains('양파'))
      imagePath = 'assets/images/onion.png';
    else if (name.contains('사과'))
      imagePath = 'assets/images/apple.png';
    else if (name.contains('당근'))
      imagePath = 'assets/images/carrot.png';
    else if (name.contains('대파') || name.contains('파'))
      imagePath = 'assets/images/green_onion.png';
    else if (name.contains('물'))
      imagePath = 'assets/images/water.png';
    else if (name.contains('김치'))
      imagePath = 'assets/images/kimchi.png';
    else if (name.contains('두부'))
      imagePath = 'assets/images/tofu.png';
    else if (name.contains('돼지') || name.contains('삼겹살'))
      imagePath = 'assets/images/pork.png';

    // 이미지가 있으면 반환
    if (imagePath != null) {
      return Image.asset(
        imagePath,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return _getCategoryIcon(category);
        },
      );
    }

    // 이미지가 없으면 카테고리 아이콘 반환
    return _getCategoryIcon(category);
  }

  static Widget _getCategoryIcon(String category) {
    switch (category) {
      case '유제품':
        return const Icon(
          Icons.local_drink,
          color: Colors.blueAccent,
          size: 30,
        );
      case '채소':
      case '야채':
        return const Icon(Icons.grass, color: Colors.green, size: 30);
      case '과일':
        return const Icon(Icons.apple, color: Colors.redAccent, size: 30);
      case '육류':
        return const Icon(Icons.set_meal, color: Colors.brown, size: 30);
      case '수산물':
        return const Icon(Icons.sailing, color: Colors.blue, size: 30);
      default:
        return const Icon(Icons.kitchen, color: Colors.grey, size: 30);
    }
  }
}
