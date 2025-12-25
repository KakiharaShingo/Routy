//
//  PinAnnotation.swift
//  Routy
//
//  Created by 垣原親伍 on 2025/12/18.
//

import SwiftUI
import MapKit

/// カスタムピンAnnotation
struct PinAnnotation: View {
    // checkpoint単体ではなく、グループを受け取るように変更
    // ただし、既存コードへの影響を最小限にするため、GroupedCheckpointを前提とするが
    // 呼び出し側で単体のCheckpointをラップしたGroupedCheckpointを作ることも可能
    let group: MapViewModel.GroupedCheckpoint
    let isSelected: Bool

    var checkpoint: Checkpoint {
        group.representative
    }
    
    var count: Int {
        group.checkpoints.count
    }

    var body: some View {
        ZStack {
            // ピンの影
            Circle()
                .fill(.black.opacity(0.2))
                .frame(width: isSelected ? 12 : 8, height: isSelected ? 12 : 8)
                .offset(y: isSelected ? 20 : 16)

            // ピン本体
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(pinColor)
                        .frame(width: isSelected ? 36 : 28, height: isSelected ? 36 : 28)
                        .overlay(
                            Image(systemName: pinIcon)
                                .font(.system(size: isSelected ? 16 : 12))
                                .foregroundColor(.white)
                        )
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                    
                    // バッジ（複数ある場合）
                    if count > 1 {
                        ZStack {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 18, height: 18)
                            Text("\(count)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .offset(x: 10, y: -10)
                    }
                }

                // ピンの先端
                Triangle()
                    .fill(pinColor)
                    .frame(width: isSelected ? 12 : 8, height: isSelected ? 12 : 8)
                    .offset(y: -1)
            }
        }

        .scaleEffect(isSelected ? 1.2 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }

    private var pinColor: Color {
        // カテゴリがあればカテゴリの色、なければタイプの色
        if let category = checkpoint.category {
            return categoryColor(for: category)
        }

        switch checkpoint.type {
        case .photo:
            return .blue
        case .manualCheckin:
            return .green
        }
    }

    private var pinIcon: String {
        // カテゴリがあればカテゴリのアイコン、なければタイプのアイコン
        if let category = checkpoint.category {
            return category.icon
        }

        switch checkpoint.type {
        case .photo:
            return "camera.fill"
        case .manualCheckin:
            return "mappin"
        }
    }

    private func categoryColor(for category: CheckpointCategory) -> Color {
        switch category {
        case .restaurant: return .orange
        case .cafe: return .brown
        case .gasStation: return .red
        case .hotel: return .purple
        case .tourist: return .blue
        case .park: return .green
        case .shopping: return .pink
        case .transport: return .indigo
        case .other: return .gray
        }
    }
}

struct CalloutView: View {
    let group: MapViewModel.GroupedCheckpoint
    @State private var showPhotoGrid = false

    var checkpoint: Checkpoint {
        group.representative
    }

    var body: some View {
        VStack(spacing: 8) {
            // 大きな画像 (代表)
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

                if group.checkpoints.count > 1 {
                    Text("訪問回数: \(group.checkpoints.count)回")
                        .font(.caption)
                        .foregroundColor(.primary)
                        .padding(.top, 2)

                    Divider()
                        .padding(.vertical, 4)

                    // 訪問履歴リスト
                    ScrollView {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(group.checkpoints.sorted(by: { $0.timestamp > $1.timestamp })) { cp in
                                Text(DateFormatter.japaneseDateTime.string(from: cp.timestamp))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .frame(height: 60) // 高さを制限

                    Divider()
                        .padding(.vertical, 4)

                    // 写真一覧ボタン
                    Button(action: {
                        showPhotoGrid = true
                    }) {
                        HStack {
                            Image(systemName: "photo.on.rectangle.angled")
                            Text("写真一覧を見る")
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                } else {
                    Text(DateFormatter.japaneseDateTime.string(from: checkpoint.timestamp))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(width: 200)
            .background(Color(UIColor.systemBackground))
            .cornerRadius(10)
            .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
            .sheet(isPresented: $showPhotoGrid) {
                PhotoGridView(group: group)
            }

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

