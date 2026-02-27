# ResourceHud のシグナルハンドリングを最適化

## 優先度: 低
## 区分: リファクタ

## 概要

`resource_hud.gd:35-39` で `_on_inventory_changed(_type, _new_amount)` がシグナルの引数を無視し、毎回 `get_tree().get_first_node_in_group("player")` で Pawn を再検索して全ラベルを更新している。

## 対象ファイル

- `root/scenes/game_scene/achievement_master/ui/resource_hud.gd`

## 修正方針

- `_connect_to_pawn()` で取得した Pawn 参照をメンバ変数 `_pawn` に保持する
- `_on_inventory_changed()` ではシグナルの `type` と `new_amount` を使い、該当ラベルのみ更新する
- `is_instance_valid(_pawn)` で無効参照を防ぐ
