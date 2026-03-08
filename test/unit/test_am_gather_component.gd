## AmGatherComponent の採取開始・タイマー・完了・中断をテストする
extends GutTest

# ---- 定数 ----
const GatherComponentScript := preload(
	"res://root/scenes/game_scene/achievement_master/character/Player/am_gather_component.gd"
)
const MockResourceNodeScript := preload("res://test/helper/mock_resource_node.gd")

# ---- インスタンス ----
var _comp: AmGatherComponent
var _sprite: AnimatedSprite2D
var _progress_bar: ProgressBar


## テスト用の SpriteFrames を生成する（アニメーション名エラー回避）
func _make_sprite_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.add_animation(&"Attack")
	return frames


## テスト用のコンポーネントと依存ノードを生成する
func before_each() -> void:
	_comp = GatherComponentScript.new()
	add_child_autofree(_comp)
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = _make_sprite_frames()
	add_child_autofree(_sprite)
	_progress_bar = ProgressBar.new()
	_progress_bar.visible = false
	add_child_autofree(_progress_bar)
	_comp.initialize(_sprite, _progress_bar)


## 有効なリソースノードモックを生成する
func _make_resource_node(
	gather_data: Dictionary = {"gather_time": 1.0, "gather_animation": "Attack"},
	harvest_result: Dictionary = {},
) -> Node2D:
	var node: Node2D = MockResourceNodeScript.new()
	node.setup_gather(gather_data, harvest_result)
	add_child_autofree(node)
	return node


# ==================================================
# start_gather テスト
# ==================================================

func test_start_gather_rejects_node_without_method() -> void:
	var plain_node := Node2D.new()
	add_child_autofree(plain_node)

	var result: bool = _comp.start_gather(plain_node)

	assert_false(result, "get_gather_data がないノードは false を返す")


func test_start_gather_rejects_depleted_resource() -> void:
	var node := _make_resource_node({}, {})

	var result: bool = _comp.start_gather(node)

	assert_false(result, "空 Dictionary を返すノードは false を返す")


func test_start_gather_succeeds_with_valid_resource() -> void:
	var node := _make_resource_node()

	var result: bool = _comp.start_gather(node)

	assert_true(result, "有効なリソースノードで true を返す")
	assert_true(_progress_bar.visible, "プログレスバーが表示される")
	assert_eq(_progress_bar.value, 0.0, "プログレスバーの初期値が 0")


# ==================================================
# process_tick テスト
# ==================================================

func test_process_tick_advances_timer() -> void:
	var node := _make_resource_node({"gather_time": 2.0, "gather_animation": "Attack"})
	_comp.start_gather(node)

	_comp.process_tick(0.5)

	assert_almost_eq(_progress_bar.value, 0.5, 0.01, "プログレスバーが 0.5 秒分進む")


func test_process_tick_finishes_when_duration_elapsed() -> void:
	var harvest_result: Dictionary = {"type": 0, "amount": 5}
	var node := _make_resource_node({"gather_time": 1.0, "gather_animation": "Attack"}, harvest_result)
	_comp.start_gather(node)
	var finished_results: Array = []
	_comp.gather_finished.connect(func(r: Dictionary) -> void: finished_results.append(r))

	# 採取時間を超過させる
	_comp.process_tick(1.1)

	assert_eq(finished_results.size(), 1, "gather_finished シグナルが 1 回発火する")
	assert_false(_progress_bar.visible, "完了後プログレスバーが非表示になる")
	assert_true(node.harvest_called, "harvest が呼ばれる")


# ==================================================
# cancel テスト
# ==================================================

func test_cancel_emits_signal_and_resets() -> void:
	var node := _make_resource_node()
	_comp.start_gather(node)
	var cancelled: Array = []
	_comp.gather_cancelled.connect(func() -> void: cancelled.append(true))

	_comp.cancel()

	assert_eq(cancelled.size(), 1, "gather_cancelled シグナルが発火する")


func test_cancel_after_start_hides_progress_bar() -> void:
	var node := _make_resource_node()
	_comp.start_gather(node)
	assert_true(_progress_bar.visible, "開始直後はプログレスバーが表示される")

	_comp.cancel()

	assert_false(_progress_bar.visible, "中断後プログレスバーが非表示になる")
