import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otsu4/data/history_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ukalab_core/answer_feedback.dart';
import 'package:ukalab_core/ukalab_core.dart';

Question _q(String qid) => Question(
      qid: qid,
      examId: 'otsu4',
      subjectId: 'law',
      topicId: 'ch1',
      prompt: '問題$qidの文',
      choices: const ['正解の選択肢', '誤りの選択肢'],
      answerIndex: 0,
      explanation: '解説$qid',
      source: QuestionSource.original,
      sourceRef: '自作',
      contentVer: '1',
    );

/// 解答後の画面と同じ組み合わせ（履歴の記録 + AnswerFeedbackPanel）を再現する小さな画面。
class _Host extends ConsumerStatefulWidget {
  const _Host();
  @override
  ConsumerState<_Host> createState() => _HostState();
}

class _HostState extends ConsumerState<_Host> {
  final q = _q('a');
  int? selected;

  @override
  Widget build(BuildContext context) => Column(children: [
        for (var i = 0; i < q.choices.length; i++)
          TextButton(
            onPressed: () {
              setState(() => selected = i);
              ref.read(historyProvider.notifier).record(q, correct: i == q.answerIndex);
            },
            child: Text(q.choices[i]),
          ),
        if (selected != null) // 本体も解答後(_answered)にだけ置く
          AnswerFeedbackPanel(
          question: q,
          selectedIndex: selected,
          onCause: (c) => ref.read(historyProvider.notifier).setCause(q.qid, c),
        ),
      ]);
}

Future<ProviderContainer> _pump(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final container = ProviderContainer();
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: const MaterialApp(home: Scaffold(body: _Host())),
  ));
  await tester.pumpAndSettle();
  return container;
}

Future<void> _tap(WidgetTester tester, String text) async {
  await tester.runAsync(() async {
    await tester.tap(find.text(text));
    await Future<void>.delayed(const Duration(milliseconds: 200));
  });
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('不正解だと原因パネルが出て、原因を選ぶと履歴に付く', (tester) async {
    final c = await _pump(tester);
    expect(find.text('知識不足'), findsNothing);
    await _tap(tester, '誤りの選択肢');
    expect(find.text('知識不足'), findsOneWidget);
    expect(c.read(historyProvider).single.cause, isNull);
    await _tap(tester, '知識不足');
    final rec = c.read(historyProvider).single;
    expect(rec.correct, isFalse);
    expect(rec.cause, WrongCause.knowledge);
  });

  testWidgets('正解では原因パネルの中身は出ない', (tester) async {
    final c = await _pump(tester);
    await _tap(tester, '正解の選択肢');
    expect(find.text('知識不足'), findsNothing);
    expect(c.read(historyProvider).single.correct, isTrue);
  });

  test('setCause は永続化され、再読み込みで復元される', () async {
    SharedPreferences.setMockInitialValues({});
    final c1 = ProviderContainer();
    await c1.read(historyProvider.notifier).record(_q('a'), correct: false);
    await c1.read(historyProvider.notifier).setCause('a', WrongCause.misread);
    c1.dispose();
    final c2 = ProviderContainer();
    addTearDown(c2.dispose);
    c2.read(historyProvider);
    await c2.read(historyProvider.notifier).setCause('zzz', null); // _loaded を待つ
    expect(c2.read(historyProvider).single.cause, WrongCause.misread);
  });
}
