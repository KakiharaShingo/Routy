//
//  TimelineViewModel.swift
//  Routy
//
//  Created by 垣原親伍 on 2025/12/18.
//

import Foundation
import Observation

/// タイムライン画面のViewModel
@Observable
@MainActor
class TimelineViewModel {
    /// チェックポイントのリスト
    var checkpoints: [Checkpoint] = []
    /// 日付でグループ化されたチェックポイント
    var groupedCheckpoints: [Date: [Checkpoint]] = [:]

    /// チェックポイントを読み込む
    /// - Parameter trip: Trip
    func loadCheckpoints(from trip: Trip) {
        checkpoints = trip.checkpoints.sorted { $0.timestamp < $1.timestamp }
        groupCheckpointsByDate()
    }

    /// チェックポイントを日付でグループ化
    func groupCheckpointsByDate() {
        let calendar = Calendar.current
        groupedCheckpoints = Dictionary(grouping: checkpoints) { checkpoint in
            calendar.startOfDay(for: checkpoint.timestamp)
        }
    }

    /// 日付をフォーマット
    /// - Parameter date: Date
    /// - Returns: フォーマットされた日付文字列
    func formatDate(_ date: Date) -> String {
        return DateFormatter.dateOnly.string(from: date)
    }

    /// 時刻をフォーマット
    /// - Parameter date: Date
    /// - Returns: フォーマットされた時刻文字列
    func formatTime(_ date: Date) -> String {
        return DateFormatter.timeOnly.string(from: date)
    }

    /// グループ化された日付をソート
    /// - Returns: ソートされた日付の配列
    func sortedDates() -> [Date] {
        return groupedCheckpoints.keys.sorted(by: >)
    }
}
