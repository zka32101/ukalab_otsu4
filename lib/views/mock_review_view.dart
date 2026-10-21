import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:ukalab_core/ukalab_core.dart';
import 'package:ukalab_core/learning.dart';

import 'choice_labels.dart';

/// 模擬試験で間違えた問題だけを見返す画面。選択肢は採点時の正解・選んだ
/// 回答を表示し、解説も合わせて確認できる。[MockExamView] の結果画面から
/// 「間違えた問題を振り返る」で遷移する。
class MockReviewView extends StatelessWidget {
  const MockReviewView({super.key, required this.questions, required this.answers});

  final List<Question> questions;
  final Map<String, Object?> answers;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('間違えた問題の振り返り')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: questions.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, i) {
          final q = questions[i];
          final selected = answers[q.qid];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              QuestionCard(text: q.prompt, index: i + 1, total: questions.length),
              const SizedBox(height: 12),
              for (var ci = 0; ci < q.choices.length; ci++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ChoiceTile(
                    label: choiceLabels[ci],
                    text: q.choices[ci],
                    state: ci == q.answerIndex
                        ? ChoiceState.correct
                        : ci == selected
                            ? ChoiceState.incorrect
                            : ChoiceState.idle,
                    onTap: null,
                  ),
                ),
              const SizedBox(height: 8),
              ExplanationPanel(body: q.explanation, sourceRef: q.sourceRef),
            ],
          );
        },
      ),
    );
  }
}
