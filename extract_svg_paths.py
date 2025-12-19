#!/usr/bin/env python3
"""
SVGから都道府県のパスデータを抽出するスクリプト
"""
import re
import urllib.request

# SVGをダウンロード
url = "https://raw.githubusercontent.com/geolonia/japanese-prefectures/master/map-full.svg"
with urllib.request.urlopen(url) as response:
    svg_content = response.read().decode('utf-8')

# 各都道府県のグループを抽出（gタグ全体とその中身）
prefecture_pattern = r'(<g[^>]*data-code="(\d+)"[^>]*>)(.*?)</g>'
matches = re.findall(prefecture_pattern, svg_content, re.DOTALL)

print("// 都道府県SVGパスデータ")
print("// 自動生成: extract_svg_paths.py")
print()

for g_tag, code, content in matches:
    # transformを抽出（gタグから）
    transform_match = re.search(r'transform="([^"]+)"', g_tag)
    transform = transform_match.group(1) if transform_match else ""

    # translate値を抽出
    translate_match = re.search(r'translate\(([^)]+)\)', transform)
    tx, ty = 0, 0
    if translate_match:
        coords = translate_match.group(1).split(',')
        tx = float(coords[0].strip())
        ty = float(coords[1].strip()) if len(coords) > 1 else 0

    # pathまたはpolygonを抽出
    path_data_list = []

    # path要素
    for path_match in re.finditer(r'<path[^>]*d="([^"]+)"', content):
        path_data_list.append(path_match.group(1))

    # polygon要素をpathに変換
    for polygon_match in re.finditer(r'<polygon[^>]*points="([^"]+)"', content):
        points_str = polygon_match.group(1).strip()
        # スペース区切りの座標を配列に変換 (x y x y ... 形式)
        coords = points_str.split()
        if len(coords) >= 2:
            # 2つずつペアにしてパスに変換
            path_parts = [f"M{coords[0]},{coords[1]}"]
            for i in range(2, len(coords), 2):
                if i + 1 < len(coords):
                    path_parts.append(f"L{coords[i]},{coords[i+1]}")
            path_parts.append("Z")
            path_data_list.append(" ".join(path_parts))

    if path_data_list:
        # 複数のパスを結合
        combined_path = " ".join(path_data_list)

        print(f"shapes[{code}] = PrefectureShapeData(")
        print(f"    prefectureId: {code},")
        print(f'    pathData: "{combined_path}",')
        print(f"    transform: CGAffineTransform(translationX: {tx}, y: {ty})")
        print(f")")
        print()
