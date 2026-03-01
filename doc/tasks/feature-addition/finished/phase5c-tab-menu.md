# Phase 5C: AM 専用 4 タブメニューの基盤を追加

## 目的

Tab キー（`open_menu`）で開閉する Achievement Master 専用の 4 タブメニューを作成する。ESC の既存 PauseScreen と共存させる。

## 作成ファイル

- `ui/menu/am_pause_menu.gd` + `.tscn`

## 仕様

- `process_mode = ALWAYS`（PauseScreen と同様）
- Tab キーで開閉、`get_tree().paused` を切り替え
- ブラー + 彩度低下（`pause_screen.gd` のシェーダーパターンを再利用）
- 4 タブ: 装備 / ステータス / スキル / 実績（装備〜スキルは placeholder）
- 既存 PauseScreen が開いている時は Tab を無視
- 以下のフォルダに格納された画像アセットを活用してUIを構築する。 
  `D:\MyWork\GameDevelopment\Godot\Godot_v4.5.1\projects\GameGallery\root\scenes\game_scene\achievement_master\ui\assets`

## 修正ファイル

- `village.tscn` / `grassland.tscn` — AmPauseMenu インスタンスを追加

## 参照する既存パターン

- `pause_screen.gd` — Tween アニメーション、`menu_opened_amount`、`_is_in_toggle` ガード
- `overlay_controller.gd` — ESC ハンドリングとの競合回避

## コミットメッセージ

`feat: AM 専用 4 タブメニューの基盤を追加`
