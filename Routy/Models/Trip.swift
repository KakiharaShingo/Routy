//
//  Trip.swift
//  Routy
//
//  Created by 垣原親伍 on 2025/12/18.
//

import Foundation
import SwiftData

/// 旅行を表すモデル
@Model
class Trip {
    /// 旅行名
    var name: String
    /// 開始日
    var startDate: Date
    /// 終了日
    var endDate: Date
    /// カバー写真URL(サムネイル用)
    var coverPhotoURL: String?
    /// チェックポイントのリスト
    @Relationship(deleteRule: .cascade, inverse: \Checkpoint.trip)
    var checkpoints: [Checkpoint]
    /// 作成日時
    var createdAt: Date
    /// 更新日時
    var updatedAt: Date

    /// イニシャライザ
    init(
        name: String,
        startDate: Date,
        endDate: Date,
        coverPhotoURL: String? = nil,
        checkpoints: [Checkpoint] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.coverPhotoURL = coverPhotoURL
        self.checkpoints = checkpoints
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
