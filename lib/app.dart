import 'package:app_common_kit/app_common_kit.dart' show applyAppTextScale;
import 'package:ukalab_core/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ukalab_core/achievements.dart';
import 'data/theme_store.dart';
import 'views/home_view.dart';
import 'views/mock_exam_view.dart';
import 'views/record_view.dart';
import 'views/settings_view.dart';
import 'views/study_view.dart';

/// 実績バッジの解除通知のスナックバーを、どの画面にいても表示するためのキー。
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class Otsu4App extends ConsumerWidget {
  const Otsu4App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    watchAchievementUnlocks(ref, scaffoldMessengerKey);
    return MaterialApp(
      title: 'うかラボ 危険物乙4',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: scaffoldMessengerKey,
      theme: UkalabTheme.light(field: UkalabField.tech, cert: UkalabCert.hazmat4),
      darkTheme: UkalabTheme.dark(field: UkalabField.tech, cert: UkalabCert.hazmat4),
      themeMode: themeMode,
      // 文字の大きさ（設定画面で選ぶ）を端末の文字サイズに掛け合わせる。
      builder: applyAppTextScale,
      home: UkalabShell(
        pages: [
          HomeView(),
          StudyView(),
          MockExamView(),
          RecordView(),
          SettingsView(),
        ],
      ),
    );
  }
}
