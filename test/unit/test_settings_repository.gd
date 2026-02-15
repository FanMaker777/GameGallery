extends GutTest

## SettingsRepositoryスクリプト参照
const SETTINGS_REPOSITORY_SCRIPT: GDScript = preload("res://root/autoload/settings_repository/settings_repository.gd")

## テスト対象のSettingsRepositoryインスタンス
var _repository: Node

## テスト前処理でインスタンスを生成するメソッド
func before_each() -> void:
	_repository = SETTINGS_REPOSITORY_SCRIPT.new()

## テスト後処理で参照を破棄するメソッド
func after_each() -> void:
	_repository.free()
	_repository = null

## Audio設定の欠損キー・型不一致を補正できることを確認するテスト
func test_sanitize_audio_settings_欠損値と型不一致を補正できる() -> void:
	var sanitized: Dictionary = _repository.sanitize_audio_settings({
		"master_bus_mute": "オン",
		"master_volume": 1.5,
		"bgm_volume": "0.25",
		"se_volume": "invalid",
	})
	assert_eq(sanitized["master_mute"], true)
	assert_eq(sanitized["master_volume"], 1.0)
	assert_eq(sanitized["bgm_volume"], 0.25)
	assert_eq(sanitized["se_volume"], 1.0)

## Video設定の不正値が許可候補へ丸められることを確認するテスト
func test_sanitize_video_settings_不正値を補正できる() -> void:
	var sanitized: Dictionary = _repository.sanitize_video_settings({
		"display_mode": "不明",
		"resolution": 1280,
		"v_sync": "有効",
		"fps": 57,
		"fps_display": "無効",
	})
	assert_eq(sanitized["display_mode"], "windowed")
	assert_eq(sanitized["resolution"], "1280")
	assert_eq(sanitized["v_sync"], "enabled")
	assert_eq(sanitized["fps"], 60)
	assert_eq(sanitized["fps_display"], false)

## VideoのFPSが許可候補のうち最も近い値へ丸められることを確認するテスト
func test_sanitize_video_settings_fpsは最も近い許可候補へ丸める() -> void:
	var sanitized: Dictionary = _repository.sanitize_video_settings({"fps": 119})
	assert_eq(sanitized["fps"], 120)
