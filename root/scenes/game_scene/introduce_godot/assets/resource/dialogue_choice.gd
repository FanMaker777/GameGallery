## 対話シーンにおける選択肢1件分のデータを保持するリソース
@icon("uid://dxv3fhu42t0rr")
class_name DialogueChoice extends Resource

## 選択肢として表示するテキスト
@export var text := ""
## 選択後にジャンプする対話行のインデックス
@export_range(0, 20) var target_line_idx := 0
## この選択肢が対話終了（退出）かどうか
@export var is_quit := false
