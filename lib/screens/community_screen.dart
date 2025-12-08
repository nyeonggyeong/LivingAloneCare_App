import 'dart:io'; // 파일 처리를 위해 추가
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  int _selectedTabIndex = 0;

  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final List<String> _tags = [];
  bool _isUploading = false;

  XFile? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedTabIndex == 2) {
      return _buildWriteView();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildPostList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() => _selectedTabIndex = 2);
        },
        backgroundColor: const Color(0xFFFFA36A),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildWriteView() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () {
            setState(() {
              _selectedTabIndex = 0;
              _clearWriteData();
            });
          },
        ),
        title: const Text(
          '글 쓰기',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: _isUploading ? null : _savePost,
            child: _isUploading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    '완료',
                    style: TextStyle(
                      color: Color(0xFFFFA36A),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _contentController,
              maxLines: 8,
              decoration: const InputDecoration(
                hintText: '자취 꿀팁이나 요리 노하우를 공유해보세요!',
                border: InputBorder.none,
              ),
            ),
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagController,
                    decoration: const InputDecoration(
                      hintText: '태그 입력 (예: #자취)',
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.tag, size: 20),
                    ),
                    onSubmitted: (_) => _addTag(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Color(0xFF99D279)),
                  onPressed: _addTag,
                ),
              ],
            ),
            if (_tags.isNotEmpty)
              Wrap(
                spacing: 8,
                children: _tags
                    .map(
                      (tag) => Chip(
                        label: Text(tag),
                        backgroundColor: const Color(0xFFF0F9EB),
                        labelStyle: const TextStyle(
                          color: Color(0xFF99D279),
                          fontWeight: FontWeight.bold,
                        ),
                        onDeleted: () => setState(() => _tags.remove(tag)),
                      ),
                    )
                    .toList(),
              ),
            const SizedBox(height: 20),

            GestureDetector(
              onTap: _pickImage,
              child: _selectedImage != null
                  ? Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(_selectedImage!.path),
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          right: 8,
                          top: 8,
                          child: CircleAvatar(
                            backgroundColor: Colors.black54,
                            child: IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 20,
                              ),
                              onPressed: () =>
                                  setState(() => _selectedImage = null),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Container(
                      height: 100,
                      width: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, color: Colors.grey),
                          SizedBox(height: 4),
                          Text(
                            '사진 추가',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  Future<void> _savePost() async {
    if (_contentController.text.trim().isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('로그인이 필요합니다.')));
      return;
    }

    setState(() => _isUploading = true);

    try {
      String nickname = '익명';
      String profileImage = user.photoURL ?? '';

      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>;
          nickname = data['nickname'] ?? data['name'] ?? '익명';
          if (data['profileImage'] != null &&
              data['profileImage'].toString().isNotEmpty) {
            profileImage = data['profileImage'];
          }
        }
      } catch (e) {
        print('유저 정보 가져오기 실패: $e');
      }

      List<String> imageUrls = [];
      if (_selectedImage != null) {
        final storageRef = FirebaseStorage.instance.ref().child(
          'posts/${DateTime.now().millisecondsSinceEpoch}_${user.uid}.jpg',
        );

        await storageRef.putFile(File(_selectedImage!.path));
        final downloadUrl = await storageRef.getDownloadURL();
        imageUrls.add(downloadUrl);
      }

      await FirebaseFirestore.instance.collection('posts').add({
        'author': {
          'uid': user.uid,
          'nickname': nickname,
          'profileImage': profileImage,
        },
        'content': _contentController.text,
        'tags': _tags,
        'imageUrls': imageUrls,
        'likes': [], // 좋아요를 누른 사용자 UID 리스트 초기화
        'likeCount': 0,
        'commentCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      setState(() {
        _selectedTabIndex = 0;
        _clearWriteData();
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('에러 발생: $e')));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _addTag() {
    if (_tagController.text.isNotEmpty) {
      setState(() {
        _tags.add('#${_tagController.text.trim()}');
        _tagController.clear();
      });
    }
  }

  void _clearWriteData() {
    _contentController.clear();
    _tagController.clear();
    _tags.clear();
    _selectedImage = null; // 이미지 초기화
  }

  void _showCommentSheet(String postId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        // 키보드에 의해 위젯이 가려지지 않도록 Padding으로 감싸줌.
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 댓글 목록을 표시하는 부분
                Container(
                  // 화면 높이의 40%를 댓글 목록 공간으로 사용
                  height: MediaQuery.of(context).size.height * 0.4, 
                  child: _buildCommentList(postId),
                ),

                // 댓글 입력창
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: const InputDecoration(
                          hintText: '댓글을 입력하세요...',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send, color: Color(0xFFFFA36A)),
                      onPressed: () => _addComment(postId),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() {
      // BottomSheet가 닫힐 때 컨트롤러를 초기화
      _commentController.clear();
    });  
  }

  Widget _buildPostList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text("게시글이 없습니다."));

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          itemCount: docs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 20),
          itemBuilder: (context, index) {
            final doc = docs[index]; // DocumentSnapshot 객체 가져오기
            final data = doc.data() as Map<String, dynamic>;
            // doc.id를 두 번째 인자로 전달
            return _buildPostCard(data, doc.id);
          },
        );
      },
    );
  }

  // 함수 시그니처 수정: postId 인자 추가
  Widget _buildPostCard(Map<String, dynamic> post, String postId) {
    final user = FirebaseAuth.instance.currentUser;
    final author = post['author'] as Map<String, dynamic>? ?? {};
    final nickname = author['nickname'] ?? '익명';
    final profileImage = author['profileImage'] ?? '';
    final isAuthor = user?.uid == author['uid']; // 작성자 확인 로직

    String timeAgo = '';
    if (post['createdAt'] != null && post['createdAt'] is Timestamp) {
      timeAgo = _formatTimestamp(post['createdAt'] as Timestamp);
    }

    List<dynamic> imageUrls = post['imageUrls'] ?? [];
    String? firstImage = imageUrls.isNotEmpty ? imageUrls[0] : null;
    List<dynamic> tags = post['tags'] ?? [];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                // 게시물 상단: 사용자 정보 및 삭제/공유 메뉴
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: profileImage.isNotEmpty
                          ? NetworkImage(profileImage)
                          : null,
                      child: profileImage.isEmpty
                          ? const Icon(Icons.person, color: Colors.grey)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nickname,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        Text(
                          timeAgo,
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                      ],
                    ),
                    const Spacer(),

                    // 삭제 메뉴 또는 공유 아이콘 표시
                    if (isAuthor) 
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'delete') {
                            _confirmAndDeletePost(postId, post['imageUrls'] as List<dynamic>?); // 삭제 함수 호출
                          }
                        },
                        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                          const PopupMenuItem<String>(
                            value: 'delete',
                            child: Text('삭제하기', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                        icon: const Icon(Icons.more_vert, color: Colors.grey, size: 20),
                      )
                    else 
                      const Icon(Icons.share_outlined, color: Colors.grey, size: 20),
                  ],
                ),     
                // 게시물 상단 끝
          
          // 게시물 내용
          const SizedBox(height: 16), // 사용자 정보와 내용 사이 간격 추가
          Text(
            post['content'] ?? '',
            style: const TextStyle(fontSize: 15, height: 1.5),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),

          // 태그
          if (tags.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: tags
                  .map(
                    (tag) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F9EB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        tag.toString(),
                        style: const TextStyle(
                          color: Color(0xFF99D279),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),

          // 이미지
          if (firstImage != null) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 200,
                width: double.infinity,
                color: Colors.grey[100],
                child: Image.network(
                  firstImage,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),

          // 좋아요 / 댓글 카운트
          Row(
            children: [
              // 좋아요 버튼 (IconButton으로 변경)
              IconButton(
                padding: EdgeInsets.zero, // IconButton의 기본 패딩 제거
                constraints: const BoxConstraints(), // 크기 제약 조건 제거
                icon: Icon(
                  // post['likes']는 좋아요를 누른 사용자 UID 리스트
                  // 현재 로그인된 사용자(user?.uid)가 이 리스트에 포함되어 있는지 확인
                  post['likes'] != null && (post['likes'] as List).contains(user?.uid)
                    ? Icons.favorite // 좋아요를 누른 상태
                    : Icons.favorite_border, // 좋아요를 누르지 않은 상태
                  color: post['likes'] != null && (post['likes'] as List).contains(user?.uid)
                    ? Colors.redAccent // 누르면 빨간색
                    : Colors.grey[600], // 안 누르면 회색
                  size: 22,
                ),
                onPressed: () {
                  // user는 _buildPostCard 상단에서 FirebaseAuth.instance.currentUser로 가져온 변수
                  if (user == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('로그인이 필요합니다.')));
                    return;
                  }
                  // 좋아요 토글 함수 호출
                  _toggleLike(
                    postId,
                    post['likes'] as List<dynamic>? ?? [],
                  );
                },
              ),
              
              const SizedBox(width: 6),
              // 좋아요 카운트 (likes 리스트의 길이를 사용)
              Text(
                '${(post['likes'] as List<dynamic>? ?? []).length}',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(width: 20),
    
              // 댓글 버튼으로 변경
              IconButton(
                padding: EdgeInsets.zero, 
                constraints: const BoxConstraints(),
                icon: Icon(
                  Icons.chat_bubble_outline,
                  color: Colors.grey[600],
                  size: 20,
                ),
                onPressed: () {
                  // 댓글 버튼 클릭 시 BottomSheet 표시
                  _showCommentSheet(postId);
                },
              ),
              const SizedBox(width: 6),

              Text(
                '${post['commentCount'] ?? 0}',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
        ], 
      ),
    ); 
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    return DateFormat('yyyy.MM.dd').format(date);
  }

  Future<void> _confirmAndDeletePost(String postId, List<dynamic>? imageUrls) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('게시글 삭제'),
          content: const Text('정말로 이 게시글을 삭제하시겠습니까?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('삭제', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        // 1. Firestore 문서 삭제
        await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
        
        // 2. Storage 이미지 삭제 (Storage URL이 있는 경우)
        if (imageUrls != null && imageUrls.isNotEmpty) {
          for (var url in imageUrls) {
            await FirebaseStorage.instance.refFromURL(url.toString()).delete(); 
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('게시글이 삭제되었습니다.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('삭제 실패: $e')),
          );
        }
      }
    }
  }

  Future<void> _toggleLike(String postId, List<dynamic> currentLikes) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return; // 로그인 안 되어 있으면 중단

    final postRef = FirebaseFirestore.instance.collection('posts').doc(postId);
    final userId = user.uid;

    try {
      if (currentLikes.contains(userId)) {
        // 이미 좋아요를 눌렀다면: 좋아요 취소 (사용자 UID 제거)
        await postRef.update({
          'likes': FieldValue.arrayRemove([userId]),
          'likeCount': FieldValue.increment(-1),
        });
      } else {
        // 좋아요를 누르지 않았다면: 좋아요 추가 (사용자 UID 추가)
        await postRef.update({
          'likes': FieldValue.arrayUnion([userId]),
          'likeCount': FieldValue.increment(1),
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('좋아요 업데이트 실패: $e')),
        );
      }
    }
  }

  Future<void> _addComment(String postId) async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('로그인이 필요합니다.')));
      }
      return;
    }

    String nickname = '익명';
    String profileImage = user.photoURL ?? '';

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        nickname = data['nickname'] ?? data['name'] ?? '익명';
        if (data['profileImage'] != null && data['profileImage'].toString().isNotEmpty) {
          profileImage = data['profileImage'];
        }
      }
    } catch (e) {
      print('유저 정보 가져오기 실패: $e');
    }

    try {
      // 댓글 문서 추가 (Sub-collection)
      await FirebaseFirestore.instance
         .collection('posts')
          .doc(postId)
          .collection('comments')
          .add({
            'author': {
              'uid': user.uid,
              'nickname': nickname,
              'profileImage': profileImage,
            },
            'content': content,
            'createdAt': FieldValue.serverTimestamp(),
          });

      // 상위 게시글의 commentCount 필드 1 증가
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .update({'commentCount': FieldValue.increment(1)});
        
      if (mounted) {
        _commentController.clear();
        // 댓글 목록이 자동으로 업데이트되므로, UI 갱신은 StreamBuilder에 맡김.
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('댓글 작성 실패: $e')));
      }
    }
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
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
            '커뮤니티',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '요리 노하우를 공유해보세요',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              children: [_buildTabButton(0, "게시글"), _buildTabButton(1, "공동구매")],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String text) {
    final bool isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFFFFA36A), Color(0xFFD2AC6E)],
                  )
                : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCommentList(String postId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .orderBy('createdAt', descending: false) // 최신 댓글이 아래로 오도록 설정
          .snapshots(),
      builder: (context, snapshot) {
       if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data!.docs;
      
        if (docs.isEmpty) {
          return const Center(child: Text("첫 댓글을 달아주세요!", style: TextStyle(color: Colors.grey)));
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final comment = docs[index].data() as Map<String, dynamic>;
            return _buildCommentItem(comment);
          },
        );
      },
    );
  }

  // 개별 댓글 항목 위젯
  Widget _buildCommentItem(Map<String, dynamic> comment) {
    final author = comment['author'] as Map<String, dynamic>? ?? {};
    final nickname = author['nickname'] ?? '익명';
    final profileImage = author['profileImage'] ?? '';

    String timeAgo = '';
    if (comment['createdAt'] != null && comment['createdAt'] is Timestamp) {
      timeAgo = _formatTimestamp(comment['createdAt'] as Timestamp);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundImage: profileImage.isNotEmpty ? NetworkImage(profileImage) : null,
            child: profileImage.isEmpty ? const Icon(Icons.person, size: 16) : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      nickname,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeAgo,
                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(comment['content'] ?? '', style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
