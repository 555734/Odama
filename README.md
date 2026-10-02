# Odama Racing MVP

大玉だけが走る、スマートフォン横画面向けの3D周回レースMVPです。Godot 4.7.2 / GDScriptで制作しました。既存のレースゲームのキャラクター、ロゴ、コース、音源は使用していません。

## 遊べる内容

- 4種類の模様を持つ自走する大玉。各モデルは塗装テクスチャ付きの `.glb` として `game/models/` に収録。
- 3周のタイムレース、順位、ベストラップ、リスタート。
- 3体のAIレーサー、接近時の軽い接触、ブースト残量、ブレーキ。
- 横画面用のタッチボタン。PCでは左右矢印または A/D、下矢印または S、スペースキーで操作。
- コース、樹木、旗、観客席、雲、ゴールゲートは軽量な3Dジオメトリで生成。コースと背景の `.glb` も収録。

## 開き方

Godot 4.7.2で `game/project.godot` を開き、メインシーンを実行してください。ローカルでの基本確認は次のコマンドです。

```text
godot --headless --editor --path game --quit
godot --headless --path game --script res://tests/smoke.gd
```

球体の塗装テクスチャは `node game/tools/generate_textures.mjs`、編集可能なGLBモデルは `godot --headless --path game --script res://tools/export_models.gd` で再生成できます。元のイメージボード、方向別の参考画像、寸法図は `asset-pack/` にあります。Godotの座標系は Y 上方向のため、素材集の Z 上方向から変換しています。

## Androidビルド

GitHub Actionsの `Android MVP` ワークフローが `main` へのpush、PR、手動実行でGodot公式のエディターとexport templatesを取得し、テスト後に**デバッグ署名APK**をartifactとして保存します。Actionsのrunの `odama-android-debug` からダウンロードできます。APKはAndroid端末での試用向けで、ストア公開用の署名やAABは含めていません。

ワークフローに秘密鍵、個人情報、GitHub書き込み権限は置いていません。デバッグ署名鍵は各runner上で一時生成し、ビルド後に破棄します。ネットワーク通信、位置情報、連絡先などのAndroid権限は要求しません。

## MVPの範囲

AIはシンプルな速度・車線制御です。コースは素材集のモジュールを参考にした閉じた楕円コースで、ジャンプやループ、アイテム、オンライン対戦、音声、iOSビルドは今後の拡張項目です。物理コリジョンは軽量化のため走路座標と接近判定で実装しています。
