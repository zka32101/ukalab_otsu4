import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ukalab_core/ukalab_core.dart';

import '../data/question_repository.dart';
import '../data/srs_store.dart';
import 'question_search_view.dart';

/// 苦手問題の復習（間隔反復）で記録中の問題を、箱（Box）番号・次回復習予定日
/// とともに一覧表示する画面。記録タブの「苦手問題の復習」カードから開く。
/// タップすると、その問題の詳細（読み取り専用）を確認できる。
class SrsItemListView extends ConsumerStatefulWidget {
  const SrsItemListView({super.key});

  @override
  ConsumerState<SrsItemListView> createState() => _SrsItemListViewState();
}

class _SrsItemListViewState extends ConsumerState<SrsItemListView> {
  final _repo = const QuestionRepository();
  Map<String, Question>? _byQid;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await _repo.load();
    if (!mounted) return;
    setState(() => _byQid = {for (final q in all) q.qid: q});
  }

  String _dueText(DateTime dueAt, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueAt.year, dueAt.month, dueAt.day);
    final days = due.difference(today).inDays;
    if (days <= 0) return '復習対象（期限切れ）';
    if (days == 1) return '次回復習: 明日';
    return '次回復習: $days日後（${due.month}/${due.day}）';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final byQid = _byQid;
    final srs = ref.watch(srsProvider);

    if (byQid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('苦手問題の一覧')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final items = [
      for (final item in srs.values) if (byQid.containsKey(item.qid)) item,
    ]..sort((a, b) => a.dueAt.compareTo(b.dueAt));
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: const Text('苦手問題の一覧')),
      body: items.isEmpty
          ? const Center(child: Text('間違えた問題はまだありません。'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final question = byQid[item.qid]!;
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Text('${item.box}')),
                    // 問題文は途中で切らず、全文を折り返して表示する。
                    title: Text(question.prompt),
                    subtitle: Text(
                      'Box ${item.box} / ${Srs.maxBox} ・ ${_dueText(item.dueAt, now)}',
                      style: theme.textTheme.bodySmall,
                    ),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => QuestionDetailView(question: question)),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
