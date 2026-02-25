## 任意の PackedScene を一定周期でランダムな位置にスポーンさせる汎用スポナー
## Inspector から spawn_scene / spawn_interval / max_count / spawn_area を設定する
class_name GenericSpawner extends Node2D


## スポーン対象シーン（Inspector から任意の .tscn を指定）
@export var spawn_scene: PackedScene
## スポーン周期（秒）
@export var spawn_interval: float = 20.0
## シーン内に同時存在できる最大インスタンス数
@export var max_count: int = 3
## スポーン範囲（Spawner のローカル座標基準の矩形）
@export var spawn_area: Rect2 = Rect2(-200, -200, 400, 400)

## 現在スポーン済みのインスタンス数（tree_exited で自動減算）
var _alive_count: int = 0
## スポーンタイマー
var _timer: Timer = null


## タイマーを生成してスポーン周期を開始する
func _ready() -> void:
	# spawn_scene が未設定の場合は警告して停止
	if spawn_scene == null:
		Log.warn("GenericSpawner: spawn_scene が未設定です（ノード: %s）" % name)
		return

	_timer = Timer.new()
	_timer.wait_time = spawn_interval
	_timer.one_shot = false
	_timer.autostart = true
	# タイムアウト時にスポーン処理を呼ぶ
	_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(_timer)
	Log.debug("GenericSpawner: 初期化完了 (対象=%s, 周期=%.1fs, 最大数=%d)" % [
		spawn_scene.resource_path.get_file(), spawn_interval, max_count
	])


## タイマー発火時にスポーンを試みる
func _on_spawn_timer_timeout() -> void:
	# 最大数に達していたらスポーンしない
	if _alive_count >= max_count:
		return
	_spawn_instance()


## spawn_scene のインスタンスを spawn_area 内のランダム位置に生成する
func _spawn_instance() -> void:
	var instance: Node = spawn_scene.instantiate()
	# スポーン領域内のランダム座標を計算（Spawner のグローバル座標基準）
	var random_x: float = randf_range(spawn_area.position.x, spawn_area.end.x)
	var random_y: float = randf_range(spawn_area.position.y, spawn_area.end.y)

	# Node2D 系ならposition を設定、それ以外はそのまま追加
	if instance is Node2D:
		(instance as Node2D).position = Vector2(random_x, random_y)

	# インスタンスがシーンツリーから削除されたらカウントを減らす
	instance.tree_exited.connect(_on_instance_removed)
	add_child(instance)
	_alive_count += 1
	Log.debug("GenericSpawner: スポーン完了 (存在数=%d/%d)" % [_alive_count, max_count])


## スポーン済みインスタンスが削除された時にカウントを減算する
func _on_instance_removed() -> void:
	_alive_count -= 1
	Log.debug("GenericSpawner: インスタンス削除 (存在数=%d/%d)" % [_alive_count, max_count])
