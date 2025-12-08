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
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            // doc.id를 두 번째 인자로 전달
            return _buildPostCard(data, doc.id);
          },
        );
      },
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post, String postId) {
    final user = FirebaseAuth.instance.currentUser;
    final author = post['author'] as Map<String, dynamic>? ?? {};
    final nickname = author['nickname'] ?? '익명';
    final profileImage = author['profileImage'] ?? '';
    final isAuthor = user?.uid == author['uid'];

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
          _buildUserInfo(nickname, profileImage, timeAgo),
          const SizedBox(height: 16),
          Text(
            post['content'] ?? '',
            style: const TextStyle(fontSize: 15, height: 1.5),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
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
          Row(
            children: [
              Icon(Icons.favorite_border, color: Colors.grey[600], size: 22),
              const SizedBox(width: 6),
              Text(
                '${post['likeCount'] ?? 0}',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(width: 20),
              Icon(
                Icons.chat_bubble_outline,
                color: Colors.grey[600],
                size: 20,
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

  Widget _buildUserInfo(String nickname, String profileImage, String timeAgo) {
    return Row(
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
        const Icon(Icons.share_outlined, color: Colors.grey, size: 20),
      ],
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
}
