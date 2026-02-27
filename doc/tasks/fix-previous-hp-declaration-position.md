# AchievementManager の _previous_hp 変数宣言位置を修正

## 優先度: 低
## 区分: コード品質

## 概要

`achievement_manager.gd:283` で `var _previous_hp: int = -1` がメソッド定義の間に宣言されている。他の変数はすべてファイル先頭の「内部状態」セクションに集約されているため不整合。

## 対象ファイル

- `root/scenes/game_scene/achievement_master/autoload/achievement_manager/achievement_manager.gd:283`

## 修正方針

- `_previous_hp` の宣言をファイル先頭の `# ---- プレイヤー参照 ----` セクションに移動する
