## 採取可能なリソースノードの基底クラス
## Player が InteractArea で検知し、interact キーで採取する
class_name ResourceNode extends StaticBody2D

## 採取完了時に発火する（AchievementManager 連携用）
signal resource_harvested(resource_type: int, node_key: String)

## ResourceDefinitions.NODE_DATA のキーと一致させる
@export var node_key: String = "tree"

## 採取済みかどうか
var is_depleted: bool = false

var _node_data: Dictionary = {}


func _ready() -> void:
	add_to_group("resource_node")
	_node_data = ResourceDefinitions.NODE_DATA.get(node_key, {})
	_update_visual()


## Player が採取前に呼ぶ — アニメーション種別や時間を返す
func get_gather_data() -> Dictionary:
	if is_depleted:
		return {}
	return _node_data.duplicate()


## Player が採取完了時に呼ぶ — リソース種別と量を返す
func harvest() -> Dictionary:
	if is_depleted:
		return {}
	is_depleted = true
	_update_visual()
	_play_harvest_effect()
	resource_harvested.emit(_node_data.get("resource_type"), node_key)
	Log.info("ResourceNode: 採取完了 [%s]" % node_key)
	# リスポーンタイマーを開始する（respawn_time が設定されている場合のみ）
	var respawn_time: float = _node_data.get("respawn_time", 0.0)
	if respawn_time > 0.0:
		get_tree().create_timer(respawn_time).timeout.connect(_respawn)
	return {
		"type": _node_data.get("resource_type"),
		"amount": _node_data.get("yield_amount", 1),
	}


## サブクラスでオーバーライドして枯渇/復活時の外観を変更する
func _update_visual() -> void:
	pass


## 採取完了時の白フラッシュ + パーティクルエフェクトを再生する
func _play_harvest_effect() -> void:
	# 白フラッシュ
	var original_modulate: Color = modulate
	modulate = Color(2.0, 2.0, 2.0, 1.0)
	var flash_tween: Tween = create_tween()
	flash_tween.tween_property(self, "modulate", original_modulate, 0.1)
	# パーティクル（動的生成、one_shot、0.5s後に自動削除）
	var particles: GPUParticles2D = GPUParticles2D.new()
	particles.one_shot = true
	particles.amount = 8
	particles.lifetime = 0.3
	var mat: ParticleProcessMaterial = ParticleProcessMaterial.new()
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 45.0
	mat.initial_velocity_min = 30.0
	mat.initial_velocity_max = 60.0
	mat.gravity = Vector3(0, 98, 0)
	mat.scale_min = 2.0
	mat.scale_max = 4.0
	mat.color = Color(1.0, 1.0, 0.8, 0.8)
	particles.process_material = mat
	add_child(particles)
	particles.emitting = true
	get_tree().create_timer(0.5).timeout.connect(particles.queue_free)


## リスポーン処理 — 枯渇状態を解除して外観を復活に切り替える
func _respawn() -> void:
	is_depleted = false
	_update_visual()
	Log.info("ResourceNode: リスポーン [%s]" % node_key)
