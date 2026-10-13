import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otsu4/data/exam_date_store.dart';
import 'package:otsu4/views/exam_prep_entry.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ukalab_core/ui.dart';
import 'package:ukalab_core/ukalab_core.dart';

// ukalab_core v0.63.0 の試験日カウントダウンを、ホームの接続部品 ExamCountdownSection 越しに確認する。
final _today = DateTime(2026, 10, 13, 12);

Future<void> _pump(WidgetTester tester, DateTime? examDate) async {
  SharedPreferences.setMockInitialValues({});
  final service = ExamDateService();
  await tester.runAsync(() => service.setDate(examDate));
  await tester.pumpWidget(ProviderScope(
    overrides: [examDateServiceProvider.overrideWithValue(service)],
    child: MaterialApp(
      home: Scaffold(body: ExamCountdownSection(clock: () => _today)),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('試験日が未設定なら何も出ない', (tester) async {
    await _pump(tester, null);
    expect(find.byType(ExamCountdownChip), findsNothing);
    expect(find.byType(Chip), findsNothing);
    expect(find.byType(ActionChip), findsNothing);
  });

  const cases = <(String, int, String)>[
    ('farAway', 200, 'あと200日'),
    ('approaching', 60, 'あと60日'),
    ('close', 20, 'あと20日'),
    ('finalDays', 3, 'あと3日'),
  ];
  for (final (name, days, _) in cases) {
    testWidgets('設定済み($name: $days日)ならチップが出て日数を含む', (tester) async {
      await _pump(tester, DateTime(2026, 10, 13 + days));
      expect(find.byType(ActionChip), findsOneWidget);
      final chip = tester.widget<ActionChip>(find.byType(ActionChip));
      final expected = ExamCountdownStrings.ja
          .chip(const ExamCountdownEngine().compute(DateTime(2026, 10, 13 + days), today: _today));
      expect((chip.label as Text).data, expected);
      expect(expected, contains('$days'));
    });
  }

  testWidgets('当日は「今日が試験日」', (tester) async {
    await _pump(tester, DateTime(2026, 10, 13));
    expect(find.text(ExamCountdownStrings.ja.chipToday), findsOneWidget);
  });

  testWidgets('試験日を過ぎたら日数を出さず「おつかれさまでした」', (tester) async {
    await _pump(tester, DateTime(2026, 10, 1));
    expect(find.text('おつかれさまでした'), findsOneWidget);
    expect(find.textContaining('あと'), findsNothing);
  });

  testWidgets('タップで試験日の設定(日付ピッカー)が開く', (tester) async {
    await _pump(tester, DateTime(2026, 11, 13));
    await tester.tap(find.byType(ActionChip));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
  });

  testWidgets('過ぎた試験日でもタップで設定が開ける(ピッカーが落ちない)', (tester) async {
    await _pump(tester, DateTime(2025, 1, 1));
    await tester.tap(find.byType(ActionChip));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
