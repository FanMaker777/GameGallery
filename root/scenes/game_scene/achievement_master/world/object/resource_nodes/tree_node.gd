## 木のリソースノード — 採取すると切り株に変わり、時間で再生する
class_name WoodTreeNode extends ResourceNode

## 木（採取可能）アニメーション名のプレフィックス
const _TREE_PREFIX: String = "Tree"
## 切り株（枯渇）アニメーション名のプレフィックス
const _STUMP_PREFIX: String = "Stump"

## 木のアニメーションスプライト
@onready var _animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


## ノードキーを設定して基底クラスの初期化を呼ぶ
func _ready() -> void:
	node_key = "tree"
	super._ready()


## 枯渇状態に応じて木と切り株のアニメーションを切り替える
func _update_visual() -> void:
	if _animated_sprite == null:
		return
	# 現在のアニメーション名からバリアント番号のサフィックスを取得する
	var suffix: String = _get_variant_suffix(_animated_sprite.animation)
	if is_depleted:
		# 枯渇時は切り株アニメーションに切り替える
		_animated_sprite.play(_STUMP_PREFIX + suffix)
	else:
		# 通常時は木のアニメーションに切り替える
		_animated_sprite.play(_TREE_PREFIX + suffix)


## アニメーション名から "_2" や "_3" 等のバリアントサフィックスを抽出する
func _get_variant_suffix(anim_name: String) -> String:
	# Tree_2 → "_2", Tree → "", Stump_3 → "_3"
	for prefix: String in [_TREE_PREFIX, _STUMP_PREFIX]:
		if anim_name.begins_with(prefix):
			return anim_name.substr(prefix.length())
	# 不明なアニメーション名の場合は空文字（デフォルトバリアント）
	Log.info("WoodTreeNode: 不明なアニメーション名 [%s]" % anim_name)
	return ""
