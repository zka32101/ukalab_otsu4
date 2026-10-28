import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ukalab_core/ui.dart';

import '../data/field_day_scenarios.dart';

/// プレミアム限定シナリオを未購読でタップしたときの案内。
const String kFieldDayPremiumNotice = 'このシナリオはプレミアムの機能です。設定から購入できます。';

/// 「現場の1日」の職場別シナリオ一覧。既存の「現場の1日」は無料のままで、ここに並ぶ追加分は
/// プレミアム限定([freeFieldDayScenarioIds] 以外)。未購読でロック中のシナリオをタップしても
/// 画面には入らず、案内だけ出す。
class FieldDayScenarioListView extends ConsumerStatefulWidget {
  const FieldDayScenarioListView({super.key, this.scenariosFuture});

  /// テスト用。省略時は assets から読み込む。
  final Future<List<FieldDayWorkplace>>? scenariosFuture;

  @override
  ConsumerState<FieldDayScenarioListView> createState() => _FieldDayScenarioListViewState();
}

class _FieldDayScenarioListViewState extends ConsumerState<FieldDayScenarioListView> {
  late final Future<List<FieldDayWorkplace>> _future =
      widget.scenariosFuture ?? loadFieldDayWorkplaces();

  void _open(FieldDayWorkplace scenario) {
    final entitlement = ref.read(entitlementStateProvider).valueOrNull ?? EntitlementState.free;
    if (!scenario.isFree && !entitlement.hasPremium) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(kFieldDayPremiumNotice)),
      );
      return;
    }
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => FieldDayScenarioPlayView(scenario: scenario),
    ));
  }

  @override
  Widget build(BuildContext context) {
    // タップ時の read だけだと、読み込み中に「無料」と判定されるため、ここで購読しておく。
    ref.watch(entitlementStateProvider);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('現場の1日 職場別')),
      body: FutureBuilder<List<FieldDayWorkplace>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SizedBox.shrink();
          }
          if (snapshot.hasError) {
            return ErrorState(message: '読み込みに失敗しました: ${snapshot.error}');
          }
          final scenarios = snapshot.data!;
          if (scenarios.isEmpty) {
            return const EmptyState(message: '利用できるシナリオがありません。');
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'ガソリンスタンド・化学工場の貯蔵所・危険物倉庫など、職場ごとの1日の場面で判断します。選んだあとに理由の解説が出ます。',
                style: theme.textTheme.bodyMedium,
              ),
              if (scenarios.any((s) => s.isAiDraft)) ...[
                const SizedBox(height: 4),
                Text(
                  kFieldDayScenarioDraftNotice,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                ),
              ],
              const SizedBox(height: 12),
              for (final s in scenarios) ...[
                Card(
                  child: ListTile(
                    title: Text(s.story.title),
                    subtitle: Text(
                      '全${s.story.chapters.length}場面 ・ ${s.isFree ? '無料' : 'プレミアム'}',
                      style: theme.textTheme.bodySmall,
                    ),
                    trailing: s.isFree
                        ? const Icon(Icons.chevron_right)
                        : Icon(Icons.lock_outline, color: theme.colorScheme.outline),
                    onTap: () => _open(s),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// 1シナリオを遊ぶ画面。判断→解説→結果の流れは共通部品 [StoryModeWidget] が担い、
/// ここでは AI 下書きの表示を添える。
class FieldDayScenarioPlayView extends StatelessWidget {
  const FieldDayScenarioPlayView({super.key, required this.scenario});

  final FieldDayWorkplace scenario;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = scenario.story;
    return Scaffold(
      appBar: AppBar(title: Text(s.title)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (scenario.isAiDraft) ...[
                Text(
                  kFieldDayScenarioDraftNotice,
                  style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.outline),
                ),
                const SizedBox(height: 8),
              ],
              StoryModeWidget(
                scenario: StoryScenarioSpec(
                  title: s.title,
                  description: s.description,
                  chapters: [
                    for (final c in s.chapters)
                      StoryChapterSpec(
                        situation: c.situation,
                        choices: [
                          for (final ch in c.choices)
                            StoryChoiceSpec(
                              choiceId: ch.choiceId,
                              text: ch.text,
                              isRecommended: ch.isRecommended,
                              feedback: ch.feedback,
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
