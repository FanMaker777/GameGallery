## ワニの情報キャラクター（NPC）の会話制御を担当する
## プレイヤーが近づくと会話可能になり、入力に応じてセリフを順番に表示する
extends Node2D

# ---- エクスポート変数 ----
## 表示するセリフの配列
@export var lines: PackedStringArray = []

# ---- ノード参照 ----
## ワニのスプライト
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
## 会話吹き出しUI
@onready var bubble: Node = $CanvasLayer/Bubble
## 吹き出しの追従ターゲット位置
@onready var bubble_target: Node2D = $BubbleTarget

# ---- 変数 ----
## 会話がアクティブかどうか
var _is_active := false : set = _set_active
## 現在表示中のセリフインデックス（-1 は未開始）
var _current_line := -1
## 近くにいるプレイヤーの参照
var player: Player = null


## 初期化処理（入力処理の有効/無効を設定する）
func _ready() -> void:
	set_process_unhandled_input(_is_active)


## アクティブ状態のセッター（入力処理の切り替えと吹き出しのリセットを行う）
func _set_active(value: bool) -> void:
	if _is_active == value:
		return
	_is_active = value
	set_process_unhandled_input(_is_active)
	# 非アクティブになった場合、開いている吹き出しを閉じる
	if _is_active == false && bubble.active:
		_reset_bubble()


## 未処理入力を受け取り、下キーでセリフを順次表示する
func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("move_down"):
		# スプライトのバウンスアニメーションを再生
		var tween := create_tween()
		tween.tween_property(sprite, "scale", Vector2(1.2, 0.8), 0.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tween.tween_property(sprite, "scale", Vector2(0.8, 1.2), 0.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tween.tween_property(sprite, "scale", Vector2.ONE, 0.15)

		# 最初のセリフの場合は吹き出しを開く
		if _current_line == -1:
			bubble.open(bubble_target)
		# 最後のセリフまで表示した場合は吹き出しをリセットする
		if _current_line >= lines.size() - 1:
			_reset_bubble()
			return
		_current_line += 1
		bubble.write(lines[_current_line])
		_look_at_target(player.global_position)


## スプライトをターゲット位置の方向に向ける
func _look_at_target(pos: Vector2) -> void:
	sprite.flip_h = (pos.x - self.global_position.x) < 0


## 吹き出しを閉じてセリフインデックスをリセットする
func _reset_bubble() -> void:
	_current_line = -1
	bubble.close()


## プレイヤーが検知エリアに入った時の処理
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player:
		player = body
		_set_active(true)


## プレイヤーが検知エリアから出た時の処理
func _on_area_2d_body_exited(body: Node2D) -> void:
	if body is Player:
		player = null
		_set_active(false)
