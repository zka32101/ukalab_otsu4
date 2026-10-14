import 'package:app_common_kit/app_common_kit.dart';
import 'package:app_common_kit/hands_free_tts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ukalab_core/ui.dart';
import 'package:ukalab_core/ukalab_core.dart';

import '../data/exam_repository.dart';
import '../data/glossary.dart';
import '../data/question_repository.dart';
import '../data/reading_repository.dart';
import '../data/selected_level_store.dart';
import 'glossary_card_view.dart';
import 'practice_session_view.dart';

/// 章ごとの解説読み物の一覧。選択中の類（乙4・乙1等）に関係する科目の
/// 読み物だけを表示する。
class ReadingListView extends ConsumerWidget {
  const ReadingListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readingsAsync = ref.watch(chapterReadingsProvider);
    final examAsync = ref.watch(examConfigProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('章ごとの解説読み物')),
      body: readingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text('読み込みに失敗しました。')),
        data: (all) {
          final exam = examAsync.valueOrNull;
          final level = exam == null ? null : currentLevel(exam, ref.watch(selectedLevelIdProvider));
          final ids = level?.subjectQuestionCounts?.keys.toSet();
          final readings = ids == null ? all : [for (final r in all) if (ids.contains(r.subjectId)) r];
          if (readings.isEmpty) {
            return const EmptyState(message: '解説読み物のデータがまだありません。');
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: readings.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final r = readings[i];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.menu_book_outlined),
                  title: Text(r.title),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => ReadingDetailView(reading: r)),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// 読み物の詳細。用語は用語集（`glossary.dart`）の用語名を termId として繋ぐ。
class ReadingDetailView extends ConsumerWidget {
  const ReadingDetailView({super.key, required this.reading});

  final ChapterReading reading;

  bool _isPremium(WidgetRef ref) => canUsePremiumFeature(
        PremiumFeature.readingReadAloud,
        isPremium: (ref.read(entitlementStateProvider).valueOrNull ?? EntitlementState.free)
            .hasPremium,
      );

  void _openQuestion(BuildContext context, String qid) async {
    final all = await const QuestionRepository().load();
    final matched = [for (final q in all) if (q.qid == qid) q];
    if (matched.isEmpty || !context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('関連問題')),
          body: ScrollablePracticeSession(pool: matched, emptyMessage: '問題が見つかりません。'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = reading;
    final questions = ref.watch(_questionsProvider).valueOrNull ?? const <Question>[];
    final allText = r.sections.map((s) => s.body).join('\n');
    return Scaffold(
      appBar: AppBar(title: Text(r.title)),
      body: ChapterReadingWidget(
        title: r.title,
        sections: [
          for (final s in r.sections) ReadingSectionView(heading: s.heading, body: s.body),
        ],
        relatedTerms: [
          for (final id in r.relatedTermIds) RelatedTermRef(termId: id, label: id),
        ],
        relatedQuestions: [
          for (final id in r.relatedQuestionIds)
            for (final q in questions)
              if (q.qid == id) RelatedQuestionRef(questionId: id, label: q.prompt),
        ],
        bodyTermReferences: termReferencesIn(allText),
        onRelatedTermTap: (termId) => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => GlossaryCardView(initialTerm: termId)),
        ),
        onRelatedQuestionTap: (qid) => _openQuestion(context, qid),
        onReadAloud: !_isPremium(ref)
            ? null
            : () {
                final text = r.sections.map((s) => '${s.heading}。${s.body}').join('');
                ref.read(handsFreeSpeakerProvider).speakNow(text);
              },
      ),
    );
  }
}

final _questionsProvider = FutureProvider<List<Question>>((ref) => const QuestionRepository().load());
