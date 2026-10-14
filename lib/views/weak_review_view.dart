import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ukalab_core/ukalab_core.dart';

import '../data/question_repository.dart';
import '../data/srs_store.dart';
import 'practice_session_view.dart';

/// 苦手問題（間違えた問題を間隔反復で優先出題する復習）の画面。
/// `StudyView` の一問一答で間違えた問題が、復習時期が来ると表示対象になる。
class WeakReviewView extends ConsumerStatefulWidget {
  const WeakReviewView({super.key});

  @override
  ConsumerState<WeakReviewView> createState() => _WeakReviewViewState();
}

class _WeakReviewViewState extends ConsumerState<WeakReviewView> {
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
    final dueQids = ref.read(dueWeakQidsProvider).toSet();
    setState(() => _questions = [for (final q in all) if (dueQids.contains(q.qid)) q]);
  }

  @override
  Widget build(BuildContext context) {
    final qs = _questions;
    return Scaffold(
      appBar: AppBar(title: const Text('苦手問題の復習')),
      body: qs == null
          ? const Center(child: CircularProgressIndicator())
          : ScrollablePracticeSession(
              pool: qs,
              mode: PracticeMode.weak,
              emptyMessage: '苦手問題はありません。間違えた問題は、ここに表示されます。',
            ),
    );
  }
}
