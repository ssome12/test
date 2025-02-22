import 'dart:convert';
import 'package:http/http.dart' as http;

const String groqApiKey =
    "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";
const String groqEndpoint =
    "https://api.groq.com/openai/v1/chat/completions";

// 지원 모드: 스크린샷과 smalltalk만 사용
enum AIMode { screenshot, smalltalk }

Future<String> fetchAIAnswerByMode(String contextText, AIMode mode) async {
  String systemPrompt;

  // 모드에 따른 system prompt 지정
  switch (mode) {
    case AIMode.screenshot:
      systemPrompt =
      "너는 스크린샷을 분석할 수 있어. 이미지의 내용을 간결하게 요약하고, 그에 맞는 간단한 설명과 추천 메시지를 한 문장으로 출력해.";
      break;
    case AIMode.smalltalk:
      systemPrompt =
      "너는 부드럽고 자연스러운 smalltalk를 제공할 수 있어. 처음 만나는 사람과 가볍고 친근하게 대화를 시작할 수 있는 한 문장을 만들어줘.";
      break;
  }

  final response = await http.post(
    Uri.parse(groqEndpoint),
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $groqApiKey",
    },
    body: jsonEncode({
      "model": "llama-3.3-70b-versatile",
      "messages": [
        {"role": "system", "content": systemPrompt},
        {"role": "user", "content": contextText}
      ],
      "max_tokens": 256,
      "temperature": 0.7,
    }),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    final String reply = data["choices"][0]["message"]["content"].trim();
    return reply;
  } else {
    return "🚨 오류 발생: ${response.statusCode}";
  }
}
