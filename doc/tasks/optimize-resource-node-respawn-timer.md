# ResourceNode のリスポーンタイマーを Timer ノードに変更

## 優先度: 中
## 区分: 最適化

## 概要

`resource_node.gd:24-33` で毎フレーム `_process(delta)` でリスポーンタイマーを手動処理している。枯渇していないときも `_process()` が呼ばれる（early return はあるが毎フレームのオーバーヘッド）。

## 対象ファイル

- `root/scenes/game_scene/achievement_master/world/resource_nodes/resource_node.gd`

## 修正方針

- `_process()` によるタイマー管理を `Timer` ノードに置き換える
- `harvest()` 時に `timer.start(respawn_time)` → `timeout` で `_respawn()` を呼ぶ
- 通常時は `set_process(false)` でフレーム処理を無効化する
- サブクラス（TreeNode, GoldStoneNode, SheepNode）への影響を確認する
