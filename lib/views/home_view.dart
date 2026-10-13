import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ukalab_core/reminder.dart';
import 'package:ukalab_core/ukalab_core.dart';

import '../data/core_features.dart';
import '../data/daily_answer_stats_store.dart';
import '../data/exam_date_store.dart';
import '../data/exam_repository.dart';
import '../data/glossary.dart';
import '../data/mock_history_store.dart';
import '../data/selected_level_store.dart';
import '../widgets/oshi_card.dart';
import '../widgets/oshi_home_cards.dart';
import 'exam_prep_entry.dart';
import 'mistake_note_screen.dart';
import 'glossary_card_view.dart';

/// ホーム。試験の概要と、学ぶ・模擬への導線。
///
/// 推し（MascotWidget）・コイン残高は `OshiCard` で表示。正式な出題範囲の
/// 網羅率・正答率はまだ無い（問題データ未着手）ため、暫定の進捗指標を使う
/// （`lib/data/progress_store.dart`・README参照）。
class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  final _repo = const ExamRepository();
  ExamConfig? _exam;
  Object? _error;
  bool _showAccuracyTrend = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final exam = await _repo.load();
      if (!mounted) return;
      setState(() => _exam = exam);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return ErrorState(onRetry: () {
        setState(() => _error = null);
        _load();
      });
    }
    final exam = _exam;
    if (exam == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final level = currentLevel(exam, ref.watch(selectedLevelIdProvider));
    final theme = Theme.of(context);
    final reminderSettings = ref.watch(reminderSettingsProvider);
    final examDate = ref.watch(examDateProvider);
    final mockHistory = ref.watch(mockHistoryProvider);
    final showMockReminder = reminderSettings.mockReminderEnabled &&
        shouldShowMockIntervalReminder(mockHistory, DateTime.now());
    final nextMockDate =
        reminderSettings.mockReminderEnabled ? nextRecommendedMockDate(mockHistory) : null;
    final dailyAnswerStats = ref.watch(dailyAnswerStatsProvider);
    final weekly = weeklyAnswerSummary(dailyAnswerStats);
    final weeklyAnswered = weekly.fold<int>(0, (sum, e) => sum + e.answered);
    final weeklyCorrect = weekly.fold<int>(0, (sum, e) => sum + e.correct);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (examDate != null) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.event_outlined, color: theme.colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          examCountdownText(daysUntilExam(examDate, DateTime.now())),
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                    ],
                  ),
                  if (mockHistory.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      passPredictionShortLabel(
                        predictPassTrend(mockHistory, passPct: level.passRule.totalPct),
                      ),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        const StudyReminderCard(),
        const SizedBox(height: 16),
        if (showMockReminder) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.quiz_outlined, color: theme.colorScheme.secondary),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('前回の模擬試験から日が経っています。模擬タブで力試しをしてみましょう'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (!showMockReminder && nextMockDate != null) ...[
          Row(
            children: [
              Icon(Icons.event_note_outlined, size: 16, color: theme.colorScheme.secondary),
              const SizedBox(width: 6),
              Text(nextMockDateText(nextMockDate, DateTime.now()), style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 16),
        ],
        const OshiCard(),
        const SizedBox(height: 8),
        // 推しの一言(無料)。タップで別の一言。
        const OshiMessageCard(),
        const SizedBox(height: 16),
        const ExamCountdownSection(),
        const CoreFeaturesCard(),
        const SizedBox(height: 16),
        // 週間ふりかえり(無料。今週できたことだけを見せる)。
        WeeklyRecapSection(
            exam: exam, questions: ref.watch(allQuestionsProvider).valueOrNull ?? const []),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const Icon(Icons.edit_note_outlined),
            title: const Text('間違いノート'),
            subtitle: const Text('間違えた問題を見返して、解き直せます。'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => openMistakeNote(context, ref, exam: exam),
          ),
        ),
        const SizedBox(height: 16),
        if (glossaryTermOfDay(glossaryTerms, DateTime.now()) != null) ...[
          _TermOfDayCard(term: glossaryTermOfDay(glossaryTerms, DateTime.now())!),
          const SizedBox(height: 16),
        ],
        if (weeklyAnswered > 0) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text('今週の学習サマリー', style: theme.textTheme.titleSmall)),
                      IconButton(
                        tooltip: _showAccuracyTrend ? '解答数のグラフに切り替え' : '正答率の推移に切り替え',
                        icon: Icon(_showAccuracyTrend ? Icons.bar_chart : Icons.show_chart),
                        onPressed: () => setState(() => _showAccuracyTrend = !_showAccuracyTrend),
                      ),
                    ],
                  ),
                  Text(
                    '直近7日間: $weeklyAnswered問 ・ 正答率 ${(weeklyCorrect / weeklyAnswered * 100).round()}%',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  if (_showAccuracyTrend)
                    _WeeklyAccuracyTrendChart(entries: weekly)
                  else
                    _WeeklyAnswerChart(entries: weekly),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        Text('${exam.name}${level.name}', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(
          '全${level.questionCount}問・${(level.timeLimitSec ?? 0) ~/ 60}分・科目別${level.passRule.subjectMinPct?.round() ?? level.passRule.totalPct.round()}%以上で合格',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('出題科目', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                for (final s in exam.subjects)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text('・${s.name}'),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 「今日の一語」カード。用語集から日替わりで1つの用語をピックアップして
/// 表示する（`glossaryTermOfDay`。`lib/data/glossary.dart`）。タップすると
/// 暗記カード（`GlossaryCardView`）でその用語を開ける。
class _TermOfDayCard extends StatelessWidget {
  const _TermOfDayCard({required this.term});

  final GlossaryTerm term;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => GlossaryCardView(initialTerm: term.term)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_stories_outlined, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Text('今日の一語', style: theme.textTheme.titleSmall),
                ],
              ),
              const SizedBox(height: 8),
              Text(term.term, style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(term.definition, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

/// 直近7日間（今日を含む）の解答数のミニ横棒グラフ（日ごとに縦の棒）。
/// [entries] は `weeklyAnswerSummary` が返す、古い順の7件。
class _WeeklyAnswerChart extends StatelessWidget {
  const _WeeklyAnswerChart({required this.entries});

  final List<DailyAnswerStatsEntry> entries;

  static const _weekdayLabels = ['日', '月', '火', '水', '木', '金', '土'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxAnswered = entries.fold<int>(1, (m, e) => e.answered > m ? e.answered : m);
    const maxBarHeight = 48.0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final e in entries)
          Expanded(
            child: Column(
              children: [
                Text('${e.answered}', style: theme.textTheme.labelSmall),
                const SizedBox(height: 2),
                Container(
                  height: e.answered == 0 ? 2 : maxBarHeight * e.answered / maxAnswered,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: e.answered == 0
                        ? theme.colorScheme.surfaceContainerHighest
                        : theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Text(_weekdayLabels[e.date.weekday % 7], style: theme.textTheme.labelSmall),
              ],
            ),
          ),
      ],
    );
  }
}

/// 直近7日間（今日を含む）の正答率の推移ミニグラフ（折れ線、解答数が0の日は
/// グラフから除く）。[entries] は `weeklyAnswerSummary` が返す、古い順の7件。
/// 解答が無い日が多く2点未満しか描けない場合はメッセージを表示する。
class _WeeklyAccuracyTrendChart extends StatelessWidget {
  const _WeeklyAccuracyTrendChart({required this.entries});

  final List<DailyAnswerStatsEntry> entries;

  static const _weekdayLabels = ['日', '月', '火', '水', '木', '金', '土'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final withData = [for (final e in entries) if (e.answered > 0) e];
    if (withData.length < 2) {
      return Text('正答率の推移は、解答した日が2日以上あると表示されます。', style: theme.textTheme.bodySmall);
    }
    return SizedBox(
      height: 64,
      child: CustomPaint(
        size: const Size(double.infinity, 48),
        painter: _AccuracyTrendPainter(
          series: [for (final e in withData) e.accuracy],
          color: theme.colorScheme.primary,
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: 48),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final e in withData)
                Text(_weekdayLabels[e.date.weekday % 7], style: theme.textTheme.labelSmall),
            ],
          ),
        ),
      ),
    );
  }
}

/// 正答率の折れ線を描く（0.0〜1.0のseriesを上=100%・下=0%として描画）。
class _AccuracyTrendPainter extends CustomPainter {
  _AccuracyTrendPainter({required this.series, required this.color});

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
  bool shouldRepaint(covariant _AccuracyTrendPainter oldDelegate) =>
      oldDelegate.series != series || oldDelegate.color != color;
}
