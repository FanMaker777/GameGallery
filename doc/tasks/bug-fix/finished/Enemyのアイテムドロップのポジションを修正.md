# タイトル

## 目的

スポナーから出現したEnemyを倒した時、ドロップアイテムの出現場所が、Enemyからずれているのを修正する

## 修正ファイル

- `root/scenes/game_scene/achievement_master/enemies/enemy.gd`
- `root/scenes/game_scene/achievement_master/world/spawner/generic_spawner.gd`

## 仕様

- スポナーから出現したEnemyを倒した時、Enemyの死亡した場所にドロップアイテムを出現させる。
