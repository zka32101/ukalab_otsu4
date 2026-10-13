/// 本番の applicationId（Google Play）。リストの `id` と完全一致させる。
///
/// TODO(要確認): このリポジトリに android/ が無く、CI設定・README にも記載が無いため未確定。
/// 他のうかラボは `com.yourwish.ukalab.<アプリ名>`（g_kentei / seisei_ai_passport）だが、
/// 推測では入れない。Play Console の値を確認して差し替えること。
/// 仮の値のままだと自アプリが自分の掲載リストに出てしまう（デバッグビルドでは警告が出る）。
const String kCrossPromoAppId = 'TODO_CONFIRM_APPLICATION_ID';
