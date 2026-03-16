## 操作ガイドのコンテンツを動的に生成するユーティリティ
## HelpTab と TutorialOverlay の両方から呼び出される
class_name HelpContentBuilder

## ヘッダーの金色
const HEADER_COLOR: Color = Color(1.0, 0.84, 0.0, 0.8)
## キーラベルの金色
const KEY_COLOR: Color = Color(1.0, 0.84, 0.0, 0.9)
## 説明テキストの白色
const DESC_COLOR: Color = Color(0.9, 0.9, 0.9, 1.0)
## ヘッダーフォントサイズ
const HEADER_FONT_SIZE: int = 13
## 本文フォントサイズ
const BODY_FONT_SIZE: int = 12
## キーラベルの最小幅
const KEY_MIN_WIDTH: float = 130.0

## セクション定義: [ヘッダー名, [[キー, 説明], ...]]
const SECTIONS: Array = [
	["移動", [
		["矢印キー", "移動"],
		["Shift + 矢印", "ダッシュ（スタミナ消費）"],
	]],
	["戦闘", [
		["Space", "攻撃"],
	]],
	["インタラクト", [
		["E", "採取・NPC会話（初回はギフト入手）"],
	]],
	["メニュー", [
		["Tab", "メニュー開閉"],
		["ESC", "メニュー閉じる"],
	]],
	["クイックスロット", [
		["1 / 2 / 3", "消耗品を使用"],
	]],
	["実績・スキル", [
		["", "行動で実績進行 → AP獲得 → スキル解放"],
	]],
	["マップ移動", [
		["", "マップ端のゲートで他のエリアへ"],
	]],
]


## 指定した VBoxContainer に操作ガイドのコンテンツを構築する
static func build_content(parent: VBoxContainer) -> void:
	for i: int in SECTIONS.size():
		var section: Array = SECTIONS[i]
		var header_text: String = section[0]
		var entries: Array = section[1]
		# セクション間のスペーサー（先頭以外）
		if i > 0:
			var spacer: Control = Control.new()
			spacer.custom_minimum_size = Vector2(0, 8)
			parent.add_child(spacer)
		# ヘッダー
		var header: Label = Label.new()
		header.text = header_text
		header.add_theme_color_override("font_color", HEADER_COLOR)
		header.add_theme_font_size_override("font_size", HEADER_FONT_SIZE)
		parent.add_child(header)
		# セパレーター
		var sep: HSeparator = HSeparator.new()
		parent.add_child(sep)
		# 各エントリ行
		for entry: Array in entries:
			var key_text: String = entry[0]
			var desc_text: String = entry[1]
			var row: HBoxContainer = HBoxContainer.new()
			row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			if key_text != "":
				# キーラベル（固定幅・金色）
				var key_label: Label = Label.new()
				key_label.text = key_text
				key_label.custom_minimum_size.x = KEY_MIN_WIDTH
				key_label.add_theme_color_override("font_color", KEY_COLOR)
				key_label.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
				row.add_child(key_label)
			# 説明ラベル（白色）
			var desc_label: Label = Label.new()
			desc_label.text = desc_text
			desc_label.add_theme_color_override("font_color", DESC_COLOR)
			desc_label.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
			row.add_child(desc_label)
			parent.add_child(row)
