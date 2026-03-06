## 装備品1件の定義データ（武器・防具・アクセサリ）
## ステータス効果はフィールドとして直接保持し、EquipmentStatCache と1対1で対応する
class_name EquipmentDefinition
extends ItemDefinition

## 装備スロットの種類
enum EquipSlot { WEAPON, ARMOR, ACCESSORY }

## 装備先のスロット
@export var equip_slot: EquipSlot = EquipSlot.WEAPON

@export_group("ステータス効果")
## 最大HP加算（固定値）
@export var hp_flat: int = 0
## 攻撃力加算（固定値）
@export var attack_flat: int = 0
## 移動速度増加（%）
@export var speed_percent: float = 0.0
## スタミナ最大値加算（固定値）
@export var stamina_flat: float = 0.0
## 採取速度増加（%）
@export var gather_percent: float = 0.0


## 装備品カテゴリを返す
func get_category() -> Category:
	return Category.EQUIPMENT
