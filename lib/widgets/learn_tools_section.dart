import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ukalab_core/ui.dart';
import 'package:ukalab_core/ukalab_core.dart';

import '../views/bookmark_list_view.dart';
import '../views/glossary_card_view.dart';
import '../views/memo_list_view.dart';
import '../views/mistake_note_screen.dart';
import '../views/reading_list_view.dart';

/// 「学ぶ」タブ下部の「道具」。間違いノート・ブックマーク・メモ・用語集・解説読み物への入口。
/// 件数が0でも入口は常に出す（以前は学ぶ／ホームに点在し、件数0だと隠れていた）。
/// 見出し名は ukalab_it_passport / ukalab_boki / ukalab_g_kentei の「学ぶ」と同じ。
class LearnToolsSection extends ConsumerWidget {
  const LearnToolsSection({super.key, required this.exam});

  final ExamConfig exam;

  void _push(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarkCount = ref.watch(bookmarkProvider).length;
    final memoCount = ref.watch(questionMemoProvider).length;
    return HomeSection(
      title: '道具',
      subtitle: '調べる・見返す',
      leading: const Icon(Icons.handyman_outlined),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HomeMenuTile(
              icon: Icons.edit_note_outlined,
              title: '間違いノート',
              subtitle: '間違えた問題を見返して、解き直せます。',
              onTap: () => openMistakeNote(context, ref, exam: exam),
            ),
            const SizedBox(height: 8),
            HomeMenuTile(
              icon: Icons.bookmark_outlined,
              title: 'ブックマーク',
              subtitle: bookmarkCount > 0
                  ? '$bookmarkCount問。気になる問題だけをまとめて見返せます'
                  : '気になる問題だけをまとめて見返せます',
              onTap: () => _push(context, const BookmarkListView()),
            ),
            const SizedBox(height: 8),
            HomeMenuTile(
              icon: Icons.sticky_note_2_outlined,
              title: '自分用メモの一覧',
              subtitle: memoCount > 0
                  ? '$memoCount件。書き残したメモをまとめて見返せます'
                  : '書き残したメモをまとめて見返せます',
              onTap: () => _push(context, const MemoListView()),
            ),
            const SizedBox(height: 8),
            HomeMenuTile(
              icon: Icons.menu_book_outlined,
              title: '用語集',
              subtitle: '引火点・指定数量など、頻出用語を暗記カードで確認できます',
              onTap: () => _push(context, const GlossaryCardView()),
            ),
            const SizedBox(height: 8),
            HomeMenuTile(
              icon: Icons.auto_stories_outlined,
              title: '章ごとの解説読み物',
              subtitle: '法令・物理化学・性質消火を、教科書のように体系的に読めます',
              onTap: () => _push(context, const ReadingListView()),
            ),
          ],
        ),
      ),
    );
  }
}
