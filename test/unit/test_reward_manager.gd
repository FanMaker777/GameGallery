## RewardManager の解放判定・AP消費・効果キャッシュ・セーブ/ロードをテストする
extends GutTest

# ---- ヘルパー ----

## テスト用の RewardDefinition を生成する
func _make_def(
	id: StringName = &"test_reward",
	ap_cost: int = 5,
	effect_type: RewardDefinition.EffectType = RewardDefinition.EffectType.HP_PERCENT_UP,
	effect_value: float = 10.0,
	prerequisites: Array[StringName] = [],
) -> RewardDefinition:
	var d := RewardDefinition.new()
	d.id = id
	d.name_ja = "テスト報酬"
	d.ap_cost = ap_cost
	d.effect_type = effect_type
	d.effect_value = effect_value
	d.prerequisites = prerequisites
	return d


## RewardEffectCache の動作テスト用インスタンスを返す
func _make_cache() -> RewardEffectCache:
	return autofree(RewardEffectCache.new())


# ==================================================
# RewardEffectCache テスト
# ==================================================

# ---- apply_effect ----

func test_cache_apply_hp_percent_up() -> void:
	var cache := _make_cache()
	var def := _make_def(&"hp1", 5, RewardDefinition.EffectType.HP_PERCENT_UP, 10.0)

	cache.apply_effect(def)

	assert_eq(cache.hp_percent_up, 10.0, "HP+10% が加算される")


func test_cache_apply_multiple_effects_accumulate() -> void:
	var cache := _make_cache()
	var def1 := _make_def(&"hp1", 5, RewardDefinition.EffectType.HP_PERCENT_UP, 10.0)
	var def2 := _make_def(&"hp2", 8, RewardDefinition.EffectType.HP_PERCENT_UP, 15.0)

	cache.apply_effect(def1)
	cache.apply_effect(def2)

	assert_eq(cache.hp_percent_up, 25.0, "同タイプの効果が合算される")


func test_cache_apply_attack_percent_up() -> void:
	var cache := _make_cache()
	var def := _make_def(&"atk1", 5, RewardDefinition.EffectType.ATTACK_PERCENT_UP, 5.0)

	cache.apply_effect(def)

	assert_eq(cache.attack_percent_up, 5.0, "攻撃力+5% が加算される")


func test_cache_apply_move_speed_up() -> void:
	var cache := _make_cache()
	var def := _make_def(&"spd1", 4, RewardDefinition.EffectType.MOVE_SPEED_UP, 10.0)

	cache.apply_effect(def)

	assert_eq(cache.move_speed_up, 10.0, "移動速度+10% が加算される")


func test_cache_apply_stamina_max_up() -> void:
	var cache := _make_cache()
	var def := _make_def(&"sta1", 6, RewardDefinition.EffectType.STAMINA_MAX_UP, 20.0)

	cache.apply_effect(def)

	assert_eq(cache.stamina_max_up, 20.0, "スタミナ最大値+20% が加算される")


func test_cache_apply_stamina_recovery_up() -> void:
	var cache := _make_cache()
	var def := _make_def(&"sta_rec", 8, RewardDefinition.EffectType.STAMINA_RECOVERY_UP, 25.0)

	cache.apply_effect(def)

	assert_eq(cache.stamina_recovery_up, 25.0, "スタミナ回復速度+25% が加算される")


func test_cache_apply_gather_speed_up() -> void:
	var cache := _make_cache()
	var def := _make_def(&"gath1", 6, RewardDefinition.EffectType.GATHER_SPEED_UP, 25.0)

	cache.apply_effect(def)

	assert_eq(cache.gather_speed_up, 25.0, "採取速度+25% が加算される")


func test_cache_apply_flag_minimap() -> void:
	var cache := _make_cache()
	var def := _make_def(&"mini", 8, RewardDefinition.EffectType.MINIMAP, 1.0)

	cache.apply_effect(def)

	assert_true(cache.minimap_enabled, "ミニマップフラグが有効になる")


func test_cache_apply_flag_fast_travel() -> void:
	var cache := _make_cache()
	var def := _make_def(&"ft", 12, RewardDefinition.EffectType.FAST_TRAVEL, 1.0)

	cache.apply_effect(def)

	assert_true(cache.fast_travel_enabled, "ファストトラベルフラグが有効になる")


func test_cache_apply_pin_slot() -> void:
	var cache := _make_cache()
	var def := _make_def(&"pin", 5, RewardDefinition.EffectType.PIN_SLOT_PLUS_1, 1.0)

	cache.apply_effect(def)

	assert_eq(cache.pin_slot_bonus, 1, "ピン留め枠が+1される")


# ---- reset ----

func test_cache_reset_clears_all() -> void:
	var cache := _make_cache()
	cache.hp_percent_up = 25.0
	cache.attack_percent_up = 10.0
	cache.minimap_enabled = true
	cache.pin_slot_bonus = 2

	cache.reset()

	assert_eq(cache.hp_percent_up, 0.0, "リセット後 HP ボーナスが 0")
	assert_eq(cache.attack_percent_up, 0.0, "リセット後 攻撃ボーナスが 0")
	assert_false(cache.minimap_enabled, "リセット後 ミニマップが無効")
	assert_eq(cache.pin_slot_bonus, 0, "リセット後 ピン枠ボーナスが 0")


# ==================================================
# RewardDefinition テスト
# ==================================================

func test_definition_default_values() -> void:
	var def := RewardDefinition.new()

	assert_eq(def.id, &"", "デフォルト ID は空")
	assert_eq(def.ap_cost, 5, "デフォルト AP コストは 5")
	assert_eq(def.prerequisites.size(), 0, "デフォルト前提は空配列")


# ==================================================
# RewardDatabase テスト
# ==================================================

func test_database_holds_definitions() -> void:
	var db := RewardDatabase.new()
	var def1 := _make_def(&"r1")
	var def2 := _make_def(&"r2")
	db.rewards = [def1, def2]

	assert_eq(db.rewards.size(), 2, "Database に2件の定義が格納される")
