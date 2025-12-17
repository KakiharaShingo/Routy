//
//  PhotoThumbnail.swift
//  Routy
//
//  Created by 垣原親伍 on 2025/12/18.
//

import SwiftUI
import Photos

/// 写真サムネイル表示コンポーネント
struct PhotoThumbnail: View {
    let assetID: String
    let size: CGSize

    @State private var image: UIImage?
    @State private var isLoading = true

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if isLoading {
                ProgressView()
                    .frame(width: size.width, height: size.height)
            } else {
                Image(systemName: "photo")
                    .font(.largeTitle)
                    .foregroundColor(.gray)
                    .frame(width: size.width, height: size.height)
            }
        }
        .frame(width: size.width, height: size.height)
        .background(Color.gray.opacity(0.2))
        .onAppear {
            loadImage()
        }
    }

    private func loadImage() {
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [assetID], options: nil)
        guard let asset = fetchResult.firstObject else {
            isLoading = false
            return
        }

        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .exact

        let targetSize = CGSize(width: size.width * 2, height: size.height * 2) // Retinaディスプレイ対応

        PHImageManager.default().requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: options
        ) { result, _ in
            DispatchQueue.main.async {
                self.image = result
                self.isLoading = false
            }
        }
    }
}

#Preview {
    PhotoThumbnail(assetID: "sample-asset-id", size: CGSize(width: 80, height: 80))
        .clipShape(RoundedRectangle(cornerRadius: 8))
}
