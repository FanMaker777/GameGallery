## ヘルプタブ — ポーズメニュー内の操作ガイド表示
class_name HelpTab extends MarginContainer

@onready var _content_container: VBoxContainer = %ContentContainer

## コンテンツ構築済みフラグ（遅延初期化用）
var _is_built: bool = false


func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)


## タブが表示されたときにコンテンツを構築する
func _on_visibility_changed() -> void:
	if visible and not _is_built:
		_is_built = true
		HelpContentBuilder.build_content(_content_container)
