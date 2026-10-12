import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ukalab_core/ukalab_core.dart';

import '../data/glossary.dart';
import '../data/glossary_favorite_store.dart';
import '../data/question_repository.dart';
import 'choice_labels.dart';
import 'glossary_card_view.dart';
import 'package:ukalab_core/ui.dart' show QuestionDetailScreen, TappableTermText, bookmarkProvider;

/// 重要語句で、用語集・問題を横断的に検索できる画面。学ぶタブの入り口から
/// いつでも開ける（問題データの有無にかかわらず用語集の検索はできる）。
/// 「ブックマークのみ」をオンにすると、問題の検索対象をブックマーク済みの
/// 問題だけに絞り込める。
class QuestionSearchView extends ConsumerStatefulWidget {
  const QuestionSearchView({super.key});

  @override
  ConsumerState<QuestionSearchView> createState() => _QuestionSearchViewState();
}

class _QuestionSearchViewState extends ConsumerState<QuestionSearchView> {
  final _repo = const QuestionRepository();
  final _controller = TextEditingController();
  List<Question>? _all;
  String _keyword = '';
  bool _bookmarkOnly = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await _repo.load();
    if (!mounted) return;
    setState(() => _all = all);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final all = _all;
    final bookmarked = ref.watch(bookmarkProvider);
    final favoriteTerms = ref.watch(glossaryFavoriteProvider);
    final matchedTerms = searchGlossaryTerms(_keyword);
    final searchPool = all == null ? const <Question>[] : filterByBookmark(
          all,
          bookmarked,
          onlyBookmarked: _bookmarkOnly,
        );
    final matchedQuestions = searchQuestions(searchPool, _keyword);
    final keywordIsEmpty = _keyword.trim().isEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('重要語句で探す')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: '引火点・指定数量 など',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _keyword = v),
            ),
            const SizedBox(height: 8),
            FilterChip(
              label: const Text('ブックマークのみ'),
              selected: _bookmarkOnly,
              onSelected: (v) => setState(() => _bookmarkOnly = v),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: all == null
                  ? const Center(child: CircularProgressIndicator())
                  : keywordIsEmpty
                      ? const EmptyState(
                          message: 'キーワードを入力すると、関連する用語・問題が見つかります。',
                          icon: Icons.search,
                        )
                      : matchedTerms.isEmpty && matchedQuestions.isEmpty
                          ? const EmptyState(
                              message: '一致する用語・問題は見つかりませんでした。',
                              icon: Icons.search_off,
                            )
                          : ListView(
                              children: [
                                if (matchedTerms.isNotEmpty) ...[
                                  Text('用語集（${matchedTerms.length}件）', style: theme.textTheme.titleSmall),
                                  const SizedBox(height: 8),
                                  for (final t in matchedTerms)
                                    _GlossaryResultCard(
                                      term: t,
                                      isFavorite: favoriteTerms.contains(t.term),
                                      onToggleFavorite: () =>
                                          ref.read(glossaryFavoriteProvider.notifier).toggle(t.term),
                                      onOpenCard: () => Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => GlossaryCardView(initialTerm: t.term),
                                        ),
                                      ),
                                    ),
                                  const Divider(),
                                ],
                                if (matchedQuestions.isNotEmpty) ...[
                                  Text('問題（${matchedQuestions.length}件）', style: theme.textTheme.titleSmall),
                                  for (final q in matchedQuestions)
                                    ListTile(
                                      leading: const Icon(Icons.quiz_outlined),
                                      title: Text(q.prompt, maxLines: 2, overflow: TextOverflow.ellipsis),
                                      onTap: () => Navigator.of(context).push(
                                        MaterialPageRoute(builder: (_) => QuestionDetailView(question: q)),
                                      ),
                                    ),
                                ],
                              ],
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 検索結果・メモ一覧から開く、1問だけの読み取り専用の詳細表示。画面本体は
/// ukalab_core の [QuestionDetailScreen]。解説の用語はタップして用語集を開ける。
class QuestionDetailView extends StatelessWidget {
  const QuestionDetailView({super.key, required this.question});

  final Question question;

  @override
  Widget build(BuildContext context) {
    return QuestionDetailScreen(
      question: question,
      choiceLabels: choiceLabels,
      explanationBuilder: (context, q) {
        final terms = termReferencesIn(q.explanation);
        if (terms.isEmpty) return null;
        return TappableTermText(
          text: q.explanation,
          terms: terms,
          onTermTap: (termId) => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => GlossaryCardView(initialTerm: termId)),
          ),
        );
      },
    );
  }
}

/// 重要語句検索の用語集セクション1件。タップして暗記カードを開かなくても、
/// 用語名・定義・補足をカード内にそのまま表示する。
class _GlossaryResultCard extends StatelessWidget {
  const _GlossaryResultCard({
    required this.term,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onOpenCard,
  });

  final GlossaryTerm term;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback onOpenCard;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onOpenCard,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.menu_book_outlined, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(term.term, style: theme.textTheme.titleSmall)),
                  IconButton(
                    icon: Icon(isFavorite ? Icons.star : Icons.star_border, size: 20),
                    color: isFavorite ? theme.colorScheme.primary : null,
                    tooltip: isFavorite ? 'お気に入りを解除' : 'お気に入りに追加',
                    onPressed: onToggleFavorite,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(term.definition, style: theme.textTheme.bodyMedium),
              if (term.note != null) ...[
                const SizedBox(height: 4),
                Text(term.note!, style: theme.textTheme.bodySmall),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
