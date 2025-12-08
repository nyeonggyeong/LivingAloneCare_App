import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class SavedMoneyScreen extends StatefulWidget {
  const SavedMoneyScreen({super.key});

  @override
  State<SavedMoneyScreen> createState() => _SavedMoneyScreenState();
}

class _SavedMoneyScreenState extends State<SavedMoneyScreen> {
  final User? user = FirebaseAuth.instance.currentUser;

  // 금액 포맷 (예: 1,000)
  String _formatCurrency(int amount) {
    return NumberFormat('#,###').format(amount);
  }

  // 💡 시스템(냉파) 기록인지 확인하는 함수
  bool _isSystemRecord(String description) {
    return description.contains('(냉파 성공!)');
  }

  // ==========================================
  // 1. 추가/수정 다이얼로그
  // ==========================================
  void _showAddOrEditDialog({DocumentSnapshot? doc}) {
    final bool isEditMode = doc != null;
    final TextEditingController amountController = TextEditingController();
    final TextEditingController descController = TextEditingController();

    if (isEditMode) {
      final data = doc.data() as Map<String, dynamic>;
      amountController.text = (data['amount'] ?? 0).toString();
      descController.text = data['description'] ?? '';
    }

    showDialog(
      context: context,
      builder: (context) {
        return LayoutBuilder(
          builder: (context, constraints) {
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              insetPadding: const EdgeInsets.symmetric(horizontal: 20),
              contentPadding: const EdgeInsets.all(24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditMode ? "내역 수정" : "절약 금액 추가",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (isEditMode)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteRecord(
                          doc.id,
                          (doc.data() as Map<String, dynamic>)['amount'],
                        );
                      },
                      tooltip: "삭제하기",
                    ),
                ],
              ),
              content: SizedBox(
                width: constraints.maxWidth,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "금액 (원)",
                        prefixText: "₩ ",
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFFFA36A)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(
                        labelText: "내용 (예: 배달 대신 집밥)",
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
                    final int? amount = int.tryParse(amountController.text);
                    final String desc = descController.text.trim();

                    if (amount != null && amount > 0 && desc.isNotEmpty) {
                      if (isEditMode) {
                        await _updateRecord(doc, amount, desc);
                      } else {
                        await _addSavedRecord(amount, desc);
                      }
                      if (mounted) Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFA36A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: Text(
                    isEditMode ? "수정" : "추가",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
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
  // 2. 데이터베이스 로직
  // ==========================================

  Future<void> _addSavedRecord(int amount, String description) async {
    if (user == null) return;
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
    batch.update(userRef, {'totalSavedAmount': FieldValue.increment(amount)});
    await batch.commit();
  }

  Future<void> _updateRecord(
    DocumentSnapshot doc,
    int newAmount,
    String newDesc,
  ) async {
    if (user == null) return;
    final oldData = doc.data() as Map<String, dynamic>;
    final int oldAmount = oldData['amount'] ?? 0;
    final int difference = newAmount - oldAmount;

    final batch = FirebaseFirestore.instance.batch();
    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid);

    batch.update(doc.reference, {'amount': newAmount, 'description': newDesc});

    if (difference != 0) {
      batch.update(userRef, {
        'totalSavedAmount': FieldValue.increment(difference),
      });
    }
    await batch.commit();
    if (mounted)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('수정되었습니다.')));
  }

  Future<void> _deleteRecord(String docId, int amount) async {
    if (user == null) return;
    final batch = FirebaseFirestore.instance.batch();
    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid);
    final historyRef = userRef.collection('saved_history').doc(docId);

    batch.delete(historyRef);
    batch.update(userRef, {'totalSavedAmount': FieldValue.increment(-amount)});
    await batch.commit();
    if (mounted)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('삭제되었습니다.')));
  }

  // ==========================================
  // 3. UI 화면 구성
  // ==========================================
  @override
  Widget build(BuildContext context) {
    if (user == null)
      return const Scaffold(body: Center(child: Text("로그인 필요")));

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text(
          "절약한 금액",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // 상단 총액 표시
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user!.uid)
                .snapshots(),
            builder: (context, snapshot) {
              int total = 0;
              if (snapshot.hasData && snapshot.data!.exists) {
                total =
                    (snapshot.data!.data()
                        as Map<String, dynamic>)['totalSavedAmount'] ??
                    0;
              }
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(30),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      "지금까지 아낀 식비",
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${_formatCurrency(total)}원",
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFA36A),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // 리스트
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user!.uid)
                  .collection('saved_history')
                  .orderBy('date', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "아직 기록이 없어요.\n오늘 절약한 금액을 추가해보세요!",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: docs.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final int amount = data['amount'] ?? 0;
                    final String desc = data['description'] ?? '절약';

                    final String dateStr = data['date'] != null
                        ? DateFormat(
                            'MM.dd',
                          ).format((data['date'] as Timestamp).toDate())
                        : '-';

                    // 💡 시스템 기록(냉파 성공) 여부 확인
                    final bool isSystem = _isSystemRecord(desc);

                    // 색상 설정 (시스템: 파랑 / 수동: 초록)
                    final Color iconColor = isSystem
                        ? Colors.blue
                        : const Color(0xFF4CAF50);
                    final Color iconBgColor = isSystem
                        ? Colors.blue.withOpacity(0.1)
                        : const Color(0xFFE8F5E9);
                    final IconData iconData = isSystem
                        ? Icons.kitchen
                        : Icons.savings; // 아이콘 구분

                    // 💡 리스트 아이템 UI
                    Widget listItem = Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
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
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: iconBgColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(iconData, color: iconColor),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  desc,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  dateStr,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            "+${_formatCurrency(amount)}원",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: iconColor,
                            ),
                          ),
                        ],
                      ),
                    );

                    // 💡 클릭(수정) 제한 로직
                    Widget tappableItem = GestureDetector(
                      onTap: () {
                        if (isSystem) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('냉파 성공 내역은 수정할 수 없습니다.'),
                            ),
                          );
                        } else {
                          _showAddOrEditDialog(doc: doc);
                        }
                      },
                      child: listItem,
                    );

                    // 💡 삭제(Swipe) 제한 로직
                    if (isSystem) {
                      // 시스템 기록은 Dismissible 없이 바로 반환 (삭제 불가)
                      return tappableItem;
                    } else {
                      // 수동 기록만 Dismissible 적용
                      return Dismissible(
                        key: Key(doc.id),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => _deleteRecord(doc.id, amount),
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: Colors.red[100],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.delete, color: Colors.red),
                        ),
                        child: tappableItem,
                      );
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOrEditDialog(),
        backgroundColor: const Color(0xFFFFA36A),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
