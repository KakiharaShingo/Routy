//
//  JapanStatsModels.swift
//  Routy
//
//  Created by Auto-generated on 2025/12/19.
//

import SwiftUI

/// 都道府県の制覇レベル
enum PrefectureLevel: Int, Codable, CaseIterable {
    case none = 0
    case passed = 1
    case landed = 2
    case visited = 3
    case stayed = 4
    
    var label: String {
        switch self {
        case .none: return "未踏の地"
        case .passed: return "通過した"
        case .landed: return "降り立った"
        case .visited: return "観光した"
        case .stayed: return "宿泊した"
        }
    }
    
    var score: Int {
        return self.rawValue
    }
    
    var color: Color {
        switch self {
        case .none: return Color.secondary.opacity(0.2)
        case .passed: return Color.blue.opacity(0.7)      // 通過: 青
        case .landed: return Color.teal                   // 降り立った: ティール（青緑）
        case .visited: return Color.green                 // 観光した: 緑
        case .stayed: return Color.orange                 // 宿泊した: オレンジ（金）
        }
    }
}

/// 都道府県データ
struct Prefecture: Identifiable, Hashable {
    let id: Int // 1-47 (JIS code)
    let name: String
    let region: String
    
    // グリッド表示用の座標 (x:列, y:行)
    // 日本地図をデフォルメしたグリッドに配置するため
    let x: Int
    let y: Int
}

/// デフォルメ日本地図データ (簡易グリッド配置)
/// 上（北）がy=0, 左（西）がx=0
let japanPrefectures: [Prefecture] = [
    // 北海道・東北
    Prefecture(id: 1, name: "北海道", region: "北海道", x: 13, y: 0),
    Prefecture(id: 2, name: "青森", region: "東北", x: 13, y: 2),
    Prefecture(id: 3, name: "岩手", region: "東北", x: 14, y: 3),
    Prefecture(id: 4, name: "宮城", region: "東北", x: 14, y: 4),
    Prefecture(id: 5, name: "秋田", region: "東北", x: 13, y: 3),
    Prefecture(id: 6, name: "山形", region: "東北", x: 13, y: 4),
    Prefecture(id: 7, name: "福島", region: "東北", x: 13, y: 5),
    
    // 関東
    Prefecture(id: 8, name: "茨城", region: "関東", x: 14, y: 6),
    Prefecture(id: 9, name: "栃木", region: "関東", x: 13, y: 6),
    Prefecture(id: 10, name: "群馬", region: "関東", x: 12, y: 6),
    Prefecture(id: 11, name: "埼玉", region: "関東", x: 12, y: 7),
    Prefecture(id: 12, name: "千葉", region: "関東", x: 14, y: 8),
    Prefecture(id: 13, name: "東京", region: "関東", x: 13, y: 8),
    Prefecture(id: 14, name: "神奈川", region: "関東", x: 13, y: 9),
    
    // 中部
    Prefecture(id: 15, name: "新潟", region: "中部", x: 12, y: 5),
    Prefecture(id: 16, name: "富山", region: "中部", x: 10, y: 5),
    Prefecture(id: 17, name: "石川", region: "中部", x: 9, y: 5),
    Prefecture(id: 18, name: "福井", region: "中部", x: 8, y: 6),
    Prefecture(id: 19, name: "山梨", region: "中部", x: 12, y: 8),
    Prefecture(id: 20, name: "長野", region: "中部", x: 11, y: 6),
    Prefecture(id: 21, name: "岐阜", region: "中部", x: 10, y: 7),
    Prefecture(id: 22, name: "静岡", region: "中部", x: 12, y: 9),
    Prefecture(id: 23, name: "愛知", region: "中部", x: 11, y: 8),
    
    // 近畿
    Prefecture(id: 24, name: "三重", region: "近畿", x: 10, y: 9),
    Prefecture(id: 25, name: "滋賀", region: "近畿", x: 9, y: 7),
    Prefecture(id: 26, name: "京都", region: "近畿", x: 8, y: 7),
    Prefecture(id: 27, name: "大阪", region: "近畿", x: 8, y: 8),
    Prefecture(id: 28, name: "兵庫", region: "近畿", x: 7, y: 7),
    Prefecture(id: 29, name: "奈良", region: "近畿", x: 9, y: 8),
    Prefecture(id: 30, name: "和歌山", region: "近畿", x: 8, y: 9),
    
    // 中国
    Prefecture(id: 31, name: "鳥取", region: "中国", x: 6, y: 7),
    Prefecture(id: 32, name: "島根", region: "中国", x: 5, y: 7),
    Prefecture(id: 33, name: "岡山", region: "中国", x: 6, y: 8),
    Prefecture(id: 34, name: "広島", region: "中国", x: 5, y: 8),
    Prefecture(id: 35, name: "山口", region: "中国", x: 4, y: 8),
    
    // 四国
    Prefecture(id: 36, name: "徳島", region: "四国", x: 7, y: 10),
    Prefecture(id: 37, name: "香川", region: "四国", x: 6, y: 9),
    Prefecture(id: 38, name: "愛媛", region: "四国", x: 5, y: 10),
    Prefecture(id: 39, name: "高知", region: "四国", x: 6, y: 11),
    
    // 九州・沖縄
    Prefecture(id: 40, name: "福岡", region: "九州", x: 3, y: 9),
    Prefecture(id: 41, name: "佐賀", region: "九州", x: 2, y: 9),
    Prefecture(id: 42, name: "長崎", region: "九州", x: 1, y: 9),
    Prefecture(id: 43, name: "熊本", region: "九州", x: 2, y: 10),
    Prefecture(id: 44, name: "大分", region: "九州", x: 3, y: 10),
    Prefecture(id: 45, name: "宮崎", region: "九州", x: 3, y: 11),
    Prefecture(id: 46, name: "鹿児島", region: "九州", x: 2, y: 11),
    Prefecture(id: 47, name: "沖縄", region: "沖縄", x: 0, y: 13) // かなり離す
]
