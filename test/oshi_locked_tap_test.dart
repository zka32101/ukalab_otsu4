import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otsu4/data/character_wiring.dart';
import 'package:otsu4/data/progress_store.dart';
import 'package:otsu4/widgets/oshi_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ukalab_core/ui.dart';

class _Obs extends NavigatorObserver {
  final events = <String>[];
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => events.add('push ${route.runtimeType}');
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => events.add('pop ${route.runtimeType}');
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      events.add('replace ${oldRoute.runtimeType} -> ${newRoute.runtimeType}');
}

final _obs = _Obs();

Future<void> _pump(WidgetTester tester) async {
  _obs.events.clear();
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
      navigatorObservers: [_obs],
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

    expect(find.text('プレミアムを見る'), findsOneWidget);
    await tester.tap(find.text('プレミアムを見る'));
    for (var i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('購入欄の代わり'), findsOneWidget, reason: 'navigator events: ${_obs.events}');
    expect(find.byType(CharacterSelectScreen), findsNothing);
  });
}
