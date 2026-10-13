import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ukalab_core/ukalab_core.dart';

import '../data/core_features.dart';
import '../data/exam_date_store.dart';
import '../data/history_store.dart';
import 'practice_session_view.dart';

/// ukalab_core の共通機能の画面で使う文言。core 側に文言は無い（データと関数のみ）ので、
/// ここに1か所だけ集める。励ます表現のみで、責める表現・他人との比較は使わない。
class CoreFeatureText {
  const CoreFeatureText._();

  static const sectionTitle = '試験に向けて';
  static const tenMinTitle = '今日の10分プラン';
  static const tenMinSubtitle = '弱点や見直したい問題から、10分に収まるだけ選びます';
  static const examEveTitle = '試験直前モード';
  static const examEveSubtitle = '最近間違えた問題・頻出・計算式を見直します';
  static const checklistTitle = '試験当日チェックリスト';
  static const checklistSubtitle = '持ち物と当日の流れを確かめます';
  static const premiumNote = 'プレミアムで使えます';
  static const emptyPlan = '今は出題できる問題がありません。';
  static const emptyEve = '見直す問題はまだありません。「学ぶ」で解くと、ここに集まります。';
  static const updateLogTitle = '更新ログ';
  static const updateLogSubtitle = '問題や解説の追加・訂正の記録を見られます';
  static const updateLogEmpty = '最近の更新はありません。';
  static const exportTitle = '学習履歴の書き出し（CSV）';
  static const exportSubtitle = '日ごとの解答数・正答率・分野ごとの正答率を書き出します';
  static const exportEmpty = 'まだ書き出せる履歴がありません。解くとここに集まります。';
  static const exportCopy = 'コピー';
  static const exportCopied = 'コピーしました';
  static const exportNote = '氏名・ID・端末情報・問題文は含まれません。';
  static const confirmNeeded = '公式で要確認';
  static const checklistDone = '準備ができました。落ち着いて、いつもどおりに。';
  static const checklistNote = '公式の受験案内で必ずご確認ください。項目は目安です。';

  static String minutes(int seconds) => '約${(seconds / 60).ceil()}分';
  static String progress(int done, int total) => '$done / $total 完了';
  static String planCount(int n, int seconds) => '$n問・${minutes(seconds)}';
  static String eveDays(int daysLeft) =>
      daysLeft == 0 ? '試験直前モード（今日が試験日）' : '試験直前モード（あと$daysLeft日）';

  static String category(ChecklistCategory c) => switch (c) {
        ChecklistCategory.belongings => '持ち物',
        ChecklistCategory.travel => '会場までの移動',
        ChecklistCategory.admission => '受験票・本人確認',
        ChecklistCategory.environment => '受験環境',
      };

  static String updateKind(UpdateKind k) => switch (k) {
        UpdateKind.lawChange => '法改正',
        UpdateKind.syllabusChange => '出題範囲の改訂',
        UpdateKind.correction => '訂正',
        UpdateKind.newContent => '追加',
      };

  static String affected(int n) => '$n問';
}

void _showPremiumNote(BuildContext context) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(const SnackBar(content: Text(CoreFeatureText.premiumNote)));
}

void _openPractice(
    BuildContext context, String title, List<Question> pool, String empty) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: PracticeSessionView(pool: pool, emptyMessage: empty),
        ),
      ),
    ),
  );
}

/// ホームの「試験に向けて」カード。10分プラン・試験直前モード・当日チェックリストへの入口。
class CoreFeaturesCard extends ConsumerWidget {
  const CoreFeaturesCard({super.key, this.clock = DateTime.now});

  final DateTime Function() clock;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final examDate = ref.watch(examDateProvider);
    final now = clock();
    final eve = examDate == null ? null : examEveStatus([examDate], now);
    final tenMinOk = isPremiumFor(ref, PremiumFeature.tenMinutePlan);
    final eveOk = isPremiumFor(ref, PremiumFeature.examEveMode);
    final theme = Theme.of(context);

