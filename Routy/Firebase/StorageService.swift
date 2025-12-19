//
//  StorageService.swift
//  Routy
//
//  Created by Auto-generated on 2025/12/18.
//

import Foundation
import FirebaseStorage
import UIKit

/// Firebase Storageへのアクセスを提供するサービス
class StorageService {
    /// 共有インスタンス
    static let shared = StorageService()
    
    private let storage = Storage.storage()
    private let imageCache = NSCache<NSString, UIImage>()
    
    private init() {}
    
    /// サムネイル画像をアップロードする
    /// - Returns: ダウンロードURL
    func uploadThumbnail(image: UIImage, userId: String, photoId: String) async throws -> String {
        // 50KB（目安）まで圧縮
        guard let data = compressImage(image, targetSizeKB: 50) else {
            throw NSError(domain: "ImageError", code: -1, userInfo: [NSLocalizedDescriptionKey: "画像の圧縮に失敗しました"])
        }
        
        let path = "users/\(userId)/thumbnails/\(photoId)_thumb.jpg"
        let ref = storage.reference().child(path)
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        // アップロード
        _ = try await ref.putDataAsync(data, metadata: metadata)
        
        // ダウンロードURL取得
        let url = try await ref.downloadURL()
        return url.absoluteString
    }
    
    /// 写真（本画像）をアップロードする
    /// - Parameters:
    ///   - image: アップロードする画像
    ///   - userId: ユーザーID
    ///   - photoId: 写真ID（CheckpointIDなど）
    ///   - isPremium: プレミアム会員かどうか
    /// - Returns: ダウンロードURL
    func uploadPhoto(image: UIImage, userId: String, photoId: String, isPremium: Bool) async throws -> String {
        var data: Data?
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        if isPremium {
            // プレミアム: オリジナル品質（最高画質）
            data = image.jpegData(compressionQuality: 1.0)
        } else {
            // 無料: 圧縮（500KB目安）
            data = compressImage(image, targetSizeKB: 500)
        }
        
        guard let uploadData = data else {
            throw NSError(domain: "ImageError", code: -1, userInfo: [NSLocalizedDescriptionKey: "画像データの生成に失敗"])
        }
        
        let path = "users/\(userId)/photos/\(photoId).jpg"
        let ref = storage.reference().child(path)
        
        // アップロード
        _ = try await ref.putDataAsync(uploadData, metadata: metadata)
        
        // URL取得
        let url = try await ref.downloadURL()
        return url.absoluteString
    }
    
    /// サムネイル画像をダウンロードする
    func downloadThumbnail(url: String) async throws -> UIImage {
        // キャッシュ確認
        if let cachedImage = imageCache.object(forKey: url as NSString) {
            return cachedImage
        }
        
        let ref = storage.reference(forURL: url)
        // 1MB制限でダウンロード
        let data = try await ref.data(maxSize: 1 * 1024 * 1024)
        
        guard let image = UIImage(data: data) else {
            throw NSError(domain: "ImageError", code: -1, userInfo: [NSLocalizedDescriptionKey: "画像データの変換に失敗"])
        }
        
        // キャッシュ保存
        imageCache.setObject(image, forKey: url as NSString)
        return image
    }
    
    /// 画像を削除する
    func deleteThumbnail(url: String) async throws {
        let ref = storage.reference(forURL: url)
        try await ref.delete()
        imageCache.removeObject(forKey: url as NSString)
    }
    
    /// 画像を指定サイズ(KB)以下になるよう圧縮する
    func compressImage(_ image: UIImage, targetSizeKB: Int) -> Data? {
        let targetBytes = targetSizeKB * 1024
        var compression: CGFloat = 0.8
        var data = image.jpegData(compressionQuality: compression)
        
        // 段階的に圧縮率を下げる
        while let currentData = data, currentData.count > targetBytes && compression > 0.1 {
            compression -= 0.1
            data = image.jpegData(compressionQuality: compression)
        }
        
        return data
    }
}
