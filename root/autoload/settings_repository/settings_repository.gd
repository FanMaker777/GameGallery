## オプション設定の現在値と永続化を管理するリポジトリ
extends Node

## Audio設定の許可最小音量
const AUDIO_VOLUME_MIN: float = 0.0
## Audio設定の許可最大音量
const AUDIO_VOLUME_MAX: float = 1.0
## Video設定の許可FPS候補
const ALLOWED_FPS_VALUES: Array[int] = [30, 60, 120]
## 表示モードの内部キー（ウインドウ）
const DISPLAY_MODE_WINDOWED: String = "windowed"
## 表示モードの内部キー（フルスクリーン）
const DISPLAY_MODE_FULLSCREEN: String = "fullscreen"
## VSyncの内部キー（無効）
const V_SYNC_DISABLED: String = "disabled"
## VSyncの内部キー（有効）
const V_SYNC_ENABLED: String = "enabled"

## Audio設定の型付きstate
class AudioState:
	## マスターバスのミュート状態
	var master_mute: bool
	## マスターバスの線形音量
	var master_volume: float
	## BGMバスの線形音量
	var bgm_volume: float
	## SEバスの線形音量
	var se_volume: float

	## AudioStateを初期化するメソッド
	func _init(
		init_master_mute: bool,
		init_master_volume: float,
		init_bgm_volume: float,
		init_se_volume: float,
	) -> void:
		master_mute = init_master_mute
		master_volume = init_master_volume
		bgm_volume = init_bgm_volume
		se_volume = init_se_volume

	## 現在のstateを辞書へ変換するメソッド
	func to_dictionary() -> Dictionary:
		return {
			"master_mute": master_mute,
			"master_volume": master_volume,
			"bgm_volume": bgm_volume,
			"se_volume": se_volume,
		}

## Video設定の型付きstate
class VideoState:
	## 表示モード内部キー
	var display_mode: String
	## 解像度文字列
	var resolution: String
	## VSync内部キー
	var v_sync: String
	## 描画FPS
	var fps: int
	## FPS表示の有効状態
	var fps_display: bool

	## VideoStateを初期化するメソッド
	func _init(
		init_display_mode: String,
		init_resolution: String,
		init_v_sync: String,
		init_fps: int,
		init_fps_display: bool,
	) -> void:
		display_mode = init_display_mode
		resolution = init_resolution
		v_sync = init_v_sync
		fps = init_fps
		fps_display = init_fps_display

	## 現在のstateを辞書へ変換するメソッド
	func to_dictionary() -> Dictionary:
		return {
			"display_mode": display_mode,
			"resolution": resolution,
			"v_sync": v_sync,
			"fps": fps,
			"fps_display": fps_display,
		}

## Audio設定の現在値
var audio_settings: AudioState
## Video設定の現在値
var video_settings: VideoState

## Audio設定の生デフォルト辞書を返すメソッド
func _get_raw_default_audio_settings() -> Dictionary:
	return {
		"master_mute": DefaultOption.DEFAULT_AUDIO_MASTER_BUS_MUTE,
		"master_volume": DefaultOption.DEFAULT_AUDIO_MASTER_VOLUME,
		"bgm_volume": DefaultOption.DEFAULT_AUDIO_BGM_VOLUME,
		"se_volume": DefaultOption.DEFAULT_AUDIO_SE_VOLUME,
	}

## Video設定の生デフォルト辞書を返すメソッド
func _get_raw_default_video_settings() -> Dictionary:
	return {
		"display_mode": DefaultOption.DEFAULT_VIDEO_DISPLAY_MODE,
		"resolution": DefaultOption.DEFAULT_VIDEO_RESOLUTION,
		"v_sync": DefaultOption.DEFAULT_VIDEO_V_SYNC,
		"fps": DefaultOption.DEFAULT_VIDEO_FPS,
		"fps_display": DefaultOption.DEFAULT_VIDEO_FPS_DISPLAY,
	}

func _ready() -> void:
	## 起動時に永続化ファイルを読み込み、未設定項目はデフォルト値で補完する
	_load_settings()

