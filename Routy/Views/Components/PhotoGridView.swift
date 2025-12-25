//
//  PhotoGridView.swift
//  Routy
//
//  グループ化された写真の一覧表示ビュー
//

import SwiftUI
import Photos

/// グループ内の写真を一覧表示するビュー
struct PhotoGridView: View {
    let group: MapViewModel.GroupedCheckpoint
    @Environment(\.dismiss) private var dismiss

    // 3列グリッド
    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 2) {
                    ForEach(group.checkpoints.sorted(by: { $0.timestamp > $1.timestamp })) { checkpoint in
                        NavigationLink(destination: PhotoDetailView(checkpoint: checkpoint)) {
                            PhotoGridCell(checkpoint: checkpoint)
                        }
                    }
                }
            }
            .navigationTitle(group.checkpoints.first?.name ?? "写真一覧")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
        }
    }
}

/// グリッドのセル
struct PhotoGridCell: View {
    let checkpoint: Checkpoint

    var body: some View {
        GeometryReader { geometry in
            if let assetID = checkpoint.photoAssetID {
                PhotoThumbnail(assetID: assetID, size: CGSize(width: geometry.size.width, height: geometry.size.width))
                    .aspectRatio(1, contentMode: .fill)
                    .clipped()
            } else if let url = checkpoint.photoThumbnailURL, let imageURL = URL(string: url) {
                AsyncImage(url: imageURL) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(width: geometry.size.width, height: geometry.size.width)
                .clipped()
            } else {
                ZStack {
                    Color(.systemGray6)
                    Image(systemName: "photo")
                        .foregroundColor(.gray)
                }
                .frame(width: geometry.size.width, height: geometry.size.width)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

/// 写真の詳細表示ビュー
struct PhotoDetailView: View {
    let checkpoint: Checkpoint
    @State private var fullImage: UIImage?
    @State private var isLoading = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else if let image = fullImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else if let assetID = checkpoint.photoAssetID {
                    PhotoAssetView(assetID: assetID)
                        .aspectRatio(contentMode: .fit)
                } else if let url = checkpoint.photoThumbnailURL, let imageURL = URL(string: url) {
                    AsyncImage(url: imageURL) { image in
                        image.resizable().aspectRatio(contentMode: .fit)
                    } placeholder: {
                        ProgressView().tint(.white)
                    }
                } else {
                    Image(systemName: "photo")
                        .font(.system(size: 60))
                        .foregroundColor(.white.opacity(0.5))
                }

                // 情報表示
                VStack(spacing: 8) {
                    if let name = checkpoint.name {
                        Text(name)
                            .font(.headline)
                            .foregroundColor(.white)
                    }

                    Text(DateFormatter.japaneseDateTime.string(from: checkpoint.timestamp))
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))

                    if let address = checkpoint.address {
                        Text(address)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                }
                .padding()
                .background(Color.black.opacity(0.5))
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadFullImage()
        }
    }

    private func loadFullImage() async {
        guard let assetID = checkpoint.photoAssetID else { return }

        isLoading = true
        let photoService = PhotoService()
        fullImage = await photoService.fetchImage(for: assetID)
        isLoading = false
    }
}

#Preview {
    PhotoGridView(
        group: MapViewModel.GroupedCheckpoint(
            coordinate: CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671),
            checkpoints: [
                Checkpoint(latitude: 35.6812, longitude: 139.7671, timestamp: Date(), type: .photo),
                Checkpoint(latitude: 35.6812, longitude: 139.7671, timestamp: Date().addingTimeInterval(-3600), type: .photo)
            ]
        )
    )
}
