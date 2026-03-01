# Phase 5E: ピン留め実績の HUD 表示ウィジェットを追加

## 目的

ゲーム画面右側に最大 3 件のピン留め実績の進捗をリアルタイム表示する。

## 作成ファイル

- `ui/pinned/pinned_achievement_panel.gd` + `.tscn` — パネル（VBoxContainer）
- `ui/pinned/pinned_achievement_item.gd` + `.tscn` — 1 件分（名前 + ProgressBar）

## 仕様

- `AchievementManager.pinned_changed` で再構築
- `AchievementManager.achievement_progress_updated` でリアルタイム更新
- 達成時はアニメーション後にリストから除外

## 修正ファイル

- `achievement_hud.tscn` — 右側スロットに PinnedAchievementPanel を配置

## コミットメッセージ

`feat: ピン留め実績の HUD 表示ウィジェットを追加`
