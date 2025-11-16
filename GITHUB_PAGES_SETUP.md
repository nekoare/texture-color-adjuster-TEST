# GitHub Pages セットアップ手順

このドキュメントでは、texture-color-adjuster-TESTリポジトリでGitHub Pagesを有効化する手順を説明します。

## 前提条件

- GitHubリポジトリ `nekoare/texture-color-adjuster-TEST` へのアクセス権限
- リポジトリの Settings へのアクセス権限

## セットアップ手順

### 1. GitHub Pagesを有効化

1. GitHubで https://github.com/nekoare/texture-color-adjuster-TEST にアクセス
2. リポジトリの **Settings** タブをクリック
3. 左サイドバーの **Pages** をクリック
4. **Source** セクションで以下を設定：
   - **Source**: `GitHub Actions` を選択

   **注意**: `Deploy from a branch` ではなく `GitHub Actions` を選択してください

5. **Save** をクリック（表示される場合）

### 2. GitHub Actionsワークフローを手動実行

GitHub Pagesの設定が完了したら、ワークフローを手動で実行します：

1. リポジトリの **Actions** タブをクリック
2. 左サイドバーから **Deploy to GitHub Pages** ワークフローを選択
3. **Run workflow** ボタンをクリック
4. ブランチを選択（通常は `claude/setup-texcolor-adjuster-tests-011CUshE8X6rRMiWWjBp9HzZ`）
5. **Run workflow** をクリックして実行

### 3. デプロイの確認

1. Actionsタブでワークフローの実行状態を確認
2. 正常に完了したら（緑のチェックマーク）、以下のURLにアクセス：
   ```
   https://nekoare.github.io/texture-color-adjuster-TEST/index.json
   ```
3. JSONファイルが正しく表示されることを確認

### 4. VCCでの確認

1. VCC (ALCOM) を開く
2. **Settings** → **Packages** → **Add Repository** をクリック
3. 以下のURLを入力：
   ```
   https://nekoare.github.io/texture-color-adjuster-TEST/index.json
   ```
4. リポジトリが正常に追加されることを確認

## トラブルシューティング

### "GitHub Pages is not enabled"エラー

**原因**: GitHub Pagesが有効化されていない

**解決方法**:
1. Settings → Pages に移動
2. Source を `GitHub Actions` に設定

### ワークフローが失敗する

**原因**: パッケージファイルが見つからない、または権限の問題

**確認事項**:
1. `Packages/dev.nekoare.tex-col-adjuster-test/package.json` が存在するか確認
2. ワークフローのログを確認してエラーメッセージを確認
3. リポジトリの Permissions 設定を確認：
   - Settings → Actions → General
   - **Workflow permissions** が `Read and write permissions` になっているか確認

### 404エラーが続く

**原因**: GitHub Pagesのデプロイが完了していない、またはURLが間違っている

**確認事項**:
1. Actions タブでワークフローが正常に完了しているか確認
2. デプロイには数分かかる場合があります
3. ブラウザのキャッシュをクリアして再試行
4. URLが正しいか確認：
   - 正: `https://nekoare.github.io/texture-color-adjuster-TEST/index.json`
   - 誤: `https://github.com/nekoare/texture-color-adjuster-TEST/index.json`

### index.jsonが古いバージョンのまま

**原因**: キャッシュの問題、またはワークフローが最新のコードで実行されていない

**解決方法**:
1. ブラウザのキャッシュをクリア
2. ワークフローを再実行
3. URLに `?t=` とタイムスタンプを追加してキャッシュを回避：
   ```
   https://nekoare.github.io/texture-color-adjuster-TEST/index.json?t=1234567890
   ```

## 参考情報

### GitHub Pagesの設定場所

```
https://github.com/nekoare/texture-color-adjuster-TEST/settings/pages
```

### GitHub Actionsの設定場所

```
https://github.com/nekoare/texture-color-adjuster-TEST/settings/actions
```

### ワークフローの実行履歴

```
https://github.com/nekoare/texture-color-adjuster-TEST/actions
```

## 次のステップ

GitHub Pagesが正常に動作したら、以下のドキュメントを参照して通常のアップデート手順を実行できます：

- [アップデート手順](UPDATE_PROCEDURE.md)
- [クイックチェックリスト](UPDATE_CHECKLIST.md)
- [スクリプト説明](scripts/README.md)

## 注意事項

- **mainブランチは必須ではありません**: GitHub Actionsワークフローは `workflow_dispatch` で手動実行できます
- **自動デプロイ**: 将来的に `main` ブランチを作成すれば、そのブランチへのpushで自動的にデプロイされます
- **テスト環境**: このリポジトリはテスト環境なので、本番環境（texture-color-adjuster）とは別のURLを使用しています
