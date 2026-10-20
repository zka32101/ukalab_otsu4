import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/exercise_coins.dart';
import '../data/violation.dart';
import '../widgets/answer_explanation_card.dart';

/// 違反探しモード（画期的な機能A）。4つの行動のうち、
/// 法令・消火の知識に違反しているものを1つ見つける。
class ViolationHuntView extends ConsumerStatefulWidget {
  const ViolationHuntView({super.key});

  @override
  ConsumerState<ViolationHuntView> createState() => _ViolationHuntViewState();
}

class _ViolationHuntViewState extends ConsumerState<ViolationHuntView> {
  ViolationScenario _scenario = ViolationScenario.generate(seed: 0);
  int? _selected;
  bool _answered = false;
  int _correctCount = 0;
  int _totalCount = 0;

  void _select(int i) {
    if (_answered) return;
    final correct = _scenario.statements[i].isViolation;
    setState(() {
      _selected = i;
      _answered = true;
      _totalCount++;
      if (correct) _correctCount++;
    });
    recordExerciseAnswer(ref, correct: correct);
  }

  void _next() {
    setState(() {
      _scenario = ViolationScenario.generate(seed: DateTime.now().millisecondsSinceEpoch);
      _selected = null;
      _answered = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statements = _scenario.statements;
    final violationIndex = _scenario.violationIndex;
    final correct = _answered && _selected == violationIndex;

    return Scaffold(
      appBar: AppBar(title: const Text('違反探しモード')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '次の4つの行動のうち、法令・消火の知識に違反しているものを1つ選んでください。',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < statements.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _StatementCard(
                index: i,
                statement: statements[i],
                selected: _selected == i,
                answered: _answered,
                onTap: () => _select(i),
              ),
            ),
          if (_answered) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  correct ? Icons.check_circle : Icons.cancel,
                  color: correct ? theme.colorScheme.primary : theme.colorScheme.error,
                ),
                const SizedBox(width: 8),
                Text(
                  correct ? '正解' : '不正解',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: correct ? theme.colorScheme.primary : theme.colorScheme.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            AnswerExplanationCard(
              text: statements[violationIndex].explanation,
              incorrect: !correct,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _next, child: const Text('次の問題')),
          ],
          const SizedBox(height: 16),
          Text('$_correctCount / $_totalCount 問正解', style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _StatementCard extends StatelessWidget {
  const _StatementCard({
    required this.index,
    required this.statement,
    required this.selected,
    required this.answered,
    required this.onTap,
  });

  final int index;
  final ViolationStatement statement;
  final bool selected;
  final bool answered;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTheViolation = answered && statement.isViolation;
    final borderColor = isTheViolation
        ? theme.colorScheme.error
        : (selected ? theme.colorScheme.outline : null);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: borderColor != null
            ? BorderSide(color: borderColor, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: answered ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(child: Text(statement.text)),
              if (isTheViolation)
                Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error),
            ],
          ),
        ),
      ),
    );
  }
}
