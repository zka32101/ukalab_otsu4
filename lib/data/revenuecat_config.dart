/// RevenueCat の公開SDKキー。コミットせず、ビルド時に `--dart-define` で渡す。
///   Android: `--dart-define=RC_GOOGLE_KEY=goog_...`
///   iOS:     `--dart-define=RC_APPLE_KEY=appl_...`
/// 未指定（空）・Web・その他のプラットフォームでは null を返し、呼び出し側は
/// 仮の購入サービス（FakeEntitlementService）で動く。
const rcGoogleKey = String.fromEnvironment('RC_GOOGLE_KEY');
const rcAppleKey = String.fromEnvironment('RC_APPLE_KEY');

/// いまの実行環境で使う RevenueCat の公開SDKキー。使えなければ null。
String? revenueCatKeyFor({
  required bool isWeb,
  required bool isAndroid,
  required bool isIOS,
  String googleKey = rcGoogleKey,
  String appleKey = rcAppleKey,
}) {
  if (isWeb) return null;
  if (isAndroid) return googleKey.isEmpty ? null : googleKey;
  if (isIOS) return appleKey.isEmpty ? null : appleKey;
  return null;
}
