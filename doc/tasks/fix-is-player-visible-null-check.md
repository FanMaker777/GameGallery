# IsPlayerVisible の null チェック欠落を修正

## 優先度: 高
## 区分: バグ

## 概要

`root/scripts/beehave/condition_leaf/is_player_visible.gd` で `get_first_node_in_group("player")` の結果を null チェックせずに `global_position` にアクセスしている。プレイヤー死亡後やシーン遷移中にクラッシュする可能性がある。

## 対象ファイル

- `root/scripts/beehave/condition_leaf/is_player_visible.gd:15-18`

## 現状のコード

```gdscript
player = get_tree().get_first_node_in_group("player")
# null チェックなし
blackboard.set_value(BlackBordValue.PLAYER_POSITION, player.global_position)
```

## 修正方針

- `player` が null の場合は `FAILURE` を返す
- `is_instance_valid()` も併用して安全性を確保する
