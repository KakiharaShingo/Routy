//
//  JapanStatsView.swift
//  Routy
//
//  Created by Auto-generated on 2025/12/19.
//

import SwiftUI
import SwiftData
import CoreLocation
import Photos

struct JapanStatsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var checkpoints: [Checkpoint]
    
    @State private var stats: [Int: PrefectureLevel] = [:]
    @State private var lockedStats: [Int: Bool] = [:] // ロック状態
    @State private var totalScore: Int = 0
    @State private var selectedPrefecture: Prefecture?
    @State private var showEditSheet = false
    @State private var isLoading = false
    @State private var progress: Double = 0.0
    @State private var showCompletionAlert = false
    
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
                RealisticJapanMapView(stats: $stats) { pref in
                    selectedPrefecture = pref
                    showEditSheet = true
                }
                .frame(maxHeight: 400)
                
                Spacer()
                
                // アクションボタン
                Button(action: calculateFromCheckpoints) {
                    if isLoading {
                        VStack(spacing: 4) {
                            ProgressView(value: progress, total: 1.0)
                                .progressViewStyle(LinearProgressViewStyle(tint: .white))
                                .frame(height: 8)
                            Text("集計中... \(Int(progress * 100))%")
                                .font(.caption)
                                .fontWeight(.bold)
                        }
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
            .alert("完了", isPresented: $showCompletionAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("チェックインからの集計が完了しました。")
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
        Task {
            // ローディング開始
            await MainActor.run { isLoading = true }

            // 1. 各都道府県ごとの訪問日（0時0分基準）を記録
            var prefectureDates: [Int: Set<Date>] = [:]

            let calendar = Calendar.current
            let geocoder = CLGeocoder()

            // 写真アセットから位置情報を取得して更新
            await updatePhotoLocations()

            // 処理が必要なチェックポイントを抽出（住所なし・座標あり）
            let checkpointsToProcess = checkpoints.filter {
                ($0.address == nil || $0.address!.isEmpty) && $0.latitude != 0 && $0.longitude != 0
            }
            
            // 座標でのグルーピング（近接地点をまとめて1回だけリクエストする）
            // 小数点以下2桁 ≒ 緯度1度111km -> 0.01度≒1.1km。
            // 観光地レベル（約1km圏内）の写真は同じ都道府県であるとみなして高速化
            var coordinateGroups: [String: [Checkpoint]] = [:]
            for cp in checkpointsToProcess {
                let key = String(format: "%.2f_%.2f", cp.latitude, cp.longitude)
                coordinateGroups[key, default: []].append(cp)
            }
            
            // グループごとの代表を取得
            let uniqueTasks = coordinateGroups.values.compactMap { $0.first }
            let totalTasks = uniqueTasks.count
            var completedTasks = 0
            
            // 既に住所があるチェックポイントを先に処理
            for checkpoint in checkpoints {
                if let addr = checkpoint.address, !addr.isEmpty {
                    processAddress(addr, date: checkpoint.timestamp, into: &prefectureDates, calendar: calendar)
                }
            }
            
            // 住所がないチェックポイント不要なら即完了
            if totalTasks == 0 {
                await MainActor.run {
                    progress = 1.0
                    showCompletionAlert = true
                    isLoading = false
                }
                // 下の処理への合流のためreturnせず、addressなしのまま日付集計へ進む（結果0件）
            } else {
                
                // 住所がないチェックポイントを並列処理
                await withTaskGroup(of: (String?, String, Date).self) { group in
                    var activeTasks = 0
                    let maxConcurrency = 12
                    
                    for checkpoint in uniqueTasks {
                        if activeTasks >= maxConcurrency {
                            if let result = await group.next() {
                                activeTasks -= 1
                                await MainActor.run {
                                    completedTasks += 1
                                    progress = Double(completedTasks) / Double(totalTasks)
                                }
                                
                                if let addr = result.0 {
                                    let key = result.1
                                    if let groupCheckpoints = coordinateGroups[key] {
                                        await MainActor.run {
                                            for cp in groupCheckpoints {
                                                if cp.address == nil { cp.address = addr }
                                            }
                                        }
                                        for cp in groupCheckpoints {
                                            processAddress(addr, date: cp.timestamp, into: &prefectureDates, calendar: calendar)
                                        }
                                    }
                                }
                            }
                        }
                        
                        group.addTask {
                            let key = String(format: "%.2f_%.2f", checkpoint.latitude, checkpoint.longitude)
                            do {
                                let location = CLLocation(latitude: checkpoint.latitude, longitude: checkpoint.longitude)
                                let placemarks = try await geocoder.reverseGeocodeLocation(location)
                                if let pm = placemarks.first, let adminArea = pm.administrativeArea {
                                    let fullAddress = "\(adminArea) \(pm.locality ?? "")"
                                    return (fullAddress, key, checkpoint.timestamp)
                                }
                            } catch {
                                // print("Geocoding failed")
                            }
                            return (nil, key, checkpoint.timestamp)
                        }
                        activeTasks += 1
                    }
                    
                    // 残りのタスクを回収
                    for await result in group {
                        await MainActor.run {
                            completedTasks += 1
                            progress = Double(completedTasks) / Double(totalTasks)
                        }
                        
                        if let addr = result.0 {
                            let key = result.1
                            if let groupCheckpoints = coordinateGroups[key] {
                                await MainActor.run {
                                    for cp in groupCheckpoints {
                                        if cp.address == nil { cp.address = addr }
                                    }
                                }
                                for cp in groupCheckpoints {
                                    processAddress(addr, date: cp.timestamp, into: &prefectureDates, calendar: calendar)
                                }
                            }
                        }
                    }
                }
            }
            
            // 2. ステータスの決定と更新（メインアクターで実行）
            await MainActor.run {
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
                
                // 変更を永続化（次回以降のジオコーディングスキップのため）
                try? modelContext.save()
                
                isLoading = false
                showCompletionAlert = true // 完了アラートを表示
            }
        }
    }
    
    // 住所処理ヘルパー
    private func processAddress(_ address: String, date: Date, into prefectureDates: inout [Int: Set<Date>], calendar: Calendar) {
        // 住所から都道府県を特定
        if let pref = japanPrefectures.first(where: { address.contains($0.name) }) {
            // ロックされている都道府県はスキップ
            if lockedStats[pref.id] == true { return }

            // 日付を0時0分に正規化
            let startOfDay = calendar.startOfDay(for: date)

            if prefectureDates[pref.id] == nil {
                prefectureDates[pref.id] = []
            }
            prefectureDates[pref.id]?.insert(startOfDay)
        }
    }

    // 写真アセットから位置情報を取得してチェックポイントを更新
    @MainActor
    private func updatePhotoLocations() async {
        let checkpointsWithPhotos = checkpoints.filter {
            $0.photoAssetID != nil && ($0.latitude == 0 || $0.longitude == 0)
        }

        guard !checkpointsWithPhotos.isEmpty else { return }

        for checkpoint in checkpointsWithPhotos {
            guard let assetID = checkpoint.photoAssetID else { continue }

            let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [assetID], options: nil)
            guard let asset = fetchResult.firstObject else { continue }

            // 位置情報を取得
            if let location = asset.location {
                checkpoint.latitude = location.coordinate.latitude
                checkpoint.longitude = location.coordinate.longitude
            }
        }

        // 変更を保存
        try? modelContext.save()
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
