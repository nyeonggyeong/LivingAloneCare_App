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
    int daysLeft = 100;
    if (data['expiryDate'] != null) {
      final expiryDate = (data['expiryDate'] as Timestamp).toDate();
      final now = DateTime.now();
      daysLeft = DateTime(
        expiryDate.year,
        expiryDate.month,
        expiryDate.day,
      ).difference(DateTime(now.year, now.month, now.day)).inDays;
    }

    // 2. 유통기한이 3일 이하 or 지남
    if (daysLeft <= 3) {
      bool? isConsumed = await showModalBottomSheet<bool>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text(
                  "유통기한 임박 🥕",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  "'${data['name']}'을(를)\n요리에 사용했나요?",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, color: Colors.black54),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFA36A),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "네! 먹었어요",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text(
                    "아니요, 그냥 버렸어요",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      );

      // 3. 처리 로직
      if (isConsumed == true && mounted) {
        // 먹음 -> 금액 입력 팝업 띄우기
        await _showPriceInputDialog(docId, data['name']);
      } else if (isConsumed == false) {
        // 그냥 버림 -> 바로 삭제 (이름 넘겨줌)
        await _deleteIngredient(docId, data['name']);
      }
    } else {
      // 4. 유통기한 넉넉하면 일반 삭제 확인
      _showDeleteConfirmDialog(docId, data['name']);
    }
  }

  // 가격 입력 팝업
  Future<void> _showPriceInputDialog(String docId, String name) async {
    final TextEditingController priceController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text(
                  "절약 금액 입력 💰",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  "'$name'으로 아낀 금액을 입력해주세요",
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    prefixText: "₩ ",
                    hintText: "예: 3000",
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    final int? amount = int.tryParse(
                      priceController.text.trim(),
                    );
                    if (amount != null && amount > 0) {
                      // 1. 절약 기록 저장
                      await _saveMoneyToDB(amount, "$name (냉파 성공!)");

                      // 2. 재료 삭제 (절약 알림이 뜰 것이므로 삭제 알림은 false)
                      await _deleteIngredient(docId, name, showMessage: false);

                      if (mounted) {
                        Navigator.pop(context);

                        // ✅ [수정됨] 삭제 알림과 동일한 스타일/위치 적용
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("$amount원 절약했어요 🎉"),
                            duration: const Duration(seconds: 2),
                            behavior:
                                SnackBarBehavior.floating, // 위치 동일하게 (떠있음)
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                10,
                              ), // 모양 동일하게
                            ),
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFA36A),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "저장하기",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
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
  Future<void> _deleteIngredient(
    String docId,
    String name, {
    bool showMessage = true,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('inventory')
          .doc(docId)
          .delete();

      // 화면이 여전히 존재하는지 확인 후 스낵바 표시
      if (mounted && showMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("'$name' 삭제 완료! 🗑️"),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("삭제 중 오류가 발생했습니다.")));
      }
    }
  }

  void _showDeleteConfirmDialog(String docId, String name) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                "'$name'을(를)\n냉장고에서 제거할까요? 🗑️",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // 삭제 실행 (이름 넘겨줌 -> 스낵바 뜸)
                  _deleteIngredient(docId, name);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFA36A),
                  minimumSize: const Size.fromHeight(48),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "삭제하기",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("취소", style: TextStyle(color: Colors.grey)),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

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
