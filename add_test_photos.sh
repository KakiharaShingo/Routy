#!/bin/bash

# テスト用の位置情報付き写真をシミュレーターに追加するスクリプト

# 起動中のシミュレーターを取得
DEVICE_ID=$(xcrun simctl list devices | grep "Booted" | grep -o -E '\([A-Z0-9-]+\)' | tr -d '()')

if [ -z "$DEVICE_ID" ]; then
    echo "エラー: 起動中のシミュレーターが見つかりません"
    echo "シミュレーターを起動してから再実行してください"
    exit 1
fi

echo "シミュレーター $DEVICE_ID に写真を追加します..."

# サンプル画像のURLリスト（位置情報付き）
# これらはフリーの位置情報付きサンプル画像です
SAMPLE_IMAGES=(
    "https://github.com/ianare/exif-samples/raw/master/jpg/gps/DSCN0010.jpg"
    "https://github.com/ianare/exif-samples/raw/master/jpg/gps/DSCN0012.jpg"
    "https://github.com/ianare/exif-samples/raw/master/jpg/gps/DSCN0021.jpg"
    "https://github.com/ianare/exif-samples/raw/master/jpg/gps/DSCN0025.jpg"
    "https://github.com/ianare/exif-samples/raw/master/jpg/gps/DSCN0029.jpg"
)

# 一時ディレクトリを作成
TEMP_DIR=$(mktemp -d)
echo "一時ディレクトリ: $TEMP_DIR"

# 画像をダウンロード
echo "画像をダウンロード中..."
cd "$TEMP_DIR"
for i in "${!SAMPLE_IMAGES[@]}"; do
    curl -L -o "photo_$i.jpg" "${SAMPLE_IMAGES[$i]}" 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "✓ photo_$i.jpg ダウンロード完了"
    fi
done

# シミュレーターに追加
echo ""
echo "シミュレーターに写真を追加中..."
for file in *.jpg; do
    if [ -f "$file" ]; then
        xcrun simctl addmedia "$DEVICE_ID" "$file"
        echo "✓ $file を追加しました"
    fi
done

# クリーンアップ
rm -rf "$TEMP_DIR"

echo ""
echo "完了！シミュレーターの写真アプリを確認してください。"
echo ""
echo "アプリで使用するには:"
echo "1. TravelLogアプリを起動"
echo "2. 「日付選択」をタップ"
echo "3. 適切な日付範囲を選択（今日から1週間前など）"
echo "4. 「写真を読込」をタップ"
