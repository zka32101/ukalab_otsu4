import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otsu4/data/exam_repository.dart';
import 'package:otsu4/data/field_day_scenarios.dart';
import 'package:otsu4/views/field_day_scenario_view.dart';
import 'package:ukalab_core/ukalab_core.dart';

late ExamConfig _exam;
late List<FieldDayWorkplace> _scenarios;

Future<void> _pumpList(WidgetTester tester, {required bool premium}) async {
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      entitlementStateProvider.overrideWith(
          (ref) => Stream.value(EntitlementState(hasPremium: premium))),
    ],
    child: MaterialApp(
      home: FieldDayScenarioListView(scenariosFuture: Future.value(_scenarios)),
    ),
  ));
  // pumpAndSettle は使わず、一定回数だけ進める。
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    _exam = await const ExamRepository().load();
    _scenarios = await loadFieldDayWorkplaces();
  });

  group('データ検証', () {
    test('職場別シナリオは3本で、各4場面・3択、追加分はすべてプレミアム限定', () {
      expect(_scenarios.length, 3);
      for (final s in _scenarios) {
        expect(s.story.chapters.length, 4);
        for (final c in s.story.chapters) {
          expect(c.choices.length, 3);
        }
        expect(s.isFree, isFalse);
      }
    });

    test('品質ゲートに通る(AI下書きの印・自作の出典・禁止語なし)', () {
      expect(validateFieldDayWorkplaces(_scenarios, exam: _exam), isEmpty);
      for (final s in _scenarios) {
        expect(s.contentStatus, 'ai-draft');
        expect(s.story.source, QuestionSource.original);
        expect(s.story.sourceRef, contains('自作'));
      }
    });

    test('禁止語(公式/本試験相当/過去問/合格保証)を全データに含まない', () {
      for (final s in _scenarios) {
        final all = s.story.toJson().toString();
        for (final w in kFieldDayForbiddenWords) {
          expect(all.contains(w), isFalse, reason: '${s.scenarioId} に $w');
        }
      }
    });

    test('禁止語やAI下書きの欠落を検出できる', () {
      final bad = parseFieldDayWorkplaces(
        '{"scenarioId":"x","examId":"hazmat4","title":"過去問で学ぶ","description":"d",'
        '"chapters":[{"chapterId":"a","situation":"s","choices":[{"choiceId":"1","text":"t","isRecommended":true,"feedback":"f"},{"choiceId":"2","text":"u","isRecommended":false,"feedback":"g"}]},'
        '{"chapterId":"b","situation":"s","choices":[{"choiceId":"1","text":"t","isRecommended":true,"feedback":"f"},{"choiceId":"2","text":"u","isRecommended":false,"feedback":"g"}]}],'
        '"source":"original","sourceRef":"出典","contentVer":"1"}',
      );
      final codes = validateFieldDayWorkplaces(bad.scenarios, exam: _exam).map((i) => i.code).toSet();
      expect(codes, containsAll(['no-ai-draft', 'forbidden-word', 'no-self-made']));
    });
  });

  group('一覧画面', () {
    testWidgets('無料: AI下書きの表示が出て、全シナリオに鍵アイコンが付く', (tester) async {
      await _pumpList(tester, premium: false);
      expect(find.text(kFieldDayScenarioDraftNotice), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsNWidgets(3));
    });

    testWidgets('無料: タップしても案内のSnackBarだけで、画面に入れない', (tester) async {
      await _pumpList(tester, premium: false);
      await tester.tap(find.text(_scenarios[0].story.title));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text(kFieldDayPremiumNotice), findsOneWidget);
      expect(find.byType(FieldDayScenarioPlayView), findsNothing);
    });

    testWidgets('プレミアム: 開けて、AI下書きの表示と判断→解説→次の章へ進める', (tester) async {
      await _pumpList(tester, premium: true);
      await tester.tap(find.text(_scenarios[0].story.title));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(find.byType(FieldDayScenarioPlayView), findsOneWidget);
      expect(find.text(kFieldDayPremiumNotice), findsNothing);
      expect(find.text(kFieldDayScenarioDraftNotice), findsOneWidget);
      expect(find.text('第1章 / 全4章'), findsOneWidget);

      final rec = _scenarios[0].story.chapters.first.choices.firstWhere((c) => c.isRecommended);
      await tester.tap(find.text(rec.text));
      await tester.pump();
      expect(find.text('よい判断です'), findsOneWidget);
      await tester.tap(find.text('次の章へ'));
      await tester.pump();
      expect(find.text('第2章 / 全4章'), findsOneWidget);
    });
  });
}
