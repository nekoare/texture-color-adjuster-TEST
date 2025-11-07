#!/bin/bash

# TextureColorAdjuster バージョン更新スクリプト
# 使用方法: ./scripts/update-version.sh <新しいバージョン番号> [<変更内容の種類>]
# 例: ./scripts/update-version.sh 1.2.1 patch

set -e

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 引数チェック
if [ $# -lt 1 ]; then
    echo -e "${RED}エラー: バージョン番号を指定してください${NC}"
    echo "使用方法: $0 <バージョン番号> [変更タイプ]"
    echo "例: $0 1.2.1 patch"
    exit 1
fi

NEW_VERSION=$1
CHANGE_TYPE=${2:-"minor"}  # デフォルトはminor
PACKAGE_NAME="dev.nekoare.tex-col-adjuster-test"
PACKAGE_DIR="Packages/${PACKAGE_NAME}"
PACKAGE_JSON="${PACKAGE_DIR}/package.json"
INDEX_JSON="index.json"
CHANGELOG="CHANGELOG.md"

# リポジトリのルートディレクトリに移動
cd "$(dirname "$0")/.."

echo -e "${GREEN}=== TextureColorAdjuster バージョン更新 ===${NC}"
echo "新しいバージョン: ${NEW_VERSION}"
echo "変更タイプ: ${CHANGE_TYPE}"
echo ""

# 現在のバージョンを取得
CURRENT_VERSION=$(grep '"version":' "${PACKAGE_JSON}" | head -1 | sed 's/.*"version": "\(.*\)".*/\1/')
echo "現在のバージョン: ${CURRENT_VERSION}"
echo ""

# 確認
read -p "バージョンを ${CURRENT_VERSION} から ${NEW_VERSION} に更新しますか? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}キャンセルしました${NC}"
    exit 1
fi

# 1. package.json のバージョンを更新
echo -e "${GREEN}[1/5] package.json を更新中...${NC}"
sed -i "s/\"version\": \"${CURRENT_VERSION}\"/\"version\": \"${NEW_VERSION}\"/" "${PACKAGE_JSON}"
echo "✓ package.json を更新しました"

# 2. index.json に新しいバージョンエントリを追加
echo -e "${GREEN}[2/5] index.json に新しいバージョンを追加中...${NC}"
echo -e "${YELLOW}注意: index.json は手動で編集する必要があります${NC}"
echo "以下の手順を実行してください:"
echo "  1. ${INDEX_JSON} を開く"
echo "  2. 最新のバージョンエントリをコピー"
echo "  3. version を ${NEW_VERSION} に変更"
echo "  4. url を https://nekoare.github.io/texture-color-adjuster-TEST/${PACKAGE_NAME}-v${NEW_VERSION}.zip に変更"
echo "  5. zipSHA256 は仮値 (0000...) を設定"
echo ""
read -p "index.json の編集が完了したら Enter を押してください..."

# 3. CHANGELOG.md を更新
echo -e "${GREEN}[3/5] CHANGELOG.md を更新中...${NC}"
CURRENT_DATE=$(date +%Y-%m-%d)
TEMP_FILE=$(mktemp)

# 既存のCHANGELOGの先頭に新しいエントリを追加
cat > "${TEMP_FILE}" << EOF
# Changelog

## [${NEW_VERSION}] - ${CURRENT_DATE}

### Added
-

### Changed
-

### Fixed
-

### Removed
-

EOF

# 既存のCHANGELOGの内容を追加（最初の"# Changelog"行を除く）
tail -n +2 "${CHANGELOG}" >> "${TEMP_FILE}" || echo "" >> "${TEMP_FILE}"
mv "${TEMP_FILE}" "${CHANGELOG}"

echo "✓ CHANGELOG.md にテンプレートを追加しました"
echo -e "${YELLOW}注意: ${CHANGELOG} を編集して変更内容を記入してください${NC}"
echo ""
read -p "CHANGELOG.md の編集が完了したら Enter を押してください..."

# 4. zipファイルを作成してSHA256を計算
echo -e "${GREEN}[4/5] zipファイルを作成中...${NC}"
cd Packages
ZIP_FILE="${PACKAGE_NAME}-v${NEW_VERSION}.zip"

# 既存のzipファイルがあれば削除
if [ -f "${ZIP_FILE}" ]; then
    rm "${ZIP_FILE}"
fi

# zipファイルを作成
zip -r "${ZIP_FILE}" "${PACKAGE_NAME}/" -x "*.meta" "*.DS_Store"
echo "✓ ${ZIP_FILE} を作成しました"

# SHA256を計算
SHA256=$(sha256sum "${ZIP_FILE}" | awk '{print $1}')
echo ""
echo -e "${GREEN}SHA256 ハッシュ:${NC}"
echo -e "${YELLOW}${SHA256}${NC}"
echo ""
echo "この値を index.json の zipSHA256 フィールドに設定してください"
cd ..

echo ""
read -p "index.json の zipSHA256 を更新したら Enter を押してください..."

# 5. 変更をコミット
echo -e "${GREEN}[5/5] Git コミットの準備...${NC}"
echo "以下のファイルが変更されました:"
git status --short

echo ""
read -p "これらの変更をコミットしますか? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    git add -A
    git commit -m "Update to version ${NEW_VERSION}

- Updated package.json version
- Added version ${NEW_VERSION} to index.json
- Updated CHANGELOG.md
- Created package zip file"

    echo ""
    read -p "タグ v${NEW_VERSION} を作成しますか? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git tag -a "v${NEW_VERSION}" -m "Version ${NEW_VERSION}"
        echo -e "${GREEN}✓ タグ v${NEW_VERSION} を作成しました${NC}"
    fi

    echo ""
    echo -e "${GREEN}完了しました！${NC}"
    echo ""
    echo "次のステップ:"
    echo "  1. git push origin <branch-name>"
    echo "  2. git push origin v${NEW_VERSION}"
    echo "  3. GitHub Actions の実行を確認"
    echo "  4. VCC でテスト"
else
    echo -e "${YELLOW}コミットをスキップしました${NC}"
fi
