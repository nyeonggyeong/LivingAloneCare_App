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
  List<dynamic> _recommendationList = [];
  List<dynamic> _popularList = [];

  bool _isLoading = true;
  String? _errorMessage;

  int _selectedTabIndex = 0;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchRecommendations();
  }

  Future<void> _fetchRecommendations() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted)
        setState(() {
          _isLoading = false;
          _errorMessage = "로그인이 필요합니다.";
        });
      return;
    }

    // 이미 데이터가 있으면 로딩 생략
    if (_recommendationList.isNotEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);

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
          _recommendationList = data['recommendations'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print("❌ Recommendation Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchPopularRecipes() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_popularList.isNotEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final inventorySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('inventory')
          .get();

      final myIngredients = inventorySnapshot.docs
          .map((doc) => doc.data()['name'].toString().trim())
          .toList();

      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('recipes')
          .orderBy('likeCount', descending: true)
          .limit(20)
          .get();

      List<dynamic> fetchedList = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;

        final List<dynamic> requiredIngredients =
            data['ingredients'] ?? data['requiredIngredients'] ?? [];

        List<String> missing = [];

        for (var req in requiredIngredients) {
          String reqName = '';
          if (req is Map) {
            reqName = (req['name'] ?? req['ingredientId'] ?? '').toString();
          } else {
            reqName = req.toString();
          }

          reqName = reqName.split('(').first.trim();

          if (reqName.isEmpty) continue;

          bool hasIt = myIngredients.any(
            (my) => my.contains(reqName) || reqName.contains(my),
          );

          if (!hasIt) {
            missing.add(reqName);
          }
        }

        data['missingIngredients'] = missing;
        data['matchingRate'] = missing.isEmpty
            ? 100
            : (100 - (missing.length * 10)).clamp(0, 90);

        return data;
      }).toList();

      if (mounted) {
        setState(() {
          _popularList = fetchedList;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("❌ Popular Recipe Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onTabChanged(int index) {
    if (_selectedTabIndex == index) return;

    setState(() {
      _selectedTabIndex = index;
      _isLoading = true;
    });

    if (index == 0) {
      _fetchRecommendations();
    } else {
      _fetchPopularRecipes();
    }
  }

  @override
  Widget build(BuildContext context) {
    // 현재 탭에 따라 보여줄 리스트 결정
    final currentList = _selectedTabIndex == 0
        ? _recommendationList
        : _popularList;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: Column(
        children: [
          _buildHeader(),
          _buildTabs(), // 탭 부분 수정됨
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFFA36A)),
                  )
                : _errorMessage != null
                ? Center(child: Text(_errorMessage!))
                : currentList.isEmpty
                ? _buildEmptyView()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    // 인기 레시피 탭일 때는 '더보기' 버튼 숨길지 결정 가능
                    itemCount:
                        currentList.length + (_selectedTabIndex == 0 ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == currentList.length) {
                        return _buildMoreButton();
                      }
                      return RecipeListCard(recipe: currentList[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ... _buildHeader() 코드는 기존과 동일 ...
  Widget _buildHeader() {
    // (기존 코드 그대로 사용)
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "보유 재료로 만들 수 있는",
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedTabIndex == 0
                            ? "AI 맞춤 추천 레시피"
                            : "지금 가장 핫한 레시피 🔥", // 탭에 따라 텍스트 변경
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _selectedTabIndex == 0
                            ? "보유 재료 90% 이상 활용 가능"
                            : "다른 사람들이 많이 저장했어요",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
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
                  child: Icon(
                    _selectedTabIndex == 0
                        ? Icons.restaurant_menu
                        : Icons.whatshot,
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

  // 💡 [수정된 부분] 탭 위젯 (클릭 기능 및 스타일 변경)
  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _onTabChanged(0), // 0번 탭 클릭
              child: _buildSingleTab("맞춤 추천", 0),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => _onTabChanged(1), // 1번 탭 클릭
              child: _buildSingleTab("인기 레시피", 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleTab(String title, int index) {
    final bool isActive = _selectedTabIndex == index;
    return Container(
      height: 48,
      decoration: BoxDecoration(
        gradient: isActive
            ? const LinearGradient(
                colors: [Color(0xFFFFA36A), Color(0xFF99D279)],
              )
            : null,
        color: isActive ? null : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: const Color(0xFF99D279).withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
        border: isActive ? null : Border.all(color: Colors.grey.shade300),
      ),
      child: Center(
        child: Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.black54,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
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
            _selectedTabIndex == 0
                ? "추천할 레시피를 찾지 못했어요 😭"
                : "아직 등록된 레시피가 없어요 😭",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500], fontSize: 16),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              setState(() => _isLoading = true);
              _selectedTabIndex == 0
                  ? _fetchRecommendations()
                  : _fetchPopularRecipes();
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

  String _calculateLevel(int count) {
    if (count >= 50) return "요리 마스터";
    if (count >= 30) return "고수 요리사";
    if (count >= 10) return "중수 요리사"; // 10개 이상이면 중수
    return "초보 요리사";
  }

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
    final myRecipeRef = userRef.collection('saved_recipes').doc(docId);

    final publicRecipeRef = FirebaseFirestore.instance
        .collection('recipes')
        .doc(docId);

    try {
      if (_isSaved) {
        await myRecipeRef.delete();

        try {
          await publicRecipeRef.update({
            'likeCount': FieldValue.increment(-1),
          }); // 카운트 감소
        } catch (e) {
          print("원본 레시피 카운트 감소 실패 (무시 가능): $e");
        }
      } else {
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
        await myRecipeRef.set(saveData);

        await publicRecipeRef.set({
          'name': widget.recipe['name'],
          'imageUrl': widget.recipe['imageUrl'],
          'cookingTime': widget.recipe['cookingTime'],
          'difficulty': widget.recipe['difficulty'],
          'likeCount': FieldValue.increment(1),

          'requiredIngredients':
              widget.recipe['requiredIngredients'] ??
              widget.recipe['ingredients'] ??
              [],
          'tags': widget.recipe['tags'] ?? [],
        }, SetOptions(merge: true));
      }

      final snapshot = await userRef.collection('saved_recipes').get();
      final int actualCount = snapshot.docs.length;
      final String newLevel = _calculateLevel(actualCount);

      await userRef.update({
        'savedRecipeCount': actualCount,
        'level': newLevel,
      });

      if (mounted) {
        setState(() {
          _isSaved = !_isSaved;
        });
        String message = _isSaved ? '나만의 레시피북에 저장되었어요! 🧡' : '저장이 취소되었습니다.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      print("저장 오류: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("오류가 발생했습니다: $e")));
      }
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
