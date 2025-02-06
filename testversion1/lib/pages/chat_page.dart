// chat_page.dart
// 사용자와 AI 챗봇이 대화할 수 있는 페이지입니다.
// 상단에는 "질문을 입력하세요"와 함께 두 개의 입력 칸(상대의 회신, 나의 회신)이 있으며,
// 입력 후 하단의 버튼(토글 가능한 하트/번개 아이콘 및 오른쪽 "대답 받아보기" 버튼)을 눌러 AI 조언을 요청하면
// 응답이 카드 형태로 생성되어 아래에 추가되고, 각 응답은 복사 기능이 제공되며, 대화 로그는 자동 저장됩니다.
// 전체 배경은 가운데 흰색, 주변 연분홍 그라데이션 처리되어 있습니다.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Clipboard 관련
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

const String groqApiKey = "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";
const String groqEndpoint = "https://api.groq.com/openai/v1/chat/completions";

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  // Controllers for the two input fields
  final TextEditingController otherController = TextEditingController();
  final TextEditingController myController = TextEditingController();

  // List to store generated chat responses
  List<Map<String, String>> chatHistory = [];
  bool _isLoading = false;

  // 토글 상태: true이면 하트, false이면 번개
  bool isHeart = true;

  // 자동 저장: 대화 로그를 SharedPreferences에 저장 (예제에서는 간단히 JSON 문자열로 저장)
  Future<void> _saveLog() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('chat_log', jsonEncode(chatHistory));
    // 실제 프로젝트에서는 LogsPage와 연동해 더 정교하게 관리할 수 있음.
  }

  // 복사 기능: 텍스트를 클립보드에 복사하고 스낵바 메시지 표시
  void _copyText(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("복사 되었습니다")),
    );
  }

  // AI에게 조언 요청: 두 입력 필드의 텍스트를 결합하여 메시지 생성
  Future<void> _requestAdvice() async {
    setState(() {
      _isLoading = true;
    });

    // 두 입력값 읽기
    final String otherInput = otherController.text.trim();
    final String myInput = myController.text.trim();

    // 최소한 하나 이상의 메시지가 있어야 함
    if (otherInput.isEmpty && myInput.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // 최종 질문 메시지 구성 (두 필드 모두 입력되면 줄바꿈 처리)
    String finalQuestion = "";
    if (otherInput.isNotEmpty && myInput.isNotEmpty) {
      finalQuestion = "상대의 회신: $otherInput\n나의 회신: $myInput";
    } else if (otherInput.isNotEmpty) {
      finalQuestion = "상대의 회신: $otherInput";
    } else {
      finalQuestion = "나의 회신: $myInput";
    }

    // 시스템 프롬프트를 토글 상태에 따라 다르게 설정
    String systemPrompt = isHeart
        ? "너는 최고의 데이트 조언가야. 한 문장으로 조언해줘."
        : "너는 빠른 캐치 전문가야. 간결하게 답변해줘.";

    try {
      final Map<String, dynamic> requestBody = {
        "model": "llama3-70b-chat",
        "messages": [
          {"role": "system", "content": systemPrompt},
          {"role": "user", "content": finalQuestion}
        ],
        "max_tokens": 256,
        "temperature": 0.7
      };

      final http.Response response = await http.post(
        Uri.parse(groqEndpoint),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $groqApiKey",
        },
        body: jsonEncode(requestBody),
      );

      final Map<String, dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        final String reply = data["choices"][0]["message"]["content"].trim();
        setState(() {
          chatHistory.insert(0, {
            "question": finalQuestion,
            "answer": reply
          });
          // 입력창 초기화
          otherController.clear();
          myController.clear();
        });
        // 자동 저장 대화 로그
        await _saveLog();
      } else {
        setState(() {
          chatHistory.insert(0, {
            "question": finalQuestion,
            "answer": "🚨 오류 발생: ${response.statusCode}"
          });
        });
      }
    } catch (e) {
      setState(() {
        chatHistory.insert(0, {
          "question": finalQuestion,
          "answer": "🚨 오류 발생: $e"
        });
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 하단 버튼: 좌측 토글 버튼과 우측 조언 요청 버튼
  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // 좌측: 토글 가능한 동그란 버튼 (하트 또는 번개 아이콘)
          GestureDetector(
            onTap: () {
              setState(() {
                isHeart = !isHeart;
              });
            },
            child: CircleAvatar(
              backgroundColor: Colors.white,
              radius: 25,
              child: Icon(
                isHeart ? Icons.favorite : Icons.flash_on,
                color: isHeart ? Colors.pink : Colors.orange,
                size: 30,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // 우측: 조언 요청 버튼 (토글 상태에 따라 레이블 변경)
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : _requestAdvice,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
              ),
              child: Text(
                isHeart ? "이쁜 대화하기" : "빠른 캐치하기",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 각 채팅 응답 카드를 생성 (오른쪽에 복사 버튼 두 개 포함)
  Widget _buildChatCard(Map<String, String> message) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "🙋 질문: ${message['question']}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "🤖 AI 답변: ${message['answer']}",
              style: const TextStyle(color: Colors.black87),
            ),
            // 복사 버튼들 (오른쪽 정렬)
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () => _copyText(message['question'] ?? ""),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_all),
                    onPressed: () => _copyText(message['answer'] ?? ""),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 배경 그라데이션: 가운데 흰색, 바깥쪽 연분홍
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.0,
            colors: [Colors.white, Colors.pink.shade100],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 상단 헤더 및 입력 영역
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "질문을 입력하세요",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "참고할 회신 받으려면 메시지 하나 이상 입력",
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    // 두 개의 입력 칸: 왼쪽은 상대의 회신, 오른쪽은 나의 회신
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: otherController,
                            decoration: const InputDecoration(
                              labelText: "상대의 회신",
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: myController,
                            decoration: const InputDecoration(
                              labelText: "나의 회신",
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // AI 생성 라인 구분선
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: const [
                    Expanded(child: Divider(color: Colors.black26)),
                    SizedBox(width: 8),
                    Text("AI 생성 라인"),
                    SizedBox(width: 8),
                    Expanded(child: Divider(color: Colors.black26)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // 생성된 응답 리스트
              Expanded(
                child: ListView.builder(
                  reverse: true,
                  itemCount: chatHistory.length,
                  itemBuilder: (context, index) {
                    return _buildChatCard(chatHistory[index]);
                  },
                ),
              ),
              // 하단 바: 토글 버튼 및 조언 요청 버튼
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }
}
