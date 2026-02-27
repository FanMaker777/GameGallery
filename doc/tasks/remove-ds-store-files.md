# .DS_Store ファイルを削除し .gitignore に追加

## 優先度: 低
## 区分: 環境整備

## 概要

macOS のメタデータファイル `.DS_Store` が achievement_master 配下に 24 個散在している。リポジトリを汚染するため削除し、再発防止のため `.gitignore` に追加すべき。

## 対象

- `root/scenes/game_scene/achievement_master/` 配下の `.DS_Store` ファイル 24 個

## 修正方針

- `git rm --cached` で追跡から除外する
- `.gitignore` に `.DS_Store` を追加する
- ローカルのファイル自体も削除する
