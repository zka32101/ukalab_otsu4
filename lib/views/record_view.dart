import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ukalab_core/ukalab_core.dart';

import 'package:ukalab_core/achievements.dart' as core;
import '../data/achievements.dart';
import '../data/combo_store.dart';
import 'package:ukalab_core/daily_goal.dart';
import '../data/exam_repository.dart';
import '../data/mock_history_store.dart';
import '../data/progress_store.dart';
import '../data/selected_level_store.dart';
import '../data/srs_store.dart';
import '../data/subject_stats_history_store.dart';
import '../data/subject_stats_store.dart';
import '../widgets/achievement_share_card.dart';
import 'focus_training_view.dart';
import 'mock_report_view.dart';
import 'srs_calendar_view.dart';
import 'srs_item_list_view.dart';
import 'streak_calendar_view.dart';
import 'weak_review_view.dart';

/// 学習記録。正式な出題範囲（`Question`）の網羅率・正答率はまだ無い
/// （問題データ未着手）ため、`ProgressSnapshot`（演習の解答数）を暫定の
/// 記録として表示する（`lib/data/progress_store.dart`・README参照）。
/// 苦手問題の復習（間隔反復。`lib/data/srs_store.dart`）の状況と、
/// 模擬試験の結果履歴（`lib/data/mock_history_store.dart`）も表示する。
class RecordView extends ConsumerWidget {
  const RecordView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider);
    final theme = Theme.of(context);
    final mockHistory = ref.watch(mockHistoryProvider);
    final subjectStats = ref.watch(subjectStatsProvider);
    final subjectStatsHistory = ref.watch(subjectStatsHistoryProvider);
    final dailyGoalHistory = ref.watch(dailyGoalHistoryProvider);
    final exam = ref.watch(examConfigProvider).valueOrNull;
    final selectedLevelId = ref.watch(selectedLevelIdProvider);

    if (progress.answered == 0 && mockHistory.isEmpty) {
      return const EmptyState(
        message: '学習記録はまだありません。学ぶタブの演習から始めましょう。',
        icon: Icons.insights_outlined,
      );
    }

    final srs = ref.watch(srsProvider);
    final dueCount = ref.watch(dueWeakQidsProvider).length;
    final masteredCount = srs.values.where((i) => i.box == Srs.maxBox).length;
    final bestCombo = ref.watch(comboProvider);
    final achievedStreak = effectiveAchievedStreak(ref.watch(dailyGoalProvider), DateTime.now());
    final achievements = buildAchievements(
      answered: progress.answered,
      streakDays: progress.streakDays,
      mockHistory: mockHistory,
      subjectStats: subjectStats,
      bestCombo: bestCombo,
      masteredCount: masteredCount,
      achievedStreak: achievedStreak,
    );
    final unlockedCount = achievements.where((a) => a.unlocked).length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.emoji_events_outlined),
            title: Text('実績（$unlockedCount / ${achievements.length}）'),
            subtitle: const Text('連続学習日数・解答数・模試合格等のバッジを確認できます'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => core.AchievementsView(
                  categoryLabels: achievementCategoryLabels,
                  shareCardBuilder: (a, date) => AchievementShareCard(achievement: a, date: date),
                )),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (progress.answered > 0) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('これまでの演習', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 12),
                  _StatRow(label: '解答数', value: '${progress.answered}問'),
                  _StatRow(label: '正解数', value: '${progress.correct}問'),
                  _StatRow(
                    label: '正答率',
                    value: '${(progress.accuracy * 100).round()}%',
                  ),
                  _StatRow(label: '連続学習日数', value: '${progress.streakDays}日'),
                  if (latestStreakMilestone(progress.streakDays) != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.emoji_events_outlined, size: 18, color: theme.colorScheme.primary),
                        const SizedBox(width: 6),
                        Text(
                          '${latestStreakMilestone(progress.streakDays)}日連続達成！',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const StreakCalendarView()),
                    ),
                    child: const Text('学習カレンダーを見る'),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (dailyGoalHistory.length > 1) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('デイリーミッションの達成履歴', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(
                    '直近${dailyGoalHistory.length}日分の記録です',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  _DailyGoalHistoryChart(history: dailyGoalHistory),
                ],
              ),
            ),
          ),
        ],
        if (srs.isNotEmpty) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('苦手問題の復習', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 12),
                  _StatRow(label: '間違えて記録中の問題', value: '${srs.length}問'),
                  _StatRow(label: '復習待ち', value: '$dueCount問'),
                  _StatRow(label: '定着した問題', value: '$masteredCount問'),
                  const SizedBox(height: 12),
                  Text('箱（Box）別の分布', style: theme.textTheme.bodySmall),
                  const SizedBox(height: 8),
                  _SrsBoxDistributionChart(distribution: srsBoxDistribution(srs.values)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (dueCount > 0)
                        FilledButton.tonal(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const WeakReviewView()),
                          ),
                          child: const Text('復習する'),
                        ),
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SrsCalendarView()),
                        ),
                        child: const Text('復習カレンダー'),
                      ),
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SrsItemListView()),
                        ),
                        child: const Text('問題ごとの詳細'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
        if (mockHistory.isNotEmpty) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('模擬試験の結果', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 12),
                  for (final entry in mockHistory.reversed.take(5))
                    MockHistoryRow(entry: entry, exam: exam, levelId: selectedLevelId),
                  if (mockHistory.length > 1) ...[
                    const SizedBox(height: 12),
                    MockScoreTrendChart(
                      series: [for (final e in mockHistory) e.pct / 100],
                    ),
                  ],
                  if (mockHistory.length > 1 && exam != null) ...[
                    const SizedBox(height: 8),
                    PassPredictionRow(
                      history: mockHistory,
                      passPct: currentLevel(exam, selectedLevelId).passRule.totalPct,
                    ),
                  ],
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MockReportView()),
                    ),
                    child: const Text('成績レポートを見る'),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (subjectStats.isNotEmpty) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('分野別の正答率', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 12),
                  for (final s in orderedSubjects(exam, subjectStats))
                    SubjectStatRow(label: s.$1, stat: s.$2),
                ],
              ),
            ),
          ),
        ],
        if (subjectStats.length > 1) ...[
          const SizedBox(height: 12),
          _WeakMapCard(exam: exam, subjectStats: subjectStats),
        ],
        if (subjectStatsHistory.length > 1) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('分野別正答率の推移', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(
                    '直近${subjectStatsHistory.length}日分の記録です',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  for (final s in _orderedSubjectIdsAndNames(exam, subjectStats))
                    SubjectTrendRow(
                      label: s.$2,
                      series: [
                        for (final e in subjectStatsHistory) e.accuracyBySubject[s.$1] ?? 0,
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Text(
          '一問一答・画期的な機能（温度の実験室・貯蔵所パズル・消火マッチング・'
          '違反探しモード・現場の1日）の解答を合計した、暫定の記録です。'
          '正式な出題範囲の問題データが入ったら、科目別の網羅率・正答率に切り替わります。',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// 模擬試験の結果1回分の行。日時・得点率・合否を表示する。
/// [entry] の科目別データ（`subjectScore`/`subjectMax`）のうち、[exam] の
/// 科目別合格基準（`passRule.subjectMinPct`）に満たなかった科目の名前を返す。
/// 科目別データ・しきい値・[exam] のいずれかが無ければ空リスト。[levelId] を
/// 指定すると、その類（`LevelConfig`）の合格基準を使う（未指定なら先頭）。
List<String> shortfallSubjectNames(MockHistoryEntry entry, ExamConfig? exam, {String? levelId}) {
  final subjectMinPct = exam == null ? null : currentLevel(exam, levelId).passRule.subjectMinPct;
  final scores = entry.subjectScore;
  if (exam == null || subjectMinPct == null || scores == null) return [];
  return [
    for (final subjectId in scores.keys)
      if ((entry.subjectPct(subjectId) ?? 100) < subjectMinPct)
        exam.subjects
            .firstWhere(
              (s) => s.subjectId == subjectId,
              orElse: () => SubjectConfig(subjectId: subjectId, name: subjectId, order: 0),
            )
            .name,
  ];
}

class MockHistoryRow extends StatelessWidget {
  const MockHistoryRow({required this.entry, this.exam, this.levelId});

  final MockHistoryEntry entry;

  /// 渡すと、不合格だった科目（足切り）のバッジを表示する。
  final ExamConfig? exam;

  /// 足切り判定に使う類（`LevelConfig.levelId`）。未指定なら先頭の類。
  final String? levelId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final at = entry.at;
    final dateText =
        '${at.year}/${at.month.toString().padLeft(2, '0')}/${at.day.toString().padLeft(2, '0')}';
    final shortfalls = shortfallSubjectNames(entry, exam, levelId: levelId);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                entry.passed ? Icons.check_circle : Icons.cancel_outlined,
                color: entry.passed ? theme.colorScheme.primary : theme.colorScheme.error,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(dateText, style: theme.textTheme.bodyMedium)),
              Expanded(
                flex: 2,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (entry.pct / 100).clamp(0, 1),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                flex: 2,
                child: Text(
                  '${entry.score}/${entry.max}（${entry.pct.round()}%）',
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          if (shortfalls.isNotEmpty) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (final name in shortfalls)
                  Chip(
                    label: Text('$name 足切り', style: theme.textTheme.labelSmall),
                    backgroundColor: theme.colorScheme.errorContainer,
                    labelStyle: TextStyle(color: theme.colorScheme.onErrorContainer),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// デイリーミッションの達成履歴。古い順に、その日の解答数を目標達成の有無で
/// 色分けした横棒で表示する（復習カレンダーと同じ横棒の表現を使う）。
class _DailyGoalHistoryChart extends StatelessWidget {
  const _DailyGoalHistoryChart({required this.history});

  final List<DailyGoalHistoryEntry> history;

  static const _weekdayLabels = ['月', '火', '水', '木', '金', '土', '日'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxCount = history.map((e) => e.count).fold<int>(0, (a, b) => a > b ? a : b);
    return Column(
      children: [
        for (final entry in history)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 56,
                  child: Text(
                    '${entry.date.month}/${entry.date.day}'
                    '（${_weekdayLabels[entry.date.weekday - 1]}）',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) => Stack(
                      children: [
                        Container(
                          height: 14,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        if (maxCount > 0 && entry.count > 0)
                          Container(
                            height: 14,
                            width: constraints.maxWidth * (entry.count / maxCount).clamp(0.08, 1.0),
                            decoration: BoxDecoration(
                              color: entry.achieved ? theme.colorScheme.primary : theme.colorScheme.outline,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 36,
                  child: Text(
                    '${entry.count}問',
                    textAlign: TextAlign.right,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// 模擬試験の得点率の推移。古い順の得点率（0.0〜1.0）を折れ線グラフで表示する。
class MockScoreTrendChart extends StatelessWidget {
  const MockScoreTrendChart({required this.series, this.title = '得点率の推移'});

  final List<double> series;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.bodySmall),
        const SizedBox(height: 4),
        SizedBox(
          height: 48,
          child: CustomPaint(
            size: const Size(double.infinity, 48),
            painter: TrendPainter(series: series, color: theme.colorScheme.primary),
          ),
        ),
      ],
    );
  }
}

/// 模試の合格ライン到達見込み1行。直近の傾向に応じたアイコン・メッセージを表示する。
/// [subjectId] を指定すると、その科目のデータがある回だけを対象にした
/// 科目別の見込みを表示する（データが揃っていなければ何も表示しない）。
class PassPredictionRow extends StatelessWidget {
  const PassPredictionRow({required this.history, required this.passPct, this.subjectId});

  final List<MockHistoryEntry> history;
  final double passPct;
  final String? subjectId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subject = subjectId;
    final prediction = subject == null
        ? predictPassTrend(history, passPct: passPct)
        : predictSubjectPassTrend(history, subject, passPct: passPct);
    if (prediction == null) return const SizedBox.shrink();
    final (icon, text, color) = switch (prediction) {
      PassPrediction.onTrack => (
          Icons.check_circle_outline,
          '直近の平均が合格ラインに達しています。この調子で続けましょう',
          theme.colorScheme.primary,
        ),
      PassPrediction.closeToTarget => (
          Icons.trending_up,
          'もう少しで合格ラインに届きそうです',
          theme.colorScheme.secondary,
        ),
      PassPrediction.needsWork => (
          Icons.priority_high,
          'まだ合格ラインまで距離があります。苦手分野の復習がおすすめです',
          theme.colorScheme.error,
        ),
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: theme.textTheme.bodySmall?.copyWith(color: color))),
      ],
    );
  }
}

/// 連続学習日数のマイルストーン（節目）。
const List<int> streakMilestones = [3, 7, 14, 30, 60, 100, 200, 365];

/// 現在の連続学習日数が到達している、最も大きいマイルストーン。
/// どれにも達していなければ null。
int? latestStreakMilestone(int streakDays) {
  int? latest;
  for (final d in streakMilestones) {
    if (streakDays >= d) latest = d;
  }
  return latest;
}

/// データがある分野だけ、`ExamConfig` の並び順で（名前, 統計）を返す。
/// `exam` が未取得（読み込み中）なら subjectId をそのまま名前にする。
List<(String, SubjectStat)> orderedSubjects(ExamConfig? exam, Map<String, SubjectStat> stats) {
  if (exam == null) {
    return [for (final e in stats.entries) (e.key, e.value)];
  }
  final subjects = [...exam.subjects]..sort((a, b) => a.order.compareTo(b.order));
  return [
    for (final s in subjects)
      if (stats.containsKey(s.subjectId)) (s.name, stats[s.subjectId]!),
  ];
}

/// データがある分野だけ、`ExamConfig` の並び順で（subjectId, 名前, 統計）を返す
/// （成績レポートからの苦手分野への直接ジャンプ用。`orderedSubjects` と並び順は
/// 同じだが、`FocusTrainingView` に渡す subjectId も持つ）。
List<(String, String, SubjectStat)> orderedSubjectsWithId(
  ExamConfig? exam,
  Map<String, SubjectStat> stats,
) {
  if (exam == null) {
    return [for (final e in stats.entries) (e.key, e.key, e.value)];
  }
  final subjects = [...exam.subjects]..sort((a, b) => a.order.compareTo(b.order));
  return [
    for (final s in subjects)
      if (stats.containsKey(s.subjectId)) (s.subjectId, s.name, stats[s.subjectId]!),
  ];
}

/// データがある分野だけ、`ExamConfig` の並び順で（subjectId, 名前）を返す
/// （「分野別正答率の推移」用。履歴のキーは subjectId のため）。
List<(String, String)> _orderedSubjectIdsAndNames(ExamConfig? exam, Map<String, SubjectStat> stats) {
  if (exam == null) {
    return [for (final id in stats.keys) (id, id)];
  }
  final subjects = [...exam.subjects]..sort((a, b) => a.order.compareTo(b.order));
  return [
    for (final s in subjects)
      if (stats.containsKey(s.subjectId)) (s.subjectId, s.name),
  ];
}

/// 分野別正答率の推移1行。分野名・最新の正答率・折れ線の推移を表示する。
/// 成績レポート（`lib/views/mock_report_view.dart`）の分野別比較でも使う。
class SubjectTrendRow extends StatelessWidget {
  const SubjectTrendRow({required this.label, required this.series});

  final String label;
  final List<double> series;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final latest = series.isEmpty ? 0.0 : series.last;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
              const SizedBox(width: 8),
              Text('${(latest * 100).round()}%', style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 36,
            child: CustomPaint(
              size: const Size(double.infinity, 36),
              painter: TrendPainter(series: series, color: theme.colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}

/// 折れ線グラフの描画。series は古い順の正答率（0.0〜1.0）。
class TrendPainter extends CustomPainter {
  TrendPainter({required this.series, required this.color});

  final List<double> series;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (series.length < 2) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path();
    final dx = size.width / (series.length - 1);
    for (var i = 0; i < series.length; i++) {
      final x = dx * i;
      final y = size.height * (1 - series[i].clamp(0.0, 1.0));
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant TrendPainter oldDelegate) =>
      oldDelegate.series != series || oldDelegate.color != color;
}

/// データがある分野を、正答率が低い順に（名前, 統計）で返す
/// （「弱点マップ」用）。`exam` が未取得なら subjectId をそのまま名前にする。
List<(String, SubjectStat)> sortedByWeakness(ExamConfig? exam, Map<String, SubjectStat> stats) {
  final named = exam == null
      ? [for (final e in stats.entries) (e.key, e.value)]
      : orderedSubjects(exam, stats);
  return [...named]..sort((a, b) => a.$2.accuracy.compareTo(b.$2.accuracy));
}

/// データがある分野を、正答率が低い順に（subjectId, 名前, 統計）で返す
/// （「弱点マップ」タップでその分野の演習に遷移するためsubjectIdも保持する）。
/// `exam` が未取得なら subjectId をそのまま名前にする。
List<(String, String, SubjectStat)> sortedByWeaknessWithId(
  ExamConfig? exam,
  Map<String, SubjectStat> stats,
) {
  final List<(String, String, SubjectStat)> named;
  if (exam == null) {
    named = [for (final e in stats.entries) (e.key, e.key, e.value)];
  } else {
    final subjects = [...exam.subjects]..sort((a, b) => a.order.compareTo(b.order));
    named = [
      for (final s in subjects)
        if (stats.containsKey(s.subjectId)) (s.subjectId, s.name, stats[s.subjectId]!),
    ];
  }
  return [...named]..sort((a, b) => a.$3.accuracy.compareTo(b.$3.accuracy));
}

/// 弱点マップのカード。横棒グラフ表示と円グラフ表示を切り替えられる
/// （`_pieMode`。円グラフは正答率ではなく分野ごとの解答数の内訳を示す）。
class _WeakMapCard extends StatefulWidget {
  const _WeakMapCard({required this.exam, required this.subjectStats});

  final ExamConfig? exam;
  final Map<String, SubjectStat> subjectStats;

  @override
  State<_WeakMapCard> createState() => _WeakMapCardState();
}

class _WeakMapCardState extends State<_WeakMapCard> {
  bool _pieMode = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ranked = sortedByWeaknessWithId(widget.exam, widget.subjectStats);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('弱点マップ', style: theme.textTheme.titleSmall)),
                IconButton(
                  tooltip: _pieMode ? 'リスト表示に切り替え' : '円グラフ表示に切り替え',
                  icon: Icon(_pieMode ? Icons.bar_chart : Icons.pie_chart_outline),
                  onPressed: () => setState(() => _pieMode = !_pieMode),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _pieMode ? '分野ごとの解答数の内訳です' : '正答率が低い分野から順に並べています。タップするとその分野を演習できます',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            if (_pieMode)
              _WeakMapPie(ranked: ranked)
            else
              for (final s in ranked)
                _WeakMapBar(
                  label: s.$2,
                  stat: s.$3,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => FocusTrainingView(subjectId: s.$1, subjectName: s.$2),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

/// 弱点マップの円グラフ表示。分野ごとの解答数の割合を扇形で示し、下に凡例
/// （分野名・正答率）を並べる。
class _WeakMapPie extends StatelessWidget {
  const _WeakMapPie({required this.ranked});

  final List<(String, String, SubjectStat)> ranked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = [
      theme.colorScheme.primary,
      theme.colorScheme.secondary,
      theme.colorScheme.tertiary,
      theme.colorScheme.error,
    ];
    final total = ranked.fold<int>(0, (sum, s) => sum + s.$3.answered);
    return Column(
      children: [
        SizedBox(
          width: 140,
          height: 140,
          child: CustomPaint(
            painter: _PieChartPainter(
              values: [for (final s in ranked) s.$3.answered.toDouble()],
              colors: colors,
            ),
          ),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < ranked.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Container(width: 12, height: 12, color: colors[i % colors.length]),
                const SizedBox(width: 8),
                Expanded(child: Text(ranked[i].$2, style: theme.textTheme.bodySmall)),
                Text(
                  total == 0 ? '0%' : '${(ranked[i].$3.answered * 100 / total).round()}%',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// 円グラフを描画する。[values] の合計が0のときは何も描かない。
class _PieChartPainter extends CustomPainter {
  _PieChartPainter({required this.values, required this.colors});

  final List<double> values;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<double>(0, (sum, v) => sum + v);
    if (total <= 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    var startAngle = -3.14159265 / 2;
    for (var i = 0; i < values.length; i++) {
      final sweep = values[i] / total * 2 * 3.14159265;
      if (sweep <= 0) continue;
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.fill;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweep, true, paint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.colors != colors;
}

/// 弱点マップの1行。正答率に応じて色を変えた横棒グラフ。タップでその分野の
/// 演習に遷移する。
class _WeakMapBar extends StatelessWidget {
  const _WeakMapBar({required this.label, required this.stat, required this.onTap});

  final String label;
  final SubjectStat stat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = stat.accuracy < weakSubjectAccuracyThreshold
        ? theme.colorScheme.error
        : theme.colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
                const SizedBox(width: 8),
                Row(
                  children: [
                    Text(
                      '${(stat.accuracy * 100).round()}%',
                      style: theme.textTheme.bodySmall?.copyWith(color: color),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, size: 16),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            LayoutBuilder(
              builder: (context, constraints) => Stack(
                children: [
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Container(
                    height: 8,
                    width: constraints.maxWidth * stat.accuracy.clamp(0, 1),
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 分野別の正答率1行。解答数・正答率バーを表示する。
class SubjectStatRow extends StatelessWidget {
  const SubjectStatRow({required this.label, required this.stat});

  final String label;
  final SubjectStat stat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Expanded(
            flex: 2,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: stat.accuracy, minHeight: 8),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 2,
            child: Text(
              '${stat.correct}/${stat.answered}（${(stat.accuracy * 100).round()}%）',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

/// 苦手問題の復習の、箱（Box 0〜`Srs.maxBox`）別の問題数の横棒グラフ。
/// 箱が大きいほど復習間隔が長く定着が進んでいることを示す
/// （`lib/data/srs_store.dart` の `srsBoxDistribution`）。
class _SrsBoxDistributionChart extends StatelessWidget {
  const _SrsBoxDistributionChart({required this.distribution});

  final Map<int, int> distribution;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxCount = distribution.values.isEmpty
        ? 0
        : distribution.values.reduce((a, b) => a > b ? a : b);
    final boxes = distribution.keys.toList()..sort();
    return Column(
      children: [
        for (final box in boxes)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                SizedBox(
                  width: 48,
                  child: Text('箱$box', style: theme.textTheme.bodySmall),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) => Stack(
                      children: [
                        Container(
                          height: 10,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        if (maxCount > 0 && (distribution[box] ?? 0) > 0)
                          Container(
                            height: 10,
                            width: constraints.maxWidth *
                                ((distribution[box] ?? 0) / maxCount).clamp(0.08, 1.0),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 32,
                  child: Text(
                    '${distribution[box] ?? 0}問',
                    textAlign: TextAlign.right,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          const SizedBox(width: 12),
          Flexible(child: Text(value, style: theme.textTheme.titleSmall, textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}
