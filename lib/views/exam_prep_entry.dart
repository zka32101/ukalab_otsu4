import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ukalab_core/ui.dart';
import 'package:ukalab_core/ukalab_core.dart';

import '../data/core_features.dart';
import '../data/exam_date_store.dart';
import '../data/history_store.dart';
import 'exam_date_picker.dart';
import 'practice_session_view.dart';

/// ukalab_core の共通画面（`lib/ui/exam_prep/`）をこのアプリのデータにつなぐ部分。
/// 画面・文言は core 側。ここは取得・保存・premium 判定・遷移だけ。

void _openPractice(
    BuildContext context, String title, List<Question> pool, String empty) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: ScrollablePracticeSession(pool: pool, emptyMessage: empty),
      ),
    ),
  );
}

/// ホームの試験日カウントダウン(ukalab_core v0.63.0。無料)。未設定なら何も出さない。
/// タップで既存の試験日設定(日付ピッカー)を開く。
class ExamCountdownSection extends ConsumerWidget {
  const ExamCountdownSection({super.key, this.clock = DateTime.now});

  final DateTime Function() clock;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(examDateProvider);
    if (date == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ExamCountdownChip(
          examDate: date,
          clock: clock,
          onTap: () => pickExamDate(context, ref),
        ),
      ),
    );
  }
}

/// ホームの「試験に向けて」カード。
class CoreFeaturesCard extends ConsumerWidget {
  const CoreFeaturesCard({super.key, this.clock = DateTime.now});

  final DateTime Function() clock;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ExamPrepCard(
      clock: clock,
      questions: () => ref.read(allQuestionsProvider).valueOrNull ?? const [],
      records: () => ref.read(historyProvider),
      examDate: ref.watch(examDateProvider),
      tenMinUnlocked: isPremiumFor(ref, PremiumFeature.tenMinutePlan),
      examEveUnlocked: isPremiumFor(ref, PremiumFeature.examEveMode),
      onStartPractice: _openPractice,
      onOpenChecklist: (c) async {
        final notifier = ref.read(checklistProvider.notifier);
        await notifier.ready;
        if (!c.mounted) return;
        final items = await loadChecklist();
        if (!c.mounted) return;
        await Navigator.of(c).push(MaterialPageRoute<void>(
          builder: (_) => ExamDayChecklistView(
            examId: kExamId,
            items: items,
            initialProgress: ref.read(checklistProvider),
            onChanged: notifier.setProgress,
          ),
        ));
      },
    );
  }
}

/// 設定タブの、更新ログ・履歴書き出しの入口。
class CoreFeatureSettingsTiles extends ConsumerWidget {
  const CoreFeatureSettingsTiles({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ExamPrepSettingsTiles(
      exportUnlocked: isPremiumFor(ref, PremiumFeature.historyExport),
      onOpenUpdateLog: (c) => Navigator.of(c).push(MaterialPageRoute<void>(
          builder: (_) => UpdateLogView(entriesFuture: loadUpdateLog()))),
      onOpenExport: (c) => Navigator.of(c).push(MaterialPageRoute<void>(
          builder: (_) => HistoryExportView(
                records: ref.read(historyProvider),
                questions:
                    ref.read(allQuestionsProvider).valueOrNull ?? const [],
              ))),
    );
  }
}
