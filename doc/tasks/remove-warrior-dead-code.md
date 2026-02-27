# 未使用の warrior.gd を削除

## 優先度: 中
## 区分: デッドコード整理

## 概要

`character/Warrior/warrior.gd` は Pawn に完全置換済みで、どのシーンからも参照されていない。さらに `ui_left/ui_right` 等のデフォルトアクションを使用しており、プロジェクト規約（カスタムアクション優先）にも違反。

## 対象ファイル

- `root/scenes/game_scene/achievement_master/character/Warrior/warrior.gd`
- `root/scenes/game_scene/achievement_master/character/Warrior/warrior.gd.uid`

## 修正方針

- `warrior.gd` と `.uid` を削除する
- `warrior.tscn` からスクリプト参照を外す（tscn 自体はアセットとして残す可能性あり — 要確認）
- `class_name RpgPlayer` が他で参照されていないことを確認する
