import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ukalab_core/ukalab_core.dart';

import '../data/mock_wrong_store.dart';
import '../data/question_repository.dart';
import 'practice_session_view.dart';

/// 直近の模擬試験で間違えた問題だけをまとめて演習する画面。模試終了直後の
/// 「間違えた問題を振り返る」（`MockReviewView`。読み取り専用）とは別に、
/// 選んで答える一問一答として、模試を離れたあとでも復習できるようにする
/// （`lib/data/mock_wrong_store.dart`）。
class MockWrongReviewView extends ConsumerStatefulWidget {
  const MockWrongReviewView({super.key});

  @override
  ConsumerState<MockWrongReviewView> createState() => _MockWrongReviewViewState();
}

class _MockWrongReviewViewState extends ConsumerState<MockWrongReviewView> {
  final _repo = const QuestionRepository();
  List<Question>? _questions;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await _repo.load();
    if (!mounted) return;
    final wrongQids = ref.read(mockWrongProvider).toSet();
    setState(() => _questions = [for (final q in all) if (wrongQids.contains(q.qid)) q]);
  }

  @override
  Widget build(BuildContext context) {
    final qs = _questions;
    return Scaffold(
      appBar: AppBar(title: const Text('前回の模試で間違えた問題')),
      body: qs == null
          ? const Center(child: CircularProgressIndicator())
          : ScrollablePracticeSession(
              pool: qs,
              emptyMessage: '前回の模試では間違えた問題はありませんでした。',
            ),
    );
  }
}
