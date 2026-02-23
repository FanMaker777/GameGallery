## 【Beehave】プレイヤーを攻撃するアクションリーフ
class_name AttackPlayer
extends ActionLeaf

@export var attack_cooldown: float = 3.0
var _time_since_last_attack: float = 0.0

@onready var _animated_sprite: AnimatedSprite2D = %AnimatedSprite

func tick(actor: Node, blackboard: Blackboard) -> int:
	# Check if cooldown has elapsed
	if _time_since_last_attack < attack_cooldown:
		_time_since_last_attack += get_physics_process_delta_time()
		#Log.debug("攻撃クールダウン", _time_since_last_attack)
		return RUNNING
	
	# Reset cooldown
	_time_since_last_attack = 0.0
	
	# Perform attack
	Log.debug("Enemy attacks player!")
	# In a real game, you might trigger an animation or spawn a projectile here
	_animated_sprite.play("Attack")
	
	return SUCCESS
