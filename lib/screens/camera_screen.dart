import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_functions/cloud_functions.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  File? _image;
  bool _isAnalyzing = false;
  List<String> _detectedItems = [];
  final ImagePicker _picker = ImagePicker();

  // 카메라/갤러리에서 사진 가져오기
  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _detectedItems = [];
      });
      _analyzeImage(File(pickedFile.path));
    }
  }

  // Cloud Functions로 이미지 전송 및 분석 요청
  Future<void> _analyzeImage(File imageFile) async {
    setState(() {
      _isAnalyzing = true;
    });

    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Functions 호출
      final functions = FirebaseFunctions.instanceFor(
        region: 'asia-northeast3',
      );
      final callable = functions.httpsCallable('analyzeImage');

      final result = await callable.call({'image': base64Image});

      final data = result.data as Map<String, dynamic>;
      final items = List<String>.from(data['items'] ?? []);

      setState(() {
        _detectedItems = items;
      });
    } catch (e) {
      print('에러 발생: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('분석 실패: $e')));
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('재료 촬영')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // 이미지 표시 영역
            Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey),
              ),
              child: _image == null
                  ? const Center(
                      child: Icon(
                        Icons.camera_alt,
                        size: 50,
                        color: Colors.grey,
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(_image!, fit: BoxFit.cover),
                    ),
            ),

            const SizedBox(height: 20),

            // 버튼 영역
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera),
                  label: const Text('카메라'),
                ),
                const SizedBox(width: 20),
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo),
                  label: const Text('갤러리'),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // 결과 표시 영역
            if (_isAnalyzing)
              const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 10),
                  Text('AI가 재료를 분석 중입니다...'),
                ],
              )
            else if (_detectedItems.isNotEmpty)
              Column(
                children: [
                  const Text(
                    '🔍 인식된 재료',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8.0,
                    children: _detectedItems.map((item) {
                      return ActionChip(
                        label: Text(item),
                        onPressed: () {
                          print('$item 선택됨');
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
