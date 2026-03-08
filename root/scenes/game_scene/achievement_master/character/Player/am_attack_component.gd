## 攻撃の開始・タイマー管理・ヒットボックス制御・命中判定を担当するコンポーネント
class_name AmAttackComponent extends Node

# ---- 定数 ----
## 攻撃アニメーションの持続時間（秒）
const ATTACK_DURATION: float = 0.4

# ---- シグナル ----
## 攻撃が終了したときに発火する
signal attack_finished
## 攻撃が敵に命中したときに発火する
signal attack_hit(target: Node2D, damage: int)

# ---- 状態 ----
## 攻撃経過時間
var _attack_timer: float = 0.0

# ---- ノード参照（initialize で注入） ----
## アニメーションスプライト
var _animated_sprite: AnimatedSprite2D
## 攻撃判定エリア
var _attack_hitbox: Area2D
## 攻撃判定のコリジョン形状
var _attack_hitbox_shape: CollisionShape2D


## コンポーネントを初期化する — Player の _ready() から呼ばれる
func initialize(
	sprite: AnimatedSprite2D,
	hitbox: Area2D,
	hitbox_shape: CollisionShape2D,
) -> void:
	_animated_sprite = sprite
	_attack_hitbox = hitbox
	_attack_hitbox_shape = hitbox_shape
	# ヒットボックスは通常時無効化する
	_attack_hitbox.monitoring = false
	_attack_hitbox_shape.disabled = true
	# ヒットボックスのシグナルを接続する
	_attack_hitbox.body_entered.connect(_on_hitbox_body_entered)


## 攻撃を開始する — アニメーション再生、ヒットボックスの位置設定と有効化
func start_attack() -> void:
	_attack_timer = 0.0
	_animated_sprite.play("Attack")
	# ヒットボックスの向きを flip_h に合わせる
	var dir_sign: float = -1.0 if _animated_sprite.flip_h else 1.0
	_attack_hitbox.position.x = absf(_attack_hitbox.position.x) * dir_sign
	# ヒットボックスを有効化する
	_attack_hitbox.monitoring = true
	_attack_hitbox_shape.disabled = false


## 攻撃タイマーを進め、持続時間を超えたら終了する — Player が ATTACK 状態のときに毎フレーム呼ぶ
func process_tick(delta: float) -> void:
	_attack_timer += delta
	if _attack_timer >= ATTACK_DURATION:
		_finish()


## 攻撃終了 — ヒットボックスを無効化してシグナルを発火する
func _finish() -> void:
	_attack_hitbox.monitoring = false
	_attack_hitbox_shape.disabled = true
	attack_finished.emit()


## ヒットボックスに敵が入ったときの処理 — ダメージ計算と適用
func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		var damage: int = AmPlayerStatCalculator.get_effective_attack(
			InventoryManager.get_equip_cache(), SkillManager.get_effect_cache()
		)
		body.take_damage(damage)
		attack_hit.emit(body, damage)
		Log.info("Attack: 敵にダメージ %d → %s" % [damage, body.name])
