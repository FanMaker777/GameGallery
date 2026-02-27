# BlackBordValue のタイポを BlackBoardValue に修正

## 優先度: 中
## 区分: 命名修正

## 概要

`beehave_blackbord_value.gd` の `class_name BlackBordValue` は "Board" のタイポ。7 ファイルで参照されている。

## 対象ファイル

- `root/scripts/const/beehave_blackbord_value.gd`（定義元 + ファイル名リネーム）
- `root/scenes/game_scene/achievement_master/enemys/enemy.gd`
- `root/scripts/beehave/action_leaf/attack_player.gd`
- `root/scripts/beehave/action_leaf/chase_player.gd`
- `root/scripts/beehave/action_leaf/move_to_patrol_point.gd`
- `root/scripts/beehave/action_leaf/wait_at_patrol_point.gd`
- `root/scripts/beehave/condition_leaf/is_player_visible.gd`

## 修正方針

1. `beehave_blackbord_value.gd` → `beehave_blackboard_value.gd` にリネーム
2. `class_name BlackBordValue` → `class_name BlackBoardValue` に変更
3. 全 7 ファイルで `BlackBordValue` → `BlackBoardValue` に一括置換
4. `.uid` ファイルやシーン参照の更新を確認する
