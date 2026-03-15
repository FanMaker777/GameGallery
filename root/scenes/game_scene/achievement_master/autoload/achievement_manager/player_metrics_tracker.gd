## プレイ時間・歩行距離・NPC会話クールダウンの追跡を担当する
class_name PlayerMetricsTracker
extends Node

## NPC会話のクールダウン時間（秒）
const NPC_TALK_COOLDOWN: float = 30.0
## ピクセル→メートル換算係数（64pxタイル = 2m 基準）
const PIXELS_PER_METER: float = 32.0
## 歩行距離の記録間隔（メートル）
const DISTANCE_RECORD_INTERVAL_M: float = 10.0
## 記録閾値のピクセル換算値
var _record_threshold_px: float = DISTANCE_RECORD_INTERVAL_M * PIXELS_PER_METER

@onready var _tracker: AchievementTracker = %AchievementTracker

## NPC会話クールダウン { npc_id: last_time_msec }
var _npc_talk_cooldowns: Dictionary = {}
## 登録されたプレイヤーノード
var _player: Node = null
## 前フレームのプレイヤー位置（歩行距離計算用）
var _previous_player_pos: Vector2 = Vector2.ZERO
## 歩行距離の累積ピクセル（_record_threshold_px に達したら record）
var _distance_accumulator: float = 0.0
## プレイ時間の累積（1秒ごとに record）
var _play_time_accumulator: float = 0.0


func _process(delta: float) -> void:
	# プレイ時間を追跡する
	_play_time_accumulator += delta
	if _play_time_accumulator >= 1.0:
		_play_time_accumulator -= 1.0
		_tracker.add_play_time(1.0)
	# プレイヤーの歩行距離を追跡する
	if _player != null and is_instance_valid(_player):
		var current_pos: Vector2 = _player.global_position
		if _previous_player_pos != Vector2.ZERO:
			var moved: float = current_pos.distance_to(_previous_player_pos)
			if moved > 0.1 and moved < 500.0:  # テレポート除外
				_distance_accumulator += moved
				# 一定距離ごとに record_action を呼ぶ
				while _distance_accumulator >= _record_threshold_px:
					_distance_accumulator -= _record_threshold_px
					_tracker.record_action(&"distance_walked", {&"amount": int(DISTANCE_RECORD_INTERVAL_M)})
		_previous_player_pos = current_pos


## プレイヤーノードを登録し、距離追跡を初期化する
func register_player(player: Node) -> void:
	_player = player
	_previous_player_pos = player.global_position
	_distance_accumulator = 0.0


## NPCに話しかけたとき（クールダウンチェック付き）
func _on_npc_interacted(npc_id: String) -> void:
	# クールダウンチェック（同一NPC連打防止）
	var now: int = Time.get_ticks_msec()
	var last_time: int = _npc_talk_cooldowns.get(npc_id, 0)
	if now - last_time < int(NPC_TALK_COOLDOWN * 1000.0):
		Log.debug("PlayerMetricsTracker: NPC会話クールダウン中 [%s]" % npc_id)
		return
	_npc_talk_cooldowns[npc_id] = now
	_tracker.record_action(&"npc_talked", {&"instance_id": npc_id})
