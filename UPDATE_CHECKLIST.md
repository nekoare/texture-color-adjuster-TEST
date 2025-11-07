# アップデート クイックチェックリスト

## 事前準備
- [ ] 元のリポジトリの最新版を確認
- [ ] 新しいバージョン番号を決定（例: 1.2.1）

## ファイル更新
- [ ] Editorフォルダ内のファイルを最新版に置き換え
- [ ] `package.json` のバージョン番号を更新
- [ ] `index.json` に新バージョンエントリを追加（SHA256は仮値でOK）
- [ ] `CHANGELOG.md` に変更内容を記載

## パッケージ作成
- [ ] zipファイルを作成
  ```bash
  cd Packages
  zip -r dev.nekoare.tex-col-adjuster-test-vX.Y.Z.zip dev.nekoare.tex-col-adjuster-test/
  ```
- [ ] SHA256ハッシュを計算して `index.json` を更新
  ```bash
  sha256sum dev.nekoare.tex-col-adjuster-test-vX.Y.Z.zip
  ```

## Git操作
- [ ] `git add -A`
- [ ] `git commit -m "Update to version X.Y.Z"`
- [ ] `git tag -a vX.Y.Z -m "Version X.Y.Z"`
- [ ] `git push origin <branch-name>`
- [ ] `git push origin vX.Y.Z`

## 検証
- [ ] GitHub Actionsが正常に完了
- [ ] GitHub PagesのURLで `index.json` を確認
- [ ] VCCで新バージョンが表示されるか確認
- [ ] テストプロジェクトでインストールテスト

## 完了後
- [ ] 問題なければ本番環境（texture-color-adjuster）に反映
