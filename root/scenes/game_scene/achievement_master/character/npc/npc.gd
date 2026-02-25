@tool
## 村に配置する会話可能なNPC
## Eキーで話しかけるとセリフを順番に表示する
## @tool によりエディタ上で Inspector の変更が即座にビューポートへ反映される
class_name Npc extends CharacterBody2D

# ---- エクスポート変数 ----
# npc_name と sprite_frames にはセッターを付け、
# Inspector 変更時にエディタ上へリアルタイム反映する。
# dialogues / display_duration はビューポートに表示先がないためセッター不要。

## NPC の表示名（NameLabel に反映）。セッターで足元ラベルに即時反映される
@export var npc_name: String:
	set(value):
		npc_name = value
		_apply_npc_name()

## セリフリスト（interact ごとに順番に表示）。ビューポート反映先がないためセッター不要
@export var dialogues: Array[String]
## セリフの表示秒数。ビューポート反映先がないためセッター不要
@export var display_duration: float = 3.0

## アニメーション用 SpriteFrames リソース（Inspector から設定）
## セッターで AnimatedSprite2D に即時反映される（再生はランタイムのみ）
@export var sprite_frames: SpriteFrames:
	set(value):
		sprite_frames = value
		_apply_sprite_frames()

# ---- 内部状態 ----
## 次に表示するセリフのインデックス
var _dialogue_index: int = 0
## 会話中フラグ（連打防止用）
var _is_talking: bool = false

# ---- ノードキャッシュ ----
## アニメーションスプライト（%AnimatedSprite ユニーク名で参照）
@onready var _animated_sprite: AnimatedSprite2D = %AnimatedSprite
## セリフ表示用ラベル（頭上に表示、%DialogueLabel ユニーク名で参照）
@onready var _dialogue_label: Label = %DialogueLabel
## NPC 名表示用ラベル（足元に表示、%NameLabel ユニーク名で参照）
@onready var _name_label: Label = %NameLabel

# ========== ライフサイクル ==========

## 初期化 — エクスポート変数をノードに反映し、ランタイム専用の設定を行う
## セッターはノード準備前に呼ばれる場合があるため、
## _ready() で改めて _apply_*() を呼び確実に初期化する
func _ready() -> void:
	# エディタ・ランタイム共通: Inspector の値をノードに反映
	_apply_npc_name()
	_apply_sprite_frames()
	# エディタ内ではここで終了（以下のランタイム専用処理を実行しない）
	if Engine.is_editor_hint():
		return
	# ---- ランタイム専用 ----
	# NPC グループに登録（プレイヤーからの検索用）
	add_to_group("npc")
	# SpriteFrames が設定されていれば Idle アニメーションを再生開始
	if sprite_frames != null:
		_animated_sprite.play("Idle")
	# セリフラベルは初期非表示（interact 時に表示する）
	_dialogue_label.visible = false
	Log.info("Npc: %s 初期化完了" % npc_name)

# ========== エディタ反映 ==========

## npc_name を足元の NameLabel に反映する
func _apply_npc_name() -> void:
	# ノードツリー構築前（シーンロード中）は何もしない
	if not is_node_ready():
		return
	_name_label.text = npc_name


## sprite_frames を AnimatedSprite2D に反映する
## アニメーション再生（play）はランタイム専用のため、ここではリソース割り当てのみ行う
func _apply_sprite_frames() -> void:
	# ノードツリー構築前（シーンロード中）は何もしない
	if not is_node_ready():
		return
	if sprite_frames != null:
		_animated_sprite.sprite_frames = sprite_frames
	else:
		_animated_sprite.sprite_frames = null

# ========== インタラクション ==========

## プレイヤーから呼び出される会話メソッド
## セリフを順番に表示し、一定時間後に非表示にする
func interact() -> void:
	# エディタ内では実行しない（Log やタイマーがエディタで問題を起こす防止）
	if Engine.is_editor_hint():
		return
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
	# エディタ内では実行しない（ランタイム専用メソッド）
	if Engine.is_editor_hint():
		return
	_dialogue_label.visible = false
	_is_talking = false
