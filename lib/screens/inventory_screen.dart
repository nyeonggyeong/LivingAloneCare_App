import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:livingalonecare_app/screens/home_screen.dart'; // IngredientImageHelper 사용

enum InventorySortType { expiryDate, registeredAt }

class InventoryScreen extends StatefulWidget {
  final InventorySortType sortType;

  const InventoryScreen({
    super.key,
    this.sortType = InventorySortType.expiryDate,
  });

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final User? user = FirebaseAuth.instance.currentUser;

  // ==========================================
  // 💡 유통기한 임박 체크 및 절약 금액 저장
  // ==========================================
  Future<void> _checkExpiryAndSaveMoney(
    String docId,
    Map<String, dynamic> data,
  ) async {
    if (user == null) return;

    // 1. 유통기한 남은 일수 계산
    int daysLeft = 100; // 기본값 넉넉하게
    if (data['expiryDate'] != null) {
      final expiryDate = (data['expiryDate'] as Timestamp).toDate();
      final now = DateTime.now();
      daysLeft = DateTime(
        expiryDate.year,
        expiryDate.month,
        expiryDate.day,
      ).difference(DateTime(now.year, now.month, now.day)).inDays;
    }

    // 2. 유통기한이 3일 이하로 남았거나 이미 지난 경우 (절약 기회!)
    if (daysLeft <= 3) {
      bool? isConsumed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          title: const Text("🗑️ 재료 정리"),
          content: Text(
            "'${data['name']}'의 유통기한이 얼마 안 남았네요.\n요리에 사용해서 식비를 아꼈나요?",
            style: const TextStyle(color: Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false), // 그냥 버림
              child: const Text("그냥 버림", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true), // 먹어서 아낌
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFA36A),
              ),
              child: const Text(
                "네! 먹었어요",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );

      // 3. 먹어서 아꼈다면 금액 입력 받기
      if (isConsumed == true && mounted) {
        await _showPriceInputDialog(docId, data['name']);
      } else if (isConsumed == false) {
        // 그냥 버림 -> 바로 삭제
        await _deleteIngredient(docId);
      }
      // null이면(팝업 밖 터치) 아무것도 안 함 (삭제 취소)
    } else {
      // 4. 유통기한이 넉넉하면 그냥 삭제 여부만 확인
      _showDeleteConfirmDialog(docId, data['name']);
    }
  }

  // 가격 입력 팝업
  Future<void> _showPriceInputDialog(String docId, String name) async {
    final TextEditingController priceController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text("💰 절약 금액 입력"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("'$name'의 대략적인 가격을 입력해주세요."),
            const SizedBox(height: 16),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: "금액 (원)",
                prefixText: "₩ ",
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFFFA36A)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("취소", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final int? amount = int.tryParse(priceController.text);
              if (amount != null && amount > 0) {
                // 1) 절약 내역 저장
                await _saveMoneyToDB(amount, "$name (냉파 성공!)");
                // 2) 재료 삭제
                await _deleteIngredient(docId);

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("$amount원 절약 성공! 대단해요 🎉")),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFA36A),
            ),
            child: const Text("저장 및 삭제", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 절약 내역 DB 저장 함수
  Future<void> _saveMoneyToDB(int amount, String description) async {
    final batch = FirebaseFirestore.instance.batch();
    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid);
    final historyRef = userRef.collection('saved_history').doc();

    batch.set(historyRef, {
      'amount': amount,
      'description': description,
      'date': FieldValue.serverTimestamp(),
    });

    batch.update(userRef, {
      'totalSavedAmount': FieldValue.increment(amount),
      'savedRecipeCount': FieldValue.increment(0), // 필요시 다른 카운트도 업데이트
    });

    await batch.commit();
  }

  // 재료 삭제 함수
  Future<void> _deleteIngredient(String docId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('inventory')
        .doc(docId)
        .delete();
  }

  // 일반 삭제 확인 (유통기한 넉넉할 때)
  void _showDeleteConfirmDialog(String docId, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text("재료 삭제"),
        content: Text("'$name'을(를) 냉장고에서 뺄까요?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("취소", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              _deleteIngredient(docId);
              Navigator.pop(context);
            },
            child: const Text("삭제", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // UI 빌드 부분
  // ==========================================

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(body: Center(child: Text("로그인 필요")));
    }

    String title = widget.sortType == InventorySortType.expiryDate
        ? "유통기한 임박 재료"
        : "최근 추가한 재료";
    String orderByField = widget.sortType == InventorySortType.expiryDate
        ? 'expiryDate'
        : 'registeredAt';

    bool descending = widget.sortType == InventorySortType.registeredAt;

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
            .doc(user!.uid)
            .collection('inventory')
            .orderBy(orderByField, descending: descending)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('오류가 발생했습니다.'));
          }
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
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              // 💡 Dismissible의 confirmDismiss를 사용하여 삭제 전 로직 수행
              return Dismissible(
                key: Key(doc.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  padding: const EdgeInsets.only(right: 20),
                  alignment: Alignment.centerRight,
                  decoration: BoxDecoration(
                    color: Colors.red[400],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                confirmDismiss: (direction) async {
                  // 💡 여기서 유통기한 체크 로직 실행!
                  await _checkExpiryAndSaveMoney(doc.id, data);
                  // Dismissible 자체가 사라지는 건 수동으로 처리했으므로 false 반환
                  // (DB에서 삭제되면 StreamBuilder가 알아서 화면 갱신함)
                  return false;
                },
                child: _buildInventoryItem(context, doc.id, data, user!.uid),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildInventoryItem(
    BuildContext context,
    String docId,
    Map<String, dynamic> data,
    String userId,
  ) {
    String name = data['name'] ?? '알 수 없음';
    String category = data['category'] ?? '기타';

    // D-Day 계산 로직
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
