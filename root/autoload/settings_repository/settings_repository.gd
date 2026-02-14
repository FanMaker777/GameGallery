## オプション設定の現在値と永続化を管理するリポジトリ
extends Node

## Audio設定の現在値
var audio_settings: Dictionary = {}
## Video設定の現在値
var video_settings: Dictionary = {}

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
	# デフォルト設定を読み込み
	var default_state: Dictionary = create_default_state()
	audio_settings = default_state["audio"].duplicate(true)
	video_settings = default_state["video"].duplicate(true)
	
	# ユーザーデータフォルダから、オプション設定のConfigFileを読み込み
	var config: ConfigFile = ConfigFile.new()
	var load_error: int = config.load(PathConsts.SETTINGS_FILE_PATH)
	if load_error != OK:
		Log.warn("Cofigファイルが読み込めませんでした。", load_error)
		# 初回起動や破損時はデフォルト値を保存して以後の読込を安定化する。
		save_settings()
		return
	
	# ConfigFileに保存されていたオプション設定を取得
	# ConfigFileから取得できない値は、デフォルト設定を使用(第3引数で指定)
	audio_settings["master_bus_mute"] = config.get_value("audio", "master_bus_mute", audio_settings["master_bus_mute"])
	audio_settings["master_volume"] = config.get_value("audio", "master_volume", audio_settings["master_volume"])
	audio_settings["bgm_volume"] = config.get_value("audio", "bgm_volume", audio_settings["bgm_volume"])
	audio_settings["se_volume"] = config.get_value("audio", "se_volume", audio_settings["se_volume"])

	video_settings["display_mode"] = config.get_value("video", "display_mode", video_settings["display_mode"])
	video_settings["resolution"] = config.get_value("video", "resolution", video_settings["resolution"])
	video_settings["v_sync"] = config.get_value("video", "v_sync", video_settings["v_sync"])
	video_settings["fps"] = config.get_value("video", "fps", video_settings["fps"])
	video_settings["fps_display"] = config.get_value("video", "fps_display", video_settings["fps_display"])

## 現在値を永続化ファイルへ保存するメソッド
func save_settings() -> void:
	var config: ConfigFile = ConfigFile.new()

	config.set_value("audio", "master_bus_mute", audio_settings["master_bus_mute"])
	config.set_value("audio", "master_volume", audio_settings["master_volume"])
	config.set_value("audio", "bgm_volume", audio_settings["bgm_volume"])
	config.set_value("audio", "se_volume", audio_settings["se_volume"])

	config.set_value("video", "display_mode", video_settings["display_mode"])
	config.set_value("video", "resolution", video_settings["resolution"])
	config.set_value("video", "v_sync", video_settings["v_sync"])
	config.set_value("video", "fps", video_settings["fps"])
	config.set_value("video", "fps_display", video_settings["fps_display"])

	var save_error: int = config.save(PathConsts.SETTINGS_FILE_PATH)
	if save_error != OK:
		Log.error("SettingsRepositoryの保存に失敗しました: %s" % save_error)

## 現在のAudio設定を辞書で返すメソッド
func get_audio_settings() -> Dictionary:
	return audio_settings.duplicate(true)

## 現在のVideo設定を辞書で返すメソッド
func get_video_settings() -> Dictionary:
	return video_settings.duplicate(true)

## Audio設定を更新して永続化するメソッド
func update_audio_settings(new_audio_settings: Dictionary) -> void:
	audio_settings["master_bus_mute"] = new_audio_settings.get("master_bus_mute", audio_settings["master_bus_mute"])
	audio_settings["master_volume"] = new_audio_settings.get("master_volume", audio_settings["master_volume"])
	audio_settings["bgm_volume"] = new_audio_settings.get("bgm_volume", audio_settings["bgm_volume"])
	audio_settings["se_volume"] = new_audio_settings.get("se_volume", audio_settings["se_volume"])
	save_settings()

## Video設定を更新して永続化するメソッド
func update_video_settings(new_video_settings: Dictionary) -> void:
	video_settings["display_mode"] = new_video_settings.get("display_mode", video_settings["display_mode"])
	video_settings["resolution"] = new_video_settings.get("resolution", video_settings["resolution"])
	video_settings["v_sync"] = new_video_settings.get("v_sync", video_settings["v_sync"])
	video_settings["fps"] = new_video_settings.get("fps", video_settings["fps"])
	video_settings["fps_display"] = new_video_settings.get("fps_display", video_settings["fps_display"])
	save_settings()

## 全設定をデフォルト値へ戻して永続化するメソッド
func reset_to_default() -> void:
	var default_state: Dictionary = create_default_state()
	audio_settings = default_state["audio"].duplicate(true)
	video_settings = default_state["video"].duplicate(true)
	save_settings()
