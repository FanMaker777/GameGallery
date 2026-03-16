## 採取可能なリソースの種類・量・アニメーション等を定義するデータクラス
class_name ResourceDefinitions


## リソースの種類
enum ResourceType {
	WOOD,
	GOLD,
	MEAT,
	BERRY,
	HERB,
	MUSHROOM,
	IRON,
}


## リソースノードごとの設定データ
## key は各リソースノードの node_key と一致させる
const NODE_DATA: Dictionary = {
	"tree": {
		"resource_type": ResourceType.WOOD,
		"yield_amount": 3,
		"gather_animation": "HarvestTree",
		"gather_time": 5.0,
		"respawn_time": 30.0,
	},
	"gold_stone": {
		"resource_type": ResourceType.GOLD,
		"yield_amount": 2,
		"gather_animation": "HarvestGold",
		"gather_time": 10.0,
		"respawn_time": 45.0,
	},
	"sheep": {
		"resource_type": ResourceType.MEAT,
		"yield_amount": 1,
		"gather_animation": "HarvestSheep",
		"gather_time": 3.0,
		"respawn_time": 20.0,
	},
	"berry_bush": {
		"resource_type": ResourceType.BERRY,
		"yield_amount": 2,
		"gather_animation": "HarvestTree",
		"gather_time": 4.0,
		"respawn_time": 25.0,
	},
	"herb": {
		"resource_type": ResourceType.HERB,
		"yield_amount": 1,
		"gather_animation": "HarvestSheep",
		"gather_time": 2.0,
		"respawn_time": 35.0,
	},
	"mushroom": {
		"resource_type": ResourceType.MUSHROOM,
		"yield_amount": 2,
		"gather_animation": "HarvestSheep",
		"gather_time": 1.5,
		"respawn_time": 40.0,
	},
	"iron_stone": {
		"resource_type": ResourceType.IRON,
		"yield_amount": 2,
		"gather_animation": "HarvestGold",
		"gather_time": 8.0,
		"respawn_time": 40.0,
	},
}


## ResourceType を表示名に変換する
static func get_type_name(type: ResourceType) -> String:
	match type:
		ResourceType.WOOD:
			return "Wood"
		ResourceType.GOLD:
			return "Gold"
		ResourceType.MEAT:
			return "Meat"
		ResourceType.BERRY:
			return "Berry"
		ResourceType.HERB:
			return "Herb"
		ResourceType.MUSHROOM:
			return "Mushroom"
		ResourceType.IRON:
			return "Iron"
		_:
			return "Unknown"


## ResourceType を InventoryManager のアイテムIDに変換する
static func to_item_id(type: ResourceType) -> StringName:
	match type:
		ResourceType.WOOD:
			return &"wood"
		ResourceType.GOLD:
			return &"gold"
		ResourceType.MEAT:
			return &"meat"
		ResourceType.BERRY:
			return &"berry"
		ResourceType.HERB:
			return &"herb"
		ResourceType.MUSHROOM:
			return &"mushroom"
		ResourceType.IRON:
			return &"iron"
		_:
			return &""
