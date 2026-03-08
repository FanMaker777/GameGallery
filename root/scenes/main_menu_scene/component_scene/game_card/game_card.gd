## メインメニューに表示するゲームカードUIを管理する
@tool
extends Control

# ---- ノード参照 ----
## タイトル表示ラベル
@onready var _title_label: Label = %TitleLabel
## サムネイル画像表示用TextureRect
@onready var _thumbnail_texture_rect: TextureRect = %ThumbnailTextureRect
## ジャンル表示ラベル
@onready var _genre_label: Label = %GenreLabel
## 説明文表示ラベル
@onready var _description_label: Label = %DescriptionLabel
## ゲーム開始ボタン
@onready var _play_button: Button = %PlayButton

# ---- エクスポート変数 ----
## カードに表示するゲームタイトル
@export var title: String = "ゲームタイトル": set = set_title
## カードに表示するサムネイル画像
@export var thumbnail: Texture = preload("uid://bdr5qrqlnxt3x"): set = set_thumbnail
## カードに表示するジャンル名
@export var genre: String = "ジャンル": set = set_genre
## カードに表示する説明文
@export var description: String = "説明": set = set_description
## 遷移先のゲームシーンパス
@export var game_scene_path: String = ""

## 各プロパティの初期反映とPlayボタンのシグナル接続を行う
func _ready() -> void:
	# 各プロパティの表示を初期化
	set_title(title)
	set_thumbnail(thumbnail)
	set_genre(genre)
	set_description(description)
	# Playボタン押下時のコールバックを接続
	_play_button.pressed.connect(func() -> void:
		Log.debug("Play Game：", title)

		# プレイ先のゲームのPackedSceneが存在する場合
		if game_scene_path != "":
			# ゲームシーンに遷移
			GameManager.load_scene_with_transition(game_scene_path)
		else:
			Log.warn("game_scene_path = null")
	)

## タイトルを設定しラベルに反映する
func set_title(new_title: String) -> void:
		title = new_title
		# ラベルが存在する場合のみ反映
		if _title_label != null:
			_title_label.text = new_title

## サムネイル画像を設定しTextureRectに反映する
func set_thumbnail(new_thumbnail: Texture) -> void:
		thumbnail = new_thumbnail
		# TextureRectが存在する場合のみ反映
		if _thumbnail_texture_rect != null:
			_thumbnail_texture_rect.texture = new_thumbnail

## ジャンルを設定しラベルに反映する
func set_genre(new_genre: String) -> void:
		genre = new_genre
		# ラベルが存在する場合のみ反映
		if _genre_label != null:
			_genre_label.text = new_genre

## 説明文を設定しラベルに反映する
func set_description(new_description: String) -> void:
		description = new_description
		# ラベルが存在する場合のみ反映
		if _description_label != null:
			_description_label.text = new_description
