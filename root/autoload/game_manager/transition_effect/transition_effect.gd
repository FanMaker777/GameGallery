## 画面遷移時の演出を担当する
extends CanvasLayer

## 画面遷移時のエフェクト
@export var t_effect: TransitionRect
## 画面遷移の所要時間(秒)
@export_range(0, 10, 0.01) var transition_time:float = 1.0
## 画面のフェードアウト時に発信されるシグナル
signal finished_fade_out

func _ready() -> void:
	Log.info("_ready TransitionEffect")
	# 初期状態では非表示に設定
	t_effect.visible = false
	
func fade_in() -> void:
	Log.debug("func fade_in")
	# 遷移画面の表示を有効化
	t_effect.visible = true
	# 遷移エフェクトを全て表示
	t_effect.factor = 1.0
	# 遷移エフェクトをアニメーションさせてフェードインを表現
	var tween := create_tween()
	tween.tween_property(t_effect, "factor", 0.0, transition_time)
	# 画面遷移終了時、画面表示を無効化
	tween.finished.connect(func() -> void:
		t_effect.visible = false
	)

func fade_out() -> void:
	Log.debug("func fade_out")
	# 遷移画面の表示を有効化
	t_effect.visible = true
	# 遷移エフェクトを非表示に設定
	t_effect.factor = 0.0
	# 遷移エフェクトをアニメーションさせてフェードアウトを表現
	var tween := create_tween()
	tween.tween_property(t_effect, "factor", 1.0, transition_time)
	# 画面遷移終了時、画面表示を無効化
	tween.finished.connect(func() -> void:
		t_effect.visible = false
		# フェードアウト終了のシグナルを発信
		emit_signal("finished_fade_out")
	)