## DefaultOptionを基準にAudioのデフォルトstateを生成するメソッド
func _create_default_audio_state() -> AudioState:
	var raw_audio_state: Dictionary = _get_raw_default_audio_settings()
	var sanitized_audio_state: Dictionary = sanitize_audio_settings(raw_audio_state)
	return AudioState.new(
		sanitized_audio_state["master_mute"],
		sanitized_audio_state["master_volume"],
		sanitized_audio_state["bgm_volume"],
		sanitized_audio_state["se_volume"],
	)

## DefaultOptionを基準にVideoのデフォルトstateを生成するメソッド
func _create_default_video_state() -> VideoState:
	var raw_video_state: Dictionary = _get_raw_default_video_settings()
	var sanitized_video_state: Dictionary = sanitize_video_settings(raw_video_state)
	return VideoState.new(
		sanitized_video_state["display_mode"],
		sanitized_video_state["resolution"],
		sanitized_video_state["v_sync"],
		sanitized_video_state["fps"],
		sanitized_video_state["fps_display"],
	)

## デフォルト設定値の辞書を生成するメソッド
func create_default_state() -> Dictionary:
	return {
		"audio": _create_default_audio_state().to_dictionary(),
		"video": _create_default_video_state().to_dictionary(),
	}

## 永続化ファイルを読み込み、現在値へ反映するメソッド
func _load_settings() -> void:
	# DefaultOptionをフォールバックとして型付きデフォルトstateを生成
	audio_settings = _create_default_audio_state()
	video_settings = _create_default_video_state()

	# ユーザーデータフォルダから、オプション設定のConfigFileを読み込み
	var config: ConfigFile = ConfigFile.new()
	var load_error: int = config.load(PathConsts.SETTINGS_FILE_PATH)
	if load_error != OK:
		Log.warn("Configファイルが読み込めませんでした。", load_error)
		# 初回起動や破損時はデフォルト値を保存して以後の読込を安定化する。
		save_settings()
		return

	# ConfigFileから取得した値をリポジトリ側でサニタイズして反映する
	var loaded_audio_state: Dictionary = {
		"master_mute": _get_audio_config_value(config, "master_mute", audio_settings.master_mute),
		"master_volume": config.get_value("audio", "master_volume", audio_settings.master_volume),
		"bgm_volume": config.get_value("audio", "bgm_volume", audio_settings.bgm_volume),
		"se_volume": config.get_value("audio", "se_volume", audio_settings.se_volume),
	}
	var loaded_video_state: Dictionary = {
		"display_mode": config.get_value("video", "display_mode", video_settings.display_mode),
		"resolution": config.get_value("video", "resolution", video_settings.resolution),
		"v_sync": config.get_value("video", "v_sync", video_settings.v_sync),
		"fps": config.get_value("video", "fps", video_settings.fps),
		"fps_display": config.get_value("video", "fps_display", video_settings.fps_display),
	}
	update_audio_settings(loaded_audio_state)
	update_video_settings(loaded_video_state)

## Audio設定をConfigから取得するメソッド（旧キー互換あり）
func _get_audio_config_value(config: ConfigFile, key: String, fallback: Variant) -> Variant:
	if config.has_section_key("audio", key):
		return config.get_value("audio", key, fallback)
	if key == "master_mute" and config.has_section_key("audio", "master_bus_mute"):
		# 旧バージョンの保存キーを読み替える
		return config.get_value("audio", "master_bus_mute", fallback)
	return fallback

## Audio設定の欠損キーと型不一致を補正するメソッド
func sanitize_audio_settings(raw_audio_settings: Dictionary) -> Dictionary:
	var default_audio_settings: Dictionary = _get_raw_default_audio_settings()
	var master_mute_value: bool = _to_bool(
		raw_audio_settings.get("master_mute", raw_audio_settings.get("master_bus_mute", default_audio_settings["master_mute"])),
		default_audio_settings["master_mute"],
	)
	var master_volume_value: float = _to_clamped_volume(
		raw_audio_settings.get("master_volume", default_audio_settings["master_volume"]),
		default_audio_settings["master_volume"],
	)
	var bgm_volume_value: float = _to_clamped_volume(
		raw_audio_settings.get("bgm_volume", default_audio_settings["bgm_volume"]),
		default_audio_settings["bgm_volume"],
	)
	var se_volume_value: float = _to_clamped_volume(
		raw_audio_settings.get("se_volume", default_audio_settings["se_volume"]),
		default_audio_settings["se_volume"],
	)
	return {
		"master_mute": master_mute_value,
		"master_volume": master_volume_value,
		"bgm_volume": bgm_volume_value,
		"se_volume": se_volume_value,
	}

