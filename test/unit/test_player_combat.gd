## AmPlayer の HP・スタミナ境界値計算をテストする
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


# ---- テスト: take_damage 基本 ----

func test_take_damage_reduces_hp() -> void:
	_player.take_damage(20)

	assert_eq(_player.hp, 80, "take_damage で HP が減算される")


func test_take_damage_clamps_to_zero() -> void:
	_player.take_damage(AmPlayer.BASE_MAX_HP + 50)

	assert_eq(_player.hp, 0, "take_damage で HP が 0 にクランプされる（超過ダメージ）")


func test_take_damage_exact_max_hp() -> void:
	_player.take_damage(AmPlayer.BASE_MAX_HP)

	assert_eq(_player.hp, 0, "take_damage で amount == MAX_HP → HP が 0 になる")


func test_take_damage_max_hp_minus_1() -> void:
	_player.take_damage(AmPlayer.BASE_MAX_HP - 1)

	assert_eq(_player.hp, 1, "take_damage で amount == MAX_HP - 1 → HP が 1 残る")


func test_take_damage_zero() -> void:
	_player.take_damage(0)

	assert_eq(_player.hp, AmPlayer.BASE_MAX_HP, "take_damage(0) で HP が変化しない")


func test_take_damage_ignored_while_invincible() -> void:
	_player._is_invincible = true

	_player.take_damage(50)

	assert_eq(_player.hp, AmPlayer.BASE_MAX_HP, "無敵中は take_damage が無視される")


# ---- テスト: スタミナ ----

func test_stamina_drain_clamps_to_zero() -> void:
	_player.stamina = 5.0
	_player._is_dashing = true

	# 大きな delta で一気に消費する
	_player._process_stamina(100.0)

	assert_eq(_player.stamina, 0.0, "スタミナ消費で 0 未満にならない")


func test_stamina_recovery_clamps_to_max() -> void:
	_player.stamina = _player.max_stamina - 1.0
	_player._is_dashing = false

	# 大きな delta で一気に回復する
	_player._process_stamina(100.0)

	assert_eq(_player.stamina, _player.max_stamina, "スタミナ回復で max_stamina を超えない")
