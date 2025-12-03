import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // 현재 선택된 내비게이션 인덱스

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
    // 더미 데이터
    final List<Map<String, dynamic>> expiringItems = [
      {'name': '우유', 'category': '유제품', 'dDay': 'D-2', 'color': Colors.red},
      {'name': '계란', 'category': '계란/알류', 'dDay': 'D-3', 'color': Colors.grey},
      {'name': '당근', 'category': '채소', 'dDay': 'D-5', 'color': Colors.grey},
    ];

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shrinkWrap: true, // ScrollView 안에 ListView 넣을 때 필수
      physics: const NeverScrollableScrollPhysics(), // 스크롤 막기 (전체 스크롤 사용)
      itemCount: expiringItems.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = expiringItems[index];
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
              // 이미지 대신 아이콘/색상 박스
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.image,
                  color: Colors.grey,
                ), // TODO: 실제 이미지로 교체
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['category'],
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              // D-Day 태그
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: item['color'] == Colors.red
                      ? const Color(0xFFFFEAEA)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  item['dDay'],
                  style: TextStyle(
                    color: item['color'] == Colors.red
                        ? Colors.red
                        : Colors.grey,
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
  }

  // 3. 최근 추가한 재료 (가로 스크롤)
  Widget _buildRecentList() {
    final List<Map<String, String>> recentItems = [
      {'name': '양파', 'count': '3개'},
      {'name': '감자', 'count': '5개'},
      {'name': '애호박', 'count': '2개'},
      {'name': '대파', 'count': '1단'},
      {'name': '마늘', 'count': '1봉'},
    ];

    return SizedBox(
      height: 140, // 가로 스크롤 영역 높이
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        scrollDirection: Axis.horizontal,
        itemCount: recentItems.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final item = recentItems[index];
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
                child: const Icon(
                  Icons.kitchen,
                  color: Colors.orangeAccent,
                ), // TODO: 이미지 교체
              ),
              const SizedBox(height: 8),
              Text(
                item['name']!,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                item['count']!,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          );
        },
      ),
    );
  }
}
