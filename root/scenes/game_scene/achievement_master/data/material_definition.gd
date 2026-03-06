## 素材アイテム1件の定義データ（木材・金・肉など）
## 既存の ResourceDefinitions.ResourceType と紐づけて採取・ドロップシステムと連携する
class_name MaterialDefinition
extends ItemDefinition

## 対応する既存リソース種別（採取・ドロップとの紐づけ）
@export var resource_type: ResourceDefinitions.ResourceType = ResourceDefinitions.ResourceType.WOOD


## 素材カテゴリを返す
func get_category() -> Category:
	return Category.MATERIAL
