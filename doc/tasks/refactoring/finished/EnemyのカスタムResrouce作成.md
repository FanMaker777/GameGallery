## 目的

AchievementMasterのEnemyの各種データを定義するGodotのResoruceを追加する。

## 仕様

- Enemyの各種データを定義したGodotのカスタムResoruceを作成する。
　カスタムResoruceは、ステータス、ドロップアイテム、SpriteFramesなど、Enemyの種類によって異なる、かつスクリプトやシーンから分離可能なデータを持つ。
- Enemy固有のデータを設定したカスタムResoruceを適用することで、既存のEnemyシーンを簡単に各種Enemyとして表現できる。
- モデルとして、現在実装済みのskullのデータを格納した、固有のカスタムResoruceを作成し、Enemysシーンにデフォルトで適用する。
