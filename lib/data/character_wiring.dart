import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ukalab_core/ui.dart';

/// このアプリの資格id（`UkalabCert.hazmat4.id`）。core の資格専用キャラ「サラ」の
/// `appIds` と同じ綴り。相互紹介の `appId`（'otsu4'）とは別物。
final String kCharacterAppId = UkalabCert.hazmat4.id;

/// 資格専用キャラの配線。core は権利状態を読まないので、アプリ側で
/// 自分の資格idと、プレミアムかどうか（entitlement の変化に追従）を渡す。
final List<Override> qualificationCharacterOverrides = [
  characterAppIdProvider.overrideWithValue(kCharacterAppId),
  characterPremiumProvider.overrideWith(
    (ref) => (ref.watch(entitlementStateProvider).valueOrNull ??
            EntitlementState.free)
        .hasPremium,
  ),
];
