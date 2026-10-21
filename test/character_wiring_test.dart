import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otsu4/data/character_wiring.dart';
import 'package:ukalab_core/ui.dart';

void main() {
  test('資格専用キャラの配線: appId は hazmat4 で、サラの appIds と一致する', () {
    final c = ProviderContainer(overrides: [
      entitlementServiceProvider.overrideWithValue(FakeEntitlementService()),
      ...qualificationCharacterOverrides,
    ]);
    addTearDown(c.dispose);
    expect(c.read(characterAppIdProvider), 'hazmat4');
    expect(UkalabCharacters.qualificationPacksFor('hazmat4').map((p) => p.id),
        contains('sala'));
  });

  test('プレミアムかどうかが entitlement に追従する（無料 false → 購入後 true）', () async {
    final service = FakeEntitlementService(
      availableOffers: const [
        EntitlementOffer(
            id: 'premium', productId: 'p', title: 'p', priceString: '-'),
      ],
      grantOnPurchase: const {'p': EntitlementState(hasPremium: true)},
    );
    final c = ProviderContainer(overrides: [
      entitlementServiceProvider.overrideWithValue(service),
      ...qualificationCharacterOverrides,
    ]);
    addTearDown(c.dispose);
    c.listen(characterPremiumProvider, (_, __) {});
    await Future<void>.delayed(Duration.zero);
    expect(c.read(characterPremiumProvider), isFalse);
    await service.purchase('p');
    await Future<void>.delayed(Duration.zero);
    expect(c.read(characterPremiumProvider), isTrue);
  });
}
