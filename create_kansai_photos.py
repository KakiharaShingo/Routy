#!/usr/bin/env python3
"""
関西地域の位置情報付きテスト写真を生成するスクリプト
"""

import os
import subprocess
import random
from datetime import datetime, timedelta
from PIL import Image
import piexif
from io import BytesIO

# 関西の有名な場所の座標
KANSAI_LOCATIONS = [
    # 大阪
    {"name": "大阪城", "lat": 34.6873, "lon": 135.5262, "city": "大阪"},
    {"name": "道頓堀", "lat": 34.6686, "lon": 135.5006, "city": "大阪"},
    {"name": "通天閣", "lat": 34.6523, "lon": 135.5063, "city": "大阪"},
    {"name": "梅田スカイビル", "lat": 34.7055, "lon": 135.4903, "city": "大阪"},
    {"name": "海遊館", "lat": 34.6547, "lon": 135.4291, "city": "大阪"},
    {"name": "USJ", "lat": 34.6654, "lon": 135.4321, "city": "大阪"},
    {"name": "天王寺動物園", "lat": 34.6509, "lon": 135.5097, "city": "大阪"},

    # 京都
    {"name": "清水寺", "lat": 34.9949, "lon": 135.7850, "city": "京都"},
    {"name": "金閣寺", "lat": 35.0394, "lon": 135.7292, "city": "京都"},
    {"name": "伏見稲荷大社", "lat": 34.9671, "lon": 135.7727, "city": "京都"},
    {"name": "嵐山", "lat": 35.0096, "lon": 135.6768, "city": "京都"},
    {"name": "祇園", "lat": 35.0037, "lon": 135.7783, "city": "京都"},
    {"name": "京都駅", "lat": 34.9859, "lon": 135.7581, "city": "京都"},
    {"name": "銀閣寺", "lat": 35.0269, "lon": 135.7983, "city": "京都"},
    {"name": "二条城", "lat": 35.0142, "lon": 135.7481, "city": "京都"},

    # 神戸
    {"name": "神戸ポートタワー", "lat": 34.6829, "lon": 135.1862, "city": "神戸"},
    {"name": "メリケンパーク", "lat": 34.6808, "lon": 135.1864, "city": "神戸"},
    {"name": "北野異人館街", "lat": 34.6958, "lon": 135.1898, "city": "神戸"},
    {"name": "六甲山", "lat": 34.7676, "lon": 135.2308, "city": "神戸"},
    {"name": "南京町", "lat": 34.6902, "lon": 135.1915, "city": "神戸"},

    # 奈良
    {"name": "東大寺", "lat": 34.6890, "lon": 135.8398, "city": "奈良"},
    {"name": "奈良公園", "lat": 34.6850, "lon": 135.8432, "city": "奈良"},
    {"name": "春日大社", "lat": 34.6812, "lon": 135.8482, "city": "奈良"},
    {"name": "興福寺", "lat": 34.6828, "lon": 135.8323, "city": "奈良"},

    # 和歌山
    {"name": "和歌山城", "lat": 34.2266, "lon": 135.1706, "city": "和歌山"},
    {"name": "高野山", "lat": 34.2135, "lon": 135.5804, "city": "和歌山"},
    {"name": "白浜", "lat": 33.6914, "lon": 135.3386, "city": "和歌山"},

    # 滋賀
    {"name": "彦根城", "lat": 35.2764, "lon": 136.2517, "city": "滋賀"},
    {"name": "琵琶湖", "lat": 35.2167, "lon": 136.1000, "city": "滋賀"},
]

def dms_to_rational(degrees, minutes, seconds):
    """度分秒をExif用のRational形式に変換"""
    d = (int(degrees * 1000000), 1000000)
    m = (int(minutes * 1000000), 1000000)
    s = (int(seconds * 1000000), 1000000)
    return (d, m, s)

