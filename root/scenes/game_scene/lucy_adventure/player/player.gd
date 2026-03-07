## プレイヤーキャラクターの移動・ジャンプ・状態遷移・死亡/リスポーンを管理する
## 状態マシンパターンで各アクション状態を制御する
class_name Player extends CharacterBody2D

# ---- 定数 ----
## 爆発エフェクトのプリロード済みシーン
const EXPLOSION = preload("uid://bfuki5y2411xs")

## プレイヤーの状態一覧
enum States {
	SPAWN,       ## スポーン中
	GROUND,      ## 地上
	JUMP,        ## ジャンプ中
	FALL,        ## 落下中
	PUSH,        ## 押し中
	DIE,         ## 死亡中
	DOUBLE_JUMP  ## 二段ジャンプ中
}

## 最大ジャンプ回数
const MAX_JUMPS := 2

# ---- エクスポート変数 ----
## 水平加速度（ピクセル/秒^2）
@export var acceleration := 700.0
## 水平減速度（ピクセル/秒^2）
@export var deceleration := 1400.0
## 最大落下速度（ピクセル/秒）
@export var max_fall_speed := 320.0

## ジャンプ時の水平到達距離（ピクセル）
@export var jump_horizontal_distance := 80.0
## ジャンプの最大高さ（ピクセル）
@export var jump_height := 50.0
## ジャンプ上昇にかかる時間（秒）
@export var jump_time_to_peak := 0.37
## ジャンプ下降にかかる時間（秒）
@export var jump_time_to_descent := 0.25
## ジャンプカット時の速度除数
@export var jump_cut_divider := 15.0

## 二段ジャンプの最大高さ（ピクセル）
@export var double_jump_height := 30.0
## 二段ジャンプ上昇にかかる時間（秒）
@export var double_jump_time_to_peak := 0.3
## 二段ジャンプ下降にかかる時間（秒）
@export var double_jump_time_to_descent := 0.25

# ---- 変数 ----
## 現在の水平入力方向
var direction_x := 0.0
## 現在のプレイヤー状態
var current_state: States = States.SPAWN
## 現在適用中の重力値
var current_gravity := 0.0

# 状態固有の変数
## コヨーテタイムが有効かどうか
var coyote_time_active := false
## 現在のジャンプ回数
var jump_count := 0

# ---- ノード参照 ----
## プレイヤーのアニメーションスプライト
@onready var animated_sprite: AnimatedSprite2D = %AnimatedSprite2D
## プレイヤーのコリジョン形状
@onready var collision_shape_2d: CollisionShape2D = %CollisionShape2D
## 移動時の埃パーティクル
@onready var dust: GPUParticles2D = %Dust
## コヨーテタイム用タイマー
@onready var coyote_timer := Timer.new()

# ---- 算出パラメータ（通常ジャンプ） ----
## 最大水平速度
@onready var max_speed := calculate_max_speed(jump_horizontal_distance, jump_time_to_peak, jump_time_to_descent)
## ジャンプ初速度
@onready var jump_speed := calculate_jump_speed(jump_height, jump_time_to_peak)
## ジャンプ上昇時の重力
@onready var jump_gravity := calculate_jump_gravity(jump_height, jump_time_to_peak)
## 落下時の重力
@onready var fall_gravity := calculate_fall_gravity(jump_height, jump_time_to_descent)

# ---- 算出パラメータ（二段ジャンプ） ----
## 二段ジャンプ初速度
@onready var double_jump_speed := calculate_jump_speed(double_jump_height, double_jump_time_to_peak)
## 二段ジャンプ上昇時の重力
@onready var double_jump_gravity := calculate_jump_gravity(double_jump_height, double_jump_time_to_peak)
## 二段ジャンプ落下時の重力
@onready var double_jump_fall_gravity := calculate_fall_gravity(double_jump_height, double_jump_time_to_descent)

## リスポーン地点
@onready var respawn_position: Vector2 = global_position


## 初期化処理（初期状態の遷移とコヨーテタイマーの設定を行う）
func _ready() -> void:
	_transition_to_state(current_state)

	# コヨーテタイマーの設定
	coyote_timer.wait_time = 0.1
	coyote_timer.one_shot = true
	coyote_timer.timeout.connect(_on_coyote_timer_timeout)
	add_child(coyote_timer)


## 物理フレーム毎の処理（入力取得・状態別処理・重力適用・移動実行）
func _physics_process(delta: float) -> void:
	direction_x = signf(Input.get_axis("move_left", "move_right"))

	# 現在の状態に応じた処理を実行する
	match current_state:
		States.SPAWN:
			pass
		States.GROUND:
			process_ground_state(delta)
		States.JUMP:
			process_jump_state(delta)
		States.FALL:
			process_fall_state(delta)
		States.PUSH:
			process_push_state(delta)
		States.DOUBLE_JUMP:
			process_double_jump_state(delta)
		States.DIE:
			pass

	# 重力を適用し、最大落下速度で制限する
	velocity.y += current_gravity * delta
	velocity.y = minf(velocity.y, max_fall_speed)
	move_and_slide()

	# 死亡・スポーン以外の状態でモブとの接触を判定する
	if current_state not in [States.DIE, States.SPAWN]:
		_handle_mob_interactions()


