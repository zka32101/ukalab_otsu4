import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/glossary.dart';
import '../data/glossary_favorite_store.dart';
import '../data/learned_terms.dart';
import '../data/recent_glossary_terms_store.dart';
import 'recent_glossary_terms_view.dart';

/// 分野フィルタの選択肢（表示名）。nullは「すべて」。
const _subjectFilterLabels = <String?, String>{
  null: 'すべて',
  'law': '法令',
  'physics_chem': '物理化学',
  'property_extinguish': '性質・消火',
};

/// 乙4の頻出用語の暗記カード。タップで表（用語）・裏（定義）を切り替え、
/// 「次へ」で次の用語に進む。分野（法令・物理化学・性質消火）・お気に入り
/// （`lib/data/glossary_favorite_store.dart`）・未習得（自己申告の「覚えた」
/// フラグ、`lib/data/learned_terms.dart`）で絞り込める。
/// `lib/data/glossary.dart` の既存の確認済みデータに基づく定義を使い、
/// 新たな一次資料の収集は行っていない。
class GlossaryCardView extends ConsumerStatefulWidget {
  const GlossaryCardView({
    super.key,
    this.initialTerm,
    this.initialFavoritesOnly = false,
    this.initialShuffle = false,
  });

  /// 開いた直後に表示する用語（検索・解説文中のタップから遷移した場合）。
  /// 一致しなければ最初の用語から表示する（フィルタは「すべて」で開く）。
  final String? initialTerm;

  /// 開いた直後から「お気に入りのみ」を有効にするか（お気に入り単語帳の
  /// 入り口から開いた場合）。
  final bool initialFavoritesOnly;

  /// 開いた直後から「ランダム順」を有効にするか。
  final bool initialShuffle;

  @override
  ConsumerState<GlossaryCardView> createState() => _GlossaryCardViewState();
}

class _GlossaryCardViewState extends ConsumerState<GlossaryCardView> {
  String? _subjectFilter;
  late bool _favoritesOnly;
  bool _unmasteredOnly = false;
  late bool _shuffle;
  bool _alphabetical = false;
  List<GlossaryTerm>? _shuffledCache;
  late int _index;
  late bool _showDefinition;

  @override
  void initState() {
    super.initState();
    _favoritesOnly = widget.initialFavoritesOnly;
    _shuffle = widget.initialShuffle;
    final found = widget.initialTerm == null
        ? -1
        : glossaryTerms.indexWhere((t) => t.term == widget.initialTerm);
    _index = found >= 0 ? found : 0;
    // 検索・解説文中のタップから来た場合は、用語名ではなく定義を直接見せる。
    _showDefinition = found >= 0;
    if (_showDefinition) {
      ref.read(recentGlossaryTermsProvider.notifier).record(widget.initialTerm!);
    }
  }

  void _setSubjectFilter(String? subjectId) {
    setState(() {
      _subjectFilter = subjectId;
      _index = 0;
      _showDefinition = false;
    });
  }

  void _toggleFavoritesOnly() {
    setState(() {
      _favoritesOnly = !_favoritesOnly;
      _index = 0;
      _showDefinition = false;
    });
  }

  void _toggleUnmasteredOnly() {
    setState(() {
      _unmasteredOnly = !_unmasteredOnly;
      _index = 0;
      _showDefinition = false;
    });
  }

  void _toggleShuffle() {
    setState(() {
      _shuffle = !_shuffle;
      // シャッフルと五十音順は同時に有効にすると矛盾するため、排他にする。
      if (_shuffle) _alphabetical = false;
      _shuffledCache = null;
      _index = 0;
      _showDefinition = false;
    });
  }

  void _toggleAlphabetical() {
    setState(() {
      _alphabetical = !_alphabetical;
      if (_alphabetical) {
        _shuffle = false;
        _shuffledCache = null;
      }
      _index = 0;
      _showDefinition = false;
    });
  }

  /// [filtered] をシャッフルモード時はランダムな順序で、五十音順モード時は
  /// 用語名の文字コード順で返す。どちらでも無ければ元の並び順のまま。
  /// シャッフルは、フィルタの変更で対象の用語が変わらない限り、同じ並び順を
  /// 保つ（タップごとに並びが変わってしまうのを防ぐ）。
  List<GlossaryTerm> _displayTerms(List<GlossaryTerm> filtered) {
    if (_alphabetical) {
      return sortedGlossaryTermsAlphabetically(filtered);
    }
    if (!_shuffle) return filtered;
    final cache = _shuffledCache;
    if (cache != null && cache.length == filtered.length && cache.toSet().containsAll(filtered)) {
      return cache;
    }
    final shuffled = shuffledGlossaryTerms(filtered);
    _shuffledCache = shuffled;
    return shuffled;
  }

  void _next(int length) {
    setState(() {
      _index = (_index + 1) % length;
      _showDefinition = false;
    });
  }

