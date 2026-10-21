import 'dart:async';

import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ukalab_core/ukalab_core.dart';

import '../data/answer_recording.dart';
import '../data/combo_store.dart';
import '../data/feature_flags.dart';
import '../data/glossary.dart';
import '../data/history_store.dart';
import '../data/recent_questions.dart';
import '../data/review_schedule.dart';
import '../data/srs_store.dart';
import 'choice_labels.dart';
import 'glossary_card_view.dart';
import 'package:ukalab_core/answer_feedback.dart' show AnswerFeedbackPanel, WrongCause;
import 'package:ukalab_core/learning.dart';
import 'package:ukalab_core/ui.dart' show
        BookmarkToggleButton,
        ClozeQuestionView,
        QuestionMemoField,
        QuestionViewResult,
        ReverseLookupQuestionView,
        TappableTermText,
        TrueFalseQuestionView;

/// [PracticeSessionView] を、縦にスクロールできる形で置く。
///
/// [PracticeSessionView] 自身は縦に並べるだけでスクロールしないため、画面の高さに収まらない
/// 長い問題文・選択肢・解説（やアクセシビリティの大きい文字）が下にはみ出して隠れてしまう。
/// 一問一答（[StudyView]）のようにすでにスクロール内に置く場合は不要。
/// 最小の高さを画面に合わせるので、空表示は従来どおり中央に出る。
class ScrollablePracticeSession extends StatelessWidget {
  const ScrollablePracticeSession({
    super.key,
    required this.pool,
    required this.emptyMessage,
    this.mode = PracticeMode.practice,
    this.padding = const EdgeInsets.all(16),
  });

  final List<Question> pool;
  final String emptyMessage;
  final PracticeMode mode;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: padding,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: constraints.hasBoundedHeight
                ? (constraints.maxHeight - padding.vertical).clamp(0, double.infinity)
                : 0,
          ),
          child: PracticeSessionView(pool: pool, emptyMessage: emptyMessage, mode: mode),
        ),
      ),
    );
  }
}

/// 一問一答の演習（`Question` のプール）共通部分。[pool] が空なら
/// [emptyMessage] を表示する。[StudyView]（全体プール）と、苦手問題だけの
/// 復習（`WeakReviewView`）の両方で使う。直近出題した問題（アプリ起動中のみ
/// 記憶。`lib/data/recent_questions.dart`）は、プールが十分にあれば避ける。
class PracticeSessionView extends ConsumerStatefulWidget {
  const PracticeSessionView({
    super.key,
    required this.pool,
    required this.emptyMessage,
    this.mode = PracticeMode.practice,
    this.newTypesEnabled = kNewQuestionTypesEnabled,
  });

  final List<Question> pool;
  final String emptyMessage;
  final PracticeMode mode;

  /// ○×・空欄補充・説明から用語を出題に含めるか（既定は [kNewQuestionTypesEnabled]）。
  /// false のときは [pool] に含まれていても出さない（二重の防御）。
  final bool newTypesEnabled;

  @override
  ConsumerState<PracticeSessionView> createState() => _PracticeSessionViewState();
}

class _PracticeSessionViewState extends ConsumerState<PracticeSessionView> {
  PracticeSession? _session;
  int? _selected;
  bool _answered = false;
  int _combo = 0;

  /// 回答済みの間に画面へ出す問題（選択式・新タイプ共通）。[PracticeSession] は解答した時点で
  /// 「現在の問題」を次へ進めるため、「次へ」を押すまでは解答した問題で描く。
  Question? _answeredQuestion;

  late final List<Question> _pool =
      selectableQuestions(widget.pool, newTypesEnabled: widget.newTypesEnabled);

  @override
  void initState() {
    super.initState();
    _restart(seed: DateTime.now().millisecondsSinceEpoch);
  }

