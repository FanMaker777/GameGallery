## オプションメニューのオーディオ設定タブを制御するスクリプト
## 各設定値のCofigFileへの書き込みは、このクラスでは行わず、AudioManagerで処理
class_name OptionAudio extends VBoxContainer

## 各ボタン押下時の音量増減量(線形数量)
const LARGE_STEP: float = 0.10
const SMALL_STEP: float = 0.01
## 音量を表すプログレスバーの最小値
const PROGRESS_MIN: float = 0.0
## 音量を表すプログレスバーの最大値
const PROGRESS_MAX: float = 100.0

@onready var _audio_option_button: OptionButton = %AudioOptionButton
# マスターボリューム
@onready var _master_progress_bar: ProgressBar = $OptionsMarginContainer/OptionsVBoxContainer/MasterVolumeHBoxContainer/ProgressBar
@onready var _master_decrement_button: Button = $OptionsMarginContainer/OptionsVBoxContainer/MasterVolumeHBoxContainer/DecrementSliderButton
@onready var _master_decrement_step_button: Button = $OptionsMarginContainer/OptionsVBoxContainer/MasterVolumeHBoxContainer/DecrementStepSliderButton
@onready var _master_increment_step_button: Button = $OptionsMarginContainer/OptionsVBoxContainer/MasterVolumeHBoxContainer/IncrementStepSliderButton
@onready var _master_increment_button: Button = $OptionsMarginContainer/OptionsVBoxContainer/MasterVolumeHBoxContainer/IncrementSliderButton
# BGMボリューム
@onready var _bgm_progress_bar: ProgressBar = $OptionsMarginContainer/OptionsVBoxContainer/BgmVolumeHBoxContainer/ProgressBar
@onready var _bgm_decrement_button: Button = $OptionsMarginContainer/OptionsVBoxContainer/BgmVolumeHBoxContainer/DecrementSliderButton
@onready var _bgm_decrement_step_button: Button = $OptionsMarginContainer/OptionsVBoxContainer/BgmVolumeHBoxContainer/DecrementStepSliderButton
@onready var _bgm_increment_step_button: Button = $OptionsMarginContainer/OptionsVBoxContainer/BgmVolumeHBoxContainer/IncrementStepSliderButton
@onready var _bgm_increment_button: Button = $OptionsMarginContainer/OptionsVBoxContainer/BgmVolumeHBoxContainer/IncrementSliderButton
# SEボリューム
@onready var _effect_progress_bar: ProgressBar = $OptionsMarginContainer/OptionsVBoxContainer/EffectVolumeHBoxContainer/ProgressBar
@onready var _effect_decrement_button: Button = $OptionsMarginContainer/OptionsVBoxContainer/EffectVolumeHBoxContainer/DecrementSliderButton
@onready var _effect_decrement_step_button: Button = $OptionsMarginContainer/OptionsVBoxContainer/EffectVolumeHBoxContainer/DecrementStepSliderButton
@onready var _effect_increment_step_button: Button = $OptionsMarginContainer/OptionsVBoxContainer/EffectVolumeHBoxContainer/IncrementStepSliderButton
@onready var _effect_increment_button: Button = $OptionsMarginContainer/OptionsVBoxContainer/EffectVolumeHBoxContainer/IncrementSliderButton

## ボタン接続と初期表示同期を行うメソッド
func _ready() -> void:
	# Audio設定ボタン選択時のメソッドをコネクト
	_audio_option_button.item_selected.connect(_selected_audio_option_button)
	# 各増減ボタンに音量更新メソッドをコネクト
	_connect_master_buttons()
	_connect_bgm_buttons()
	_connect_effect_buttons()

