@tool
extends Control

@onready var _title_label: Label = %TitleLabel
@onready var _thumbnail_texture_rect: TextureRect = %ThumbnailTextureRect
@onready var _genre_label: Label = %GenreLabel
@onready var _description_label: Label = %DescriptionLabel
@onready var _play_button: Button = %PlayButton

@export var title:String = "ゲームタイトル":set = set_title
@export var thumbnail:= preload("uid://bdr5qrqlnxt3x"):set = set_thumbnail
@export var genre:String = "ジャンル":set = set_genre
@export var description:String = "説明":set = set_description
@export var game_scene_path:String = ""

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_title(title)
	set_thumbnail(thumbnail)
	set_genre(genre)
	set_description(description)
	# Playボタン押下時
	_play_button.pressed.connect(func() -> void:
		Log.debug("Play Game：", title)
		
		# プレイ先のゲームのPackedSceneが存在する場合
		if game_scene_path != "":
			# ゲームシーンに遷移
			GameManager.load_scene_with_transition(game_scene_path)
		else:
			Log.warn("game_scene_path = null")
	)

func set_title(new_title:String):
		title = new_title
		if _title_label != null:
			_title_label.text = new_title

func set_thumbnail(new_thumbnail):
		thumbnail = new_thumbnail
		if _thumbnail_texture_rect != null:
			_thumbnail_texture_rect.texture = new_thumbnail

func set_genre(new_genre:String):
		genre = new_genre
		if _genre_label != null:
			_genre_label.text = new_genre

func set_description(new_description:String):
		description = new_description
		if _description_label != null:
			_description_label.text = new_description