  void _prev(int length) {
    setState(() {
      _index = (_index - 1 + length) % length;
      _showDefinition = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final favorites = ref.watch(glossaryFavoriteProvider);
    final mastered = ref.watch(learnedTermsProvider);
    final filtered = filterGlossaryTerms(
      subjectId: _subjectFilter,
      favoritesOnly: _favoritesOnly,
      favoriteTerms: favorites,
      unmasteredOnly: _unmasteredOnly,
      masteredTerms: mastered,
    );
    final terms = _displayTerms(filtered);

    final filterRow = Column(
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final entry in _subjectFilterLabels.entries)
              ChoiceChip(
                label: Text(entry.value),
                selected: _subjectFilter == entry.key,
                onSelected: (_) => _setSubjectFilter(entry.key),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            FilterChip(
              label: const Text('お気に入りのみ'),
              selected: _favoritesOnly,
              onSelected: (_) => _toggleFavoritesOnly(),
            ),
            FilterChip(
              label: const Text('未習得のみ'),
              selected: _unmasteredOnly,
              onSelected: (_) => _toggleUnmasteredOnly(),
            ),
            FilterChip(
              label: const Text('ランダム順'),
              avatar: const Icon(Icons.shuffle, size: 18),
              selected: _shuffle,
              onSelected: (_) => _toggleShuffle(),
            ),
            FilterChip(
              label: const Text('五十音順'),
              avatar: const Icon(Icons.sort_by_alpha, size: 18),
              selected: _alphabetical,
              onSelected: (_) => _toggleAlphabetical(),
            ),
          ],
        ),
      ],
    );

    // 文字が大きい端末ではフィルタが縦に伸びて下の暗記カードを押し出す（はみ出す）ため、
    // 画面の高さの一定割合までに抑え、それ以上はスクロールで見られるようにする。
    final cappedFilterRow = ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.35),
      child: SingleChildScrollView(child: filterRow),
    );

    final historyAction = IconButton(
      icon: const Icon(Icons.history_outlined),
      tooltip: '最近見た用語',
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const RecentGlossaryTermsView()),
      ),
    );

    if (terms.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('用語集'), actions: [historyAction]),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              cappedFilterRow,
              const SizedBox(height: 24),
              const Expanded(
                child: Center(child: Text('該当する用語がありません。')),
              ),
            ],
          ),
        ),
      );
    }

    final index = _index.clamp(0, terms.length - 1);
    final term = terms[index];
    final isFavorite = favorites.contains(term.term);
    final isMastered = mastered.contains(term.term);

    return Scaffold(
      appBar: AppBar(title: const Text('用語集'), actions: [historyAction]),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            cappedFilterRow,
            const SizedBox(height: 12),
            Text(
              '${index + 1} / ${terms.length}',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: () {
                      final nextShowDefinition = !_showDefinition;
                      setState(() => _showDefinition = nextShowDefinition);
                      if (nextShowDefinition) {
                        ref.read(recentGlossaryTermsProvider.notifier).record(term.term);
                      }
                    },
                    child: Card(
                      // 定義が長い用語や大きい文字でもカードからはみ出さないよう、中身をスクロールできるようにする
                      // （短いときは従来どおり中央に置く）。
                      child: LayoutBuilder(
                        builder: (context, constraints) => SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: (constraints.maxHeight - 48).clamp(0, double.infinity),
                            ),
                            child: Center(
                              child: _showDefinition
                                  ? Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          term.definition,
                                          style: theme.textTheme.titleMedium,
                                          textAlign: TextAlign.center,
                                        ),
                                        if (term.note != null) ...[
                                          const SizedBox(height: 16),
                                          Text(
                                            term.note!,
                                            style: theme.textTheme.bodySmall,
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ],
                                    )
                                  : Text(
                                      term.term,
                                      style: theme.textTheme.headlineSmall,
                                      textAlign: TextAlign.center,
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    left: 4,
                    child: IconButton(
                      icon: Icon(isMastered ? Icons.check_circle : Icons.check_circle_outline),
                      color: isMastered ? theme.colorScheme.primary : null,
                      tooltip: isMastered ? '覚えたを解除' : '覚えた',
                      onPressed: () => ref.read(learnedTermsProvider.notifier).toggle(term.term),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton(
                      icon: Icon(isFavorite ? Icons.star : Icons.star_border),
                      color: isFavorite ? theme.colorScheme.primary : null,
                      tooltip: isFavorite ? 'お気に入りを解除' : 'お気に入りに追加',
                      onPressed: () => ref.read(glossaryFavoriteProvider.notifier).toggle(term.term),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _showDefinition ? 'タップで用語に戻る' : 'タップで定義を見る',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _prev(terms.length),
                    child: const Text('前へ'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _next(terms.length),
                    child: const Text('次へ'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
