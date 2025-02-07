import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Clipboard 관련
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

const String groqApiKey =
    "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";
const String groqEndpoint =
    "https://api.groq.com/openai/v1/chat/completions";

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key}) : super(key: key);
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage>
    with SingleTickerProviderStateMixin {
  // 제목 입력 컨트롤러 (로그 제목)
  final TextEditingController titleController = TextEditingController();
  // 입력 필드 컨트롤러 (상대의 회신, 나의 회신)
  final TextEditingController otherController = TextEditingController();
  final TextEditingController myController = TextEditingController();

  // 대화 기록 리스트: 각 항목은
  // {"text": String, "type": "상대" 또는 "나의", "isAI": "true"/"false"}
  final List<Map<String, String>> chatHistory = [];
  bool _isLoading = false;
  bool isHeart = true;
  bool showGuideText = true;

  // 전체 스크롤 컨트롤러 (입력 영역, 메시지, 구분선, AI 메시지 모두 포함)
  final ScrollController _chatScrollController = ScrollController();

  // AnimationController 및 Tween for "빠른 캐치하기" 버튼 애니메이션
  late final AnimationController _buttonController;
  late final Animation<double> _buttonAnimation;

  @override
  void initState() {
    super.initState();
    _buttonController =
    AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..repeat(reverse: true);
    _buttonAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );
  }

  /// 대화 로그 자동 저장 (간단한 JSON 문자열로)
  Future<void> _saveLog() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('chat_log', jsonEncode(chatHistory));
  }

  /// 클립보드 복사 기능: 텍스트 복사 후 스낵바 표시 ("복사됨")
  void _copyText(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("복사됨")));
  }

  /// 사용자가 메시지 입력 시 chatHistory에 추가 후 전체 스크롤 영역 맨 아래로 이동
  void _recordUserMessage(String text, String type) {
    if (text.trim().isEmpty) return;
    setState(() {
      chatHistory.add({
        "text": text.trim(),
        "type": type, // "상대" 또는 "나의"
        "isAI": "false",
      });
      showGuideText = false;
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// 사용자 메시지만 추출하여 AI에 전달할 컨텍스트 생성 (모든 사용자 메시지를 한 줄씩 결합)
  String _getUserContext() {
    final List<String> msgs = chatHistory
        .where((msg) => msg["isAI"] != "true")
        .map((msg) => msg["text"] ?? "")
        .toList();
    return msgs.join("\n");
  }

  /// AI에게 조언 요청: 사용자 메시지 컨텍스트 기반으로 API 호출, 응답은 AI 메시지로 추가
  Future<void> _requestAdvice() async {
    setState(() {
      _isLoading = true;
    });
    final String finalQuestion = _getUserContext();
    if (finalQuestion.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      return;
    }
    final String systemPrompt = isHeart
        ? "너는 최적의 연애 강사야. 지금 상황에서 빠르게 상대의 관심을 끌 수 있는, 핫하고 섹시한 접근법을 한 문장으로 제시해줘. " +
        "상대의 마지막 말을 추적해서,최적의 연애강사인만큼, 상대를 즐겁게 또 강하게 사로잡을수 있는 말을 하고, 너무 부담스럽지 않게 접근해야함 적절한 이모티콘사용, 그리고 매번 다른 답변을 해주고"+
        "상대방에게 첫 인상부터 강렬하게 다가갈 수 있도록, 로맨틱하면서도 개성 있는 첫 인사말을 제안해줘." +
        "상대방과의 대화에서 분위기를 부드럽게 전환할 수 있는, 세련된 대화 전환 구절을 추천해줘."
        : "너는 상대방의 채팅에서 전문적으로 상황 파악을 해서 알려줘야함. 특히 한국어인 냠, 냥 같은 'ㅁ' 'ㅇ' 밑에 받침만 들어가도 느낌이 다르고, 차가운 멘트인지"
        +"전체적인 맥락파악을 최대한 해야함, 정보가 애매하다면 좀더 채팅을 입력해 달라고 얘기해줘 그리고 구체적인것과 논리적으로 상황 설명";
    try {
      final http.Response response = await http.post(
        Uri.parse(groqEndpoint),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $groqApiKey",
        },
        // <font color="red">수정: 요청 본문에 필요한 모든 필드를 jsonEncode로 전달</font>
        body: jsonEncode({
          "model": "llama-3.3-70b-versatile",
          "messages": [
            {
              "role": "system",
              "content": systemPrompt
            },
            {
              "role": "user",
              "content": finalQuestion
            }
          ],
          "max_tokens": 256,
          "temperature": 0.7,
        }),
      );

      // <font color="red">수정: 응답 상태 코드에 따라 jsonDecode를 시도하도록 수정</font>
      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
        jsonDecode(utf8.decode(response.bodyBytes));
        final String reply =
        data["choices"][0]["message"]["content"].trim();
        setState(() {
          chatHistory.add({
            "text": reply,
            "isAI": "true",
          });
        });
        Future.delayed(const Duration(milliseconds: 100), () {
          if (_chatScrollController.position.maxScrollExtent - _chatScrollController.offset < 100) {
            _chatScrollController.animateTo(
              _chatScrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
        await _saveLog();
      } else {
        // <font color="red">주의: 상태 코드가 200이 아닐 때는 응답 본문이 JSON 형식이 아닐 수 있으므로 jsonDecode를 시도하지 않음</font>
        setState(() {
          chatHistory.add({
            "text": "🚨 오류 발생: ${response.statusCode}",
            "isAI": "true",
          });
        });
      }
    } catch (e) {
      setState(() {
        chatHistory.add({
          "text": "🚨 오류 발생: $e",
          "isAI": "true",
        });
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 헤더: 뒤로가기 아이콘과 중앙의 제목 입력 ("이름")
  Widget _buildCustomHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Center(
              child: Container(
                width: 120,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.pink.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.pink.shade200, width: 1),
                ),
                child: TextField(
                  controller: titleController,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    hintText: "이름",
                    border: InputBorder.none,
                  ),
                  style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  /// 입력 영역: "상대의 회신"과 "나의 회신"
  /// - 단일행 입력 (maxLines: 1)과 textInputAction을 설정하여 엔터 시 전송되도록 함.
  Widget _buildInputArea() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: otherController,
              decoration: const InputDecoration(
                labelText: "상대의 회신",
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.send,
              maxLines: 1,
              onSubmitted: (value) {
                _recordUserMessage(value, "상대");
                otherController.clear();
              },
              onChanged: (value) {
                if (value.trim().isNotEmpty) {
                  setState(() {
                    showGuideText = false;
                  });
                }
              },
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
              textInputAction: TextInputAction.send,
              maxLines: 1,
              onSubmitted: (value) {
                _recordUserMessage(value, "나의");
                myController.clear();
              },
              onChanged: (value) {
                if (value.trim().isNotEmpty) {
                  setState(() {
                    showGuideText = false;
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  /// AI 생성 라인 구분선 위젯 (입력 영역 바로 아래에 위치)
  Widget _buildSeparator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: const [
          Expanded(child: Divider(color: Colors.black26)),
          SizedBox(width: 8),
          Text("AI 생성 라인"),
          SizedBox(width: 8),
          Expanded(child: Divider(color: Colors.black26)),
        ],
      ),
    );
  }

  /// 사용자 메시지 말풍선 (로그 번호 포함)
  Widget _buildUserChatBubble(Map<String, String> message, int index) {
    bool isMine = message["type"] == "나의";
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: isMine
              ? const LinearGradient(
            colors: [Color(0xFFB3E5FC), Color(0xFF81D4FA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
              : const LinearGradient(
            colors: [Color(0xFFFFCDD2), Color(0xFFFFAB91)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            //Text(
              // "${index + 1}. ",
             // style: const TextStyle(fontWeight: FontWeight.bold),
           // ),
            Flexible(
              child: Text(
                message["text"] ?? "",
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// AI 메시지 말풍선 (로그 번호 및 복사 버튼 포함)
  Widget _buildAiChatBubble(Map<String, String> message, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFC1E3), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Text(
          //   "${index + 1}. ",
          //   style: const TextStyle(fontWeight: FontWeight.bold),
          // ),
          Expanded(
            child: Text(
              message["text"] ?? "",
              style: const TextStyle(fontSize: 16),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 20),
            onPressed: () => _copyText(message["text"] ?? ""),
          ),
        ],
      ),
    );
  }

  /// 사용자 메시지 위젯 (시간 순서대로)
  List<Widget> _buildUserMessagesWidgets() {
    List<Map<String, String>> userMessages =
    chatHistory.where((msg) => msg["isAI"] != "true").toList();
    return List.generate(userMessages.length,
            (index) => _buildUserChatBubble(userMessages[index], index));
  }

  /// AI 메시지 위젯 (역순: 최신 메시지가 바로 아래에)
  List<Widget> _buildAiMessagesWidgets() {
    List<Map<String, String>> aiMessages =
    chatHistory.where((msg) => msg["isAI"] == "true").toList();
    aiMessages = aiMessages.reversed.toList();
    return List.generate(aiMessages.length,
            (index) => _buildAiChatBubble(aiMessages[index], index));
  }

  @override
  void dispose() {
    _chatScrollController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  /// 하단 영역: 아이콘과 버튼들을 중앙 정렬하고, "빠른 캐치하기" 버튼은 넓게(200px) 표시하며 애니메이션 효과 적용
  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                isHeart = !isHeart;
              });
            },
            child: CircleAvatar(
              backgroundColor: Colors.black12,
              radius: 25,
              child: Icon(
                isHeart ? Icons.favorite : Icons.flash_on,
                color: isHeart ? Colors.pink : Colors.orange,
                size: 30,
              ),
            ),
          ),
          const SizedBox(width: 16),
          isHeart
              ? SizedBox(
            width: 200,
            child: ScaleTransition(
              scale: _buttonAnimation,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _requestAdvice,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 50),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                  elevation: 8,
                ),
                child: const Text("이쁜 대화하기"),
              ),
            ),
          )
              : SizedBox(
            width: 200,
            child: ScaleTransition(
              scale: _buttonAnimation,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _requestAdvice,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 50),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                  elevation: 8,
                ),
                child: const Text("빠른 캐치하기"),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 전체 배경 그라데이션
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
              // 헤더 영역
              _buildCustomHeader(),
              // 스크롤 가능한 전체 콘텐츠: 입력 영역, 사용자 메시지, 구분선, AI 메시지
              Expanded(
                child: SingleChildScrollView(
                  controller: _chatScrollController,
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 입력 영역은 최상단에 고정되어 있으며, 새 메시지가 생성되면 위로 밀려납니다.
                      _buildInputArea(),
                      ..._buildUserMessagesWidgets(),
                      _buildSeparator(),
                      ..._buildAiMessagesWidgets(),
                    ],
                  ),
                ),
              ),
              // 하단 영역
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }
}
