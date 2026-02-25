## 村の建物（衝突付き）— テクスチャを差し替えて再利用する
class_name Building extends StaticBody2D

@export var building_texture: Texture2D  ## Inspector からテクスチャ設定
@export var collision_size: Vector2 = Vector2(80, 40)  ## 建物底部の衝突サイズ
@export var collision_offset: Vector2 = Vector2(0, 0)  ## 衝突位置オフセット


func _ready() -> void:
	if building_texture:
		$Sprite2D.texture = building_texture
	var shape: RectangleShape2D = $CollisionShape2D.shape as RectangleShape2D
	if shape:
		shape = shape.duplicate()
		shape.size = collision_size
		$CollisionShape2D.shape = shape
	$CollisionShape2D.position = collision_offset
