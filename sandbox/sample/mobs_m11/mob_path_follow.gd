class_name MobPathFollow extends PathFollow2D

var mob: Mob = null: set = set_mob


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if mob == null and get_child_count() > 0:
		set_mob(get_child(0))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	progress += mob.speed * delta

func set_mob(new_mob: Mob) -> void:
	mob = new_mob
	if mob != null:
		# Mobがシーンツリーから削除時、PathFollow2Dノードも削除
		mob.tree_exited.connect(queue_free)
