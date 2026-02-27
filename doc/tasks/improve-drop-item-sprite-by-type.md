# DropItem のスプライトをリソース種別に応じて切り替え

## 優先度: 低
## 区分: リファクタ

## 概要

`drop_item.gd` は `resource_type` を export しているが、スプライトは常に `Gold_Resource.png` 固定。将来 Wood や Meat のドロップを追加した際にスプライトが変わらない。

## 対象ファイル

- `root/scenes/game_scene/achievement_master/world/drop_item/drop_item.gd`
- `root/scenes/game_scene/achievement_master/world/drop_item/drop_item.tscn`

## 修正方針

- `resource_type` に応じてテクスチャを切り替える Dictionary マッピングを追加する
- `_ready()` または `resource_type` のセッターでスプライトを更新する
- 各リソース種別のドロップ用画像を用意する（Wood, Meat 用）
