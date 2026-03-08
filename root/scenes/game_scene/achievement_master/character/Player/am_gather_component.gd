## 採取の開始・タイマー管理・完了・中断を担当するコンポーネント
class_name AmGatherComponent extends Node

# ---- シグナル ----
## 採取が完了したときに発火する（harvest 結果を含む）
signal gather_finished(result: Dictionary)
## 採取が中断されたときに発火する
signal gather_cancelled

# ---- 状態 ----
## 採取中の対象ノード
var _gather_target: Node2D = null
## 採取経過時間
var _gather_timer: float = 0.0
## 採取に必要な時間
var _gather_duration: float = 0.0

# ---- ノード参照（initialize で注入） ----
## アニメーションスプライト
var _animated_sprite: AnimatedSprite2D
## 採取プログレスバー
var _progress_bar: ProgressBar


## コンポーネントを初期化する — Player の _ready() から呼ばれる
func initialize(sprite: AnimatedSprite2D, progress_bar: ProgressBar) -> void:
	_animated_sprite = sprite
	_progress_bar = progress_bar


## 採取を開始する — 対象ノードを検証し、タイマー・アニメーション・プログレスバーをセットアップする
## 成功時は true を返す（Player が State.GATHER に遷移する）
func start_gather(node: Node2D) -> bool:
	if not node.has_method("get_gather_data"):
		return false
	var data: Dictionary = node.get_gather_data()
	# 枯渇チェック
	if data.is_empty():
		return false
	_gather_target = node
	_gather_duration = data.get("gather_time", 1.0) / AmPlayerStatCalculator.get_effective_gather_speed(
		InventoryManager.get_equip_cache(), SkillManager.get_effect_cache()
	)
	_gather_timer = 0.0
	_animated_sprite.play(data.get("gather_animation", "Attack1"))
	# プログレスバーを表示する
	_progress_bar.max_value = _gather_duration
	_progress_bar.value = 0.0
	_progress_bar.visible = true
	Log.info("Gather: 採取開始 → %s (%.1f秒)" % [node.name, _gather_duration])
	return true


## 採取タイマーを進め、完了/中断を判定する — Player が GATHER 状態のときに毎フレーム呼ぶ
func process_tick(delta: float) -> void:
	# 移動入力があれば採取を中断する
	var dir: Vector2 = Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)
	if dir != Vector2.ZERO:
		cancel()
		return
	_gather_timer += delta
	_progress_bar.value = _gather_timer
	if _gather_timer >= _gather_duration:
		_finish()


## 採取を中断する — 外部（被ダメージ等）から呼ばれる
func cancel() -> void:
	Log.debug("Gather: 採取中断")
	_gather_target = null
	_gather_timer = 0.0
	_progress_bar.visible = false
	gather_cancelled.emit()


## 採取完了 — harvest を呼び出し結果をシグナルで返す
func _finish() -> void:
	var result: Dictionary = {}
	if _gather_target != null and is_instance_valid(_gather_target) and _gather_target.has_method("harvest"):
		result = _gather_target.harvest()
	_gather_target = null
	_progress_bar.visible = false
	gather_finished.emit(result)
