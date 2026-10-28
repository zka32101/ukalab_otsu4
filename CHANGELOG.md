# CHANGELOG

## 2026-10-28

- 「現場の1日」職場別シナリオ3本(`assets/experience/field_day_workplaces_hazmat4.jsonl`)から `contentStatus: ai-draft` を外した。体験コンテンツは専門家確認不要(あくまで体験)との判断による。専門家確認済みではなく、`sourceRef` は「AI下書き由来(体験コンテンツ、専門家確認は不要と判断)」。本文は変更なし。
- 品質ゲート `validateFieldDayWorkplaces`: `no-ai-draft` を `unknown-content-status` に置き換え。`contentStatus` が空(通常)か `ai-draft` 以外は拒否する。
- 画面の「AI下書き・専門確認前」注記は、`ai-draft` のシナリオがあるときだけ表示。
- 用語集 `lib/data/glossary.dart` の `aiDraft: true`(31語)は今回対象外(未決)。
