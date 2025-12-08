import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 💡 추가
import 'package:cloud_firestore/cloud_firestore.dart'; // 💡 추가

class RecipeDetailScreen extends StatefulWidget {
  final Map<String, dynamic> recipeData;

  const RecipeDetailScreen({super.key, required this.recipeData});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  bool _isSearchingVideo = false;
  bool _isSaved = false; // 💡 저장 상태 변수
  bool _isProcessing = false; // 💡 중복 클릭 방지용

  @override
  void initState() {
    super.initState();
    _checkIfSaved(); // 💡 화면 진입 시 저장 여부 확인
  }

  // 💡 1. 이미 저장된 레시피인지 확인하는 함수
  Future<void> _checkIfSaved() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // 레시피 ID가 있다면 그것을 사용하고, 없다면 이름으로 대체 (고유 ID 사용 권장)
    final String docId = widget.recipeData['id'] ?? widget.recipeData['name'];

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
      print("저장 확인 오류: $e");
    }
  }

  String _calculateLevel(int count) {
    if (count >= 50) return "요리 마스터";
    if (count >= 30) return "고수 요리사";
    if (count >= 10) return "중수 요리사";
    return "초보 요리사";
  }

  // 💡 수정된 _toggleSave 함수
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

    final String docId = widget.recipeData['id'] ?? widget.recipeData['name'];
    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);
    final recipeRef = userRef.collection('saved_recipes').doc(docId);

    try {
      // 1. 현재 유저 정보 가져오기 (현재 저장 개수를 알기 위해)
      final userDoc = await userRef.get();
      int currentCount = userDoc.data()?['savedRecipeCount'] ?? 0;

      if (_isSaved) {
        // ❌ 삭제 로직
        await recipeRef.delete();

        // 개수 감소 및 등급 재계산
        int newCount = currentCount > 0 ? currentCount - 1 : 0;
        String newLevel = _calculateLevel(newCount);

        await userRef.update({
          'savedRecipeCount': newCount,
          'level': newLevel, // 💡 등급 업데이트!
        });

        if (mounted) {
          setState(() => _isSaved = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('저장이 취소되었습니다.')));
        }
      } else {
        // ⭕ 저장 로직
        final saveData = {
          'id': docId,
          'name': widget.recipeData['name'],
          'imageUrl': widget.recipeData['imageUrl'],
          'cookingTime': widget.recipeData['cookingTime'],
          'difficulty': widget.recipeData['difficulty'],
          'savedAt': FieldValue.serverTimestamp(),
          // 필요 데이터 추가...
        };

        await recipeRef.set(saveData);

        // 개수 증가 및 등급 재계산
        int newCount = currentCount + 1;
        String newLevel = _calculateLevel(newCount);

        await userRef.update({
          'savedRecipeCount': newCount,
          'level': newLevel, // 💡 등급 업데이트!
        });

        if (mounted) {
          setState(() => _isSaved = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('나만의 레시피북에 저장되었어요! 🧡'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      print("저장 토글 오류: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('오류가 발생했습니다.')));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _openYoutube() async {
    setState(() => _isSearchingVideo = true);
    try {
      final functions = FirebaseFunctions.instanceFor(
        region: 'asia-northeast3',
      );
      final callable = functions.httpsCallable('searchRecipeVideos');
      final result = await callable.call({
        'recipeName': widget.recipeData['name'],
      });
      final urlString = result.data['youtubeSearchUrl'] as String;
      final url = Uri.parse(urlString);

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      print("유튜브 검색 오류: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('영상을 찾아낼 수 없어요 😭')));
      }
    } finally {
      if (mounted) setState(() => _isSearchingVideo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipeData;
    final steps = (recipe['steps'] as List<dynamic>?) ?? [];
    final ingredients = (recipe['requiredIngredients'] as List<dynamic>?) ?? [];
    final tags = (recipe['tags'] as List<dynamic>?) ?? [];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300.0,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFFFFA36A),

            // 💡 3. 하트 아이콘 버튼 추가 (AppBar actions)
            actions: [
              IconButton(
                icon: Icon(
                  _isSaved ? Icons.favorite : Icons.favorite_border,
                  color: _isSaved ? Colors.red : Colors.white,
                  size: 28, // 아이콘 크기 약간 키움
                ),
                onPressed: _toggleSave, // 클릭 시 토글 함수 실행
              ),
              const SizedBox(width: 8), // 우측 여백
            ],

            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                recipe['name'] ?? '레시피 상세',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 1),
                      blurRadius: 2,
                      color: Colors.black45,
                    ),
                  ],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    recipe['imageUrl'] ?? '',
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.broken_image,
                        size: 50,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black54],
                        stops: [0.7, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.timer_outlined,
                        size: 20,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "${recipe['cookingTime'] ?? 30}분",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.whatshot, size: 20, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        "${recipe['difficulty'] ?? '보통'}",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: _isSearchingVideo ? null : _openYoutube,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        icon: _isSearchingVideo
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.play_arrow, size: 20),
                        label: Text(_isSearchingVideo ? "검색중..." : "영상 보기"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: tags.map((tag) {
                      return Chip(
                        label: Text('#$tag'),
                        backgroundColor: const Color(0xFFFFF3E0),
                        labelStyle: const TextStyle(
                          color: Color(0xFFFFA36A),
                          fontWeight: FontWeight.bold,
                        ),
                        side: BorderSide.none,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    "필요한 재료",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F9F9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: ingredients.isEmpty
                          ? [
                              const Text(
                                "재료 정보가 없습니다.",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ]
                          : ingredients.map((ing) {
                              String name = "";
                              String quantity = "";
                              if (ing is String) {
                                name = ing;
                              } else if (ing is Map) {
                                name = ing['name'] ?? ing['ingredientId'] ?? '';
                                quantity = ing['quantityText'] ?? '';
                                if (quantity.isEmpty &&
                                    ing['quantity'] != null) {
                                  quantity =
                                      "${ing['quantity']}${ing['unit'] ?? ''}";
                                }
                              }
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      quantity,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFFFA36A),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    "조리 순서",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ListView.separated(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: steps.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 24),
                    itemBuilder: (context, index) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: Color(0xFF99D279),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              "${index + 1}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              steps[index].toString(),
                              style: const TextStyle(
                                fontSize: 16,
                                height: 1.6,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