## Video設定の欠損キーと型不一致を補正するメソッド
func sanitize_video_settings(raw_video_settings: Dictionary) -> Dictionary:
	var default_video_settings: Dictionary = _get_raw_default_video_settings()
	var default_fps_value: int = _to_int(default_video_settings["fps"], 60)
	var default_fps_display_value: bool = _to_bool(default_video_settings["fps_display"], false)
	var display_mode_value: String = _sanitize_display_mode(
		raw_video_settings.get("display_mode", default_video_settings["display_mode"]),
		default_video_settings["display_mode"],
	)
	var resolution_value: String = str(raw_video_settings.get("resolution", default_video_settings["resolution"]))
	var v_sync_value: String = _sanitize_v_sync(
		raw_video_settings.get("v_sync", default_video_settings["v_sync"]),
		default_video_settings["v_sync"],
	)
	var fps_value: int = _sanitize_fps(
		raw_video_settings.get("fps", default_fps_value),
		default_fps_value,
	)
	var fps_display_value: bool = _to_bool(
		raw_video_settings.get("fps_display", default_fps_display_value),
		default_fps_display_value,
	)
	return {
		"display_mode": display_mode_value,
		"resolution": resolution_value,
		"v_sync": v_sync_value,
		"fps": fps_value,
		"fps_display": fps_display_value,
	}

## 表示モード文字列を既知キーへ補正するメソッド
func _sanitize_display_mode(raw_display_mode: Variant, fallback: String) -> String:
	var normalized_fallback: String = str(fallback).to_lower()
	if normalized_fallback in [DISPLAY_MODE_FULLSCREEN, "フルスクリーン"]:
		fallback = DISPLAY_MODE_FULLSCREEN
	else:
		fallback = DISPLAY_MODE_WINDOWED
	var normalized_display_mode: String = str(raw_display_mode).to_lower()
	if normalized_display_mode in [DISPLAY_MODE_WINDOWED, "ウインドウ"]:
		return DISPLAY_MODE_WINDOWED
	if normalized_display_mode in [DISPLAY_MODE_FULLSCREEN, "フルスクリーン"]:
		return DISPLAY_MODE_FULLSCREEN
	return fallback

## VSync文字列を既知キーへ補正するメソッド
func _sanitize_v_sync(raw_v_sync: Variant, fallback: String) -> String:
	var normalized_fallback: String = str(fallback).to_lower()
	if normalized_fallback in [V_SYNC_ENABLED, "有効"]:
		fallback = V_SYNC_ENABLED
	else:
		fallback = V_SYNC_DISABLED
	var normalized_v_sync: String = str(raw_v_sync).to_lower()
	if normalized_v_sync in [V_SYNC_DISABLED, "無効"]:
		return V_SYNC_DISABLED
	if normalized_v_sync in [V_SYNC_ENABLED, "有効"]:
		return V_SYNC_ENABLED
	return fallback

## FPSを許可候補へ丸めて返すメソッド
func _sanitize_fps(raw_fps: Variant, fallback: int) -> int:
	var parsed_fps: int = _to_int(raw_fps, fallback)
	var nearest_fps: int = ALLOWED_FPS_VALUES[0]
	var nearest_distance: int = abs(parsed_fps - nearest_fps)
	for allowed_fps in ALLOWED_FPS_VALUES:
		var current_distance: int = abs(parsed_fps - allowed_fps)
		if current_distance < nearest_distance:
			nearest_fps = allowed_fps
			nearest_distance = current_distance
	return nearest_fps

