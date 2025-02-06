// logs_page.dart
// 사용자의 대화 로그를 관리하며, ChatPage로 이동하여 대화를 이어가거나 새 대화를 시작하고, 대화 내역을 로컬에 저장합니다.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LogsPage extends StatefulWidget {
  const LogsPage({super.key});
  @override
  _LogsPageState createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  List<Map<String, dynamic>> logs = []; // 각 로그: {'id': String, 'topic': String, 'chatHistory': List<Map<String, String>>}

  @override
  void initState() {
    super.initState();
    loadLogs();
  }

  Future<void> loadLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final logsString = prefs.getString('logs');
    if (logsString != null) {
      setState(() {
        logs = List<Map<String, dynamic>>.from(jsonDecode(logsString));
      });
    }
  }

  Future<void> saveLogs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('logs', jsonEncode(logs));
  }

  /// ChatPage로 이동 (log가 있으면 기존 대화, 없으면 새 대화)
  Future<void> navigateToChat({Map<String, dynamic>? log}) async {
    final result = await Navigator.pushNamed(context, '/chat', arguments: log);
    if (result != null && result is Map<String, dynamic>) {
      // 기존 로그가 있다면 업데이트, 아니면 새 로그 추가
      if (log != null) {
        int index = logs.indexWhere((element) => element['id'] == log['id']);
        if (index != -1) {
          logs[index] = result;
        }
      } else {
        logs.add(result);
      }
      await saveLogs();
      setState(() {}); // UI 갱신
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("로그 관리"),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                return Card(
                  child: ListTile(
                    title: Text(log['topic'] ?? "대화"),
                    subtitle: Text("메시지 ${log['chatHistory']?.length ?? 0}개"),
                    onTap: () => navigateToChat(log: log),
                  ),
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: () => navigateToChat(), // 새 대화 시작
            child: const Text("새 챗 시작"),
          ),
        ],
      ),
    );
  }
}
