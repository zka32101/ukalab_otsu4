# 相互紹介（うかラボ共通・cross_promo_kit 利用）

うかラボ8アプリの相互紹介は、独自実装ではなく `ukalab_core` の薄いラッパー（内部で `cross_promo_kit` を使用）で行う。

## このアプリでの実装

| 項目 | 場所 |
|---|---|
| 初期化 | `lib/main.dart` の `unawaited(UkalabCrossPromo.init())`（Firebase 初期化＋kit 初期化。失敗しても例外を投げず、起動を止めない） |
| 表示 | `lib/views/settings_view.dart` の `UkalabCrossPromoSection(currentAppId: kCrossPromoAppId)`（掲載0件なら何も表示しない） |
| appId | `lib/data/cross_promo_setup.dart` の `kCrossPromoAppId`（`com.yourwish.ukalab_otsu`。android の applicationId と一致することを `test/cross_promo_test.dart` で検証） |
| 子ども向け | 大人向けのため `isChildDirected` は付けない（既定 false） |
| テスト | `test/cross_promo_test.dart`（掲載0件・Firebase無しで例外なし／掲載ありで表示／init が例外を投げない／appId 一致） |

学習中画面（問題・模擬試験・復習・危険予測）には置かない。設定画面のみ。

## 掲載リスト（Remote Config 側の作業）

掲載内容（各アプリのストアURL・アイコン・カテゴリ「うかラボ」）は Firebase の Remote Config で配信し、コードでは変更できない。
Remote Config のキー名と JSON の正確な仕様は **cross_promo_kit のドキュメント（v0.3.0）を参照**すること。

1要素の形（テストで使っている形。値はプレースホルダ）:

```json
{
  "id": "<対象アプリの applicationId>",
  "name": "<アプリ名>",
  "tagline": "<一言>",
  "iconUrl": "<アイコンURL>",
  "storeUrl": "<ストアURL>",
  "category": "うかラボ"
}
```

- 対象 Firebase プロジェクトへの投入は運営判断。空のままなら何も表示されない。
- `google-services.json` はリポジトリに置かず、CI で Secret `GOOGLE_SERVICES_JSON_BASE64` から生成する（README 参照）。

## 新しいうかラボアプリを足すとき

`ukalab_core` の `lib/ukalab_app_ids.dart`（`kUkalabAppIds`）に applicationId を追記する。
