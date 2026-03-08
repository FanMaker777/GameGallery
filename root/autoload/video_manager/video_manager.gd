## ゲームのVideo設定を管理してDisplayServer/Engineへ反映するマネージャー
extends Node

## 表示モードのマッピング定数
const DISPLAY_MODE_MAP: Dictionary = {
	"ウインドウ": DisplayServer.WINDOW_MODE_WINDOWED,
	"フルスクリーン": DisplayServer.WINDOW_MODE_FULLSCREEN,
}
## 解像度のマッピング定数
const RESOLUTION_MAP: Dictionary = {
	"854 × 480": Vector2i(854, 480),
	"1280 × 720": Vector2i(1280, 720),
	"1920 × 1080": Vector2i(1920, 1080),
}
## VSync(垂直同期)のマッピング定数
const VSYNC_MAP: Dictionary = {
	"無効": DisplayServer.VSYNC_DISABLED,
	"有効": DisplayServer.VSYNC_ENABLED,
}

func _ready() -> void:
	## 保存済みVideo設定値を読込して反映する
	_sync_from_repository()

## 保存済みVideo設定値を読み込み、DisplayServer/Engineへ反映するメソッド
func _sync_from_repository() -> void:
	var video_settings: Dictionary = SettingsRepository.get_video_settings()
	_apply_display_mode(str(video_settings.get("display_mode", "ウインドウ")))
	_apply_resolution(str(video_settings.get("resolution", "1280 × 720")))
	_apply_v_sync(str(video_settings.get("v_sync", "無効")))
	_apply_fps(str(video_settings.get("fps", "60")))

## 表示モードを設定するメソッド
func set_display_mode(text: String) -> void:
	_apply_display_mode(text)
	_save_current_video_setting("display_mode", text)

## 解像度を設定するメソッド
func set_resolution(text: String) -> void:
	_apply_resolution(text)
	_save_current_video_setting("resolution", text)

## VSync(垂直同期)を設定するメソッド
func set_v_sync(text: String) -> void:
	_apply_v_sync(text)
	_save_current_video_setting("v_sync", text)

## FPSを設定するメソッド
func set_fps(text: String) -> void:
	_apply_fps(text)
	_save_current_video_setting("fps", text)

## FPS表示を設定するメソッド（保存のみ、適用は未実装）
func set_fps_display(text: String) -> void:
	_save_current_video_setting("fps_display", text)

## Video設定値をデフォルト値に初期化するメソッド
func set_default_video_option() -> void:
	SettingsRepository.update_video_settings(SettingsRepository.create_default_state()["video"])
	_sync_from_repository()

## 表示モード設定を適用するメソッド
func _apply_display_mode(text: String) -> void:
	if DISPLAY_MODE_MAP.has(text):
		DisplayServer.window_set_mode(DISPLAY_MODE_MAP[text])

## 解像度設定を適用するメソッド
func _apply_resolution(text: String) -> void:
	if RESOLUTION_MAP.has(text):
		DisplayServer.window_set_size(RESOLUTION_MAP[text])

## VSync設定を適用するメソッド
func _apply_v_sync(text: String) -> void:
	if VSYNC_MAP.has(text):
		DisplayServer.window_set_vsync_mode(VSYNC_MAP[text])

## FPS設定を適用するメソッド
func _apply_fps(text: String) -> void:
	Engine.max_fps = int(text)

## 現在のVideo設定値をSettingsRepositoryへ保存するメソッド
func _save_current_video_setting(key: String, value: String) -> void:
	var video_settings: Dictionary = SettingsRepository.get_video_settings()
	video_settings[key] = value
	SettingsRepository.update_video_settings(video_settings)
