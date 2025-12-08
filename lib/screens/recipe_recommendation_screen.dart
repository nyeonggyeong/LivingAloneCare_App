import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:livingalonecare_app/screens/recipe_detail_screen.dart';

class RecipeRecommendationScreen extends StatefulWidget {
  const RecipeRecommendationScreen({super.key});

  @override
  State<RecipeRecommendationScreen> createState() =>
      _RecipeRecommendationScreenState();
}

class _RecipeRecommendationScreenState
    extends State<RecipeRecommendationScreen> {
  List<dynamic> _recommendations = [];
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchRecommendations();
  }

  // Cloud Functions 호출
  Future<void> _fetchRecommendations() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "로그인이 필요합니다.";
        });
      }
      return;
    }

    try {
      final functions = FirebaseFunctions.instanceFor(
        region: 'asia-northeast3',
      );

      final HttpsCallable callable = functions.httpsCallable(
        'recommendRecipes',
      );

      final result = await callable.call();
      final data = Map<String, dynamic>.from(result.data as Map);

      if (mounted) {
        setState(() {
          _recommendations = data['recommendations'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print("❌ Error: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: Column(
        children: [
          _buildHeader(),
          _buildTabs(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFFA36A)),
                  )
                : _errorMessage != null
                ? Center(child: Text(_errorMessage!))
                : _recommendations.isEmpty
                ? _buildEmptyView()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    itemCount: _recommendations.length + 1,
                    itemBuilder: (context, index) {
                      if (index == _recommendations.length) {
                        return _buildMoreButton();
                      }
                      // 💡 RecipeListCard 위젯 사용
                      return RecipeListCard(recipe: _recommendations[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
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
          const Text(
            "냉파 레시피! 추천",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  offset: Offset(0, 1),
                  blurRadius: 2,
                  color: Colors.black12,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.white30),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "냉장고 파먹을 레시피 검색...",
                hintStyle: TextStyle(color: Colors.white70),
                prefixIcon: Icon(Icons.search, color: Colors.white70),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "보유 재료로 만들 수 있는",
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "200개 이상의 냉파 레시피",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        "보유 재료 90% 이상 활용 가능",
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.restaurant_menu,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFA36A), Color(0xFF99D279)],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF99D279).withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  "맞춤 추천",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Center(
                child: Text(
                  "인기 레시피",
                  style: TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoreButton() {
    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 30),
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: const Center(
        child: Text(
          "더 많은 레시피 보기",
          style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.kitchen, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "냉장고가 비어있거나\n추천할 레시피를 찾지 못했어요 😭",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500], fontSize: 16),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _fetchRecommendations();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFA36A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text("다시 시도", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// =======================================================
// 💡 [수정된 부분] 리스트 아이템 위젯 (개수 확인 후 등급 업데이트)
// =======================================================
class RecipeListCard extends StatefulWidget {
  final dynamic recipe;

  const RecipeListCard({super.key, required this.recipe});

  @override
  State<RecipeListCard> createState() => _RecipeListCardState();
}

class _RecipeListCardState extends State<RecipeListCard> {
  bool _isSaved = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _checkIfSaved();
  }

  // 💡 0. 등급 계산 로직 (기준에 따라 수정 가능)
  String _calculateLevel(int count) {
    if (count >= 50) return "요리 마스터";
    if (count >= 30) return "고수 요리사";
    if (count >= 10) return "중수 요리사"; // 10개 이상이면 중수
    return "초보 요리사";
  }

  // 1. 저장 여부 확인
  Future<void> _checkIfSaved() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final String docId = widget.recipe['id'] ?? widget.recipe['name'];

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('saved_recipes')
          .doc(docId)
          .get();

      if (mounted) {
        setState(() {
          _isSaved = doc.exists;
        });
      }
    } catch (e) {
      print("리스트 카드 확인 오류: $e");
    }
  }

  // 💡 2. 저장/삭제 및 등급 업데이트 (핵심!)
  Future<void> _toggleSave() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('로그인이 필요합니다.')));
      return;
    }

    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    final String docId = widget.recipe['id'] ?? widget.recipe['name'];
    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);
    final recipeRef = userRef.collection('saved_recipes').doc(docId);

    try {
      // (1) 저장 또는 삭제 동작 수행
      if (_isSaved) {
        await recipeRef.delete(); // 삭제
      } else {
        // 저장
        final saveData = {
          'id': docId,
          'name': widget.recipe['name'],
          'imageUrl': widget.recipe['imageUrl'],
          'cookingTime': widget.recipe['cookingTime'],
          'difficulty': widget.recipe['difficulty'],
          'savedAt': FieldValue.serverTimestamp(),
          'steps': widget.recipe['steps'],
          'requiredIngredients': widget.recipe['requiredIngredients'],
          'tags': widget.recipe['tags'],
        };
        await recipeRef.set(saveData);
      }

      // (2) ⭐️ 실제 저장된 개수를 DB에서 직접 세어옵니다. (가장 정확함)
      final snapshot = await userRef.collection('saved_recipes').get();
      final int actualCount = snapshot.docs.length;

      // (3) 개수에 따른 등급 계산
      final String newLevel = _calculateLevel(actualCount);

      // (4) 유저 정보(개수와 등급) 일괄 업데이트
      await userRef.update({
        'savedRecipeCount': actualCount,
        'level': newLevel,
      });

      // (5) UI 업데이트 및 메시지 표시
      if (mounted) {
        setState(() {
          _isSaved = !_isSaved; // 상태 반전
        });

        String message = _isSaved ? '나만의 레시피북에 저장되었어요! 🧡' : '저장이 취소되었습니다.';

        // 등급이 올랐을 때 축하 메시지 (선택 사항)
        // if (_isSaved && (actualCount == 10 || actualCount == 30 || actualCount == 50)) {
        //   message = '축하합니다! $newLevel(으)로 승급하셨어요! 🎉';
        // }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      print("저장 오류: $e");
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    final double matchingRate = (recipe['matchingRate'] as num).toDouble();
    final List<dynamic> missing = recipe['missingIngredients'] ?? [];
    final List<dynamic> tags = recipe['tags'] ?? [];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipeDetailScreen(
              recipeData: Map<String, dynamic>.from(recipe as Map),
            ),
          ),
        ).then((_) {
          _checkIfSaved(); // 상세 화면에서 돌아오면 상태 갱신
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    recipe['imageUrl'] ?? '',
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 100,
                        height: 100,
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.broken_image,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: matchingRate >= 100
                          ? const Color(0xFF99D279).withOpacity(0.9)
                          : const Color(0xFFFFA36A).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "${matchingRate.toInt()}% 매칭",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          recipe['name'] ?? '알 수 없음',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // 찜하기 버튼
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          _isSaved ? Icons.favorite : Icons.favorite_border,
                          size: 24,
                          color: _isSaved ? Colors.red : Colors.grey,
                        ),
                        onPressed: _toggleSave,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: tags
                        .take(2)
                        .map((tag) => _buildTag(tag.toString()))
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                  if (missing.isNotEmpty)
                    Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 14,
                          color: Color(0xFFFFA36A),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            "부족: ${missing.join(', ')}",
                            style: const TextStyle(
                              color: Color(0xFFFFA36A),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    )
                  else
                    const Text(
                      "바로 요리 가능해요! 👩‍🍳",
                      style: TextStyle(
                        color: Color(0xFF99D279),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "${recipe['cookingTime'] ?? 30}분",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.people_outline,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "${recipe['servings'] ?? 2}인분",
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
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFFFA36A),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
