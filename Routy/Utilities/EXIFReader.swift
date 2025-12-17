//
//  EXIFReader.swift
//  Routy
//
//  Created by 垣原親伍 on 2025/12/18.
//

import Foundation
import Photos
import CoreLocation
import CoreImage

/// EXIF位置情報を読み取るユーティリティ
class EXIFReader {
    /// PHAssetからEXIF位置情報を抽出
    /// - Parameter asset: PHAsset
    /// - Returns: CLLocationCoordinate2D、位置情報がない場合はnil
    static func extractLocation(from asset: PHAsset) async -> CLLocationCoordinate2D? {
        // PHAssetのlocationプロパティを優先使用
        if let location = asset.location {
            return location.coordinate
        }

        // locationがnilの場合、画像データからEXIF読取
        return await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.isSynchronous = false
            options.isNetworkAccessAllowed = true
            options.deliveryMode = .highQualityFormat

            PHImageManager.default().requestImageDataAndOrientation(for: asset, options: options) { data, _, _, _ in
                guard let imageData = data,
                      let ciImage = CIImage(data: imageData),
                      let properties = ciImage.properties as? [String: Any],
                      let gpsInfo = properties[kCGImagePropertyGPSDictionary as String] as? [String: Any],
                      let latitude = gpsInfo[kCGImagePropertyGPSLatitude as String] as? Double,
                      let longitude = gpsInfo[kCGImagePropertyGPSLongitude as String] as? Double,
                      let latitudeRef = gpsInfo[kCGImagePropertyGPSLatitudeRef as String] as? String,
                      let longitudeRef = gpsInfo[kCGImagePropertyGPSLongitudeRef as String] as? String else {
                    continuation.resume(returning: nil)
                    return
                }

                // 緯度の符号を調整 (N: 正, S: 負)
                let finalLatitude = latitudeRef == "S" ? -latitude : latitude
                // 経度の符号を調整 (E: 正, W: 負)
                let finalLongitude = longitudeRef == "W" ? -longitude : longitude

                let coordinate = CLLocationCoordinate2D(latitude: finalLatitude, longitude: finalLongitude)
                continuation.resume(returning: coordinate)
            }
        }
    }
}
