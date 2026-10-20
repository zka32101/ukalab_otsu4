import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/exam_repository.dart';
import '../data/question_repository.dart';

/// 収録問題数。全体と、分野（科目。性質・消火は第1〜6類ごとに分かれている）ごとの件数を
/// 有効な問題プール（[activeQuestionsProvider]。新形式問題のフラグ適用後）から動的に数える。
class QuestionCountCard extends ConsumerWidget {
  const QuestionCountCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final pool = ref.watch(activeQuestionsProvider).valueOrNull;
    final exam = ref.watch(examConfigProvider).valueOrNull;
    final subjects = [...?exam?.subjects]..sort((a, b) => a.order.compareTo(b.order));
    final names = {for (final s in subjects) s.subjectId: s.name};
    final rows = pool == null
        ? const <(String, int)>[]
        : countBySubject(pool, order: [for (final s in subjects) s.subjectId]);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('収録問題数', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            if (pool == null)
              const Text('読み込み中…')
            else if (pool.isEmpty)
              const Text('問題データがありません。')
            else ...[
              Text(
                '全体 ${pool.length}問',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              for (final r in rows)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: Text(names[r.$1] ?? r.$1)),
                      const SizedBox(width: 12),
                      Text('${r.$2}問', style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
