## 可変幅の足場プラットフォームの基底クラス
## スプライトとコリジョンの幅を連動して管理する
@tool
class_name Platform extends AnimatableBody2D

# ---- エクスポート変数 ----
## 足場の幅（ピクセル単位、16刻み）
@export_range(32.0, 512.0, 16.0) var width := 128.0: set = set_width

# ---- ノード参照 ----
## コリジョン形状ノード
@onready var _collision_shape_2d: CollisionShape2D = %CollisionShape2D
## コリジョンの矩形シェイプ
@onready var _shape: RectangleShape2D = _collision_shape_2d.shape
## 足場の見た目（NinePatchRect）
@onready var _sprite: NinePatchRect = %Sprite


## 初期化処理（幅を適用する）
func _ready() -> void:
	set_width(width)


## 幅を設定し、コリジョンとスプライトのサイズを同期する
func set_width(value: float) -> void:
	width = value
	if not is_inside_tree():
		return
	_shape.size.x = width
	_sprite.position.x = -width / 2.0
	_sprite.size.x = width
