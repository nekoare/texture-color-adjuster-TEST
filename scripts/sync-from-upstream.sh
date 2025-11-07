#!/bin/bash

# 元のリポジトリから変更を同期するスクリプト
# 使用方法: ./scripts/sync-from-upstream.sh

set -e

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

UPSTREAM_REPO="https://github.com/nekoare/texture-color-adjuster.git"
UPSTREAM_PACKAGE_NAME="dev.nekoare.tex-col-adjuster"
TEST_PACKAGE_NAME="dev.nekoare.tex-col-adjuster-test"
TEMP_DIR="/tmp/tex-col-adjuster-upstream"

# リポジトリのルートディレクトリに移動
cd "$(dirname "$0")/.."

echo -e "${GREEN}=== 元のリポジトリから変更を同期 ===${NC}"
echo "元のリポジトリ: ${UPSTREAM_REPO}"
echo ""

# 1. 元のリポジトリをクローン
echo -e "${GREEN}[1/5] 元のリポジトリをクローン中...${NC}"
if [ -d "${TEMP_DIR}" ]; then
    echo "一時ディレクトリが既に存在します。削除します..."
    rm -rf "${TEMP_DIR}"
fi

git clone "${UPSTREAM_REPO}" "${TEMP_DIR}"
echo "✓ クローンが完了しました"
echo ""

# 2. 最新のバージョンを確認
echo -e "${GREEN}[2/5] 元のリポジトリのバージョンを確認中...${NC}"
UPSTREAM_VERSION=$(grep '"version":' "${TEMP_DIR}/Packages/${UPSTREAM_PACKAGE_NAME}/package.json" | head -1 | sed 's/.*"version": "\(.*\)".*/\1/')
CURRENT_VERSION=$(grep '"version":' "Packages/${TEST_PACKAGE_NAME}/package.json" | head -1 | sed 's/.*"version": "\(.*\)".*/\1/')

echo "元のリポジトリバージョン: ${UPSTREAM_VERSION}"
echo "現在のテストバージョン: ${CURRENT_VERSION}"
echo ""

# 3. 変更の確認
echo -e "${GREEN}[3/5] 変更されたファイルを確認中...${NC}"
echo ""

# Editorフォルダの差分を表示
echo -e "${BLUE}Editor フォルダの変更:${NC}"
if [ -d "Packages/${TEST_PACKAGE_NAME}/Editor" ]; then
    diff -r "${TEMP_DIR}/Packages/${UPSTREAM_PACKAGE_NAME}/Editor" "Packages/${TEST_PACKAGE_NAME}/Editor" --brief || true
else
    echo "Editorフォルダが存在しません"
fi
echo ""

# その他のファイルの確認
echo -e "${BLUE}その他の変更:${NC}"
for file in LICENSE README.md CHANGELOG.md; do
    if [ -f "${TEMP_DIR}/${file}" ]; then
        if diff "${TEMP_DIR}/${file}" "${file}" > /dev/null 2>&1; then
            echo "  ${file}: 変更なし"
        else
            echo -e "  ${file}: ${YELLOW}変更あり${NC}"
        fi
    fi
done
echo ""

# 4. 同期の実行
read -p "変更を同期しますか? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}同期をキャンセルしました${NC}"
    rm -rf "${TEMP_DIR}"
    exit 0
fi

echo -e "${GREEN}[4/5] ファイルを同期中...${NC}"

# Editorフォルダを同期
if [ -d "${TEMP_DIR}/Packages/${UPSTREAM_PACKAGE_NAME}/Editor" ]; then
    echo "Editor フォルダを同期中..."
    mkdir -p "Packages/${TEST_PACKAGE_NAME}/Editor"
    cp -r "${TEMP_DIR}/Packages/${UPSTREAM_PACKAGE_NAME}/Editor/"* "Packages/${TEST_PACKAGE_NAME}/Editor/"
    echo "✓ Editor フォルダを同期しました"
fi

# Runtimeフォルダがあれば同期
if [ -d "${TEMP_DIR}/Packages/${UPSTREAM_PACKAGE_NAME}/Runtime" ]; then
    echo "Runtime フォルダを同期中..."
    mkdir -p "Packages/${TEST_PACKAGE_NAME}/Runtime"
    cp -r "${TEMP_DIR}/Packages/${UPSTREAM_PACKAGE_NAME}/Runtime/"* "Packages/${TEST_PACKAGE_NAME}/Runtime/"
    echo "✓ Runtime フォルダを同期しました"
fi

# Resourcesフォルダがあれば同期
if [ -d "${TEMP_DIR}/Packages/${UPSTREAM_PACKAGE_NAME}/Resources" ]; then
    echo "Resources フォルダを同期中..."
    mkdir -p "Packages/${TEST_PACKAGE_NAME}/Resources"
    cp -r "${TEMP_DIR}/Packages/${UPSTREAM_PACKAGE_NAME}/Resources/"* "Packages/${TEST_PACKAGE_NAME}/Resources/"
    echo "✓ Resources フォルダを同期しました"
fi

# CHANGELOG.mdを同期（ただしテスト用の注釈を保持）
if [ -f "${TEMP_DIR}/CHANGELOG.md" ]; then
    echo "CHANGELOG.md を同期中..."
    cp "${TEMP_DIR}/CHANGELOG.md" "CHANGELOG.md"
    echo "✓ CHANGELOG.md を同期しました"
fi

# LICENSEを同期
if [ -f "${TEMP_DIR}/LICENSE" ]; then
    echo "LICENSE を同期中..."
    cp "${TEMP_DIR}/LICENSE" "LICENSE"
    echo "✓ LICENSE を同期しました"
fi

echo ""

# 5. クリーンアップ
echo -e "${GREEN}[5/5] クリーンアップ中...${NC}"
rm -rf "${TEMP_DIR}"
echo "✓ 一時ファイルを削除しました"
echo ""

# 変更内容を表示
echo -e "${GREEN}同期が完了しました！${NC}"
echo ""
echo -e "${YELLOW}次のステップ:${NC}"
echo "  1. 変更内容を確認: git diff"
echo "  2. 動作テストを実行"
echo "  3. バージョン番号を更新: ./scripts/update-version.sh ${UPSTREAM_VERSION}"
echo "  4. コミットしてプッシュ"
echo ""

# 変更されたファイルを表示
echo -e "${BLUE}変更されたファイル:${NC}"
git status --short
