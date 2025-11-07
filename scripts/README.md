# スクリプト説明

このディレクトリには、TextureColorAdjusterのアップデート作業を補助するスクリプトが含まれています。

## スクリプト一覧

### sync-from-upstream.sh

元のリポジトリ（nekoare/texture-color-adjuster）から最新の変更を取得して同期します。

**使用方法:**
```bash
./scripts/sync-from-upstream.sh
```

**実行内容:**
1. 元のリポジトリをクローン
2. バージョン情報を表示
3. 変更されたファイルを確認
4. ユーザーに確認後、以下をコピー:
   - Editor フォルダ
   - Runtime フォルダ（存在する場合）
   - Resources フォルダ（存在する場合）
   - CHANGELOG.md
   - LICENSE

**注意事項:**
- package.json は自動では更新されません（バージョン番号がテスト用に異なるため）
- README.md も自動では更新されません（テスト用の注釈があるため）
- 同期後は必ず動作確認を行ってください

---

### update-version.sh

バージョン番号を更新し、リリース準備を行います。

**使用方法:**
```bash
./scripts/update-version.sh <新しいバージョン番号> [変更タイプ]
```

**例:**
```bash
# パッチバージョンの更新
./scripts/update-version.sh 1.2.1 patch

# マイナーバージョンの更新
./scripts/update-version.sh 1.3.0 minor

# メジャーバージョンの更新
./scripts/update-version.sh 2.0.0 major
```

**実行内容:**
1. package.json のバージョンを更新
2. index.json に新しいバージョンエントリを追加（手動編集が必要）
3. CHANGELOG.md にテンプレートを追加（手動で変更内容を記入）
4. zipファイルを作成してSHA256ハッシュを計算
5. 変更をコミット（オプション）
6. Git タグを作成（オプション）

**注意事項:**
- index.json と CHANGELOG.md は手動での編集が必要です
- スクリプトは対話的に進行します
- 各ステップで確認を求められます

---

## 推奨ワークフロー

### 1. 元のリポジトリから変更を同期

```bash
# 最新の変更を取得
./scripts/sync-from-upstream.sh

# 変更内容を確認
git diff
```

### 2. 動作確認

- Unity エディタで動作テスト
- 既存機能が正常に動作するか確認
- 新機能が追加されている場合は機能テスト

### 3. バージョン更新とリリース

```bash
# バージョン番号を更新してリリース準備
./scripts/update-version.sh 1.2.1

# プッシュ
git push origin <branch-name>
git push origin v1.2.1
```

### 4. デプロイとテスト

- GitHub Actions の実行を確認
- GitHub Pages で index.json が更新されているか確認
- VCC (ALCOM) で新しいバージョンが表示されるか確認
- テストプロジェクトでインストールテスト

---

## トラブルシューティング

### スクリプトが実行できない

実行権限を付与してください:
```bash
chmod +x scripts/*.sh
```

### 一時ディレクトリが残っている

手動で削除してください:
```bash
rm -rf /tmp/tex-col-adjuster-upstream
```

### Git コミットが失敗する

- 既に変更がコミットされている可能性があります
- `git status` で状態を確認してください
- 必要に応じて手動でコミットしてください

---

## スクリプトのカスタマイズ

スクリプトは bash で書かれています。必要に応じて編集してプロジェクトに合わせてカスタマイズできます。

主な変更ポイント:
- `UPSTREAM_REPO`: 元のリポジトリのURL
- `UPSTREAM_PACKAGE_NAME`: 元のパッケージ名
- `TEST_PACKAGE_NAME`: テスト用のパッケージ名
- 同期するファイルやディレクトリのリスト
