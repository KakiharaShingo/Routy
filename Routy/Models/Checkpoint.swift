//
//  Checkpoint.swift
//  Routy
//
//  Created by 垣原親伍 on 2025/12/18.
//

import Foundation
import SwiftData
import CoreLocation

/// チェックポイント(地点)を表すモデル
@Model
class Checkpoint {
    /// 緯度
    var latitude: Double
    /// 経度
    var longitude: Double
    /// タイムスタンプ(撮影日時またはチェックイン日時)
    var timestamp: Date
    /// チェックポイントの種類
    var type: CheckpointType
    /// PhotoKit Asset    /// 写真のアセットID（ローカル識別子）
    var photoAssetID: String?
    /// クラウド上のサムネイルURL
    var photoThumbnailURL: String?
    /// クラウド上の本画像URL（有料プラン等）
    var photoURL: String?
    /// 場所の名前（POI名など）
    var name: String?
    /// メモ
    var note: String?
    /// 住所(逆ジオコーディング結果)
    var address: String?
    /// 親の旅行
    var trip: Trip?

    // MARK: - Firebase Sync Properties
    /// FirestoreドキュメントID
    var firebaseId: String?
    /// 同期ステータス
    var syncStatus: SyncStatus = SyncStatus.synced
    /// 最終同期日時
    var lastSyncedAt: Date?
    /// 同期が必要かどうか
    var needsSync: Bool = false
    
    // photoThumbnailURL declared above (line 26), removing duplicate
    
    /// 同期済みかどうか
    var isSynced: Bool {
        return syncStatus == .synced && !needsSync
    }
    
    /// 同期が必要であることをマークする
    func markNeedsSync() {
        needsSync = true
        syncStatus = .pending
        // CheckpointにはupdatedAtがないので追加を検討するか、timestampを更新しないように注意
        // ここでは便宜上、モデルにupdatedAtがないため、単純にフラグのみ立てる
    }

    /// イニシャライザ
    init(
        latitude: Double,
        longitude: Double,
        timestamp: Date,
        type: CheckpointType = .manualCheckin,
        photoAssetID: String? = nil,
        photoThumbnailURL: String? = nil,
        photoURL: String? = nil,
        name: String? = nil,
        note: String? = nil,
        address: String? = nil,
        trip: Trip? = nil
    ) {
        self.latitude = latitude
        self.longitude = longitude
        self.timestamp = timestamp
        self.type = type
        self.photoAssetID = photoAssetID
        self.photoThumbnailURL = photoThumbnailURL
        self.photoURL = photoURL
        self.name = name
        self.note = note
        self.address = address
        self.trip = trip
    }

    /// CLLocationCoordinate2Dを返すヘルパーメソッド
    func coordinate() -> CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
