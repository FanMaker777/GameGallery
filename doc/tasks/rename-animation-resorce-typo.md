# animation_resorce/ フォルダ名のタイポを修正

## 優先度: 中
## 区分: 命名修正

## 概要

`character/npc/animation_resorce/` は "resource" のタイポ。正しくは `animation_resource/`。

## 対象

- `root/scenes/game_scene/achievement_master/character/npc/animation_resorce/` → `animation_resource/`

## 修正方針

1. フォルダ名を `animation_resource/` にリネームする
2. `npc.tscn` や村シーンでこのフォルダ内の `.tres` ファイルを参照している箇所を確認・更新する
3. Godot の UID システムが自動解決するか確認する
