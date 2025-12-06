import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:livingalonecare_app/screens/home_screen.dart'; // 이미지 헬퍼 사용을 위해 import

enum InventorySortType { expiryDate, registeredAt }

class InventoryScreen extends StatelessWidget {
  final InventorySortType sortType;

  const InventoryScreen({
    super.key,
    this.sortType = InventorySortType.expiryDate,
  });

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null)
      return const Scaffold(body: Center(child: Text("로그인 필요")));

    String title = sortType == InventorySortType.expiryDate
        ? "유통기한 임박 재료"
        : "최근 추가한 재료";
    String orderByField = sortType == InventorySortType.expiryDate
        ? 'expiryDate'
        : 'registeredAt';
    bool descending =
        sortType == InventorySortType.registeredAt; // 최근 추가순은 내림차순

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('inventory')
            .orderBy(orderByField, descending: descending)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return const Center(child: Text('오류가 발생했습니다.'));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                '냉장고가 비어있어요!',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return _buildInventoryItem(data);
            },
          );
        },
      ),
    );
  }

  Widget _buildInventoryItem(Map<String, dynamic> data) {
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
              padding: const EdgeInsets.all(8.0),
              // HomeScreen에 있는 헬퍼 클래스 재사용
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
                  "${data['storageLocation'] ?? '냉장'} · $category · ${data['quantity']}${data['unit']}",
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
          if (dDayText.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
  }
}
