## ゲームの音量状態を管理してAudioServerへ反映するマネージャー
extends Node

@onready var bgm_player: AudioStreamPlayer = %BackGroundMusicPlayer

const MASTER_BUS_NAME: StringName = &"Master"
const BGM_BUS_NAME: StringName = &"BGM"
const SE_BUS_NAME: StringName = &"SE"
## Masterバスのミュート状態(true=ミュート)
var is_master_bus_mute: bool = false
## Masterの線形音量(1.0 = 100%の音量)
var master_volume_linear: float = 1.0
## BGMの線形音量(1.0 = 100%の音量)
var bgm_volume_linear: float = 1.0
## SEの線形音量(1.0 = 100%の音量)
var se_volume_linear: float = 1.0

func _ready() -> void:
	## 保存済みAudio設定値を読込して反映する
	_sync_from_repository()

## 保存済みAudio設定値を読み込み、実行中のAudioServerへ反映するメソッド
func _sync_from_repository() -> void:
	# SettingsRepositoryからAudio設定値を読み込み
	var audio_settings: Dictionary = SettingsRepository.get_audio_settings()
	is_master_bus_mute = bool(audio_settings.get("master_mute", false))
	master_volume_linear = float(audio_settings.get("master_volume", 1.0))
	bgm_volume_linear = float(audio_settings.get("bgm_volume", 1.0))
	se_volume_linear = float(audio_settings.get("se_volume", 1.0))
	# 読み込んだAudio設定値をゲームに反映
	set_master_bus_mute(is_master_bus_mute)
	_apply_bus_volume(MASTER_BUS_NAME, master_volume_linear)
	_apply_bus_volume(BGM_BUS_NAME, bgm_volume_linear)
	_apply_bus_volume(SE_BUS_NAME, se_volume_linear)

## バス名に対応するAudioServerバスへ反映するメソッド
func _apply_bus_volume(bus_name: StringName, volume_linear: float) -> void:
	# 引数のバス名のインデックスを取得
	var bus_index: int = AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		# バス設定が未作成でもクラッシュさせず、原因を追えるようログを残す。
		Log.warn("%s バスが見つからないため音量反映をスキップしました" % bus_name)
		return
	# 引数のバスの線形音量を設定
	AudioServer.set_bus_volume_linear(bus_index, volume_linear)

## Audio設定値をデフォルト値に初期化するメソッド
func set_default_audio_option() -> void:
	## 設定保存先をデフォルト値へ戻してから反映する
	SettingsRepository.update_audio_settings(SettingsRepository.create_default_state()["audio"])
	_sync_from_repository()

## Master音量を設定するメソッド（0.0〜1.0は線形値、それ以外はdB値として扱う）
func set_master_volume(linear_or_db: float) -> void:
	# 引数を線形値に変換
	master_volume_linear = _normalize_volume_to_linear(linear_or_db)
	# 対応するAudioServerバスへ変更後の音量を反映
	_apply_bus_volume(MASTER_BUS_NAME, master_volume_linear)
	# ConfigFileに書き込み
	_save_current_audio_state()

## BGM音量を設定するメソッド（0.0〜1.0は線形値、それ以外はdB値として扱う）
func set_bgm_volume(linear_or_db: float) -> void:
	# 引数を線形値に変換
	bgm_volume_linear = _normalize_volume_to_linear(linear_or_db)
	# 対応するAudioServerバスへ変更後の音量を反映
	_apply_bus_volume(BGM_BUS_NAME, bgm_volume_linear)
	# ConfigFileに書き込み
	_save_current_audio_state()

## SE音量を設定するメソッド（0.0〜1.0は線形値、それ以外はdB値として扱う）
func set_se_volume(linear_or_db: float) -> void:
	# 引数を線形値に変換
	se_volume_linear = _normalize_volume_to_linear(linear_or_db)
	# 対応するAudioServerバスへ変更後の音量を反映
	_apply_bus_volume(SE_BUS_NAME, se_volume_linear)
	# ConfigFileに書き込み
	_save_current_audio_state()

## マスターバスのミュートを設定するメソッド(引数trueでミュートに設定)
func set_master_bus_mute(is_mute: bool) -> void:
	Log.debug("Masterバスのミュート設定を変更")
	# AudioManagerの変数に変更結果を格納
	is_master_bus_mute = is_mute
	# masterバスのインデックスを取得
	var bus_index: int = AudioServer.get_bus_index(MASTER_BUS_NAME)
	if bus_index == -1:
		# バス設定が未作成でもクラッシュさせず、原因を追えるようログを残す。
		Log.warn("%s バスが見つからないため音量反映をスキップしました" % MASTER_BUS_NAME)
		return
	# AudioServerのMasterバスのミュートを設定
	AudioServer.set_bus_mute(bus_index, is_master_bus_mute)
	# ConfigFileに書き込み
	_save_current_audio_state()

## 現在のAudio設定値をSettingsRepositoryへ保存するメソッド
func _save_current_audio_state() -> void:
	SettingsRepository.update_audio_settings({
		"master_mute": is_master_bus_mute,
		"master_volume": master_volume_linear,
		"bgm_volume": bgm_volume_linear,
		"se_volume": se_volume_linear,
	})

## 入力値を線形音量へ正規化するメソッド
func _normalize_volume_to_linear(linear_or_db: float) -> float:
	if linear_or_db >= 0.0 and linear_or_db <= 1.0:
		return linear_or_db
	return clampf(db_to_linear(linear_or_db), 0.0, 1.0)
