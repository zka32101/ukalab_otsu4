import 'package:flutter/material.dart';

import 'bookmark_list_view.dart';
import 'character_preview_view.dart';
import 'focus_training_view.dart';
import 'glossary_card_view.dart';
import 'memo_list_view.dart';
import 'mock_report_view.dart';
import 'mock_wrong_review_view.dart';
import 'question_search_view.dart';
import 'reading_list_view.dart';
import 'recent_glossary_terms_view.dart';
import 'streak_calendar_view.dart';
import 'srs_calendar_view.dart';
import 'weak_review_view.dart';

/// 学ぶタブに増えてきた補助ツール（用語集・検索・メモ・復習カレンダー等）を
/// まとめて見渡せる一覧。学ぶタブの入り口カードは条件付き表示（件数が0の
/// ときは隠れる）が、この一覧は常にすべてのツールを一覧できる。
class StudyToolsView extends StatelessWidget {
  const StudyToolsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('学習ツール一覧')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ToolTile(
            icon: Icons.history_edu_outlined,
            title: '苦手問題の復習',
            description: '間違えた問題を、間隔をあけて優先的に出題します',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const WeakReviewView()),
            ),
          ),
          _ToolTile(
            icon: Icons.event_available_outlined,
            title: '復習カレンダー',
            description: '苦手問題の復習予定を日別に見える化します',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SrsCalendarView()),
            ),
          ),
          _ToolTile(
            icon: Icons.fitness_center_outlined,
            title: '集中特訓',
            description: '正答率が低い分野だけを優先的に演習します',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FocusTrainingView()),
            ),
          ),
          _ToolTile(
            icon: Icons.replay_outlined,
            title: '前回の模試の間違い',
            description: '直近の模擬試験で間違えた問題をまとめて復習します',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MockWrongReviewView()),
            ),
          ),
          _ToolTile(
            icon: Icons.summarize_outlined,
            title: '成績レポート',
            description: '模擬試験の受験履歴・得点率の推移・合格予測をまとめて確認します',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MockReportView()),
            ),
          ),
          _ToolTile(
            icon: Icons.bookmark_outlined,
            title: 'ブックマーク',
            description: '気になる問題だけをまとめて見返せます',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BookmarkListView()),
            ),
          ),
          _ToolTile(
            icon: Icons.sticky_note_2_outlined,
            title: '自分用メモの一覧',
            description: '書き残したメモをまとめて見返せます',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MemoListView()),
            ),
          ),
          _ToolTile(
            icon: Icons.auto_stories_outlined,
            title: '章ごとの解説読み物',
            description: '法令・物理化学・性質消火を教科書のように体系的に読めます',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ReadingListView()),
            ),
          ),
          _ToolTile(
            icon: Icons.menu_book_outlined,
            title: '用語集',
            description: '引火点・指定数量など、頻出用語を暗記カードで確認できます',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const GlossaryCardView()),
            ),
          ),
          _ToolTile(
            icon: Icons.star_outline,
            title: 'お気に入り単語帳',
            description: 'お気に入り登録した用語だけを、ランダム順の暗記カードで復習できます',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const GlossaryCardView(initialFavoritesOnly: true, initialShuffle: true),
              ),
            ),
          ),
          _ToolTile(
            icon: Icons.search_outlined,
            title: '重要語句で探す',
            description: 'キーワードから、関連する用語集・問題をまとめて探せます',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const QuestionSearchView()),
            ),
          ),
          _ToolTile(
            icon: Icons.history_outlined,
            title: '最近見た用語',
            description: '用語集で定義を見た用語を、新しい順に振り返れます',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RecentGlossaryTermsView()),
            ),
          ),
          _ToolTile(
            icon: Icons.calendar_month_outlined,
            title: '学習カレンダー',
            description: '目標達成日・解答した日を、直近28日間のカレンダーで見える化します',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const StreakCalendarView()),
            ),
          ),
          _ToolTile(
            icon: Icons.face_retouching_natural_outlined,
            title: '推しの衣装プレビュー',
            description: 'いま装備中の衣装を着た状態で、5人のキャラクターを比較できます',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CharacterPreviewView()),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolTile extends StatelessWidget {
  const _ToolTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(description),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
