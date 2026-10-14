import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otsu4/app.dart';
import 'package:otsu4/data/glossary.dart';
import 'package:otsu4/views/glossary_card_view.dart';
import 'package:otsu4/views/mock_review_view.dart';
import 'package:otsu4/views/nagara_study_view.dart';
import 'package:otsu4/views/practice_session_view.dart';
import 'package:otsu4/views/question_search_view.dart';
import 'package:otsu4/views/weak_review_view.dart';
import 'package:otsu4/widgets/mock_result_share_card.dart';
import 'package:app_common_kit/app_common_kit.dart' show ChoiceTile;

import 'support/clip_harness.dart';

final _vScroll = find.byWidgetPredicate((w) => w is Scrollable && w.axis == Axis.vertical);

Future<void> scrollTop(WidgetTester tester) async {
  if (_vScroll.evaluate().isEmpty) return;
  // ドラッグ量に頼らず先頭へ戻す（文字3倍では画面が数千px以上になり、1回のドラッグでは戻りきらない）。
  tester.state<ScrollableState>(_vScroll.first).position.jumpTo(0);
  await tester.pump();
}

/// [target] が見えるまで画面をスクロールしてからタップする。見つからなければ false。
Future<bool> tapScrolling(WidgetTester tester, Finder target, {bool toTop = false}) async {
  // ペース遅れのスナックバーが画面中央や下のボタンに被らないよう、先に閉じておく。
  Future<void> clearSnackBars() async {
    if (find.byType(ScaffoldMessenger).evaluate().isNotEmpty) {
      tester.state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger).first).clearSnackBars();
      await tester.pump(const Duration(milliseconds: 400));
    }
  }

  await clearSnackBars();
  if (toTop) await scrollTop(tester);
  // 対象が組み立てられるまで、縦スクロールを少しずつ送る（ヒットしない位置のドラッグは握りつぶさず、
  // 毎回スナックバーを閉じてから動かす）。
  for (var i = 0; i < 200 && target.evaluate().isEmpty; i++) {
    if (_vScroll.evaluate().isEmpty) return false;
    await clearSnackBars();
    await tester.drag(_vScroll.first, const Offset(0, -200), warnIfMissed: false);
    await tester.pump();
  }
  await clearSnackBars();
  if (target.evaluate().isEmpty) return false;
  await tester.ensureVisible(target.first);
  await tester.pump();
  if (target.evaluate().isEmpty) return false;
  // 画面より背の高い選択肢は中心が画面外になるため、左上寄りの位置をタップする。
  final size = tester.getSize(target.first);
  final point = tester.getTopLeft(target.first) + Offset(size.width / 2, size.height < 80 ? size.height / 2 : 24);
  await tester.tapAt(point);
  await tester.pump();
  return true;
}