  void _restart({required int seed}) {
    final minSize = _pool.length < 10 ? _pool.length : 10;
    final recentIds = ref.read(recentQuestionsProvider).toSet();
    final qs = excludeRecent(_pool, recentIds, (q) => q.qid, minPoolSize: minSize);
    setState(() {
      _session = qs.isEmpty
          ? null
          : PracticeSession(
              pool: qs,
              size: minSize,
              mode: widget.mode,
              seed: seed,
            );
      _selected = null;
      _answered = false;
      _answeredQuestion = null;
      _combo = 0;
    });
    final session = _session;
    if (session != null) {
      // initState からも呼ばれる。build 中の provider 変更(デバッグ時の assert)を避けるため次の microtask で記録する。
      final shown = session.questions.map((q) => q.qid).toList();
      Future.microtask(() {
        if (mounted) ref.read(recentQuestionsProvider.notifier).recordShown(shown);
      });
    }
  }

  void _select(int i) {
    final answeredQ = _session!.current!;
    final record = _session!.answer(i);
    setState(() {
      _selected = i;
      _answered = true;
      _answeredQuestion = answeredQ;
      _combo = record.correct ? _combo + 1 : 0;
    });
    if (record.correct) {
      ref.read(comboProvider.notifier).recordCombo(_combo);
    }
    recordPracticeAnswer(ref, answeredQ, correct: record.correct, isActive: () => mounted);
  }

  /// 新タイプ（○×・空欄補充・説明から用語）の解答。core の画面の結果を
  /// [PracticeSession] に渡し、通常の演習と同じ記録先へ書く。
  void _answerNewType(Question q, QuestionViewResult r) {
    final session = _session;
    if (session == null || _answered || session.current?.qid != q.qid) return;
    final AnswerRecord record;
    switch (q.type) {
      case QuestionType.trueFalse:
        record = session.answerTrueFalse(r.boolAnswer!);
      case QuestionType.cloze:
        record = session.answerCloze(r.blankAnswers!);
      case QuestionType.reverseLookup:
        record = session.answerReverseLookup(r.text!);
      case QuestionType.choice:
      case QuestionType.journal:
      case QuestionType.worksheet:
      case QuestionType.ledger:
        return;
    }
    setState(() {
      _answered = true;
      _answeredQuestion = q;
      _combo = record.correct ? _combo + 1 : 0;
    });
    if (record.correct) {
      ref.read(comboProvider.notifier).recordCombo(_combo);
    }
    recordPracticeAnswer(ref, q, correct: record.correct, isActive: () => mounted);
  }

  /// 自由入力の打ち間違いを本人が「合っていた」と申告したとき。直前の不正解の記録を正解に直す。
  /// （分野別統計・日別の解答数などの件数は解答時点のまま。履歴・復習予定・SRS を正解側に直す。）
  void _selfReported(Question q) {
    _session?.markLastSelfReportedCorrect();
    final now = DateTime.now();
    ref.read(historyProvider.notifier).markLatestCorrect(q.qid);
    ref.read(reviewScheduleProvider.notifier).applyResult(q.qid, correct: true, now: now);
    ref.read(srsProvider.notifier).review(qid: q.qid, correct: true);
    setState(() => _combo = _combo + 1);
  }

