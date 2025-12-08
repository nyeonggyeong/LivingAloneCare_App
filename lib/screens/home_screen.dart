import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:livingalonecare_app/screens/add_ingredient_screen.dart';
import 'package:livingalonecare_app/screens/inventory_screen.dart';
import 'package:livingalonecare_app/screens/recipe_recommendation_screen.dart';
import 'package:livingalonecare_app/screens/login_screen.dart';
import 'package:livingalonecare_app/data/ingredient_data.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _setupFCM();
  }

  Future<void> _setupFCM() async {
    if (user == null) return;
    final messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('🔔 알림 권한 허용됨');
      String? token = await messaging.getToken();
      if (token != null) {
        await FirebaseFirestore.instance.collection('users').doc(user!.uid).set(
          {'fcmToken': token, 'lastLogin': FieldValue.serverTimestamp()},
          SetOptions(merge: true),
        );
      }
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        ScaffoldMessenger.of(context).clearMaterialBanners();

        ScaffoldMessenger.of(context).showMaterialBanner(
          MaterialBanner(
            backgroundColor: Colors.white,
            elevation: 5,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),

            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFA36A).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_active_rounded,
                color: Color(0xFFFFA36A),
                size: 28,
              ),
            ),

            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.notification!.title ?? '알림',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message.notification!.body ?? '',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),

            actions: [
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
                },
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFFFA36A), // 버튼 글자색
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
                child: const Text('확인'),
              ),
            ],
          ),
        );

        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
          }
        });
      }
    });
  }

  // 로그아웃 함수
  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      print("로그아웃 오류: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('로그아웃 중 오류가 발생했습니다.')));
    }
  }

  Future<void> _deleteIngredient(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('inventory')
          .doc(docId)
          .delete();

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('재료가 삭제되었습니다 🗑️')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('삭제 중 오류 발생: $e')));
    }
  }

  void _showDeleteDialog(String docId, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("재료 삭제"),
        content: Text("'$name'을(를) 냉장고에서 뺄까요?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("취소", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteIngredient(docId);
            },
            child: const Text("삭제", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AddIngredientScreen()),
      );
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return const RecipeRecommendationScreen();
      case 3:
        return const Center(child: Text("커뮤니티 화면 (준비중)"));
      case 4:
        return const Center(child: Text("마이페이지 (준비중)"));
      default:
        return _buildHomeContent();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(body: Center(child: Text("로그인이 필요합니다.")));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: _buildBody(),

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
                  colors: [Color(0xFFE8C889), Color(0xFFD2AC6E)],
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

      // 하단 내비게이션 바
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        elevation: 10,
        height: 70,
        padding: EdgeInsets.zero,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildTopSection(),

          const SizedBox(height: 20),

          _buildSectionTitle(
            '유통기한 임박',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const InventoryScreen(
                    sortType: InventorySortType.expiryDate,
                  ),
                ),
              );
            },
          ),
          _buildExpiringList(),

          const SizedBox(height: 20),

          _buildSectionTitle(
            '최근 추가한 재료',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const InventoryScreen(
                    sortType: InventorySortType.registeredAt,
                  ),
                ),
              );
            },
          ),
          _buildRecentList(),

          const SizedBox(height: 80),
        ],
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

  Widget _buildTopSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    '오늘은 뭐 먹을까요?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              // 알림 아이콘 옆에 로그아웃 버튼 추가
              Row(
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.notifications,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  IconButton(
                    onPressed: _signOut, // 로그아웃 기능 연결
                    tooltip: "로그아웃",
                    icon: const Icon(
                      Icons.logout,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(user!.uid)
                      .collection('inventory')
                      .snapshots(),
                  builder: (context, snapshot) {
                    String countText = '...';
                    if (snapshot.hasData) {
                      countText = '${snapshot.data!.docs.length}개';
                    }
                    return _buildSummaryCard(
                      icon: Icons.kitchen,
                      title: '보유 재료',
                      value: countText,
                    );
                  },
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

          GestureDetector(
            onTap: () => _onItemTapped(2),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
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
          ),
        ],
      ),
    );
  }

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

  Widget _buildExpiringList() {
    final Query query = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('inventory')
        .orderBy('expiryDate'); // 오름차순

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

  // 최근 추가한 재료
  Widget _buildRecentList() {
    final Query query = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('inventory')
        .orderBy('registeredAt', descending: true);
    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const SizedBox();
        return SizedBox(
          height: 150,
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
                    width: 80,
                    height: 80,
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
                      padding: const EdgeInsets.all(14.0),
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
    String searchName = name.toLowerCase();
    String? imagePath;

    // IngredientData.imageMap을 순회하며 이미지 찾기
    for (var entry in IngredientData.imageMap.entries) {
      if (searchName.contains(entry.key)) {
        imagePath = entry.value;
        break;
      }
    }

    if (imagePath != null) {
      return Image.asset(
        imagePath,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return _getCategoryIcon(category);
        },
      );
    }
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
