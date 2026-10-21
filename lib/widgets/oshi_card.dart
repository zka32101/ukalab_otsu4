import 'package:ukalab_core/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/oshi_lines.dart';
import '../data/progress_store.dart';
import '../views/settings_view.dart';

MascotStage _stageFor(ProgressSnapshot p) =>
    MasteryModel.standard.stageOf(MasteryInput(coverage: p.coverage, accuracy: p.accuracy));

/// ホームの「推し」カード。共通キットの [UkalabOshiCard] に、乙4の成長段階・連続日数を渡す。
/// 推しの選択・着替え・合格報告・表示切替はキット側。特別な状況が無いときのあいさつだけ、
/// 時間帯に応じたセリフ（`lib/data/oshi_lines.dart`）を使う。
///
/// 正式な出題範囲（`Question`）の網羅率・正答率はまだ無い（問題データ未着手）ため、
/// `ProgressSnapshot`（演習の解答数）を暫定の習得度として使う（README参照）。
/// 試験日の設定機能はまだ無いため、試験日連動の装い（`ExamPhase`）は常に none。
///
/// ロック中の資格専用キャラ（サラ）のプレビューの「プレミアムを見る」が押されたら
/// （[UkalabOshiCard.onLockedTap]）、開いている「推しを選ぶ」画面を設定画面（購入欄が先頭付近）に
/// 置き換えて開く。下部タブは外から切り替えられないため、Navigator で設定画面を開く。
class OshiCard extends ConsumerWidget {
  const OshiCard({super.key, this.purchaseBuilder});

  /// 購入欄へ誘導する画面。null なら設定画面（テストで差し替える）。
  final WidgetBuilder? purchaseBuilder;

  static Widget _settingsPage(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('設定')),
        body: const SettingsView(),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final last = progress.lastStudyDate;
    final days = last == null ? null : today.difference(DateTime(last.year, last.month, last.day)).inDays;
    return UkalabOshiCard(
      cert: UkalabCert.hazmat4,
      stage: _stageFor(progress),
      appId: 'otsu4',
      onLockedTap: () => Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: purchaseBuilder ?? _settingsPage),
      ),
      streakDays: progress.streakDays,
      studiedToday: days == 0,
      daysSinceLastStudy: days,
      greeting: (now, seed) => pickTimeOfDayGreeting(now, seed: seed),
    );
  }
}
