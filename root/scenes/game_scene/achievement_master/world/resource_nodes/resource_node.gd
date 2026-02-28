## 採取可能なリソースノードの基底クラス
## Pawn が InteractArea で検知し、interact キーで採取する
class_name ResourceNode extends StaticBody2D

## 採取完了時に発火する（AchievementManager 連携用）
signal resource_harvested(resource_type: int, node_key: String)

## ResourceDefinitions.NODE_DATA のキーと一致させる
@export var node_key: String = "tree"

## 採取済みかどうか
var is_depleted: bool = false

var _node_data: Dictionary = {}


func _ready() -> void:
	add_to_group("resource_node")
	_node_data = ResourceDefinitions.NODE_DATA.get(node_key, {})
	_update_visual()


## Pawn が採取前に呼ぶ — アニメーション種別や時間を返す
func get_gather_data() -> Dictionary:
	if is_depleted:
		return {}
	return _node_data.duplicate()


## Pawn が採取完了時に呼ぶ — リソース種別と量を返す
func harvest() -> Dictionary:
	if is_depleted:
		return {}
	is_depleted = true
	_update_visual()
	resource_harvested.emit(_node_data.get("resource_type"), node_key)
	Log.info("ResourceNode: 採取完了 [%s]" % node_key)
	# リスポーンタイマーを開始する（respawn_time が設定されている場合のみ）
	var respawn_time: float = _node_data.get("respawn_time", 0.0)
	if respawn_time > 0.0:
		get_tree().create_timer(respawn_time).timeout.connect(_respawn)
	return {
		"type": _node_data.get("resource_type"),
		"amount": _node_data.get("yield_amount", 1),
	}


## サブクラスでオーバーライドして枯渇/復活時の外観を変更する
func _update_visual() -> void:
	pass


## リスポーン処理 — 枯渇状態を解除して外観を復活に切り替える
func _respawn() -> void:
	is_depleted = false
	_update_visual()
	Log.info("ResourceNode: リスポーン [%s]" % node_key)
