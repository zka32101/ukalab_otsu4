import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 設定タブの「ながら学習」(片手・ハンズフリー)の設定。保存はキットの [handsFreeProvider]
/// (端末内。バックアップ・リセットの対象外。ユーザー設定として扱う)。
/// 文言と候補値はキットのもの([KitStrings]・[HandsFreeSettings])。
class NagaraSettingsSection extends ConsumerWidget {
  const NagaraSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = KitStrings.of(context);
    final nagara = strings.nagara;
    final settings = ref.watch(handsFreeProvider);
    final notifier = ref.read(handsFreeProvider.notifier);
    return SettingsSection(
      title: strings.settingsHandsFree,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(strings.handsFreeEnable),
          value: settings.enabled,
          onChanged: notifier.setEnabled,
        ),
        if (settings.enabled) ...[
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(strings.handsFreeSpeakQuestion),
            value: settings.speakQuestion,
            onChanged: notifier.setSpeakQuestion,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(strings.handsFreeSpeakExplanation),
            value: settings.speakExplanation,
            onChanged: notifier.setSpeakExplanation,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(strings.handsFreeSpeed),
            trailing: Text('${settings.speechRate.toStringAsFixed(1)}x'),
          ),
          Slider(
            semanticFormatterCallback: (v) => '${strings.handsFreeSpeed} ${v.toStringAsFixed(1)}x',
            value: settings.speechRate,
            min: HandsFreeSettings.minSpeechRate,
            max: HandsFreeSettings.maxSpeechRate,
            divisions: 10,
            label: '${settings.speechRate.toStringAsFixed(1)}x',
            onChanged: notifier.setSpeechRate,
          ),
          _SecondsChoice(
            title: nagara.settingsThinkSeconds,
            options: HandsFreeSettings.thinkSecondsOptions,
            value: settings.thinkSeconds,
            label: nagara.secondsOption,
            onSelected: notifier.setThinkSeconds,
          ),
          _SecondsChoice(
            title: nagara.settingsBetweenSeconds,
            options: HandsFreeSettings.betweenSecondsOptions,
            value: settings.betweenSeconds,
            label: nagara.secondsOption,
            onSelected: notifier.setBetweenSeconds,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(nagara.settingsAutoAdvance),
            value: settings.autoAdvance,
            onChanged: notifier.setAutoAdvance,
          ),
        ],
      ],
    );
  }
}

class _SecondsChoice extends StatelessWidget {
  const _SecondsChoice({
    required this.title,
    required this.options,
    required this.value,
    required this.label,
    required this.onSelected,
  });

  final String title;
  final List<int> options;
  final int value;
  final String Function(int seconds) label;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    // 保存済みの値が候補に無くても(旧データ・範囲内の任意値)、いまの値を選択肢に含めて見えるようにする。
    final shown = options.contains(value) ? options : ([...options, value]..sort());
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final s in shown)
                ChoiceChip(
                  label: Text(label(s)),
                  selected: s == value,
                  onSelected: (_) => onSelected(s),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
