//
//  PinAnnotation.swift
//  Routy
//
//  Created by 垣原親伍 on 2025/12/18.
//

import SwiftUI

/// カスタムピンAnnotation
struct PinAnnotation: View {
    let checkpoint: Checkpoint
    let isSelected: Bool

    var body: some View {
        ZStack {
            // ピンの影
            Circle()
                .fill(.black.opacity(0.2))
                .frame(width: isSelected ? 12 : 8, height: isSelected ? 12 : 8)
                .offset(y: isSelected ? 20 : 16)

            // ピン本体
            VStack(spacing: 0) {
                Circle()
                    .fill(pinColor)
                    .frame(width: isSelected ? 36 : 28, height: isSelected ? 36 : 28)
                    .overlay(
                        Image(systemName: pinIcon)
                            .font(.system(size: isSelected ? 16 : 12))
                            .foregroundColor(.white)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)

                // ピンの先端
                Triangle()
                    .fill(pinColor)
                    .frame(width: isSelected ? 12 : 8, height: isSelected ? 12 : 8)
                    .offset(y: -1)
            }
        }

        .scaleEffect(isSelected ? 1.2 : 1.0)
        .overlay(alignment: .top) {
            if isSelected {
                CalloutView(checkpoint: checkpoint)
                    .offset(y: -250) // ピンの上に表示（画像が大きくなったので調整）
                    .transition(.scale.combined(with: .opacity).animation(.spring(duration: 0.2)))
            }
        }
        .animation(.spring(response: 0.3), value: isSelected)
        .zIndex(isSelected ? 100 : 0) // 選択されたピンを最前面に
    }

    private var pinColor: Color {
        switch checkpoint.type {
        case .photo:
            return .blue
        case .manualCheckin:
            return .green
        }
    }

    private var pinIcon: String {
        switch checkpoint.type {
        case .photo:
            return "camera.fill"
        case .manualCheckin:
            return "mappin"
        }
    }
}

struct CalloutView: View {
    let checkpoint: Checkpoint

    var body: some View {
        VStack(spacing: 8) {
            // 大きな画像
            if let assetID = checkpoint.photoAssetID {
                PhotoAssetView(assetID: assetID)
                    .frame(width: 200, height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else if let url = checkpoint.photoThumbnailURL, let imageURL = URL(string: url) {
                AsyncImage(url: imageURL) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    ProgressView()
                }
                .frame(width: 200, height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                ZStack {
                    Color(.systemGray6)
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                }
                .frame(width: 200, height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // 情報カード
            VStack(spacing: 4) {
                Text(checkpoint.name ?? "スポット")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text(DateFormatter.japaneseDateTime.string(from: checkpoint.timestamp))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(width: 200)
            .background(Color(UIColor.systemBackground))
            .cornerRadius(10)
            .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)

            // 吹き出しの三角
            Triangle()
                .fill(Color(UIColor.systemBackground))
                .frame(width: 14, height: 10)
                .rotationEffect(.degrees(180))
                .offset(y: -1)
        }
    }
}

/// 三角形のShape
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    VStack(spacing: 40) {
        PinAnnotation(
            checkpoint: Checkpoint(
                latitude: 35.6812,
                longitude: 139.7671,
                timestamp: Date(),
                type: .photo
            ),
            isSelected: false
        )

        PinAnnotation(
            checkpoint: Checkpoint(
                latitude: 35.6812,
                longitude: 139.7671,
                timestamp: Date(),
                type: .photo
            ),
            isSelected: true
        )

        PinAnnotation(
            checkpoint: Checkpoint(
                latitude: 35.6812,
                longitude: 139.7671,
                timestamp: Date(),
                type: .manualCheckin
            ),
            isSelected: false
        )
    }
    .padding()
}
