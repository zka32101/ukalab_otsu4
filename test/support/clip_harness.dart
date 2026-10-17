import 'dart:io';

import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otsu4/data/achievements_provider.dart';
import 'package:otsu4/data/answered_questions_store.dart';
import 'package:otsu4/data/combo_store.dart';
import 'package:otsu4/data/daily_answer_stats_store.dart';
import 'package:otsu4/data/exam_date_store.dart';
import 'package:otsu4/data/glossary_favorite_store.dart';
import 'package:otsu4/data/learned_terms.dart';
import 'package:otsu4/data/mock_history_store.dart';
import 'package:otsu4/data/mock_wrong_store.dart';
import 'package:otsu4/data/progress_store.dart';
import 'package:otsu4/data/question_repository.dart';
import 'package:otsu4/data/recent_glossary_terms_store.dart';
import 'package:otsu4/data/selected_level_store.dart';
import 'package:otsu4/data/srs_store.dart';
import 'package:otsu4/data/subject_stats_history_store.dart';
import 'package:otsu4/data/subject_stats_store.dart';
import 'package:otsu4/data/theme_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ukalab_core/achievements.dart';
import 'package:ukalab_core/daily_goal.dart';
import 'package:ukalab_core/reminder.dart';
import 'package:ukalab_core/ui.dart';
import 'package:ukalab_core/ukalab_core.dart';
import '../test_ads.dart';

/// 実問題のうち、表示が長くなりやすいもの（最長の選択肢・問題文・解説）。
List<Question> worstCaseQuestions = const [];

Future<List<Question>> loadWorstCase(WidgetTester tester, {int each = 3}) async {
  if (worstCaseQuestions.isNotEmpty) return worstCaseQuestions;
  final all = (await tester.runAsync(() => const QuestionRepository().load()))!;
  int maxChoice(Question q) => q.choices.fold(0, (m, c) => c.length > m ? c.length : m);
  final byChoice = [...all]..sort((a, b) => maxChoice(b).compareTo(maxChoice(a)));
  final byPrompt = [...all]..sort((a, b) => b.prompt.length.compareTo(a.prompt.length));
  final byExpl = [...all]..sort((a, b) => b.explanation.length.compareTo(a.explanation.length));
  final five = [for (final q in all) if (q.choices.length >= 5) q]
    ..sort((a, b) => maxChoice(b).compareTo(maxChoice(a)));
  final picked = <String, Question>{};
  for (final l in [byChoice, byPrompt, byExpl, five]) {
    for (final q in l.take(each)) {
      picked[q.qid] = q;
    }
  }
  return worstCaseQuestions = picked.values.toList();
}

