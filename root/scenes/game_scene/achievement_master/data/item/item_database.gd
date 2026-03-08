## 全アイテム定義を格納するコンテナリソース
## 基底型 Array[ItemDefinition] で装備品・消耗品・素材を統一管理する
class_name ItemDatabase
extends Resource

## 全アイテム定義の配列（Inspector でサブクラスを選択して追加可能）
@export var items: Array[ItemDefinition] = []
