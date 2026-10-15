import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otsu4/launch_splash.dart';

void main() {
  testWidgets('起動時画面は StartupSplash にアイコンと背景色を渡す', (tester) async {
    await tester.pumpWidget(const LaunchSplashApp());
    final splash = tester.widget<StartupSplash>(find.byType(StartupSplash));
    expect(splash.appIconAsset, kLaunchIconAsset);
    expect(splash.backgroundColor, kLaunchBackgroundColor);
  });
}
