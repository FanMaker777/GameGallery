## RecordDatabase のカウント・ストリーク・ユニーク・リセットをテストする
extends GutTest

# ---- セットアップ ----

var _db: RecordDatabase


func before_each() -> void:
	_db = autofree(RecordDatabase.new())


# ---- テスト: record 基本 ----

func test_record_increments_count_by_1() -> void:
	_db.record(&"enemy_killed")

	assert_eq(_db.enemy_killed, 1, "record で count が 1 加算される")


func test_record_increments_count_by_amount() -> void:
	_db.record(&"enemy_killed", {&"amount": 5})

	assert_eq(_db.enemy_killed, 5, "record で amount 指定時にその値が加算される")


func test_record_accumulates() -> void:
	_db.record(&"enemy_killed")
	_db.record(&"enemy_killed")
	_db.record(&"enemy_killed")

	assert_eq(_db.enemy_killed, 3, "record を複数回呼ぶと累積される")


func test_record_ignores_unknown_action() -> void:
	_db.record(&"unknown_action")

	# 既知のカウンタが変化していないことを確認する
	assert_eq(_db.enemy_killed, 0, "未知のアクションは無視される")
	assert_engine_error("未知のアクション", "Log.warn が出力される")


# ---- テスト: 型名別内訳 ----

func test_record_updates_type_breakdown() -> void:
	_db.record(&"enemy_killed", {&"type_name": "Skull"})

	assert_eq(
		_db.enemy_killed_by_type.get("Skull", 0), 1,
		"type_name 指定で型別内訳が更新される",
	)


func test_record_accumulates_type_breakdown() -> void:
	_db.record(&"enemy_killed", {&"type_name": "Skull"})
	_db.record(&"enemy_killed", {&"type_name": "Skull", &"amount": 2})

	assert_eq(
		_db.enemy_killed_by_type.get("Skull", 0), 3,
		"type_name 指定で型別内訳が累積される",
	)


# ---- テスト: ユニークセット ----

func test_record_adds_unique_instance() -> void:
	_db.record(&"map_entered", {&"instance_id": "forest"})

	assert_eq(
		_db.unique_maps_entered.size(), 1,
		"instance_id 指定で unique_count が加算される",
	)


func test_record_does_not_duplicate_instance() -> void:
	_db.record(&"map_entered", {&"instance_id": "forest"})
	_db.record(&"map_entered", {&"instance_id": "forest"})

	assert_eq(
		_db.unique_maps_entered.size(), 1,
		"同一 instance_id は重複カウントされない",
	)


func test_record_counts_different_instances() -> void:
	_db.record(&"map_entered", {&"instance_id": "forest"})
	_db.record(&"map_entered", {&"instance_id": "cave"})

	assert_eq(
		_db.unique_maps_entered.size(), 2,
		"異なる instance_id は両方カウントされる",
	)


# ---- テスト: ストリーク ----

func test_increment_streak() -> void:
	_db.increment_streak(&"enemy_killed", &"player_damaged")

	assert_eq(
		_db.streak_enemy_killed_no_damage, 1,
		"increment_streak で値が加算される",
	)


func test_increment_streak_ignores_unknown_key() -> void:
	_db.increment_streak(&"unknown", &"unknown")

	# 全ストリークが 0 のままであることを確認する
	assert_eq(_db.streak_enemy_killed_no_damage, 0, "未知のストリークキーは無視される")
	assert_engine_error("未知のストリーク", "Log.warn が出力される")


func test_reset_streaks_by_reset_on() -> void:
	_db.increment_streak(&"enemy_killed", &"player_damaged", 5)
	_db.increment_streak(&"map_entered", &"player_damaged", 3)

	_db.reset_streaks_by_reset_on(&"player_damaged")

	assert_eq(
		_db.streak_enemy_killed_no_damage, 0,
		"reset_streaks_by_reset_on で関連ストリークがリセットされる (enemy_killed_no_damage)",
	)
	assert_eq(
		_db.streak_map_no_damage, 0,
		"reset_streaks_by_reset_on で関連ストリークがリセットされる (map_no_damage)",
	)


func test_reset_streaks_does_not_affect_unrelated() -> void:
	_db.increment_streak(&"resource_harvested", &"attack_started", 4)

	_db.reset_streaks_by_reset_on(&"player_damaged")

	assert_eq(
		_db.streak_harvest_no_attack, 4,
		"reset_streaks_by_reset_on は無関係なストリークに影響しない",
	)


# ---- テスト: reset_all ----

func test_reset_all_clears_everything() -> void:
	_db.record(&"enemy_killed", {&"amount": 10, &"type_name": "Skull"})
	_db.record(&"map_entered", {&"instance_id": "forest"})
	_db.increment_streak(&"enemy_killed", &"player_damaged", 5)

	_db.reset_all()

	assert_eq(_db.enemy_killed, 0, "reset_all で enemy_killed がリセットされる")
	assert_eq(
		_db.enemy_killed_by_type.size(), 0,
		"reset_all で enemy_killed_by_type がリセットされる",
	)
	assert_eq(
		_db.unique_maps_entered.size(), 0,
		"reset_all で unique_maps_entered がリセットされる",
	)
	assert_eq(
		_db.streak_enemy_killed_no_damage, 0,
		"reset_all でストリークがリセットされる",
	)


# ---- テスト: 境界値 ----

func test_get_count_unknown_action_returns_0() -> void:
	assert_eq(_db.get_count(&"totally_unknown"), 0, "get_count で未知のアクションは 0 を返す")


func test_get_unique_count_no_mapping_returns_0() -> void:
	assert_eq(
		_db.get_unique_count(&"enemy_killed"), 0,
		"get_unique_count で対応なしアクションは 0 を返す",
	)
