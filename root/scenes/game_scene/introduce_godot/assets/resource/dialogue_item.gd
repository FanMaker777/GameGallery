## スライドショーエントリに選択肢を追加した対話1行分のリソース
@icon("res://assets/dialogue_item_icon.svg")
class_name DialogueItem extends SlideShowEntry

@export_group("Choices")
## この対話行に紐づく選択肢の一覧
@export var choices: Array[DialogueChoice] = []
