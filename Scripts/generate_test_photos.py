#!/usr/bin/env python3
"""
テスト用の位置情報付き写真を生成してシミュレータに追加するスクリプト
"""

import os
import subprocess
from PIL import Image, ImageDraw, ImageFont
import piexif
from datetime import datetime, timedelta

# テストロケーションデータ
TEST_LOCATIONS = [
    {
        "name": "レストラン",
        "category": "restaurant",
        "lat": 35.6585805,
        "lon": 139.7454329,
        "color": (255, 149, 0),  # Orange
        "icon": "🍽️"
    },
    {
        "name": "カフェ",
        "category": "cafe",
        "lat": 35.6617773,
        "lon": 139.7040506,
        "color": (162, 132, 94),  # Brown
        "icon": "☕"
    },
    {
        "name": "ガソリンスタンド",
        "category": "gas_station",
        "lat": 35.6938107,
        "lon": 139.7033677,
        "color": (255, 59, 48),  # Red
        "icon": "⛽"
    },
    {
        "name": "ホテル",
        "category": "hotel",
        "lat": 35.6812362,
        "lon": 139.7671248,
        "color": (175, 82, 222),  # Purple
        "icon": "🏨"
    },
    {
        "name": "浅草寺",
        "category": "tourist",
        "lat": 35.7147651,
        "lon": 139.7966553,
        "color": (0, 122, 255),  # Blue
        "icon": "🗼"
    },
    {
        "name": "上野公園",
        "category": "park",
        "lat": 35.7148245,
        "lon": 139.7738466,
        "color": (52, 199, 89),  # Green
        "icon": "🌳"
    },
    {
        "name": "銀座三越",
        "category": "shopping",
        "lat": 35.6718285,
        "lon": 139.7654424,
        "color": (255, 45, 85),  # Pink
        "icon": "🛍️"
    },
    {
        "name": "東京駅",
        "category": "transport",
        "lat": 35.6812362,
        "lon": 139.7671248,
        "color": (90, 200, 250),  # Cyan
        "icon": "🚆"
    },
    {
        "name": "皇居",
        "category": "other",
        "lat": 35.6851915,
        "lon": 139.7527995,
        "color": (142, 142, 147),  # Gray
        "icon": "📍"
    }
]

CATEGORY_NAMES = {
    "restaurant": "レストラン",
    "cafe": "カフェ",
    "gas_station": "ガソリンスタンド",
    "hotel": "ホテル",
    "tourist": "観光",
    "park": "公園",
    "shopping": "ショッピング",
    "transport": "交通",
    "other": "その他"
}

def decimal_to_dms(decimal_degree, is_latitude=True):
    """10進数の緯度経度をDMS形式に変換"""
    is_positive = decimal_degree >= 0
    decimal_degree = abs(decimal_degree)

    degrees = int(decimal_degree)
    minutes_full = (decimal_degree - degrees) * 60
    minutes = int(minutes_full)
    seconds = (minutes_full - minutes) * 60

    # EXIF形式: ((degrees, 1), (minutes, 1), (seconds*10000, 10000))
    dms = ((degrees, 1), (minutes, 1), (int(seconds * 10000), 10000))

    if is_latitude:
        ref = 'N' if is_positive else 'S'
    else:
        ref = 'E' if is_positive else 'W'

    return dms, ref

def create_gradient_image(width, height, color_start, color_end):
    """グラデーション画像を生成"""
    image = Image.new('RGB', (width, height))
    draw = ImageDraw.Draw(image)

    for y in range(height):
        ratio = y / height
        r = int(color_start[0] * (1 - ratio) + color_end[0] * ratio)
        g = int(color_start[1] * (1 - ratio) + color_end[1] * ratio)
        b = int(color_start[2] * (1 - ratio) + color_end[2] * ratio)
        draw.line([(0, y), (width, y)], fill=(r, g, b))

    return image

