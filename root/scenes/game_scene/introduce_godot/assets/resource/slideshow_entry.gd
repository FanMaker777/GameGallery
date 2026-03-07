## スライドショー1ページ分の表情・キャラクター画像とテキストを保持するリソース
class_name SlideShowEntry extends Resource

# ---- 画像 ----
@export_group("Images")
## キャラクターの表情テクスチャ
@export var expression: Texture = preload("uid://bghgtvtpjneuw")
## キャラクター本体のテクスチャ
@export var character: Texture = preload("uid://lvdxjuogsivg")

# ---- テキスト ----
@export_group("Text")
## スライドに表示するテキスト
@export_multiline var text := ""
