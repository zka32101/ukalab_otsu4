import 'package:ukalab_core/glossary.dart' show learnedTermsDataPart;
import 'package:ukalab_core/ui.dart';
import 'package:ukalab_core/ukalab_core.dart';

import 'package:ukalab_core/achievements.dart';
import 'answered_questions_store.dart';
import 'combo_store.dart';
import 'core_features.dart';
import 'daily_answer_stats_store.dart';
import 'package:ukalab_core/daily_goal.dart';
import 'learned_terms.dart';
import 'history_store.dart';
import 'mock_history_store.dart';
import 'mistake_notes.dart';
import 'mock_wrong_store.dart';
import 'progress_store.dart';
import 'review_schedule.dart';
import 'recent_glossary_terms_store.dart';
import 'srs_store.dart';
import 'subject_stats_history_store.dart';
import 'subject_stats_store.dart';

List<Map<String, dynamic>> _maps(Object? json) => (json as List).cast<Map<String, dynamic>>();

/// 設定タブの「データの管理」（書き出し・読み込み・リセット）の対象。
///
/// 進捗・解答履歴・模試結果・デイリーミッション・分野別統計・苦手問題の復習・
/// 自分用メモ・最近見た用語・コンボの自己最高記録・日別の解答数・正解数・試験当日チェックリストのチェック状態・用語集の
/// 「覚えた」（`learnedTerms`。旧 `glossaryMastered` の旧形式バックアップも読める）・間違いノート・実績バッジの解除通知済みIDが対象。
/// テーマ・リマインダー設定・試験日・用語集のお気に入り・ブックマークは
/// ユーザー設定・curationとして扱い、含めない。
///
/// 各 `id` は、共通化前のバックアップJSONのキーと同じ（互換のため変えない）。
final List<DataPart> otsu4DataParts = [
  DataPart(
    id: 'history',
    export: (ref) => encodeHistory(ref.read(historyProvider)),
    restore: (ref, json) => ref.read(historyProvider.notifier).replace(decodeHistory(json as String?)),
    reset: (ref) => ref.read(historyProvider.notifier).reset(),
  ),
  DataPart(
    id: 'progress',
    export: (ref) => ref.read(progressProvider).toJson(),
    restore: (ref, json) =>
        ref.read(progressProvider.notifier).restore(ProgressSnapshot.fromJson(json as Map<String, dynamic>)),
    reset: (ref) => ref.read(progressProvider.notifier).reset(),
  ),
  DataPart(
    id: 'srs',
    export: (ref) => [for (final i in ref.read(srsProvider).values) i.toJson()],
    restore: (ref, json) => ref.read(srsProvider.notifier).restore({
      for (final j in _maps(json)) SrsItem.fromJson(j).qid: SrsItem.fromJson(j),
    }),
    reset: (ref) => ref.read(srsProvider.notifier).reset(),
  ),
  DataPart(
    id: 'mockHistory',
    export: (ref) => [for (final e in ref.read(mockHistoryProvider)) e.toJson()],
    restore: (ref, json) =>
        ref.read(mockHistoryProvider.notifier).restore([for (final j in _maps(json)) MockHistoryEntry.fromJson(j)]),
    reset: (ref) => ref.read(mockHistoryProvider.notifier).reset(),
  ),
  DataPart(
    id: 'mockWrong',
    export: (ref) => ref.read(mockWrongProvider),
    restore: (ref, json) => ref.read(mockWrongProvider.notifier).setWrong((json as List).cast<String>()),
    reset: (ref) => ref.read(mockWrongProvider.notifier).reset(),
  ),
  DataPart(
    id: 'dailyGoal',
    export: (ref) => ref.read(dailyGoalProvider).toJson(),
    restore: (ref, json) =>
        ref.read(dailyGoalProvider.notifier).restore(DailyGoal.fromJson(json as Map<String, dynamic>)),
    reset: (ref) => ref.read(dailyGoalProvider.notifier).reset(),
  ),
  DataPart(
    id: 'dailyGoalHistory',
    export: (ref) => [for (final e in ref.read(dailyGoalHistoryProvider)) e.toJson()],
    restore: (ref, json) => ref
        .read(dailyGoalHistoryProvider.notifier)
        .restore([for (final j in _maps(json)) DailyGoalHistoryEntry.fromJson(j)]),
    reset: (ref) => ref.read(dailyGoalHistoryProvider.notifier).reset(),
  ),
  DataPart(
    id: 'subjectStats',
    export: (ref) => {for (final e in ref.read(subjectStatsProvider).entries) e.key: e.value.toJson()},
    restore: (ref, json) => ref.read(subjectStatsProvider.notifier).restore({
      for (final e in (json as Map<String, dynamic>).entries)
        e.key: SubjectStat.fromJson(e.value as Map<String, dynamic>),
    }),
    reset: (ref) => ref.read(subjectStatsProvider.notifier).reset(),
  ),
  DataPart(
    id: 'subjectStatsHistory',
    export: (ref) => [for (final e in ref.read(subjectStatsHistoryProvider)) e.toJson()],
    restore: (ref, json) => ref
        .read(subjectStatsHistoryProvider.notifier)
        .restore([for (final j in _maps(json)) SubjectStatsHistoryEntry.fromJson(j)]),
    reset: (ref) => ref.read(subjectStatsHistoryProvider.notifier).reset(),
  ),
  DataPart(
    id: 'answeredQuestions',
    export: (ref) => ref.read(answeredQuestionsProvider).toList(),
    restore: (ref, json) =>
        ref.read(answeredQuestionsProvider.notifier).restore((json as List).cast<String>().toSet()),
    reset: (ref) => ref.read(answeredQuestionsProvider.notifier).reset(),
  ),
  DataPart(
    id: 'questionMemo',
    export: (ref) => ref.read(questionMemoProvider),
    restore: (ref, json) =>
        ref.read(questionMemoProvider.notifier).restore((json as Map<String, dynamic>).cast<String, String>()),
    reset: (ref) => ref.read(questionMemoProvider.notifier).reset(),
  ),
  DataPart(
    id: 'recentGlossaryTerms',
    export: (ref) => ref.read(recentGlossaryTermsProvider),
    restore: (ref, json) =>
        ref.read(recentGlossaryTermsProvider.notifier).restore((json as List).cast<String>()),
    reset: (ref) => ref.read(recentGlossaryTermsProvider.notifier).reset(),
  ),
  DataPart(
    id: 'bestCombo',
    export: (ref) => ref.read(comboProvider),
    restore: (ref, json) => ref.read(comboProvider.notifier).restore(json as int),
    reset: (ref) => ref.read(comboProvider.notifier).reset(),
  ),
  DataPart(
    id: 'dailyAnswerStats',
    export: (ref) => [for (final e in ref.read(dailyAnswerStatsProvider)) e.toJson()],
    restore: (ref, json) => ref
        .read(dailyAnswerStatsProvider.notifier)
        .restore([for (final j in _maps(json)) DailyAnswerStatsEntry.fromJson(j)]),
    reset: (ref) => ref.read(dailyAnswerStatsProvider.notifier).reset(),
  ),
  // 用語集の「覚えた」（ukalab_core の共通部品）。読み込み・リセット後は画面の状態も読み直す。
  _learnedTermsPart(),
  // 旧実装の「覚えた」（id `glossaryMastered`）。書き出さず、旧形式のバックアップの読み込みだけ受ける。
  // リセットでは旧キーも消す（旧キーが残って再取り込みされないようにする）。
  DataPart(
    id: 'glossaryMastered',
    export: (ref) => null,
    restore: (ref, json) async {
      if (json is! List) return;
      await learnedTermsStore.replace(json.cast<String>().toSet());
      await clearLegacyGlossaryMastered();
      await ref.read(learnedTermsProvider.notifier).reload();
    },
    reset: (ref) => clearLegacyGlossaryMastered(),
  ),
  DataPart(
    id: 'examChecklist',
    export: (ref) => ref.read(checklistProvider).checkedIds.toList()..sort(),
    restore: (ref, json) => ref.read(checklistProvider.notifier).restore((json as List).cast<String>()),
    reset: (ref) => ref.read(checklistProvider.notifier).reset(),
  ),
  // 間違いノート(間違えた問題ID・日時・原因・分野・回数。端末内)。
  mistakeNoteDataPart(mistakeNoteStore),
  // 今日の復習の予定(間違いノートから作る復習日程。端末内)。
  reviewScheduleDataPart(),
  // 解除通知済みの実績ID。バックアップには含めず（書き出さず・読み込まず）、リセットだけ行う。
  DataPart(
    id: 'achievementUnlock',
    export: (ref) => null,
    restore: (ref, json) async {},
    reset: (ref) => ref.read(achievementUnlockProvider.notifier).reset(),
  ),
];

DataPart _learnedTermsPart() {
  final base = learnedTermsDataPart(learnedTermsStore);
  return DataPart(
    id: base.id,
    export: base.export,
    restore: (ref, json) async {
      await base.restore(ref, json);
      await ref.read(learnedTermsProvider.notifier).reload();
    },
    reset: (ref) async {
      await base.reset(ref);
      await clearLegacyGlossaryMastered();
      await ref.read(learnedTermsProvider.notifier).reload();
    },
  );
}
