import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otsu4/data/exam_repository.dart';
import 'package:otsu4/data/question_repository.dart';
import 'package:otsu4/widgets/answer_explanation_card.dart';
import 'package:otsu4/widgets/question_count_card.dart';
import 'package:ukalab_core/ui.dart';
import 'package:ukalab_core/ukalab_core.dart';

double _lum(Color c) => c.computeLuminance();

double _contrast(Color a, Color b) {
  final l1 = _lum(a);
  final l2 = _lum(b);
  return (math.max(l1, l2) + 0.05) / (math.min(l1, l2) + 0.05);
}

Question _q(String id, String subjectId) => Question(
      qid: id,
      examId: 'hazmat4',
      subjectId: subjectId,
      topicId: 't',
      prompt: 'p$id',
      choices: ['a', 'b'],
      answerIndex: 0,
      explanation: 'e',
      source: QuestionSource.original,
      sourceRef: '自作',
      contentVer: '1',
    );

const _longText =
    '危険物の貯蔵・取扱いは、指定数量以上の場合は許可を受けた貯蔵所で行う必要があります。'
    'この行動は法令に違反します。理由は、許可なく指定数量以上を仮置きしているためです。'
    '市町村長等の承認を得た場合に限り、10日以内の仮貯蔵・仮取扱いが認められます。';

void main() {
  for (final dark in [false, true]) {
    final label = dark ? 'ダーク' : 'ライト';
    for (final incorrect in [true, false]) {
      testWidgets('解説カードのコントラスト $label incorrect=$incorrect', (tester) async {
        final theme = dark
            ? UkalabTheme.dark(field: UkalabField.tech, cert: UkalabCert.hazmat4)
            : UkalabTheme.light(field: UkalabField.tech, cert: UkalabCert.hazmat4);
        final scheme = theme.colorScheme;
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Scaffold(
              body: SizedBox(
                width: 280,
                child: AnswerExplanationCard(text: _longText, incorrect: incorrect),
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        expect(find.text(incorrect ? '解説（不正解）' : '解説'), findsOneWidget);
        final box = tester.widget<Container>(
          find.descendant(of: find.byType(AnswerExplanationCard), matching: find.byType(Container)).first,
        );
        final bg = (box.decoration! as BoxDecoration).color!;
        expect(bg, AnswerExplanationCard.backgroundOf(scheme, incorrect: incorrect));
        final body = tester.widget<Text>(find.text(_longText));
        final fg = body.style!.color!;
        expect(_contrast(fg, bg), greaterThanOrEqualTo(4.5));
        final head = tester.widget<Text>(find.text(incorrect ? '解説（不正解）' : '解説'));
        expect(_contrast(head.style!.color!, bg), greaterThanOrEqualTo(4.5));
      });
    }
  }

  group('収録問題数', () {
    const exam = ExamConfig(
      examId: 'hazmat4',
      name: '危険物取扱者',
      audience: Audience.adult,
      subjects: [
        SubjectConfig(subjectId: 'law', name: '法令', order: 1),
        SubjectConfig(subjectId: 'chem', name: '物理化学', order: 2),
      ],
      levels: [],
    );

    test('countBySubject は順序を保ち、0件の分野も出す', () {
      final pool = [_q('1', 'law'), _q('2', 'law'), _q('3', 'other')];
      expect(countBySubject(pool, order: ['law', 'chem']), [('law', 2), ('chem', 0), ('other', 1)]);
    });

    Future<void> pump(WidgetTester tester, List<Question> pool) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeQuestionsProvider.overrideWith((ref) async => pool),
            examConfigProvider.overrideWith((ref) async => exam),
          ],
          child: const MaterialApp(home: Scaffold(body: QuestionCountCard())),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('全体と分野ごとの件数を表示する', (tester) async {
      await pump(tester, [_q('1', 'law'), _q('2', 'law'), _q('3', 'chem')]);
      expect(find.text('全体 3問'), findsOneWidget);
      expect(find.text('法令'), findsOneWidget);
      expect(find.text('2問'), findsOneWidget);
      expect(find.text('物理化学'), findsOneWidget);
      expect(find.text('1問'), findsOneWidget);
    });

    testWidgets('0件でも崩れない', (tester) async {
      await pump(tester, const []);
      expect(find.text('問題データがありません。'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