/// アセット読み込み（実時間）を待って [finder] が出るまで進める。
Future<void> waitFor(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 100 && finder.evaluate().isEmpty; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// 実問題のうち最長の選択肢・問題文・解説を使い、狭い幅（320/280dp）・大きい文字（1/2/3倍）でも
/// 文字がはみ出さない・切れないことを、画面（出題・解答・結果・模擬試験・記録・設定ほか）ごとに確認する。
void main() {
  setUpAll(preloadAssets);

  for (final width in [320.0, 280.0]) {
    for (final scale in [1.0, 2.0, 3.0]) {
      final tag = '幅${width.toInt()}・文字$scale倍';

      testWidgets('一問一答（最長の選択肢・解説）は$tagでオーバーフローしない', (tester) async {
        final qs = await loadWorstCase(tester);
        await pumpClip(
          tester,
          Scaffold(
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [PracticeSessionView(pool: qs, emptyMessage: '空')],
            ),
          ),
          width: width,
          scale: scale,
        );
        for (var i = 0; i < 8; i++) {
          expectNoLayoutErrors(tester, '出題 ${i + 1}問目');
          await scrollTop(tester);
          final tiles = find.byType(ChoiceTile);
          if (tiles.evaluate().isEmpty) break;
          await tapScrolling(tester, tiles, toTop: true);
          expectNoLayoutErrors(tester, '解答後 ${i + 1}問目');
          if (!await tapScrolling(tester, find.text('次の問題'))) break;
        }
      });

      testWidgets('苦手問題の復習は$tagでオーバーフローしない', (tester) async {
        await loadWorstCase(tester);
        await pumpClip(tester, const WeakReviewView(), width: width, scale: scale);
        for (var i = 0; i < 6; i++) {
          expectNoLayoutErrors(tester, '出題 ${i + 1}問目');
          await scrollTop(tester);
          final tiles = find.byType(ChoiceTile);
          if (tiles.evaluate().isEmpty) break;
          await tapScrolling(tester, tiles, toTop: true);
          expectNoLayoutErrors(tester, '解答後 ${i + 1}問目');
          if (!await tapScrolling(tester, find.text('次の問題'))) break;
        }
      });

      testWidgets('用語集（定義が最長の用語）は$tagでオーバーフローしない', (tester) async {
        final longest = ([...glossaryTerms]..sort((a, b) =>
                (b.definition.length + (b.note?.length ?? 0)).compareTo(a.definition.length + (a.note?.length ?? 0))))
            .first;
        await pumpClip(tester, GlossaryCardView(initialTerm: longest.term), width: width, scale: scale);
        expectNoLayoutErrors(tester, '定義');
        await tester.tap(find.byType(Card).first, warnIfMissed: false);
        await tester.pump();
        expectNoLayoutErrors(tester, '用語');
      });

      testWidgets('ながら学習は$tagでオーバーフローしない', (tester) async {
        final qs = await loadWorstCase(tester);
        await pumpClip(tester, NagaraStudyView(pool: qs), width: width, scale: scale);
        expectNoLayoutErrors(tester);
      });

      testWidgets('模試の振り返りは$tagでオーバーフローしない', (tester) async {
        final qs = await loadWorstCase(tester);
        await pumpClip(
          tester,
          MockReviewView(questions: qs, answers: {for (final q in qs) q.qid: 0}),
          width: width,
          scale: scale,
        );
        expectNoLayoutErrors(tester);
      });

      testWidgets('問題の詳細は$tagでオーバーフローしない', (tester) async {
        final qs = await loadWorstCase(tester);
        for (final q in qs) {
          await pumpClip(tester, QuestionDetailView(question: q), width: width, scale: scale);
          expectNoLayoutErrors(tester, q.qid);
        }
      });

      testWidgets('問題検索の結果は$tagでオーバーフローしない', (tester) async {
        await pumpClip(tester, const QuestionSearchView(), width: width, scale: scale);
        await tester.enterText(find.byType(TextField).first, '危険物');
        await settleClip(tester);
        expectNoLayoutErrors(tester);
      });

      testWidgets('結果のシェアカードは$tagでオーバーフローしない', (tester) async {
        await pumpClip(
          tester,
          Scaffold(
            body: Center(
              child: MockResultShareCard(
                score: 30,
                max: 35,
                passed: true,
                date: DateTime(2026, 10, 1),
                examName: 'うかラボ 危険物取扱者乙種第4類',
              ),
            ),
          ),
          width: width,
          scale: scale,
        );
        expectNoLayoutErrors(tester);
      });

      for (final level in ['otsu4', 'otsu1', 'otsu6']) {
        testWidgets('5タブ（$level）は$tagでオーバーフローしない', (tester) async {
          await loadWorstCase(tester);
          await pumpClipApp(tester, const Otsu4App(), width: width, scale: scale, levelId: level);
          expectNoLayoutErrors(tester, 'ホーム');
          final dests = find.byType(NavigationDestination);
          final n = dests.evaluate().length;
          expect(n, greaterThanOrEqualTo(5));
          for (var i = 1; i < n; i++) {
            await tester.tap(dests.at(i), warnIfMissed: false);
            await settleClip(tester);
            expectNoLayoutErrors(tester, 'タブ$i');
            // 下までスクロールして、画面の後ろ側の部品も描画させる。
            final scrollable = _vScroll;
            if (scrollable.evaluate().isNotEmpty) {
              for (var k = 0; k < 6; k++) {
                await tester.drag(scrollable.first, const Offset(0, -600), warnIfMissed: false);
                await tester.pump(const Duration(milliseconds: 100));
                expectNoLayoutErrors(tester, 'タブ$i スクロール$k');
              }
            }
          }
        });
      }

      testWidgets('模擬試験（解答〜結果）は$tagでオーバーフローしない', (tester) async {
        await loadWorstCase(tester);
        await pumpClipApp(tester, const Otsu4App(), width: width, scale: scale);
        for (var attempt = 0; attempt < 4 && find.text('開始する').evaluate().isEmpty; attempt++) {
          await waitFor(tester, find.byType(NavigationDestination));
          await tester.tap(find.byType(NavigationDestination).at(2), warnIfMissed: false);
          await tester.pump(const Duration(milliseconds: 300));
          await waitFor(tester, find.text('開始する'));
        }
        if (find.text('開始する').evaluate().isNotEmpty) {
          await tester.tap(find.text('開始する'), warnIfMissed: false);
          await tester.pump();
        } else {
          fail('模擬試験の開始ボタンが表示されない: ${tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).take(8).toList()} progress=${find.byType(CircularProgressIndicator).evaluate().length}');
        }
        var stopped = '';
        for (var i = 0; i < 150 && find.text('結果カードを見る').evaluate().isEmpty; i++) {
          stopped = '$i問目で停止: ${tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).take(5).toList()} tiles=${find.byType(ChoiceTile).evaluate().length}';
          expectNoLayoutErrors(tester, '模試 ${i + 1}問目');
          await scrollTop(tester);
          final tiles = find.byType(ChoiceTile);
          await tapScrolling(tester, tiles, toTop: true);
          final b = await tapScrolling(tester, find.text('次の問題'));
          if (!b) {
            if (!await tapScrolling(tester, find.text('採点する'))) break;
          }
        }
        await settleClip(tester);
        expectNoLayoutErrors(tester, '模試結果');
        // 結果カードのダイアログ（共有用）と、学習教材リンク集。
        final card = find.text('結果カードを見る');
        expect(card, findsOneWidget, reason: '模試の結果画面まで進めている（$stopped）');
        if (card.evaluate().isNotEmpty) {
          await tester.ensureVisible(card);
          await tester.tap(card, warnIfMissed: false);
          await settleClip(tester);
          expectNoLayoutErrors(tester, '結果カードのダイアログ');
          await tester.tap(find.text('閉じる'), warnIfMissed: false);
          await settleClip(tester);
        }
        final links = find.text('学習教材リンク集を見る');
        if (links.evaluate().isNotEmpty) {
          await tester.ensureVisible(links);
          await tester.tap(links, warnIfMissed: false);
          await settleClip(tester);
          expectNoLayoutErrors(tester, '学習教材リンク集');
        }
      });
    }
  }
}