/// main.dart と同じ構成で、端末内保存のみ（外部サービスなし）の overrides を作る。
/// [seed] が true なら、模試履歴・苦手問題・解答履歴などの表示データを入れて、記録系の画面も描画させる。
Future<List<Override>> clipOverrides(
  WidgetTester tester, {
  String? levelId,
  List<Override> extra = const [],
  bool seed = true,
}) async {
  final worst = await loadWorstCase(tester);
  SharedPreferences.setMockInitialValues({});
  return (await tester.runAsync(() async {
    final coin = CoinService(
      store: InMemoryCoinStore(),
      shop: OutfitCatalog.shopItems([UkalabCert.hazmat4]),
    );
    await coin.load();
    final outfit = OutfitService(store: SharedPreferencesOutfitStore('otsu4'));
    await outfit.load();
    final progress = ProgressService();
    await progress.load();
    final srs = SrsService();
    await srs.load();
    final mockHistory = MockHistoryService();
    await mockHistory.load();
    final mockWrong = MockWrongService();
    await mockWrong.load();
    final studyNotes = await studyNotesOverrides('otsu4');
    final dailyGoal = await dailyGoalOverrides('otsu4');
    final stats = SubjectStatsService();
    await stats.load();
    final statsHistory = SubjectStatsHistoryService();
    await statsHistory.load();
    final theme = ThemeService();
    await theme.load();
    final examDate = ExamDateService();
    await examDate.load();
    final level = SelectedLevelService();
    await level.load();
    if (levelId != null) await level.select(levelId);
    final answered = AnsweredQuestionsService();
    await answered.load();
    final fav = GlossaryFavoriteService();
    await fav.load();
    final learned = await learnedTermsStore.load();
    final reminder = await reminderOverrides('otsu4');
    final recent = RecentGlossaryTermsService();
    await recent.load();
    final combo = ComboService();
    await combo.load();
    final daily = DailyAnswerStatsService();
    await daily.load();
    final unlock = await achievementUnlockOverrides('otsu4');
    if (seed) {
      final now = DateTime.now();
      for (var i = 0; i < 4; i++) {
        await mockHistory.add(MockHistoryEntry(
          at: now.subtract(Duration(days: i * 3)),
          score: 20 + i * 5,
          max: 35,
          passed: i > 1,
          subjectScore: {'law': 8 + i, 'physics_chem': 6 + i, 'property_extinguish': 6 + i},
          subjectMax: {'law': 15, 'physics_chem': 10, 'property_extinguish': 10},
        ));
      }
      for (final q in worst) {
        await stats.recordAnswer(subjectId: q.subjectId, correct: q.qid.hashCode.isEven);
        await srs.review(qid: q.qid, correct: false);
        await answered.record(q.qid);
      }
      await mockWrong.setWrong([for (final q in worst) q.qid]);
      for (var i = 0; i < 7; i++) {
        final d = DailyAnswerStatsService(clock: () => now.subtract(Duration(days: i)));
        await d.load();
        await d.recordAnswer(correct: i.isEven);
      }
    }
    return <Override>[
      ...extra,
      handsFreeStoreProvider.overrideWithValue(InMemoryHandsFreeStore()),
      stubAdGateOverride(),
      entitlementServiceProvider.overrideWithValue(FakeEntitlementService(
        availableOffers: const [
          EntitlementOffer(
            id: 'premium',
            productId: 'otsu4_premium',
            title: 'プレミアム（広告非表示＋追加機能）',
            priceString: '¥1,500',
          ),
        ],
      )),
      coinServiceProvider.overrideWithValue(coin),
      outfitServiceProvider.overrideWithValue(outfit),
      progressServiceProvider.overrideWithValue(progress),
      srsServiceProvider.overrideWithValue(srs),
      mockHistoryServiceProvider.overrideWithValue(mockHistory),
      mockWrongServiceProvider.overrideWithValue(mockWrong),
      ...studyNotes,
      ...dailyGoal,
      subjectStatsServiceProvider.overrideWithValue(stats),
      subjectStatsHistoryServiceProvider.overrideWithValue(statsHistory),
      themeServiceProvider.overrideWithValue(theme),
      examDateServiceProvider.overrideWithValue(examDate),
      selectedLevelServiceProvider.overrideWithValue(level),
      answeredQuestionsServiceProvider.overrideWithValue(answered),
      glossaryFavoriteServiceProvider.overrideWithValue(fav),
      learnedTermsInitialProvider.overrideWithValue(learned),
      ...reminder,
      recentGlossaryTermsServiceProvider.overrideWithValue(recent),
      comboServiceProvider.overrideWithValue(combo),
      dailyAnswerStatsServiceProvider.overrideWithValue(daily),
      ...unlock,
      achievementsOverride,
    ];
  }))!;
}

/// 幅 [width]・文字倍率 [scale] で [home] を表示する。
Future<void> pumpClip(
  WidgetTester tester,
  Widget home, {
  required double width,
  required double scale,
  double height = 700,
  String? levelId,
  bool dark = false,
  List<Override> extra = const [],
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  captureLayoutErrors(tester);
  final overrides = await clipOverrides(tester, levelId: levelId, extra: extra);
  await tester.pumpWidget(ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      theme: UkalabTheme.light(field: UkalabField.tech, cert: UkalabCert.hazmat4),
      darkTheme: UkalabTheme.dark(field: UkalabField.tech, cert: UkalabCert.hazmat4),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      home: home,
    ),
  ));
  await settleClip(tester);
}

