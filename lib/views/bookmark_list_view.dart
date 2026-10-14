import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ukalab_core/ukalab_core.dart';

import '../data/exam_repository.dart';
import '../data/question_repository.dart';
import 'practice_session_view.dart';
import 'package:ukalab_core/ui.dart' show BookmarkTagEditScreen, bookmarkProvider, bookmarkTagProvider;

/// ブックマークした問題（`lib/data/bookmark_store.dart`）だけをまとめて
/// 演習できる画面。`StudyView` の一問一答でブックマークした問題がここに並ぶ。
/// 複数の分野にまたがる場合は分野別に、タグを付けた場合はタグでも絞り込める
/// （`lib/data/bookmark_tag_store.dart`。タグはAppBarの「タグを編集」から
/// つけられる）。
class BookmarkListView extends ConsumerStatefulWidget {
  const BookmarkListView({super.key});

  @override
  ConsumerState<BookmarkListView> createState() => _BookmarkListViewState();
}

class _BookmarkListViewState extends ConsumerState<BookmarkListView> {
  final _repo = const QuestionRepository();
  final _examRepo = const ExamRepository();
  List<Question>? _questions;
  ExamConfig? _exam;
  String? _subjectFilter;
  String? _tagFilter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await _repo.load();
    final exam = await _examRepo.load();
    if (!mounted) return;
    final qids = ref.read(bookmarkProvider);
    setState(() {
      _questions = [for (final q in all) if (qids.contains(q.qid)) q];
      _exam = exam;
    });
  }

  /// ブックマークした問題がある分野だけ、`ExamConfig` の並び順で返す。
  List<SubjectConfig> _availableSubjects(ExamConfig exam, List<Question> qs) {
    final ids = qs.map((q) => q.subjectId).toSet();
    final subjects = [for (final s in exam.subjects) if (ids.contains(s.subjectId)) s];
    subjects.sort((a, b) => a.order.compareTo(b.order));
    return subjects;
  }

  @override
  Widget build(BuildContext context) {
    final qs = _questions;
    final exam = _exam;
    if (qs == null || exam == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('ブックマーク')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final subjects = _availableSubjects(exam, qs);
    final filter = _subjectFilter;
    final subjectFilteredQs = filterBySubject(qs, filter);

    final tags = ref.watch(bookmarkTagProvider);
    final availableTags = allBookmarkTags(tags, qs.map((q) => q.qid));
    final tagFilter = _tagFilter;
    final filteredQs = tagFilter == null
        ? subjectFilteredQs
        : [for (final q in subjectFilteredQs) if ((tags[q.qid] ?? const {}).contains(tagFilter)) q];

    return Scaffold(
      appBar: AppBar(
        title: const Text('ブックマーク'),
        actions: [
          if (qs.isNotEmpty)
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => BookmarkTagEditScreen(questions: qs)),
              ),
              child: const Text('タグを編集'),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (subjects.length > 1) ...[
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  ChoiceChip(
                    label: const Text('すべて'),
                    selected: filter == null,
                    onSelected: (_) => setState(() => _subjectFilter = null),
                  ),
                  for (final s in subjects)
                    ChoiceChip(
                      label: Text(s.name),
                      selected: filter == s.subjectId,
                      onSelected: (_) => setState(() => _subjectFilter = s.subjectId),
                    ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            if (availableTags.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  ChoiceChip(
                    label: const Text('タグ: すべて'),
                    selected: tagFilter == null,
                    onSelected: (_) => setState(() => _tagFilter = null),
                  ),
                  for (final t in availableTags)
                    ChoiceChip(
                      label: Text(t),
                      selected: tagFilter == t,
                      onSelected: (_) => setState(() => _tagFilter = t),
                    ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            Expanded(
              child: ScrollablePracticeSession(
                key: ValueKey((filter, tagFilter)),
                padding: EdgeInsets.zero,
                pool: filteredQs,
                emptyMessage: qs.isEmpty
                    ? 'ブックマークはまだありません。一問一答で問題カードのしおりアイコンから登録できます。'
                    : '条件に合うブックマークはまだありません。',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
