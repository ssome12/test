import 'package:flutter/material.dart';

class AIAnswerCard extends StatelessWidget {
  final String answerText;

  const AIAnswerCard({Key? key, required this.answerText}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2, // 약간 낮은 elevation으로 작게 보이게 함
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          answerText,
          maxLines: 1, // 한 줄로 제한
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }
}