    List<Question> questions() =>
        ref.read(allQuestionsProvider).valueOrNull ?? const [];

    void tenMin() {
      if (!tenMinOk) return _showPremiumNote(context);
      final qs = questions();
      final records = ref.read(historyProvider);
      final firstQids = (eve != null && eve.active)
          ? [
              for (final i in buildExamEveSet(qs, records, now: now))
                i.question.qid
            ]
          : const <String>[];
      final plan =
          buildTimeBoxedPlan(qs, records, now: now, firstQids: firstQids);
      _openPractice(context, CoreFeatureText.tenMinTitle, plan.questions,
          CoreFeatureText.emptyPlan);
    }

    void eveMode() {
      if (!eveOk) return _showPremiumNote(context);
      final items =
          buildExamEveSet(questions(), ref.read(historyProvider), now: now);
      _openPractice(context, CoreFeatureText.examEveTitle,
          [for (final i in items) i.question], CoreFeatureText.emptyEve);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(CoreFeatureText.sectionTitle,
                  style: theme.textTheme.titleSmall),
            ),
            ListTile(
              key: const ValueKey('tenMinPlanTile'),
              leading: const Icon(Icons.timer_outlined),
              title: const Text(CoreFeatureText.tenMinTitle),
              subtitle: Text(tenMinOk
                  ? CoreFeatureText.tenMinSubtitle
                  : CoreFeatureText.premiumNote),
              trailing: const Icon(Icons.chevron_right),
              onTap: tenMin,
            ),
            if (eve != null && eve.active)
              ListTile(
                key: const ValueKey('examEveTile'),
                leading: const Icon(Icons.event_available_outlined),
                title: Text(CoreFeatureText.eveDays(eve.daysLeft)),
                subtitle: Text(eveOk
                    ? CoreFeatureText.examEveSubtitle
                    : CoreFeatureText.premiumNote),
                trailing: const Icon(Icons.chevron_right),
                onTap: eveMode,
              ),
            if (examDate != null)
              ListTile(
                key: const ValueKey('checklistTile'),
                leading: const Icon(Icons.checklist_outlined),
                title: const Text(CoreFeatureText.checklistTitle),
                subtitle: Text(examCountdownText(daysUntilExam(examDate, now))),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                      builder: (_) => const ChecklistView()),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 試験当日チェックリスト。チェックは端末内に保存する。
class ChecklistView extends ConsumerWidget {
  const ChecklistView({super.key, this.itemsOverride});

  /// テスト用。null なら assets から読む。
  final List<ChecklistItem>? itemsOverride;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(checklistProvider);
    final theme = Theme.of(context);
    Widget body(List<ChecklistItem> items) {
      final done = progress.doneCount(items);
      ChecklistCategory? last;
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(CoreFeatureText.progress(done, items.length),
              style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          LinearProgressIndicator(
              value: items.isEmpty ? 0 : done / items.length),
          const SizedBox(height: 8),
          Text(CoreFeatureText.checklistNote, style: theme.textTheme.bodySmall),
          if (progress.isComplete(items)) ...[
            const SizedBox(height: 8),
            Text(CoreFeatureText.checklistDone,
                style: theme.textTheme.bodyMedium),
          ],
          for (final item in items) ...[
            if (item.category != last)
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 4),
                child: Text(CoreFeatureText.category(last = item.category),
                    style: theme.textTheme.labelLarge),
              ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: progress.isChecked(item.itemId),
              onChanged: (_) =>
                  ref.read(checklistProvider.notifier).toggle(item.itemId),
              title: Text(item.label),
              subtitle: item.officialConfirmed
                  ? null
                  : Text(item.note == null
                      ? CoreFeatureText.confirmNeeded
                      : '${CoreFeatureText.confirmNeeded}: ${item.note}'),
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
        ],
      );
    }