/// アセット読み込み（実時間）を待ってから描画を進める。
Future<void> settleClip(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 150)));
    await tester.pump(const Duration(milliseconds: 100));
  }
  // 読み込み中の表示（ぐるぐる）が消えるまで待つ。負荷が高いと読み込みが遅れ、
  // 読み込み前の画面だけを検査してしまうのを防ぐ。
  for (var i = 0; i < 100 && find.byType(CircularProgressIndicator).evaluate().isNotEmpty; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// アプリ全体（5タブのシェル）を表示する。
Future<void> pumpClipApp(
  WidgetTester tester,
  Widget app, {
  required double width,
  required double scale,
  double height = 700,
  String? levelId,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  captureLayoutErrors(tester);
  final overrides = await clipOverrides(tester, levelId: levelId);
  await tester.pumpWidget(ProviderScope(overrides: overrides, child: app));
  await settleClip(tester);
}

final List<FlutterErrorDetails> _captured = [];
final Set<String> _sites = {};

/// 描画中に出たエラー（RenderFlex overflow 等）を、テスト中ずっと集める。
/// 1回のテストで複数箇所を一度に洗い出すため、最初の1件で止めず、テスト終了時にまとめて失敗させる。
void captureLayoutErrors(WidgetTester tester) {
  _captured.clear();
  _sites.clear();
  final prev = FlutterError.onError;
  FlutterError.onError = (d) {
    // テスト自身の失敗（expect など）は握りつぶさずフレームワークへ渡す。
    if (d.exception is FlutterError || d.exception is AssertionError) {
      _captured.add(d);
    } else {
      prev?.call(d);
    }
  };
  addTearDown(() {
    _drain();
    FlutterError.onError = prev;
    _dropExternal();
    final found = _sites.toList()..sort();
    _sites.clear();
    expect(found, isEmpty, reason: 'テキストの切れ・はみ出し:\n${found.join('\n')}');
  });
}

/// 共通パッケージ（ukalab_core / app_common_kit）側のウィジェットが原因の既知のはみ出し。
/// このアプリからは直せないため、そちらのリポジトリで直すまで一覧から除く（PR本文に記載）。
const _externalSites = [
  'lib/entitlement/purchase_section.dart', // ukalab_core: 設定の購入セクション（文字3倍）
  'lib/hands_free/nagara_session_view.dart', // ukalab_core: ながら学習の操作行（幅280〜）
];

void _drain() {
  for (final d in _captured) {
    final text = d.toString();
    final head = d.exceptionAsString().split('\n').first;
    final m = RegExp(r'(lib/[\w/]+\.dart:\d+)').firstMatch(text);
    _sites.add('$head @ ${m?.group(1) ?? text.split('\n').take(6).join(' | ')}');
  }
  _captured.clear();
}

void _dropExternal() {
  // 画面を閉じるときの Inspector の警告はテキストの切れとは無関係なので除く。
  _sites.removeWhere((e) => e.contains("deactivated widget"));
  final hasExternal = _sites.any((e) => _externalSites.any(e.contains));
  _sites.removeWhere((e) => _externalSites.any(e.contains));
  // 上記の既知のはみ出しに連鎖して出る、描画後の semantics 等の assertion も除く。
  if (hasExternal) {
    _sites.removeWhere((e) =>
        e.contains('Failed assertion') ||
        e.contains('not laid out') ||
        e.contains("deactivated widget"));
  }
}

/// ここまでに出たエラーを記録する（テスト終了時にまとめて失敗として報告する）。
void expectNoLayoutErrors(WidgetTester tester, [String where = '']) {
  final thrown = tester.takeException();
  if (thrown != null) _sites.add('例外: $thrown');
  _drain();
}

/// アセットを、テストの偽の時間の外（setUpAll）で先に読み込んでキャッシュしておく。
/// テスト本体の中で読み始めると、テストが先に終わった場合に未完了の Future が
/// キャッシュに残り、後続のテストが読み込み待ちのまま進まなくなることがある。
Future<void> preloadAssets() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final e in Directory('assets').listSync(recursive: true)) {
    if (e is! File) continue;
    final path = e.path.replaceAll('\\', '/');
    if (path.endsWith('.json') || path.endsWith('.jsonl') || path.endsWith('.csv')) {
      await rootBundle.loadString(path);
    }
  }
  await rootBundle.loadString('assets/readings.jsonl');
}
