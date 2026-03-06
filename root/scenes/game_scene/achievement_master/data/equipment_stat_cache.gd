## 装備中アイテムのステータス効果累積値を保持するキャッシュ
## InventoryManager が装備変更時に更新し、Pawn の get_effective_*() が参照する
class_name EquipmentStatCache
extends Resource

# ---- 戦闘系 ----
## 最大HP加算（固定値）
var hp_flat: int = 0
## 攻撃力加算（固定値）
var attack_flat: int = 0

# ---- 移動系 ----
## 移動速度増加（%）
var speed_percent: float = 0.0

# ---- スタミナ系 ----
## スタミナ最大値加算（固定値）
var stamina_flat: float = 0.0

# ---- 採取系 ----
## 採取速度増加（%）
var gather_percent: float = 0.0


## 全値をゼロにリセットする
func reset() -> void:
	hp_flat = 0
	attack_flat = 0
	speed_percent = 0.0
	stamina_flat = 0.0
	gather_percent = 0.0


## 装備品定義のステータスをキャッシュに加算する
func apply_equipment(def: EquipmentDefinition) -> void:
	hp_flat += def.hp_flat
	attack_flat += def.attack_flat
	speed_percent += def.speed_percent
	stamina_flat += def.stamina_flat
	gather_percent += def.gather_percent
