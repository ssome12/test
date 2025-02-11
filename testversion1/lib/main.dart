import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:testversion1/pages/chat_page.dart';
import 'package:testversion1/pages/logs_page.dart';
import 'package:testversion1/pages/loading_page.dart';

Future<void> main() async {
  // Flutter 엔진 초기화 후 Firebase 초기화
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat AI App',
      // 앱 시작 시 로딩 페이지를 먼저 보여줍니다.
      initialRoute: '/loading',
      routes: {
        '/loading': (context) => const LoadingPage(),
        '/chat': (context) => const ChatPage(),
        '/logs': (context) => const LogsPage(),
      },
    );
  }
}
