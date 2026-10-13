import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ukalab_core/glossary.dart' show LearnedTermsStore;

/// 用語集の「覚えた」の保存先（ukalab_core の共通部品）。キーは
/// `ukalab_otsu4_learned_term_ids`。termId には用語名（`GlossaryTerm.term`）を使う。
/// 用語名を変えると、その用語の「覚えた」は外れる（安定IDへの移行は別課題）。
final LearnedTermsStore learnedTermsStore = LearnedTermsStore('otsu4');

/// 旧実装（`GlossaryMasteredStore`）の保存キー。値は用語名のJSON配列文字列。
const legacyGlossaryMasteredKey = 'ukalab_otsu4_glossary_mastered';

/// 旧キーからの取り込みが済んだことを表すフラグのキー。
const learnedTermsMigratedKey = 'ukalab_otsu4_learned_terms_migrated_v1';

/// 旧キー `ukalab_otsu4_glossary_mastered` の「覚えた」を [store] へ取り込む。
///
/// 冪等: 取り込み済みフラグ（[learnedTermsMigratedKey]）が立っていれば何もしない。
/// 旧キーは消さずに残す（アプリを前のバージョンへ戻しても「覚えた」が見えるため）。
/// 二重取り込みはフラグで防ぐので、旧キーが残っていても支障はない。
/// 取り込みは和集合（新ストアに既にある分は消さない）。旧データが壊れていれば空として扱い、
/// フラグだけ立てる。
Future<void> migrateLegacyGlossaryMastered(LearnedTermsStore store) async {
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool(learnedTermsMigratedKey) ?? false) return;
  final legacy = _readLegacy(prefs);
  if (legacy.isNotEmpty) {
    final current = await store.load();
    await store.replace({...current, ...legacy});
  }
  await prefs.setBool(learnedTermsMigratedKey, true);
}

/// 旧キーを削除する（リセット・旧形式バックアップの読み込み時）。移行済みフラグは立てたままにし、
/// 以後に旧キーから再取り込みされないようにする。
Future<void> clearLegacyGlossaryMastered() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(legacyGlossaryMasteredKey);
  await prefs.setBool(learnedTermsMigratedKey, true);
}

Set<String> _readLegacy(SharedPreferences prefs) {
  try {
    final raw = prefs.getString(legacyGlossaryMasteredKey);
    if (raw == null) return {};
    return (jsonDecode(raw) as List).cast<String>().toSet();
  } catch (_) {
    return {};
  }
}

/// `main()` で移行・読み込みした「覚えた」の初期値を渡すための Provider。
final learnedTermsInitialProvider = Provider<Set<String>>((ref) => const {});

/// 「覚えた」にした用語名の集合。
class LearnedTermsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => ref.watch(learnedTermsInitialProvider);

  Future<void> toggle(String term) async {
    final learned = !state.contains(term);
    await learnedTermsStore.setLearned(term, learned);
    state = learned ? {...state, term} : ({...state}..remove(term));
  }

  /// 保存先から読み直す（バックアップの読み込み・リセットの後）。
  Future<void> reload() async {
    state = await learnedTermsStore.load();
  }
}

final learnedTermsProvider = NotifierProvider<LearnedTermsNotifier, Set<String>>(LearnedTermsNotifier.new);
