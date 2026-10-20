import 'package:app_common_kit/app_common_kit.dart' show EntitlementState, entitlementStateProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ukalab_core/ukalab_core.dart';

import '../data/answered_questions_store.dart';
import 'package:ukalab_core/daily_goal.dart';
import '../data/exam_repository.dart';
import '../data/mock_wrong_store.dart';
import '../data/question_repository.dart';
import '../data/selected_level_store.dart';
import '../data/srs_store.dart';
import '../data/subject_stats_store.dart';
import '../widgets/learn_tools_section.dart';
import 'extinguisher_match_view.dart';
import 'field_day_view.dart';
import 'focus_training_view.dart';
import 'mock_wrong_review_view.dart';
import 'practice_session_view.dart';
import 'question_search_view.dart';
import 'storage_puzzle_view.dart';
import 'study_tools_view.dart';
import 'temperature_lab_view.dart';
import 'violation_hunt_view.dart';
import 'weak_review_view.dart';
import 'package:ukalab_core/answer_feedback.dart' show WeakSummaryCard, canShowWeakSummary;
import '../data/history_store.dart';

/// 一問一答の演習（問題データが無ければ空状態）と、体験型の演習（画期的な
/// 機能A〜E）への入り口。体験型の演習は一問一答の問題データの有無に
/// かかわらず常に表示する。
class StudyView extends ConsumerStatefulWidget {
  const StudyView({super.key});

  @override
  ConsumerState<StudyView> createState() => _StudyViewState();
}