def decimal_to_dms(decimal_degree):
    """10進数の座標を度分秒に変換"""
    degrees = int(decimal_degree)
    minutes_decimal = (decimal_degree - degrees) * 60
    minutes = int(minutes_decimal)
    seconds = (minutes_decimal - minutes) * 60
    return degrees, minutes, seconds

def create_photo_with_exif(location, timestamp, output_path):
    """位置情報付きの写真を生成"""
    # ランダムな色のグラデーション画像を生成
    width, height = 1200, 900
    img = Image.new('RGB', (width, height))
    pixels = img.load()

    # ランダムな色を選択
    colors = [
        (135, 206, 235),  # スカイブルー
        (255, 182, 193),  # ライトピンク
        (144, 238, 144),  # ライトグリーン
        (255, 218, 185),  # ピーチ
        (221, 160, 221),  # プラム
        (176, 224, 230),  # パウダーブルー
    ]
    base_color = random.choice(colors)

    # グラデーション効果
    for y in range(height):
        for x in range(width):
            r = int(base_color[0] * (1 - y / height * 0.3))
            g = int(base_color[1] * (1 - y / height * 0.3))
            b = int(base_color[2] * (1 - y / height * 0.3))
            pixels[x, y] = (r, g, b)

    # EXIF情報を作成
    exif_dict = {
        "0th": {},
        "Exif": {},
        "GPS": {},
        "1st": {},
    }

    # 位置情報を追加
    lat = location["lat"]
    lon = location["lon"]

    lat_deg, lat_min, lat_sec = decimal_to_dms(abs(lat))
    lon_deg, lon_min, lon_sec = decimal_to_dms(abs(lon))

    exif_dict["GPS"][piexif.GPSIFD.GPSLatitudeRef] = 'N' if lat >= 0 else 'S'
    exif_dict["GPS"][piexif.GPSIFD.GPSLatitude] = dms_to_rational(lat_deg, lat_min, lat_sec)
    exif_dict["GPS"][piexif.GPSIFD.GPSLongitudeRef] = 'E' if lon >= 0 else 'W'
    exif_dict["GPS"][piexif.GPSIFD.GPSLongitude] = dms_to_rational(lon_deg, lon_min, lon_sec)

    # 撮影日時を追加
    exif_dict["Exif"][piexif.ExifIFD.DateTimeOriginal] = timestamp.strftime("%Y:%m:%d %H:%M:%S")
    exif_dict["0th"][piexif.ImageIFD.DateTime] = timestamp.strftime("%Y:%m:%d %H:%M:%S")

    # カメラ情報を追加
    exif_dict["0th"][piexif.ImageIFD.Make] = b"Apple"
    exif_dict["0th"][piexif.ImageIFD.Model] = b"iPhone 15 Pro"

    # EXIF情報をバイト列に変換
    exif_bytes = piexif.dump(exif_dict)

    # 画像を保存
    img.save(output_path, exif=exif_bytes, quality=95)
    print(f"✓ 作成: {output_path} - {location['name']} ({timestamp.strftime('%Y-%m-%d %H:%M')})")

