import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otsu4/data/achievements_provider.dart';
import 'package:otsu4/data/answered_questions_store.dart';
import 'package:otsu4/data/combo_store.dart';
import 'package:otsu4/data/core_features.dart';
import 'package:otsu4/data/daily_answer_stats_store.dart';
import 'package:otsu4/data/exam_date_store.dart';
import 'package:otsu4/data/exam_repository.dart';
import 'package:otsu4/data/mock_history_store.dart';
import 'package:otsu4/data/mock_wrong_store.dart';
import 'package:otsu4/data/progress_store.dart';
import 'package:otsu4/data/review_schedule.dart';
import 'package:otsu4/widgets/oshi_growth_section.dart';
import 'package:otsu4/data/selected_level_store.dart';
import 'package:otsu4/data/srs_store.dart';
import 'package:otsu4/data/subject_stats_history_store.dart';
import 'package:otsu4/data/subject_stats_store.dart';
import 'package:otsu4/data/theme_store.dart';
import 'package:otsu4/views/home_view.dart';
import 'package:otsu4/views/mock_exam_view.dart';
import 'package:otsu4/views/mistake_note_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ukalab_core/achievements.dart';
import 'package:ukalab_core/daily_goal.dart';
import 'package:ukalab_core/reminder.dart';
import 'package:ukalab_core/ui.dart';
import 'package:ukalab_core/ukalab_core.dart';
import 'test_ads.dart';

ExamConfig _exam() => ExamConfig(
      examId: 'hazmat4',
      name: '危険物乙4',
      audience: Audience.adult,
      subjects: const [
        SubjectConfig(subjectId: 'law', name: '法令'),
        SubjectConfig(subjectId: 'physics_chem', name: '物理・化学'),
      ],
      levels: const [],
      examDates: const [],
    );

Question _q(String qid, String subject, {int answer = 0}) => Question(
      qid: qid,
      examId: 'hazmat4',
      subjectId: subject,
      topicId: 'topic-$qid',
      prompt: '問題文-$qid',
      choices: const ['正解の選択肢', '誤りの選択肢'],
      answerIndex: answer,
      explanation: '解説-$qid',
      source: QuestionSource.original,
      sourceRef: '自作',
      contentVer: '1',
    );

ProgressRecord _rec(String qid, DateTime at, {bool correct = true}) => ProgressRecord(
      qid: qid,
      subjectId: 'law',
      correct: correct,
      at: at,
      topicId: 'definition',
    );

Future<List<Override>> _overrides(
  WidgetTester tester, {
  List<ProgressRecord> history = const [],
  ProgressSnapshot? progress,
}) async {
  SharedPreferences.setMockInitialValues({
    if (history.isNotEmpty) 'ukalab_otsu4_history_v1': encodeHistory(history),
  });
  return (await tester.runAsync(() async {
    final coin = CoinService(store: InMemoryCoinStore());
    await coin.load();
    final progressService = ProgressService();
    await progressService.load();
    if (progress != null) await progressService.restore(progress);
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
    final examDateService = ExamDateService();
    await examDateService.setDate(null);
    final studyNotes = await studyNotesOverrides('otsu4');
    final goal = await dailyGoalOverrides('otsu4');
    final reminder = await reminderOverrides('otsu4');
    final theme = ThemeService();
    await theme.load();
    final unlock = await achievementUnlockOverrides('otsu4');
    final outfit = OutfitService(store: SharedPreferencesOutfitStore('otsu4'));
    await outfit.load();
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
      examDateServiceProvider.overrideWithValue(examDateService),
      themeServiceProvider.overrideWithValue(theme),
      achievementsOverride,
      ...unlock,
      outfitServiceProvider.overrideWithValue(outfit),
      entitlementServiceProvider.overrideWithValue(FakeEntitlementService()),
      stubAdGateOverride(),
      ...studyNotes,
      ...goal,
      ...reminder,
    ];
  }))!;
}

