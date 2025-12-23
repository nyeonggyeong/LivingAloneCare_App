import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:livingalonecare_app/screens/recipe_detail_screen.dart'; // 상세화면 경로 확인

class SavedRecipesScreen extends StatelessWidget {
  const SavedRecipesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "저장한 레시피",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: user == null
          ? const Center(child: Text("로그인이 필요합니다."))
          : StreamBuilder<QuerySnapshot>(
              // 💡 DB 경로: users -> uid -> saved_recipes 컬렉션을 구독
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('saved_recipes')
                  .orderBy(
                    'savedAt',
                    descending: true,
                  ) // 최신순 정렬 (저장할 때 savedAt 필드 필요)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFFA36A)),
                  );
                }

                if (snapshot.hasError) {
                  return Center(child: Text("오류가 발생했습니다: ${snapshot.error}"));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyView();
                }

                final docs = snapshot.data!.docs;

                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: docs.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    // 문서 ID도 함께 넘겨주면 삭제 시 유용함
                    final String docId = docs[index].id;

                    return _buildSavedRecipeCard(context, data, docId);
                  },
                );
              },
            ),
    );
  }

  Widget _buildSavedRecipeCard(
    BuildContext context,
    Map<String, dynamic> recipe,
    String docId,
  ) {
    return GestureDetector(
      onTap: () {
        // 상세 화면으로 이동
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipeDetailScreen(
              recipeData: recipe, // 저장된 레시피 데이터를 상세 화면으로 전달
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
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
        child: Row(
          children: [
            // 레시피 이미지
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                recipe['imageUrl'] ?? '',
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[200],
                    child: const Icon(Icons.restaurant, color: Colors.grey),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            // 레시피 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe['name'] ?? '이름 없는 레시피',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // 태그나 간단 정보 표시
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "${recipe['cookingTime'] ?? 0}분",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.whatshot, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        recipe['difficulty'] ?? '보통',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // 삭제 버튼 (선택 사항)
            IconButton(
              icon: const Icon(
                Icons.bookmark,
                color: Color(0xFFFFA36A),
              ), // 꽉 찬 북마크 아이콘
              onPressed: () {
                // 여기서 바로 삭제 로직을 구현하거나, 상세 페이지에서 해제하도록 유도
                _showUnsaveDialog(context, docId);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _calculateLevel(int count) {
    if (count >= 50) return "요리 마스터";
    if (count >= 30) return "고수 요리사";
    if (count >= 10) return "중수 요리사";
    return "초보 요리사";
  }

  void _showUnsaveDialog(BuildContext context, String docId) {
    showDialog(
      context: context,
      barrierDismissible: true, // 바깥 터치 시 닫힘
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), // 둥근 모서리
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. 아이콘 및 제목
                const Icon(
                  Icons.bookmark_remove,
                  size: 40,
                  color: Color(0xFFFFA36A), // 오렌지색 아이콘
                ),
                const SizedBox(height: 16),
                const Text(
                  "저장을 취소할까요?",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "나만의 레시피북에서\n이 레시피가 삭제됩니다.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),

                // 2. 버튼 영역 (취소 / 삭제)
                Row(
                  children: [
                    // 취소 버튼
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: Colors.grey[100],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "취소",
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // 삭제 버튼
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          // 다이얼로그 먼저 닫기
                          Navigator.pop(context);

                          // 삭제 로직 실행
                          await _processUnsave(context, docId);
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: const Color(0xFFFFA36A), // 오렌지색 배경
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "삭제",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _processUnsave(BuildContext context, String docId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);

      // 1. 현재 정보 가져오기 & 카운트 감소
      final userDoc = await userRef.get();
      int currentCount = userDoc.data()?['savedRecipeCount'] ?? 0;
      int newCount = currentCount > 0 ? currentCount - 1 : 0;
      String newLevel = _calculateLevel(newCount);

      // 2. DB 삭제 및 업데이트
      await userRef.collection('saved_recipes').doc(docId).delete();
      await userRef.update({'savedRecipeCount': newCount, 'level': newLevel});

      // 3. 알림 띄우기 (전달받은 context 사용)
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.delete_outline, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  "삭제가 완료되었습니다.",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFFFA36A).withOpacity(0.95),
            behavior: SnackBarBehavior.floating,
            elevation: 0,
            shape: const StadiumBorder(),
            margin: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print("삭제 오류: $e");
    }
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bookmark_border, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "아직 저장한 레시피가 없어요.",
            style: TextStyle(color: Colors.grey[500], fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            "마음에 드는 레시피를 저장해보세요!",
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
