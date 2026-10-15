import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ukalab_core/ui.dart' show PeerStatsCard;
import 'package:ukalab_core/ukalab_core.dart';
import 'package:otsu4/data/peer_stats_prep.dart';
import 'package:otsu4/data/progress_store.dart';
import 'package:otsu4/widgets/cert_prop_badge.dart';
import 'package:otsu4/widgets/peer_stats_settings_tile.dart';

ProgressRecord _r(String qid, int day) =>
    ProgressRecord(qid: qid, subjectId: 's', correct: true, at: DateTime(2026, 10, day));

class _MemSettings implements PeerStatsSettings {
  bool v = false;
  @override
  Future<bool> isSharingEnabled() async => v;
  @override
  Future<void> setSharingEnabled(bool e) async => v = e;
}

void main() {
  group('PeerStatsSettings', () {
    test('既定OFF・保存・復元', () async {
      SharedPreferences.setMockInitialValues({});
      expect(await SharedPrefsPeerStatsSettings().isSharingEnabled(), isFalse);
      await SharedPrefsPeerStatsSettings().setSharingEnabled(true);
      expect(await SharedPrefsPeerStatsSettings().isSharingEnabled(), isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('ukalab_otsu4_peer_stats_sharing_v1'), isTrue);
      await SharedPrefsPeerStatsSettings().setSharingEnabled(false);
      expect(await SharedPrefsPeerStatsSettings().isSharingEnabled(), isFalse);
    });
  });

  test('ローカル値の取り出しが既存値と一致する', () {
    final records = [_r('a', 1), _r('a', 2), _r('b', 2)];
    // 累計カウンタ(answered)は履歴の件数上限に影響されない。
    const progress = ProgressSnapshot(answered: 10, streakDays: 4);
    final v = peerLocalValuesFrom(
        progress: progress, records: records, examDate: DateTime(2026, 12, 1));
    expect(v.streakDays, 4);
    expect(v.totalAnswers, 10);
    expect(v.totalAnswers, progress.answered);
    expect(v.distinctQuestions, 2);
    expect(v.examDate, DateTime(2026, 12, 1));
    expect(peerLocalValuesFrom(progress: progress, records: const []).examDate, isNull);
  });

  test('設定スイッチの表示フラグは本番で false', () {
    expect(kPeerStatsSettingsVisible, isFalse);
  });

  testWidgets('設定スイッチ（ウィジェット単体）: 説明文・既定OFF・切り替えで保存', (tester) async {
    final s = _MemSettings();
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: PeerStatsSettingsTile(settings: s))));
    await tester.pumpAndSettle();
    expect(find.text('匿名の集計に参加する'), findsOneWidget);
    expect(find.textContaining('連続学習日数・累計の問題数・試験日'), findsOneWidget);
    expect(find.textContaining('オフのままでも'), findsOneWidget);
    expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value, isFalse);
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    expect(s.v, isTrue);
  });

  testWidgets('PeerStatsCard はモックのスナップショットで表示できる（ホームには置かない）', (tester) async {
    const snap = PeerStatsSnapshot(
        asOf: '2026-10-15',
        activeToday: 1234,
        participants: 5000,
        totalQuestions: 900000,
        medianQuestions: 120);
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: PeerStatsCard(snapshot: snap, streakDays: 3))));
    expect(find.byType(Card), findsOneWidget);
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: PeerStatsCard(snapshot: null))));
    expect(find.byType(Card), findsNothing);
  });

  group('CertPropBadge', () {
    testWidgets('小さい幅でもオーバーフローせず、画像を出す', (tester) async {
      tester.view.physicalSize = const Size(240, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: Row(children: [
            Expanded(child: Text('乙種第4類危険物取扱者 全50問・120分・科目別60%以上で合格')),
            SizedBox(width: 8),
            CertPropBadge(),
          ]),
        ),
      ));
      expect(find.byType(Image), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('画像読込失敗時は非表示にフォールバック（例外なし）', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: CertPropBadge())));
      await tester.pump();
      final image = tester.widget<Image>(find.byType(Image));
      final fallback = image.errorBuilder!(tester.element(find.byType(Image)), 'x', null);
      expect(fallback, isA<SizedBox>());
      expect(find.byType(IgnorePointer), findsWidgets);
    });
  });
}
