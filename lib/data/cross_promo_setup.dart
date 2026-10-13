import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// 本番の applicationId（Google Play）。リストの `id` と完全一致させる。
///
/// TODO(要確認): このリポジトリに android/ が無く、CI設定・README にも記載が無いため未確定。
/// 他のうかラボは `com.yourwish.ukalab.<アプリ名>`（g_kentei / seisei_ai_passport）だが、
/// 推測では入れない。Play Console の値を確認して差し替えること。
/// 仮の値のままだと自アプリが自分の掲載リストに出てしまう（デバッグビルドでは警告が出る）。
const String kCrossPromoAppId = 'TODO_CONFIRM_APPLICATION_ID';

/// 紹介するシリーズ（同じカテゴリのアプリだけを紹介する。方針は cross_promo_kit/docs/ROLLOUT.md）。
const String kCrossPromoCategory = 'うかラボ';

/// 相互紹介のための Firebase 初期化。失敗しても例外は投げず、起動を止めない。
///
/// firebase_options / google-services.json / GoogleService-Info.plist が未配置の間は
/// 失敗するが、その場合は紹介リストが空になるだけで無害（CrossPromoSection は何も表示しない）。
/// 戻り値は初期化に成功したかどうか。
Future<bool> initFirebaseForCrossPromo() async {
  try {
    await Firebase.initializeApp().timeout(const Duration(seconds: 10));
    return true;
  } catch (e) {
    debugPrint('[cross_promo] Firebase の初期化をスキップしました: $e');
    return false;
  }
}
