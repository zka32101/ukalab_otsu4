import 'package:app_common_kit/app_common_kit.dart' show ResultSummary;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otsu4/data/achievements_provider.dart';
import 'package:otsu4/data/answered_questions_store.dart';
import 'package:otsu4/data/combo_store.dart';
import 'package:otsu4/data/daily_answer_stats_store.dart';
import 'package:otsu4/data/feature_flags.dart';
import 'package:otsu4/data/history_store.dart';
import 'package:otsu4/data/mock_history_store.dart';
import 'package:otsu4/data/mock_wrong_store.dart';
import 'package:otsu4/data/progress_store.dart';
import 'package:otsu4/data/selected_level_store.dart';
import 'package:otsu4/data/srs_store.dart';
import 'package:otsu4/data/subject_stats_history_store.dart';
import 'package:otsu4/data/subject_stats_store.dart';
import 'package:otsu4/views/practice_session_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ukalab_core/achievements.dart';
import 'package:ukalab_core/daily_goal.dart';
import 'package:ukalab_core/ui.dart';
import 'package:ukalab_core/ukalab_core.dart';
import 'test_ads.dart';

// 新タイプの問題はテスト内の最小フィクスチャ（出荷する assets には入れない）。

Question _base(
  String id,
  QuestionType type, {
  String prompt = '',
  bool? answerBool,
  List<ClozeBlank> blanks = const [],
  String? clue,
  List<String> answers = const [],
  List<String> choices = const [],
}) =>
    Question(
      qid: id,
      examId: 'hazmat4',
      subjectId: 'law',
      topicId: 't',
      type: type,
      prompt: prompt,
      explanation: '$idの解説文',
      source: QuestionSource.original,
      sourceRef: '自作',
      contentVer: '1',
      answerBool: answerBool,
      blanks: blanks,
      clue: clue,
      answers: answers,
      choices: choices,
    );

Question _choice(String id) => Question(
      qid: id,
      examId: 'hazmat4',
      subjectId: 'law',
      topicId: 't',
      prompt: '選択式$id',
      choices: ['$idの正解', '$idの誤り'],
      answerIndex: 0,
      explanation: '$idの解説',
      source: QuestionSource.original,
      sourceRef: '自作',
      contentVer: '1',
    );

Question _tf() => _base('tf1', QuestionType.trueFalse, prompt: '指定数量以上の危険物は、貯蔵所で貯蔵する。', answerBool: true);

Question _cloze() => _base('cz1', QuestionType.cloze,
    prompt: 'ガソリンは第{{1}}類の危険物である。', blanks: const [ClozeBlank(id: 1, answers: ['四'])]);

Question _rev() => _base('rv1', QuestionType.reverseLookup,
    prompt: '次の説明に当てはまる用語は何か。',
    clue: '引火点が21度未満の第一石油類に属する液体',
    answers: const ['ガソリン'],
    choices: const ['ガソリン', '軽油', '灯油', '重油']);

List<Question> _mixed() => [_choice('c1'), _tf(), _cloze(), _rev()];

Future<List<Override>> _overrides(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  return (await tester.runAsync(() async {
    final coin = CoinService(store: InMemoryCoinStore());
    await coin.load();
    final progressService = ProgressService();
    await progressService.load();
    final srs = SrsService();
    await srs.load();
    final mockHistory = MockHistoryService();
    await mockHistory.load();
    final mockWrong = MockWrongService();
    await mockWrong.load();
    final subjectStats = SubjectStatsService();
    await subjectStats.load();
    final subjectStatsHistory = SubjectStatsHistoryService();
    await subjectStatsHistory.load();
    final selectedLevel = SelectedLevelService();
    await selectedLevel.load();
    final answered = AnsweredQuestionsService();
    await answered.load();
    final combo = ComboService();
    await combo.load();
    final daily = DailyAnswerStatsService();
    await daily.load();
    final studyNotes = await studyNotesOverrides('otsu4');
    final goal = await dailyGoalOverrides('otsu4');
    final unlock = await achievementUnlockOverrides('otsu4');
    return <Override>[
      coinServiceProvider.overrideWithValue(coin),
      progressServiceProvider.overrideWithValue(progressService),
      srsServiceProvider.overrideWithValue(srs),
      mockHistoryServiceProvider.overrideWithValue(mockHistory),
      mockWrongServiceProvider.overrideWithValue(mockWrong),
      subjectStatsServiceProvider.overrideWithValue(subjectStats),
      subjectStatsHistoryServiceProvider.overrideWithValue(subjectStatsHistory),
      selectedLevelServiceProvider.overrideWithValue(selectedLevel),
      answeredQuestionsServiceProvider.overrideWithValue(answered),
      comboServiceProvider.overrideWithValue(combo),
      dailyAnswerStatsServiceProvider.overrideWithValue(daily),
      achievementsOverride,
      stubAdGateOverride(),
      ...unlock,
      ...studyNotes,
      ...goal,
    ];
  }))!;
}

