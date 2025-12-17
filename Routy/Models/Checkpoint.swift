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
    /// PhotoKit Asset ID (写真の場合のみ)
    var photoAssetID: String?
    /// メモ
    var note: String?
    /// 住所(逆ジオコーディング結果)
    var address: String?
    /// 親の旅行
    var trip: Trip?

    /// イニシャライザ
    init(
        latitude: Double,
        longitude: Double,
        timestamp: Date,
        type: CheckpointType,
        photoAssetID: String? = nil,
        note: String? = nil,
        address: String? = nil,
        trip: Trip? = nil
    ) {
        self.latitude = latitude
        self.longitude = longitude
        self.timestamp = timestamp
        self.type = type
        self.photoAssetID = photoAssetID
        self.note = note
        self.address = address
        self.trip = trip
    }

    /// CLLocationCoordinate2Dを返すヘルパーメソッド
    func coordinate() -> CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