## 0.0〜1.0へclampした音量を返すメソッド
func _to_clamped_volume(raw_volume: Variant, fallback: float) -> float:
	return clampf(_to_float(raw_volume, fallback), AUDIO_VOLUME_MIN, AUDIO_VOLUME_MAX)

## Variantをboolへ安全変換するメソッド
func _to_bool(raw_value: Variant, fallback: bool) -> bool:
	match typeof(raw_value):
		TYPE_BOOL:
			return raw_value
		TYPE_INT, TYPE_FLOAT:
			return raw_value != 0
		TYPE_STRING:
			var normalized_text: String = str(raw_value).to_lower()
			if normalized_text in ["true", "1", "有効", "オン"]:
				return true
			if normalized_text in ["false", "0", "無効", "オフ"]:
				return false
	return fallback

## Variantをfloatへ安全変換するメソッド
func _to_float(raw_value: Variant, fallback: float) -> float:
	if raw_value is float:
		return raw_value
	if raw_value is int:
		return float(raw_value)
	if raw_value is String and String(raw_value).is_valid_float():
		return float(raw_value)
	return fallback

## Variantをintへ安全変換するメソッド
func _to_int(raw_value: Variant, fallback: int) -> int:
	if raw_value is int:
		return raw_value
	if raw_value is float:
		return int(round(raw_value))
	if raw_value is String and String(raw_value).is_valid_int():
		return int(raw_value)
	return fallback

## 現在値を永続化ファイルへ保存するメソッド
func save_settings() -> void:
	var config: ConfigFile = ConfigFile.new()

	config.set_value("audio", "master_mute", audio_settings.master_mute)
	config.set_value("audio", "master_volume", audio_settings.master_volume)
	config.set_value("audio", "bgm_volume", audio_settings.bgm_volume)
	config.set_value("audio", "se_volume", audio_settings.se_volume)

	config.set_value("video", "display_mode", video_settings.display_mode)
	config.set_value("video", "resolution", video_settings.resolution)
	config.set_value("video", "v_sync", video_settings.v_sync)
	config.set_value("video", "fps", video_settings.fps)
	config.set_value("video", "fps_display", video_settings.fps_display)

	var save_error: int = config.save(PathConsts.SETTINGS_FILE_PATH)
	if save_error != OK:
		Log.error("SettingsRepositoryの保存に失敗しました: %s" % save_error)

## 現在のAudio設定を辞書で返すメソッド
func get_audio_settings() -> Dictionary:
	return audio_settings.to_dictionary().duplicate(true)

## 現在のVideo設定を辞書で返すメソッド
func get_video_settings() -> Dictionary:
	return video_settings.to_dictionary().duplicate(true)

## Audio設定を更新して永続化するメソッド
func update_audio_settings(new_audio_settings: Dictionary) -> void:
	var merged_audio_settings: Dictionary = audio_settings.to_dictionary()
	merged_audio_settings.merge(new_audio_settings, true)
	var sanitized_audio_settings: Dictionary = sanitize_audio_settings(merged_audio_settings)
	audio_settings = AudioState.new(
		sanitized_audio_settings["master_mute"],
		sanitized_audio_settings["master_volume"],
		sanitized_audio_settings["bgm_volume"],
		sanitized_audio_settings["se_volume"],
	)
	save_settings()

## Video設定を更新して永続化するメソッド
func update_video_settings(new_video_settings: Dictionary) -> void:
	var merged_video_settings: Dictionary = video_settings.to_dictionary()
	merged_video_settings.merge(new_video_settings, true)
	var sanitized_video_settings: Dictionary = sanitize_video_settings(merged_video_settings)
	video_settings = VideoState.new(
		sanitized_video_settings["display_mode"],
		sanitized_video_settings["resolution"],
		sanitized_video_settings["v_sync"],
		sanitized_video_settings["fps"],
		sanitized_video_settings["fps_display"],
	)
	save_settings()

## 全設定をデフォルト値へ戻して永続化するメソッド
func reset_to_default() -> void:
	audio_settings = _create_default_audio_state()
	video_settings = _create_default_video_state()
	save_settings()
