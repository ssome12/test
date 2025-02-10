import 'package:flutter/material.dart';
import 'package:testversion1/pages/chat_page.dart';
import 'package:testversion1/pages/logs_page.dart';
import 'package:testversion1/pages/loading_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat AI App',
      // 앱 시작 시 로딩 페이지를 먼저 보여줌
      initialRoute: '/loading',
      routes: {
        // 올바른 경로 명명 규칙 사용 (앞에 /)
        '/loading': (context) => const LoadingPage(),
        '/chat': (context) => const ChatPage(),
        '/logs': (context) => const LogsPage(),
      },
    );
  }
}
