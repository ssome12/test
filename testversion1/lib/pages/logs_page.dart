import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';  // 앱 공유를 위해 추가
import 'chat_page.dart';

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

  Future<void> _deleteLog(int index) async {
    setState(() {
      logs.removeAt(index);
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('chat_logs', jsonEncode(logs));
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      print("선택된 이미지 경로: ${pickedFile.path}");
      // TODO: 선택된 이미지 파일(pickedFile.path)을 ChatPage에 전달하는 로직 구현
    } else {
      print("이미지 선택 취소됨");
    }
  }

  // 하단 시트를 띄워 옵션 메뉴를 보여주는 함수
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
              // 이메일 보내주세요
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
              // 앱공유해주세요
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('앱공유해주세요'),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    await Share.share('앱 다운로드 링크: https://yourdownloadlink.com');
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('앱 공유를 할 수 없습니다.')),
                    );
                  }
                },
              ),
              // 언어
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('언어'),
                onTap: () {
                  Navigator.pop(context);
                  _showLanguageDialog(context);
                },
              ),
              // 업그레이드
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
              // 인스타그램 아이콘 (예시로 카메라 아이콘 사용)
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
              // 이용약관 & 개인정보 보호 (작은 글씨로 링크)
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
                        final Uri privacyUri = Uri.parse('https://yourdomain.com/privacy');
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
                  print("한국어 선택");
                  // 여기서 언어 변경 로직을 구현 (예: SharedPreferences에 저장)
                },
              ),
              ListTile(
                title: const Text("English"),
                onTap: () {
                  Navigator.pop(context);
                  print("English 선택");
                  // 여기서 언어 변경 로직을 구현
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // 헤더가 배경 위에 자연스럽게 오도록 설정
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        // 헤더 가운데에 이미지와 텍스트("SOME") 배치 (이미지는 assets/some.png 사용)
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/some.png',
              height: 30,
            )
          ],
        ),
        actions: [
          // 우측 상단에 더보기(옵션) 아이콘만 남김
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
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
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
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ChatPage(initialLog: log),
                              ),
                            );
                          },
                          child: Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  mainAxisAlignment:
                                  MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      content,
                                      style: const TextStyle(fontSize: 14),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: IconButton(
                                  icon: const Icon(Icons.close, size: 16),
                                  onPressed: () {
                                    _deleteLog(index);
                                  },
                                ),
                              ),
                            ],
                          ),
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
                  print("스크린샷 업로드 버튼 탭됨");
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
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChatPage(),
                    ),
                  );
                },
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
