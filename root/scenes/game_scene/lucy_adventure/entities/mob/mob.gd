## 敵キャラクター（モブ）の移動・衝突・死亡処理を管理する
## 地面を左右に歩き、プレイヤーに接触するとダメージを与える
class_name Mob extends CharacterBody2D

# ---- 変数 ----
## 移動方向（-1: 左、1: 右）
var direction_x := -1
## 歩行速度（ピクセル/秒）
var walk_speed := 32.0
## 死亡済みフラグ
var is_dead := false

# ---- ノード参照 ----
## モブのアニメーションスプライト
@onready var sprite: AnimatedSprite2D = %Sprite
## 地面検知用レイキャスト
@onready var ground_cast: RayCast2D = %GroundCast
## プレイヤーへのダメージ判定エリア
@onready var hit_box: Area2D = %HitBox


## 初期化処理（ヒットボックスにプレイヤー接触時の死亡処理を接続する）
func _ready() -> void:
	# プレイヤーがヒットボックスに触れたら死亡させる
	hit_box.body_entered.connect(func (entered_body: Node2D) -> void:
		if entered_body is not Player:
			return
		entered_body.die()
	)


## 物理フレーム毎の移動処理（地面歩行と崖・壁での反転）
func _physics_process(delta: float) -> void:
	if is_on_floor():
		# 崖端または壁に到達したら方向を反転する
		if not ground_cast.is_colliding() or is_on_wall():
			_flip_direction()
		velocity.x = direction_x * walk_speed
	else:
		# 空中では下に落下する
		velocity.y = 100.0
	move_and_slide()


## モブの死亡処理（爆発エフェクト生成後に自身を削除する）
func die() -> void:
	# 二重死亡を防止する
	if is_dead:
		return

	is_dead = true
	set_physics_process(false)
	sprite.play("hurt")
	collision_layer = 0
	collision_mask = 0
	hit_box.set_deferred("monitoring", false)

	# 爆発エフェクトを生成する
	var explosion: Node = load("uid://bfuki5y2411xs").instantiate()
	explosion.global_position = global_position
	get_parent().add_child(explosion)

	# 少し待ってから削除する
	await get_tree().create_timer(0.5).timeout
	queue_free()


## 移動方向を反転し、レイキャストとスプライトの向きも更新する
func _flip_direction() -> void:
	direction_x *= -1
	ground_cast.position.x = 8.0 * direction_x
	sprite.flip_h = not sprite.flip_h
