## SaveManager の Saveable 登録・収集・配布・リセットをテストする
extends GutTest

# ---- ヘルパー定数 ----
const SaveManagerScript := preload(
	"res://root/scenes/game_scene/achievement_master/autoload/save_manager/save_manager.gd"
)
const MockSaveableScript := preload("res://test/helper/mock_saveable.gd")

# ---- インスタンス ----
var _mgr: Node


## テスト用 SaveManager を生成する（_ready の自動実行を回避するためツリー追加を遅延）
func _make_save_manager() -> Node:
	var mgr: Node = SaveManagerScript.new()
	# _saveables は宣言時に初期化済みなので _ready なしでも利用可能
	return mgr


## 単一キーの MockSaveable を生成する
func _make_single_key_saveable(key: StringName, data: Dictionary = {}) -> Node:
	var s: Node = MockSaveableScript.new()
	var keys: Array[StringName] = [key]
	s.setup_keys(keys)
	if not data.is_empty():
		s.data_store[key] = data
	add_child_autofree(s)
	return s


## 複数キーの MockSaveable を生成する（AchievementTracker 相当）
func _make_multi_key_saveable(
	keys: Array[StringName],
	data_map: Dictionary = {},
) -> Node:
	var s: Node = MockSaveableScript.new()
	s.setup_keys(keys)
	for k: StringName in data_map:
		s.data_store[k] = data_map[k]
	add_child_autofree(s)
	return s


## 必須メソッドの一部が欠けたノードを生成する
func _make_incomplete_node() -> Node:
	var n := Node.new()
	add_child_autofree(n)
	return n


# ---- セットアップ / ティアダウン ----

func before_each() -> void:
	_mgr = _make_save_manager()


func after_each() -> void:
	if _mgr != null:
		_mgr.free()
		_mgr = null


# ==================================================
# register_saveable テスト
# ==================================================

func test_register_saveable_adds_to_list() -> void:
	var s := _make_single_key_saveable(&"test")

	_mgr.register_saveable(s)

	assert_eq(_mgr._saveables.size(), 1, "Saveable が1件登録される")
	assert_eq(_mgr._saveables[0], s, "登録されたノードが一致する")


func test_register_saveable_rejects_incomplete_node() -> void:
	var n := _make_incomplete_node()

	_mgr.register_saveable(n)

	assert_eq(_mgr._saveables.size(), 0, "必須メソッド欠落ノードは登録されない")
	assert_engine_error("が未実装", "Log.warn が出力される")


func test_register_saveable_prevents_duplicate() -> void:
	var s := _make_single_key_saveable(&"test")

	_mgr.register_saveable(s)
	_mgr.register_saveable(s)

	assert_eq(_mgr._saveables.size(), 1, "二重登録は防止される")


# ==================================================
# 単一キー Saveable の collect/distribute テスト
# ==================================================

func test_single_key_collect() -> void:
	var s := _make_single_key_saveable(&"skill", {"unlocked_ids": ["s1"], "spent_ap": 5})
	_mgr.register_saveable(s)

	var collected: Dictionary = {}
	for saveable: Node in _mgr._saveables:
		for key: StringName in saveable.get_save_keys():
			collected[String(key)] = saveable.get_save_data_for_key(key)

	assert_true(collected.has("skill"), "skill キーが収集される")
	assert_eq(collected["skill"]["spent_ap"], 5, "データ内容が正しい")


func test_single_key_distribute() -> void:
	var s := _make_single_key_saveable(&"inventory")
	_mgr.register_saveable(s)
	var data: Dictionary = {"inventory": {"bag": {"sword": 1}}}

	# _distribute_save_data を直接呼ぶ
	_mgr._distribute_save_data(data)

	assert_true(s.data_store.has(&"inventory"), "inventory データが配布される")
	assert_eq(s.data_store[&"inventory"]["bag"]["sword"], 1, "データ内容が正しい")


# ==================================================
# 複数キー Saveable の collect/distribute テスト
# ==================================================

