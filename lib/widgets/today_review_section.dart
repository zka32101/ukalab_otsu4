import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ukalab_core/ui.dart';
import 'package:ukalab_core/ukalab_core.dart';

import '../data/history_store.dart';
import '../data/mistake_notes.dart';
import '../data/review_schedule.dart';
import '../views/mistake_note_screen.dart';

/// ホームの「今日の復習」。間違いノートの「これから」の問題を、忘れる頃に見返す予定にして、
/// 期限が来た件数だけを穏やかに知らせる(ukalab_core の [TodayReviewCard]。文言・色は core)。
///
/// 復習の出題画面は新しく作らず、「やってみる」は既存の間違いノート([MistakeNoteScreen])を開く。
/// 解き直した結果は解答の記録([recordPracticeAnswer])から復習予定へ反映される。
class TodayReviewSection extends ConsumerStatefulWidget {
  const TodayReviewSection({super.key, required this.exam, this.clock = DateTime.now});

  final ExamConfig exam;
  final DateTime Function() clock;

  @override
  ConsumerState<TodayReviewSection> createState() => _TodayReviewSectionState();
}

class _TodayReviewSectionState extends ConsumerState<TodayReviewSection> {
  @override
  void initState() {
    super.initState();
    _sync();
  }

  /// 間違いノート(保存済み + 最新の解答履歴)から復習予定を同期する。履歴の読み込み完了を待つ。
  Future<void> _sync() async {
    try {
      await ref.read(historyProvider.notifier).ready;
      if (!mounted) return;
      final stored = await mistakeNoteStore.read();
      if (!mounted) return;
      final notes = mistakeNoteEngine.update(stored, ref.read(historyProvider));
      await ref.read(reviewScheduleProvider.notifier).sync(notes);
    } catch (_) {
      // 読めなければ件数 0 のまま(静かに「おやすみ」表示)。
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(historyProvider, (_, __) => _sync());
    final items = ref.watch(reviewScheduleProvider);
    return TodayReviewCard(
      dueCount: reviewSchedulerEngine.dueCount(items, widget.clock()),
      onStart: () async {
        await openMistakeNote(context, ref, exam: widget.exam);
        if (mounted) await _sync();
      },
    );
  }
}
