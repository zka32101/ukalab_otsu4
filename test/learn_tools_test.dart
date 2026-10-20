import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otsu4/views/bookmark_list_view.dart';
import 'package:otsu4/views/glossary_card_view.dart';
import 'package:otsu4/views/home_view.dart';
import 'package:otsu4/views/memo_list_view.dart';
import 'package:otsu4/views/mistake_note_screen.dart';
import 'package:otsu4/views/reading_list_view.dart';
import 'package:otsu4/views/study_view.dart';
import 'package:otsu4/widgets/learn_tools_section.dart';
import 'package:ukalab_core/ui.dart';

import 'support/clip_harness.dart';

/// 他のうかラボのアプリと同じ配置の確認:
/// ホームは「今日やること／記録／試験に向けて」、調べる系の入口は「学ぶ」下部の「道具」。

Future<void> _tapAndBack(WidgetTester tester, String text, Type screen) async {
  final finder = find.text(text);
  await tester.scrollUntilVisible(finder, 200, scrollable: find.byType(Scrollable).first);
  await tester.tap(finder);
  for (var i = 0; i < 30 && find.byType(screen).evaluate().isEmpty; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(find.byType(screen), findsOneWidget, reason: '$text の先の画面');
  Navigator.of(tester.element(find.byType(screen))).pop();
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(preloadAssets);

  testWidgets('ホームに「道具」の入口(間違いノート・用語集・読み物)は無く、3区切りになる', (tester) async {
    await pumpClip(tester, const Scaffold(body: HomeView()), width: 800, scale: 1.0, height: 6000);
    for (final h in ['今日やること', '記録', '試験に向けて']) {
      expect(find.widgetWithText(HomeSectionHeader, h), findsOneWidget, reason: h);
    }
    expect(find.widgetWithText(HomeSectionHeader, '道具'), findsNothing);
    expect(find.text('試験の準備'), findsNothing);
    expect(find.text('間違いノート'), findsNothing);
    expect(find.text('用語集'), findsNothing);
    expect(find.text('章ごとの解説読み物'), findsNothing);
    expectNoLayoutErrors(tester);
  });

  testWidgets('「学ぶ」の「道具」に、件数0でも全入口が出て、開ける', (tester) async {
    await pumpClip(tester, const Scaffold(body: StudyView()), width: 800, scale: 1.0, height: 900);
    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(find.widgetWithText(HomeSectionHeader, '道具'), 300,
        scrollable: scrollable);
    expect(find.widgetWithText(HomeSectionHeader, '道具'), findsOneWidget);
    // 以前の個別カード(学ぶの上部)は道具に一本化した。
    expect(find.text('章ごとの解説読み物'), findsOneWidget);
    expect(find.text('用語集'), findsOneWidget);
    expect(find.text('ブックマーク'), findsOneWidget);
    expect(find.text('自分用メモの一覧'), findsOneWidget);
    expect(find.text('間違いノート'), findsOneWidget);
    await _tapAndBack(tester, '間違いノート', MistakeNoteScreen);
    await _tapAndBack(tester, 'ブックマーク', BookmarkListView);
    await _tapAndBack(tester, '自分用メモの一覧', MemoListView);
    await _tapAndBack(tester, '用語集', GlossaryCardView);
    await _tapAndBack(tester, '章ごとの解説読み物', ReadingListView);
    expectNoLayoutErrors(tester);
  });

  for (final width in [320.0, 280.0]) {
    for (final scale in [1.0, 2.0, 3.0]) {
      testWidgets('道具は幅${width.toInt()}・文字$scale倍でオーバーフローしない', (tester) async {
        await pumpClip(tester, const LearnToolsHarness(), width: width, scale: scale);
        expect(find.byType(LearnToolsSection), findsOneWidget);
        expectNoLayoutErrors(tester);
      });
    }
  }
}
