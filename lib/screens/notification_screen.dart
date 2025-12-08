import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:livingalonecare_app/screens/inventory_screen.dart'; // 💡 냉장고 화면 import
import 'package:livingalonecare_app/screens/recipe_detail_screen.dart'; // 💡 레시피 상세 화면 import

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final User? user = FirebaseAuth.instance.currentUser;

  // 1. 알림 삭제 함수
  Future<void> _deleteNotification(String docId) async {
    if (user == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('notifications')
        .doc(docId)
        .delete();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('알림이 삭제되었습니다.'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  // 2. 알림 클릭 처리 (읽음 처리 + 이동)
  Future<void> _onNotificationTap(
    String docId,
    Map<String, dynamic> data,
  ) async {
    if (user == null) return;

    // (1) 읽음 처리: DB 업데이트
    if (data['isRead'] == false) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('notifications')
          .doc(docId)
          .update({'isRead': true});
    }

    if (!mounted) return;

    // (2) 화면 이동 로직
    // 🚨 주의: DB에 'route' 필드가 있어야 작동합니다!
    final String route = data['route'] ?? '';
    final String targetId = data['targetId'] ?? '';

    if (route == 'inventory') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const InventoryScreen(
            sortType: InventorySortType.expiryDate, // 유통기한 임박 순서로 열기
          ),
        ),
      );
    } else if (route == 'recipe' && targetId.isNotEmpty) {
      _navigateToRecipe(targetId);
    } else if (route == 'community') {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('커뮤니티 이동 기능은 준비 중입니다.')));
    } else {
      // route 정보가 없을 때
      print("이동할 경로(route)가 없습니다: $data");
    }
  }

  // 레시피 데이터 가져오기 및 이동 (Helper)
  Future<void> _navigateToRecipe(String recipeId) async {
    try {
      // 저장된 레시피 목록에서 찾기 (또는 전체 레시피 컬렉션에서 찾기)
      // 예시: saved_recipes에서 조회
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('saved_recipes')
          .doc(recipeId)
          .get();

      if (doc.exists && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipeDetailScreen(
              recipeData: doc.data() as Map<String, dynamic>,
            ),
          ),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('삭제되었거나 존재하지 않는 레시피입니다.')),
          );
        }
      }
    } catch (e) {
      print("이동 오류: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          '알림 센터',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: user == null
          ? const Center(child: Text("로그인이 필요합니다."))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user!.uid)
                  .collection('notifications')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_off_outlined,
                          size: 60,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "새로운 알림이 없어요",
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final bool isRead = data['isRead'] ?? false;

                    String timeAgo = '';
                    if (data['createdAt'] != null) {
                      final date = (data['createdAt'] as Timestamp).toDate();
                      timeAgo = DateFormat('MM.dd HH:mm').format(date);
                    }

                    // 3. Dismissible: 밀어서 삭제 기능
                    return Dismissible(
                      key: Key(doc.id), // 고유 키 필수
                      direction: DismissDirection.endToStart, // 오른쪽->왼쪽
                      onDismissed: (direction) {
                        _deleteNotification(doc.id);
                      },
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      child: GestureDetector(
                        onTap: () => _onNotificationTap(doc.id, data),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            // 안 읽음: 연한 주황색, 읽음: 흰색
                            color: isRead
                                ? Colors.white
                                : const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Stack(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFFFFA36A,
                                      ).withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.notifications_active_rounded,
                                      color: Color(0xFFFFA36A),
                                      size: 24,
                                    ),
                                  ),
                                  if (!isRead)
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          data['title'] ?? '알림',
                                          style: TextStyle(
                                            fontWeight: isRead
                                                ? FontWeight.normal
                                                : FontWeight.bold,
                                            fontSize: 15,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        Text(
                                          timeAgo,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[400],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      data['body'] ?? '',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isRead
                                            ? Colors.grey[600]
                                            : Colors.black87,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
