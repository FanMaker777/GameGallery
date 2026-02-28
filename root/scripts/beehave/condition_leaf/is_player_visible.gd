## プレイヤーが探知範囲内に存在するかを判定する Beehave 条件リーフ
class_name IsPlayerVisible
extends ConditionLeaf

## プレイヤーノードのキャッシュ
var player: Node2D = null

## 毎 tick 呼ばれる — プレイヤーが探知範囲内なら位置を blackboard に保存して SUCCESS を返す
func tick(actor: Node, blackboard: Blackboard) -> int:
	# プレイヤーが探知範囲内に存在するかの判定を blackboard から取得
	var is_visible: bool = blackboard.get_value(BlackBordValue.IS_PLAYER_VISIBLE)
	# プレイヤーが探知範囲内に存在しない場合
	if not is_visible:
		return FAILURE

	# シーンツリーからプレイヤーノードの参照を取得
	player = get_tree().get_first_node_in_group("player")
	# プレイヤーが存在しないか無効な場合は FAILURE を返す
	if not is_instance_valid(player):
		return FAILURE

	# プレイヤーが探知範囲内にいる場合、位置を blackboard に保存
	blackboard.set_value(BlackBordValue.PLAYER_POSITION, player.global_position)
	return SUCCESS
