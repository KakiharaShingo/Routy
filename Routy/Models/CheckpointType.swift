//
//  CheckpointType.swift
//  Routy
//
//  Created by 垣原親伍 on 2025/12/18.
//

import Foundation

/// チェックポイントの種類
enum CheckpointType: String, Codable {
    /// 写真から生成されたチェックポイント
    case photo
    /// 手動チェックイン
    case manualCheckin
}
