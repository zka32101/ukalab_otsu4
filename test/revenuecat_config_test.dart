import 'package:flutter_test/flutter_test.dart';
import 'package:otsu4/data/revenuecat_config.dart';

String? _key({
  bool web = false,
  bool android = false,
  bool ios = false,
  String google = '',
  String apple = '',
}) =>
    revenueCatKeyFor(isWeb: web, isAndroid: android, isIOS: ios, googleKey: google, appleKey: apple);

void main() {
  group('revenueCatKeyFor', () {
    test('コミットされた既定値は空（実キーを含まない）', () {
      expect(rcGoogleKey, isEmpty);
      expect(rcAppleKey, isEmpty);
    });

    test('Android は RC_GOOGLE_KEY、iOS は RC_APPLE_KEY を使う', () {
      expect(_key(android: true, google: 'goog_x', apple: 'appl_y'), 'goog_x');
      expect(_key(ios: true, google: 'goog_x', apple: 'appl_y'), 'appl_y');
    });

    test('キーが空なら null（仮の購入サービスで動く）', () {
      expect(_key(android: true), isNull);
      expect(_key(ios: true), isNull);
      expect(_key(android: true, apple: 'appl_y'), isNull);
      expect(_key(ios: true, google: 'goog_x'), isNull);
    });

    test('Web・その他のプラットフォームは常に null', () {
      expect(_key(web: true, android: true, google: 'goog_x'), isNull);
      expect(_key(google: 'goog_x', apple: 'appl_y'), isNull);
    });
  });
}
