# SheepNode の不要な super._process() 呼び出しを削除

## 優先度: 低
## 区分: リファクタ

## 概要

`sheep_node.gd:49` で `super._process(delta)` を呼んで基底クラスの リスポーンタイマーを回しているが、SheepNode は `harvest()` で `queue_free()` する。ノード自体が消滅するため、基底クラスのリスポーン処理には到達しない（再スポーンは GenericSpawner が担当）。

## 対象ファイル

- `root/scenes/game_scene/achievement_master/world/resource_nodes/sheep_node.gd:49`

## 修正方針

- `super._process(delta)` の呼び出しを削除する
- コメントで「リスポーンは GenericSpawner が担当」と明記する

## 備考

タスク「ResourceNode のリスポーンタイマーを Timer ノードに変更」と合わせて対応すると効率的。
