class_name Player extends CharacterBody2D

@export_category("MoveStatus")
@export var acceleration := 700.0
@export var deceleration := 1400.0
@export var max_fall_speed := 320.0

@export_category("JumpStatus")
@export var jump_horizontal_distance := 80.0
@export var jump_height := 50.0
@export var jump_time_to_peak := 0.37
@export var jump_time_to_descent := 0.25
@export var jump_cut_divider := 15.0

@export_category("DoubleJumpStatus")
@export var double_jump_height := 30.0
@export var double_jump_time_to_peak := 0.3
@export var double_jump_time_to_descent := 0.25

## ジャンプ回数
var jump_count := 0
## 最大ジャンプ回数
const MAX_JUMP_COUNT := 2

@onready var _animated_sprite_2d: AnimatedSprite2D = %AnimatedSprite2D
@onready var _state_chart: StateChart = %StateChart

@onready var max_speed := calculate_max_speed(jump_horizontal_distance, jump_time_to_peak, jump_time_to_descent)
@onready var jump_speed := calculate_jump_speed(jump_height, jump_time_to_peak)
@onready var jump_gravity := calculate_jump_gravity(jump_height, jump_time_to_peak)
@onready var fall_gravity := calculate_fall_gravity(jump_height, jump_time_to_descent)

# Double jump calculations
@onready var double_jump_speed := calculate_jump_speed(double_jump_height, double_jump_time_to_peak)
@onready var double_jump_gravity := calculate_jump_gravity(double_jump_height, double_jump_time_to_peak)
@onready var double_jump_fall_gravity := calculate_fall_gravity(double_jump_height, double_jump_time_to_descent)

## State「Idle」の時、物理フレーム毎に実行するメソッド
func _on_idle_state_physics_processing(delta: float) -> void:
	if not is_on_floor():
		# State「Fall」に遷移
		_state_chart.send_event("ToFall")
		return
	
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		# State「Jump」に遷移
		_state_chart.send_event("ToJump")
		return
	
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		# State「Run」に遷移
		_state_chart.send_event("ToRun")

## State「Run」の時、物理フレーム毎に実行するメソッド
func _on_run_state_physics_processing(delta: float) -> void:
	if not is_on_floor():
		# State「Fall」に遷移
		_state_chart.send_event("ToFall")
		return
	
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		# State「Jump」に遷移
		_state_chart.send_event("ToJump")
		return
	
	# プレイヤーの左右移動入力を正規化して取得
	var direction_x = signf(Input.get_axis("ui_left", "ui_right"))
	# プレイヤーの左右移動入力がある場合
	if direction_x:
		# 水平移動方向に加速
		velocity.x += acceleration * direction_x * delta
		# 水平移動速度を最高速度以内に制限
		velocity.x = clampf(velocity.x, -max_speed, max_speed)
		# spriteの向きを移動方向に合わせる
		_animated_sprite_2d.flip_h = velocity.x < 0
	else:
		# 停止に向けて減速
		velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)
	
	# 水平移動速度が0=停止状態の場合
	if velocity.x == 0:
		# State「Idle」に遷移
		_state_chart.send_event("ToIdle")

	move_and_slide()

## State「Fall」の時、物理フレーム毎に実行するメソッド
func _on_fall_state_physics_processing(delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		# ジャンプ回数が最大ジャンプ未満の場合
		if jump_count < MAX_JUMP_COUNT:
			# State「DoubleJump」に遷移
			_state_chart.send_event("ToDoubleJump")
			return

	if is_on_floor():
		# State「Idle」に遷移
		_state_chart.send_event("ToIdle")
		return
	
	# プレイヤーの左右移動入力を正規化して取得
	var direction_x = signf(Input.get_axis("ui_left", "ui_right"))
	# プレイヤーの左右移動入力がある場合
	if direction_x:
		# 水平移動方向に加速
		velocity.x += acceleration * direction_x * delta
		# 水平移動速度を最高速度以内に制限
		velocity.x = clampf(velocity.x, -max_speed, max_speed)
		# spriteの向きを移動方向に合わせる
		_animated_sprite_2d.flip_h = velocity.x < 0
	else:
		# 停止に向けて減速
		velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)
	
	# fall中の重力を適用
	velocity.y += fall_gravity * delta
	# 落下速度が最大速度を超えないように制限
	velocity.y = minf(velocity.y, max_fall_speed)
	
	move_and_slide()

## State「Jump」の時、物理フレーム毎に実行するメソッド
func _on_jump_state_physics_processing(delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		# ジャンプ回数が最大ジャンプ未満の場合
		if jump_count < MAX_JUMP_COUNT:
			# State「DoubleJump」に遷移
			_state_chart.send_event("ToDoubleJump")
			return
	
	# プレイヤーの左右移動入力を正規化して取得
	var direction_x = signf(Input.get_axis("ui_left", "ui_right"))
	# プレイヤーの左右移動入力がある場合
	if direction_x:
		# 水平移動方向に加速
		velocity.x += acceleration * direction_x * delta
		# 水平移動速度を最高速度以内に制限
		velocity.x = clampf(velocity.x, -max_speed, max_speed)
		# spriteの向きを移動方向に合わせる
		_animated_sprite_2d.flip_h = velocity.x < 0
	else:
		# 停止に向けて減速
		velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)
		
	# jump中の重力を適用
	velocity.y += jump_gravity * delta
	
	if velocity.y > 0:
		# State「Fall」に遷移
		_state_chart.send_event("ToFall")
	
	move_and_slide()

## State「DoubleJump」の時、物理フレーム毎に実行するメソッド
func _on_double_jump_state_physics_processing(delta: float) -> void:
	# プレイヤーの左右移動入力を正規化して取得
	var direction_x = signf(Input.get_axis("ui_left", "ui_right"))
	# プレイヤーの左右移動入力がある場合
	if direction_x:
		# 水平移動方向に加速
		velocity.x += acceleration * direction_x * delta
		# 水平移動速度を最高速度以内に制限
		velocity.x = clampf(velocity.x, -max_speed, max_speed)
		# spriteの向きを移動方向に合わせる
		_animated_sprite_2d.flip_h = velocity.x < 0
	else:
		# 停止に向けて減速
		velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)
	
	# DoubleJump中の重力を適用
	velocity.y += double_jump_gravity * delta
	
	if velocity.y > 0:
		# State「Fall」に遷移
		_state_chart.send_event("ToFall")
	
	move_and_slide()

# 各Stateに遷移時に実行するメソッド
func _on_idle_state_entered() -> void:
	_animated_sprite_2d.play("Idle")
	# ジャンプ回数をリセット
	jump_count = 0

func _on_run_state_entered() -> void:
	_animated_sprite_2d.play("Run")

func _on_jump_state_entered() -> void:
	_animated_sprite_2d.play("Jump")
	# 垂直移動速度にJump速度を設定
	velocity.y = jump_speed
	# ジャンプ回数を加算
	jump_count += 1

func _on_fall_state_entered() -> void:
	_animated_sprite_2d.play("Fall")

func _on_double_jump_state_entered() -> void:
	_animated_sprite_2d.play("DoubleJump")
	# 垂直移動速度にDoubleJump速度を設定
	velocity.y = double_jump_speed
	# ジャンプ回数を加算
	jump_count += 1

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