  Widget _buildNewType(Question q, PracticeSession session) {
    final index = session.index + (_answered ? 0 : 1);
    final total = session.questions.length;
    final terms = const <Term>[];
    void onCause(WrongCause? c) => ref.read(historyProvider.notifier).setCause(q.qid, c);
    final Widget view = switch (q.type) {
      QuestionType.trueFalse => TrueFalseQuestionView(
          key: ValueKey('tf-${q.qid}'),
          question: q,
          terms: terms,
          index: index,
          total: total,
          onAnswered: (r) => _answerNewType(q, r),
          onCause: onCause,
          onNext: _next,
        ),
      QuestionType.cloze => ClozeQuestionView(
          key: ValueKey('cloze-${q.qid}'),
          question: q,
          terms: terms,
          index: index,
          total: total,
          onAnswered: (r) => _answerNewType(q, r),
          onSelfReported: () => _selfReported(q),
          onCause: onCause,
          onNext: _next,
        ),
      QuestionType.reverseLookup => ReverseLookupQuestionView(
          key: ValueKey('rev-${q.qid}'),
          question: q,
          terms: terms,
          index: index,
          total: total,
          onAnswered: (r) => _answerNewType(q, r),
          onSelfReported: () => _selfReported(q),
          onCause: onCause,
          onNext: _next,
        ),
      QuestionType.choice ||
      QuestionType.journal ||
      QuestionType.worksheet ||
      QuestionType.ledger =>
        const SizedBox.shrink(),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(alignment: Alignment.centerRight, child: BookmarkToggleButton(qid: q.qid)),
        view,
        if (_answered) ...[
          const SizedBox(height: 12),
          QuestionMemoField(key: ValueKey(q.qid), qid: q.qid),
        ],
      ],
    );
  }

  void _next() {
    setState(() {
      _selected = null;
      _answered = false;
      _answeredQuestion = null;
    });
    // 最後の問題の次（結果表示）に進むときに、全画面広告を出す（頻度は AdGate が制限する）。
    if (_session?.current == null) {
      unawaited(ref.read(adGateProvider).maybeShowInterstitial(InterstitialTrigger.sessionEnd));
    }
  }

  void _retry() => _restart(seed: DateTime.now().millisecondsSinceEpoch);

  ChoiceState _choiceState(int i, int answerIndex) {
    if (!_answered) return ChoiceState.idle;
    if (i == answerIndex) return ChoiceState.correct;
    if (i == _selected) return ChoiceState.incorrect;
    return ChoiceState.idle;
  }

  @override
  Widget build(BuildContext context) {
    if (_pool.isEmpty) {
      return EmptyState(message: widget.emptyMessage, icon: Icons.menu_book_outlined);
    }

    final session = _session!;
    // 回答済みの間は、回答した問題で描く（session.current はすでに次の問題）。
    final answeredQ = _answered ? _answeredQuestion : null;
    if (answeredQ != null && isNewQuestionType(answeredQ)) {
      return _buildNewType(answeredQ, session);
    }
    final q = answeredQ ?? session.current;
    if (q == null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ResultSummary(
            correct: session.correctCount,
            total: session.questions.length,
            onRetry: _retry,
          ),
          const SizedBox(height: 16),
          ref.watch(adGateProvider).banner(BannerPlacement.result),
        ],
      );
    }

    if (isNewQuestionType(q)) return _buildNewType(q, session);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: QuestionCard(
                text: q.prompt,
                index: session.index + (_answered ? 0 : 1),
                total: session.questions.length,
              ),
            ),
            BookmarkToggleButton(qid: q.qid),
          ],
        ),
        if (_combo >= 2) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.local_fire_department_outlined,
                  size: 16, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  '$_combo問連続正解中',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Theme.of(context).colorScheme.primary),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        for (var i = 0; i < q.choices.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ChoiceTile(
              label: choiceLabels[i],
              text: q.choices[i],
              state: _choiceState(i, q.answerIndex),
              onTap: _answered ? null : () => _select(i),
            ),
          ),
        if (_answered) ...[
          const SizedBox(height: 8),
          Builder(builder: (context) {
            final terms = termReferencesIn(q.explanation);
            return ExplanationPanel(
              body: q.explanation,
              sourceRef: q.sourceRef,
              bodyWidget: terms.isEmpty
                  ? null
                  : TappableTermText(
                      text: q.explanation,
                      terms: terms,
                      onTermTap: (termId) => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => GlossaryCardView(initialTerm: termId)),
                      ),
                    ),
            );
          }),
          const SizedBox(height: 12),
          // 不正解のときだけ表示される（原因ラベル・違いの比較・対策）。
          AnswerFeedbackPanel(
            key: ValueKey('feedback-${q.qid}'),
            question: q,
            selectedIndex: _selected,
            onCause: (c) => ref.read(historyProvider.notifier).setCause(q.qid, c),
          ),
          const SizedBox(height: 12),
          QuestionMemoField(key: ValueKey(q.qid), qid: q.qid),
          const SizedBox(height: 16),
          FilledButton(onPressed: _next, child: const Text('次の問題')),
        ],
      ],
    );
  }
}
