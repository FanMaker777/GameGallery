# Phase 5B: 統合型 AchievementHud を追加（ResourceHud を置換）

## 目的

現在の ResourceHud を拡張し、全 HUD 要素を統合する CanvasLayer を作成する。

## 作成ファイル

- `ui/achievement_hud.gd` + `.tscn`

## レイアウト

- 左上: HP バー + リソース数（既存 ResourceHud ロジック吸収）+ AP カウンター
- 右側: ピン留め実績パネル（5E で実装、枠だけ用意）
- 下部中央: ToastManager（5A のインスタンス埋め込み）

## 修正ファイル

- `village.tscn` / `grassland.tscn` — ResourceHud → AchievementHud に差し替え

## 再利用する既存コード

- `resource_hud.gd` の `_connect_to_pawn()` / `_on_inventory_changed()` / `_on_health_changed()` パターンをそのまま移植

## コミットメッセージ

`feat: 統合型 AchievementHud を追加（ResourceHud を置換）`
