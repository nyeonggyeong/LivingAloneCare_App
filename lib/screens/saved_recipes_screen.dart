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
      builder: (context) => AlertDialog(
        title: const Text("저장 취소"),
        content: const Text("이 레시피를 저장 목록에서 삭제하시겠습니까?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("아니요", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                final userRef = FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid);

                // 1. 현재 정보 가져오기
                final userDoc = await userRef.get();
                int currentCount = userDoc.data()?['savedRecipeCount'] ?? 0;
                int newCount = currentCount > 0 ? currentCount - 1 : 0;
                String newLevel = _calculateLevel(newCount);

                // 2. 삭제 및 업데이트 수행
                await userRef.collection('saved_recipes').doc(docId).delete();

                await userRef.update({
                  'savedRecipeCount': newCount,
                  'level': newLevel, // 💡 등급 업데이트
                });
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("삭제", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
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
