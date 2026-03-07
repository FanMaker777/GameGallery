## 解放済みスキルの効果累積値を保持するキャッシュ
## SkillManager がスキル解放・ロード時に更新し、各システムが参照する
class_name SkillEffectCache
extends Resource

# ---- 戦闘系 ----
## 最大HP増加（%）
var hp_percent_up: float = 0.0
## 攻撃力増加（%）
var attack_percent_up: float = 0.0
## 死亡復帰時間短縮（%）
var respawn_time_down: float = 0.0
## スタミナ最大値増加（%）
var stamina_max_up: float = 0.0
## スタミナ回復速度増加（%）
var stamina_recovery_up: float = 0.0

# ---- 農業系 ----
## 収穫量増加（%）
var harvest_bonus: float = 0.0
## 採取速度増加（%）
var gather_speed_up: float = 0.0

# ---- 探索系 ----
## 移動速度増加（%）
var move_speed_up: float = 0.0
## 店割引（%）
var shop_discount: float = 0.0

# ---- フラグ系 ----
## ドロップ自動回収範囲倍率
var auto_collect_multiplier: float = 1.0
## ピン留め枠追加数
var pin_slot_bonus: int = 0
## 多様性ボーナス有効
var diversity_bonus_enabled: bool = false
## ミニマップ表示
var minimap_enabled: bool = false
## ファストトラベル解放
var fast_travel_enabled: bool = false


## 全値をゼロ/デフォルトにリセットする
func reset() -> void:
	hp_percent_up = 0.0
	attack_percent_up = 0.0
	respawn_time_down = 0.0
	stamina_max_up = 0.0
	stamina_recovery_up = 0.0
	harvest_bonus = 0.0
	gather_speed_up = 0.0
	move_speed_up = 0.0
	shop_discount = 0.0
	auto_collect_multiplier = 1.0
	pin_slot_bonus = 0
	diversity_bonus_enabled = false
	minimap_enabled = false
	fast_travel_enabled = false


## スキル定義の効果をキャッシュに加算する
func apply_effect(def: SkillDefinition) -> void:
	match def.effect_type:
		SkillDefinition.EffectType.HP_PERCENT_UP:
			hp_percent_up += def.effect_value
		SkillDefinition.EffectType.ATTACK_PERCENT_UP:
			attack_percent_up += def.effect_value
		SkillDefinition.EffectType.RESPAWN_TIME_DOWN:
			respawn_time_down += def.effect_value
		SkillDefinition.EffectType.STAMINA_MAX_UP:
			stamina_max_up += def.effect_value
		SkillDefinition.EffectType.STAMINA_RECOVERY_UP:
			stamina_recovery_up += def.effect_value
		SkillDefinition.EffectType.HARVEST_BONUS:
			harvest_bonus += def.effect_value
		SkillDefinition.EffectType.GATHER_SPEED_UP:
			gather_speed_up += def.effect_value
		SkillDefinition.EffectType.MOVE_SPEED_UP:
			move_speed_up += def.effect_value
		SkillDefinition.EffectType.SHOP_DISCOUNT:
			shop_discount += def.effect_value
		SkillDefinition.EffectType.AUTO_COLLECT:
			auto_collect_multiplier += def.effect_value
		SkillDefinition.EffectType.PIN_SLOT_PLUS_1:
			pin_slot_bonus += int(def.effect_value)
		SkillDefinition.EffectType.DIVERSITY_BONUS:
			diversity_bonus_enabled = true
		SkillDefinition.EffectType.MINIMAP:
			minimap_enabled = true
		SkillDefinition.EffectType.FAST_TRAVEL:
			fast_travel_enabled = true
