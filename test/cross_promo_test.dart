import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otsu4/data/cross_promo_setup.dart';
import 'package:ukalab_core/cross_promo.dart';
// ignore: implementation_imports
import 'package:ukalab_core/src/cross_promo_test_support.dart';

const _list = '''
[
  {"id":"com.example.other","name":"別の資格アプリ","tagline":"合格を目指そう","iconUrl":"","storeUrl":"https://play.google.com/store/apps/details?id=com.example.other","category":"うかラボ"}
]
''';

Widget _host(Widget child) => MaterialApp(
      home: Scaffold(body: ListView(padding: const EdgeInsets.all(16), children: [child])),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('掲載リストが空なら何も表示せず、例外にもならない（Firebase無し）', (tester) async {
    await tester.pumpWidget(_host(const UkalabCrossPromoSection(currentAppId: kCrossPromoAppId)));
    expect(tester.takeException(), isNull);
    expect(find.text('他のアプリもチェック！'), findsNothing);
  });

  testWidgets('掲載があれば設定画面相当のリスト内で紹介カードが表示される', (tester) async {
    await tester.pumpWidget(_host(ukalabCrossPromoSectionForTest(
      currentAppId: kCrossPromoAppId,
      rawJson: _list,
    )));
    expect(tester.takeException(), isNull);
    expect(find.text('他のアプリもチェック！'), findsOneWidget);
    expect(find.text('別の資格アプリ'), findsOneWidget);
  });

  test('UkalabCrossPromo.init() は Firebase 無しでも例外を投げない', () async {
    await UkalabCrossPromo.init();
  });

  test('kCrossPromoAppId は android の applicationId と完全一致する', () {
    final gradle = File('android/app/build.gradle.kts').existsSync()
        ? File('android/app/build.gradle.kts')
        : File('android/app/build.gradle');
    final m = RegExp(r'applicationId\s*=?\s*"([^"]+)"').firstMatch(gradle.readAsStringSync());
    expect(m, isNotNull);
    expect(kCrossPromoAppId, m!.group(1));
    expect(kCrossPromoAppId, 'com.yourwish.ukalab_otsu');
  });
}
