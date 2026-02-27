## 採取可能なリソースの種類・量・アニメーション等を定義するデータクラス
class_name ResourceDefinitions


## リソースの種類
enum ResourceType {
	WOOD,
	GOLD,
	MEAT,
}


## リソースノードごとの設定データ
## key は各リソースノードの node_key と一致させる
const NODE_DATA: Dictionary = {
	"tree": {
		"resource_type": ResourceType.WOOD,
		"yield_amount": 3,
		"gather_animation": "HarvestTree",
		"gather_time": 0.6,
		"respawn_time": 30.0,
	},
	"gold_stone": {
		"resource_type": ResourceType.GOLD,
		"yield_amount": 2,
		"gather_animation": "HarvestGold",
		"gather_time": 0.3,
		"respawn_time": 45.0,
	},
	"sheep": {
		"resource_type": ResourceType.MEAT,
		"yield_amount": 1,
		"gather_animation": "HarvestSheep",
		"gather_time": 0.6,
		"respawn_time": 20.0,
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
		_:
			return "Unknown"
