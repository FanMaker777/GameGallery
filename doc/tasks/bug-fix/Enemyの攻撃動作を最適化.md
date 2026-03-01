## 目的

**achievement_masterのEnemyの動作をスムーズにする。**  

現在、achievement_masterのEnemyの動作が、ワンテンポ遅い。 
例)プレイヤーが検知範囲内に入っても、少し時間をおいてから追跡し始める。 
プレイヤーが離れていても、プレイヤーがかつて存在した場所に攻撃を仕掛けるなど。


## 修正ファイル

- `root/scenes/game_scene/achievement_master/enemies/enemy.gd`
- `root/scenes/game_scene/achievement_master/enemies/enemy.tscn`

## 仕様

- Enemyはプレイヤーに対してスムーズに追跡、攻撃などのアクションを実行する。
