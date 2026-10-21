import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otsu4/data/character_wiring.dart';
import 'package:otsu4/data/progress_store.dart';
import 'package:otsu4/widgets/oshi_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ukalab_core/ui.dart';

Future<void> _pump(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final progressService = ProgressService();
  await tester.runAsync(progressService.load);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      progressServiceProvider.overrideWithValue(progressService),
      entitlementServiceProvider.overrideWithValue(FakeEntitlementService()),
      ...qualificationCharacterOverrides,
    ],
    child: MaterialApp(
      home: Scaffold(
        body: ListView(children: [
          OshiCard(purchaseBuilder: (_) => const Scaffold(body: Text('購入欄の代わり'))),
        ]),
      ),
    ),
  ));
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  testWidgets('推しカードに onLockedTap が渡っている', (tester) async {
    await _pump(tester);
    expect(tester.widget<UkalabOshiCard>(find.byType(UkalabOshiCard)).onLockedTap, isNotNull);
  });

  testWidgets('ロック中のサラのプレビューから、選択画面を置き換えて購入欄へ誘導される', (tester) async {
    await _pump(tester);
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    final item = find.widgetWithText(PopupMenuItem<Object>, '推しを選ぶ');
    expect(item, findsOneWidget);
    await tester.tap(item, warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(CharacterSelectScreen), findsOneWidget);

    final sala = find.text('サラ');
    await tester.ensureVisible(sala);
    await tester.pump();
    await tester.tap(sala);
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('プレミアムを見る'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('購入欄の代わり'), findsOneWidget);
    expect(find.byType(CharacterSelectScreen), findsNothing);
  });
}
