## 薬草のリソースノード — 採取すると刈り取られた状態になり、時間で復活する
class_name HerbNode extends ResourceNode

## 通常（採取可能）アニメーション名
const _ALIVE_ANIM: String = "Alive"
## 枯渇（採取済み）アニメーション名
const _DEPLETED_ANIM: String = "Depleted"

## 薬草のアニメーションスプライト
@onready var _animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


## ノードキーを設定して基底クラスの初期化を呼ぶ
func _ready() -> void:
	node_key = "herb"
	super._ready()


## 枯渇状態に応じてアニメーションを切り替える
func _update_visual() -> void:
	if _animated_sprite == null:
		return
	if is_depleted:
		_animated_sprite.play(_DEPLETED_ANIM)
	else:
		_animated_sprite.play(_ALIVE_ANIM)
