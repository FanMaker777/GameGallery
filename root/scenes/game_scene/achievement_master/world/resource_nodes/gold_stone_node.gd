## 金鉱石のリソースノード — 採取するとハイライトが消え、時間で復活する
class_name GoldStoneNode extends ResourceNode

## ハイライト（採取可能）アニメーション名のプレフィックス
const _HIGHLIGHT_PREFIX: String = "HighLight"
## アイドル（枯渇）アニメーション名のプレフィックス
const _IDLE_PREFIX: String = "Idle"

## 金鉱石のアニメーションスプライト
@onready var _animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


## ノードキーを設定して基底クラスの初期化を呼ぶ
func _ready() -> void:
	node_key = "gold_stone"
	super._ready()


## 枯渇状態に応じてアニメーションを切り替える
func _update_visual() -> void:
	if _animated_sprite == null:
		return
	# 現在のアニメーション名からバリアント番号のサフィックスを取得する
	var suffix: String = _get_variant_suffix(_animated_sprite.animation)
	if is_depleted:
		# 枯渇時は静止した Idle アニメーションに切り替える
		_animated_sprite.play(_IDLE_PREFIX + suffix)
	else:
		# 通常時はキラキラ光る HighLight アニメーションに切り替える
		_animated_sprite.play(_HIGHLIGHT_PREFIX + suffix)


## アニメーション名から "_2" や "_3" 等のバリアントサフィックスを抽出する
func _get_variant_suffix(anim_name: String) -> String:
	# HighLight_2 → "_2", HighLight → "", Idle_3 → "_3"
	for prefix: String in [_HIGHLIGHT_PREFIX, _IDLE_PREFIX]:
		if anim_name.begins_with(prefix):
			return anim_name.substr(prefix.length())
	# 不明なアニメーション名の場合は空文字（デフォルトバリアント）
	Log.info("GoldStoneNode: 不明なアニメーション名 [%s]" % anim_name)
	return ""
