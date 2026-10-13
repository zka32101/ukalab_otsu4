import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otsu4/data/achievements_provider.dart';
import 'package:otsu4/data/answered_questions_store.dart';
import 'package:otsu4/data/combo_store.dart';
import 'package:otsu4/data/daily_answer_stats_store.dart';
import 'package:otsu4/data/data_parts.dart';
import 'package:otsu4/data/core_features.dart';
import 'package:otsu4/data/exam_date_store.dart';
import 'package:otsu4/data/exam_repository.dart';
import 'package:otsu4/data/mistake_notes.dart';
import 'package:otsu4/data/mock_history_store.dart';
import 'package:otsu4/data/mock_wrong_store.dart';
import 'package:otsu4/data/oshi_recap.dart';
import 'package:otsu4/data/progress_store.dart';
import 'package:otsu4/data/selected_level_store.dart';
import 'package:otsu4/data/srs_store.dart';
import 'package:otsu4/data/theme_store.dart';
import 'package:otsu4/data/subject_stats_history_store.dart';
import 'package:otsu4/data/subject_stats_store.dart';
import 'package:otsu4/views/exam_prep_entry.dart';
import 'package:otsu4/views/home_view.dart';
import 'package:otsu4/views/mistake_note_screen.dart';
import 'package:otsu4/views/settings_view.dart';
import 'package:otsu4/views/practice_session_view.dart';
import 'package:otsu4/widgets/oshi_home_cards.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ukalab_core/achievements.dart';
import 'package:ukalab_core/daily_goal.dart';
import 'package:ukalab_core/reminder.dart';
import 'package:ukalab_core/ui.dart';
import 'package:ukalab_core/ukalab_core.dart';

// 2026-10-14 は水曜。月曜始まりの今週は 10/12〜10/18。
final _now = DateTime(2026, 10, 14, 12);

Question _q(String qid, {String topic = 'definition'}) => Question(
      qid: qid,
      examId: 'hazmat4',
      subjectId: 'law',
      topicId: topic,
      prompt: '問題文-$qid',
      choices: const ['正解の選択肢', '誤りの選択肢'],
      answerIndex: 0,
      explanation: '解説-$qid',
      source: QuestionSource.original,
      sourceRef: '自作',
      contentVer: '1',
    );

ExamConfig _exam() => ExamConfig(
      examId: 'hazmat4',
      name: '危険物乙4',
      audience: Audience.adult,
      subjects: const [
        SubjectConfig(subjectId: 'law', name: '法令'),
      ],
      levels: const [],
      examDates: const [],
    );

ProgressRecord _rec(String qid, DateTime at, {bool correct = true}) => ProgressRecord(
      qid: qid,
      subjectId: 'law',
      correct: correct,
      at: at,
      topicId: 'definition',
    );

/// 出題画面(PracticeSessionView)が使う保存先を、すべて端末内モックで用意する。
Future<List<Override>> _overrides(
  WidgetTester tester, {
  List<ProgressRecord> history = const [],
  DateTime? examDate,
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
    await examDateService.setDate(examDate);
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
      ...studyNotes,
      ...goal,
      ...reminder,
    ];
  }))!;
}

/// 履歴の読み込み(実際の非同期)を待ってから描画に反映する。
Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
  await tester.pump();
  await tester.pump();
}

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  List<ProgressRecord> history = const [],
  DateTime? examDate,
  ProgressSnapshot? progress,
}) async {
  final overrides =
      await _overrides(tester, history: history, examDate: examDate, progress: progress);
  await tester.pumpWidget(ProviderScope(
    overrides: overrides,
    child: MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child))),
  ));
  await _settle(tester);
}

