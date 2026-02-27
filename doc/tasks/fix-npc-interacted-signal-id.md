# NPC の npc_interacted シグナルが npc_name を ID として使用している問題を修正

## 優先度: 高
## 区分: 不整合

## 概要

`npc.gd:105` で `npc_interacted.emit(npc_name)` としているが、シグナル定義のパラメータ名は `npc_id: String`。同名 NPC が存在した場合、AchievementManager のクールダウン制御（`_npc_talk_cooldowns`）が正しく機能しない。

## 対象ファイル

- `root/scenes/game_scene/achievement_master/character/npc/npc.gd:105`
- `root/scenes/game_scene/achievement_master/autoload/achievement_manager/achievement_manager.gd:238-246`

## 修正方針

- NPC に一意の `@export var npc_id: StringName` を追加する
- `npc_interacted.emit(npc_id)` に変更する
- 村シーンの各 NPC インスタンスで `npc_id` を設定する
