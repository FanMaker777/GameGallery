#@icon("res://icons/icon_mob.svg")
class_name Mob extends Area2D

## 最大体力
@export var max_health := 100
## 体力
@export var health := 100 :set = set_health
## 体力バー
@onready var _health_bar: ProgressBar = %HealthBar
## 移動速度(xピクセル/s)
@export var speed := 100.0
## コインのドロップ数
@export var drop_coins := 10

@onready var _bar_pivot: Node2D = %BarPivot

## 体力のセッターメソッド
func set_health(new_health: int) -> void:
	# 体力を適正範囲に調整
	health = clampi(new_health, 0, max_health)
	# 体力バーに新しい体力を設定
	if _health_bar != null:
		_health_bar.value = health
	# 体力が0の場合
	if health == 0:
		# 死亡メソッド
		_die(true)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# 体力バーの最大値を、最大体力に設定
	_health_bar.max_value = health
	set_health(health)

func _physics_process(_delta: float) -> void:
	_bar_pivot.global_rotation = 0.0

## 被ダメージ時のメソッド
func take_damage(amount: int) -> void:
	health -= amount
	# ダメージインジケーターをインスタンス化
	var damage_indicator: Node2D = preload("uid://bq0ta0wigo4jt").instantiate()
	# ダメージインジケーターをルートノードに追加
	get_tree().current_scene.add_child(damage_indicator)
	# ダメージインジケーターの位置をMobに同期
	damage_indicator.global_position = global_position
	# ダメージインジケーターを表示
	damage_indicator.display_amount(amount)

## 死亡時のメソッド
func _die(was_killed := false) -> void:
	# killされた場合
	if was_killed:
		# コインのドロップ数分ループ処理
		for current_index :int in drop_coins:
			# コインをインスタンス化
			var coin:Node2D = preload("uid://sy1ky7l7c3ij").instantiate()
			# コインをゲームのメインノードの子として追加
			# call_deferred：物理エンジンのエラーを避けるため、フレームの終わりまで呼び出しを遅延
			get_tree().current_scene.add_child.call_deferred(coin)
			# コインをモブの位置に配置
			coin.global_position = global_position
	queue_free()
