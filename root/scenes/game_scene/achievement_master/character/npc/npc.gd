## 村に配置する会話可能なNPC
## Eキーで話しかけるとセリフを順番に表示する
class_name Npc extends CharacterBody2D

# ---- エクスポート変数 ----
## NPC の表示名（NameLabel に反映）
@export var npc_name: String
## セリフリスト（interact ごとに順番に表示）
@export var dialogues: Array[String]
## セリフの表示秒数
@export var display_duration: float = 3.0
## アニメーション用 SpriteFrames リソース（Inspector から設定）
@export var sprite_frames: SpriteFrames

# ---- 内部状態 ----
## 次に表示するセリフのインデックス
var _dialogue_index: int = 0
## 会話中フラグ（連打防止用）
var _is_talking: bool = false

# ---- ノードキャッシュ ----
## アニメーションスプライト
@onready var _animated_sprite: AnimatedSprite2D = %AnimatedSprite
## セリフ表示用ラベル（頭上に表示）
@onready var _dialogue_label: Label = %DialogueLabel
## NPC 名表示用ラベル（足元に表示）
@onready var _name_label: Label = %NameLabel

# ========== ライフサイクル ==========

## 初期化 — グループ登録、SpriteFrames 適用、ラベル設定
func _ready() -> void:
	add_to_group("npc")
	# エクスポートされた SpriteFrames を AnimatedSprite2D に適用
	if sprite_frames != null:
		_animated_sprite.sprite_frames = sprite_frames
		_animated_sprite.play("Idle")
	# セリフラベルは初期非表示
	_dialogue_label.visible = false
	# NPC 名を足元ラベルに反映
	_name_label.text = npc_name
	Log.info("Npc: %s 初期化完了" % npc_name)

# ========== インタラクション ==========

## プレイヤーから呼び出される会話メソッド
## セリフを順番に表示し、一定時間後に非表示にする
func interact() -> void:
	# 会話中は再インタラクトを無視（連打防止）
	if _is_talking:
		return
	# セリフが未設定の場合は何もしない
	if dialogues.is_empty():
		return
	_is_talking = true
	# 現在のインデックスのセリフを表示
	_dialogue_label.text = dialogues[_dialogue_index]
	_dialogue_label.visible = true
	# 次回は次のセリフを表示（末尾に達したら先頭に戻る）
	_dialogue_index = (_dialogue_index + 1) % dialogues.size()
	Log.debug("Npc: %s がセリフを表示 (index=%d)" % [npc_name, _dialogue_index])
	# 一定時間後にセリフを非表示にする
	var timer: SceneTreeTimer = get_tree().create_timer(display_duration)
	timer.timeout.connect(_hide_dialogue)


## セリフラベルを非表示にして会話中フラグを解除する
func _hide_dialogue() -> void:
	_dialogue_label.visible = false
	_is_talking = false
