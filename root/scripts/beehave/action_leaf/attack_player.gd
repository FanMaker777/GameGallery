## 【Beehave】プレイヤーを攻撃するアクションリーフ
## 攻撃アニメーション完了を待ち、範囲内のプレイヤーにダメージを与えてSUCCESSを返す
class_name AttackPlayer
extends ActionLeaf

## 攻撃後のクールダウン時間（秒）
@export var attack_cooldown: float = 2.0

## 前回の攻撃からの経過時間
var _time_since_last_attack: float = INF
## 攻撃アニメーション再生中フラグ
var _is_attacking: bool = false
## 攻撃ダメージが既に適用されたかどうか（同一攻撃での二重ダメージ防止）
var _damage_dealt: bool = false


## 攻撃開始前にフラグをリセットする
func before_run(_actor: Node, blackboard: Blackboard) -> void:
	_is_attacking = false
	_damage_dealt = false
	# 攻撃アニメーション完了フラグをリセット
	blackboard.set_value(BlackBoardValue.ATTACK_ANIM_FINISHED, false)
	# ヒットフレーム到達フラグをリセット
	blackboard.set_value(BlackBoardValue.ATTACK_HIT_FRAME_REACHED, false)


## 毎フレームの攻撃処理 — アニメーション管理とダメージ判定を行う
func tick(actor: Node, blackboard: Blackboard) -> int:
	# 攻撃中は移動を停止
	actor.velocity = Vector2.ZERO

	# 攻撃アニメーション再生中 → ヒットフレームでダメージ適用、アニメ完了でSUCCESS
	if _is_attacking:
		# ヒットフレーム到達時にダメージを適用する（アニメ完了を待たない）
		var hit_frame_reached: bool = blackboard.get_value(
			BlackBoardValue.ATTACK_HIT_FRAME_REACHED, false
		)
		if hit_frame_reached and not _damage_dealt:
			_apply_damage_to_player(actor, blackboard)

		# アニメーション完了で攻撃シーケンスを終了する
		var anim_finished: bool = blackboard.get_value(
			BlackBoardValue.ATTACK_ANIM_FINISHED, false
		)
		if anim_finished:
			# ブラックボードのフラグをリセットしてクールダウン開始
			blackboard.set_value(BlackBoardValue.ATTACK_HIT_FRAME_REACHED, false)
			_is_attacking = false
			_damage_dealt = false
			_time_since_last_attack = 0.0
			return SUCCESS
		# アニメーション完了待ち
		blackboard.set_value(BlackBoardValue.DESIRED_ANIM_STATE, "Attack")
		return RUNNING

	# クールダウン中は待機アニメーションで待つ
	if _time_since_last_attack < attack_cooldown:
		_time_since_last_attack += get_physics_process_delta_time()
		blackboard.set_value(BlackBoardValue.DESIRED_ANIM_STATE, "Idle")
		return RUNNING

	# クールダウン完了 → 攻撃開始
	_is_attacking = true
	_damage_dealt = false
	blackboard.set_value(BlackBoardValue.ATTACK_ANIM_FINISHED, false)
	blackboard.set_value(BlackBoardValue.ATTACK_HIT_FRAME_REACHED, false)
	blackboard.set_value(BlackBoardValue.DESIRED_ANIM_STATE, "Attack")
	Log.debug("攻撃開始!")
	return RUNNING


## 攻撃範囲内のプレイヤーにダメージを与える
func _apply_damage_to_player(actor: Node, blackboard: Blackboard) -> void:
	# プレイヤーを検索
	var player: Node2D = actor.get_tree().get_first_node_in_group("player")
	if player == null or not is_instance_valid(player):
		return
	# プレイヤーが既に死亡している場合はダメージを与えない
	if player.get("hp") != null and player.hp <= 0:
		return
	# 攻撃範囲内にいるか距離で判定する
	var attack_range: float = blackboard.get_value(BlackBoardValue.ATTACK_RANGE, 75.0)
	var distance: float = actor.global_position.distance_to(player.global_position)
	if distance > attack_range:
		return
	# プレイヤーにダメージを与える
	if player.has_method("take_damage"):
		var damage: int = blackboard.get_value(BlackBoardValue.ATTACK_DAMAGE, 10)
		player.take_damage(damage)
		_damage_dealt = true
		Log.info("AttackPlayer: プレイヤーにダメージ %d (距離=%.0f)" % [damage, distance])
