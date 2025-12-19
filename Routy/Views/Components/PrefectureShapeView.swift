//
//  PrefectureShapeView.swift
//  Routy
//
//  Created by Claude on 2025/12/20.
//

import SwiftUI

/// 都道府県の形状をSVGパスで描画するShape
struct PrefectureShape: Shape {
    let pathData: String
    let transform: CGAffineTransform

    func path(in rect: CGRect) -> Path {
        let bezierPath = SVGPathParser.parse(pathData)
        var path = Path(bezierPath.cgPath)

        // SVGの座標系からビューの座標系にスケーリング
        let bounds = path.boundingRect
        if bounds.width > 0 && bounds.height > 0 {
            let scaleX = rect.width / bounds.width
            let scaleY = rect.height / bounds.height
            let scale = min(scaleX, scaleY)

            // 中央に配置するためのオフセット計算
            let scaledWidth = bounds.width * scale
            let scaledHeight = bounds.height * scale
            let offsetX = (rect.width - scaledWidth) / 2 - bounds.minX * scale
            let offsetY = (rect.height - scaledHeight) / 2 - bounds.minY * scale

            var transform = CGAffineTransform(scaleX: scale, y: scale)
            transform = transform.translatedBy(x: offsetX / scale, y: offsetY / scale)

            path = path.applying(transform)
        }

        return path
    }
}

/// 都道府県の形状を表示するビュー
struct PrefectureShapeView: View {
    let prefecture: Prefecture
    let level: PrefectureLevel
    let size: CGSize

    var body: some View {
        if let shapeData = PrefectureShapeData.shape(for: prefecture.id) {
            PrefectureShape(
                pathData: shapeData.pathData,
                transform: shapeData.transform
            )
            .fill(level.color)
            .frame(width: size.width, height: size.height)
            .overlay(
                PrefectureShape(
                    pathData: shapeData.pathData,
                    transform: shapeData.transform
                )
                .stroke(Color.white, lineWidth: 1)
            )
        } else {
            // フォールバック: 形状データがない場合は従来の四角形表示
            RoundedRectangle(cornerRadius: 6)
                .fill(level.color)
                .frame(width: size.width, height: size.height)
                .overlay(
                    Text(simplifyName(prefecture.name))
                        .font(.system(size: size.width * 0.35, weight: .bold))
                        .foregroundColor(level == .none ? .gray : .white)
                        .minimumScaleFactor(0.5)
                )
        }
    }

    private func simplifyName(_ name: String) -> String {
        if name.hasSuffix("県") { return String(name.dropLast()) }
        if name.hasSuffix("府") { return String(name.dropLast()) }
        if name == "東京都" { return "東京" }
        return name
    }
}

#Preview {
    VStack(spacing: 20) {
        // 北海道
        PrefectureShapeView(
            prefecture: japanPrefectures[0],
            level: .visited,
            size: CGSize(width: 150, height: 150)
        )
        .border(Color.gray)

        // 東京都
        PrefectureShapeView(
            prefecture: japanPrefectures[12],
            level: .stayed,
            size: CGSize(width: 150, height: 150)
        )
        .border(Color.gray)

        // 大阪府
        PrefectureShapeView(
            prefecture: japanPrefectures[26],
            level: .landed,
            size: CGSize(width: 150, height: 150)
        )
        .border(Color.gray)
    }
    .padding()
}
