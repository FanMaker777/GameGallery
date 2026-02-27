# Enemy のドロップリソース種別のハードコードを解消

## 優先度: 中
## 区分: 設計改善

## 概要

`enemy.gd:127` で `drop.resource_type = ResourceDefinitions.ResourceType.GOLD` がハードコードされている。`drop_gold_amount` は `@export` だがリソース種別は固定で、Gold 以外のドロップに対応できない。

## 対象ファイル

- `root/scenes/game_scene/achievement_master/enemys/enemy.gd:117-131`

## 修正方針

- `@export var drop_resource_type: ResourceDefinitions.ResourceType = ResourceDefinitions.ResourceType.GOLD` を追加する
- `drop_gold_amount` を `drop_amount` にリネームする
- `_spawn_drop_item()` で `drop_resource_type` と `drop_amount` を使用する
