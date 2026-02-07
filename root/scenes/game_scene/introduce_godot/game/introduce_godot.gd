@icon("uid://c1y5nxj2xu33x")
extends Control

## Audio player that plays voice sounds while text is being written
@onready var audio_stream_player: AudioStreamPlayer = %AudioStreamPlayer
@onready var _explanation_panel_container: PanelContainer = %ExplanationPanelContainer
@onready var _explanation_panel_container_2: PanelContainer = %ExplanationPanelContainer2

func _ready() -> void:
	Log.info("_ready introduce_godot")
	
	# 説明用の画像を非表示に設定
	_explanation_panel_container.visible = false
	_explanation_panel_container_2.visible = false
	# アドオン「Dialogic」から受け取るシグナルを接続
	Dialogic.signal_event.connect(_on_dialogic_signal)
	# アドオン「Dialogic」のタイムラインを開始
	Dialogic.start("introduce_godot")

## アドオン「Dialogic」からのシグナル受信時メソッド
## argument:String=Dialogicでシグナル発信時に設定した引数
func _on_dialogic_signal(argument:String) -> void:
	Log.debug("Dialogicのシグナルを検知", argument)
	
	match argument:
		"show_explanation":
			Log.debug("show_explanation")
			_explanation_panel_container.visible = true
			var tween:Tween = create_tween()
			tween.tween_property(_explanation_panel_container, "modulate:a", 1.0, 0.5).from(0.0)
		"show_explanation2":
			Log.debug("show_explanation2")
			_explanation_panel_container_2.visible = true
			var tween:Tween = create_tween()
			tween.tween_property(_explanation_panel_container_2, "modulate:a", 1.0, 0.5).from(0.0)
		"hide_explanation":
			Log.debug("hide_explanation")
			_explanation_panel_container.visible = false
		"hide_explanation2":
			Log.debug("hide_explanation2")
			_explanation_panel_container_2.visible = false
		"end_timeline":
			Log.debug("end_timeline")
			 # 2秒待つ（この関数だけが一時停止する。ゲーム全体は止まらない）
			await get_tree().create_timer(2.0).timeout
			# GameManager経由で戻ることで、シーン参照の循環を避ける。
			GameManager.load_main_menu_scene()
	
