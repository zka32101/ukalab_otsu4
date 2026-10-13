import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ukalab_core/daily_goal.dart';
import 'package:ukalab_core/ukalab_core.dart';

import 'answered_questions_store.dart';
import 'daily_answer_stats_store.dart';
import 'exercise_coins.dart';
import 'history_store.dart';
import 'srs_store.dart';
import 'subject_stats_history_store.dart';
import 'subject_stats_store.dart';

/// 1問の解答を、通常の演習(`PracticeSessionView`)と同じ記録先へ書く。
///
/// 解答履歴(間違いノートの元データ)・推しの進捗とコイン・日別の解答数・苦手問題の復習(SRS)・
/// デイリーミッション・解答済み問題・分野別の統計とその推移。連続正解(コンボ)は演習画面だけが持つので含めない。
/// 一問一答の演習と、ながらセッション(`NagaraStudyView`)の両方から呼ぶ。
///
/// [isActive] は、非同期の後続処理(デイリーミッション・分野別統計の推移の保存)を続けてよいかの確認。
/// 画面が閉じていたら false を返す。
void recordPracticeAnswer(
  WidgetRef ref,
  Question q, {
  required bool correct,
  bool Function()? isActive,
}) {
  bool active() => isActive?.call() ?? true;
  ref.read(historyProvider.notifier).record(q, correct: correct);
  recordExerciseAnswer(ref, correct: correct);
  ref.read(dailyAnswerStatsProvider.notifier).recordAnswer(correct: correct);
  ref.read(srsProvider.notifier).review(qid: q.qid, correct: correct);
  ref.read(dailyGoalProvider.notifier).recordAnswer().then((_) {
    if (!active()) return;
    final goal = ref.read(dailyGoalProvider);
    ref.read(dailyGoalHistoryProvider.notifier).recordSnapshot(
          date: goal.todayDate ?? DateTime.now(),
          count: goal.todayCount,
          achieved: goal.achieved,
        );
  });
  ref.read(answeredQuestionsProvider.notifier).record(q.qid);
  ref.read(subjectStatsProvider.notifier).recordAnswer(subjectId: q.subjectId, correct: correct).then((_) {
    if (!active()) return;
    ref.read(subjectStatsHistoryProvider.notifier).recordSnapshot(ref.read(subjectStatsProvider));
  });
}
