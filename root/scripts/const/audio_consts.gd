## オーディオリソース（BGM・SE）の定数を一括管理するクラス
class_name AudioConsts

# ---- BGM ----
## メインメニューBGM
const BGM_MENU: AudioStream = preload("uid://cymepixjpujgb")
## Achievement Master — 村マップBGM
const BGM_VILLAGE: AudioStream = preload("uid://dkyd0dsyhc553")
## Achievement Master — 草原マップBGM
const BGM_GRASSLAND: AudioStream = preload("uid://ch4gtaubeprin")
## Lucy Adventure — ステージBGM
const BGM_LUCY: AudioStream = preload("uid://dms6uninj35h2")
##  Introduce Godot - BGM
const BGM_INTRODUCE_GODOT: AudioStream = preload("uid://jbypqnvtwqjm")

# ---- SE（共通） ----
## UIクリック音
const SE_UI_CLICK: AudioStream = preload("uid://c66cay4oms5me")
## メニュー開閉SE
const SE_MENU_TOGGLE: AudioStream = preload("uid://dxajqdya8vr4g")

# ---- SE（Achievement Master） ----
## 攻撃ヒットSE
const SE_ATTACK_HIT: AudioStream = preload("uid://covef1vvojep0")
## 採取完了SE
const SE_GATHER_FINISH: AudioStream = preload("uid://bgludwi3pn43n")
## プレイヤー被ダメージSE
const SE_PLAYER_DAMAGE: AudioStream = null  # TODO: 音源配置後に preload に戻す
## 敵撃破SE
const SE_ENEMY_DEFEAT: AudioStream = preload("uid://cye2vhc3kovke")
## 実績解除SE
const SE_ACHIEVEMENT_UNLOCK: AudioStream = preload("uid://catpl55vobkuo")
## アイテム拾得SE
const SE_ITEM_PICKUP: AudioStream = preload("uid://cacik02pt0t0f")
## ポーション使用SE
const SE_USE_POTION: AudioStream = preload("uid://ci7hueh23g8si")
## ゴールド増減SE
const SE_GOLD: AudioStream = preload("uid://dm05hykv03mcb")
## 装備変更SE
const SE_EQUIP_EQUIPMENT: AudioStream = preload("uid://d0irc7luhwpb4")
## スキル取得SE
const SE_GET_SKILL: AudioStream = preload("uid://cmip2umnkxvjj")

# ---- SE（Lucy Adventure） ----
## ジャンプSE
const SE_JUMP: AudioStream = preload("uid://sl8ylws1fpiq")
## 踏みつけSE
const SE_STOMP: AudioStream = preload("uid://bpnna7jlr6a1q")
## プレイヤー死亡SE
const SE_PLAYER_DIE: AudioStream = null  # TODO: 音源配置後に preload に戻す
## ゴール到達SE
const SE_GOAL_REACH: AudioStream = preload("uid://dboch42so2ipu")
