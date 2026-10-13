import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otsu4/data/core_features.dart';
import 'package:otsu4/data/exam_date_store.dart';
import 'package:otsu4/views/core_feature_views.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ukalab_core/ukalab_core.dart';

Question _q(String qid, {List<String> tags = const []}) => Question(
      qid: qid,
      examId: 'hazmat4',
      subjectId: 'law',
      topicId: 'ch1',
      prompt: '問題$qid',
      choices: const ['A', 'B'],
      answerIndex: 0,
      explanation: '解説',
      source: QuestionSource.original,
      sourceRef: '自作',
      contentVer: '1',
      tags: tags,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('更新ログ・チェックリストの同梱データが読めて、検証を通る', () async {
    final log = await loadUpdateLog(now: DateTime(2026, 10, 13));
    expect(log, isNotEmpty);
    expect(
        log.first.date.isAfter(log.last.date) ||
            log.first.date == log.last.date,
        isTrue);
    final items = await loadChecklist();
    expect(items.length, greaterThanOrEqualTo(5));
    expect(unconfirmedItems(items), isNotEmpty); // 公式未確認のものは未確認のまま
  });

  test('履歴CSVに個人情報・問題IDを含めず、日別と分野別が並ぶ', () {
    final q = _q('hazmat4-secret-id');
    final csv = historyCsvText([
      ProgressRecord(
          qid: q.qid,
          subjectId: 'law',
          topicId: 'ch1',
          at: DateTime(2026, 10, 12, 9),
          correct: true,
          ms: 30000),
      ProgressRecord(
          qid: q.qid,
          subjectId: 'law',
          topicId: 'ch1',
          at: DateTime(2026, 10, 12, 10),
          correct: false),
    ], [
      q
    ]);
    expect(csv, contains('日付,解答数,正答数,正答率(%),学習時間(分)'));
    expect(csv, contains('2026-10-12,2,1,50.0,0.5'));
    expect(csv, contains('分野,解答数,正答数,正答率(%)'));
    expect(csv, contains('ch1,2,1,50.0'));
    expect(csv, isNot(contains('secret')));
  });

  test('試験直前は3日前から、10分プランは時間内に収まる', () {
    final now = DateTime(2026, 10, 13);
    expect(examEveStatus([DateTime(2026, 10, 15)], now)!.active, isTrue);
    expect(examEveStatus([DateTime(2026, 11, 15)], now)!.active, isFalse);
    final qs = [for (var i = 0; i < 40; i++) _q('q$i')];
    final plan = buildTimeBoxedPlan(qs, const [], now: now);
    expect(plan.estimatedSeconds, lessThanOrEqualTo(600));
    expect(plan.questions, isNotEmpty);
  });

  testWidgets('チェックリスト: チェックが進捗に反映され、保存される', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final items = [
      for (final id in ['a', 'b', 'c'])
        ChecklistItem(
            itemId: id,
            examId: 'hazmat4',
            category: ChecklistCategory.belongings,
            label: '項目$id'),
    ];
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(home: ChecklistView(itemsOverride: items)),
    ));
    await tester.pump();
    expect(find.text('0 / ${items.length} 完了'), findsOneWidget);
    await tester.tap(find.byType(CheckboxListTile).first);
    await tester.pump();
    expect(find.text('1 / ${items.length} 完了'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('ukalab_otsu4_exam_checklist_v1'), hasLength(1));
  });

  testWidgets('更新ログ: 新しい順に表示、空なら穏やかな文言', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: UpdateLogView(
          entriesFuture: Future.value([
        UpdateLogEntry(
            entryId: 'a',
            examId: 'hazmat4',
            date: DateTime(2026, 10, 10),
            kind: UpdateKind.correction,
            title: '訂正しました'),
      ])),
    ));
    await tester.pump();
    expect(find.text('訂正しました'), findsOneWidget);
    await tester.pumpWidget(
        MaterialApp(home: UpdateLogView(entriesFuture: Future.value([]))));
    await tester.pump();
    expect(find.text(CoreFeatureText.updateLogEmpty), findsOneWidget);
  });

  testWidgets('ホームのカード: 試験日が遠いと直前モードは出ず、近いと出る', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final now = DateTime(2026, 10, 13);
    Future<void> pump(DateTime? exam) async {
      final service = ExamDateService();
      await service.setDate(exam);
      await tester.pumpWidget(ProviderScope(
        key: UniqueKey(),
        overrides: [examDateServiceProvider.overrideWithValue(service)],
        child: MaterialApp(
            home: Scaffold(body: CoreFeaturesCard(clock: () => now))),
      ));
      await tester.pump();
    }

    await pump(null);
    expect(find.byKey(const ValueKey('tenMinPlanTile')), findsOneWidget);
    expect(find.byKey(const ValueKey('examEveTile')), findsNothing);
    expect(find.byKey(const ValueKey('checklistTile')), findsNothing);

    await pump(DateTime(2026, 10, 15));
    expect(find.byKey(const ValueKey('examEveTile')), findsOneWidget);
    expect(find.byKey(const ValueKey('checklistTile')), findsOneWidget);
  });

  test('文言に責める表現・他人比較を含めない', () {
    final texts = [
      CoreFeatureText.tenMinSubtitle,
      CoreFeatureText.examEveSubtitle,
      CoreFeatureText.emptyEve,
      CoreFeatureText.exportEmpty,
      CoreFeatureText.checklistDone,
      CoreFeatureText.checklistNote,
      CoreFeatureText.updateLogEmpty,
    ].join();
    for (final w in ['遅れ', 'サボ', 'ダメ', '他の人', '平均', 'ランキング', '順位']) {
      expect(texts.contains(w), isFalse, reason: w);
    }
  });
}
