import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:ukalab_core/ui.dart';

/// 起動時画面のアイコン（store/icon/hazmat4_1024.png を縮小した版）。
const kLaunchIconAsset = 'assets/icon/app_icon_256.png';

/// 起動時画面の背景色。アイコン画像の背景（赤橙のグラデーション）の中間色に合わせる。
const kLaunchBackgroundColor = Color(0xFFC23D16);

/// 初期化（端末内データの読み込み）中に出す起動時画面。
/// MaterialApp の外（runApp の最初）で使えるよう、テーマ付きの MaterialApp で包む。
class LaunchSplashApp extends StatelessWidget {
  const LaunchSplashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: UkalabTheme.light(field: UkalabField.tech, cert: UkalabCert.hazmat4),
      home: const StartupSplash(
        appIconAsset: kLaunchIconAsset,
        backgroundColor: kLaunchBackgroundColor,
      ),
    );
  }
}
