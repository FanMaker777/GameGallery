# enemys/ フォルダ名を enemies/ に修正

## 優先度: 中
## 区分: 命名修正

## 概要

フォルダ名が `enemys/` だが正しい英語複数形は `enemies/`。コード内のグループ名は `"enemies"` と正しいため、フォルダ名とグループ名が不一致。

## 対象

- `root/scenes/game_scene/achievement_master/enemys/` → `enemies/` にリネーム

## 修正方針

1. フォルダ名を `enemies/` にリネームする
2. `enemy.tscn` 内のスクリプトパス参照を更新する
3. 他シーン（village.tscn, grassland.tscn）からの ExtResource パスを確認・更新する
4. Godot の UID システムが自動解決するか確認する
