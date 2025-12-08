import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class GoalHistoryScreen extends StatefulWidget {
  const GoalHistoryScreen({super.key});

  @override
  State<GoalHistoryScreen> createState() => _GoalHistoryScreenState();
}

class _GoalHistoryScreenState extends State<GoalHistoryScreen> {
  // 현재 선택된 날짜 (기본값: 오늘)
  DateTime _selectedDate = DateTime.now();

  // 월 이동 함수
  void _changeMonth(int offset) {
    setState(() {
      _selectedDate = DateTime(
        _selectedDate.year,
        _selectedDate.month + offset,
      );
    });
  }

  // 금액 포맷
  String _formatCurrency(int amount) {
    return NumberFormat('#,###').format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    // 선택된 달의 문서 ID (예: 2025-12)
    final String selectedDocId = DateFormat('yyyy-MM').format(_selectedDate);
    final String displayDate = DateFormat('yyyy년 MM월').format(_selectedDate);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text(
          "월별 목표 기록",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: user == null
          ? const Center(child: Text("로그인이 필요합니다."))
          : Column(
              children: [
                // ==========================================
                // 1. 상단: 월 선택 및 해당 월 상세 카드
                // ==========================================
                Container(
                  color: const Color(0xFFF9F9F9),
                  child: Column(
                    children: [
                      // 월 선택 네비게이션
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: () => _changeMonth(-1),
                              icon: const Icon(
                                Icons.chevron_left,
                                size: 30,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Text(
                              displayDate,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 20),
                            IconButton(
                              onPressed: () => _changeMonth(1),
                              icon: const Icon(
                                Icons.chevron_right,
                                size: 30,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 선택된 달의 데이터 스트림
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .collection('goals')
                            .doc(selectedDocId)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) return const Text("오류 발생");

                          // 데이터가 없을 때 (기록 없음)
                          if (!snapshot.hasData || !snapshot.data!.exists) {
                            return Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              padding: const EdgeInsets.all(30),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.history_toggle_off,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    "이 달의 목표 기록이 없어요.",
                                    style: TextStyle(color: Colors.grey[500]),
                                  ),
                                ],
                              ),
                            );
                          }

                          // 데이터가 있을 때 카드 표시
                          final data =
                              snapshot.data!.data() as Map<String, dynamic>;
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            child: _buildHistoryCard(
                              selectedDocId,
                              data,
                              isHighlighted: true,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),
                const Divider(thickness: 1, height: 1),

                // ==========================================
                // 2. 하단: 전체 기록 리스트 (모아보기)
                // ==========================================
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(24, 24, 24, 10),
                        child: Text(
                          "전체 기록 모아보기",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(user.uid)
                              .collection('goals')
                              .orderBy(
                                FieldPath.documentId,
                                descending: true,
                              ) // 최신순
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            final docs = snapshot.data?.docs ?? [];

                            if (docs.isEmpty) {
                              return const Center(child: Text("저장된 기록이 없습니다."));
                            }

                            return ListView.separated(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              itemCount: docs.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final doc = docs[index];
                                final data = doc.data() as Map<String, dynamic>;
                                return _buildHistoryCard(
                                  doc.id,
                                  data,
                                  isHighlighted: false,
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // 💡 공통으로 사용하는 카드 위젯
  Widget _buildHistoryCard(
    String docId,
    Map<String, dynamic> data, {
    bool isHighlighted = false,
  }) {
    final String title = data['title'] ?? '목표 없음';
    final int target = data['targetAmount'] ?? 0;
    final int saved = data['currentSaved'] ?? 0;

    // 달성률 계산
    double progress = 0.0;
    if (target > 0) progress = saved / target;
    if (progress > 1.0) progress = 1.0;
    final int percent = (progress * 100).toInt();
    final bool isSuccess = progress >= 1.0;

    // 하단 리스트용 날짜 포맷 (2025-12 -> 2025년 12월)
    String dateLabel = docId;
    try {
      DateTime dt = DateFormat('yyyy-MM').parse(docId);
      dateLabel = DateFormat('yyyy년 MM월').format(dt);
    } catch (e) {
      /* 포맷 에러 무시 */
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isHighlighted
            ? Border.all(
                color: const Color(0xFFFFA36A),
                width: 1.5,
              ) // 선택된 달은 테두리 강조
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 날짜 및 뱃지
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateLabel,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isHighlighted ? 18 : 16,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isSuccess
                      ? const Color(0xFF99D279).withOpacity(0.2)
                      : const Color(0xFFFFA36A).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isSuccess ? "성공! 🎉" : "${percent}% 달성",
                  style: TextStyle(
                    color: isSuccess
                        ? const Color(0xFF689F38)
                        : const Color(0xFFFFA36A),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 목표 제목
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),

          // 금액 정보
          Row(
            children: [
              Text(
                "${_formatCurrency(saved)}원",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                " / ${_formatCurrency(target)}원",
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 프로그레스 바
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                isSuccess ? const Color(0xFF99D279) : const Color(0xFFFFA36A),
              ),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}
