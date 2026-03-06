## 消耗品1件の定義データ（HPポーション・スタミナ回復薬など）
## 使用するとバッグから1個消費され、Pawn 側で効果が適用される
class_name ConsumableDefinition
extends ItemDefinition

## 消耗品の効果種別
enum EffectType { HP_RECOVER, STAMINA_RECOVER }

## 効果の種類
@export var effect_type: EffectType = EffectType.HP_RECOVER
## 効果の数値（回復量など）
@export var effect_value: float = 0.0


## 消耗品カテゴリを返す
func get_category() -> Category:
	return Category.CONSUMABLE
