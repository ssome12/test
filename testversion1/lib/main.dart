// main.dart
// AI Dating Advisor 앱의 메인 파일로, 앱 라우팅 및 초기 페이지 설정을 담당합니다.

import 'package:flutter/material.dart';
import 'package:testversion1/pages/logs_page.dart';
import 'package:testversion1/pages/chat_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Dating Advisor',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/logs',
      routes: {
        '/logs': (context) => const LogsPage(),
        '/chat': (context) => const ChatPage(),
      },
    );
  }
}
