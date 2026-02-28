## ToastManager のキュー管理ロジックをテストする
extends GutTest

# ---- ヘルパー ----

## テスト用の AchievementDefinition を生成する
func _make_def(rank: AchievementDefinition.Rank, id: StringName = &"test") -> AchievementDefinition:
	var d := AchievementDefinition.new()
	d.id = id
	d.name_ja = "テスト実績"
	d.rank = rank
	d.ap = 10
	return d


# ---- セットアップ ----

var _manager: ToastManager


func before_each() -> void:
	_manager = ToastManager.new()
	# add_child すると _ready() が走り、AchievementManager シグナルに接続される
	# テストではシグナル接続されても問題ないのでそのまま追加する
	add_child_autofree(_manager)


# ---- テスト: キュー振り分け ----

func test_bronze_added_to_queue() -> void:
	var def := _make_def(AchievementDefinition.Rank.BRONZE)
	_manager._on_achievement_unlocked(&"test", def)
	# Bronze は通常キューの末尾に追加される（_try_show_next で pop されるので
	# _is_showing が true になっていればキューには残らないが、_show_toast が
	# TOAST_SCENE.instantiate() を使うので実際にトーストが生成される）
	# → _is_showing が true になっていることで追加成功を確認する
	assert_true(_manager._is_showing, "Bronze を追加すると表示が開始される")


func test_silver_added_to_front_of_queue() -> void:
	# まず Bronze を2つキューに入れる（1つ目は即表示されるので2つ必要）
	var bronze1 := _make_def(AchievementDefinition.Rank.BRONZE, &"b1")
	var bronze2 := _make_def(AchievementDefinition.Rank.BRONZE, &"b2")
	_manager._on_achievement_unlocked(&"b1", bronze1)
	_manager._on_achievement_unlocked(&"b2", bronze2)

	# Silver をキューに入れる → 先頭に挿入される
	var silver := _make_def(AchievementDefinition.Rank.SILVER, &"s1")
	_manager._on_achievement_unlocked(&"s1", silver)

	# キューの先頭が Silver であることを確認する
	assert_eq(_manager._queue[0].id, &"s1", "Silver はキューの先頭に追加される")


func test_gold_added_to_front_of_queue() -> void:
	# Bronze を2つ入れておく
	var bronze1 := _make_def(AchievementDefinition.Rank.BRONZE, &"b1")
	var bronze2 := _make_def(AchievementDefinition.Rank.BRONZE, &"b2")
	_manager._on_achievement_unlocked(&"b1", bronze1)
	_manager._on_achievement_unlocked(&"b2", bronze2)

	# Gold をキューに入れる → 先頭に挿入される
	var gold := _make_def(AchievementDefinition.Rank.GOLD, &"g1")
	_manager._on_achievement_unlocked(&"g1", gold)

	assert_eq(_manager._queue[0].id, &"g1", "Gold はキューの先頭に追加される")


# ---- テスト: 戦闘中の遅延 ----

func test_bronze_delayed_during_combat() -> void:
	# 戦闘状態にする
	_manager._on_combat_state_changed(true)

	var def := _make_def(AchievementDefinition.Rank.BRONZE)
	_manager._on_achievement_unlocked(&"test", def)

	assert_eq(_manager._combat_queue.size(), 1, "戦闘中の Bronze は combat_queue に溜まる")
	assert_eq(_manager._queue.size(), 0, "通常キューには追加されない")


func test_combat_queue_flushed_on_combat_end() -> void:
	# 戦闘状態にして Bronze を溜める
	_manager._on_combat_state_changed(true)
	_manager._on_achievement_unlocked(&"b1", _make_def(AchievementDefinition.Rank.BRONZE, &"b1"))
	_manager._on_achievement_unlocked(&"b2", _make_def(AchievementDefinition.Rank.BRONZE, &"b2"))
	assert_eq(_manager._combat_queue.size(), 2, "戦闘中に2件溜まる")

	# 戦闘終了
	_manager._on_combat_state_changed(false)

	assert_eq(_manager._combat_queue.size(), 0, "combat_queue はクリアされる")
	# 1件は即表示されるので _is_showing == true、残り1件がキューに残る
	assert_true(_manager._is_showing, "戦闘終了後に表示が開始される")


func test_silver_not_delayed_during_combat() -> void:
	# 戦闘状態にする
	_manager._on_combat_state_changed(true)

	var def := _make_def(AchievementDefinition.Rank.SILVER, &"s1")
	_manager._on_achievement_unlocked(&"s1", def)

	assert_eq(_manager._combat_queue.size(), 0, "Silver は combat_queue には入らない")
	assert_true(_manager._is_showing, "Silver は戦闘中でも即表示される")


# ---- テスト: 表示制限 ----

func test_show_next_skipped_when_already_showing() -> void:
	# 最初の Bronze で _is_showing = true になる
	_manager._on_achievement_unlocked(&"b1", _make_def(AchievementDefinition.Rank.BRONZE, &"b1"))
	assert_true(_manager._is_showing, "1件目で表示中になる")

	# キューに Bronze を追加
	_manager._on_achievement_unlocked(&"b2", _make_def(AchievementDefinition.Rank.BRONZE, &"b2"))

	# _try_show_next を明示的に呼んでも表示中のため何も起きない
	var queue_size_before: int = _manager._queue.size()
	_manager._try_show_next()
	assert_eq(_manager._queue.size(), queue_size_before, "表示中は _try_show_next でキューが消費されない")
