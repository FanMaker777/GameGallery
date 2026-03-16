## 鉄鉱石のリソースノード — 採取すると暗転し、時間で復活する
class_name IronStoneNode extends ResourceNode

## 鉄鉱石のスプライト
@onready var _sprite: Sprite2D = $Sprite2D


## ノードキーを設定して基底クラスの初期化を呼ぶ
func _ready() -> void:
	node_key = "iron_stone"
	super._ready()


## 枯渇状態に応じてmodulateで表示を切り替える
func _update_visual() -> void:
	if _sprite == null:
		return
	if is_depleted:
		_sprite.modulate = Color(0.3, 0.3, 0.3, 1.0)
	else:
		_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
