## 【Beehave】プレイヤーを攻撃するアクションリーフ
## 攻撃アニメーション完了を待ってからSUCCESSを返す。攻撃中は移動を停止する。
class_name AttackPlayer
extends ActionLeaf

## 攻撃後のクールダウン時間（秒）
@export var attack_cooldown: float = 2.0

## 前回の攻撃からの経過時間
var _time_since_last_attack: float = INF
## 攻撃アニメーション再生中フラグ
var _is_attacking: bool = false

func before_run(_actor: Node, blackboard: Blackboard) -> void:
	_is_attacking = false
	# 攻撃アニメーション完了フラグをリセット
	blackboard.set_value(BlackBordValue.ATTACK_ANIM_FINISHED, false)

func tick(actor: Node, blackboard: Blackboard) -> int:
	# 攻撃中は移動を停止
	actor.velocity = Vector2.ZERO

	# 攻撃アニメーション再生中 → 完了を待つ
	if _is_attacking:
		var anim_finished: bool = blackboard.get_value(
			BlackBordValue.ATTACK_ANIM_FINISHED, false
		)
		if anim_finished:
			# 攻撃アニメーション完了 → クールダウン開始
			_is_attacking = false
			_time_since_last_attack = 0.0
			return SUCCESS
		# アニメーション完了待ち
		blackboard.set_value(BlackBordValue.DESIRED_ANIM_STATE, "Attack")
		return RUNNING

	# クールダウン中
	if _time_since_last_attack < attack_cooldown:
		_time_since_last_attack += get_physics_process_delta_time()
		blackboard.set_value(BlackBordValue.DESIRED_ANIM_STATE, "Idle")
		return RUNNING

	# クールダウン完了 → 攻撃開始
	_is_attacking = true
	blackboard.set_value(BlackBordValue.ATTACK_ANIM_FINISHED, false)
	blackboard.set_value(BlackBordValue.DESIRED_ANIM_STATE, "Attack")
	Log.debug("攻撃開始!")
	return RUNNING