    final override = itemsOverride;
    return Scaffold(
      appBar: AppBar(title: const Text(CoreFeatureText.checklistTitle)),
      body: override != null
          ? body(override)
          : FutureBuilder<List<ChecklistItem>>(
              future: loadChecklist(),
              builder: (context, snap) => snap.hasData
                  ? body(snap.data!)
                  : const Center(child: CircularProgressIndicator()),
            ),
    );
  }
}

/// 更新ログ。
class UpdateLogView extends StatelessWidget {
  const UpdateLogView({super.key, this.entriesFuture});

  /// テスト用。null なら assets から読む。
  final Future<List<UpdateLogEntry>>? entriesFuture;

  static String _date(DateTime d) =>
      '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text(CoreFeatureText.updateLogTitle)),
      body: FutureBuilder<List<UpdateLogEntry>>(
        future: entriesFuture ?? loadUpdateLog(),
        builder: (context, snap) {
          if (!snap.hasData)
            return const Center(child: CircularProgressIndicator());
          final entries = snap.data!;
          if (entries.isEmpty) {
            return const Center(child: Text(CoreFeatureText.updateLogEmpty));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final e in entries)
                Card(
                  child: ListTile(
                    title: Text(e.title),
                    subtitle: Text([
                      '${_date(e.date)} ・ ${CoreFeatureText.updateKind(e.kind)}'
                          '${e.affectedQuestions > 0 ? ' ・ ${CoreFeatureText.affected(e.affectedQuestions)}' : ''}'
                          '${e.versionRef != null ? ' ・ ${e.versionRef}' : ''}',
                      if (e.detail != null) e.detail!,
                    ].join('\n')),
                    isThreeLine: e.detail != null,
                    titleTextStyle: theme.textTheme.titleSmall,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// 学習履歴のCSV書き出し。保存・共有のプラグインは足さず、コピーで渡す。
class HistoryExportView extends ConsumerWidget {
  const HistoryExportView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(historyProvider);
    final questions =
        ref.watch(allQuestionsProvider).valueOrNull ?? const <Question>[];
    final csv = historyCsvText(records, questions);
    return Scaffold(
      appBar: AppBar(title: const Text(CoreFeatureText.exportTitle)),
      body: records.isEmpty
          ? const Center(
              child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(CoreFeatureText.exportEmpty)))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(CoreFeatureText.exportNote,
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 8),
                FilledButton.icon(
                  key: const ValueKey('copyCsv'),
                  icon: const Icon(Icons.copy),
                  label: const Text(CoreFeatureText.exportCopy),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: csv));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text(CoreFeatureText.exportCopied)));
                  },
                ),
                const SizedBox(height: 12),
                SelectableText(csv,
                    style:
                        const TextStyle(fontFamily: 'monospace', fontSize: 12)),
              ],
            ),
    );
  }
}

/// 設定タブに置く、更新ログ・履歴書き出しの入口。
class CoreFeatureSettingsTiles extends ConsumerWidget {
  const CoreFeatureSettingsTiles({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exportOk = isPremiumFor(ref, PremiumFeature.historyExport);
    return Card(
      child: Column(
        children: [
          ListTile(
            key: const ValueKey('updateLogTile'),
            leading: const Icon(Icons.history_toggle_off_outlined),
            title: const Text(CoreFeatureText.updateLogTitle),
            subtitle: const Text(CoreFeatureText.updateLogSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const UpdateLogView())),
          ),
          ListTile(
            key: const ValueKey('exportTile'),
            leading: const Icon(Icons.file_download_outlined),
            title: const Text(CoreFeatureText.exportTitle),
            subtitle: Text(exportOk
                ? CoreFeatureText.exportSubtitle
                : CoreFeatureText.premiumNote),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => exportOk
                ? Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => const HistoryExportView()))
                : _showPremiumNote(context),
          ),
        ],
      ),
    );
  }
}
