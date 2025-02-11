import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Clipboard 관련
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart'; // image_picker 패키지 (버전 1.1.2)

const String groqApiKey =
    "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";
const String groqEndpoint =
    "https://api.groq.com/openai/v1/chat/completions";

/// ChatPage는 선택적으로 초기 로그 데이터(initialLog)를 받을 수 있습니다.
class ChatPage extends StatefulWidget {
  final Map<String, dynamic>? initialLog;
  const ChatPage({Key? key, this.initialLog}) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage>
    with SingleTickerProviderStateMixin {
  // 컨트롤러들
  final TextEditingController titleController = TextEditingController();
  final TextEditingController otherController = TextEditingController();
  final TextEditingController myController = TextEditingController();

  // 대화 기록 리스트 (각 메시지는 {"text": String, "type": "상대" 또는 "나의", "isAI": "true"/"false"})
  final List<Map<String, String>> chatHistory = [];
  bool _isLoading = false;
  bool isHeart = true;
  bool showGuideText = true;

  // 스크롤 컨트롤러
  final ScrollController _chatScrollController = ScrollController();

  // 버튼 애니메이션 컨트롤러 및 Tween
  late final AnimationController _buttonController;
  late final Animation<double> _buttonAnimation;

  // image_picker 인스턴스
  final ImagePicker _picker = ImagePicker();

  // 내부적으로 현재 로그의 id (수정 모드일 때 사용)
  String? _currentLogId;

  @override
  void initState() {
    super.initState();

    // 초기 로그가 전달된 경우, 기존 메시지와 제목, id 복원
    if (widget.initialLog != null) {
      var messages = widget.initialLog!["messages"];
      if (messages != null && messages is List) {
        chatHistory.addAll(
            messages.map((e) => Map<String, String>.from(e)).toList());
      }
      titleController.text = widget.initialLog!["title"] ?? "";
      _currentLogId = widget.initialLog!["id"]; // 기존 id 복원
      showGuideText = false;
    }

    _buttonController =
    AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..repeat(reverse: true);
    _buttonAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );
  }

  /// 로그 저장 함수
  /// - 직접테스트 입력 모드: 기존 로그가 없으면 새 로그 생성, 이후에는 같은 로그를 업데이트합니다.
  /// - 수정 모드: widget.initialLog가 전달된 경우, 해당 로그를 업데이트합니다.
  Future<void> _saveSessionLog() async {
    if (chatHistory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("저장할 채팅 로그가 없습니다.")));
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final String? logsString = prefs.getString('chat_logs');
    List<dynamic> logsList = logsString != null ? jsonDecode(logsString) : [];