## 設定保存値をUIへ同期するメソッド
func sync_ui_from_setting_value() -> void:
	# SettingsRepositoryから現在のAudio設定を取得
	var audio_settings: Dictionary = SettingsRepository.get_audio_settings()
	# Masterバスのミュート状態に応じて(true=ミュート中)
	if bool(audio_settings.get("master_mute", false)):
		# オプションボタンをAudioオフに設定
		_audio_option_button.selected = 1
	else:
		# オプションボタンをAudioオンに設定
		_audio_option_button.selected = 0
	# 音量を表すプログレスバーを更新
	_master_progress_bar.value = _to_progress_value(float(audio_settings.get("master_volume", 1.0)))
	_bgm_progress_bar.value = _to_progress_value(float(audio_settings.get("bgm_volume", 1.0)))
	_effect_progress_bar.value = _to_progress_value(float(audio_settings.get("se_volume", 1.0)))

## Audioボタン選択時の処理メソッド
func _selected_audio_option_button(selected_index:int) -> void:
	# 選択された値を取得
	var selected_text:String = _audio_option_button.get_item_text(selected_index)
	# 選択された値に応じてゲーム設定を変更
	match selected_text:
		"オン":
			# Masterバスを非ミュートに設定
			AudioManager.set_master_bus_mute(false)
		"オフ":
			# Masterバスをミュートに設定
			AudioManager.set_master_bus_mute(true)

## Masterボタン群のシグナル接続を行うメソッド
func _connect_master_buttons() -> void:
	_master_decrement_button.pressed.connect(func() -> void: _change_master_volume(-LARGE_STEP))
	_master_decrement_step_button.pressed.connect(func() -> void: _change_master_volume(-SMALL_STEP))
	_master_increment_step_button.pressed.connect(func() -> void: _change_master_volume(SMALL_STEP))
	_master_increment_button.pressed.connect(func() -> void: _change_master_volume(LARGE_STEP))

## BGMボタン群のシグナル接続を行うメソッド
func _connect_bgm_buttons() -> void:
	_bgm_decrement_button.pressed.connect(func() -> void: _change_bgm_volume(-LARGE_STEP))
	_bgm_decrement_step_button.pressed.connect(func() -> void: _change_bgm_volume(-SMALL_STEP))
	_bgm_increment_step_button.pressed.connect(func() -> void: _change_bgm_volume(SMALL_STEP))
	_bgm_increment_button.pressed.connect(func() -> void: _change_bgm_volume(LARGE_STEP))

## エフェクトボタン群のシグナル接続を行うメソッド
func _connect_effect_buttons() -> void:
	_effect_decrement_button.pressed.connect(func() -> void: _change_effect_volume(-LARGE_STEP))
	_effect_decrement_step_button.pressed.connect(func() -> void: _change_effect_volume(-SMALL_STEP))
	_effect_increment_step_button.pressed.connect(func() -> void: _change_effect_volume(SMALL_STEP))
	_effect_increment_button.pressed.connect(func() -> void: _change_effect_volume(LARGE_STEP))

## Master音量の増減とUI更新をまとめて行うメソッド
func _change_master_volume(change_value: float) -> void:
	var next_value: float = clampf(AudioManager.master_volume_linear + change_value, 0.0, 1.0)
	AudioManager.set_master_volume(next_value)
	_master_progress_bar.value = _to_progress_value(next_value)

## BGM音量の増減とUI更新をまとめて行うメソッド
func _change_bgm_volume(change_value: float) -> void:
	var next_value: float = clampf(AudioManager.bgm_volume_linear + change_value, 0.0, 1.0)
	AudioManager.set_bgm_volume(next_value)
	_bgm_progress_bar.value = _to_progress_value(next_value)

## エフェクト音量の増減とUI更新をまとめて行うメソッド
func _change_effect_volume(change_value: float) -> void:
	var next_value: float = clampf(AudioManager.se_volume_linear + change_value, 0.0, 1.0)
	AudioManager.set_se_volume(next_value)
	_effect_progress_bar.value = _to_progress_value(next_value)

## 線形音量をProgressBar表示用の値へ変換するメソッド
func _to_progress_value(volume_linear: float) -> float:
	return clampf(volume_linear * 100.0, PROGRESS_MIN, PROGRESS_MAX)
