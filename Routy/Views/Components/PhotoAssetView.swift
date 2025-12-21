
import SwiftUI
import PhotosUI

struct PhotoAssetView: View {
    let assetID: String
    @State private var image: UIImage?
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Color.gray.opacity(0.3)
                    ProgressView()
                }
            }
        }
        .onAppear {
            loadAsset()
        }
    }
    
    private func loadAsset() {
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [assetID], options: nil)
        if let asset = assets.firstObject {
            let manager = PHImageManager.default()
            let options = PHImageRequestOptions()
            options.isNetworkAccessAllowed = true
            options.deliveryMode = .highQualityFormat
            
            manager.requestImage(for: asset, targetSize: CGSize(width: 500, height: 500), contentMode: .aspectFill, options: options) { result, _ in
                if let result = result {
                    self.image = result
                }
            }
        }
    }
}