def main():
    # 出力ディレクトリを作成
    output_dir = "/tmp/kansai_photos"
    os.makedirs(output_dir, exist_ok=True)

    print("=" * 60)
    print("関西旅行の写真を生成中...")
    print("=" * 60)
    print()

    # 3日間の旅行を想定
    base_date = datetime.now() - timedelta(days=2)

    photos = []

    # 1日目: 大阪観光（午前から夜まで）
    day1 = base_date
    osaka_spots = [loc for loc in KANSAI_LOCATIONS if loc["city"] == "大阪"]
    random.shuffle(osaka_spots)

    print("📅 1日目: 大阪")
    time_offset = 9  # 午前9時スタート
    for i, spot in enumerate(osaka_spots[:7]):
        photo_time = day1.replace(hour=time_offset + i, minute=random.randint(0, 59), second=random.randint(0, 59))
        filename = f"{output_dir}/day1_{i+1:02d}_{spot['name']}.jpg"
        create_photo_with_exif(spot, photo_time, filename)
        photos.append(filename)

    print()

    # 2日目: 京都観光（朝から夕方まで）
    day2 = base_date + timedelta(days=1)
    kyoto_spots = [loc for loc in KANSAI_LOCATIONS if loc["city"] == "京都"]
    random.shuffle(kyoto_spots)

    print("📅 2日目: 京都")
    time_offset = 8  # 午前8時スタート
    for i, spot in enumerate(kyoto_spots[:8]):
        photo_time = day2.replace(hour=time_offset + i, minute=random.randint(0, 59), second=random.randint(0, 59))
        filename = f"{output_dir}/day2_{i+1:02d}_{spot['name']}.jpg"
        create_photo_with_exif(spot, photo_time, filename)
        photos.append(filename)

    print()

    # 3日目: 神戸・奈良・滋賀など
    day3 = base_date + timedelta(days=2)
    other_spots = [loc for loc in KANSAI_LOCATIONS if loc["city"] in ["神戸", "奈良", "和歌山", "滋賀"]]
    random.shuffle(other_spots)

    print("📅 3日目: 神戸・奈良など")
    time_offset = 9  # 午前9時スタート
    for i, spot in enumerate(other_spots[:10]):
        photo_time = day3.replace(hour=time_offset + i // 2, minute=random.randint(0, 59), second=random.randint(0, 59))
        filename = f"{output_dir}/day3_{i+1:02d}_{spot['name']}.jpg"
        create_photo_with_exif(spot, photo_time, filename)
        photos.append(filename)

    print()
    print("=" * 60)
    print(f"✅ 完了！ {len(photos)}枚の写真を生成しました")
    print(f"📁 保存先: {output_dir}")
    print()

    # シミュレーターに追加
    print("シミュレーターに写真を追加中...")
    try:
        # 起動中のシミュレーターを検出
        result = subprocess.run(
            ["xcrun", "simctl", "list", "devices"],
            capture_output=True,
            text=True
        )

        booted_device = None
        for line in result.stdout.split('\n'):
            if 'Booted' in line:
                # デバイスIDを抽出
                import re
                match = re.search(r'\(([A-Z0-9-]+)\)', line)
                if match:
                    booted_device = match.group(1)
                    break

        if booted_device:
            print(f"シミュレーター {booted_device} を検出")
            for photo in photos:
                subprocess.run(["xcrun", "simctl", "addmedia", booted_device, photo], check=True)
            print(f"✅ {len(photos)}枚の写真をシミュレーターに追加しました")
        else:
            print("⚠️  起動中のシミュレーターが見つかりません")
            print("   シミュレーターを起動してから、以下のコマンドで手動追加してください:")
            print(f"   xcrun simctl addmedia booted {output_dir}/*.jpg")
    except Exception as e:
        print(f"⚠️  シミュレーターへの追加中にエラー: {e}")
        print(f"   手動で追加してください: xcrun simctl addmedia booted {output_dir}/*.jpg")

    print()
    print("=" * 60)
    print("🎉 準備完了！")
    print()
    print("アプリで使用するには:")
    print("1. TravelLogアプリを起動")
    print("2. 「日付選択」をタップ")
    print(f"3. 期間: {base_date.strftime('%Y/%m/%d')} ～ {(base_date + timedelta(days=2)).strftime('%Y/%m/%d')}")
    print("4. 「写真を読込」をタップ")
    print("=" * 60)

if __name__ == "__main__":
    # 必要なパッケージをインストール
    try:
        import PIL
        import piexif
    except ImportError:
        print("必要なパッケージをインストール中...")
        subprocess.run(["pip3", "install", "Pillow", "piexif"], check=True)
        print("再度スクリプトを実行してください")
        exit(0)

    main()