    Map<String, dynamic> newLog;
    if (_currentLogId != null) {
      // 업데이트 모드: 기존 로그 업데이트
      newLog = {
        "id": _currentLogId,
        "title": titleController.text.isNotEmpty
            ? titleController.text
            : " ",
        "date": DateTime.now().toString(),
        "messages": chatHistory,
      };

      int existingIndex =
      logsList.indexWhere((log) => log['id'] == _currentLogId);
      if (existingIndex >= 0) {
        logsList[existingIndex] = newLog;
      } else {
        logsList.add(newLog);
      }
    } else {
      // 직접테스트 입력 모드: 새로운 로그 생성 및 id 저장
      _currentLogId = DateTime.now().millisecondsSinceEpoch.toString();
      newLog = {
        "id": _currentLogId,
        "title": titleController.text.isNotEmpty
            ? titleController.text
            : "최근 대화내역",
        "date": DateTime.now().toString(),
        "messages": chatHistory,
      };
      logsList.add(newLog);
    }
    await prefs.setString('chat_logs', jsonEncode(logsList));
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("대화 내역이 저장되었습니다.")));
  }

  /// 클립보드 복사 기능: 텍스트 복사 후 "복사됨" 스낵바 표시
  void _copyText(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("복사됨")));
  }

  /// 메시지 편집/삭제 옵션: 해당 메시지에 대해 BottomSheet 띄우기
  void _showMessageOptions(int index) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text("편집"),
              onTap: () {
                Navigator.pop(context);
                _editMessage(index);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text("삭제"),
              onTap: () {
                Navigator.pop(context);
                _deleteMessage(index);
              },
            ),
          ],
        );
      },
    );
  }

  /// 메시지 편집: 해당 메시지 내용을 수정하는 다이얼로그 띄우기
  void _editMessage(int index) {
    final TextEditingController editController =
    TextEditingController(text: chatHistory[index]["text"]);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("메시지 편집"),
          content: TextField(
            controller: editController,
            maxLines: null,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("취소"),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  chatHistory[index]["text"] = editController.text;
                });
                Navigator.pop(context);
              },
              child: const Text("저장"),
            ),
          ],
        );
      },
    );
  }

  /// 메시지 삭제: 해당 메시지를 chatHistory에서 제거
  void _deleteMessage(int index) {
    setState(() {
      chatHistory.removeAt(index);
    });
  }

  /// 사용자 메시지 기록 및 스크롤 이동
  void _recordUserMessage(String text, String type) {
    if (text.trim().isEmpty) return;
    setState(() {
      chatHistory.add({
        "text": text.trim(),
        "type": type,
        "isAI": "false",
      });
      showGuideText = false;
    });
  }

  /// 이미지 메시지 기록 함수 (추가)
  void _recordImageMessage(String imagePath) {
    setState(() {
      chatHistory.add({
        "type": "image",
        "imagePath": imagePath,
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

  /// 사용자 메시지만 추출하여 AI에게 전달할 컨텍스트 생성
  String _getUserContext() {
    final List<String> msgs = chatHistory
        .where((msg) => msg["isAI"] != "true")
        .map((msg) => msg["text"] ?? "")
        .toList();
    return msgs.join("\n");
  }

  /// AI에게 조언 요청 (API 호출 후 응답을 chatHistory에 추가)
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
        ? "너는 최적의 연애 강사야. 지금 상황에서 빠르게 상대의 관심을 끌 수 있는, 핫하고 섹시한 접근법을 한 문장으로 제시해줘. "
        "상대의 마지막 말을 추적해서, 최적의 연애강사인만큼, 상대를 즐겁게 또 강하게 사로잡을 수 있는 말을 하고, 너무 부담스럽지 않게 접근해야함. 적절한 이모티콘 사용과 매번 다른 답변을 해줘."
        : "너는 상대방의 채팅에서 상황을 전문적으로 파악해서 알려줘야해. 정보가 부족하면 추가 채팅 입력을 요청하고, 구체적으로 상황을 설명해줘.";
    try {
      final http.Response response = await http.post(
        Uri.parse(groqEndpoint),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $groqApiKey",
        },
        body: jsonEncode({
          "model": "llama-3.3-70b-versatile",
          "messages": [
            {"role": "system", "content": systemPrompt},
            {"role": "user", "content": finalQuestion}
          ],
          "max_tokens": 256,
          "temperature": 0.7,
        }),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
        jsonDecode(utf8.decode(response.bodyBytes));
        final String reply =
        data["choices"][0]["message"]["content"].trim();
        setState(() {
          chatHistory.add({"text": reply, "isAI": "true"});
        });
        Future.delayed(const Duration(milliseconds: 100), () {
          if (_chatScrollController.position.maxScrollExtent -
              _chatScrollController.offset <
              100) {
            _chatScrollController.animateTo(
              _chatScrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      } else {
        setState(() {
          chatHistory.add({
            "text": "🚨 오류 발생: ${response.statusCode}",
            "isAI": "true"
          });
        });
      }
    } catch (e) {
      setState(() {
        chatHistory.add({"text": "🚨 오류 발생: $e", "isAI": "true"});
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 헤더: 뒤로가기, 제목 입력, 로그 저장 버튼
  Widget _buildCustomHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              Navigator.pushNamed(context, '/logs');
            },
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
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.save, color: Colors.black),
            onPressed: _saveSessionLog,
          ),
        ],
      ),
    );
  }

  /// 입력 영역: "상대의 회신" 및 "나의 회신" 텍스트필드
  Widget _buildInputArea() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: otherController,
              decoration: InputDecoration(
                labelText: "상대의 회신",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
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
              decoration: InputDecoration(
                labelText: "나의 회신",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
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

  /// 구분선
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

  /// 사용자 메시지 말풍선 (편집/삭제 지원)
  Widget _buildUserChatBubble(Map<String, String> message, int index) {
    bool isMine = message["type"] == "나의";
    return GestureDetector(
      onLongPress: () => _showMessageOptions(index),
      child: Align(
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
          child: Text(
            message["text"] ?? "",
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }

  /// AI 메시지 말풍선 (편집/삭제 및 클립보드 복사)
  Widget _buildAiChatBubble(Map<String, String> message, int index) {
    return GestureDetector(
      onLongPress: () => _showMessageOptions(index),
      child: Container(
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
      ),
    );
  }

  /// 사용자 메시지 위젯 리스트 생성
  List<Widget> _buildUserMessagesWidgets() {
    List<Map<String, String>> userMessages =
    chatHistory.where((msg) => msg["isAI"] != "true").toList();
    return List.generate(
      userMessages.length,
          (index) => _buildUserChatBubble(userMessages[index], index),
    );
  }

  /// AI 메시지 위젯 리스트 생성 (최신 메시지가 하단에 표시)
  List<Widget> _buildAiMessagesWidgets() {
    List<Map<String, String>> aiMessages =
    chatHistory.where((msg) => msg["isAI"] == "true").toList();
    aiMessages = aiMessages.reversed.toList();
    return List.generate(
      aiMessages.length,
          (index) => _buildAiChatBubble(aiMessages[index], index),
    );
  }

  @override
  void dispose() {
    _chatScrollController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  /// 하단 버튼 영역: "이쁜 대화하기" / "빠른 캐치하기" (애니메이션 적용)
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
      // 전체 배경 그라데이션 적용
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
              // 헤더: 뒤로가기, 제목 입력, 로그 저장 버튼
              _buildCustomHeader(),
              // 스크롤 가능한 콘텐츠: 입력 영역, 안내 텍스트, 사용자 메시지, 구분선, AI 메시지
              Expanded(
                child: SingleChildScrollView(
                  controller: _chatScrollController,
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildInputArea(),
                      if (showGuideText)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 4),
                          child: Text(
                            "! 회신을 받으려면 하나 이상 입력하세요",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ),
                      ..._buildUserMessagesWidgets(),
                      _buildSeparator(),
                      ..._buildAiMessagesWidgets(),
                    ],
                  ),
                ),
              ),
              // 하단 영역: 버튼 영역
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }
}
