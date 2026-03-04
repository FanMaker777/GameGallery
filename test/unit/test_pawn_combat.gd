## Pawn の HP・スタミナ境界値計算をテストする
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


# ---- テスト: take_damage 基本 ----

func test_take_damage_reduces_hp() -> void:
	_pawn.take_damage(20)

	assert_eq(_pawn.hp, 80, "take_damage で HP が減算される")


func test_take_damage_clamps_to_zero() -> void:
	_pawn.take_damage(Pawn.BASE_MAX_HP + 50)

	assert_eq(_pawn.hp, 0, "take_damage で HP が 0 にクランプされる（超過ダメージ）")


func test_take_damage_exact_max_hp() -> void:
	_pawn.take_damage(Pawn.BASE_MAX_HP)

	assert_eq(_pawn.hp, 0, "take_damage で amount == MAX_HP → HP が 0 になる")


func test_take_damage_max_hp_minus_1() -> void:
	_pawn.take_damage(Pawn.BASE_MAX_HP - 1)

	assert_eq(_pawn.hp, 1, "take_damage で amount == MAX_HP - 1 → HP が 1 残る")


func test_take_damage_zero() -> void:
	_pawn.take_damage(0)

	assert_eq(_pawn.hp, Pawn.BASE_MAX_HP, "take_damage(0) で HP が変化しない")


func test_take_damage_ignored_while_invincible() -> void:
	_pawn._is_invincible = true

	_pawn.take_damage(50)

	assert_eq(_pawn.hp, Pawn.BASE_MAX_HP, "無敵中は take_damage が無視される")


# ---- テスト: スタミナ ----

func test_stamina_drain_clamps_to_zero() -> void:
	_pawn.stamina = 5.0
	_pawn._is_dashing = true

	# 大きな delta で一気に消費する
	_pawn._process_stamina(100.0)

	assert_eq(_pawn.stamina, 0.0, "スタミナ消費で 0 未満にならない")


func test_stamina_recovery_clamps_to_max() -> void:
	_pawn.stamina = _pawn.max_stamina - 1.0
	_pawn._is_dashing = false

	# 大きな delta で一気に回復する
	_pawn._process_stamina(100.0)

	assert_eq(_pawn.stamina, _pawn.max_stamina, "スタミナ回復で max_stamina を超えない")
