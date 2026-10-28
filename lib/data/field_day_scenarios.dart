import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:ukalab_core/ukalab_core.dart';

/// 「現場の1日」の職場別シナリオ（ガソリンスタンド・化学工場の貯蔵所・危険物倉庫）のデータ。
///
/// 既存の「現場の1日」（`field_day.dart`。4場面を毎回ランダムに組み立てる）はそのまま
/// 無料で使える。ここで追加する職場別シナリオはプレミアム限定。

/// `contentStatus` が `ai-draft` のシナリオにだけ出す、AI下書きであることの表示。
/// 体験コンテンツは専門家確認不要と判断済み(2026-10-28)のため、現行の3本には付かない。
const String kFieldDayScenarioDraftNotice = '学習用の架空シナリオ(AI下書き・専門確認前)';

/// データに付ける AI 下書きの印(`contentStatus`)。
const String kFieldDayContentStatusAiDraft = 'ai-draft';

/// 配信を許す `contentStatus`。空(キーなし)は通常コンテンツ。これ以外は品質ゲートで拒否する。
const Set<String> kFieldDayAllowedContentStatuses = <String>{'', kFieldDayContentStatusAiDraft};

/// 無料で遊べる職場別シナリオ。既存の「現場の1日」が無料のため、追加分はすべてプレミアム限定。
const Set<String> freeFieldDayScenarioIds = <String>{};

const String kFieldDayScenarioAsset = 'assets/experience/field_day_workplaces_hazmat4.jsonl';

/// 学習コンテンツに使わない表現。
const List<String> kFieldDayForbiddenWords = ['公式', '本試験相当', '過去問', '合格保証'];

/// コア側の [StoryScenario] に、アプリ側の追加項目(contentStatus)を足したもの。
class FieldDayWorkplace {
  const FieldDayWorkplace({required this.story, required this.contentStatus});

  final StoryScenario story;

  /// 通常コンテンツは空(キーなし)。AI下書きは 'ai-draft'。
  final String contentStatus;

  String get scenarioId => story.scenarioId;
  bool get isFree => freeFieldDayScenarioIds.contains(scenarioId);
  bool get isAiDraft => contentStatus == kFieldDayContentStatusAiDraft;
}

class ParsedFieldDayWorkplaces {
  const ParsedFieldDayWorkplaces(this.scenarios, this.issues);

  final List<FieldDayWorkplace> scenarios;
  final List<ContentIssue> issues;
}

ParsedFieldDayWorkplaces parseFieldDayWorkplaces(String text) {
  final base = parseStoryScenariosJsonl(text);
  final extras = <String, Map<String, dynamic>>{};
  for (final raw in const LineSplitter().convert(text)) {
    final line = raw.trim();
    if (line.isEmpty || line.startsWith('//')) continue;
    try {
      final decoded = jsonDecode(line);
      if (decoded is Map<String, dynamic> && decoded['scenarioId'] is String) {
        extras[decoded['scenarioId'] as String] = decoded;
      }
    } on FormatException {
      // 構文の問題は parseStoryScenariosJsonl 側で報告済み。
    }
  }
  final scenarios = <FieldDayWorkplace>[];
  for (final s in base.scenarios) {
    final j = extras[s.scenarioId] ?? const <String, dynamic>{};
    scenarios.add(FieldDayWorkplace(
      story: s,
      contentStatus: j['contentStatus'] is String ? j['contentStatus'] as String : '',
    ));
  }
  return ParsedFieldDayWorkplaces(scenarios, base.issues);
}

/// 配信前の品質ゲート。コアの検査に加えて、contentStatus(未知の値は拒否)・出典・禁止表現を確かめる。
List<ContentIssue> validateFieldDayWorkplaces(
  List<FieldDayWorkplace> items, {
  required ExamConfig exam,
}) {
  final issues = <ContentIssue>[
    ...validateStoryScenarios([for (final i in items) i.story], exam: exam),
  ];
  for (final item in items) {
    final s = item.story;
    void add(String code, String message) => issues.add(ContentIssue(s.scenarioId, code, message));
    if (!kFieldDayAllowedContentStatuses.contains(item.contentStatus)) {
      add('unknown-content-status', 'contentStatus が不明な値です: ${item.contentStatus}');
    }
    if (s.source != QuestionSource.original) add('not-original', 'source は original(自作)である必要があります');
    if (!s.sourceRef.contains('自作')) add('no-self-made', 'sourceRef に自作である旨がありません');
    final all = jsonEncode(s.toJson());
    for (final w in kFieldDayForbiddenWords) {
      if (all.contains(w)) add('forbidden-word', '使わない表現が含まれています: $w');
    }
  }
  return issues;
}

Future<List<FieldDayWorkplace>> loadFieldDayWorkplaces() async {
  final text = await rootBundle.loadString(kFieldDayScenarioAsset);
  final parsed = parseFieldDayWorkplaces(text);
  if (parsed.issues.isNotEmpty) {
    throw StateError('現場の1日(職場別)のデータに不備があります: ${parsed.issues.first}');
  }
  return parsed.scenarios.where((s) => !s.story.disabled).toList();
}