## Calculates the maximum horizontal speed based on jump parameters
func calculate_max_speed(distance: float, time_to_peak: float, time_to_descent: float) -> float:
	return distance / (time_to_peak + time_to_descent)


## Calculates the initial jump velocity needed to reach a certain height
## Returns a negative value so you can directly apply it to velocity.y
func calculate_jump_speed(height: float, time_to_peak: float) -> float:
	return (-2.0 * height) / time_to_peak


## Calculates the gravity to apply while rising during a jump to reach the desired height
func calculate_jump_gravity(height: float, time_to_peak: float) -> float:
	return (2.0 * height) / pow(time_to_peak, 2.0)


## Calculates the gravity to apply while falling to get a consistent parabolic jump that matches the desired height
func calculate_fall_gravity(height: float, time_to_descent: float) -> float:
	return (2.0 * height) / pow(time_to_descent, 2.0)


## 地上状態の処理（移動・岩押し判定・ジャンプ入力・落下判定）
func process_ground_state(delta: float) -> void:
	var is_moving := absf(direction_x) > 0.0
	if is_moving:
		# 岩に接触していればプッシュ状態に遷移する
		if check_and_push_rock():
			_transition_to_state(States.PUSH)
			return

		velocity.x += acceleration * direction_x * delta
		velocity.x = clampf(velocity.x, -max_speed, max_speed)

		animated_sprite.flip_h = direction_x < 0.0
		animated_sprite.play("Run")
	else:
		# 入力がなければ減速する
		velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)
		animated_sprite.play("Idle")

	dust.emitting = absf(direction_x) > 0.0

	# ジャンプ入力があればジャンプ、床がなければ落下に遷移する
	if Input.is_action_just_pressed("jump"):
		_transition_to_state(States.JUMP)
	elif not is_on_floor():
		_transition_to_state(States.FALL)


## ジャンプ状態の処理（天井衝突・着地判定・二段ジャンプ・ジャンプカット）
func process_jump_state(delta: float) -> void:
	# 天井に当たったら上方向速度をゼロにする
	if is_on_ceiling():
		velocity.y = 0.0

	# 着地判定と落下遷移判定
	if is_on_floor():
		_transition_to_state(States.GROUND)
	elif velocity.y >= 0.0:
		_transition_to_state(States.FALL)

	# 二段ジャンプまたはジャンプカットの入力処理
	if Input.is_action_just_pressed("jump") and jump_count < MAX_JUMPS:
		_transition_to_state(States.DOUBLE_JUMP)
	elif Input.is_action_just_released("jump"):
		var jump_cut_speed := jump_speed / jump_cut_divider
		if velocity.y < 0.0 and velocity.y < jump_cut_speed:
			velocity.y = jump_cut_speed

	# 空中での水平移動制御
	if direction_x != 0.0:
		velocity.x += acceleration * direction_x * delta
		velocity.x = clampf(velocity.x, -max_speed, max_speed)
		animated_sprite.flip_h = direction_x < 0.0


## 落下状態の処理（着地判定・空中移動・コヨーテタイムジャンプ）
func process_fall_state(delta: float) -> void:
	# 着地したら地上状態に遷移する
	if is_on_floor():
		_transition_to_state(States.GROUND)
		return

	# 空中での水平移動制御
	if direction_x != 0.0:
		velocity.x += acceleration * direction_x * delta
		velocity.x = clampf(velocity.x, -max_speed, max_speed)
		animated_sprite.flip_h = direction_x < 0.0

	# コヨーテタイム中ならジャンプ、残りジャンプ回数があれば二段ジャンプ
	if Input.is_action_just_pressed("jump"):
		if coyote_time_active:
			_transition_to_state(States.JUMP)
		elif jump_count < MAX_JUMPS:
			_transition_to_state(States.DOUBLE_JUMP)


## 押し状態の処理（岩との接触判定・状態遷移）
func process_push_state(delta: float) -> void:
	var is_moving := absf(direction_x) > 0.0
	if is_moving:
		# 岩に接触し続けていればプッシュアニメーション、離れたら地上に遷移
		if check_and_push_rock():
			animated_sprite.play("Push")
		else:
			_transition_to_state(States.GROUND)
	else:
		_transition_to_state(States.GROUND)

	# 床がなければ落下、ジャンプ入力があればジャンプに遷移
	if not is_on_floor():
		_transition_to_state(States.FALL)
	elif Input.is_action_just_pressed("jump"):
		_transition_to_state(States.JUMP)


