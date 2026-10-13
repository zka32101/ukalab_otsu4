import 'package:app_common_kit/app_common_kit.dart'
    show EntitlementState, entitlementStateProvider;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ukalab_core/ukalab_core.dart';

import 'question_repository.dart';

/// ukalab_core の共通機能（更新ログ・試験直前・10分プラン・当日チェックリスト・履歴の書き出し）を
/// このアプリのデータにつなぐ部分。画面は `lib/views/` 側。

/// 試験定義の examId（`assets/exam/hazmat4_exam.json`）。
const String kExamId = 'hazmat4';

const String updateLogAsset = 'assets/features/update_log.jsonl';
const String checklistAsset = 'assets/features/checklist.jsonl';

/// 全問題。
final allQuestionsProvider =
    FutureProvider<List<Question>>((ref) => const QuestionRepository().load());

/// 更新ログ（新しい順。未来の予定と90日より前は除く）。
Future<List<UpdateLogEntry>> loadUpdateLog(
    {DateTime? now, AssetBundle? bundle}) async {
  final text = await (bundle ?? rootBundle).loadString(updateLogAsset);
  return recentUpdates(parseUpdateLogJsonl(text).entries, now ?? DateTime.now(),
      examId: kExamId);
}

/// 当日チェックリスト（会場受験。分類順）。
Future<List<ChecklistItem>> loadChecklist({AssetBundle? bundle}) async {
  final text = await (bundle ?? rootBundle).loadString(checklistAsset);
  return checklistFor(kExamId, parseChecklistItemsJsonl(text).items,
      venue: ExamVenueKind.venue);
}

/// 解答履歴から、日付ごと・分野ごとのCSVを組む（個人情報・問題IDは含めない）。
String historyCsvText(List<ProgressRecord> records, List<Question> questions) {
  final daily = dailySummaryCsv(summarizeByDay(records));
  final topic =
      topicAccuracyCsv(summarizeByTopic(records, questions: questions));
  return '$daily\n$topic';
}

/// プレミアムか（試験直前・10分プラン・履歴の書き出しの利用可否）。
bool isPremiumFor(WidgetRef ref, PremiumFeature feature) =>
    canUsePremiumFeature(
      feature,
      isPremium: (ref.watch(entitlementStateProvider).valueOrNull ??
              EntitlementState.free)
          .hasPremium,
    );

/// 当日チェックリストのチェック状態（端末内）。
class ChecklistNotifier extends Notifier<ChecklistProgress> {
  static const _key = 'ukalab_otsu4_exam_checklist_v1';
  late Future<void> _loaded;

  @override
  ChecklistProgress build() {
    _loaded = _load();
    return const ChecklistProgress();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = prefs.getStringList(_key);
      if (ids != null) state = ChecklistProgress({...ids, ...state.checkedIds});
    } catch (_) {}
  }

  Future<void> toggle(String itemId) async {
    await _loaded;
    state = state.toggle(itemId);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_key, state.checkedIds.toList()..sort());
    } catch (_) {}
  }
}

final checklistProvider =
    NotifierProvider<ChecklistNotifier, ChecklistProgress>(
        ChecklistNotifier.new);
