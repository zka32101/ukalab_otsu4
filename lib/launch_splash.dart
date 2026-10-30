import 'package:flutter/material.dart';
import 'package:ukalab_core/ui.dart';

/// 起動時画面のアイコン（透過の adaptive foreground。角丸クリップはしない）。
const kLaunchIconAsset = 'assets/icon/app_icon_foreground.png';

/// 起動時画面のアイコンの表示サイズ。
/// このアプリの前景画像は余白が大きく（中身が画像の約43%）、既定の160では
/// 他のうかラボアプリ（G検定は中身が約60%）より小さく見えるため、見える大きさを揃える。
const double kLaunchIconSize = 224;

/// 起動時画面の背景色。端末側の起動画面（ic_launcher_background）と同じ色にして一枚の画面に見せる。
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
      home: const UkalabStartupSplash(
        backgroundColor: kLaunchBackgroundColor,
        iconAsset: kLaunchIconAsset,
        iconSize: kLaunchIconSize,
      ),
    );
  }
}
