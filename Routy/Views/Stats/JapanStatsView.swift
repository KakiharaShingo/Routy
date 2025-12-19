//
//  JapanStatsView.swift
//  Routy
//
//  Created by Auto-generated on 2025/12/19.
//

import SwiftUI
import SwiftData

struct JapanStatsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var checkpoints: [Checkpoint]
    
    @State private var stats: [Int: PrefectureLevel] = [:]
    @State private var lockedStats: [Int: Bool] = [:] // ロック状態
    @State private var totalScore: Int = 0
    @State private var selectedPrefecture: Prefecture?
    @State private var showEditSheet = false
    @State private var isLoading = false
    
    // 制覇率計算
    var visitedCount: Int {
        stats.values.filter { $0 != .none }.count
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // スコアヘッダー
                HStack {
                    VStack(alignment: .leading) {
                        Text("Travel Score")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("\(totalScore)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("制覇率")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("\(visitedCount)/47")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // マップ
                JapanMapView(stats: $stats) { pref in
                    selectedPrefecture = pref
                    showEditSheet = true
                }
                .frame(maxHeight: 400)
                
                Spacer()
                
                // アクションボタン
                Button(action: calculateFromCheckpoints) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text("チェックインから集計する")
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
                .padding()
            }
            .navigationTitle("日本旅行マップ")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink("リスト編集") {
                        PrefectureListView(stats: $stats, lockedStats: $lockedStats)
                    }
                }
            }
            .sheet(item: $selectedPrefecture) { pref in
                PrefectureEditSheet(prefecture: pref, level: binding(for: pref))
                    .presentationDetents([.height(300)])
            }
            .onAppear {
                loadStats()
            }
            .onChange(of: stats) { _ in
                calculateScore()
                saveStats()
            }
            .onChange(of: lockedStats) { _ in
                saveStats()
            }
        }
    }
    
    // 指定した都道府県のBindingを作成
    private func binding(for pref: Prefecture) -> Binding<PrefectureLevel> {
        Binding(
            get: { stats[pref.id] ?? .none },
            set: { stats[pref.id] = $0 }
        )
    }
    
    // スコア再計算
    private func calculateScore() {
        totalScore = stats.values.reduce(0) { $0 + $1.score }
    }
    
    // 統計データの読み込み（Firestoreから）
    private func loadStats() {
        guard let userId = AuthService.shared.currentUser?.uid else { return }
        Task {
            isLoading = true
            do {
                if let profile = try await FirestoreService.shared.getUserProfile(userId: userId) {
                    
                    // Stats読み込み
                    if let savedStats = profile["prefectureStats"] as? [String: Int] {
                        var newStats: [Int: PrefectureLevel] = [:]
                        for (key, value) in savedStats {
                            if let id = Int(key), let level = PrefectureLevel(rawValue: value) {
                                newStats[id] = level
                            }
                        }
                        self.stats = newStats
                    }
                    
                    // Locks読み込み
                    if let savedLocks = profile["prefectureLocks"] as? [String: Bool] {
                        var newLocks: [Int: Bool] = [:]
                        for (key, value) in savedLocks {
                            if let id = Int(key) {
                                newLocks[id] = value
                            }
                        }
                        self.lockedStats = newLocks
                    }
                    
                    calculateScore()
                }
            } catch {
                print("Stats load failed: \(error)")
            }
            isLoading = false
        }
    }
    
    // 統計データの保存
    private func saveStats() {
        guard let userId = AuthService.shared.currentUser?.uid else { return }
        
        // stats変換
        var saveStatsData: [String: Int] = [:]
        for (key, value) in stats {
            saveStatsData["\(key)"] = value.rawValue
        }
        
        // locks変換
        var saveLocksData: [String: Bool] = [:]
        for (key, value) in lockedStats {
            saveLocksData["\(key)"] = value
        }
        
        Task {
            do {
                try await FirestoreService.shared.saveUserProfile(userId: userId, data: [
                    "prefectureStats": saveStatsData,
                    "prefectureLocks": saveLocksData
                ])
            } catch {
                print("Stats save failed: \(error)")
            }
        }
    }
    
    // チェックイン履歴からの自動集計
    private func calculateFromCheckpoints() {
        isLoading = true
        
        // 1. 各都道府県ごとの訪問日（0時0分基準）を記録
        var prefectureDates: [Int: Set<Date>] = [:]
        
        let calendar = Calendar.current
        
        for checkpoint in checkpoints {
            guard let address = checkpoint.address else { continue }
            
            // 住所から都道府県を特定
            if let pref = japanPrefectures.first(where: { address.contains($0.name) }) {
                // ロックされている都道府県はスキップ
                if lockedStats[pref.id] == true { continue }
                
                // 日付を0時0分に正規化
                let startOfDay = calendar.startOfDay(for: checkpoint.timestamp)
                
                if prefectureDates[pref.id] == nil {
                    prefectureDates[pref.id] = []
                }
                prefectureDates[pref.id]?.insert(startOfDay)
            }
        }
        
        // 2. ステータスの決定と更新
        for (prefId, dateSet) in prefectureDates {
            // ロック確認（念のため）
            if lockedStats[prefId] == true { continue }

            let sortedDates = dateSet.sorted()
            let currentLevel = stats[prefId] ?? .none
            var newLevel: PrefectureLevel = .none
            
            if sortedDates.isEmpty { continue }
            
            // 連続した2日間の記録があるかチェック（宿泊判定）
            var hasConsecutiveDays = false
            if sortedDates.count >= 2 {
                for i in 0..<(sortedDates.count - 1) {
                    let d1 = sortedDates[i]
                    let d2 = sortedDates[i+1]
                    
                    if let days = calendar.dateComponents([.day], from: d1, to: d2).day, days == 1 {
                        hasConsecutiveDays = true
                        break
                    }
                }
            }
            
            if hasConsecutiveDays {
                newLevel = .stayed
            } else {
                newLevel = .visited
            }
            
            // 現在のレベルより高い場合のみ更新
            if newLevel.rawValue > currentLevel.rawValue {
                stats[prefId] = newLevel
            }
        }
        
        isLoading = false
    }
}

