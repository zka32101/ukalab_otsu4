import 'package:cross_promo_kit/cross_promo_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otsu4/data/cross_promo_setup.dart';

const _apps = [
  PromotedApp(
    id: 'com.example.other_one',
    name: '別の資格アプリ',
    tagline: '合格を目指そう',
    iconUrl: '',
    storeUrl: 'https://play.google.com/store/apps/details?id=com.example.other_one',
    category: 'うかラボ',
  ),
];

Widget _host(Widget child) => MaterialApp(
      home: Scaffold(body: ListView(padding: const EdgeInsets.all(16), children: [child])),
    );

void main() {
  testWidgets('掲載リストが空なら何も表示せず、例外にもならない（Firebase無し）', (tester) async {
    await tester.pumpWidget(_host(const CrossPromoSection(
      currentAppId: kCrossPromoAppId,
      currentCategory: kCrossPromoCategory,
    )));
    expect(tester.takeException(), isNull);
    expect(find.text('他のアプリもチェック！'), findsNothing);
  });

  testWidgets('appsOverride を渡すと設定画面相当のリスト内で紹介カードが表示される', (tester) async {
    await tester.pumpWidget(_host(const CrossPromoSection(
      currentAppId: kCrossPromoAppId,
      currentCategory: kCrossPromoCategory,
      appsOverride: _apps,
    )));
    expect(tester.takeException(), isNull);
    expect(find.text('他のアプリもチェック！'), findsOneWidget);
    expect(find.text('別の資格アプリ'), findsOneWidget);
  });

  test('Firebase が使えない環境でも initFirebaseForCrossPromo は例外を投げない', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    expect(await initFirebaseForCrossPromo(), isFalse);
  });

  test('CrossPromoService.init() は Firebase 無しでも例外を投げず、リストは空のまま', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await CrossPromoService.init();
    expect(
      CrossPromoService.getPromotedApps(
        currentAppId: kCrossPromoAppId,
        currentCategory: kCrossPromoCategory,
      ),
      isEmpty,
    );
  });
}
