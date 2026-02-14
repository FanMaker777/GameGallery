## BGM/SEの音量状態を管理してAudioServerへ反映するマネージャー
extends Node

@onready var bgm_player: AudioStreamPlayer = %BackGroundMusicPlayer

const MASTER_BUS_NAME: StringName = &"Master"
const BGM_BUS_NAME: StringName = &"BGM"
const SE_BUS_NAME: StringName = &"SE"
## Mauterバスのミュート状態(true=ミュート)
var is_master_bus_mute:bool = false
## Masterの線形音量(1.0 = 100%の音量)
var master_volume_linear: float = 1.0
## BGMの線形音量(1.0 = 100%の音量)
var bgm_volume_linear: float = 1.0
## SEの線形音量(1.0 = 100%の音量)
var se_volume_linear: float = 1.0

func _ready() -> void:
	# Audio設定値をデフォルト値に初期化
	set_default_audio_option()

## Audio設定値をデフォルト値に初期化するメソッド
func set_default_audio_option() -> void:
	# AudioServerのMasterバスのミュートを無効化
	is_master_bus_mute = DefaultOption.DEFAULT_AUDIO_MASTER_BUS_MUTE
	set_master_bus_mute(is_master_bus_mute)
	
	# 各音量をデフォルト値に設定
	master_volume_linear = DefaultOption.DEFAULT_AUDIO_MASTER_VOLUME
	bgm_volume_linear = DefaultOption.DEFAULT_AUDIO_BGM_VOLUME
	se_volume_linear = DefaultOption.DEFAULT_AUDIO_SE_VOLUME
	
	# AudioServerの各バスの音量を設定
	_apply_bus_volume(MASTER_BUS_NAME, master_volume_linear)
	_apply_bus_volume(BGM_BUS_NAME, bgm_volume_linear)
	_apply_bus_volume(SE_BUS_NAME, se_volume_linear)

## Master音量を設定するメソッド（0.0〜1.0は線形値、それ以外はdB値として扱う）
func set_master_volume(linear_or_db: float) -> void:
	master_volume_linear = _normalize_volume_to_linear(linear_or_db)
	_apply_bus_volume(MASTER_BUS_NAME, master_volume_linear)

## BGM音量を設定するメソッド（0.0〜1.0は線形値、それ以外はdB値として扱う）
func set_bgm_volume(linear_or_db: float) -> void:
	bgm_volume_linear = _normalize_volume_to_linear(linear_or_db)
	_apply_bus_volume(BGM_BUS_NAME, bgm_volume_linear)

## SE音量を設定するメソッド（0.0〜1.0は線形値、それ以外はdB値として扱う）
func set_se_volume(linear_or_db: float) -> void:
	se_volume_linear = _normalize_volume_to_linear(linear_or_db)
	_apply_bus_volume(SE_BUS_NAME, se_volume_linear)

## 入力値を線形音量へ正規化するメソッド
func _normalize_volume_to_linear(linear_or_db: float) -> float:
	if linear_or_db >= 0.0 and linear_or_db <= 1.0:
		return linear_or_db
	return clampf(db_to_linear(linear_or_db), 0.0, 1.0)

## バス名に対応するAudioServerバスへdB値変換して反映するメソッド
func _apply_bus_volume(bus_name: StringName, volume_linear: float) -> void:
	# 引数のバス名のインデックスを取得
	var bus_index: int = AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		# バス設定が未作成でもクラッシュさせず、原因を追えるようログを残す。
		Log.warn("%s バスが見つからないため音量反映をスキップしました" % bus_name)
		return
	# 引数のバスの線形音量を設定
	AudioServer.set_bus_volume_linear(bus_index, volume_linear)

## マスターバスのミュートを設定するメソッド(引数trueでミュートに設定)
func set_master_bus_mute(is_mute:bool) -> void:
	Log.debug("Masterバスのミュート設定を変更")
	# AudioManagerの変数に変更結果を格納
	is_master_bus_mute = is_mute
	# masterバスのインデックスを取得
	var bus_index: int = AudioServer.get_bus_index(MASTER_BUS_NAME)
	AudioServer.set_bus_mute(bus_index, is_master_bus_mute)
