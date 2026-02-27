class_name IsPlayerVisible
extends ConditionLeaf

var player = null

func tick(actor: Node, blackboard: Blackboard) -> int:
	# プレイヤーが探知範囲内に存在するかの判定をblackboardから取得
	var is_player_visible = blackboard.get_value(BlackBordValue.IS_PLAYER_VISIBLE)
	# プレイヤーが探知範囲内に存在しない場合
	if not is_player_visible:
		# Log.debug("探知範囲内にプレイヤーがいませんでした")
		return FAILURE
	
	# シーンツリーからプレイヤーノードの参照を取得
	player = get_tree().get_first_node_in_group("player")
	
	# Player is visible, save position in blackboard
	blackboard.set_value(BlackBordValue.PLAYER_POSITION, player.global_position)
	return SUCCESS
