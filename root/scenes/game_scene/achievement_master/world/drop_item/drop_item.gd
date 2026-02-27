## 敵がドロップするアイテム
## Pawn が接近すると自動回収され、インベントリに加算される
class_name DropItem extends Node2D


# ---- エクスポート ----
## ドロップするリソースの種別（Inspector で設定）
@export var resource_type: ResourceDefinitions.ResourceType
## ドロップ量（Inspector で設定）
@export var amount: int = 5

# ---- 内部状態 ----
## 二重回収防止フラグ（一度回収処理に入ったら true にする）
var _picked_up: bool = false

# ---- ノードキャッシュ ----
## ドロップアイテムのスプライト
@onready var _sprite: Sprite2D = $Sprite2D
## Pawn 検知用エリア
@onready var _pickup_area: Area2D = $PickupArea


# ========== ライフサイクル ==========

## 初期化 — シグナル接続とスポーン演出を開始する
func _ready() -> void:
	# PickupArea に Pawn が入ったら回収処理を呼ぶ
	_pickup_area.body_entered.connect(_on_pickup_area_body_entered)
	# スポーン時のバウンド演出を再生する
	_play_spawn_bounce()


# ========== スポーン演出 ==========

## スポーン時のバウンド演出 — 上に40px跳ねて元の位置に戻る（計0.4秒）
func _play_spawn_bounce() -> void:
	var original_y: float = position.y
	var tween: Tween = create_tween()
	# フェーズ1: 上方向に跳ねる（0.2秒）
	tween.tween_property(self, "position:y", original_y - 40.0, 0.2) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	# フェーズ2: 元の位置に落下する（0.2秒）
	tween.tween_property(self, "position:y", original_y, 0.2) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)


# ========== 回収処理 ==========

## Pawn が PickupArea に入ったときのコールバック
func _on_pickup_area_body_entered(body: Node2D) -> void:
	# 二重回収を防止する
	if _picked_up:
		return
	# Pawn グループに属していない場合は無視する
	if not body.is_in_group("player"):
		return
	# collect_drop メソッドを持っていない場合は無視する
	if not body.has_method("collect_drop"):
		return
	# 回収フラグを立てて Pawn のインベントリに加算する
	_picked_up = true
	body.collect_drop(resource_type, amount)
	# 回収演出を再生する
	_play_collect_effect(body)


## 回収演出 — Pawn に向かって吸い込まれ + フェードアウトし、完了後に削除する
func _play_collect_effect(target: Node2D) -> void:
	var tween: Tween = create_tween()
	# 3つの演出を同時に再生する
	tween.set_parallel(true)
	# Pawn の位置に向かって移動する（0.25秒）
	tween.tween_property(self, "global_position", target.global_position, 0.25) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	# 透明度を 0 にフェードアウトする（0.25秒）
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	# スケールを縮小する（0.25秒）
	tween.tween_property(self, "scale", Vector2(0.3, 0.3), 0.25)
	# 演出完了後にノードを削除する
	tween.chain().tween_callback(queue_free)
