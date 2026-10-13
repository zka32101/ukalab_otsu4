import 'package:app_common_kit/app_common_kit.dart';
import 'package:app_common_kit/hands_free_tts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otsu4/data/achievements_provider.dart';
import 'package:otsu4/data/answered_questions_store.dart';
import 'package:otsu4/data/daily_answer_stats_store.dart';
import 'package:otsu4/data/history_store.dart';
import 'package:otsu4/data/mistake_notes.dart';
import 'package:otsu4/data/progress_store.dart';
import 'package:otsu4/data/selected_level_store.dart';
import 'package:otsu4/data/srs_store.dart';
import 'package:otsu4/data/subject_stats_history_store.dart';
import 'package:otsu4/data/subject_stats_store.dart';
import 'package:otsu4/views/nagara_settings_section.dart';
import 'package:otsu4/views/nagara_study_view.dart';
import 'package:otsu4/views/study_tools_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ukalab_core/daily_goal.dart';
import 'package:ukalab_core/ui.dart';
import 'package:ukalab_core/ukalab_core.dart';

Question _q(String qid) => Question(
      qid: qid,
      examId: 'hazmat4',
      subjectId: 'law',
      topicId: 'definition',
      prompt: '問題文-$qid',
      choices: ['正解-$qid', '誤り-$qid'],
      answerIndex: 0,
      explanation: '解説-$qid',
      source: QuestionSource.original,
      sourceRef: '自作',
      contentVer: '1',
    );

Future<List<Override>> _overrides(
  WidgetTester tester,
  FakeSpeechBackend speech, {
  HandsFreeStore? store,
  HandsFreeSettings? settings,
}) async {
  SharedPreferences.setMockInitialValues({});
  final s = store ?? InMemoryHandsFreeStore();
  if (settings != null) await s.write(settings.toJson());
  return (await tester.runAsync(() async {
    final coin = CoinService(store: InMemoryCoinStore());
    await coin.load();
    final progress = ProgressService();
    await progress.load();
    final srs = SrsService();
    await srs.load();
    final subjectStats = SubjectStatsService();
    await subjectStats.load();
    final subjectStatsHistory = SubjectStatsHistoryService();
    await subjectStatsHistory.load();
    final answered = AnsweredQuestionsService();
    await answered.load();
    final daily = DailyAnswerStatsService();
    await daily.load();
    final goal = await dailyGoalOverrides('otsu4');
    final selectedLevel = SelectedLevelService();
    await selectedLevel.load();
    return <Override>[
      coinServiceProvider.overrideWithValue(coin),
      progressServiceProvider.overrideWithValue(progress),
      srsServiceProvider.overrideWithValue(srs),
      subjectStatsServiceProvider.overrideWithValue(subjectStats),
      subjectStatsHistoryServiceProvider.overrideWithValue(subjectStatsHistory),
      answeredQuestionsServiceProvider.overrideWithValue(answered),
      dailyAnswerStatsServiceProvider.overrideWithValue(daily),
      selectedLevelServiceProvider.overrideWithValue(selectedLevel),
      achievementsOverride,
      ...goal,
      handsFreeStoreProvider.overrideWithValue(s),
      speechBackendProvider.overrideWithValue(speech),
    ];
  }))!;
}

Future<ProviderContainer> _pump(
  WidgetTester tester,
  Widget home,
  FakeSpeechBackend speech, {
  HandsFreeSettings settings = const HandsFreeSettings(thinkSeconds: 1, betweenSeconds: 0),
  HandsFreeStore? store,
}) async {
  final overrides = await _overrides(tester, speech, store: store, settings: settings);
  final container = ProviderContainer(overrides: overrides);
  addTearDown(container.dispose);
  // 実アプリと同じく、画面を出す前に設定を読み込む(main.dart)。
  await tester.runAsync(() => container.read(handsFreeProvider.notifier).load());
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp(home: home),
  ));
  return container;
}

