## 一般エネミーの基底スクリプト
## アニメーション管理を一元化し、リーフはBlackboard経由で希望アニメーションを指定する
class_name Enemy extends CharacterBody2D

## flip_hを切り替える最小X速度閾値（ちらつき防止）
@export var flip_threshold: float = 10.0

## 最大HP
const MAX_HP: int = 30
## プレイヤーに与える攻撃ダメージ
const ATTACK_DAMAGE: int = 10
## 現在HP
var hp: int = MAX_HP

@onready var _blackboard: Blackboard = %Blackboard
@onready var _animated_sprite: AnimatedSprite2D = %AnimatedSprite

## 現在再生中のアニメーション名（重複play防止用）
var _current_anim: String = ""

func _ready() -> void:
	add_to_group("enemies")
	# blackboardに初期地点を待機地点として登録
	_blackboard.set_value(BlackBordValue.IDLE_POSITION, global_position)
	# 攻撃ダメージ量をblackboardに登録（リーフから参照するため）
	_blackboard.set_value(BlackBordValue.ATTACK_DAMAGE, ATTACK_DAMAGE)
	# 攻撃アニメーション完了シグナルを接続
	_animated_sprite.animation_finished.connect(_on_animation_finished)

func _physics_process(_delta: float) -> void:
	# --- アニメーション管理（一元化） ---
	# リーフがBlackboardに書いた希望アニメーションを読み取り、重複再生を防止しつつ更新
	var desired_anim: String = _blackboard.get_value(
		BlackBordValue.DESIRED_ANIM_STATE, "Idle"
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

## 攻撃アニメーション完了時のコールバック
func _on_animation_finished() -> void:
	if _animated_sprite.animation == &"Attack":
		_blackboard.set_value(BlackBordValue.ATTACK_ANIM_FINISHED, true)

## Pawnの攻撃ヒットボックスから呼ばれる — ダメージを受ける
func take_damage(amount: int) -> void:
	hp -= amount
	Log.info("Enemy: ダメージ %d を受けた (残HP: %d)" % [amount, hp])
	if hp <= 0:
		_die()


## 死亡処理
func _die() -> void:
	Log.info("Enemy: 死亡 [%s]" % name)
	queue_free()


func _on_detect_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_blackboard.set_value(BlackBordValue.IS_PLAYER_VISIBLE, true)

func _on_detect_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_blackboard.set_value(BlackBordValue.IS_PLAYER_VISIBLE, false)
