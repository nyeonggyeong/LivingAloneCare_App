import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // 메일 보내기용 (패키지 없으면 생략 가능)

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  // 이메일 문의하기 함수
  Future<void> _sendEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@livingalonecare.com', // 개발자 이메일 주소
      queryParameters: {
        'subject': '[자취생 키우기] 문의합니다',
        'body': '문의 내용을 입력해주세요.\n\n',
      },
    );

    try {
      await launchUrl(emailLaunchUri);
    } catch (e) {
      // 이메일 앱을 열 수 없을 때 (시뮬레이터 등)
      print("이메일 열기 실패: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text(
          "도움말",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "자주 묻는 질문 (FAQ)",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // FAQ 리스트
            _buildFaqItem(
              "Q. 레시피 추천은 어떻게 이루어지나요?",
              "A. 사용자가 냉장고에 등록한 재료들을 분석하여, 만들 수 있는 요리를 우선적으로 추천해 드립니다. 유통기한이 임박한 재료를 활용하는 '냉파(냉장고 파먹기) 레시피'가 상단에 표시됩니다.",
            ),
            _buildFaqItem(
              "Q. 재료 등록은 어떻게 하나요?",
              "A. 홈 화면 하단의 '+' 버튼을 누르면 직접 입력하거나, 영수증/식재료 사진을 찍어 AI 인식으로 간편하게 등록할 수 있습니다.",
            ),
            _buildFaqItem(
              "Q. 알림 설정을 변경하고 싶어요.",
              "A. 마이페이지 > 알림 설정 메뉴에서 유통기한 임박 알림, 레시피 추천 알림 등을 켜거나 끌 수 있습니다.",
            ),
            _buildFaqItem(
              "Q. 회원 탈퇴는 어디서 하나요?",
              "A. 마이페이지 > 설정 > 계정 관리 메뉴에서 회원 탈퇴를 진행하실 수 있습니다. 탈퇴 시 모든 데이터는 삭제됩니다.",
            ),

            const SizedBox(height: 40),

            // 문의하기 섹션
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.headset_mic,
                    size: 40,
                    color: Color(0xFFFFA36A),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "더 궁금한 점이 있으신가요?",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "앱 사용 중 불편한 점이나 건의사항이 있다면\n언제든지 알려주세요.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _sendEmail,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFA36A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        "이메일로 문의하기",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            question,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          iconColor: const Color(0xFFFFA36A),
          textColor: const Color(0xFFFFA36A),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Text(
              answer,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
