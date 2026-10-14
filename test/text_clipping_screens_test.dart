import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otsu4/views/bookmark_list_view.dart';
import 'package:otsu4/views/character_preview_view.dart';
import 'package:otsu4/views/extinguisher_match_view.dart';
import 'package:otsu4/views/field_day_view.dart';
import 'package:otsu4/views/focus_training_view.dart';
import 'package:otsu4/views/glossary_card_view.dart';
import 'package:otsu4/views/mock_report_view.dart';
import 'package:otsu4/views/mock_wrong_review_view.dart';
import 'package:otsu4/views/nagara_study_view.dart';
import 'package:otsu4/views/question_search_view.dart';
import 'package:otsu4/views/reading_list_view.dart';
import 'package:otsu4/views/recent_glossary_terms_view.dart';
import 'package:otsu4/views/source_credits_view.dart';
import 'package:otsu4/views/srs_calendar_view.dart';
import 'package:otsu4/views/srs_item_list_view.dart';
import 'package:otsu4/views/storage_puzzle_view.dart';
import 'package:otsu4/views/streak_calendar_view.dart';
import 'package:otsu4/views/study_tools_view.dart';
import 'package:otsu4/views/temperature_lab_view.dart';
import 'package:otsu4/views/violation_hunt_view.dart';
import 'package:otsu4/views/weak_review_view.dart';

import 'support/clip_harness.dart';

/// 画面ごとに、狭い幅・大きい文字で RenderFlex overflow 等が出ないことを確認する。
final _screens = <String, Widget Function()>{
  'bookmark': () => const BookmarkListView(),
  'character_preview': () => const CharacterPreviewView(),
  'extinguisher': () => const ExtinguisherMatchView(),
  'field_day': () => const FieldDayView(),
  'focus_training': () => const FocusTrainingView(),
  'glossary': () => const GlossaryCardView(),
  'mock_report': () => const MockReportView(),
  'mock_wrong_review': () => const MockWrongReviewView(),
  'nagara_study': () => const NagaraStudyView(),
  'question_search': () => const QuestionSearchView(),
  'reading_list': () => const ReadingListView(),
  'recent_glossary': () => const RecentGlossaryTermsView(),
  'source_credits': () => const SourceCreditsView(),
  'srs_calendar': () => const SrsCalendarView(),
  'srs_item_list': () => const SrsItemListView(),
  'storage_puzzle': () => const StoragePuzzleView(),
  'streak_calendar': () => const StreakCalendarView(),
  'study_tools': () => const StudyToolsView(),
  'temperature_lab': () => const TemperatureLabView(),
  'violation_hunt': () => const ViolationHuntView(),
  'weak_review': () => const WeakReviewView(),
};

void main() {
  setUpAll(preloadAssets);

  for (final width in [320.0, 280.0]) {
    for (final scale in [1.0, 2.0, 3.0]) {
      final tag = '幅${width.toInt()}・文字$scale倍';
      _screens.forEach((name, build) {
        testWidgets('$name は$tagでオーバーフローしない', (tester) async {
          await pumpClip(tester, build(), width: width, scale: scale);
          expectNoLayoutErrors(tester);
        });
      });
    }
  }
}