Future<void> _pumpHome(
  WidgetTester tester, {
  List<ProgressRecord> history = const [],
  ProgressSnapshot? progress,
  Size size = const Size(800, 4000),
  double textScale = 1.0,
  List<Override>? reuse,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final overrides = reuse ?? await _overrides(tester, history: history, progress: progress);
  rootBundle.evict(ExamRepository.assetPath);
  await tester.runAsync(() => const ExamRepository().load());
  await tester.pumpWidget(ProviderScope(
    key: UniqueKey(),
    overrides: [
      ...overrides,
      examConfigProvider.overrideWith((ref) async => _exam()),
    ],
    child: MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: const Scaffold(body: HomeView()),
    ),
  ));
  final container = ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
  await tester.runAsync(() => container.read(allQuestionsProvider.future));
  for (var i = 0; i < 100 && find.byType(HomeSection).evaluate().isEmpty; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump();
  }
  for (var i = 0; i < 10; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump();
  }
}

MistakeNoteEntry _note(String qid, DateTime missedAt) => MistakeNoteEntry(
      qid: qid,
      firstMissedAt: missedAt,
      lastMissedAt: missedAt,
      missCount: 1,
      overcome: false,
      topicId: 'definition',
      correctStreak: 0,
      lastAnsweredAt: missedAt,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('今日の復習: 復習予定(間違いノートから)', () {
    test('同期した問題が、間違えた翌日に期限になり、正解で段が進む', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(reviewScheduleProvider.notifier);
      final missed = DateTime(2026, 10, 10, 9);
      await notifier.sync([_note('q1', missed)]);
      expect(container.read(reviewScheduleProvider).single.stage, 0);
      // 翌日の 0 時から期限。
      final day = DateTime(2026, 10, 11, 8);
      expect(reviewSchedulerEngine.dueCount(container.read(reviewScheduleProvider), day), 1);
      await notifier.applyResult('q1', correct: true, now: day);
      final after = container.read(reviewScheduleProvider).single;
      expect(after.stage, 1);
      expect(reviewSchedulerEngine.dueCount([after], day), 0);
      // 保存されていて、読み直しても同じ。
      await notifier.reload();
      expect(container.read(reviewScheduleProvider).single.stage, 1);
    });

    test('復習予定に無い問題の結果は何も変えない', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(reviewScheduleProvider.notifier);
      await notifier.applyResult('none', correct: false, now: DateTime(2026, 10, 11));
      expect(container.read(reviewScheduleProvider), isEmpty);
    });

    test('キーは ukalab_otsu4_review_schedule で、バックアップの部品に登録されている', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(reviewScheduleProvider.notifier).sync([_note('q1', DateTime(2026, 10, 10))]);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('ukalab_otsu4_review_schedule'), contains('q1'));
    });

    testWidgets('ホーム: 期限の来た間違いを数え、「今日やること」に出る', (tester) async {
      final now = DateTime.now();
      await _pumpHome(tester, history: [_rec('q1', now.subtract(const Duration(days: 3)), correct: false)]);
      expect(find.byType(TodayReviewCard), findsOneWidget);
      expect(tester.widget<TodayReviewCard>(find.byType(TodayReviewCard)).dueCount, 1);
      expect(find.text('1問、見返せるよ'), findsOneWidget);
    });

    testWidgets('ホーム: 間違いが無ければ「おやすみ」表示で、始めるボタンは出ない', (tester) async {
      await _pumpHome(tester);
      expect(tester.widget<TodayReviewCard>(find.byType(TodayReviewCard)).dueCount, 0);
      expect(find.text('やってみる'), findsNothing);
    });

    testWidgets('ホーム: 「やってみる」で既存の間違いノートが開く', (tester) async {
      final now = DateTime.now();
      await _pumpHome(tester, history: [_rec('q1', now.subtract(const Duration(days: 3)), correct: false)]);
      await tester.tap(find.text('やってみる'));
      for (var i = 0; i < 100 && find.byType(MistakeNoteScreen).evaluate().isEmpty; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(MistakeNoteScreen), findsOneWidget);
    });
  });

  group('模擬試験の結果分析: 入力の作り方', () {
    test('分野は科目単位。未回答は不正解として数える', () {
      final picked = [_q('a', 'law'), _q('b', 'law'), _q('c', 'physics_chem', answer: 1)];
      final answers = <String, Object?>{'a': 0, 'b': 1};
      final out = mockExamAnswersFor(picked, answers);
      expect([for (final a in out) a.topicId], ['law', 'law', 'physics_chem']);
      expect([for (final a in out) a.correct], [true, false, false]);
    });

    for (final (width, scale) in [(320.0, 2.0), (800.0, 1.0)]) {
      testWidgets('分析カードは幅 $width・文字 $scale 倍でオーバーフローしない', (tester) async {
        tester.view.physicalSize = Size(width, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        final picked = [for (var i = 0; i < 6; i++) _q('l$i', 'law'), for (var i = 0; i < 4; i++) _q('p$i', 'physics_chem')];
        final answers = <String, Object?>{
          for (var i = 0; i < 6; i++) 'l$i': i < 2 ? 0 : 1,
          for (var i = 0; i < 4; i++) 'p$i': 0,
        };
        final exam = _exam();
        await tester.pumpWidget(MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              child: MockExamAnalysisCard(
                analysis: const MockExamAnalysisEngine().analyze(mockExamAnswersFor(picked, answers)),
                topicLabel: (id) => exam.subject(id)?.name ?? id,
              ),
            ),
          ),
        ));
        expect(tester.takeException(), isNull);
        expect(find.text('法令'), findsWidgets);
      });
    }
  });

  group('推しの成長演出', () {
    test('累計: 回答数は演習の累計、学習日数は履歴などの「学習した日」の合計(連続ではない)', () {
      final p = oshiGrowthProgressFor(
        progress: const ProgressSnapshot(answered: 12),
        records: [
          _rec('a', DateTime(2026, 10, 1, 9)),
          _rec('b', DateTime(2026, 10, 1, 20)),
          _rec('c', DateTime(2026, 10, 5, 9)),
        ],
        mockHistory: [MockHistoryEntry(at: DateTime(2026, 10, 9), score: 20, max: 35, passed: false)],
        dailyStats: [DailyAnswerStatsEntry(date: DateTime(2026, 10, 5), answered: 3, correct: 2)],
      );
      expect(p.totalAnswered, 12);
      expect(p.studyDays, 3);
    });

    testWidgets('ホーム: 成長の吹き出しは出ない(節目に届いていなければ祝福も出ない)', (tester) async {
      await _pumpHome(tester);
      expect(find.byType(OshiGrowthSection), findsOneWidget); // 祝福の見張り役は残す
      expect(find.byType(OshiGrowthBubble, skipOffstage: false), findsNothing);
      expect(find.byType(OshiGrowthCelebrationCard), findsNothing);
    });

    testWidgets('ホーム: 節目(10問)に届いていれば祝福を一度だけ出す', (tester) async {
      final overrides = await _overrides(tester, progress: const ProgressSnapshot(answered: 10));
      await _pumpHome(tester, reuse: overrides);
      expect(find.byType(OshiGrowthCelebrationCard), findsOneWidget);
      await tester.tap(find.byType(FilledButton).last);
      // 推しのアニメーションが続くので pumpAndSettle は使わない。
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(OshiGrowthCelebrationCard), findsNothing);
      // 作り直しても、同じ節目はもう祝わない。
      await _pumpHome(tester, reuse: overrides);
      expect(find.byType(OshiGrowthCelebrationCard), findsNothing);
    });
  });

  group('ホームのレイアウト(今日の復習・成長の見張り役を含む)', () {
    for (final (width, scale) in [(320.0, 1.0), (320.0, 2.0)]) {
      testWidgets('幅 $width・文字 $scale 倍でオーバーフローしない', (tester) async {
        final now = DateTime.now();
        await _pumpHome(
          tester,
          size: Size(width, 6000),
          textScale: scale,
          history: [_rec('q1', now.subtract(const Duration(days: 3)), correct: false)],
        );
        expect(find.byType(TodayReviewCard), findsOneWidget);
        expect(find.byType(OshiGrowthBubble, skipOffstage: false), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('3つのグループの構成は変わらず、今日の復習は「今日やること」・成長は「記録」に入る', (tester) async {
      await _pumpHome(tester);
      expect(find.text('今日やること'), findsOneWidget);
      expect(find.text('記録'), findsOneWidget);
      expect(find.text('試験の準備'), findsOneWidget);
      final today = find.ancestor(
          of: find.byType(TodayReviewCard), matching: find.byType(HomeSection));
      final record = find.ancestor(
          of: find.byType(OshiGrowthSection), matching: find.byType(HomeSection));
      expect(today, findsOneWidget);
      expect(record, findsOneWidget);
      expect(tester.widget<HomeSection>(today).title, '今日やること');
      expect(tester.widget<HomeSection>(record).title, '記録');
    });
  });
}
