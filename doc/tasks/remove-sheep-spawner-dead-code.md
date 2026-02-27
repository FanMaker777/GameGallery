# 未使用の SheepSpawner を削除

## 優先度: 中
## 区分: デッドコード整理

## 概要

`sheep_spawner.gd` + `sheep_spawner.tscn` は GenericSpawner に完全置換済み。仕様書でも「旧 SheepSpawner を完全に置換」と明記。村シーンでは GenericSpawner を使用中（確認済み）。

## 対象ファイル

- `root/scenes/game_scene/achievement_master/world/resource_nodes/sheep_spawner.gd`
- `root/scenes/game_scene/achievement_master/world/resource_nodes/sheep_spawner.gd.uid`
- `root/scenes/game_scene/achievement_master/world/resource_nodes/sheep_spawner.tscn`

## 修正方針

- 上記 3 ファイルを削除する
- `class_name SheepSpawner` が他で参照されていないことを確認する
