## 1件分の実績解除トースト通知パネル
## 実績名・ランク・AP報酬を表示し、スライドアニメーションで出入りする
class_name AchievementToast extends PanelContainer

# ---- シグナル ----
## トーストのアニメーションが完了したときに発火する
signal toast_finished

# ---- 定数 ----
## トースト表示時間（秒）
const DISPLAY_DURATION: float = 2.0
## スライドアニメーション時間（秒）
const SLIDE_DURATION: float = 0.3
## スライド移動距離（ピクセル）
const SLIDE_OFFSET: float = 300.0

# ---- ランク表示マッピング ----
## ランクごとのラベル文字列
const RANK_LABELS: Dictionary = {
	AchievementDefinition.Rank.BRONZE: "[B]",
	AchievementDefinition.Rank.SILVER: "[S]",
	AchievementDefinition.Rank.GOLD: "[G]",
}
## ランクごとの表示色
const RANK_COLORS: Dictionary = {
	AchievementDefinition.Rank.BRONZE: Color(0.80, 0.50, 0.20),
	AchievementDefinition.Rank.SILVER: Color(0.75, 0.75, 0.75),
	AchievementDefinition.Rank.GOLD: Color(1.00, 0.84, 0.00),
}

# ---- ノードキャッシュ ----
## ランクアイコンラベル
@onready var _rank_label: Label = %RankLabel
## 実績名ラベル
@onready var _title_label: Label = %TitleLabel
## 説明ラベル
@onready var _description_label: Label = %DescriptionLabel
## AP報酬ラベル
@onready var _ap_label: Label = %ApLabel


## 実績定義データからトースト内容をセットする
func setup(definition: AchievementDefinition) -> void:
	# ランクラベルの設定
	_rank_label.text = RANK_LABELS[definition.rank]
	_rank_label.add_theme_color_override(
		"font_color", RANK_COLORS[definition.rank]
	)
	# 実績名の設定
	_title_label.text = definition.name_ja
	# 説明の設定
	_description_label.text = definition.description_ja
	# AP報酬の設定
	_ap_label.text = "+%d AP" % definition.ap


## スライドイン → 表示 → スライドアウトのアニメーションを再生する
func play_animation() -> void:
	# 初期位置を画面右外に設定する
	var original_x: float = position.x
	position.x = original_x + SLIDE_OFFSET
	modulate.a = 0.0

	# スライドイン
	var tween: Tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "position:x", original_x, SLIDE_DURATION)
	tween.parallel().tween_property(self, "modulate:a", 1.0, SLIDE_DURATION * 0.5)

	# 表示時間待機
	tween.tween_interval(DISPLAY_DURATION)

	# スライドアウト
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "position:x", original_x + SLIDE_OFFSET, SLIDE_DURATION)
	tween.parallel().tween_property(self, "modulate:a", 0.0, SLIDE_DURATION)

	# アニメーション完了後にシグナル発火して自身を削除する
	tween.tween_callback(_on_animation_finished)


## アニメーション完了時の処理
func _on_animation_finished() -> void:
	toast_finished.emit()
	queue_free()
