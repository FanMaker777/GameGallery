## Sheep を一定周期でランダムな位置にスポーンさせるスポナー
## export 変数でスポーン周期と最大数を制御する
class_name SheepSpawner extends Node2D


## Sheep シーンを事前読み込み
const _SHEEP_SCENE: PackedScene = preload("uid://4rnts66f2wbv")

## スポーン周期（秒）
@export var spawn_interval: float = 20.0
## シーン内に存在できる Sheep の最大数
@export var max_sheep_count: int = 3
## スポーン領域（Spawner のローカル座標基準の矩形）
@export var spawn_area: Rect2 = Rect2(-200, -200, 400, 400)

## スポーンタイマー
var _timer: Timer = null

## タイマーを生成してスポーン周期を開始する
func _ready() -> void:
	_timer = Timer.new()
	_timer.wait_time = spawn_interval
	_timer.one_shot = false
	_timer.autostart = true
	# タイムアウト時にスポーン処理を呼ぶ
	_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(_timer)
	Log.info("SheepSpawner: 初期化完了 (周期=%.1fs, 最大数=%d)" % [spawn_interval, max_sheep_count])


## タイマー発火時に Sheep のスポーンを試みる
func _on_spawn_timer_timeout() -> void:
	# 現在のシーン内の Sheep 数をカウント
	var current_count: int = _count_sheep()
	# 最大数に達していたらスポーンしない
	if current_count >= max_sheep_count:
		return
	# Sheep をインスタンス化してランダム位置に配置
	_spawn_sheep()


## シーン内の SheepNode 数を返す
func _count_sheep() -> int:
	var count: int = 0
	for node: Node in get_tree().get_nodes_in_group("resource_node"):
		if node is SheepNode:
			count += 1
	return count


## Sheep を spawn_area 内のランダム位置に生成する
func _spawn_sheep() -> void:
	var sheep: SheepNode = _SHEEP_SCENE.instantiate() as SheepNode
	# スポーン領域内のランダム座標を計算（Spawner のグローバル座標基準）
	var random_x: float = randf_range(spawn_area.position.x, spawn_area.end.x)
	var random_y: float = randf_range(spawn_area.position.y, spawn_area.end.y)
	sheep.position = global_position + Vector2(random_x, random_y)
	add_child(sheep)
	Log.info("SheepSpawner: Sheep をスポーン (位置=%.0f, %.0f)" % [sheep.position.x, sheep.position.y])
