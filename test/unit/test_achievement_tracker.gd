## AchievementTracker の進捗導出・解除・ピン留め・リセットをテストする
extends GutTest

# ---- ヘルパー ----

## テスト用の AchievementDefinition を生成する
func _make_def(
	id: StringName = &"test_ach",
	type: AchievementDefinition.Type = AchievementDefinition.Type.COUNTER,
	trigger: StringName = &"enemy_killed",
	target: int = 5,
	reset_on: StringName = &"",
	unique_instances: bool = false,
	ap: int = 10,
) -> AchievementDefinition:
	var d := AchievementDefinition.new()
	d.id = id
	d.name_ja = "テスト実績"
	d.rank = AchievementDefinition.Rank.BRONZE
	d.ap = ap
	d.type = type
	d.trigger_action = trigger
	d.target_count = target
	d.reset_on = reset_on
	d.unique_instances = unique_instances
	return d


## AchievementTracker を手動セットアップする（Autoload / ファイルI/O 依存を排除）
func _make_tracker(defs: Array[AchievementDefinition] = []) -> AchievementTracker:
	var tracker := AchievementTracker.new()
	# _record_db を新規インスタンスで差し替える
	tracker._record_db = RecordDatabase.new()
	# _database と _def_map を手動構築する
	var db := AchievementDatabase.new()
	db.achievements = defs
	tracker._database = db
	tracker._def_map = {}
	for def: AchievementDefinition in defs:
		tracker._def_map[def.id] = def
	add_child_autofree(tracker)
	return tracker


# ---- セットアップ ----

var _tracker: AchievementTracker
var _def: AchievementDefinition


func before_each() -> void:
	_def = _make_def()
	_tracker = _make_tracker([_def])


# ---- テスト: _derive_progress ----

func test_derive_progress_counter_returns_count() -> void:
	_tracker._record_db.record(&"enemy_killed", {&"amount": 3})

	var progress: int = _tracker._derive_progress(_def)

	assert_eq(progress, 3, "COUNTER 型で get_count を返す")


func test_derive_progress_challenge_returns_streak() -> void:
	var chal_def := _make_def(
		&"chal", AchievementDefinition.Type.CHALLENGE,
		&"enemy_killed", 5, &"player_damaged",
	)
	var tracker := _make_tracker([chal_def])
	tracker._record_db.increment_streak(&"enemy_killed", &"player_damaged", 4)

	var progress: int = tracker._derive_progress(chal_def)

	assert_eq(progress, 4, "CHALLENGE 型で get_streak を返す")


func test_derive_progress_unique_returns_unique_count() -> void:
	var uniq_def := _make_def(
		&"uniq", AchievementDefinition.Type.COUNTER,
		&"map_entered", 3, &"", true,
	)
	var tracker := _make_tracker([uniq_def])
	tracker._record_db.record(&"map_entered", {&"instance_id": "forest"})
	tracker._record_db.record(&"map_entered", {&"instance_id": "cave"})

	var progress: int = tracker._derive_progress(uniq_def)

	assert_eq(progress, 2, "unique_instances=true で get_unique_count を返す")


# ---- テスト: _unlock_achievement ----

func test_unlock_adds_to_unlocked() -> void:
	_tracker._unlock_achievement(_def)

	assert_true(_tracker._unlocked.has(&"test_ach"), "_unlock_achievement で _unlocked に追加される")


func test_unlock_adds_ap() -> void:
	_tracker._unlock_achievement(_def)

	assert_eq(_tracker._total_ap, 10, "_unlock_achievement で AP が加算される")


func test_unlock_emits_signal() -> void:
	var received := []
	_tracker.achievement_unlocked.connect(
		func(id: StringName, def: AchievementDefinition) -> void:
			received.append(id)
	)

	_tracker._unlock_achievement(_def)

	assert_eq(received.size(), 1, "_unlock_achievement でシグナルが発火する")
	assert_eq(received[0], &"test_ach", "シグナルに正しい ID が渡される")


func test_double_unlock_does_not_double_ap() -> void:
	_tracker._unlock_achievement(_def)
	_tracker._unlock_achievement(_def)

	assert_eq(_tracker._total_ap, 10, "二重解除で AP が二重加算されない")


func test_unlock_auto_unpins() -> void:
	# 先にピン留めする
	_tracker.pin_achievement(&"test_ach")
	assert_true(_tracker.is_pinned(&"test_ach"), "ピン留め済みの前提")

	_tracker._unlock_achievement(_def)

	assert_false(_tracker.is_pinned(&"test_ach"), "解除時にピン留めが自動解除される")


# ---- テスト: ピン留め ----

