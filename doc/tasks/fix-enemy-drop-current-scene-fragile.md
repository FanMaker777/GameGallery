# Enemy のドロップアイテム追加先を current_scene から改善

## 優先度: 中
## 区分: 設計改善

## 概要

`enemy.gd:130` で `get_tree().current_scene.add_child(drop)` としている。シーン遷移中に `current_scene` が変わる可能性があり脆弱。

## 対象ファイル

- `root/scenes/game_scene/achievement_master/enemys/enemy.gd:130`

## 修正方針

以下のいずれかで対応する:

1. **専用コンテナノード方式（推奨）**: マップシーンに `DropItemContainer`（Node2D）を配置し、そこに `add_child` する
2. **親ノード方式**: `get_parent().add_child(drop)` で自身の兄弟ノードとして追加する
3. **グループ検索方式**: `"drop_container"` グループのノードを検索して追加する

いずれの方式でも、ドロップが Enemy の子ノードにならない（`queue_free` で一緒に消えない）ことが重要。
