# 専門家レビュー対象（優先サンプル）

- 対象: 各ファイルの先頭・末尾10問＋法令/物理化学の数値を含む問題（優先サンプル）
- 必要な専門性: 危険物取扱者（乙4または甲種）・受験講習の指導経験者
- 一覧: `review_priority.csv`（UTF-8 BOM付き。Excel で開ける。末尾3列「判定(OK/修正/削除)」「コメント」「根拠」は空欄）
- 全問の確認ではなく**優先サンプル**。依頼文・観点・反映方法は ukalab_core の `docs/expert_review_requests.md` と `docs/expert_review_session_handover.md` を参照。
- 反映は別PRで。記録は確認日（年月）と確認者区分のみ。氏名・所属・連絡先は記録しない。
- 追加分(AI下書き)の確認用一覧: `physchem_class4_additions_checklist.md`(物理化学・第4類の追加80問。`ai-draft` 付き)、`multi_angle_checklist.md`(新形式36問)。
- 確認済み(2026-10-28): 上記の追加分(物理化学40問・第4類の類別/性質40問・新形式36問、計116問)は専門家の確認がOKとなり、`ai-draft` タグを外して `sourceRef` を「専門家確認済み」に更新した(`contentVer` は 2026.10.3)。チェックリストは記録として残す。
- 体験コンテンツの扱い(2026-10-28): 「現場の1日」職場別シナリオ3本(`assets/experience/field_day_workplaces_hazmat4.jsonl`)は、AI下書き由来だが「体験コンテンツは専門家確認不要(あくまで体験なので)」と判断し、`contentStatus: ai-draft` を外した。**専門家確認済みではない**ため `sourceRef` は「AI下書き由来(体験コンテンツ、専門家確認は不要と判断)」とし、本文は変更していない。用語集 `lib/data/glossary.dart` の `aiDraft: true`(31語)は用語データで体験コンテンツではないため対象外(未決)。
