import 'package:app_common_kit/app_common_kit.dart';
import 'package:app_common_kit/hands_free_tts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ukalab_core/ukalab_core.dart';

import '../data/answer_recording.dart';
import '../data/exam_repository.dart';
import '../data/question_repository.dart';
import '../data/recent_questions.dart';
import '../data/selected_level_store.dart';

/// ながら学習(ながらセッション)で1回に出す問題数の上限。
/// 到達すると「ひと休みしましょう」の声かけで終わる(キットの文言。責める言い方はしない)。
const int kNagaraSessionLimit = 20;

/// ながら学習。画面を点けている間、問題と選択肢を読み → 考える間 → 正解と解説を読み → 次へ、を自動で進める。
/// 出題は一問一答(`PracticeSessionView`)と同じ選び方(選択中の類の科目に絞り、直近に出した問題を避けて
/// ランダム)。選択式の問題だけを使う。バックグラウンド再生・音声入力は無い(画面が消えると止まる)。
class NagaraStudyView extends ConsumerStatefulWidget {
  const NagaraStudyView({super.key, this.pool, this.limit = kNagaraSessionLimit});

  /// 出題元。省略時は、選択中の類の全問題を読み込む(テストでは差し替える)。
  final List<Question>? pool;

  /// 1回に出す問題数の上限。
  final int limit;

  @override
  ConsumerState<NagaraStudyView> createState() => _NagaraStudyViewState();
}

class _NagaraStudyViewState extends ConsumerState<NagaraStudyView> {
  List<Question>? _picked;
  late final int _seed = DateTime.now().millisecondsSinceEpoch;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    var pool = widget.pool;
    if (pool == null) {
      final exam = await const ExamRepository().load();
      final all = await const QuestionRepository().load();
      final level = currentLevel(exam, ref.read(selectedLevelIdProvider));
      final subjectIds = level.subjectQuestionCounts?.keys.toSet();
      pool = subjectIds == null ? all : [for (final q in all) if (subjectIds.contains(q.subjectId)) q];
    }
    if (!mounted) return;
    final choice = [for (final q in pool) if (q.type == QuestionType.choice && !q.disabled) q];
    // 上限に達したことを知らせられるよう、上限より1問多く用意する(使うのは先頭の limit 問まで)。
    final size = widget.limit + 1;
    final minSize = choice.length < size ? choice.length : size;
    final recent = ref.read(recentQuestionsProvider).toSet();
    final candidates = excludeRecent(choice, recent, (q) => q.qid, minPoolSize: minSize);
    final picked = PracticeSession(pool: candidates, size: size, seed: _seed).questions;
    setState(() => _picked = picked);
    final shown = [for (final q in picked.take(widget.limit)) q.qid];
    Future.microtask(() {
      if (mounted) ref.read(recentQuestionsProvider.notifier).recordShown(shown);
    });
  }

  Question _byId(String id) => _picked!.firstWhere((q) => q.qid == id);

  /// タップで答えた問題は、正答・誤答とも1問ごとに、通常の解答と同じ経路に記録する
  /// (間違いノートは解答履歴から作られる)。未回答・スキップは記録しない。
  void _onAnswered(NagaraQuestion q, int chosen, bool correct) {
    recordPracticeAnswer(ref, _byId(q.id), correct: correct, isActive: () => mounted);
  }

  @override
  Widget build(BuildContext context) {
    final picked = _picked;
    return Scaffold(
      appBar: AppBar(title: const Text('ながら学習')),
      body: picked == null
          ? const Center(child: CircularProgressIndicator())
          : picked.isEmpty
              ? const EmptyState(message: '出題できる問題がまだありません。', icon: Icons.headphones_outlined)
              : NagaraSessionView(
                  questions: [
                    for (final q in picked)
                      NagaraQuestion(
                        id: q.qid,
                        prompt: q.prompt,
                        choices: q.choices,
                        correctIndex: q.answerIndex,
                        explanation: q.explanation,
                      ),
                  ],
                  maxQuestions: widget.limit,
                  onAnswered: _onAnswered,
                  onClose: () => Navigator.of(context).maybePop(),
                ),
    );
  }
}
