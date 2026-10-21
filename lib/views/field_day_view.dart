import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ukalab_core/learning.dart';

import '../data/exercise_coins.dart';
import '../data/field_day.dart';

/// 現場の1日モード（画期的な機能E）。1日の勤務を模した4つの場面で、
/// 温度・指定数量・消火剤の判断を順番に答える。
class FieldDayView extends ConsumerStatefulWidget {
  const FieldDayView({super.key});

  @override
  ConsumerState<FieldDayView> createState() => _FieldDayViewState();
}

class _FieldDayViewState extends ConsumerState<FieldDayView> {
  FieldDayScenario _scenario = FieldDayScenario.generate(seed: 0);
  int _index = 0;
  int? _selected;
  bool _answered = false;
  int _correctCount = 0;

  void _select(int i) {
    if (_answered) return;
    final step = _scenario.steps[_index];
    final correct = i == step.correctIndex;
    setState(() {
      _selected = i;
      _answered = true;
      if (correct) _correctCount++;
    });
    recordExerciseAnswer(ref, correct: correct);
  }

  void _next() {
    setState(() {
      _index++;
      _selected = null;
      _answered = false;
    });
  }

  void _retry() {
    setState(() {
      _scenario = FieldDayScenario.generate(seed: DateTime.now().millisecondsSinceEpoch);
      _index = 0;
      _selected = null;
      _answered = false;
      _correctCount = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final steps = _scenario.steps;
    final finished = _index >= steps.length;

    return Scaffold(
      appBar: AppBar(title: const Text('現場の1日')),
      body: finished
          ? Center(
              child: ResultSummary(
                correct: _correctCount,
                total: steps.length,
                onRetry: _retry,
              ),
            )
          : _buildStep(theme, steps[_index]),
    );
  }

  Widget _buildStep(ThemeData theme, FieldDayStep step) {
    final correct = _answered && _selected == step.correctIndex;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Icon(Icons.schedule, color: theme.colorScheme.secondary, size: 20),
            const SizedBox(width: 6),
            Expanded(child: Text(step.timeLabel, style: theme.textTheme.titleSmall)),
            const SizedBox(width: 8),
            Text('${_index + 1} / ${_scenario.steps.length}', style: theme.textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(step.prompt, style: theme.textTheme.bodyLarge),
          ),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < step.choices.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OutlinedButton(
              onPressed: _answered ? null : () => _select(i),
              style: _answered && i == step.correctIndex
                  ? OutlinedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                      side: BorderSide(color: theme.colorScheme.primary, width: 2),
                    )
                  : (_answered && i == _selected
                      ? OutlinedButton.styleFrom(
                          side: BorderSide(color: theme.colorScheme.error, width: 2),
                        )
                      : null),
              child: Align(alignment: Alignment.centerLeft, child: Text(step.choices[i])),
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
          Text(step.explanation, style: theme.textTheme.bodySmall),
          const SizedBox(height: 16),
          FilledButton(onPressed: _next, child: const Text('次へ')),
        ],
      ],
    );
  }
}
