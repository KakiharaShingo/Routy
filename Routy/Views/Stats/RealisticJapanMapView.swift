//
//  RealisticJapanMapView.swift
//  Routy
//
//  Created by Claude on 2025/12/20.
//

import SwiftUI

/// リアルな日本地図ビュー(SVGベース)
struct RealisticJapanMapView: View {
    @Binding var stats: [Int: PrefectureLevel]
    var onSelect: (Prefecture) -> Void

    // SVG座標系の全体サイズ(geolonia/japanese-prefecturesのSVGサイズ)
    private let svgWidth: CGFloat = 1000
    private let svgHeight: CGFloat = 1200

    // ズームとパンの状態
    @GestureState private var magnifyBy = 1.0
    @State private var currentZoom: CGFloat = 1.0
    @State private var totalZoom: CGFloat = 1.0
    @GestureState private var dragOffset: CGSize = .zero
    @State private var totalOffset: CGSize = .zero

    var body: some View {
        GeometryReader { geometry in
            let baseScale = min(
                geometry.size.width / svgWidth,
                geometry.size.height / svgHeight
            )
            let finalZoom = totalZoom * magnifyBy
            let finalScale = baseScale * finalZoom
            let finalOffset = CGSize(
                width: totalOffset.width + dragOffset.width,
                height: totalOffset.height + dragOffset.height
            )

            Canvas { context, size in
                    for prefecture in japanPrefectures {
                        guard let shapeData = PrefectureShapeData.shape(for: prefecture.id) else {
                            continue
                        }

                        // キャッシュ済みのパスを取得
                        var path = shapeData.cachedPath()

                        // 全体のスケーリングと配置
                        let transform = CGAffineTransform(scaleX: finalScale, y: finalScale)
                        path = path.applying(transform)

                        // 塗りつぶし
                        let fillColor = stats[prefecture.id]?.color ?? PrefectureLevel.none.color
                        context.fill(path, with: .color(fillColor))

                        // 境界線
                        context.stroke(
                            path,
                            with: .color(.white.opacity(0.8)),
                            lineWidth: 1.0 / finalZoom
                        )
                    }
                }
            .frame(width: svgWidth * finalScale, height: svgHeight * finalScale)
            .offset(finalOffset)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            .gesture(
                SimultaneousGesture(
                    // ピンチでズーム
                    MagnifyGesture()
                        .updating($magnifyBy) { value, gestureState, _ in
                            gestureState = value.magnification
                        }
                        .onEnded { value in
                            totalZoom = max(1.0, min(totalZoom * value.magnification, 5.0))
                        },
                    // ドラッグでパンまたはタップ
                    DragGesture(minimumDistance: 0, coordinateSpace: .local)
                        .updating($dragOffset) { value, gestureState, _ in
                            // ズーム中はドラッグ
                            if totalZoom > 1.0 && (abs(value.translation.width) > 3 || abs(value.translation.height) > 3) {
                                gestureState = value.translation
                            }
                        }
                        .onEnded { value in
                            // ドラッグ距離が短ければタップとして処理
                            let distance = sqrt(pow(value.translation.width, 2) + pow(value.translation.height, 2))
                            if distance < 5 {
                                // タップ位置から都道府県を特定
                                let offsetX = (geometry.size.width - svgWidth * finalScale) / 2 + totalOffset.width
                                let offsetY = (geometry.size.height - svgHeight * finalScale) / 2 + totalOffset.height
                                let tapLocation = CGPoint(
                                    x: (value.location.x - offsetX) / finalScale,
                                    y: (value.location.y - offsetY) / finalScale
                                )

                                for prefecture in japanPrefectures {
                                    guard let shapeData = PrefectureShapeData.shape(for: prefecture.id) else {
                                        continue
                                    }

                                    let path = shapeData.cachedPath()

                                    if path.contains(tapLocation) {
                                        onSelect(prefecture)
                                        break
                                    }
                                }
                            } else if totalZoom > 1.0 {
                                // パン操作
                                totalOffset.width += value.translation.width
                                totalOffset.height += value.translation.height
                            }
                        }
                )
            )
            .overlay(
                // リセットボタン
                VStack {
                    HStack {
                        Spacer()
                        if totalZoom > 1.0 || totalOffset != .zero {
                            Button {
                                withAnimation(.spring(response: 0.3)) {
                                    totalZoom = 1.0
                                    totalOffset = .zero
                                }
                            } label: {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                    .frame(width: 36, height: 36)
                                    .background(Color.black.opacity(0.6))
                                    .clipShape(Circle())
                            }
                            .padding()
                        }
                    }
                    Spacer()
                }
            )
            .drawingGroup() // Metal描画を有効化
        }
    }
}

#Preview {
    RealisticJapanMapView(
        stats: .constant([
            1: .visited,   // 北海道
            13: .stayed,   // 東京
            27: .landed    // 大阪
        ])
    ) { prefecture in
        print("Selected: \(prefecture.name)")
    }
    .frame(height: 600)
    .background(Color(UIColor.systemGroupedBackground))
}
