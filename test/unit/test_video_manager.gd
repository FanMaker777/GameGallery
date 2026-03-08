extends GutTest

## VideoManagerのDictionaryマッピング定数の正当性を検証するテスト

var _video_manager_script: GDScript

func before_all():
	_video_manager_script = load("res://root/autoload/video_manager/video_manager.gd")

## DISPLAY_MODE_MAPの値がDisplayServerの定数と一致すること
func test_display_mode_map_values():
	var map: Dictionary = _video_manager_script.DISPLAY_MODE_MAP
	assert_eq(map["ウインドウ"], DisplayServer.WINDOW_MODE_WINDOWED, "ウインドウはWINDOW_MODE_WINDOWEDに対応する")
	assert_eq(map["フルスクリーン"], DisplayServer.WINDOW_MODE_FULLSCREEN, "フルスクリーンはWINDOW_MODE_FULLSCREENに対応する")
	assert_eq(map.size(), 2, "DISPLAY_MODE_MAPは2エントリ")

## RESOLUTION_MAPの値が正しいVector2iであること
func test_resolution_map_values():
	var map: Dictionary = _video_manager_script.RESOLUTION_MAP
	assert_eq(map["854 × 480"], Vector2i(854, 480), "854 × 480の解像度が正しい")
	assert_eq(map["1280 × 720"], Vector2i(1280, 720), "1280 × 720の解像度が正しい")
	assert_eq(map["1920 × 1080"], Vector2i(1920, 1080), "1920 × 1080の解像度が正しい")
	assert_eq(map.size(), 3, "RESOLUTION_MAPは3エントリ")

## VSYNC_MAPの値がDisplayServerの定数と一致すること
func test_vsync_map_values():
	var map: Dictionary = _video_manager_script.VSYNC_MAP
	assert_eq(map["無効"], DisplayServer.VSYNC_DISABLED, "無効はVSYNC_DISABLEDに対応する")
	assert_eq(map["有効"], DisplayServer.VSYNC_ENABLED, "有効はVSYNC_ENABLEDに対応する")
	assert_eq(map.size(), 2, "VSYNC_MAPは2エントリ")
