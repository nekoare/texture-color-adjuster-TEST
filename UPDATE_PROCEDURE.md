# TextureColorAdjuster アップデート手順

このドキュメントは、TextureColorAdjusterのアップデートを本リポジトリでテストする際の手順をまとめたものです。

## 前提条件

- 元のリポジトリ（nekoare/texture-color-adjuster）に新しいバージョンがリリースされている
- または、Editorフォルダ内のファイルに変更・追加がある

## アップデート作業チェックリスト

### 1. ソースコードの更新

- [ ] 元のリポジトリから最新のコードを取得
  ```bash
  git clone https://github.com/nekoare/texture-color-adjuster.git /tmp/tex-col-adjuster-latest
  ```

- [ ] Editorフォルダ内のファイルを更新
  ```bash
  cp -r /tmp/tex-col-adjuster-latest/Packages/dev.nekoare.tex-col-adjuster/Editor/* \
        /home/user/texture-color-adjuster-TEST/Packages/dev.nekoare.tex-col-adjuster-test/Editor/
  ```

- [ ] その他のパッケージファイルの確認（.asmdef、Resourcesフォルダなど）

### 2. バージョン番号の更新

- [ ] `Packages/dev.nekoare.tex-col-adjuster-test/package.json` のバージョンを更新
  - `"version": "X.Y.Z"` を新しいバージョン番号に変更
  - セマンティックバージョニングに従う
    - メジャーバージョン: 破壊的変更
    - マイナーバージョン: 機能追加（下位互換性あり）
    - パッチバージョン: バグフィックス

### 3. VPMパッケージレジストリの更新

- [ ] `index.json` に新しいバージョンエントリを追加
  - 既存のバージョンエントリをコピーして編集
  - `version` フィールドを新しいバージョン番号に
  - `name`: `"dev.nekoare.tex-col-adjuster-test"` （変更不要）
  - `displayName`: `"Texture Color Adjuster TEST"` （変更不要）
  - `url`: `https://nekoare.github.io/texture-color-adjuster-TEST/dev.nekoare.tex-col-adjuster-test-vX.Y.Z.zip`
  - `zipSHA256`: 後で計算した値に置き換え（仮値: `"0000000000000000000000000000000000000000000000000000000000000000"`）

### 4. CHANGELOGの更新

- [ ] `CHANGELOG.md` に新しいバージョンのエントリを追加
  ```markdown
  ## [X.Y.Z] - YYYY-MM-DD

  ### Added
  - 新機能の説明

  ### Changed
  - 変更された機能の説明

  ### Fixed
  - 修正されたバグの説明

  ### Removed
  - 削除された機能の説明
  ```

### 5. パッケージの作成

- [ ] パッケージディレクトリからzipファイルを作成
  ```bash
  cd /home/user/texture-color-adjuster-TEST/Packages
  zip -r dev.nekoare.tex-col-adjuster-test-vX.Y.Z.zip dev.nekoare.tex-col-adjuster-test/
  ```

- [ ] SHA256ハッシュを計算
  ```bash
  sha256sum dev.nekoare.tex-col-adjuster-test-vX.Y.Z.zip
  ```

- [ ] `index.json` の `zipSHA256` フィールドを計算した値に更新

- [ ] zipファイルを適切な場所に配置（GitHub Pagesのルートなど）

### 6. ドキュメントの更新

- [ ] `README.md` の更新（必要な場合）
  - 新機能の説明
  - 使用方法の変更
  - 要件の変更

- [ ] パッケージ内の `Packages/dev.nekoare.tex-col-adjuster-test/README.md` も同様に更新

### 7. Git操作

- [ ] 変更をステージング
  ```bash
  git add -A
  ```

- [ ] コミット
  ```bash
  git commit -m "Update to version X.Y.Z"
  ```

- [ ] バージョンタグを作成
  ```bash
  git tag -a vX.Y.Z -m "Version X.Y.Z"
  ```

- [ ] プッシュ（タグも含む）
  ```bash
  git push origin <branch-name>
  git push origin vX.Y.Z
  ```

### 8. GitHub Pages デプロイ

- [ ] GitHub Actionsワークフローが正常に実行されることを確認
  - `.github/workflows/pages.yml` が自動的に実行される
  - GitHub Pagesにindex.jsonとzipファイルがデプロイされる

- [ ] デプロイ後、以下のURLにアクセスして確認
  ```
  https://nekoare.github.io/texture-color-adjuster-TEST/index.json
  ```

### 9. GitHubリリースの作成（オプション）

- [ ] GitHubのReleasesページで新しいリリースを作成
  - タグ: `vX.Y.Z`
  - リリースタイトル: `Version X.Y.Z`
  - 説明: CHANGELOGの内容をコピー
  - アセット: zipファイルを添付

### 10. テスト

- [ ] VCC (ALCOM) でリポジトリを再読み込み
  - 新しいバージョンが表示されることを確認

- [ ] テストプロジェクトで新しいバージョンをインストール
  - 正常にインストールできることを確認
  - 基本機能が動作することを確認

- [ ] バグが発見された場合は修正してパッチバージョンをリリース

## 注意事項

### VPM URLの重複回避

このリポジトリはテスト用なので、以下の点に注意：

- パッケージ名: `dev.nekoare.tex-col-adjuster-test` （本番は `-test` なし）
- VPM URL: `https://nekoare.github.io/texture-color-adjuster-TEST/` （本番は `-TEST` なし）
- リポジトリID: `dev.nekoare.tex-col-adjuster-test-repo` （本番は `-test-repo` なし）

### セマンティックバージョニング

- **メジャーバージョン (X.0.0)**: APIの破壊的変更、大規模な機能変更
- **マイナーバージョン (1.X.0)**: 新機能追加（後方互換性あり）
- **パッチバージョン (1.0.X)**: バグフィックス、小さな改善

### コミットメッセージの規約

```
Update to version X.Y.Z

- 変更内容の概要1
- 変更内容の概要2
- 変更内容の概要3
```

## トラブルシューティング

### zipファイルのSHA256が一致しない

- zipファイルを再作成する際は、ディレクトリ構造とファイルの順序が同じになるようにする
- 同じコマンドを使用してzipを作成する

### GitHub Pagesにデプロイされない

- `.github/workflows/pages.yml` の設定を確認
- GitHub リポジトリ設定でPagesが有効になっているか確認
- Actionsの実行ログを確認

### VCCで新しいバージョンが表示されない

- ブラウザキャッシュをクリア
- VCCを再起動
- index.jsonのURLに直接アクセスして内容を確認

## 参考リンク

- [VPM Package Manifest Specification](https://vcc.docs.vrchat.com/vpm/packages/)
- [Semantic Versioning 2.0.0](https://semver.org/)
- [GitHub Pages Documentation](https://docs.github.com/pages)
