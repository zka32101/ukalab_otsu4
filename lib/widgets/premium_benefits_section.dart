import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ukalab_core/ui.dart';
import 'package:ukalab_core/ukalab_core.dart';

/// このアプリで実際にプレミアム限定になっている機能(core の [PremiumFeature] のうち)。
/// 弱点集中ドリル・模擬試験の成長グラフ・カスタム模擬試験は、このアプリでは未実装なので載せない。
const List<PremiumFeature> kOtsu4PremiumFeatures = [
  PremiumFeature.examEveMode,
  PremiumFeature.tenMinutePlan,
  PremiumFeature.historyExport,
  PremiumFeature.readingReadAloud,
];

/// 設定の購入欄の下に出す、プレミアムでできることの一覧(core の [PremiumBenefitsCard])。
/// すでにプレミアムの人には出さない。無料版の回数制限(模擬試験・今日の復習)が
/// このアプリにはあるため、core の「無料のまま使える」一文は使わず、実態に合う補足を付ける。
class PremiumBenefitsSection extends ConsumerWidget {
  const PremiumBenefitsSection({super.key});

  /// カードの下の補足(広告の非表示・回数制限の解除)。
  static const String note = 'プレミアムには、広告の非表示と、模擬試験・今日の復習の回数制限の解除も含まれます。';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPremium =
        (ref.watch(entitlementStateProvider).valueOrNull ?? EntitlementState.free).hasPremium;
    if (hasPremium) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PremiumBenefitsCard(
            key: ValueKey('premiumBenefitsCard'),
            features: kOtsu4PremiumFeatures,
            showFreeNote: false,
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 8, 4, 0),
            child: Text(note, style: TextStyle(fontSize: 12, height: 1.6)),
          ),
        ],
      ),
    );
  }
}