## 状態遷移を実行する（前の状態の終了処理と新しい状態の開始処理を行う）
func _transition_to_state(new_state: States) -> void:
	var previous_state := current_state
	current_state = new_state

	# 前の状態の終了処理
	match previous_state:
		States.FALL:
			coyote_time_active = false
			coyote_timer.stop()

	# 新しい状態の開始処理
	match current_state:
		States.SPAWN:
			animated_sprite.play("Idle")
			# 少し待ってから落下状態に遷移する
			get_tree().create_timer(0.1).timeout.connect(
				func () -> void:
					set_physics_process(true)
					_transition_to_state(States.FALL)
			)

		States.GROUND:
			current_gravity = fall_gravity
			# 落下から着地した場合のみ着地演出を再生しジャンプ回数をリセットする
			if previous_state == States.FALL:
				play_tween_touch_ground()
				jump_count = 0

		States.JUMP:
			velocity.y = jump_speed
			current_gravity = jump_gravity
			animated_sprite.play("Jump")
			jump_count = 1
			dust.emitting = true

		States.DOUBLE_JUMP:
			velocity.y = double_jump_speed
			current_gravity = double_jump_gravity
			animated_sprite.play("Jump")
			jump_count = MAX_JUMPS
			play_tween_jump()

		States.FALL:
			current_gravity = fall_gravity
			animated_sprite.play("Fall")

			# 地上から落下した場合はコヨーテタイムを有効にする
			if previous_state == States.GROUND:
				coyote_time_active = true
				coyote_timer.start()

		States.PUSH:
			current_gravity = fall_gravity

		States.DIE:
			velocity = Vector2.ZERO
			set_physics_process(false)
			animated_sprite.play("Die")
			dust.emitting = false
			# 爆発エフェクトを生成する
			var explosion: Node2D = EXPLOSION.instantiate()
			add_child(explosion)
			explosion.global_position = collision_shape_2d.global_position
			# 一定時間後にリスポーンする
			get_tree().create_timer(1.0).timeout.connect(respawn)


## コヨーテタイマー完了時にコヨーテタイムを無効化する
func _on_coyote_timer_timeout() -> void:
	coyote_time_active = false


## 着地時のスカッシュ＆ストレッチアニメーションを再生する
func play_tween_touch_ground() -> void:
	var tween := create_tween()
	tween.tween_property(animated_sprite, "scale", Vector2(1.1, 0.9), 0.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(animated_sprite, "scale", Vector2(0.9, 1.1), 0.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(animated_sprite, "scale", Vector2.ONE, 0.15)


## ジャンプ時のスカッシュ＆ストレッチアニメーションを再生する
func play_tween_jump() -> void:
	var tween := create_tween()
	tween.tween_property(animated_sprite, "scale", Vector2(1.2, 0.8), 0.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(animated_sprite, "scale", Vector2(0.8, 1.2), 0.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(animated_sprite, "scale", Vector2.ONE, 0.15)


## 岩との衝突を判定し、接触していれば押す力を適用する
func check_and_push_rock() -> bool:
	for i in get_slide_collision_count():
		var collision_data := get_slide_collision(i)
		var collider := collision_data.get_collider() as Rock
		if collider == null:
			continue
		var normal := collision_data.get_normal()
		# 水平方向の衝突のみ対象とする
		if normal.abs() != Vector2(1.0, 0.0):
			continue
		var push_force: float = -1.0 * collision_data.get_normal().x * 40.0
		collider.velocity.x = push_force
		velocity.x = push_force
		return true
	return false


## 二段ジャンプ状態の処理（空中移動と落下遷移判定）
func process_double_jump_state(delta: float) -> void:
	# 空中での水平移動制御
	if direction_x != 0.0:
		velocity.x += acceleration * direction_x * delta
		velocity.x = clampf(velocity.x, -max_speed, max_speed)
		animated_sprite.flip_h = direction_x < 0.0

	# 上昇速度がゼロ以上になったら落下状態に遷移する
	if velocity.y >= 0.0:
		_transition_to_state(States.FALL)


## Handles all interactions with mobs, both stomping and getting hit
func _handle_mob_interactions() -> void:
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var mob := collision.get_collider() as Mob
		if mob == null or mob.is_dead:
			continue

		var normal := collision.get_normal()
		var is_above_mob := signf(normal.y) == -1.0
		if is_above_mob:
			mob.die()
			_transition_to_state(States.JUMP)
		else:
			die()


## プレイヤーの死亡処理を実行する（スポーン・死亡中は無視する）
func die() -> void:
	if current_state not in [States.SPAWN, States.DIE]:
		_transition_to_state(States.DIE)


## リスポーン地点に戻り、状態をリセットしてスポーン状態に遷移する
func respawn() -> void:
	global_position = respawn_position
	jump_count = 0
	coyote_time_active = false
	_transition_to_state(States.SPAWN)


## プレイヤーを無効化する（ゴール到達時などに呼ばれる）
func deactivate() -> void:
	animated_sprite.play("Idle")
	set_physics_process(false)
