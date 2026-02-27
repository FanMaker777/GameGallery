# PathConsts のパス形式を UID に統一

## 優先度: 低
## 区分: 整合性

## 概要

`path_consts.gd` で UID 形式と res:// 形式が混在している。

- `MAIN_MENU_SCENE` / `LUCY_ADVENTURE_SCENE` → UID（`uid://...`）
- `AM_VILLAGE_SCENE` / `AM_GRASSLAND_SCENE` → res:// パス

UID はファイル移動/リネームへの耐性が高いため、統一すべき。

## 対象ファイル

- `root/scripts/const/path_consts.gd:9-11`

## 修正方針

- `AM_VILLAGE_SCENE` / `AM_GRASSLAND_SCENE` の UID を取得して置き換える
- `PAUSE_SCREEN_ENABLE_SCENES` 内の res:// パスも UID に変更する
- MCP の `get_uid` ツールで UID を取得できる
