## Pawn の戦闘状態追跡ロジックをテストする
extends GutTest

# ---- 定数 ----
const PAWN_SCENE: PackedScene = preload(
	"res://root/scenes/game_scene/achievement_master/character/Pawn/pawn.tscn"
)

# ---- セットアップ ----

var _pawn: Pawn


func before_each() -> void:
	_pawn = PAWN_SCENE.instantiate()
	add_child_autofree(_pawn)


# ---- テスト: _enter_combat ----

func test_enter_combat_emits_signal() -> void:
	# シグナル発火時のパラメータを記録する
	var received := []
	_pawn.combat_state_changed.connect(func(v: bool) -> void: received.append(v))

	_pawn._enter_combat()

	assert_eq(received.size(), 1, "_enter_combat でシグナルが1回発火する")
	assert_true(received[0], "combat_state_changed(true) が発火する")


func test_enter_combat_resets_cooldown() -> void:
	_pawn._enter_combat()

	assert_eq(
		_pawn._combat_cooldown,
		Pawn.COMBAT_COOLDOWN,
		"_enter_combat がクールダウンを COMBAT_COOLDOWN にリセットする",
	)


func test_enter_combat_idempotent() -> void:
	# 最初の呼び出しで戦闘状態に入る
	_pawn._enter_combat()

	# シグナル監視を開始（2回目以降を検出するため）
	watch_signals(_pawn)

	# 2回目の呼び出し — 既に戦闘中なのでシグナルは発火しない
	_pawn._enter_combat()

	assert_signal_not_emitted(
		_pawn,
		"combat_state_changed",
		"既に戦闘中のとき _enter_combat はシグナルを発火しない",
	)


# ---- テスト: _exit_combat ----

func test_exit_combat_emits_signal() -> void:
	# まず戦闘状態に入る
	_pawn._enter_combat()

	# exit のシグナルだけを記録する
	var received := []
	_pawn.combat_state_changed.connect(func(v: bool) -> void: received.append(v))

	_pawn._exit_combat()

	assert_eq(received.size(), 1, "_exit_combat でシグナルが1回発火する")
	assert_false(received[0], "combat_state_changed(false) が発火する")


# ---- テスト: _process_combat_cooldown ----

func test_cooldown_decrements() -> void:
	_pawn._enter_combat()
	var initial_cooldown: float = _pawn._combat_cooldown

	_pawn._process_combat_cooldown(1.0)

	assert_almost_eq(
		_pawn._combat_cooldown,
		initial_cooldown - 1.0,
		0.001,
		"クールダウンが delta 分だけ減算される",
	)


func test_cooldown_triggers_exit() -> void:
	_pawn._enter_combat()

	# exit のシグナルだけを記録する
	var received := []
	_pawn.combat_state_changed.connect(func(v: bool) -> void: received.append(v))

	# クールダウンを一気に消化する
	_pawn._process_combat_cooldown(Pawn.COMBAT_COOLDOWN + 0.1)

	assert_false(_pawn._is_in_combat, "クールダウン完了後は戦闘状態でない")
	assert_eq(received.size(), 1, "クールダウン完了でシグナルが1回発火する")
	assert_false(received[0], "combat_state_changed(false) が発火する")
