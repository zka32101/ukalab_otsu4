import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:otsu4/data/data_parts.dart';
import 'package:otsu4/data/progress_store.dart';
import 'package:ukalab_core/ui.dart' show encodeLearningDataBackup, resetLearningData, restoreLearningDataBackup;

void main() {
  test('otsu4DataParts のidは重複せず、旧バックアップのキーと同じ', () {
    final ids = [for (final p in otsu4DataParts) p.id];
    expect(ids.toSet().length, ids.length);
    expect(
      ids,
      containsAll([
        'progress',
        'srs',
        'mockHistory',
        'mockWrong',
        'dailyGoal',
        'dailyGoalHistory',
        'subjectStats',
        'subjectStatsHistory',
        'answeredQuestions',
        'questionMemo',
        'recentGlossaryTerms',
        'bestCombo',
        'dailyAnswerStats',
        'learnedTerms',
        'glossaryMastered',
      ]),
    );
  });

  testWidgets('書き出して、リセット後に読み込むと、進捗が元に戻る', (tester) async {
    late WidgetRef ref;
    SharedPreferences.setMockInitialValues({});
    final progressService = ProgressService();
    await tester.runAsync(progressService.load);
    await tester.pumpWidget(ProviderScope(
      overrides: [progressServiceProvider.overrideWithValue(progressService)],
      child: MaterialApp(
        home: Scaffold(
          body: Consumer(builder: (context, r, _) {
            ref = r;
            return const SizedBox();
          }),
        ),
      ),
    ));
    await tester.runAsync(() async {
      await ref.read(progressProvider.notifier).restore(
            ProgressSnapshot(answered: 10, correct: 7, streakDays: 3, lastStudyDate: DateTime(2026, 10, 6)),
          );
      // 全部品を読むには各サービスの override が要るため、進捗の部品だけで往復を確かめる。
      final parts = [otsu4DataParts.firstWhere((p) => p.id == 'progress')];
      final text = encodeLearningDataBackup(ref, parts);
      await resetLearningData(ref, parts);
      expect(ref.read(progressProvider).answered, 0);

      await restoreLearningDataBackup(ref, parts, text);

      // 共通化前の旧形式（項目がトップレベルに並ぶ形）でも読み込める。
      await resetLearningData(ref, parts);
      final parsed = jsonDecode(text) as Map<String, dynamic>;
      final legacy = jsonEncode({'version': 1, ...(parsed['parts'] as Map<String, dynamic>)});
      await restoreLearningDataBackup(ref, parts, legacy);
      expect(ref.read(progressProvider).answered, 10);
      expect(ref.read(progressProvider).correct, 7);
    });
  });
}
