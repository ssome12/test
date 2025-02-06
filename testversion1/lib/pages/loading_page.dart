// loading_page.dart
// 앱 실행 시 로딩 후 "챗하기" 버튼을 통해 ChatPage로 이동하는 페이지입니다.

import 'package:flutter/material.dart';

class LoadingPage extends StatefulWidget {
  @override
  _LoadingPageState createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("AI Dating Advisor"),
            ElevatedButton(
              onPressed: () {
                print("✅ 챗하기 버튼 클릭됨"); // 👉 콘솔 확인용
                Navigator.pushNamed(context, '/chat'); // ✅ ChatPage로 이동
              },
              child: const Text("챗하기"),
            ),
          ],
        ),
      ),
    );
  }
}