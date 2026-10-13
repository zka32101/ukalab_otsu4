import 'dart:async';

import 'package:app_common_kit/app_common_kit.dart';
import 'package:ukalab_core/cross_promo.dart';
import 'package:ukalab_core/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'package:ukalab_core/achievements.dart';
import 'data/achievements_provider.dart';
import 'data/answered_questions_store.dart';
import 'data/combo_store.dart';
import 'data/daily_answer_stats_store.dart';
import 'package:ukalab_core/daily_goal.dart';
import 'package:ukalab_core/reminder.dart';
import 'data/exam_date_store.dart';
import 'data/glossary_favorite_store.dart';
import 'data/learned_terms.dart';
import 'data/mock_history_store.dart';
import 'data/mock_wrong_store.dart';
import 'data/progress_store.dart';
import 'data/recent_glossary_terms_store.dart';
import 'data/selected_level_store.dart';
import 'data/srs_store.dart';
import 'data/subject_stats_history_store.dart';
import 'data/subject_stats_store.dart';
import 'data/theme_store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 学習コイン・衣装（app_common_kit）。財布はアプリごと。端末内に保存する。
  // コインは学習の成長でのみ獲得する（課金・広告視聴での付与はしない）。
  final coinService = CoinService(
    store: SharedPreferencesCoinStore('otsu4'),
    shop: OutfitCatalog.shopItems([UkalabCert.hazmat4]),
  );
  await coinService.load();
  final outfitService = OutfitService(store: SharedPreferencesOutfitStore('otsu4'));
  await outfitService.load();

  // 推しの成長の暫定の進捗指標（問題データが入るまでの代替。README参照）。
  final progressService = ProgressService();
  await progressService.load();

  // 苦手問題の復習（間隔反復）。端末内に保存する。
  final srsService = SrsService();
  await srsService.load();

  // 模擬試験の結果履歴。端末内に保存する。
  final mockHistoryService = MockHistoryService();
  await mockHistoryService.load();

  // 直近の模擬試験で間違えた問題のqid。端末内に保存する。
  final mockWrongService = MockWrongService();
  await mockWrongService.load();

  // 気になる問題のブックマーク・タグ・問題ごとの自分用メモ。端末内に保存する。
  final studyNotes = await studyNotesOverrides('otsu4');

  // デイリーミッション（今日の目標問題数）と、その達成履歴（日次スナップショット）。端末内に保存する。
  final dailyGoalOverridesList = await dailyGoalOverrides('otsu4');

  // 分野別の解答数・正解数。端末内に保存する。
  final subjectStatsService = SubjectStatsService();
  await subjectStatsService.load();

  // 分野別正答率の推移（日次スナップショット）。端末内に保存する。
  final subjectStatsHistoryService = SubjectStatsHistoryService();
  await subjectStatsHistoryService.load();

  // テーマ設定（ライト／ダーク／端末に合わせる）。端末内に保存する。
  final themeService = ThemeService();
  await themeService.load();

  // 試験日（本番の日付）。端末内に保存する。
  final examDateService = ExamDateService();
  await examDateService.load();

  // 選択中の類（乙4・乙1等）。端末内に保存する。
  final selectedLevelService = SelectedLevelService();
  await selectedLevelService.load();

  // これまでに解答した問題のqid（分野別の出題網羅率で使う）。端末内に保存する。
  final answeredQuestionsService = AnsweredQuestionsService();
  await answeredQuestionsService.load();

  // お気に入りに登録した用語集の用語。端末内に保存する。
  final glossaryFavoriteService = GlossaryFavoriteService();
  await glossaryFavoriteService.load();

  // 「覚えた」と自己申告した用語集の用語。端末内に保存する。
  // 旧キー（ukalab_otsu4_glossary_mastered）からの取り込みは初回のみ行う。
  await migrateLegacyGlossaryMastered(learnedTermsStore);
  final learnedTerms = await learnedTermsStore.load();

  // アプリ内リマインダー（学習・模試）の個別オン/オフ設定。端末内に保存する。
  final reminderOverridesList = await reminderOverrides('otsu4');

  // 最近見た用語集の用語（新しい順）。端末内に保存する。
  final recentGlossaryTermsService = RecentGlossaryTermsService();
  await recentGlossaryTermsService.load();

  // 一問一答の連続正解数（コンボ）の自己最高記録。端末内に保存する。
  final comboService = ComboService();
  await comboService.load();

  // 日別の解答数・正解数（ホームの今週の学習サマリーで使う）。端末内に保存する。
  final dailyAnswerStatsService = DailyAnswerStatsService();
  await dailyAnswerStatsService.load();

  // 実績バッジの解除通知済みID（二重通知防止）。端末内に保存する。
  final achievementUnlockOverridesList = await achievementUnlockOverrides('otsu4');

  // 課金（RevenueCat）。実際のAPIキー取得後にRevenueCatEntitlementServiceへ差し替える。
  // 価格は競合調査を踏まえた暫定値で、運営者確認が必要（決定14）。
  final entitlementService = FakeEntitlementService(
    availableOffers: const [
      EntitlementOffer(
        id: 'noads',
        productId: 'otsu4_noads',
        title: '広告非表示',
        priceString: '¥480',
      ),
      EntitlementOffer(
        id: 'premium',
        productId: 'otsu4_premium',
        title: 'プレミアム（広告非表示＋追加機能）',
        priceString: '¥1,500',
      ),
    ],
    grantOnPurchase: const {
      'otsu4_noads': EntitlementState(hasNoAds: true),
      'otsu4_premium': EntitlementState(hasPremium: true),
    },
  );

  // 相互紹介（ukalab_core）。Firebase 初期化と Remote Config 取得を内部でまとめて行い、
  // 失敗（設定ファイル未配置など）しても例外を投げず起動を止めない。
  unawaited(UkalabCrossPromo.init());

  runApp(
    ProviderScope(
      overrides: [
        entitlementServiceProvider.overrideWithValue(entitlementService),
        coinServiceProvider.overrideWithValue(coinService),
        outfitServiceProvider.overrideWithValue(outfitService),
        progressServiceProvider.overrideWithValue(progressService),
        srsServiceProvider.overrideWithValue(srsService),
        mockHistoryServiceProvider.overrideWithValue(mockHistoryService),
        mockWrongServiceProvider.overrideWithValue(mockWrongService),
        ...studyNotes,
        ...dailyGoalOverridesList,
        subjectStatsServiceProvider.overrideWithValue(subjectStatsService),
        subjectStatsHistoryServiceProvider.overrideWithValue(subjectStatsHistoryService),
        themeServiceProvider.overrideWithValue(themeService),
        examDateServiceProvider.overrideWithValue(examDateService),
        selectedLevelServiceProvider.overrideWithValue(selectedLevelService),
        answeredQuestionsServiceProvider.overrideWithValue(answeredQuestionsService),
        glossaryFavoriteServiceProvider.overrideWithValue(glossaryFavoriteService),
        learnedTermsInitialProvider.overrideWithValue(learnedTerms),
        ...reminderOverridesList,
        recentGlossaryTermsServiceProvider.overrideWithValue(recentGlossaryTermsService),
        comboServiceProvider.overrideWithValue(comboService),
        dailyAnswerStatsServiceProvider.overrideWithValue(dailyAnswerStatsService),
        ...achievementUnlockOverridesList,
        achievementsOverride,
      ],
      child: const Otsu4App(),
    ),
  );
}
