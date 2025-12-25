//
//  TestDataGenerator.swift
//  Routy
//
//  テストデータ生成ユーティリティ
//

import Foundation
import SwiftData

/// テストデータを生成するユーティリティ
class TestDataGenerator {
    /// カテゴリーテスト用のサンプル旅行を作成
    static func createCategoryTestTrip(modelContext: ModelContext) {
        let trip = Trip(
            name: "カテゴリーテスト旅行",
            startDate: Date(),
            endDate: Date()
        )

        // 様々なカテゴリーのチェックポイントを作成
        let testCheckpoints: [(String, Double, Double, CheckpointCategory)] = [
            // レストラン - 東京タワー周辺のレストラン
            ("レストラン", 35.6585805, 139.7454329, .restaurant),

            // カフェ - 渋谷のスターバックス
            ("カフェ", 35.6617773, 139.7040506, .cafe),

            // ガソリンスタンド - 新宿のENEOS
            ("ガソリンスタンド", 35.6938107, 139.7033677, .gasStation),

            // ホテル - 東京ステーションホテル
            ("ホテル", 35.6812362, 139.7671248, .hotel),

            // 観光スポット - 浅草寺
            ("浅草寺", 35.7147651, 139.7966553, .tourist),

            // 公園 - 上野公園
            ("上野公園", 35.7148245, 139.7738466, .park),

            // ショッピング - 銀座三越
            ("銀座三越", 35.6718285, 139.7654424, .shopping),

            // 交通 - 東京駅
            ("東京駅", 35.6812362, 139.7671248, .transport),

            // その他 - 皇居
            ("皇居", 35.6851915, 139.7527995, .other)
        ]

        for (name, latitude, longitude, category) in testCheckpoints {
            let checkpoint = Checkpoint(
                latitude: latitude,
                longitude: longitude,
                timestamp: Date(),
                type: .manualCheckin,
                trip: trip
            )
            checkpoint.name = name
            checkpoint.category = category
            checkpoint.address = name + "周辺"

            modelContext.insert(checkpoint)
            trip.checkpoints.append(checkpoint)
        }

        modelContext.insert(trip)

        do {
            try modelContext.save()
            print("✅ カテゴリーテストデータを作成しました")
        } catch {
            print("❌ テストデータの保存に失敗: \(error)")
        }
    }

    /// より多くのテストデータを生成（各カテゴリー複数件）
    static func createExtendedCategoryTestTrip(modelContext: ModelContext) {
        let trip = Trip(
            name: "拡張カテゴリーテスト",
            startDate: Date(),
            endDate: Date()
        )

        let testCheckpoints: [(String, Double, Double, CheckpointCategory)] = [
            // レストラン
            ("すし処 築地", 35.6654861, 139.7706672, .restaurant),
            ("ラーメン一蘭", 35.6617773, 139.7040506, .restaurant),
            ("鳥貴族 新宿店", 35.6938107, 139.7033677, .restaurant),

            // カフェ
            ("ブルーボトル", 35.6658968, 139.7287262, .cafe),
            ("猿田彦珈琲", 35.6617773, 139.7040506, .cafe),

            // ガソリンスタンド
            ("ENEOS 環八店", 35.6851915, 139.6529773, .gasStation),
            ("Shell 首都高前", 35.6585805, 139.7454329, .gasStation),

            // ホテル
            ("ホテルニューオータニ", 35.6838107, 139.7395677, .hotel),
            ("パークハイアット東京", 35.6855897, 139.6917064, .hotel),

            // 観光
            ("東京スカイツリー", 35.7100627, 139.8107004, .tourist),
            ("明治神宮", 35.6763976, 139.6993259, .tourist),
            ("江戸東京博物館", 35.6965515, 139.7935626, .tourist),

            // 公園
            ("代々木公園", 35.6719627, 139.6960553, .park),
            ("お台場海浜公園", 35.6300968, 139.7737262, .park),

            // ショッピング
            ("東急ハンズ", 35.6617773, 139.7040506, .shopping),
            ("ドン・キホーテ", 35.6938107, 139.7033677, .shopping),

            // 交通
            ("新宿駅", 35.6896342, 139.7005511, .transport),
            ("羽田空港", 35.5493932, 139.7798386, .transport),

            // その他
            ("国会議事堂", 35.6750396, 139.7449906, .other),
            ("東京タワー", 35.6585805, 139.7454329, .other)
        ]

        for (index, (name, latitude, longitude, category)) in testCheckpoints.enumerated() {
            // 時系列で少しずつ時間をずらす
            let timestamp = Date().addingTimeInterval(TimeInterval(index * 1800)) // 30分ごと

            let checkpoint = Checkpoint(
                latitude: latitude,
                longitude: longitude,
                timestamp: timestamp,
                type: .manualCheckin,
                trip: trip
            )
            checkpoint.name = name
            checkpoint.category = category
            checkpoint.address = name + "周辺"

            modelContext.insert(checkpoint)
            trip.checkpoints.append(checkpoint)
        }

        modelContext.insert(trip)

        do {
            try modelContext.save()
            print("✅ 拡張カテゴリーテストデータを作成しました (\(testCheckpoints.count)件)")
        } catch {
            print("❌ テストデータの保存に失敗: \(error)")
        }
    }
}
