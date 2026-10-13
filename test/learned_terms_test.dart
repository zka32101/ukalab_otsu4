import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otsu4/data/data_parts.dart';
import 'package:otsu4/data/glossary.dart';
import 'package:otsu4/data/glossary_favorite_store.dart';
import 'package:otsu4/data/learned_terms.dart';
import 'package:otsu4/views/glossary_card_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ukalab_core/ui.dart'
    show DataPart, encodeLearningDataBackupAsync, resetLearningData, restoreLearningDataBackup;

const _newKey = 'ukalab_otsu4_learned_term_ids';

void main() {
  group('migrateLegacyGlossaryMastered', () {
    test('旧データがあれば新ストアへ取り込む（旧キーは残す）', () async {
      SharedPreferences.setMockInitialValues({
        legacyGlossaryMasteredKey: jsonEncode(['引火点', '指定数量']),
      });
      await migrateLegacyGlossaryMastered(learnedTermsStore);
      expect(await learnedTermsStore.load(), {'引火点', '指定数量'});
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(legacyGlossaryMasteredKey), isNotNull);
      expect(prefs.getBool(learnedTermsMigratedKey), isTrue);
    });

    test('旧データが無ければ何も取り込まず、フラグだけ立てる', () async {
      SharedPreferences.setMockInitialValues({});
      await migrateLegacyGlossaryMastered(learnedTermsStore);
      expect(await learnedTermsStore.load(), isEmpty);
      expect((await SharedPreferences.getInstance()).getBool(learnedTermsMigratedKey), isTrue);
    });

    test('二回目の起動では再取り込みしない（解除した「覚えた」が復活しない）', () async {
      SharedPreferences.setMockInitialValues({
        legacyGlossaryMasteredKey: jsonEncode(['引火点', '指定数量']),
      });
      await migrateLegacyGlossaryMastered(learnedTermsStore);
      await learnedTermsStore.setLearned('引火点', false);
      await migrateLegacyGlossaryMastered(learnedTermsStore);
      expect(await learnedTermsStore.load(), {'指定数量'});
    });

    test('新ストアに既にある分は消さず、和集合にする', () async {
      SharedPreferences.setMockInitialValues({
        legacyGlossaryMasteredKey: jsonEncode(['引火点']),
        _newKey: ['指定数量'],
      });
      await migrateLegacyGlossaryMastered(learnedTermsStore);
      expect(await learnedTermsStore.load(), {'引火点', '指定数量'});
    });

    test('旧データが壊れていても落ちない', () async {
      SharedPreferences.setMockInitialValues({legacyGlossaryMasteredKey: 'not json'});
      await migrateLegacyGlossaryMastered(learnedTermsStore);
      expect(await learnedTermsStore.load(), isEmpty);
    });
  });

  group('バックアップ・リセット', () {
    late WidgetRef ref;

    Future<void> pumpHost(WidgetTester tester) async {
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          home: Consumer(builder: (context, r, _) {
            ref = r;
            return const SizedBox();
          }),
        ),
      ));
    }

    List<DataPart> parts() => [
          for (final p in otsu4DataParts)
            if (p.id == 'learnedTerms' || p.id == 'glossaryMastered') p,
        ];

    testWidgets('書き出し→リセット→読み込みで元に戻る', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await pumpHost(tester);
      await tester.runAsync(() async {
        await ref.read(learnedTermsProvider.notifier).toggle('引火点');
        final text = await encodeLearningDataBackupAsync(ref, parts());
        final saved = (jsonDecode(text) as Map)['parts'] as Map;
        expect(saved['learnedTerms'], ['引火点']);
        expect(saved['glossaryMastered'], isNull);

        await resetLearningData(ref, parts());
        expect(ref.read(learnedTermsProvider), isEmpty);
        expect(await learnedTermsStore.load(), isEmpty);

        await restoreLearningDataBackup(ref, parts(), text);
        expect(ref.read(learnedTermsProvider), {'引火点'});
        expect(await learnedTermsStore.load(), {'引火点'});
      });
    });

    testWidgets('リセットで旧キーも消え、再起動しても再取り込みされない', (tester) async {
      SharedPreferences.setMockInitialValues({
        legacyGlossaryMasteredKey: jsonEncode(['引火点']),
      });
      await pumpHost(tester);
      await tester.runAsync(() async {
        await migrateLegacyGlossaryMastered(learnedTermsStore);
        await ref.read(learnedTermsProvider.notifier).reload();
        expect(ref.read(learnedTermsProvider), {'引火点'});

        await resetLearningData(ref, parts());
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString(legacyGlossaryMasteredKey), isNull);

        await migrateLegacyGlossaryMastered(learnedTermsStore);
        expect(await learnedTermsStore.load(), isEmpty);
      });
    });

    testWidgets('旧形式のバックアップ（glossaryMastered）も読み込める', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await pumpHost(tester);
      await tester.runAsync(() async {
        final legacy = jsonEncode({
          'version': 1,
          'glossaryMastered': ['指定数量'],
        });
        await restoreLearningDataBackup(ref, parts(), legacy);
        expect(ref.read(learnedTermsProvider), {'指定数量'});
        expect(await learnedTermsStore.load(), {'指定数量'});
      });
    });
  });

  group('GlossaryCardView', () {
    final first = glossaryTerms.first;

    Future<void> pumpCard(WidgetTester tester, {Set<String> learned = const {}}) async {
      final favorites = GlossaryFavoriteService();
      await tester.runAsync(favorites.load);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          learnedTermsInitialProvider.overrideWithValue(learned),
          glossaryFavoriteServiceProvider.overrideWithValue(favorites),
        ],
        child: const MaterialApp(home: GlossaryCardView()),
      ));
    }

    FilterChip unmasteredChip(WidgetTester tester) =>
        tester.widget<FilterChip>(find.widgetWithText(FilterChip, '未習得のみ'));

    testWidgets('「未習得のみ」は既定オフで、覚えた用語も表示される', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await pumpCard(tester, learned: {first.term});
      expect(unmasteredChip(tester).selected, isFalse);
      expect(find.text('1 / ${glossaryTerms.length}'), findsOneWidget);
      expect(find.text(first.term), findsOneWidget);
    });

    testWidgets('覚えたチェックの付け外しができ、保存される', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await pumpCard(tester);
      await tester.tap(find.byTooltip('覚えた'));
      await tester.pump();
      await tester.runAsync(() async {
        expect(await learnedTermsStore.load(), {first.term});
      });
      await tester.pump();
      expect(find.byTooltip('覚えたを解除'), findsOneWidget);

      await tester.tap(find.byTooltip('覚えたを解除'));
      await tester.pump();
      await tester.runAsync(() async {
        expect(await learnedTermsStore.load(), isEmpty);
      });
      await tester.pump();
      expect(find.byTooltip('覚えた'), findsOneWidget);
    });

    testWidgets('トグルでチェック済みを除外でき、他の絞り込みと併用できる', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await pumpCard(tester, learned: {first.term});
      await tester.tap(find.widgetWithText(FilterChip, '未習得のみ'));
      await tester.pump();
      expect(find.text('1 / ${glossaryTerms.length - 1}'), findsOneWidget);
      expect(find.text(first.term), findsNothing);

      // 五十音順・分野との併用。
      await tester.tap(find.widgetWithText(FilterChip, '五十音順'));
      await tester.pump();
      final subjectLabel = {
        'law': '法令',
        'physics_chem': '物理化学',
        'property_extinguish': '性質・消火',
      }[first.subjectId]!;
      await tester.tap(find.widgetWithText(ChoiceChip, subjectLabel));
      await tester.pump();
      final expected = glossaryTermsBySubject(first.subjectId).length - 1;
      expect(find.text('1 / $expected'), findsOneWidget);
      expect(find.text(first.term), findsNothing);

      // ランダム順に切り替えても件数は変わらない。
      await tester.tap(find.widgetWithText(FilterChip, 'ランダム順'));
      await tester.pump();
      expect(find.text('1 / $expected'), findsOneWidget);
    });

    testWidgets('お気に入りのみとの併用: お気に入りかつ未習得の用語だけが残る', (tester) async {
      final second = glossaryTerms[1];
      SharedPreferences.setMockInitialValues({
        'ukalab_otsu4_glossary_favorites': jsonEncode([first.term, second.term]),
      });
      await pumpCard(tester, learned: {first.term});
      await tester.tap(find.widgetWithText(FilterChip, 'お気に入りのみ'));
      await tester.pump();
      expect(find.text('1 / 2'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilterChip, '未習得のみ'));
      await tester.pump();
      expect(find.text('1 / 1'), findsOneWidget);
      expect(find.text(second.term), findsOneWidget);
    });
  });
}
