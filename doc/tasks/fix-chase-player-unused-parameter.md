# ChasePlayer の after_run 未使用パラメータを修正

## 優先度: 低
## 区分: リファクタ

## 概要

`chase_player.gd:38` の `after_run(actor: Node, blackboard: Blackboard)` で `blackboard` パラメータが未使用。GDScript の規約では未使用パラメータにはアンダースコアプレフィックスを付ける。

## 対象ファイル

- `root/scripts/beehave/action_leaf/chase_player.gd:38`

## 修正方針

- `blackboard` → `_blackboard` にリネームする