def add_text_to_image(image, location_data, index):
    """画像にテキストを追加"""
    draw = ImageDraw.Draw(image)
    width, height = image.size

    try:
        # macOSのシステムフォントを使用
        title_font = ImageFont.truetype("/System/Library/Fonts/ヒラギノ角ゴシック W6.ttc", 60)
        subtitle_font = ImageFont.truetype("/System/Library/Fonts/ヒラギノ角ゴシック W3.ttc", 40)
        index_font = ImageFont.truetype("/System/Library/Fonts/ヒラギノ角ゴシック W3.ttc", 30)
    except:
        title_font = ImageFont.load_default()
        subtitle_font = ImageFont.load_default()
        index_font = ImageFont.load_default()

    # アイコン
    icon_text = location_data['icon']
    icon_bbox = draw.textbbox((0, 0), icon_text, font=title_font)
    icon_width = icon_bbox[2] - icon_bbox[0]
    draw.text((width // 2 - icon_width // 2, height * 0.25), icon_text, fill=(255, 255, 255, 230), font=title_font)

    # タイトル
    title = location_data['name']
    title_bbox = draw.textbbox((0, 0), title, font=title_font)
    title_width = title_bbox[2] - title_bbox[0]
    draw.text((width // 2 - title_width // 2, height * 0.55), title, fill=(255, 255, 255), font=title_font)

    # サブタイトル
    subtitle = CATEGORY_NAMES[location_data['category']]
    subtitle_bbox = draw.textbbox((0, 0), subtitle, font=subtitle_font)
    subtitle_width = subtitle_bbox[2] - subtitle_bbox[0]
    draw.text((width // 2 - subtitle_width // 2, height * 0.65), subtitle, fill=(255, 255, 255, 200), font=subtitle_font)

    # インデックス
    index_text = f"#{index}"
    draw.text((width - 120, height - 60), index_text, fill=(255, 255, 255, 150), font=index_font)

    return image

def generate_test_photo(location_data, index, output_dir):
    """テスト写真を生成"""
    width, height = 1600, 1200

    # グラデーション背景を生成
    color = location_data['color']
    color_start = tuple(int(c * 0.8) for c in color)
    color_end = tuple(int(c * 0.4) for c in color)

    image = create_gradient_image(width, height, color_start, color_end)

    # テキストを追加
    image = add_text_to_image(image, location_data, index)

    # ファイル名
    filename = f"{index:02d}_{location_data['category']}.jpg"
    filepath = os.path.join(output_dir, filename)

    # 位置情報をEXIFに埋め込む
    lat_dms, lat_ref = decimal_to_dms(location_data['lat'], is_latitude=True)
    lon_dms, lon_ref = decimal_to_dms(location_data['lon'], is_latitude=False)

    # 日時を30分ごとにずらす
    photo_date = datetime.now() + timedelta(minutes=index * 30)
    date_str = photo_date.strftime("%Y:%m:%d %H:%M:%S")

    exif_dict = {
        "0th": {},
        "Exif": {
            piexif.ExifIFD.DateTimeOriginal: date_str.encode(),
            piexif.ExifIFD.DateTimeDigitized: date_str.encode(),
        },
        "GPS": {
            piexif.GPSIFD.GPSLatitudeRef: lat_ref.encode(),
            piexif.GPSIFD.GPSLatitude: lat_dms,
            piexif.GPSIFD.GPSLongitudeRef: lon_ref.encode(),
            piexif.GPSIFD.GPSLongitude: lon_dms,
        }
    }

    exif_bytes = piexif.dump(exif_dict)

    # 画像を保存
    image.save(filepath, "JPEG", quality=95, exif=exif_bytes)
    print(f"✅ 生成: {filename} ({location_data['name']})")

    return filepath

def add_photos_to_simulator(photo_paths):
    """生成した写真をシミュレータに追加"""
    print("\n📱 シミュレータに写真を追加中...")

    # Bootedなシミュレータを取得
    result = subprocess.run(
        ["xcrun", "simctl", "list", "devices"],
        capture_output=True,
        text=True
    )

    booted_device = None
    for line in result.stdout.split('\n'):
        if '(Booted)' in line:
            # デバイスIDを抽出
            device_id = line.split('(')[1].split(')')[0]
            booted_device = device_id
            break

    if not booted_device:
        print("❌ 起動中のシミュレータが見つかりません")
        return False

    print(f"📱 シミュレータID: {booted_device}")

    # 写真を追加
    for photo_path in photo_paths:
        subprocess.run(
            ["xcrun", "simctl", "addmedia", booted_device, photo_path],
            check=True
        )

    print(f"✅ {len(photo_paths)}枚の写真をシミュレータに追加しました")
    return True

def main():
    """メイン処理"""
    print("🎨 テスト写真生成スクリプト")
    print("=" * 50)

    # 出力ディレクトリを作成
    output_dir = "/tmp/routy_test_photos"
    os.makedirs(output_dir, exist_ok=True)

    # 写真を生成
    photo_paths = []
    for index, location in enumerate(TEST_LOCATIONS, start=1):
        filepath = generate_test_photo(location, index, output_dir)
        photo_paths.append(filepath)

    print(f"\n✅ {len(photo_paths)}枚の写真を生成しました")
    print(f"📁 保存先: {output_dir}")

    # シミュレータに追加
    if add_photos_to_simulator(photo_paths):
        print("\n✨ 完了！シミュレータの写真アプリで確認してください")
    else:
        print("\n⚠️ シミュレータへの追加に失敗しました")
        print(f"手動で追加する場合: xcrun simctl addmedia <device_id> {output_dir}/*.jpg")

if __name__ == "__main__":
    main()
