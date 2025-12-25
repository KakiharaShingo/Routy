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
    /// カテゴリ（施設の種類）
    var category: CheckpointCategory?
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
        category: CheckpointCategory? = nil,
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
        self.category = category
        self.trip = trip
    }

    /// CLLocationCoordinate2Dを返すヘルパーメソッド
    func coordinate() -> CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

/// チェックポイントのカテゴリ（施設の種類）
enum CheckpointCategory: String, Codable, CaseIterable {
    case restaurant = "restaurant"      // レストラン・飲食店
    case cafe = "cafe"                  // カフェ
    case gasStation = "gas_station"     // ガソリンスタンド
    case hotel = "hotel"                // 宿泊施設
    case tourist = "tourist"            // 観光地
    case park = "park"                  // 公園
    case shopping = "shopping"          // ショッピング
    case transport = "transport"        // 駅・空港などの交通機関
    case other = "other"                // その他

    var displayName: String {
        switch self {
        case .restaurant: return "飲食店"
        case .cafe: return "カフェ"
        case .gasStation: return "ガソリンスタンド"
        case .hotel: return "宿泊施設"
        case .tourist: return "観光地"
        case .park: return "公園"
        case .shopping: return "ショッピング"
        case .transport: return "交通機関"
        case .other: return "その他"
        }
    }

    var icon: String {
        switch self {
        case .restaurant: return "fork.knife"
        case .cafe: return "cup.and.saucer.fill"
        case .gasStation: return "fuelpump.fill"
        case .hotel: return "bed.double.fill"
        case .tourist: return "camera.fill"
        case .park: return "leaf.fill"
        case .shopping: return "cart.fill"
        case .transport: return "tram.fill"
        case .other: return "mappin.circle.fill"
        }
    }
}