/// 問題データ(アセット)の読み込み後に間違いノートが開くのを待つ。
Future<void> _waitForNoteScreen(WidgetTester tester) async {
  for (var i = 0; i < 100 && find.byType(MistakeNoteScreen).evaluate().isEmpty; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('入力の作り方(推しの一言)', () {
    test('履歴も試験日もなければ、最小の状況になる', () {
      final c = oshiMessageContextFor(
          records: const [], progress: const ProgressSnapshot(), now: _now);
      expect(c.daysSinceLastStudy, isNull);
      expect(c.streakDays, 0);
      expect(c.todayAnswered, 0);
      expect(c.todayCorrectRate, isNull);
      expect(c.examDaysLeft, isNull);
      expect(c.hasWeakTopics, isFalse);
    });

    test('今日の解答数・正答率・最終学習からの日数・連続日数・試験日・苦手が反映される', () {
      final records = [
        _rec('a', DateTime(2026, 10, 13, 9)),
        _rec('b', DateTime(2026, 10, 14, 9)),
        _rec('c', DateTime(2026, 10, 14, 10)),
        _rec('d', DateTime(2026, 10, 14, 11), correct: false),
      ];
      final c = oshiMessageContextFor(
        records: records,
        progress: ProgressSnapshot(streakDays: 2, lastStudyDate: DateTime(2026, 10, 14)),
        now: _now,
        examDate: DateTime(2026, 11, 13),
      );
      expect(c.daysSinceLastStudy, 0);
      expect(c.streakDays, 2);
      expect(c.todayAnswered, 3);
      expect(c.todayCorrectRate, closeTo(2 / 3, 1e-9));
      expect(c.examDaysLeft, 30);
      expect(c.hasWeakTopics, isTrue);
    });

    test('久しぶりのときは古い連続日数を使わない。過ぎた試験日は渡さない', () {
      final c = oshiMessageContextFor(
        records: [_rec('a', DateTime(2026, 10, 9, 9))],
        progress: ProgressSnapshot(streakDays: 5, lastStudyDate: DateTime(2026, 10, 9)),
        now: _now,
        examDate: DateTime(2026, 10, 1),
      );
      expect(c.daysSinceLastStudy, 5);
      expect(c.streakDays, 0);
      expect(c.examDaysLeft, isNull);
    });

    test('履歴が空でも、連続学習の最終学習日があれば最終学習からの日数に使う', () {
      final c = oshiMessageContextFor(
        records: const [],
        progress: ProgressSnapshot(streakDays: 3, lastStudyDate: DateTime(2026, 10, 13)),
        now: _now,
      );
      expect(c.daysSinceLastStudy, 1);
      expect(c.streakDays, 3);
    });

    test('分野の表示名は、その問題の科目名になる(無ければID)', () {
      final label = topicLabelFor([_q('a')], (id) => id == 'law' ? '法令' : null);
      expect(label('definition'), '法令');
      expect(label('unknown'), 'unknown');
    });
  });

  group('推しの一言(ホーム)', () {
    testWidgets('履歴なし: あいさつが出る', (tester) async {
      await _pump(tester, OshiMessageCard(clock: () => _now));
      expect(find.byType(OshiMessageBubble), findsOneWidget);
      final greetings = OshiMessageStrings.ja.variants(OshiSituation.greeting);
      expect(greetings.any((g) => find.text(g).evaluate().isNotEmpty), isTrue);
    });

    testWidgets('履歴あり(5日空いた): おかえりの一言が出る', (tester) async {
      await _pump(tester, OshiMessageCard(clock: () => _now),
          history: [_rec('a', DateTime(2026, 10, 9, 9))]);
      final texts = OshiMessageStrings.ja.variants(OshiSituation.welcomeBack);
      expect(texts.any((t) => find.text(t).evaluate().isNotEmpty), isTrue);
    });

    testWidgets('今日たくさん解いた: 達成の一言が出る(久しぶりにはならない)', (tester) async {
      await _pump(tester, OshiMessageCard(clock: () => _now), history: [
        for (var i = 0; i < 4; i++) _rec('q$i', DateTime(2026, 10, 14, 9, i)),
      ]);
      final texts = OshiMessageStrings.ja.variants(OshiSituation.praise);
      expect(texts.any((t) => find.text(t).evaluate().isNotEmpty), isTrue);
    });
  });

  group('週間ふりかえり(ホーム)', () {
    const strings = WeeklyRecapStrings.ja;

    testWidgets('今週解いていれば、できたことが出る', (tester) async {
      await _pump(
        tester,
        WeeklyRecapSection(exam: _exam(), questions: [_q('a')], clock: () => _now),
        history: [
          _rec('a', DateTime(2026, 10, 12, 9)),
          _rec('b', DateTime(2026, 10, 14, 9)),
          _rec('c', DateTime(2026, 10, 14, 10), correct: false),
        ],
      );
      expect(find.text(strings.title), findsOneWidget);
      expect(find.text(strings.emptyTitle), findsNothing);
      expect(find.textContaining('3${strings.questionsUnit}'), findsWidgets);
    });

    testWidgets('履歴なしの週(0件)は、責めずに穏やかな表示', (tester) async {
      await _pump(tester,
          WeeklyRecapSection(exam: _exam(), questions: const [], clock: () => _now));
      expect(find.text(strings.emptyTitle), findsOneWidget);
    });

    testWidgets('先週だけ解いていた場合も、今週は0件として穏やかに表示する', (tester) async {
      await _pump(
        tester,
        WeeklyRecapSection(exam: _exam(), questions: [_q('a')], clock: () => _now),
        history: [_rec('a', DateTime(2026, 10, 8, 9))],
      );
      expect(find.text(strings.emptyTitle), findsOneWidget);
    });
  });

  group('間違いノート', () {
    const strings = MistakeNoteStrings.ja;

    Future<void> pumpScreen(WidgetTester tester, MistakeNoteStore store,
        {List<Question>? questions, List<ProgressRecord> history = const []}) async {
      final overrides = await _overrides(tester, history: history);
      await tester.pumpWidget(ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          home: MistakeNoteScreen(
            exam: _exam(),
            questions: questions ?? [_q('q1'), _q('q2')],
            store: store,
          ),
        ),
      ));
      await _settle(tester);
    }

    testWidgets('間違えた問題が一覧に出る(正解だけの問題は出ない)', (tester) async {
      final store = InMemoryMistakeNoteStore();
      await pumpScreen(tester, store, history: [
        _rec('q1', DateTime(2026, 10, 14, 9), correct: false),
        _rec('q2', DateTime(2026, 10, 14, 10)),
      ]);
      expect(find.text('問題文-q1'), findsOneWidget);
      expect(find.text('問題文-q2'), findsNothing);
      expect(find.text(strings.retry), findsOneWidget);
      // 履歴から取り込んだ内容が保存される
      expect((await store.read()).map((e) => e.qid), ['q1']);
    });

    testWidgets('履歴なし: これからが空のメッセージ', (tester) async {
      await pumpScreen(tester, InMemoryMistakeNoteStore());
      expect(find.text(strings.emptyUpcomingTitle), findsOneWidget);
    });

    testWidgets('出題データに無い問題は出さない', (tester) async {
      await pumpScreen(tester, InMemoryMistakeNoteStore(),
          history: [_rec('gone', DateTime(2026, 10, 14, 9), correct: false)]);
      expect(find.text(strings.retry), findsNothing);
      expect(find.text(strings.emptyUpcomingTitle), findsOneWidget);
    });

    testWidgets('解き直す: 既存の出題画面がその1問で開き、解いて戻るとノートに反映される',
        (tester) async {
      final store = InMemoryMistakeNoteStore();
      await pumpScreen(tester, store,
          // 出題画面は現在時刻で記録するため、間違いは十分過去の日時にしておく。
          history: [_rec('q1', DateTime(2020, 1, 1, 9), correct: false)]);

      await tester.tap(find.text(strings.retry));
      await tester.pumpAndSettle();
      expect(find.byType(PracticeSessionView), findsOneWidget);
      final view = tester.widget<PracticeSessionView>(find.byType(PracticeSessionView));
      expect(view.pool.map((q) => q.qid), ['q1']);
      expect(find.text('問題文-q1'), findsWidgets);

      // 正解すると通常の履歴に記録され(出題画面の既存の動き)、戻ったときにノートへ取り込まれる
      await tester.tap(find.text('正解の選択肢'));
      for (var i = 0; i < 5; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      await _settle(tester);
      expect(find.byType(PracticeSessionView), findsNothing);
      expect(find.text('問題文-q1'), findsOneWidget);
      final saved = (await tester.runAsync(store.read))!;
      expect(saved.single.qid, 'q1');
      expect(saved.single.correctStreak, 1);
      expect(saved.single.overcome, isFalse);
    });
  });

  group('ホーム・設定の入口', () {
    Future<void> pumpApp(WidgetTester tester, Widget page) async {
      final overrides = await _overrides(tester);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          ...overrides,
          // 試験定義は固定のものを返す(設定の入口は exam が読めてから出る)。
          examConfigProvider.overrideWith((ref) async => _exam()),
        ],
        child: MaterialApp(home: Scaffold(body: page)),
      ));
      // 問題データ(アセット)を先に読み込んでおく(開く操作で待たされないように)。
      final container = ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
      await tester.runAsync(() => container.read(allQuestionsProvider.future));
      // 試験定義(アセット)の読み込みを待つ。
      for (var i = 0; i < 20; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
        await tester.pump();
      }
    }

    testWidgets('ホーム: 推しの一言・週間ふりかえり・間違いノートのカードが出て、ノートを開ける', (tester) async {
      await pumpApp(tester, const HomeView());
      expect(find.byType(OshiMessageBubble), findsOneWidget);
      // ホームの分類分けで「記録」が下に移ったため、スクロールして探す。
      await tester.scrollUntilVisible(find.byType(WeeklyRecapCard), 300,
          scrollable: find.byType(Scrollable).first);
      expect(find.byType(WeeklyRecapCard), findsOneWidget);
      // 推しの一言と二重にならないよう、ふりかえりの message スロットは使わない
      expect(tester.widget<WeeklyRecapCard>(find.byType(WeeklyRecapCard)).message, isNull);
      await tester.scrollUntilVisible(find.text('間違いノート'), -300,
          scrollable: find.byType(Scrollable).first);
      await tester.tap(find.text('間違いノート'));
      await _waitForNoteScreen(tester);
      expect(find.byType(MistakeNoteScreen), findsOneWidget);
    });

    testWidgets('設定: 間違いノートのタイルから開ける', (tester) async {
      await pumpApp(tester, const SettingsView());
      // 遅延ビルドの一覧なので、見つかるまで少しずつスクロールする。
      for (var i = 0; i < 40 && find.text('間違いノート').evaluate().isEmpty; i++) {
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -300));
        await tester.pump();
      }
      await tester.ensureVisible(find.text('間違いノート'));
      await tester.pump();
      await tester.tap(find.text('間違いノート'));
      await _waitForNoteScreen(tester);
      expect(find.byType(MistakeNoteScreen), findsOneWidget);
    });
  });

  group('間違いノート: バックアップ・リセット', () {
    testWidgets('データの管理に mistakeNotes が登録され、書き出し・リセット・読み込みができる',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      late WidgetRef wref;
      await tester.pumpWidget(ProviderScope(
        child: Consumer(builder: (context, ref, _) {
          wref = ref;
          return const SizedBox.shrink();
        }),
      ));
      final part = otsu4DataParts.firstWhere((p) => p.id == 'mistakeNotes');
      final entry = MistakeNoteEntry(
        qid: 'q1',
        firstMissedAt: DateTime(2026, 10, 14),
        lastMissedAt: DateTime(2026, 10, 14),
        missCount: 1,
        overcome: false,
        topicId: 'definition',
        correctStreak: 0,
        lastAnsweredAt: DateTime(2026, 10, 14),
      );
      await tester.runAsync(() async {
        await mistakeNoteStore.write([entry]);
        final exported = await part.export(wref);
        expect(exported, isA<List>());
        expect((exported as List), hasLength(1));

        await part.reset(wref);
        expect(await mistakeNoteStore.read(), isEmpty);

        await part.restore(wref, exported);
        final restored = await mistakeNoteStore.read();
        expect(restored.single.qid, 'q1');
        expect(restored.single.topicId, 'definition');
      });
    });
  });

  test('アプリ側の追加文言に、責める表現・他人比較を含めない', () {
    const texts = '間違いノート間違えた問題を見返して、解き直せます。解き直す問題が見つかりません。';
    for (final w in ['サボ', '遅れ', 'しないと', 'ダメ', '焦', '急が', '少な', '減', '先週', '前週', '比べ', 'ワースト', 'また間違']) {
      expect(texts.contains(w), isFalse, reason: w);
    }
  });
  group('ホーム: 分類分け(今日やること/記録/試験の準備)', () {
    Future<List<Override>> pumpHome(
      WidgetTester tester, {
      DateTime? examDate,
      Size size = const Size(800, 4000),
      double textScale = 1.0,
      List<Override>? reuse,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final overrides = reuse ?? await _overrides(tester, examDate: examDate);
      // 試験定義(アセット)を先に読んでおく(テスト間でも確実に読み込み完了させる)。
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
      return overrides;
    }

    testWidgets('3つの見出しが表示され、乙4に無い分類(道具・体験ラボ・設定)は作らない', (tester) async {
      await pumpHome(tester);
      expect(find.text('今日やること'), findsOneWidget);
      expect(find.text('記録'), findsOneWidget);
      expect(find.text('試験の準備'), findsOneWidget);
      for (final t in ['道具', '体験ラボ', '設定・その他']) {
        expect(find.text(t), findsNothing);
      }
      // 初回は全て展開。
      expect(find.byType(StudyReminderCard), findsOneWidget);
      expect(find.byType(WeeklyRecapCard), findsOneWidget);
      expect(find.byType(CoreFeaturesCard), findsOneWidget);
      expect(find.text('出題科目'), findsOneWidget);
    });

    testWidgets('既存の入口: 推し・一言・カウントダウンが残り、間違いノートは1か所で開ける', (tester) async {
      await pumpHome(tester, examDate: DateTime.now().add(const Duration(days: 30)));
      expect(find.byType(OshiMessageBubble), findsOneWidget);
      expect(find.byType(ExamCountdownSection), findsOneWidget);
      // 試験日カード(日数表示)は examDate があるときだけ出る。
      expect(find.byIcon(Icons.event_outlined), findsWidgets);
      expect(find.text('間違いノート'), findsOneWidget);
      await tester.tap(find.byType(HomeMenuTile));
      await _waitForNoteScreen(tester);
      expect(find.byType(MistakeNoteScreen), findsOneWidget);
    });

    testWidgets('試験日が未設定なら試験日カードは出ない(条件付き表示の維持)', (tester) async {
      await pumpHome(tester);
      expect(find.byIcon(Icons.event_outlined), findsNothing);
    });

    testWidgets('折りたたみの開閉と保存', (tester) async {
      final overrides = await pumpHome(tester);
      expect(find.byType(CoreFeaturesCard), findsOneWidget);
      await tester.tap(find.text('試験の準備'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(CoreFeaturesCard), findsNothing);
      expect(find.text('試験の準備'), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('ukalab_otsu4_home_section_exam'), isFalse);
      expect(prefs.getBool('ukalab_otsu4_home_section_today'), isNull);
      // 作り直しても畳んだまま。
      await pumpHome(tester, reuse: overrides);
      expect(find.byType(CoreFeaturesCard), findsNothing);
      // 開き直すと戻る。
      await tester.tap(find.text('試験の準備'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(CoreFeaturesCard), findsOneWidget);
      expect(prefs.getBool('ukalab_otsu4_home_section_exam'), isTrue);
    });

    testWidgets('狭い幅+大きい文字でもオーバーフローしない', (tester) async {
      await pumpHome(
        tester,
        examDate: DateTime.now().add(const Duration(days: 30)),
        size: const Size(320, 640),
        textScale: 2.0,
      );
      expect(tester.takeException(), isNull);
      for (var i = 0; i < 30; i++) {
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -300));
        await tester.pump();
      }
      expect(tester.takeException(), isNull);
    });
  });
}
