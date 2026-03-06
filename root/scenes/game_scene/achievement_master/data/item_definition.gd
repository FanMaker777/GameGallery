## 全アイテム共通のフィールドを定義する基底リソースクラス
## 装備品・消耗品・素材の3サブクラスがこのクラスを継承する
class_name ItemDefinition
extends Resource

## アイテムカテゴリ
enum Category { EQUIPMENT, CONSUMABLE, MATERIAL }

## アイテムの一意識別子
@export var id: StringName = &""
## 表示名（日本語）
@export var name_ja: String = ""
## 説明文（日本語）
@export var description_ja: String = ""

@export_group("経済")
## 購入価格（GOLD）
@export var buy_price: int = 0
## 売却価格（GOLD）
@export var sell_price: int = 0

@export_group("スタック")
## 最大スタック数（装備品は1、消耗品は10、素材は999等）
@export var max_stack: int = 1


## カテゴリを返す（サブクラスでオーバーライドする）
func get_category() -> Category:
	return Category.MATERIAL
