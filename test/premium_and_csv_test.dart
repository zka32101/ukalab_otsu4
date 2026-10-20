import 'dart:convert';

import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otsu4/views/exam_prep_entry.dart';
import 'package:otsu4/widgets/premium_benefits_section.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ukalab_core/ui.dart';
import 'package:ukalab_core/ukalab_core.dart';

Question _q(String qid) => Question(
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
    );

List<ProgressRecord> _records() => [
      ProgressRecord(
          qid: 'hazmat4-secret-id',
          subjectId: 'law',
          topicId: 'ch1',
          at: DateTime(2026, 10, 12, 9),
          correct: true),
      ProgressRecord(
          qid: 'hazmat4-secret-id',
          subjectId: 'law',
          topicId: 'ch1',
          at: DateTime(2026, 10, 12, 10),
          correct: false),
    ];

class _FakeSaver {
  final calls = <({List<int> bytes, String fileName, String mimeType})>[];
  bool result = true;
  bool throws = false;

  Future<bool> call({
    required List<int> bytes,
    required String fileName,
    required String mimeType,
    Object? sharePositionOrigin,
  }) async {
    if (throws) throw StateError('share failed');
    calls.add((bytes: bytes, fileName: fileName, mimeType: mimeType));
    return result;
  }
}

Widget _app(Widget child, {EntitlementState initial = EntitlementState.free}) =>
    ProviderScope(
      overrides: [
        entitlementServiceProvider
            .overrideWithValue(FakeEntitlementService(initial: initial)),
      ],
      child: MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child))),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PremiumBenefitsSection', () {
    testWidgets('無料版: このアプリで実在する機能だけを出し、未実装の機能は出さない', (tester) async {
      await tester.pumpWidget(_app(const PremiumBenefitsSection()));
      await tester.pump();
      expect(find.byType(PremiumBenefitsCard), findsOneWidget);
      final s = PremiumBenefitsStrings.ja;
      expect(find.text(s.title), findsOneWidget);
      for (final f in kOtsu4PremiumFeatures) {
        expect(find.byKey(ValueKey('premiumBenefit_${f.name}')), findsOneWidget,
            reason: f.name);
      }
      // 未実装の機能・core の「無料のまま」一文は出さない
      for (final f in [
        PremiumFeature.weakDrill,
        PremiumFeature.mockExamHistory,
        PremiumFeature.customMockExam,
      ]) {
        expect(find.byKey(ValueKey('premiumBenefit_${f.name}')), findsNothing,
            reason: f.name);
      }
      expect(find.byKey(const ValueKey('premiumFreeNote')), findsNothing);
      expect(find.text(PremiumBenefitsSection.note), findsOneWidget);
    });

    testWidgets('プレミアム購入済みなら出さない', (tester) async {
      await tester.pumpWidget(_app(const PremiumBenefitsSection(),
          initial: const EntitlementState(hasPremium: true)));
      await tester.pump();
      await tester.pump();
      expect(find.byType(PremiumBenefitsCard), findsNothing);
    });

    test('文言に「公式」「合格保証」「未実装の機能」を含めない', () {
      final s = PremiumBenefitsStrings.ja;
      final texts = [
        s.title,
        for (final f in kOtsu4PremiumFeatures) ...[
          s.benefits[f]!.name,
          s.benefits[f]!.description,
        ],
        PremiumBenefitsSection.note,
      ].join();
      for (final w in ['公式', '合格保証', '必ず合格', 'キャラ']) {
        expect(texts.contains(w), isFalse, reason: w);
      }
    });
  });

  group('履歴CSVのファイル保存', () {
    testWidgets('ダウンロードで shareCsv が呼ばれる(BOM付き・text/csv・日付入りファイル名・個人情報なし)',
        (tester) async {
      final saver = _FakeSaver();
      await tester.pumpWidget(MaterialApp(
        home: HistoryExportView(
          records: _records(),
          questions: [_q('hazmat4-secret-id')],
          saver: saver.call,
          now: () => DateTime(2026, 10, 20, 8),
        ),
      ));
      // クリップボードのボタンは無く、ダウンロードのボタンがある
      expect(find.byKey(const ValueKey('copyCsv')), findsNothing);
      expect(find.text(ExamPrepStrings.ja.exportSave), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('downloadCsv')));
      await tester.pump();
      await tester.pump();

      expect(saver.calls, hasLength(1));
      final call = saver.calls.single;
      expect(call.fileName, 'ukalab_history_20261020.csv');
      expect(call.mimeType, 'text/csv');
      expect(call.bytes.sublist(0, 3), [0xEF, 0xBB, 0xBF]);
      final text = utf8.decode(call.bytes.sublist(3));
      expect(text, contains('日付,解答数,正答数,正答率(%),学習時間(分)'));
      expect(text, contains('2026-10-12,2,1,50.0'));
      // 個人情報・問題IDの列を持たない
      expect(text, isNot(contains('secret')));
      expect(text, isNot(contains('qid')));
      expect(find.text(ExamPrepStrings.ja.exportSaved), findsOneWidget);
    });

    testWidgets('共有シートを閉じたら完了表示を出さず、失敗なら失敗の文言を出す', (tester) async {
      final saver = _FakeSaver()..result = false;
      Future<void> pump() => tester.pumpWidget(MaterialApp(
            key: UniqueKey(),
            home: HistoryExportView(
              records: _records(),
              questions: [_q('hazmat4-secret-id')],
              saver: saver.call,
              now: () => DateTime(2026, 10, 20),
            ),
          ));
      await pump();
      await tester.tap(find.byKey(const ValueKey('downloadCsv')));
      await tester.pump();
      await tester.pump();
      expect(saver.calls, hasLength(1));
      expect(find.text(ExamPrepStrings.ja.exportSaved), findsNothing);
      expect(find.text(ExamPrepStrings.ja.exportSaveFailed), findsNothing);

      saver.throws = true;
      await pump();
      await tester.tap(find.byKey(const ValueKey('downloadCsv')));
      await tester.pump();
      await tester.pump();
      expect(find.text(ExamPrepStrings.ja.exportSaveFailed), findsOneWidget);
    });

    testWidgets('設定の「学習履歴の書き出し」(プレミアム)から開き、saver が使われる', (tester) async {
      SharedPreferences.setMockInitialValues({
        'ukalab_otsu4_history_v1': encodeHistory(_records()),
      });
      final saver = _FakeSaver();
      await tester.pumpWidget(_app(
        CoreFeatureSettingsTiles(saver: saver.call),
        initial: const EntitlementState(hasPremium: true),
      ));
      await tester.pump();
      await tester.pump();
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('exportTile')));
      await tester.pumpAndSettle();
      expect(find.byType(HistoryExportView), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('downloadCsv')));
      await tester.pump();
      await tester.pump();
      expect(saver.calls, hasLength(1));
      expect(saver.calls.single.fileName, startsWith('ukalab_history_'));
      expect(saver.calls.single.fileName, endsWith('.csv'));
    });
  });
}
