import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ukalab_core/ukalab_core.dart';

import '../data/question_repository.dart';
import '../data/subject_stats_store.dart';
import 'practice_session_view.dart';

/// 集中特訓（苦手分野の優先出題）。[subjectId] を指定しなければ、解答数が
/// 十分あり正答率が低い分野（`weakSubjectIds`。`lib/data/subject_stats_store.dart`）
/// の問題だけをまとめて演習する。[subjectId] を指定すると、弱点マップの
/// タップ等から、しきい値にかかわらずその分野だけを直接演習できる。
class FocusTrainingView extends ConsumerStatefulWidget {
  const FocusTrainingView({super.key, this.subjectId, this.subjectName});

  /// 指定すると、この分野だけを演習する（`weakSubjectIds` の判定は使わない）。
  final String? subjectId;

  /// [subjectId] 指定時にタイトル・空状態の文言で使う分野名。
  final String? subjectName;

  @override
  ConsumerState<FocusTrainingView> createState() => _FocusTrainingViewState();
}

class _FocusTrainingViewState extends ConsumerState<FocusTrainingView> {
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
    final subjectId = widget.subjectId;
    if (subjectId != null) {
      setState(() => _questions = [for (final q in all) if (q.subjectId == subjectId) q]);
      return;
    }
    final weakIds = weakSubjectIds(ref.read(subjectStatsProvider)).toSet();
    setState(() => _questions = [for (final q in all) if (weakIds.contains(q.subjectId)) q]);
  }

  @override
  Widget build(BuildContext context) {
    final qs = _questions;
    final subjectName = widget.subjectName;
    return Scaffold(
      appBar: AppBar(title: Text(subjectName == null ? '集中特訓' : '$subjectNameの演習')),
      body: qs == null
          ? const Center(child: CircularProgressIndicator())
          : ScrollablePracticeSession(
              pool: qs,
              emptyMessage:
                  subjectName == null ? '苦手な分野はまだ特定できていません。' : 'この分野の問題データはまだありません。',
            ),
    );
  }
}
