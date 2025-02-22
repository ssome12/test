import 'dart:io';
import 'package:flutter/material.dart';
import 'ai_answer_card.dart';
import 'ai_service.dart'; // 여기에는 fetchAIAnswerByMode와 AIMode enum이 정의되어 있음
import 'package:google_ml_kit/google_ml_kit.dart';

class ScreenshotPage extends StatefulWidget {
  final String imagePath; // 업로드된 스크린샷 파일 경로

  const ScreenshotPage({Key? key, required this.imagePath}) : super(key: key);

  @override
  _ScreenshotPageState createState() => _ScreenshotPageState();
}

class _ScreenshotPageState extends State<ScreenshotPage> {
  bool isAnalyzing = true;
  String analysisResult = "";
  List<String> aiAnswers = []; // 생성된 AI 답변들을 저장하는 리스트

  @override
  void initState() {
    super.initState();
    _analyzeAndFetchAnswer();
  }

  Future<void> _analyzeAndFetchAnswer() async {
    // 실제 OCR 및 감정 분석 로직 대신 2초 딜레이 후 더미 결과 사용
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      analysisResult = "긍정적 톤, 가벼운 유머 섞인 답변 추천";
      isAnalyzing = false;
    });
    // 분석 결과를 기반으로 첫 AI 답변 자동 생성 (스크린샷 모드 사용)
    _fetchAndAppendAnswer();
  }

  Future<void> _fetchAndAppendAnswer() async {
    try {
      // isHeart 대신 AIMode.screenshot 사용
      String answer = await fetchAIAnswerByMode(analysisResult, AIMode.screenshot);
      setState(() {
        aiAnswers.add(answer);
      });
    } catch (e) {
      setState(() {
        aiAnswers.add("🚨 오류 발생: $e");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink.shade100, // 핑크 배경
      appBar: AppBar(
        title: const Text("스크린샷 분석"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 상단 영역: 스크린샷 이미지 (고정 높이)
            Container(
              height: 300, // 원하는 이미지 영역 높이
              child: Image.file(
                File(widget.imagePath),
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 8),
            const Divider(thickness: 1),
            const SizedBox(height: 8),
            // 하단 영역: AI 답변 카드 리스트
            Expanded(
              child: aiAnswers.isNotEmpty
                  ? ListView.builder(
                itemCount: aiAnswers.length,
                itemBuilder: (context, index) {
                  return AIAnswerCard(answerText: aiAnswers[index]);
                },
              )
                  : isAnalyzing
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text("답변 생성 중..."),
                  ],
                ),
              )
                  : const Center(child: Text("답변이 생성되지 않았습니다.")),
            ),
            // 하단 우측 '답변 얻기' 버튼: 누를 때마다 새로운 AI 답변을 리스트에 추가
            Align(
              alignment: Alignment.bottomRight,
              child: ElevatedButton(
                onPressed: _fetchAndAppendAnswer,
                child: const Text("답변 얻기"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
