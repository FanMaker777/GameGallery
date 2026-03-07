## レコードデータの蓄積・照会・永続化を担当する Resource
## 実績の状態（解除/ピン留め）は持たない — 生データのみを管理する
class_name RecordDatabase extends Resource

## ---- 戦闘 ----
@export var enemy_killed: int = 0                    ## 敵討伐数
@export var enemy_killed_by_type: Dictionary = {}    ## 敵種別ごとの討伐数 {String: int}
@export var attack_landed: int = 0                   ## 攻撃命中回数
@export var attack_started: int = 0                  ## 攻撃開始回数
@export var player_damaged: int = 0                  ## プレイヤー被弾回数
@export var player_died: int = 0                     ## プレイヤー死亡回数

## ---- 採取 ----
@export var resource_harvested: int = 0              ## 採取総数
@export var resource_harvested_wood: int = 0         ## 木材の採取数
@export var resource_harvested_gold: int = 0         ## 金の採取数
@export var resource_harvested_meat: int = 0         ## 肉の採取数

## ---- 探索 ----
@export var map_entered: int = 0                     ## マップ遷移回数
@export var unique_maps_entered: Array = []          ## 訪問済みマップ一覧 [String]（有限）
@export var distance_walked: int = 0                 ## 歩行距離
@export var npc_talked: int = 0                      ## NPC会話回数
@export var unique_npcs_talked: Array = []           ## 会話済みNPC一覧 [String]（有限）

## ---- 実績 ----
@export var achievement_unlocked: int = 0            ## 実績解除数
@export var ap_earned: int = 0                       ## 獲得APの累計

## ---- プレイ時間 ----
@export var play_time_seconds: float = 0.0           ## 累積プレイ時間（秒）

## ---- ストリーク ----
@export var streak_enemy_killed_no_damage: int = 0   ## 被弾なし連続討伐数（enemy_killed:player_damaged）
@export var streak_enemy_killed_rapid: int = 0       ## 60秒以内の連続討伐数（enemy_killed:timer_60）
@export var streak_harvest_no_attack: int = 0        ## 攻撃なし連続採取数（resource_harvested:attack_started）
@export var streak_map_no_damage: int = 0            ## 被弾なし連続マップ遷移数（map_entered:player_damaged）
@export var streak_npc_no_kill: int = 0              ## 討伐なし連続NPC会話数（npc_talked:enemy_killed）

# ---- 内部マッピング定数 ----

## カウント可能なアクション一覧（プロパティ名と一致）
const _KNOWN_ACTIONS: Array[StringName] = [
	&"enemy_killed", &"npc_talked", &"resource_harvested",
	&"resource_harvested_wood", &"resource_harvested_gold", &"resource_harvested_meat",
	&"map_entered", &"attack_landed", &"attack_started",
	&"player_damaged", &"player_died", &"distance_walked",
	&"achievement_unlocked", &"ap_earned",
]

## アクション名 → ユニークセットプロパティ名（有限個数のもののみ）
const _UNIQUE_PROPS: Dictionary = {
	&"map_entered": &"unique_maps_entered",
	&"npc_talked": &"unique_npcs_talked",
}

## アクション名 → 型名別内訳プロパティ名
const _TYPE_PROPS: Dictionary = {
	&"enemy_killed": &"enemy_killed_by_type",
}

## "trigger:reset_on" → ストリークプロパティ名
const _STREAK_PROPS: Dictionary = {
	"enemy_killed:player_damaged": &"streak_enemy_killed_no_damage",
	"enemy_killed:timer_60": &"streak_enemy_killed_rapid",
	"resource_harvested:attack_started": &"streak_harvest_no_attack",
	"map_entered:player_damaged": &"streak_map_no_damage",
	"npc_talked:enemy_killed": &"streak_npc_no_kill",
}

## reset_on → リセット対象ストリークプロパティ名リスト
const _STREAKS_BY_RESET: Dictionary = {
	&"player_damaged": [&"streak_enemy_killed_no_damage", &"streak_map_no_damage"],
	&"timer_60": [&"streak_enemy_killed_rapid"],
	&"attack_started": [&"streak_harvest_no_attack"],
	&"enemy_killed": [&"streak_npc_no_kill"],
}


