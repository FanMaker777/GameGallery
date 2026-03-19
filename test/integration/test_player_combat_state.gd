## AmPlayer の戦闘状態追跡ロジックをテストする
extends GutTest

# ---- 定数 ----
const PLAYER_SCENE: PackedScene = preload(
	"res://root/scenes/game_scene/achievement_master/character/Player/player.tscn"
)

# ---- セットアップ ----

var _player: AmPlayer


func before_each() -> void:
	_player = PLAYER_SCENE.instantiate()
	add_child_autofree(_player)


# ---- テスト: _enter_combat ----

func test_enter_combat_sets_flag() -> void:
	_player._enter_combat()

	assert_true(_player._is_in_combat, "_enter_combat で戦闘中フラグが立つ")


func test_enter_combat_resets_cooldown() -> void:
	_player._enter_combat()

	assert_eq(
		_player._combat_cooldown,
		AmPlayer.COMBAT_COOLDOWN,
		"_enter_combat がクールダウンを COMBAT_COOLDOWN にリセットする",
	)


func test_enter_combat_idempotent() -> void:
	_player._enter_combat()
	_player._enter_combat()

	assert_true(_player._is_in_combat, "2回呼んでも戦闘中のまま")


# ---- テスト: _exit_combat ----

func test_exit_combat_clears_flag() -> void:
	_player._enter_combat()
	_player._exit_combat()

	assert_false(_player._is_in_combat, "_exit_combat で戦闘中フラグが下りる")


# ---- テスト: _process_combat_cooldown ----

func test_cooldown_decrements() -> void:
	_player._enter_combat()
	var initial_cooldown: float = _player._combat_cooldown

	_player._process_combat_cooldown(1.0)

	assert_almost_eq(
		_player._combat_cooldown,
		initial_cooldown - 1.0,
		0.001,
		"クールダウンが delta 分だけ減算される",
	)


func test_cooldown_triggers_exit() -> void:
	_player._enter_combat()

	# クールダウンを一気に消化する
	_player._process_combat_cooldown(AmPlayer.COMBAT_COOLDOWN + 0.1)

	assert_false(_player._is_in_combat, "クールダウン完了後は戦闘状態でない")