func test_multi_key_collect() -> void:
	var keys: Array[StringName] = [&"achievement", &"record"]
	var data_map: Dictionary = {
		&"achievement": {"unlocked": {"ach1": 100}, "total_ap": 10},
		&"record": {"counts": {"enemy_killed": 5}},
	}
	var s := _make_multi_key_saveable(keys, data_map)
	_mgr.register_saveable(s)

	var collected: Dictionary = {}
	for saveable: Node in _mgr._saveables:
		for key: StringName in saveable.get_save_keys():
			collected[String(key)] = saveable.get_save_data_for_key(key)

	assert_true(collected.has("achievement"), "achievement キーが収集される")
	assert_true(collected.has("record"), "record キーが収集される")
	assert_eq(collected["achievement"]["total_ap"], 10, "achievement データが正しい")
	assert_eq(collected["record"]["counts"]["enemy_killed"], 5, "record データが正しい")


func test_multi_key_distribute() -> void:
	var keys: Array[StringName] = [&"achievement", &"record"]
	var s := _make_multi_key_saveable(keys)
	_mgr.register_saveable(s)
	var data: Dictionary = {
		"achievement": {"unlocked": {"ach1": 100}},
		"record": {"counts": {"enemy_killed": 3}},
	}

	_mgr._distribute_save_data(data)

	assert_eq(s.data_store[&"achievement"]["unlocked"]["ach1"], 100, "achievement データが配布される")
	assert_eq(s.data_store[&"record"]["counts"]["enemy_killed"], 3, "record データが配布される")


# ==================================================
# reset_all_managers テスト
# ==================================================

func test_reset_all_managers_calls_reset_on_all() -> void:
	var s1 := _make_single_key_saveable(&"skill", {"unlocked_ids": ["s1"]})
	var s2 := _make_single_key_saveable(&"npc", {"gifts_claimed": ["npc1"]})
	_mgr.register_saveable(s1)
	_mgr.register_saveable(s2)

	_mgr.reset_all_managers()

	assert_eq(s1.reset_count, 1, "1つ目の Saveable の reset が呼ばれる")
	assert_eq(s2.reset_count, 1, "2つ目の Saveable の reset が呼ばれる")
	assert_true(s1.data_store.is_empty(), "リセット後データが空になる")
	assert_true(s2.data_store.is_empty(), "リセット後データが空になる")


# ==================================================
# "reward" → "skill" マイグレーション テスト
# ==================================================

func test_reward_to_skill_migration() -> void:
	var s := _make_single_key_saveable(&"skill")
	_mgr.register_saveable(s)
	# 旧フォーマット: "reward" キーを持ち "skill" キーがないデータ
	var old_data: Dictionary = {"reward": {"unlocked_ids": ["r1"], "spent_ap": 3}}

	_mgr._distribute_save_data(old_data)

	assert_true(s.data_store.has(&"skill"), "reward が skill にマイグレーションされて配布される")
	assert_eq(s.data_store[&"skill"]["spent_ap"], 3, "マイグレーション後のデータが正しい")


func test_skill_key_takes_precedence_over_reward() -> void:
	var s := _make_single_key_saveable(&"skill")
	_mgr.register_saveable(s)
	# 両方のキーがある場合は "skill" が優先される
	var data: Dictionary = {
		"skill": {"unlocked_ids": ["s1"], "spent_ap": 10},
		"reward": {"unlocked_ids": ["r1"], "spent_ap": 3},
	}

	_mgr._distribute_save_data(data)

	assert_eq(s.data_store[&"skill"]["spent_ap"], 10, "skill キーが優先される")


# ==================================================
# distribute で存在しないキーはスキップされる
# ==================================================

func test_distribute_skips_missing_keys() -> void:
	var s := _make_single_key_saveable(&"npc")
	_mgr.register_saveable(s)
	# npc キーが無いデータを配布する
	var data: Dictionary = {"skill": {"unlocked_ids": []}}

	_mgr._distribute_save_data(data)

	assert_false(s.data_store.has(&"npc"), "存在しないキーのデータは配布されない")