# ========== 記録 API ==========

## アクションを記録する
## _KNOWN_ACTIONS に登録されたアクション名を受け取り、以下の3種類の更新を行う:
##   1. カウント加算 — アクション名と同名のプロパティに amount を加算
##   2. 型名別内訳   — context に type_name があり、_TYPE_PROPS に対応がある場合のみ内訳を更新
##   3. ユニークセット — context に instance_id があり、_UNIQUE_PROPS に対応がある場合のみ配列に追加
## [br]
## context の任意キー:
##   - &"amount"      : int — 加算量（省略時 1）
##   - &"type_name"   : String — 型名別内訳のキー（例: 敵種別名 "Skull"）
##   - &"instance_id" : String — ユニークセットに登録する識別子（例: マップパス、NPC名）
func record(action: StringName, context: Dictionary = {}) -> void:
	# 未登録アクションは警告を出して無視する
	if action not in _KNOWN_ACTIONS:
		Log.warn("RecordDatabase: 未知のアクション — %s" % String(action))
		return
	# context から加算量を取得（省略時は 1）
	var amount: int = context.get(&"amount", 1)
	# アクション名と同名のプロパティ（例: enemy_killed）に amount を加算する
	set(action, get(action) + amount)
	# _TYPE_PROPS に対応があるアクションのみ、型名別の内訳辞書を更新する
	# 例: enemy_killed → enemy_killed_by_type["Skull"] += amount
	var type_name: String = context.get(&"type_name", "")
	if not type_name.is_empty() and _TYPE_PROPS.has(action):
		var prop: StringName = _TYPE_PROPS[action]
		var type_dict: Dictionary = get(prop)
		type_dict[type_name] = type_dict.get(type_name, 0) + amount
	# _UNIQUE_PROPS に対応があるアクションのみ、ユニーク配列に instance_id を追加する
	# 例: map_entered → unique_maps_entered に未登録のマップパスを追加
	var instance_id: String = context.get(&"instance_id", "")
	if not instance_id.is_empty() and _UNIQUE_PROPS.has(action):
		var prop: StringName = _UNIQUE_PROPS[action]
		var arr: Array = get(prop)
		# 重複しないよう、未登録の場合のみ追加する
		if instance_id not in arr:
			arr.append(instance_id)


## 累積カウントを返す
func get_count(action: StringName) -> int:
	if action not in _KNOWN_ACTIONS:
		return 0
	return get(action)


## 型名別内訳を返す
func get_counts_by_type(action: StringName) -> Dictionary:
	if not _TYPE_PROPS.has(action):
		return {}
	return get(_TYPE_PROPS[action])


## ユニークインスタンス数を返す
func get_unique_count(action: StringName) -> int:
	if not _UNIQUE_PROPS.has(action):
		return 0
	var arr: Array = get(_UNIQUE_PROPS[action])
	return arr.size()


# ========== ストリーク API ==========

## ストリークを加算する
func increment_streak(trigger: StringName, reset_on: StringName, amount: int = 1) -> void:
	var key: String = "%s:%s" % [String(trigger), String(reset_on)]
	if not _STREAK_PROPS.has(key):
		Log.warn("RecordDatabase: 未知のストリーク — %s" % key)
		return
	var prop: StringName = _STREAK_PROPS[key]
	set(prop, get(prop) + amount)


## 現在のストリークを返す
func get_streak(trigger: StringName, reset_on: StringName) -> int:
	var key: String = "%s:%s" % [String(trigger), String(reset_on)]
	if not _STREAK_PROPS.has(key):
		return 0
	return get(_STREAK_PROPS[key])


## 指定 reset_on に該当するストリークを全てリセットする
func reset_streaks_by_reset_on(reset_on: StringName) -> void:
	if not _STREAKS_BY_RESET.has(reset_on):
		return
	for prop: StringName in _STREAKS_BY_RESET[reset_on]:
		set(prop, 0)


# ========== プレイ時間 ==========

## プレイ時間を加算する
func add_play_time(seconds: float) -> void:
	play_time_seconds += seconds


# ========== リセット ==========

