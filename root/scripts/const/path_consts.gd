## ファイルパスの定数を定義するクラス
class_name PathConsts

## メインメニューシーンのパス
const MAIN_MENU_SCENE: String = "uid://byjaiv21t5df7"
## ゲーム(プラットフォーマー)のパス
const LUCY_ADVENTURE_SCENE: String = "uid://b7hikg0q3dsbv"
## 設定永続化ファイルパス
const SETTINGS_FILE_PATH: String = "user://settings.cfg"

## ポーズスクリーンの表示が可能なシーンのパスリスト
const PAUSE_SCREEN_ENABLE_SCENES: PackedStringArray = [
	"res://root/scenes/game_scene/introduce_godot/game/introduce_godot.tscn",
	"res://root/scenes/game_scene/lucy_adventure/stages/samples/L10_level.tscn",
	"res://root/scenes/game_scene/lucy_adventure/stages/samples/L11_mushroom_world_playground.level.tscn"
]
