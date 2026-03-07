## ステータスタブ — プレイヤーの能力値を内訳付きで表示する
class_name StatusTab extends MarginContainer

# ---- ノードキャッシュ ----
# 戦闘
@onready var _max_hp_value: Label = %MaxHpValue
@onready var _max_hp_detail: Label = %MaxHpDetail
@onready var _attack_value: Label = %AttackValue
@onready var _attack_detail: Label = %AttackDetail
# 機動
@onready var _speed_value: Label = %SpeedValue
@onready var _speed_detail: Label = %SpeedDetail
@onready var _stamina_max_value: Label = %StaminaMaxValue
@onready var _stamina_max_detail: Label = %StaminaMaxDetail
@onready var _stamina_recovery_value: Label = %StaminaRecoveryValue
@onready var _stamina_recovery_detail: Label = %StaminaRecoveryDetail
# 採取・生産
@onready var _gather_speed_value: Label = %GatherSpeedValue
@onready var _gather_speed_detail: Label = %GatherSpeedDetail
@onready var _harvest_bonus_value: Label = %HarvestBonusValue
@onready var _harvest_bonus_detail: Label = %HarvestBonusDetail
@onready var _shop_discount_value: Label = %ShopDiscountValue
@onready var _shop_discount_detail: Label = %ShopDiscountDetail
# 特殊能力
@onready var _auto_collect_value: Label = %AutoCollectValue
@onready var _pin_slot_value: Label = %PinSlotValue
@onready var _diversity_value: Label = %DiversityValue
@onready var _minimap_value: Label = %MinimapValue
@onready var _fast_travel_value: Label = %FastTravelValue


func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)


func _on_visibility_changed() -> void:
	if visible:
		_refresh()


## 全ステータスを再計算して表示する
func _refresh() -> void:
	var ec: EquipmentStatCache = InventoryManager.get_equip_cache()
	var sc: SkillEffectCache = SkillManager.get_effect_cache()

	_refresh_combat(ec, sc)
	_refresh_mobility(ec, sc)
	_refresh_gathering(ec, sc)
	_refresh_special(sc)


func _refresh_combat(ec: EquipmentStatCache, sc: SkillEffectCache) -> void:
	_display_additive_stat(
		Pawn.BASE_MAX_HP, ec.hp_flat, sc.hp_percent_up,
		_max_hp_value, _max_hp_detail,
	)
	_display_additive_stat(
		Pawn.BASE_ATTACK_DAMAGE, ec.attack_flat, sc.attack_percent_up,
		_attack_value, _attack_detail,
	)


func _refresh_mobility(ec: EquipmentStatCache, sc: SkillEffectCache) -> void:
	# 移動速度: base * (1 + equip% + skill%)
	var spd_total: float = Pawn.BASE_SPEED * (1.0 + (ec.speed_percent + sc.move_speed_up) / 100.0)
	_speed_value.text = "%.1f" % spd_total
	_speed_detail.text = "(基礎:%.0f  装備:+%.0f%%  スキル:+%.0f%%)" % [
		Pawn.BASE_SPEED, ec.speed_percent, sc.move_speed_up,
	]

	# スタミナ最大値: (base + equip) * (1 + skill%)
	var stam_base: float = Pawn.BASE_MAX_STAMINA
	var stam_total: float = (stam_base + ec.stamina_flat) * (1.0 + sc.stamina_max_up / 100.0)
	_stamina_max_value.text = "%.1f" % stam_total
	_stamina_max_detail.text = "(基礎:%.0f  装備:+%.0f  スキル:+%.0f%%)" % [
		stam_base, ec.stamina_flat, sc.stamina_max_up,
	]

	# スタミナ回復: 100% + skill%
	var rec_total: int = 100 + int(sc.stamina_recovery_up)
	_stamina_recovery_value.text = "%d%%" % rec_total
	_stamina_recovery_detail.text = "(スキル:+%.0f%%)" % sc.stamina_recovery_up


func _refresh_gathering(ec: EquipmentStatCache, sc: SkillEffectCache) -> void:
	# 採取速度: (1 + equip% + skill%) を %表示
	var gath_total: int = 100 + int(ec.gather_percent + sc.gather_speed_up)
	_gather_speed_value.text = "%d%%" % gath_total
	_gather_speed_detail.text = "(装備:+%.0f%%  スキル:+%.0f%%)" % [ec.gather_percent, sc.gather_speed_up]

	# 収穫量ボーナス: skill%
	_display_skill_percent(sc.harvest_bonus, _harvest_bonus_value, _harvest_bonus_detail)

	# 店割引: skill%
	_display_skill_percent(sc.shop_discount, _shop_discount_value, _shop_discount_detail)


func _refresh_special(sc: SkillEffectCache) -> void:
	_auto_collect_value.text = "x%.1f" % sc.auto_collect_multiplier
	_pin_slot_value.text = "%d枠" % (AchievementTracker.MAX_PIN_COUNT + sc.pin_slot_bonus)
	_diversity_value.text = "+10%%" if sc.diversity_bonus_enabled else "+0%%"
	_minimap_value.text = "有効" if sc.minimap_enabled else "---"
	_fast_travel_value.text = "有効" if sc.fast_travel_enabled else "---"


## (base + equip_flat) * (1 + skill_pct%) の加算型ステータスを表示する
func _display_additive_stat(
	base: int, equip_flat: int, skill_pct: float,
	value_label: Label, detail_label: Label,
) -> void:
	var total: int = int((base + equip_flat) * (1.0 + skill_pct / 100.0))
	value_label.text = str(total)
	detail_label.text = "(基礎:%d  装備:+%d  スキル:+%d%%)" % [base, equip_flat, int(skill_pct)]


## スキル由来の %値のみを表示する
func _display_skill_percent(value: float, value_label: Label, detail_label: Label) -> void:
	value_label.text = "%.0f%%" % value
	detail_label.text = "(スキル:+%.0f%%)" % value
