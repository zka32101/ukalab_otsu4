import 'package:flutter/material.dart';

/// 解答後の解説カード。不正解時に濃い赤背景へ文字を載せると読みにくかったため、
/// 背景は surface に errorContainer を薄く混ぜた色、文字は onSurface（テーマから取得）にする。
/// 色だけに頼らないよう、アイコンと見出し（「解説（不正解）」）を併記する。
/// ライト/ダークとも文字と背景のコントラストは 4.5:1（WCAG AA）以上になる
/// （`test/answer_explanation_card_test.dart` で検証）。
class AnswerExplanationCard extends StatelessWidget {
  const AnswerExplanationCard({super.key, required this.text, required this.incorrect});

  final String text;
  final bool incorrect;

  /// 背景色（不透明）。テストでも同じ値を使ってコントラストを検証する。
  static Color backgroundOf(ColorScheme scheme, {required bool incorrect}) => incorrect
      ? Color.alphaBlend(scheme.errorContainer.withValues(alpha: 0.4), scheme.surface)
      : scheme.surfaceContainerHighest;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundOf(scheme, incorrect: incorrect),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: incorrect ? scheme.error : scheme.outlineVariant,
          width: incorrect ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                incorrect ? Icons.cancel_outlined : Icons.check_circle_outline,
                size: 18,
                color: scheme.onSurface,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  incorrect ? '解説（不正解）' : '解説',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            softWrap: true,
            style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurface, height: 1.7),
          ),
        ],
      ),
    );
  }
}
