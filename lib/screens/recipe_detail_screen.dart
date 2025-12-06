import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:url_launcher/url_launcher.dart'; // URL 열기 패키지

class RecipeDetailScreen extends StatefulWidget {
  final Map<String, dynamic> recipeData;

  const RecipeDetailScreen({super.key, required this.recipeData});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  bool _isSearchingVideo = false; // 유튜브 검색 로딩 상태

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

                  // 태그
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
                      color: const Color(0xFFF9F9F9), // 연한 회색 박스
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
                              // 데이터 파싱 로직 (Map 또는 String 처리)
                              String name = "";
                              String quantity = "";
                              if (ing is String) {
                                name = ing;
                              } else if (ing is Map) {
                                name = ing['name'] ?? ing['ingredientId'] ?? '';
                                quantity = ing['quantityText'] ?? '';
                                // quantityText가 없으면 숫자와 단위를 합쳐서 표시
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
                                        color: Color(0xFFFFA36A), // 오렌지색 강조
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
                    shrinkWrap: true, // ScrollView 안에서 ListView 사용 시 필수
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: steps.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 24),
                    itemBuilder: (context, index) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 순서 번호 (초록색 원)
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
                          // 설명 텍스트
                          Expanded(
                            child: Text(
                              steps[index].toString(),
                              style: const TextStyle(
                                fontSize: 16,
                                height: 1.6, // 줄간격 조절로 가독성 확보
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