// 編集用シート
struct PrefectureEditSheet: View {
    let prefecture: Prefecture
    @Binding var level: PrefectureLevel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("\(prefecture.name)")
                .font(.title)
                .fontWeight(.bold)
                .padding(.top)
            
            VStack(spacing: 12) {
                ForEach(PrefectureLevel.allCases.reversed(), id: \.self) { lvl in
                    Button(action: {
                        level = lvl
                        dismiss()
                    }) {
                        HStack {
                            Text(lvl.label)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            if level == lvl {
                                Image(systemName: "checkmark")
                            }
                            
                            Text("\(lvl.score)pt")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(lvl.color.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(level == lvl ? lvl.color : Color.clear, lineWidth: 2)
                        )
                        .cornerRadius(10)
                    }
                    .foregroundColor(.primary)
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
    }
}

// リスト表示（アクセシビリティ用）
struct PrefectureListView: View {
    @Binding var stats: [Int: PrefectureLevel]
    @Binding var lockedStats: [Int: Bool]
    
    var body: some View {
        List {
            ForEach(japanPrefectures) { pref in
                HStack {
                    Text(pref.name)
                        .fontWeight(.medium)
                    
                    // ロックボタン
                    Button(action: {
                        toggleLock(for: pref.id)
                    }) {
                        Image(systemName: (lockedStats[pref.id] ?? false) ? "lock.fill" : "lock.open")
                            .foregroundColor((lockedStats[pref.id] ?? false) ? .orange : .gray.opacity(0.3))
                    }
                    .buttonStyle(.plain) // 行選択と干渉させない
                    .padding(.horizontal, 8)
                    
                    Spacer()
                    
                    let currentLevel = stats[pref.id] ?? .none
                    
                    Menu {
                        Picker("Status", selection: Binding(
                            get: { stats[pref.id] ?? .none },
                            set: { 
                                stats[pref.id] = $0
                                // 手動変更したら自動でロックする？ユーザーの意図によるが、今回は明示的なロックのみにする
                            }
                        )) {
                            ForEach(PrefectureLevel.allCases.reversed(), id: \.self) { level in
                                HStack {
                                    Text(level.label)
                                    if level != .none {
                                        Text("(\(level.score)pt)")
                                    }
                                }
                                .tag(level)
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(currentLevel.label)
                            Image(systemName: "chevron.down")
                                .font(.caption2)
                        }
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .foregroundColor(currentLevel == .none ? .primary : .white)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(
                            Capsule()
                                .fill(currentLevel == .none ? Color.gray.opacity(0.15) : currentLevel.color)
                        )
                    }
                    .transaction { transaction in
                        transaction.animation = nil // メニュー表示時の不要なアニメーション抑制
                    }
                    // ロックされていたらメニュー無効化する？ -> 編集は許可して、自動更新だけ防ぐのが「Lock」の意味合い的に自然
                }
                .padding(.vertical, 2)
            }
        }
        .navigationTitle("都道府県リスト")
    }
    
    private func toggleLock(for id: Int) {
        let current = lockedStats[id] ?? false
        lockedStats[id] = !current
    }
}

#Preview {
    JapanStatsView()
        .modelContainer(for: [Checkpoint.self, Trip.self])
}
