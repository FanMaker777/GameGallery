## プレイヤーの実効ステータスを計算する静的ユーティリティ
## 装備キャッシュとスキル効果キャッシュから最終値を算出する（SSOT）
class_name AmPlayerStatCalculator


## 有効な最大HPを返す（基礎値 + 装備固定値 → スキル%ボーナス）
static func get_effective_max_hp(
	ec: EquipmentStatCache, sc: SkillEffectCache,
) -> int:
	var base: int = AmPlayer.BASE_MAX_HP
	if ec != null:
		base += ec.hp_flat
	if sc != null:
		return int(base * (1.0 + sc.hp_percent_up / 100.0))
	return base


## 有効な攻撃力を返す（基礎値 + 装備固定値 → スキル%ボーナス）
static func get_effective_attack(
	ec: EquipmentStatCache, sc: SkillEffectCache,
) -> int:
	var base: int = AmPlayer.BASE_ATTACK_DAMAGE
	if ec != null:
		base += ec.attack_flat
	if sc != null:
		return int(base * (1.0 + sc.attack_percent_up / 100.0))
	return base


## 有効な移動速度を返す（基礎値 → 装備%ボーナス + スキル%ボーナス）
static func get_effective_speed(
	ec: EquipmentStatCache, sc: SkillEffectCache,
) -> float:
	var percent_bonus: float = 0.0
	if ec != null:
		percent_bonus += ec.speed_percent
	if sc != null:
		percent_bonus += sc.move_speed_up
	return AmPlayer.BASE_SPEED * (1.0 + percent_bonus / 100.0)


## 有効なスタミナ最大値を返す（基礎値 + 装備固定値 → スキル%ボーナス）
static func get_effective_max_stamina(
	ec: EquipmentStatCache, sc: SkillEffectCache,
) -> float:
	var base: float = AmPlayer.BASE_MAX_STAMINA
	if ec != null:
		base += ec.stamina_flat
	if sc != null:
		return base * (1.0 + sc.stamina_max_up / 100.0)
	return base


## 有効なスタミナ回復速度を返す（基礎値 → スキル%ボーナス）
static func get_effective_stamina_recovery(sc: SkillEffectCache) -> float:
	if sc == null:
		return AmPlayer.BASE_STAMINA_RECOVERY_RATE
	return AmPlayer.BASE_STAMINA_RECOVERY_RATE * (1.0 + sc.stamina_recovery_up / 100.0)


## 有効な採取速度倍率を返す（1.0=通常、装備%ボーナス + スキル%ボーナス）
static func get_effective_gather_speed(
	ec: EquipmentStatCache, sc: SkillEffectCache,
) -> float:
	var percent_bonus: float = 0.0
	if ec != null:
		percent_bonus += ec.gather_percent
	if sc != null:
		percent_bonus += sc.gather_speed_up
	return 1.0 + percent_bonus / 100.0
