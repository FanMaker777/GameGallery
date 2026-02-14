## オプション設定の現在値と永続化を管理するリポジトリ
class_name SettingsRepository
extends Node

## 設定永続化ファイルパス
const SETTINGS_FILE_PATH: String = "user://settings.cfg"

## Audio設定の現在値
var _audio_state: Dictionary = {}
## Video設定の現在値
var _video_state: Dictionary = {}

func _ready() -> void:
	## 起動時に永続化ファイルを読み込み、未設定項目はデフォルト値で補完する
	_load_settings()

## デフォルト設定値の辞書を生成するメソッド
func create_default_state() -> Dictionary:
	return {
		"audio": {
			"master_bus_mute": DefaultOption.DEFAULT_AUDIO_MASTER_BUS_MUTE,
			"master_volume": DefaultOption.DEFAULT_AUDIO_MASTER_VOLUME,
			"bgm_volume": DefaultOption.DEFAULT_AUDIO_BGM_VOLUME,
			"se_volume": DefaultOption.DEFAULT_AUDIO_SE_VOLUME,
		},
		"video": {
			"display_mode": DefaultOption.DEFAULT_VIDEO_DISPLAY_MODE,
			"resolution": DefaultOption.DEFAULT_VIDEO_RESOLUTION,
			"v_sync": DefaultOption.DEFAULT_VIDEO_V_SYNC,
			"fps": DefaultOption.DEFAULT_VIDEO_FPS,
			"fps_display": DefaultOption.DEFAULT_VIDEO_FPS_DISPLAY,
		},
	}

## 永続化ファイルを読み込み、現在値へ反映するメソッド
func _load_settings() -> void:
	var default_state: Dictionary = create_default_state()
	_audio_state = default_state["audio"].duplicate(true)
	_video_state = default_state["video"].duplicate(true)

	var config: ConfigFile = ConfigFile.new()
	var load_error: int = config.load(SETTINGS_FILE_PATH)
	if load_error != OK:
		# 初回起動や破損時はデフォルト値を保存して以後の読込を安定化する。
		save_settings()
		return

	_audio_state["master_bus_mute"] = config.get_value("audio", "master_bus_mute", _audio_state["master_bus_mute"])
	_audio_state["master_volume"] = config.get_value("audio", "master_volume", _audio_state["master_volume"])
	_audio_state["bgm_volume"] = config.get_value("audio", "bgm_volume", _audio_state["bgm_volume"])
	_audio_state["se_volume"] = config.get_value("audio", "se_volume", _audio_state["se_volume"])

	_video_state["display_mode"] = config.get_value("video", "display_mode", _video_state["display_mode"])
	_video_state["resolution"] = config.get_value("video", "resolution", _video_state["resolution"])
	_video_state["v_sync"] = config.get_value("video", "v_sync", _video_state["v_sync"])
	_video_state["fps"] = config.get_value("video", "fps", _video_state["fps"])
	_video_state["fps_display"] = config.get_value("video", "fps_display", _video_state["fps_display"])

## 現在値を永続化ファイルへ保存するメソッド
func save_settings() -> void:
	var config: ConfigFile = ConfigFile.new()

	config.set_value("audio", "master_bus_mute", _audio_state["master_bus_mute"])
	config.set_value("audio", "master_volume", _audio_state["master_volume"])
	config.set_value("audio", "bgm_volume", _audio_state["bgm_volume"])
	config.set_value("audio", "se_volume", _audio_state["se_volume"])

	config.set_value("video", "display_mode", _video_state["display_mode"])
	config.set_value("video", "resolution", _video_state["resolution"])
	config.set_value("video", "v_sync", _video_state["v_sync"])
	config.set_value("video", "fps", _video_state["fps"])
	config.set_value("video", "fps_display", _video_state["fps_display"])

	var save_error: int = config.save(SETTINGS_FILE_PATH)
	if save_error != OK:
		Log.error("SettingsRepositoryの保存に失敗しました: %s" % save_error)

## 現在のAudio設定を辞書で返すメソッド
func get_audio_settings() -> Dictionary:
	return _audio_state.duplicate(true)

## 現在のVideo設定を辞書で返すメソッド
func get_video_settings() -> Dictionary:
	return _video_state.duplicate(true)

## Audio設定を更新して永続化するメソッド
func update_audio_settings(audio_settings: Dictionary) -> void:
	_audio_state["master_bus_mute"] = audio_settings.get("master_bus_mute", _audio_state["master_bus_mute"])
	_audio_state["master_volume"] = audio_settings.get("master_volume", _audio_state["master_volume"])
	_audio_state["bgm_volume"] = audio_settings.get("bgm_volume", _audio_state["bgm_volume"])
	_audio_state["se_volume"] = audio_settings.get("se_volume", _audio_state["se_volume"])
	save_settings()

## Video設定を更新して永続化するメソッド
func update_video_settings(video_settings: Dictionary) -> void:
	_video_state["display_mode"] = video_settings.get("display_mode", _video_state["display_mode"])
	_video_state["resolution"] = video_settings.get("resolution", _video_state["resolution"])
	_video_state["v_sync"] = video_settings.get("v_sync", _video_state["v_sync"])
	_video_state["fps"] = video_settings.get("fps", _video_state["fps"])
	_video_state["fps_display"] = video_settings.get("fps_display", _video_state["fps_display"])
	save_settings()

## 全設定をデフォルト値へ戻して永続化するメソッド
func reset_to_default() -> void:
	var default_state: Dictionary = create_default_state()
	_audio_state = default_state["audio"].duplicate(true)
	_video_state = default_state["video"].duplicate(true)
	save_settings()
