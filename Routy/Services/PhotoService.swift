//
//  PhotoService.swift
//  Routy
//
//  Created by 垣原親伍 on 2025/12/18.
//

import Foundation
import Photos
import CoreLocation
import UIKit

/// 写真ライブラリアクセスを管理するサービス
@MainActor
class PhotoService {
    /// 写真ライブラリの権限をリクエスト
    /// - Returns: 権限が付与されたかどうか
    func requestPhotoLibraryAccess() async -> Bool {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)

        switch status {
        case .authorized, .limited:
            return true
        case .notDetermined:
            let newStatus = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            return newStatus == .authorized || newStatus == .limited
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }

    /// 指定期間の写真を取得
    /// - Parameters:
    ///   - startDate: 開始日
    ///   - endDate: 終了日
    /// - Returns: PHAsset配列
    func fetchPhotos(from startDate: Date, to endDate: Date) async -> [PHAsset] {
        return await withCheckedContinuation { continuation in
            let options = PHFetchOptions()
            options.predicate = NSPredicate(format: "creationDate >= %@ AND creationDate <= %@", startDate as NSDate, endDate as NSDate)
            options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]

            let fetchResult = PHAsset.fetchAssets(with: .image, options: options)
            var assets: [PHAsset] = []

            fetchResult.enumerateObjects { asset, _, _ in
                // 位置情報があるものだけを追加
                if asset.location != nil {
                    assets.append(asset)
                }
            }

            continuation.resume(returning: assets)
        }
    }

    func extractCheckpoints(from assets: [PHAsset]) async -> [Checkpoint] {
        var checkpoints: [Checkpoint] = []

        for asset in assets {
            if let coordinate = await EXIFReader.extractLocation(from: asset) {
                let checkpoint = Checkpoint(
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude,
                    timestamp: asset.creationDate ?? Date(),
                    type: .photo,
                    photoAssetID: asset.localIdentifier
                )
                checkpoints.append(checkpoint)
            }
        }

        return checkpoints
    }
    
    /// ローカル識別子から画像を取得する
    /// - Parameter localIdentifier: PHAssetのlocalIdentifier
    /// - Returns: UIImage?
    func fetchImage(for localIdentifier: String) async -> UIImage? {
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil)
        guard let asset = fetchResult.firstObject else { return nil }
        
        return await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            options.isSynchronous = false // 非同期で処理
            
            PHImageManager.default().requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: options) { image, info in
                // info[.isDegradedKey]がtrueの場合は低解像度版なので無視（完了しない）
                // ただし、requestImageは複数回呼ばれることがある。
                // ここでは簡単のため、画像が返ってきたらresumeする（厳密にはエラーハンドリングが必要）
                
                if let isDegraded = info?[PHImageResultIsDegradedKey] as? Bool, isDegraded {
                    return
                }
                
                continuation.resume(returning: image)
            }
        }
    }
}
