# store/ — アプリアイコンの元素材（乙4 危険物取扱者）

資格ID: `hazmat4`。ストア掲載・ランチャーアイコン生成用の元素材を置くディレクトリです。
このリポジトリには `android/` `ios/` `web/` `macos/` が無く、ビルド時に `flutter create` で生成する運用のため、
ランチャーアイコン本体はここではコミットしていません。

## ファイル

| パス | 寸法 | 用途 |
|---|---|---|
| `store/icon/hazmat4_1024.png` | 1024x1024 / RGB | 正方形の完成版。ストア掲載・アプリ組込・各プラットフォームのアイコン生成の元 |
| `store/play/ukalab_hazmat4_icon_512.png` | 512x512 / RGBA(32bit) | Google Play の「アプリアイコン」(512px、1MB未満) |

## 未取込（次の作業）

Android adaptive icon 用の次の3点は、素材の取得経路の都合で今回の PR には含めていません。
生成AI版（`store/icon/`）と同じ命名で、追って追加します。

- `store/icon/hazmat4_fg.png` … adaptive の前景
- `store/icon/hazmat4_bg.png` … adaptive の背景
- `store/icon/hazmat4_small_1024.png` … 最小サイズ用

## ランチャーアイコンの作り方

Android / iOS / Web のランチャーアイコンは、プラットフォームを生成するビルド側で、
上記の素材から作成する必要があります（`flutter create` 後に差し替え、または `flutter_launcher_icons` 等）。

## 注意

- 素材は AI 生成画像（Leonardo.Ai）を含みます。公開前に、最新の利用規約・商用利用の可否を確認し、
  ストアの「AI 生成コンテンツ」の申告も確認してください。
- 乙4の新案（携行缶案）は未採用です。採用判断待ちのため、ここには含めていません。
- 画像のメタデータ（EXIF／テキストチャンク／ICC）は含めていません。
