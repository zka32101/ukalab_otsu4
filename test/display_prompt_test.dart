import 'package:flutter_test/flutter_test.dart';
import 'package:ukalab_core/ukalab_core.dart';

void main() {
  test('choice 形式の displayPrompt は prompt と同じ', () {
    const q = Question(
      qid: 'dp1',
      examId: 'hazmat4',
      subjectId: 'law',
      topicId: 't',
      prompt: '選択式の問題文',
      choices: ['正解', '誤り'],
      answerIndex: 0,
      explanation: '解説',
      source: QuestionSource.original,
      sourceRef: '自作',
      contentVer: '1',
    );
    expect(q.displayPrompt, q.prompt);
  });
}
