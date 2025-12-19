//
//  SyncStatus.swift
//  Routy
//
//  Created by Auto-generated on 2025/12/18.
//

import Foundation

/// Firebaseとの同期ステータス
enum SyncStatus: String, Codable {
    case synced       // 同期済み
    case pending      // 同期待ち
    case syncing      // 同期中
    case failed       // 同期失敗
}
