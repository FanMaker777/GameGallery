# IsPlayerVisible の型注釈・コメント言語を統一

## 優先度: 低
## 区分: コード品質

## 概要

`is_player_visible.gd` が他スクリプトと比べてコード品質が低い。

- `var player = null` / `var is_player_visible = ...` — 型注釈なし
- `# Player is visible, save position in blackboard` — 英語コメントが混在（規約は日本語）

## 対象ファイル

- `root/scripts/beehave/condition_leaf/is_player_visible.gd`

## 修正方針

- 全変数に型注釈を追加する
- コメントを日本語に統一する
- クラスヘッダーコメント（`##`）を追加する
