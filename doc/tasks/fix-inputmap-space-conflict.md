# InputMap の Space キー重複を解消

## 優先度: 低
## 区分: 整合性

## 概要

`project.godot` で `jump`（Space, C, JoypadA/Y）と `attack`（Space）が重複バインドされている。Achievement Master では `jump` は未使用だが、将来的に衝突する可能性がある。

## 対象ファイル

- `project.godot`（InputMap セクション）

## 修正方針

- `jump` から Space キーを除外する（C キーとジョイパッドのみ残す）
- または `attack` を別のキーに変更する
- 他のミニゲーム（Lucy Adventure）への影響を確認した上で判断する