func test_pin_achievement() -> void:
	_tracker.pin_achievement(&"test_ach")

	assert_true(_tracker.is_pinned(&"test_ach"), "pin_achievement で _pinned_ids に追加される")


func test_pin_rejected_for_unlocked() -> void:
	_tracker._unlocked[&"test_ach"] = 0.0

	_tracker.pin_achievement(&"test_ach")

	assert_false(_tracker.is_pinned(&"test_ach"), "解除済み実績のピン留めは拒否される")


func test_pin_rejected_over_max() -> void:
	# MAX_PIN_COUNT 分のダミー実績を作ってピン留めする
	var defs: Array[AchievementDefinition] = []
	for i in AchievementTracker.MAX_PIN_COUNT + 1:
		defs.append(_make_def(&"pin_%d" % i))
	var tracker := _make_tracker(defs)
	for i in AchievementTracker.MAX_PIN_COUNT:
		tracker.pin_achievement(&"pin_%d" % i)

	# MAX_PIN_COUNT + 1 番目のピン留めは拒否される
	tracker.pin_achievement(&"pin_%d" % AchievementTracker.MAX_PIN_COUNT)

	assert_eq(
		tracker._pinned_ids.size(), AchievementTracker.MAX_PIN_COUNT,
		"MAX_PIN_COUNT 超過時は拒否される",
	)


func test_unpin_achievement() -> void:
	_tracker.pin_achievement(&"test_ach")

	_tracker.unpin_achievement(&"test_ach")

	assert_false(_tracker.is_pinned(&"test_ach"), "unpin_achievement で _pinned_ids から削除される")


func test_pin_emits_pinned_changed() -> void:
	var received := []
	_tracker.pinned_changed.connect(func() -> void: received.append(true))

	_tracker.pin_achievement(&"test_ach")

	assert_eq(received.size(), 1, "pin で pinned_changed シグナルが発火する")


func test_unpin_emits_pinned_changed() -> void:
	_tracker.pin_achievement(&"test_ach")
	var received := []
	_tracker.pinned_changed.connect(func() -> void: received.append(true))

	_tracker.unpin_achievement(&"test_ach")

	assert_eq(received.size(), 1, "unpin で pinned_changed シグナルが発火する")


# ---- テスト: handle_challenge_reset ----

func test_handle_challenge_reset() -> void:
	_tracker._record_db.increment_streak(&"enemy_killed", &"player_damaged", 5)

	_tracker.handle_challenge_reset(&"player_damaged")

	assert_eq(
		_tracker._record_db.get_streak(&"enemy_killed", &"player_damaged"), 0,
		"handle_challenge_reset でストリークがリセットされる",
	)


# ---- テスト: reset_records ----

func test_reset_records_clears_all() -> void:
	_tracker._unlock_achievement(_def)
	_tracker._record_db.record(&"enemy_killed", {&"amount": 10})

	_tracker.reset_records()

	assert_eq(_tracker._unlocked.size(), 0, "reset_records で _unlocked がクリアされる")
	assert_eq(_tracker._total_ap, 0, "reset_records で AP がクリアされる")
	assert_eq(_tracker._pinned_ids.size(), 0, "reset_records で ピン留めがクリアされる")
	assert_eq(
		_tracker._record_db.get_count(&"enemy_killed"), 0,
		"reset_records で RecordDatabase がリセットされる",
	)


# ---- テスト: record_action 統合フロー ----

func test_record_action_unlocks_on_target() -> void:
	# target=5 の COUNTER 実績 — 5回記録したら解除される
	for i in 5:
		_tracker.record_action(&"enemy_killed")

	assert_true(
		_tracker._unlocked.has(&"test_ach"),
		"record_action → target 到達で解除される",
	)


func test_record_action_increments_challenge_streak() -> void:
	var chal_def := _make_def(
		&"chal", AchievementDefinition.Type.CHALLENGE,
		&"enemy_killed", 10, &"player_damaged",
	)
	var tracker := _make_tracker([chal_def])

	tracker.record_action(&"enemy_killed")

	assert_eq(
		tracker._record_db.get_streak(&"enemy_killed", &"player_damaged"), 1,
		"record_action で CHALLENGE のストリークが加算される",
	)


func test_record_action_emits_progress_updated() -> void:
	var received := []
	_tracker.achievement_progress_updated.connect(
		func(id: StringName, current: int, target: int) -> void:
			received.append({"id": id, "current": current, "target": target})
	)

	_tracker.record_action(&"enemy_killed")

	assert_eq(received.size(), 1, "record_action で progress_updated シグナルが発火する")
	assert_eq(received[0].id, &"test_ach", "正しい実績IDが渡される")
	assert_eq(received[0].current, 1, "現在の進捗が渡される")
	assert_eq(received[0].target, 5, "目標値が渡される")
