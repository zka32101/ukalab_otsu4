import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ukalab_core/ui.dart';
import 'package:ukalab_core/ukalab_core.dart';

import '../data/daily_answer_stats_store.dart';
import '../data/history_store.dart';
import '../data/mock_history_store.dart';
import '../data/progress_store.dart';

/// 祝い済みの節目の保存先(端末内。キー `ukalab_oshi_growth_otsu4`)。テストでは差し替えられる。
final oshiGrowthServiceProvider = Provider<OshiGrowthService>(
  (ref) => OshiGrowthService(store: SharedPreferencesOshiGrowthStore('otsu4')),
);

DateTime _day(DateTime t) => DateTime(t.year, t.month, t.day);

/// 推しの成長演出に渡す累計(個人情報・問題IDは入れない)。
///
/// - 累計の回答数: 演習の解答数(`ProgressSnapshot.answered`。上限なしの累計)。
/// - 学習日数: 解答履歴・模擬試験の履歴・日別の解答数に残っている「学習した日」の合計(連続ではない)。
///   履歴には保存件数の上限があるため、非常に長く使うと古い日が数えられなくなることがある。
OshiGrowthProgress oshiGrowthProgressFor({
  required ProgressSnapshot progress,
  required List<ProgressRecord> records,
  required List<MockHistoryEntry> mockHistory,
  required List<DailyAnswerStatsEntry> dailyStats,
}) {
  final days = <DateTime>{
    for (final r in records) _day(r.at),
    for (final m in mockHistory) _day(m.at),
    for (final d in dailyStats)
      if (d.answered > 0) _day(d.date),
  };
  return OshiGrowthProgress(totalAnswered: progress.answered, studyDays: days.length);
}

OshiGrowthProgress _watchProgress(WidgetRef ref) => oshiGrowthProgressFor(
      progress: ref.watch(progressProvider),
      records: ref.watch(historyProvider),
      mockHistory: ref.watch(mockHistoryProvider),
      dailyStats: ref.watch(dailyAnswerStatsProvider),
    );

/// ホーム(記録)の「これまでの積み重ね」への推しの反応(タップで別の一言)。
/// 表示のたびに、新しく迎えた節目があれば一度だけ祝福ダイアログを出す(複数まとめて迎えても1回)。
class OshiGrowthSection extends ConsumerStatefulWidget {
  const OshiGrowthSection({super.key});

  @override
  ConsumerState<OshiGrowthSection> createState() => _OshiGrowthSectionState();
}

class _OshiGrowthSectionState extends ConsumerState<OshiGrowthSection> {
  @override
  void initState() {
    super.initState();
    _celebrate();
  }

  Future<void> _celebrate() async {
    try {
      // 履歴の読み込み完了を待つ(読み込み前の少ない累計で判定しない)。
      await ref.read(historyProvider.notifier).ready;
      if (!mounted) return;
      final service = ref.read(oshiGrowthServiceProvider);
      await service.load();
      final milestone = await service.checkHeadline(oshiGrowthProgressFor(
        progress: ref.read(progressProvider),
        records: ref.read(historyProvider),
        mockHistory: ref.read(mockHistoryProvider),
        dailyStats: ref.read(dailyAnswerStatsProvider),
      ));
      if (milestone == null || !mounted) return;
      await showOshiGrowthDialog(context, milestone: milestone);
    } catch (_) {
      // 保存に失敗したときは記録されず、次回また祝える。
    }
  }

  @override
  Widget build(BuildContext context) => OshiGrowthBubble(progress: _watchProgress(ref));
}