## 全レコードを初期値にリセットし、ファイルに保存する
func reset_all() -> void:
	# 戦闘
	enemy_killed = 0
	enemy_killed_by_type = {}
	attack_landed = 0
	attack_started = 0
	player_damaged = 0
	player_died = 0
	# 採取
	resource_harvested = 0
	resource_harvested_wood = 0
	resource_harvested_gold = 0
	resource_harvested_meat = 0
	# 探索
	map_entered = 0
	unique_maps_entered = []
	distance_walked = 0
	npc_talked = 0
	unique_npcs_talked = []
	# 実績
	achievement_unlocked = 0
	ap_earned = 0
	# プレイ時間
	play_time_seconds = 0.0
	# ストリーク
	streak_enemy_killed_no_damage = 0
	streak_enemy_killed_rapid = 0
	streak_harvest_no_attack = 0
	streak_map_no_damage = 0
	streak_npc_no_kill = 0
	Log.info("RecordDatabase: 全レコードをリセットしました")


# ========== セーブ/ロード（SaveManager から呼ばれる） ==========

## 全 @export フィールドの値を Dictionary で返す
func get_save_data() -> Dictionary:
	return {
		"enemy_killed": enemy_killed,
		"enemy_killed_by_type": enemy_killed_by_type.duplicate(),
		"attack_landed": attack_landed,
		"attack_started": attack_started,
		"player_damaged": player_damaged,
		"player_died": player_died,
		"resource_harvested": resource_harvested,
		"resource_harvested_wood": resource_harvested_wood,
		"resource_harvested_gold": resource_harvested_gold,
		"resource_harvested_meat": resource_harvested_meat,
		"map_entered": map_entered,
		"unique_maps_entered": unique_maps_entered.duplicate(),
		"distance_walked": distance_walked,
		"npc_talked": npc_talked,
		"unique_npcs_talked": unique_npcs_talked.duplicate(),
		"achievement_unlocked": achievement_unlocked,
		"ap_earned": ap_earned,
		"play_time_seconds": play_time_seconds,
		"streak_enemy_killed_no_damage": streak_enemy_killed_no_damage,
		"streak_enemy_killed_rapid": streak_enemy_killed_rapid,
		"streak_harvest_no_attack": streak_harvest_no_attack,
		"streak_map_no_damage": streak_map_no_damage,
		"streak_npc_no_kill": streak_npc_no_kill,
	}


## Dictionary から全フィールドを復元する
func load_save_data(data: Dictionary) -> void:
	enemy_killed = int(data.get("enemy_killed", 0))
	enemy_killed_by_type = data.get("enemy_killed_by_type", {})
	attack_landed = int(data.get("attack_landed", 0))
	attack_started = int(data.get("attack_started", 0))
	player_damaged = int(data.get("player_damaged", 0))
	player_died = int(data.get("player_died", 0))
	resource_harvested = int(data.get("resource_harvested", 0))
	resource_harvested_wood = int(data.get("resource_harvested_wood", 0))
	resource_harvested_gold = int(data.get("resource_harvested_gold", 0))
	resource_harvested_meat = int(data.get("resource_harvested_meat", 0))
	map_entered = int(data.get("map_entered", 0))
	unique_maps_entered = Array(data.get("unique_maps_entered", []))
	distance_walked = int(data.get("distance_walked", 0))
	npc_talked = int(data.get("npc_talked", 0))
	unique_npcs_talked = Array(data.get("unique_npcs_talked", []))
	achievement_unlocked = int(data.get("achievement_unlocked", 0))
	ap_earned = int(data.get("ap_earned", 0))
	play_time_seconds = float(data.get("play_time_seconds", 0.0))
	streak_enemy_killed_no_damage = int(data.get("streak_enemy_killed_no_damage", 0))
	streak_enemy_killed_rapid = int(data.get("streak_enemy_killed_rapid", 0))
	streak_harvest_no_attack = int(data.get("streak_harvest_no_attack", 0))
	streak_map_no_damage = int(data.get("streak_map_no_damage", 0))
	streak_npc_no_kill = int(data.get("streak_npc_no_kill", 0))
	Log.info("RecordDatabase: ロード完了")
