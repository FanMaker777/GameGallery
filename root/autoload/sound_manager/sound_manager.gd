## BGM/SEの音量状態を管理してAudioServerへ反映するマネージャー
extends Node

const BGM_BUS_NAME: StringName = &"BGM"
const SE_BUS_NAME: StringName = &"SE"

var _bgm_volume_linear: float = 1.0
var _se_volume_linear: float = 1.0

## 保持しているBGM音量をAudioServerへ反映する初期化メソッド
func _ready() -> void:
	_apply_bgm_volume()
	_apply_se_volume()

## BGM音量を設定するメソッド（0.0〜1.0は線形値、それ以外はdB値として扱う）
func set_bgm_volume(linear_or_db: float) -> void:
	_bgm_volume_linear = _normalize_volume_to_linear(linear_or_db)
	_apply_bgm_volume()

## SE音量を設定するメソッド（0.0〜1.0は線形値、それ以外はdB値として扱う）
func set_se_volume(linear_or_db: float) -> void:
	_se_volume_linear = _normalize_volume_to_linear(linear_or_db)
	_apply_se_volume()

## UI同期用に保持しているBGM音量（線形値）を返すメソッド
func get_bgm_volume_linear() -> float:
	return _bgm_volume_linear

## UI同期用に保持しているSE音量（線形値）を返すメソッド
func get_se_volume_linear() -> float:
	return _se_volume_linear

## 入力値を線形音量へ正規化するメソッド
func _normalize_volume_to_linear(linear_or_db: float) -> float:
	if linear_or_db >= 0.0 and linear_or_db <= 1.0:
		return linear_or_db
	return clampf(db_to_linear(linear_or_db), 0.0, 1.0)

## BGMバスへ保持値を反映するメソッド
func _apply_bgm_volume() -> void:
	_apply_bus_volume(BGM_BUS_NAME, _bgm_volume_linear)

## SEバスへ保持値を反映するメソッド
func _apply_se_volume() -> void:
	_apply_bus_volume(SE_BUS_NAME, _se_volume_linear)

## バス名に対応するAudioServerバスへdB値変換して反映するメソッド
func _apply_bus_volume(bus_name: StringName, volume_linear: float) -> void:
	var bus_index: int = AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		# バス設定が未作成でもクラッシュさせず、原因を追えるようログを残す。
		Log.warn("%s バスが見つからないため音量反映をスキップしました" % bus_name)
		return
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(maxf(volume_linear, 0.0001)))
