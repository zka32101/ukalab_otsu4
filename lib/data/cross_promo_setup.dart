/// 本番の applicationId（Google Play）。リストの `id` と完全一致させる。
///
/// android/app/build.gradle(.kts) の applicationId と同じ値（test/cross_promo_test.dart で検証）。
/// 不一致だと自アプリが自分の紹介リストに出てしまう。
const String kCrossPromoAppId = 'com.yourwish.ukalab_otsu';