class _StudyViewState extends ConsumerState<StudyView> {
  final _examRepo = const ExamRepository();
  final _repo = const QuestionRepository();
  ExamConfig? _exam;
  List<Question>? _questions;
  String? _subjectFilter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final exam = await _examRepo.load();
    final qs = await _repo.load();
    if (!mounted) return;
    setState(() {
      _exam = exam;
      _questions = qs;
    });
  }

  /// 問題データがある分野だけ、`ExamConfig` の並び順で返す。
  List<SubjectConfig> _availableSubjects(ExamConfig exam, List<Question> qs) {
    final ids = qs.map((q) => q.subjectId).toSet();
    final subjects = [for (final s in exam.subjects) if (ids.contains(s.subjectId)) s];
    subjects.sort((a, b) => a.order.compareTo(b.order));
    return subjects;
  }

  @override
  Widget build(BuildContext context) {
    final exam = _exam;
    final allQs = _questions;
    if (exam == null || allQs == null) return const Center(child: CircularProgressIndicator());
    final theme = Theme.of(context);
    // 選択中の類（乙4・乙1等）に関係する科目だけに絞る。他の類の性質消火の
    // 問題が混ざって表示されないようにする。
    final level = currentLevel(exam, ref.watch(selectedLevelIdProvider));
    final relevantSubjectIds = level.subjectQuestionCounts?.keys.toSet();
    final qs = relevantSubjectIds == null
        ? allQs
        : [for (final q in allQs) if (relevantSubjectIds.contains(q.subjectId)) q];
    final dueQids = ref.watch(dueWeakQidsProvider).toSet();
    final dueCount = qs.where((q) => dueQids.contains(q.qid)).length;
    final dailyGoal = ref.watch(dailyGoalProvider);
    final weakIds = weakSubjectIds(ref.watch(subjectStatsProvider)).toSet();
    final weakQuestionCount = qs.where((q) => weakIds.contains(q.subjectId)).length;
    final mockWrongQids = ref.watch(mockWrongProvider).toSet();
    final mockWrongCount = qs.where((q) => mockWrongQids.contains(q.qid)).length;
    final goalStreak = effectiveAchievedStreak(dailyGoal, DateTime.now());
    final answeredQids = ref.watch(answeredQuestionsProvider);
    final coverage = subjectCoverage(qs, answeredQids);
    final subjects = _availableSubjects(exam, qs);
    final filter = _subjectFilter;
    final filteredQs = filterBySubject(qs, filter);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.apps_outlined),
            title: const Text('学習ツール一覧'),
            subtitle: const Text('用語集・検索・メモ・復習カレンダー等をまとめて見渡せます'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const StudyToolsView()),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (dailyGoal.target != null) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    dailyGoal.achieved ? Icons.celebration_outlined : Icons.flag_outlined,
                    color: dailyGoal.achieved ? theme.colorScheme.primary : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dailyGoal.achieved ? '今日の目標を達成しました！' : '今日のデイリーミッション',
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (dailyGoal.todayCount / dailyGoal.target!).clamp(0, 1),
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${dailyGoal.todayCount} / ${dailyGoal.target}問',
                          style: theme.textTheme.bodySmall,
                        ),
                        if (goalStreak > 0) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.local_fire_department_outlined,
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$goalStreak日連続達成',
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: theme.colorScheme.primary),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (dueCount > 0) ...[
          Card(
            child: ListTile(
              leading: const Icon(Icons.history_edu_outlined),
              title: Text('苦手問題の復習（$dueCount問）'),
              subtitle: const Text('間違えた問題を、間隔をあけて優先的に出題します'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const WeakReviewView()),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (weakQuestionCount > 0) ...[
          Card(
            child: ListTile(
              leading: const Icon(Icons.fitness_center_outlined),
              title: Text('集中特訓（$weakQuestionCount問）'),
              subtitle: const Text('正答率が低い分野だけを優先的に演習します'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FocusTrainingView()),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (mockWrongCount > 0) ...[
          Card(
            child: ListTile(
              leading: const Icon(Icons.replay_outlined),
              title: Text('前回の模試の間違い（$mockWrongCount問）'),
              subtitle: const Text('直近の模擬試験で間違えた問題をまとめて復習します'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MockWrongReviewView()),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Card(
          child: ListTile(
            leading: const Icon(Icons.search_outlined),
            title: const Text('重要語句で探す'),
            subtitle: const Text('キーワードから、関連する用語集・問題をまとめて探せます'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const QuestionSearchView()),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (subjects.isNotEmpty) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('分野別の出題網羅率', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 12),
                  for (final s in subjects)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text(s.name, style: theme.textTheme.bodySmall)),
                              const SizedBox(width: 8),
                              Text(
                                '${((coverage[s.subjectId] ?? 0) * 100).round()}%',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: coverage[s.subjectId] ?? 0,
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (subjects.length > 1) ...[
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              ChoiceChip(
                label: const Text('すべて'),
                selected: filter == null,
                onSelected: (_) => setState(() => _subjectFilter = null),
              ),
              for (final s in subjects)
                ChoiceChip(
                  label: Text(s.name),
                  selected: filter == s.subjectId,
                  onSelected: (_) => setState(() => _subjectFilter = s.subjectId),
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        if (canShowWeakSummary(
          isPremium: (ref.watch(entitlementStateProvider).valueOrNull ?? EntitlementState.free).hasPremium,
        )) ...[
          WeakSummaryCard(
            records: ref.watch(historyProvider),
            now: DateTime.now(),
            questions: allQs,
          ),
          const SizedBox(height: 12),
        ],
        PracticeSessionView(
          key: ValueKey(filter),
          pool: filteredQs,
          emptyMessage: filter == null
              ? '一問一答の問題データはまだ多くありません。'
              : 'この分野の問題データはまだありません。',
        ),
        const SizedBox(height: 24),
        Text('体験型の演習', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        _ExperienceCard(
          icon: Icons.thermostat_outlined,
          title: '温度の実験室',
          description: '気温を変えて、引火点を超える物質を確かめよう',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const TemperatureLabView()),
          ),
        ),
        const SizedBox(height: 12),
        _ExperienceCard(
          icon: Icons.inventory_2_outlined,
          title: '貯蔵所パズル',
          description: '指定数量の倍数を計算して、許可が必要か判定しよう',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const StoragePuzzleView()),
          ),
        ),
        const SizedBox(height: 12),
        _ExperienceCard(
          icon: Icons.local_fire_department_outlined,
          title: '消火マッチング',
          description: '物質と消火剤の組み合わせが有効か不適かを答えよう',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ExtinguisherMatchView()),
          ),
        ),
        const SizedBox(height: 12),
        _ExperienceCard(
          icon: Icons.search_outlined,
          title: '違反探しモード',
          description: '4つの行動から、法令・消火の知識に違反しているものを見つけよう',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ViolationHuntView()),
          ),
        ),
        const SizedBox(height: 12),
        _ExperienceCard(
          icon: Icons.work_outline,
          title: '現場の1日',
          description: '1日の勤務を模した4つの場面で、温度・指定数量・消火剤の判断をしよう',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const FieldDayView()),
          ),
        ),
        const SizedBox(height: 24),
        LearnToolsSection(exam: exam),
      ],
    );
  }
}

/// 体験型機能（温度の実験室など）への入り口カード。
class _ExperienceCard extends StatelessWidget {
  const _ExperienceCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: theme.colorScheme.secondary, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(description, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
