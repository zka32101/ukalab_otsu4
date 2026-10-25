import 'package:flutter_test/flutter_test.dart';
import 'package:otsu4/launch_splash.dart';
import 'package:ukalab_core/ui.dart';

void main() {
  testWidgets('起動時画面は UkalabStartupSplash にアイコンと背景色を渡す', (tester) async {
    await tester.pumpWidget(const LaunchSplashApp());
    final splash = tester.widget<UkalabStartupSplash>(find.byType(UkalabStartupSplash));
    expect(splash.iconAsset, kLaunchIconAsset);
    expect(splash.backgroundColor, kLaunchBackgroundColor);
  });
}
