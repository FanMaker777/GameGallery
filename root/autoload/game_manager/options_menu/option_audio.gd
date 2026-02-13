## オプションメニューのオーディオ設定タブを制御するスクリプト
extends VBoxContainer

const LARGE_STEP: float = 0.10
const SMALL_STEP: float = 0.05
const PROGRESS_MIN: float = 0.0
const PROGRESS_MAX: float = 100.0

@onready var _bgm_progress_bar: ProgressBar = $OptionsMarginContainer/OptionsVBoxContainer/BgmVolumeHBoxContainer/ProgressBar
@onready var _bgm_decrement_button: Button = $OptionsMarginContainer/OptionsVBoxContainer/BgmVolumeHBoxContainer/DecrementSliderButton
@onready var _bgm_decrement_step_button: Button = $OptionsMarginContainer/OptionsVBoxContainer/BgmVolumeHBoxContainer/DecrementStepSliderButton
@onready var _bgm_increment_step_button: Button = $OptionsMarginContainer/OptionsVBoxContainer/BgmVolumeHBoxContainer/IncrementStepSliderButton
@onready var _bgm_increment_button: Button = $OptionsMarginContainer/OptionsVBoxContainer/BgmVolumeHBoxContainer/IncrementSliderButton

@onready var _effect_progress_bar: ProgressBar = $OptionsMarginContainer/OptionsVBoxContainer/EffectVolumeHBoxContainer/ProgressBar
@onready var _effect_decrement_button: Button = $OptionsMarginContainer/OptionsVBoxContainer/EffectVolumeHBoxContainer/DecrementSliderButton
@onready var _effect_decrement_step_button: Button = $OptionsMarginContainer/OptionsVBoxContainer/EffectVolumeHBoxContainer/DecrementStepSliderButton
@onready var _effect_increment_step_button: Button = $OptionsMarginContainer/OptionsVBoxContainer/EffectVolumeHBoxContainer/IncrementStepSliderButton
@onready var _effect_increment_button: Button = $OptionsMarginContainer/OptionsVBoxContainer/EffectVolumeHBoxContainer/IncrementSliderButton

## ボタン接続と初期表示同期を行うメソッド
func _ready() -> void:
	_bind_bgm_buttons()
	_bind_effect_buttons()
	sync_from_sound_manager()

## SoundManagerの保持値をUIへ同期するメソッド
func sync_from_sound_manager() -> void:
	_bgm_progress_bar.value = _to_progress_value(SoundManager.get_bgm_volume_linear())
	_effect_progress_bar.value = _to_progress_value(SoundManager.get_se_volume_linear())

## BGMボタン群のシグナル接続を行うメソッド
func _bind_bgm_buttons() -> void:
	_bgm_decrement_button.pressed.connect(func() -> void: _change_bgm_volume(-LARGE_STEP))
	_bgm_decrement_step_button.pressed.connect(func() -> void: _change_bgm_volume(-SMALL_STEP))
	_bgm_increment_step_button.pressed.connect(func() -> void: _change_bgm_volume(SMALL_STEP))
	_bgm_increment_button.pressed.connect(func() -> void: _change_bgm_volume(LARGE_STEP))

## エフェクトボタン群のシグナル接続を行うメソッド
func _bind_effect_buttons() -> void:
	_effect_decrement_button.pressed.connect(func() -> void: _change_effect_volume(-LARGE_STEP))
	_effect_decrement_step_button.pressed.connect(func() -> void: _change_effect_volume(-SMALL_STEP))
	_effect_increment_step_button.pressed.connect(func() -> void: _change_effect_volume(SMALL_STEP))
	_effect_increment_button.pressed.connect(func() -> void: _change_effect_volume(LARGE_STEP))

## BGM音量の増減とUI更新をまとめて行うメソッド
func _change_bgm_volume(delta: float) -> void:
	var next_value: float = clampf(SoundManager.get_bgm_volume_linear() + delta, 0.0, 1.0)
	SoundManager.set_bgm_volume(next_value)
	_bgm_progress_bar.value = _to_progress_value(next_value)

## エフェクト音量の増減とUI更新をまとめて行うメソッド
func _change_effect_volume(delta: float) -> void:
	var next_value: float = clampf(SoundManager.get_se_volume_linear() + delta, 0.0, 1.0)
	SoundManager.set_se_volume(next_value)
	_effect_progress_bar.value = _to_progress_value(next_value)

## 線形音量をProgressBar表示用の値へ変換するメソッド
func _to_progress_value(volume_linear: float) -> float:
	return clampf(volume_linear * 100.0, PROGRESS_MIN, PROGRESS_MAX)