Future<ProviderContainer> _pump(
  WidgetTester tester,
  List<Question> pool, {
  required bool newTypesEnabled,
}) async {
  // 解答後は結果・解説・間違えた理由・「次へ」が縦に並ぶので、縦長の画面で試す。
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final overrides = await _overrides(tester);
  await tester.pumpWidget(ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: PracticeSessionView(
            pool: pool,
            emptyMessage: '問題がありません',
            newTypesEnabled: newTypesEnabled,
          ),
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(PracticeSessionView)));
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pumpAndSettle();
}

void main() {
  group('フラグ（既定 OFF）', () {
    test('既定は OFF で、模擬試験の許可タイプは core 既定の4タイプ', () {
      expect(kNewQuestionTypesEnabled, isFalse);
      expect(kMockExamAllowedTypes, defaultMockExamTypes);
      expect(kMockExamAllowedTypes.contains(QuestionType.trueFalse), isFalse);
      expect(kMockExamAllowedTypes.contains(QuestionType.cloze), isFalse);
      expect(kMockExamAllowedTypes.contains(QuestionType.reverseLookup), isFalse);
    });

    test('OFF: 新タイプは除かれ、選択式は順序もそのまま。ON: 新タイプも含む', () {
      expect(selectableQuestions(_mixed(), newTypesEnabled: false).map((q) => q.qid), ['c1']);
      expect(selectableQuestions([_choice('a'), _choice('b')], newTypesEnabled: false).map((q) => q.qid),
          ['a', 'b']);
      expect(selectableQuestions(_mixed(), newTypesEnabled: true).map((q) => q.qid),
          ['c1', 'tf1', 'cz1', 'rv1']);
      expect(withoutNewTypes(_mixed()).map((q) => q.qid), ['c1']);
    });

    test('模擬試験: プールに新タイプがあっても既定の許可タイプでは出ない', () {
      final level = LevelConfig(
          levelId: 'l', name: 'l', questionCount: 10, timeLimitSec: 600, passRule: const PassRule(totalPct: 70));
      final picked = pickMockExamQuestions(pool: _mixed(), level: level, allowedTypes: kMockExamAllowedTypes);
      expect(picked.map((q) => q.qid), ['c1']);
    });

    testWidgets('OFF: 出題画面に新タイプだけを渡しても出ない（空表示）', (tester) async {
      await _pump(tester, [_tf(), _cloze(), _rev()], newTypesEnabled: false);
      expect(find.text('問題がありません'), findsOneWidget);
      expect(find.byType(TrueFalseQuestionView), findsNothing);
    });

    testWidgets('OFF: 選択式との混在でも選択式だけが出る', (tester) async {
      await _pump(tester, _mixed(), newTypesEnabled: false);
      expect(find.text('選択式c1'), findsOneWidget);
      expect(find.byType(TrueFalseQuestionView), findsNothing);
      expect(find.byType(ClozeQuestionView), findsNothing);
      expect(find.byType(ReverseLookupQuestionView), findsNothing);
    });
  });

  group('履歴の自己申告補正', () {
    test('直近の不正解を正解に直し、原因を外す。正解済み・無い qid は変えない', () {
      final at = DateTime(2026, 10, 1);
      final recs = [
        ProgressRecord(qid: 'a', subjectId: 's', correct: false, at: at, cause: WrongCause.misread),
        ProgressRecord(qid: 'b', subjectId: 's', correct: false, at: at),
      ];
      final out = markLatestRecordCorrect(recs, 'a');
      expect(out[0].correct, isTrue);
      expect(out[0].cause, isNull);
      expect(out[1].correct, isFalse);
      expect(markLatestRecordCorrect(out, 'a'), same(out));
      expect(markLatestRecordCorrect(recs, 'zzz'), same(recs));
    });
  });

  group('演習（フラグ ON）', () {
    testWidgets('○×: 誤答は履歴に不正解で残り、解説が出る', (tester) async {
      final c = await _pump(tester, [_tf()], newTypesEnabled: true);
      expect(find.byType(TrueFalseQuestionView), findsOneWidget);
      await tester.tap(find.textContaining('誤り').first); // × を選ぶ（正解は○）
      await _settle(tester);
      final h = c.read(historyProvider);
      expect(h.length, 1);
      expect(h.single.qid, 'tf1');
      expect(h.single.correct, isFalse);
      expect(find.text('tf1の解説文'), findsOneWidget);

      await tester.tap(find.text('次へ'));
      await tester.pumpAndSettle();
      expect(find.byType(TrueFalseQuestionView), findsNothing); // 結果画面へ
    });

    testWidgets('空欄補充: 誤答 → 自己申告で履歴が正解に直る', (tester) async {
      final c = await _pump(tester, [_cloze()], newTypesEnabled: true);
      expect(find.byType(ClozeQuestionView), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'よん');
      await tester.pump();
      await tester.tap(find.text('解答する'));
      await _settle(tester);
      expect(c.read(historyProvider).single.correct, isFalse);

      await tester.tap(find.text('合っていた（自己申告）'));
      await _settle(tester);
      expect(c.read(historyProvider).single.correct, isTrue);
      expect(c.read(historyProvider).length, 1);
    });

    testWidgets('説明から用語（選択肢つき）: 正解を選ぶと正解で記録される', (tester) async {
      final c = await _pump(tester, [_rev()], newTypesEnabled: true);
      expect(find.byType(ReverseLookupQuestionView), findsOneWidget);
      await tester.tap(find.text('ガソリン'));
      await _settle(tester);
      expect(c.read(historyProvider).single.qid, 'rv1');
      expect(c.read(historyProvider).single.correct, isTrue);
    });
  });

  // 選択式は解答直後に session.current が次の問題へ進む。解説・正誤の色は「解答した問題」で描く。
  // 新タイプのフラグの有無に関わらず成り立つ。
  for (final flag in [false, true]) {
    testWidgets('選択式(フラグ$flag): 解答直後は解答した問題の解説と正誤で、次へで次の問題', (tester) async {
      await _pump(tester, [_choice('c1'), _choice('c2')], newTypesEnabled: flag);
      final firstId = find.text('選択式c1').evaluate().isNotEmpty ? 'c1' : 'c2';
      final otherId = firstId == 'c1' ? 'c2' : 'c1';

      await tester.tap(find.text('${firstId}の誤り')); // 不正解を選ぶ
      await _settle(tester);

      expect(find.text('選択式$firstId'), findsOneWidget);
      expect(find.text('選択式$otherId'), findsNothing);
      expect(find.text('${firstId}の解説'), findsOneWidget);
      expect(find.text('${otherId}の解説'), findsNothing);

      await tester.tap(find.text('次の問題'));
      await tester.pumpAndSettle();
      expect(find.text('選択式$otherId'), findsOneWidget);
      expect(find.text('${firstId}の解説'), findsNothing);
      expect(find.text('${otherId}の解説'), findsNothing); // 未回答なので解説は出ない
    });
  }

  testWidgets('選択式: 最後の問題でも、解答直後は結果画面でなく解説が出る', (tester) async {
    await _pump(tester, [_choice('c1')], newTypesEnabled: false);
    await tester.tap(find.text('c1の正解'));
    await _settle(tester);
    expect(find.text('c1の解説'), findsOneWidget);
    expect(find.byType(ResultSummary), findsNothing);

    await tester.tap(find.text('次の問題'));
    await tester.pumpAndSettle();
    expect(find.byType(ResultSummary), findsOneWidget);
  });
}