/// 読み上げ(非同期)とタイマーを少しずつ進める。
Future<void> _advance(WidgetTester tester, int seconds) async {
  for (var i = 0; i < seconds * 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
  await tester.pump();
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('入口', () {
    testWidgets('学習ツール一覧の「ながら学習」から、ながらセッションが開く', (tester) async {
      final speech = FakeSpeechBackend();
      await _pump(tester, const StudyToolsView(), speech);
      await tester.scrollUntilVisible(find.text('ながら学習'), 200, scrollable: find.byType(Scrollable).first);
      await tester.tap(find.text('ながら学習'));
      await tester.pump();
      // 問題データ(アセット)の読み込みを待つ。
      for (var i = 0; i < 100 && find.byType(NagaraSessionView).evaluate().isEmpty; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(NagaraSessionView), findsOneWidget);
      expect(speech.spoken, isNotEmpty);
      // 画面を離れて止める(タイマーを残さない)。
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('問題が無いときは空の案内になる', (tester) async {
      await _pump(tester, const NagaraStudyView(pool: []), FakeSpeechBackend());
      await _settle(tester);
      expect(find.byType(NagaraSessionView), findsNothing);
      expect(find.text('出題できる問題がまだありません。'), findsOneWidget);
    });
  });

  group('設定', () {
    testWidgets('項目の変更がキットの Store に保存され、読み直しても反映される', (tester) async {
      final store = InMemoryHandsFreeStore();
      final container = await _pump(
        tester,
        const Scaffold(body: SingleChildScrollView(child: NagaraSettingsSection())),
        FakeSpeechBackend(),
        settings: const HandsFreeSettings(),
        store: store,
      );
      // 有効にするまで、詳細の設定は出ない。
      expect(find.text('考える時間'), findsNothing);
      await tester.tap(find.byType(SwitchListTile).first);
      await tester.pump();
      expect(container.read(handsFreeProvider).enabled, isTrue);
      expect(find.text('考える時間'), findsOneWidget);
      expect(find.text('次の問題までの間'), findsOneWidget);
      expect(find.text('自動で次へ進む'), findsOneWidget);

      await tester.tap(find.text('8 秒'));
      await tester.pump();
      await tester.tap(find.text('3 秒').last);
      await tester.pump();
      await tester.tap(find.widgetWithText(SwitchListTile, '自動で次へ進む'));
      await tester.pump();
      await tester.tap(find.widgetWithText(SwitchListTile, '解説を読み上げる'));
      await tester.pump();

      final s = container.read(handsFreeProvider);
      expect(s.thinkSeconds, 8);
      expect(s.betweenSeconds, 3);
      expect(s.autoAdvance, isFalse);
      expect(s.speakExplanation, isFalse);

      final saved = (await tester.runAsync(store.read))!;
      final reloaded = HandsFreeSettings.fromJson(saved);
      expect(reloaded, s);
    });

    testWidgets('設定した「考える間」がセッションに反映される(5秒では答えを読まず、8秒を待つ)', (tester) async {
      final speech = FakeSpeechBackend();
      await _pump(
        tester,
        NagaraStudyView(pool: [_q('a')]),
        speech,
        settings: const HandsFreeSettings(thinkSeconds: 8, betweenSeconds: 1),
      );
      await _settle(tester);
      expect(speech.spoken.length, 1); // 問題だけ
      await _advance(tester, 5);
      expect(speech.spoken.length, 1);
      await _advance(tester, 4);
      expect(speech.spoken.length, 2); // 答えと解説
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('履歴への記録', () {
    Future<void> tapChoice(WidgetTester tester, bool correct) async {
      final prompt = find.textContaining('問題文-');
      final qid = (tester.widget<Text>(prompt.first).data ?? '').replaceFirst('問題文-', '');
      await tester.tap(find.text('${correct ? '正解' : '誤り'}-$qid').first);
      await tester.pump();
    }

    Future<ProviderContainer> start(WidgetTester tester, int n) async {
      final container = await _pump(
        tester,
        NagaraStudyView(pool: [for (var i = 0; i < n; i++) _q('q$i')]),
        FakeSpeechBackend(),
        settings: const HandsFreeSettings(thinkSeconds: 10, betweenSeconds: 0),
      );
      await _settle(tester);
      return container;
    }

    Future<List<ProgressRecord>> history(WidgetTester tester, ProviderContainer c) async {
      await tester.runAsync(() => c.read(historyProvider.notifier).ready);
      await tester.pump();
      return c.read(historyProvider);
    }

    testWidgets('正答・誤答のタップが、1問ごとにその場で履歴に載る(二重に載らない)', (tester) async {
      final container = await start(tester, 2);
      await tapChoice(tester, false);
      var h = await history(tester, container);
      expect(h.map((r) => r.correct).toList(), [false]);
      expect(container.read(dailyAnswerStatsProvider).isNotEmpty, isTrue);

      await _advance(tester, 1);
      await tapChoice(tester, true);
      h = await history(tester, container);
      expect(h.map((r) => r.correct).toList(), [false, true]);

      // 終わっても増えない。間違いノートの元データは誤答の1件。
      await _advance(tester, 2);
      expect(find.text('おつかれさまでした'), findsOneWidget);
      h = await history(tester, container);
      expect(h.length, 2);
      expect(mistakeNoteEngine.update(const [], h).length, 1);
    });

    testWidgets('終了ボタンで抜けても、解答済みの分は残る', (tester) async {
      final container = await start(tester, 3);
      await tapChoice(tester, true);
      await _advance(tester, 1);
      await tester.tap(find.text('終了'));
      await tester.pump();
      expect((await history(tester, container)).length, 1);
    });

    testWidgets('画面を戻って抜けても、解答済みの分は残る', (tester) async {
      final container = await start(tester, 3);
      await tapChoice(tester, false);
      await tester.pumpWidget(const SizedBox());
      expect((await history(tester, container)).map((r) => r.correct).toList(), [false]);
    });

    testWidgets('考える間に答えなかった問題は履歴に載らない', (tester) async {
      final container = await _pump(tester, NagaraStudyView(pool: [_q('a')]), FakeSpeechBackend());
      await _settle(tester);
      await _advance(tester, 3); // 考える間(1秒)が過ぎて終わる
      expect(find.text('おつかれさまでした'), findsOneWidget);
      expect(await history(tester, container), isEmpty);
    });

    testWidgets('スキップした問題は履歴に載らない。スキップ前の解答は残る', (tester) async {
      final container = await start(tester, 3);
      await tapChoice(tester, true);
      await _advance(tester, 1);
      await tester.tap(find.text('スキップ'));
      await _advance(tester, 1);
      expect((await history(tester, container)).map((r) => r.correct).toList(), [true]);
    });
  });

  group('上限と停止', () {
    testWidgets('上限問数に達すると、ひと休みを促して終わる', (tester) async {
      final container = await _pump(
        tester,
        NagaraStudyView(pool: [for (var i = 0; i < 5; i++) _q('q$i')], limit: 2),
        FakeSpeechBackend(),
      );
      await _settle(tester);
      await _advance(tester, 12);
      expect(find.text('おつかれさまでした'), findsOneWidget);
      expect(find.textContaining('ひと休み'), findsOneWidget);
      await tester.runAsync(() => container.read(historyProvider.notifier).ready);
      expect(container.read(historyProvider), isEmpty); // 未回答は載らない
    });

    testWidgets('既定の上限は20問', (tester) async {
      expect(kNagaraSessionLimit, 20);
    });

    testWidgets('停止すると読み上げが止まり、それ以上進まない', (tester) async {
      final speech = FakeSpeechBackend();
      await _pump(tester, NagaraStudyView(pool: [_q('a'), _q('b')]), speech);
      await _settle(tester);
      final stopsBefore = speech.stopCount;
      await tester.tap(find.text('終了'));
      await tester.pump();
      expect(find.text('おつかれさまでした'), findsOneWidget);
      expect(speech.stopCount, greaterThan(stopsBefore));
      final spokenAtStop = speech.spoken.length;
      await _advance(tester, 30);
      expect(speech.spoken.length, spokenAtStop);
    });

    testWidgets('画面を離れると読み上げもタイマーも止まる', (tester) async {
      final speech = FakeSpeechBackend();
      await _pump(tester, NagaraStudyView(pool: [_q('a'), _q('b')]), speech);
      await _settle(tester);
      final stopsBefore = speech.stopCount;
      await tester.pumpWidget(const SizedBox());
      expect(speech.stopCount, greaterThan(stopsBefore));
      final spoken = speech.spoken.length;
      await _advance(tester, 30);
      expect(speech.spoken.length, spoken);
    });
  });
}
