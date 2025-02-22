import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'chat_page.dart';
import 'screenshot_page.dart';

class LogsPage extends StatefulWidget {
  const LogsPage({Key? key}) : super(key: key);

  @override
  _LogsPageState createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  List<dynamic> logs = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final String? logsString = prefs.getString('chat_logs');
    if (logsString != null) {
      setState(() {
        logs = jsonDecode(logsString);
      });
    }
  }

  Future<void> _saveLogs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('chat_logs', jsonEncode(logs));
  }

  Future<void> _deleteLog(int index) async {
    setState(() {
      logs.removeAt(index);
    });
    await _saveLogs();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ScreenshotPage(imagePath: pickedFile.path),
        ),
      );
    } else {
      debugPrint("이미지 선택 취소됨");
    }
  }

  // (기존의 옵션 시트, 언어 선택 다이얼로그 등은 그대로 둡니다)
  void _showOptionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.email),
                title: const Text('이메일을 보내주세요'),
                onTap: () async {
                  Navigator.pop(context);
                  final Uri emailLaunchUri = Uri(
                    scheme: 'mailto',
                    path: 'seajinbs@gmail.com',
                    query: 'subject=문의 사항&body=안녕하세요,',
                  );
                  if (await canLaunchUrl(emailLaunchUri)) {
                    await launchUrl(emailLaunchUri);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('메일 앱을 실행할 수 없습니다.')),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('언어'),
                onTap: () {
                  Navigator.pop(context);
                  _showLanguageDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.upgrade),
                title: const Text('업그레이드'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('업그레이드 준비중입니다.')),
                  );
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.purple),
                title: const Text('Instagram'),
                onTap: () async {
                  final Uri instaUri = Uri.parse('https://instagram.com/youraccount');
                  if (await canLaunchUrl(instaUri)) {
                    await launchUrl(instaUri);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Instagram을 열 수 없습니다.')),
                    );
                  }
                },
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    InkWell(
                      onTap: () async {
                        final Uri termsUri = Uri.parse('https://yourdomain.com/terms');
                        if (await canLaunchUrl(termsUri)) {
                          await launchUrl(termsUri);
                        }
                      },
                      child: const Text(
                        "이용약관",
                        style: TextStyle(fontSize: 12, color: Colors.blue),
                      ),
                    ),
                    const SizedBox(width: 16),
                    InkWell(
                      onTap: () async {
                        final Uri privacyUri = Uri.parse('https://sites.google.com/view/ssomeprivatepolicy/%ED%99%88');
                        if (await canLaunchUrl(privacyUri)) {
                          await launchUrl(privacyUri);
                        }
                      },
                      child: const Text(
                        "개인정보 보호",
                        style: TextStyle(fontSize: 12, color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("언어 선택"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text("한국어"),
                onTap: () {
                  Navigator.pop(context);
                  debugPrint("한국어 선택");
                  // 언어 변경 로직 구현 (예: SharedPreferences에 저장)
                },
              ),
              ListTile(
                title: const Text("English"),
                onTap: () {
                  Navigator.pop(context);
                  debugPrint("English 선택");
                  // 언어 변경 로직 구현
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // 직접테스트 입력 버튼 클릭 시 항상 새로운 대화창(빈 ChatPage)으로 이동하도록 수정
  Future<void> _openDirectChat() async {
    final updatedLog = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ChatPage(), // initialLog을 넘기지 않아 새 대화 시작
      ),
    );
    if (updatedLog != null) {
      setState(() {
        logs.add(updatedLog);
      });
      await _saveLogs();
    }
  }

  // 타임스탬프 포맷 헬퍼 함수
  String _formatTimestamp(String timestamp) {
    try {
      final dt = DateTime.parse(timestamp);
      return '${dt.year}년 ${dt.month.toString().padLeft(2, '0')}월 ${dt.day.toString().padLeft(2, '0')}일';
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // 배경 위에 앱바 표시
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/some.png',
              height: 30,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showOptionsSheet(context),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.0,
            colors: [Colors.white, Colors.pink.shade200],
            stops: const [0.0, 1.0],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadLogs,
                child: logs.isEmpty
                    ? const Center(child: Text("저장된 대화 내역이 없습니다."))
                    : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8.0,
                      mainAxisSpacing: 8.0,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      String title = (log['title'] ?? "").trim();
                      if (title.isEmpty) {
                        title = "최근대화내역";
                      }
                      String content = "";
                      if (log['messages'] != null &&
                          log['messages'] is List &&
                          (log['messages'] as List).isNotEmpty) {
                        List messages = log['messages'];
                        content = messages.last['text'] ?? "";
                      }
                      return Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Stack(
                          children: [
                            InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatPage(initialLog: log),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Expanded(
                                      child: Center(
                                        child: Text(
                                          content,
                                          style: const TextStyle(fontSize: 14),
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    if (log.containsKey('timestamp'))
                                      Text(
                                        _formatTimestamp(log['timestamp']),
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            // 오른쪽 상단 X 버튼 (로그 삭제)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: IconButton(
                                icon: const Icon(Icons.close, color: Colors.red, size: 20),
                                onPressed: () {
                                  _deleteLog(index);
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  // 하단 버튼 영역
  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.8, end: 1.0),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutBack,
          builder: (context, scale, child) {
            return Transform.scale(scale: scale, child: child);
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () async {
                  debugPrint("스크린샷 업로드 버튼 탭됨");
                  await _pickImage();
                },
                child: Container(
                  width: 140,
                  height: 50,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF6A1B9A), Color(0xFFD81B60)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                    border: Border.fromBorderSide(
                      BorderSide(color: Colors.white, width: 2),
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      "스크린샷 업로드",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: _openDirectChat,
                child: Container(
                  width: 140,
                  height: 50,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF039BE5), Color(0xFF00ACC1)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    border: Border.fromBorderSide(
                      BorderSide(color: Colors.white, width: 2),
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      "직접테스트 입력",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
