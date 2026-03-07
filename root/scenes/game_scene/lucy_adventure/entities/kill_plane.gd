## 落下死判定用の無限平面エリアを生成・管理する
## プレイヤーが接触すると死亡処理を呼び出す
@tool
class_name KillPlane2D extends Area2D


## 初期化処理（無限判定エリアを生成し、プレイヤー接触時の死亡処理を接続する）
func _ready() -> void:
	# Nothing can detect this area, it is only for killing players.
	collision_layer = 0
	collision_mask = 1
	monitoring = true

	# Create a collision shape with a world boundary shape to create an infinite
	# detection area at the node's position.
	var collision_shape := CollisionShape2D.new()
	var shape := WorldBoundaryShape2D.new()
	collision_shape.shape = shape
	add_child(collision_shape)

	# The collision mask is set to 1 so that only the player can trigger this call.
	body_entered.connect(func _on_body_entered(body: Node) -> void:
		if body is Player:
			body.die()
	)
