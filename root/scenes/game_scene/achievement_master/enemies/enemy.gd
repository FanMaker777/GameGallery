## 一般エネミーの基底スクリプト
## アニメーション管理を一元化し、リーフはBlackboard経由で希望アニメーションを指定する
class_name Enemy extends CharacterBody2D

# ---- シグナル ----
## 死亡時に発火する（AchievementManager 等の外部連携用）
signal died

# ---- エクスポート ----
## flip_hを切り替える最小X速度閾値（ちらつき防止）
@export var flip_threshold: float = 10.0
## 攻撃アニメーションのダメージ適用フレーム（0始まり、Inspectorで調整可能）
@export_range(1, 6, 1) var attack_hit_frame: int = 3
## ドロップアイテムのシーン（Inspector から drop_item.tscn を設定）
@export var drop_item_scene: PackedScene
## ドロップするリソースの種別
@export var drop_resource_type: ResourceDefinitions.ResourceType = ResourceDefinitions.ResourceType.GOLD
## ドロップするリソースの量
@export var drop_amount: int = 5

# ---- 定数 ----
## 最大HP
const MAX_HP: int = 30
## プレイヤーに与える攻撃ダメージ
const ATTACK_DAMAGE: int = 10

# ---- 内部状態 ----
## 現在HP
var hp: int = MAX_HP
## 死亡演出中フラグ（true の間はダメージ・AI・移動を停止する）
var _is_dying: bool = false

@onready var _blackboard: Blackboard = %Blackboard
@onready var _animated_sprite: AnimatedSprite2D = %AnimatedSprite

## 現在再生中のアニメーション名（重複play防止用）
var _current_anim: String = ""

func _ready() -> void:
	add_to_group("enemies")
	# blackboardに初期地点を待機地点として登録
	_blackboard.set_value(BlackBoardValue.IDLE_POSITION, global_position)
	# 攻撃ダメージ量をblackboardに登録（リーフから参照するため）
	_blackboard.set_value(BlackBoardValue.ATTACK_DAMAGE, ATTACK_DAMAGE)
	# 攻撃アニメーション完了シグナルを接続
	_animated_sprite.animation_finished.connect(_on_animation_finished)
	# ヒットフレーム検出用のフレーム変化シグナルを接続
	_animated_sprite.frame_changed.connect(_on_frame_changed)

func _physics_process(_delta: float) -> void:
	# 死亡演出中はアニメーション更新を停止する
	if _is_dying:
		return
	# --- アニメーション管理（一元化） ---
	# リーフがBlackboardに書いた希望アニメーションを読み取り、重複再生を防止しつつ更新
	var desired_anim: String = _blackboard.get_value(
		BlackBoardValue.DESIRED_ANIM_STATE, "Idle"
	)
	_update_animation(desired_anim)

	# --- flip_h管理（閾値付きでちらつき防止） ---
	if absf(velocity.x) > flip_threshold:
		_animated_sprite.flip_h = velocity.x < 0.0

## アニメーションを更新する（重複再生を防止）
func _update_animation(anim_name: String) -> void:
	if _current_anim != anim_name:
		_animated_sprite.play(anim_name)
		_current_anim = anim_name

## 攻撃アニメーションのヒットフレーム到達時にブラックボードを更新する
func _on_frame_changed() -> void:
	if _animated_sprite.animation == &"Attack" and _animated_sprite.frame == attack_hit_frame:
		_blackboard.set_value(BlackBoardValue.ATTACK_HIT_FRAME_REACHED, true)


## 攻撃アニメーション完了時のコールバック
func _on_animation_finished() -> void:
	if _animated_sprite.animation == &"Attack":
		_blackboard.set_value(BlackBoardValue.ATTACK_ANIM_FINISHED, true)

## Pawnの攻撃ヒットボックスから呼ばれる — ダメージを受ける
func take_damage(amount: int) -> void:
	# 死亡演出中はダメージを無視する
	if _is_dying:
		return
	hp -= amount
	Log.info("Enemy: ダメージ %d を受けた (残HP: %d)" % [amount, hp])
	if hp <= 0:
		_die()


## 死亡処理 — 演出・ドロップ生成後に queue_free で削除する
func _die() -> void:
	Log.info("Enemy: 死亡 [%s]" % name)
	# 死亡演出中フラグを立てる（ダメージ・AI・移動を停止）
	_is_dying = true
	# BeehaveTree の処理を停止する
	set_physics_process(false)
	set_process(false)
	# コリジョンを無効化して他オブジェクトとの衝突を防ぐ
	collision_layer = 0
	collision_mask = 0
	# DetectArea のモニタリングを停止する
	var detect_area: Area2D = %DetectArea
	detect_area.monitoring = false
	# 移動を停止する
	velocity = Vector2.ZERO
	# 死亡シグナルを発火する（AchievementManager 等の外部連携用）
	died.emit()
	# ドロップアイテムをワールドに生成する
	_spawn_drop_item()
	# 死亡演出を再生し、完了を待つ
	await _play_death_effect()
	# ノードを削除する（GenericSpawner の tree_exited が発火 → 再スポーン）
	queue_free()


## ドロップアイテムをワールドに生成する
func _spawn_drop_item() -> void:
	# シーンが未設定の場合はスキップする（安全ガード）
	if drop_item_scene == null:
		return
	# DropItem インスタンスを生成する
	var drop: Node2D = drop_item_scene.instantiate()
	# 自身の位置にドロップアイテムを配置する
	drop.global_position = global_position
	# リソース種別とドロップ量を設定する
	drop.resource_type = drop_resource_type
	drop.amount = drop_amount
	# 親ノードに追加する（自身の子にすると queue_free で消えるため）
	# physics コールバック中は即時追加できないため call_deferred を使用
	get_parent().call_deferred("add_child", drop)
	Log.info("Enemy: ドロップアイテム生成 (%s x%d)" % [ResourceDefinitions.ResourceType.keys()[drop_resource_type], drop_amount])


## 死亡演出 — 白フラッシュ3回 → フェードアウト + 縮小（合計約0.7秒）
func _play_death_effect() -> void:
	var tween: Tween = create_tween()
	# フェーズ1: 白フラッシュ3回（modulate を明るく→元に戻す × 3、計約0.3秒）
	for i: int in range(3):
		# 白く光らせる（0.05秒）
		tween.tween_property(_animated_sprite, "modulate", Color(3.0, 3.0, 3.0, 1.0), 0.05)
		# 元の色に戻す（0.05秒）
		tween.tween_property(_animated_sprite, "modulate", Color.WHITE, 0.05)
	# フェーズ2: フェードアウト + 縮小（0.4秒）
	tween.set_parallel(true)
	# 透明度を 0 にフェードアウトする
	tween.tween_property(_animated_sprite, "modulate:a", 0.0, 0.4) \
		.set_trans(Tween.TRANS_BACK)
	# スケールを縮小する
	tween.tween_property(self, "scale", Vector2(0.3, 0.3), 0.4) \
		.set_trans(Tween.TRANS_BACK)
	# Tween 完了を待つ
	await tween.finished


func _on_detect_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_blackboard.set_value(BlackBoardValue.IS_PLAYER_VISIBLE, true)

func _on_detect_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_blackboard.set_value(BlackBoardValue.IS_PLAYER_VISIBLE, false)
