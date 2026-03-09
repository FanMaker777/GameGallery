## 統合型HUD — HP・スタミナ表示、ピン留め実績パネル枠、トースト通知を一元管理する
class_name AchievementHud extends CanvasLayer

# ---- ノードキャッシュ ----
## HPバー
@onready var _hp_bar: ProgressBar = %HpBar
## スタミナバー
@onready var _stamina_bar: ProgressBar = %StaminaBar
## HP実数値ラベル
@onready var _hp_value_label: Label = %HpValueLabel
## スタミナ実数値ラベル
@onready var _stamina_value_label: Label = %StaminaValueLabel
# ---- 状態 ----
## Player への参照キャッシュ（毎回検索しない）
var _player: Node = null


## 初期化 — Player へのシグナル接続を遅延実行する
func _ready() -> void:
	# Player が先に _ready される保証がないため遅延接続する
	_connect_to_player.call_deferred()


## Player のシグナルを購読し、参照をキャッシュする
func _connect_to_player() -> void:
	_player = get_tree().get_first_node_in_group("player")
	if _player == null:
		Log.debug("AchievementHud: グループ 'player' に Player が見つからない")
		return
	# HP変化シグナルを接続
	if _player.has_signal("health_changed"):
		_player.health_changed.connect(_on_health_changed)
	# スタミナ変化シグナルを接続
	if _player.has_signal("stamina_changed"):
		_player.stamina_changed.connect(_on_stamina_changed)
	# 全表示を最新化する
	_refresh_all()
	Log.info("AchievementHud: Player に接続完了")


## HP変化時にHPバーと実数値ラベルを更新する
func _on_health_changed(current_hp: int, max_hp: int) -> void:
	_hp_bar.max_value = max_hp
	_hp_bar.value = current_hp
	_hp_value_label.text = "%d/%d" % [current_hp, max_hp]


## スタミナ変化時にスタミナバーと実数値ラベルを更新する
func _on_stamina_changed(current_stamina: float, p_max_stamina: float) -> void:
	_stamina_bar.max_value = p_max_stamina
	_stamina_bar.value = current_stamina
	_stamina_value_label.text = "%d/%d" % [int(current_stamina), int(p_max_stamina)]


## HP・スタミナ表示を初期値で更新する
func _refresh_all() -> void:
	if _player == null:
		return
	# 装備・スキル補正後の実効最大値を計算する
	var ec: EquipmentStatCache = InventoryManager.get_equip_cache()
	var sc: SkillEffectCache = SkillManager.get_effect_cache()
	# HP の初期化
	var max_hp: int = AmPlayerStatCalculator.get_effective_max_hp(ec, sc)
	_hp_bar.max_value = max_hp
	_hp_bar.value = _player.hp
	_hp_value_label.text = "%d/%d" % [_player.hp, max_hp]
	# スタミナの初期化
	var max_st: float = AmPlayerStatCalculator.get_effective_max_stamina(ec, sc)
	_stamina_bar.max_value = max_st
	_stamina_bar.value = _player.stamina
	_stamina_value_label.text = "%d/%d" % [int(_player.stamina), int(max_st)]
