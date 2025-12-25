//
//  MapViewModel.swift
//  Routy
//
//  Created by 垣原親伍 on 2025/12/18.
//

import Foundation
import SwiftData
import MapKit
import Observation
import SwiftUI

/// 地図画面のViewModel
@MainActor
@Observable
class MapViewModel {
    /// 現在の旅行
    var currentTrip: Trip?
    /// グループ化されたチェックポイント
    struct GroupedCheckpoint: Identifiable, Equatable {
        let id: UUID = UUID()
        let coordinate: CLLocationCoordinate2D
        var checkpoints: [Checkpoint]
        
        var representative: Checkpoint {
            // 一番新しいものを代表とする
            checkpoints.sorted { $0.timestamp > $1.timestamp }.first!
        }
        
        static func == (lhs: GroupedCheckpoint, rhs: GroupedCheckpoint) -> Bool {
            lhs.id == rhs.id
        }
    }
    
    /// チェックポイントのリスト（個別のものは維持しつつ、UI用はComputedで返す形が望ましいが、パフォーマンスのため保持する）
    var checkpoints: [Checkpoint] = [] {
        didSet {
            updateGroupedCheckpoints()
        }
    }
    
    /// グループ化済みのチェックポイントリスト
    var groupedCheckpoints: [GroupedCheckpoint] = []

    /// 選択中のグループ
    var selectedGroup: GroupedCheckpoint?

    // Legacy support (for GlobalMapView compatibility)
    var selectedCheckpoint: Checkpoint?

    /// ローディング中かどうか
    var isLoading: Bool = false
    /// エラーメッセージ
    var errorMessage: String?
    /// カメラ位置
    var cameraPosition: MapCameraPosition = .automatic

    private let photoService: PhotoService
    private let geocodingService: GeocodingService
    private let modelContext: ModelContext
    private let syncManager = SyncManager.shared
    private let authService = AuthService.shared
    private let storageService = StorageService.shared

    init(modelContext: ModelContext, photoService: PhotoService? = nil, geocodingService: GeocodingService? = nil) {
        self.modelContext = modelContext
        self.photoService = photoService ?? PhotoService()
        self.geocodingService = geocodingService ?? GeocodingService()
        
        // 匿名ログインの確認
        if !authService.isAuthenticated {
            Task {
                do {
                    try await authService.signInAnonymously()
                    print("✅ [MapViewModel] 自動ログイン成功")
                } catch {
                    print("❌ [MapViewModel] 自動ログイン失敗: \(error)")
                }
            }
        }
    }
    
    /// クラウドと同期
    func syncToCloud() {
        Task {
            await syncManager.syncAll(modelContext: modelContext)
        }
    }

    /// 既存のTripに写真を追加
    /// - Parameters:
    ///   - trip: 対象のTrip
    ///   - startDate: 開始日
    ///   - endDate: 終了日
    func loadPhotosForTrip(trip: Trip, startDate: Date, endDate: Date) async {
        print("🔍 loadPhotosForTrip 開始: \(startDate) ~ \(endDate)")
        isLoading = true
        errorMessage = nil
        currentTrip = trip

        do {
            // 写真ライブラリの権限をリクエスト
            let hasAccess = await photoService.requestPhotoLibraryAccess()
            print("🔍 写真ライブラリアクセス権限: \(hasAccess)")
            guard hasAccess else {
                errorMessage = "写真ライブラリへのアクセスが許可されていません"
                isLoading = false
                return
            }

            // 写真を取得
            let assets = await photoService.fetchPhotos(from: startDate, to: endDate)
            print("🔍 取得した写真(PHAsset)数: \(assets.count)")
            guard !assets.isEmpty else {
                errorMessage = "指定期間内に位置情報付きの写真が見つかりませんでした"
                isLoading = false
                return
            }

            // Checkpointを生成
            let newCheckpoints = await photoService.extractCheckpoints(from: assets)
            print("📸 取り込んだ写真数: \(newCheckpoints.count)")

            // 住所とカテゴリを取得(バッチ処理)
            for checkpoint in newCheckpoints {
                let address = await geocodingService.getAddress(for: checkpoint.coordinate())
                checkpoint.address = address

                // カテゴリを自動判定
                await withCheckedContinuation { continuation in
                    LocationCategoryDetector.shared.detectCategory(at: checkpoint.coordinate()) { category in
                        checkpoint.category = category
                        if let category = category {
                            print("✅ カテゴリー判定成功: \(category.displayName) at \(checkpoint.coordinate())")
                        } else {
                            print("⚠️ カテゴリー判定失敗 at \(checkpoint.coordinate())")
                        }
                        continuation.resume()
                    }
                }

                checkpoint.trip = trip
                modelContext.insert(checkpoint)
                trip.checkpoints.append(checkpoint)
            }

            try modelContext.save()

            // 状態を更新
            checkpoints = trip.checkpoints
            
            // 同期フラグを設定
            trip.markNeedsSync()
            for checkpoint in newCheckpoints {
                checkpoint.markNeedsSync()
            }
            try modelContext.save()
            
            // クラウド同期
            syncToCloud()

            // 地図の初期位置を設定
            centerMapOnCheckpoints()

        } catch {
            errorMessage = "写真の読み込みに失敗しました: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// 写真を読み込む（新規Trip作成）
    /// - Parameters:
    ///   - startDate: 開始日
    ///   - endDate: 終了日
    func loadPhotos(startDate: Date, endDate: Date) async {
        isLoading = true
        errorMessage = nil

        do {
            // 写真ライブラリの権限をリクエスト
            let hasAccess = await photoService.requestPhotoLibraryAccess()
            guard hasAccess else {
                errorMessage = "写真ライブラリへのアクセスが許可されていません"
                isLoading = false
                return
            }

            // 写真を取得
            let assets = await photoService.fetchPhotos(from: startDate, to: endDate)
            guard !assets.isEmpty else {
                errorMessage = "指定期間内に位置情報付きの写真が見つかりませんでした"
                isLoading = false
                return
            }

            // Checkpointを生成
            let newCheckpoints = await photoService.extractCheckpoints(from: assets)

            // 住所とカテゴリを取得(バッチ処理)
            for checkpoint in newCheckpoints {
                let address = await geocodingService.getAddress(for: checkpoint.coordinate())
                checkpoint.address = address
                
                // カテゴリを自動判定
                await withCheckedContinuation { continuation in
                    LocationCategoryDetector.shared.detectCategory(at: checkpoint.coordinate()) { category in
                        checkpoint.category = category
                        continuation.resume()
                    }
                }
            }

            // SwiftDataに保存
            let trip = Trip(
                name: "旅行 \(DateFormatter.dateOnly.string(from: startDate))",
                startDate: startDate,
                endDate: endDate,
                checkpoints: newCheckpoints
            )

            modelContext.insert(trip)
            try modelContext.save()

            // 状態を更新
            currentTrip = trip
            checkpoints = newCheckpoints
            
            // 同期フラグを設定
            trip.markNeedsSync()
            for checkpoint in newCheckpoints {
                checkpoint.markNeedsSync()
            }
            try modelContext.save()
            
            // クラウド同期
            syncToCloud()

            // 地図の初期位置を設定
            centerMapOnCheckpoints()

        } catch {
            errorMessage = "写真の読み込みに失敗しました: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// チェックポイントを選択（Legacy support）
    func selectCheckpoint(_ checkpoint: Checkpoint) {
        selectedCheckpoint = checkpoint
    }

    /// グループを選択
    func selectGroup(_ group: GroupedCheckpoint) {
        selectedGroup = group
        // Legacy supportのためにselectedCheckpointも設定
        selectedCheckpoint = group.representative
    }

    /// 全チェックポイントが見える範囲に地図を調整
    func centerMapOnCheckpoints() {
        guard !checkpoints.isEmpty else { return }
        print("DEBUG: centerMapOnCheckpoints called with \(checkpoints.count) checkpoints")

        let coordinates = checkpoints.map { $0.coordinate() }
        let rect = coordinates.reduce(MKMapRect.null) { rect, coordinate in
            let point = MKMapPoint(coordinate)
            let pointRect = MKMapRect(x: point.x, y: point.y, width: 0, height: 0)
            return rect.union(pointRect)
        }

        if rect.width == 0 || rect.height == 0 {
             // 1点のみ、または全ての点が同じ場所にある場合
            if let first = coordinates.first {
                print("DEBUG: Single point or zero size rect. Setting region.")
                let region = MKCoordinateRegion(center: first, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
                cameraPosition = .region(region)
            }
        } else {
             // 複数地点がある場合
            print("DEBUG: Setting rect with padding.")
            cameraPosition = .rect(rect.insetBy(dx: -rect.width * 0.1, dy: -rect.height * 0.1))
        }
    }

    /// チェックポイントを削除
    /// - Parameter checkpoint: 削除するCheckpoint
    func deleteCheckpoint(_ checkpoint: Checkpoint) {
        modelContext.delete(checkpoint)
        checkpoints.removeAll { $0.id == checkpoint.id }
        // Note: didSet on checkpoints will trigger updateGroupedCheckpoints


        do {
            try modelContext.save()
        } catch {
            errorMessage = "チェックポイントの削除に失敗しました"
        }
    }

    /// チェックインを追加
    /// - Parameters:
    ///   - coordinate: 座標
    ///   - note: メモ
    func addCheckin(coordinate: CLLocationCoordinate2D, note: String?) async {
        isLoading = true

        let address = await geocodingService.getAddress(for: coordinate)

        let checkpoint = Checkpoint(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            timestamp: Date(),
            type: .manualCheckin,
            note: note,
            address: address,
            trip: currentTrip
        )

        modelContext.insert(checkpoint)
        checkpoints.append(checkpoint)

        // 同期フラグ
        checkpoint.markNeedsSync()
        currentTrip?.markNeedsSync()

        do {
            try modelContext.save()
            syncToCloud()
        } catch {
            errorMessage = "チェックインの保存に失敗しました"
        }

        isLoading = false
    }

    /// チェックポイントをグループ化する
    private func updateGroupedCheckpoints() {
        guard !checkpoints.isEmpty else {
            groupedCheckpoints = []
            return
        }

        // 距離の閾値（メートル）
        // パフォーマンス向上のため、また「全く同じ場所」という要望に合わせて、
        // 非常に近い距離（約10m以内など）のみをグループ化するように調整
        // 以前の100mは広すぎて処理コストが高く、意図と異なる可能性あり
        let distanceThreshold: CLLocationDistance = 15

        var groups: [GroupedCheckpoint] = []
        var processedIndices = Set<Int>()
        
        let sortedCheckpoints = checkpoints.sorted { $0.latitude < $1.latitude }
        
        for i in 0..<sortedCheckpoints.count {
            if processedIndices.contains(i) { continue }
            
            let baseCP = sortedCheckpoints[i]
            let baseCoord = baseCP.coordinate()
            var groupItems: [Checkpoint] = [baseCP]
            processedIndices.insert(i)
            
            // 緯度が近いものだけを探索 (1度 ≒ 111km, 15m ≒ 0.000135度)
            // 余裕を持って 0.0005度 くらいの範囲を探索
            let latRange = 0.0005
            
            for j in (i + 1)..<sortedCheckpoints.count {
                if processedIndices.contains(j) { continue }
                
                let neighborCP = sortedCheckpoints[j]
                
                if neighborCP.latitude - baseCP.latitude > latRange {
                    // 緯度でソートされているので、これ以上離れたら探索終了
                    break
                }
                
                if baseCoord.distance(to: neighborCP.coordinate()) <= distanceThreshold {
                    groupItems.append(neighborCP)
                    processedIndices.insert(j)
                }
            }
            
            let group = GroupedCheckpoint(
                coordinate: baseCoord,
                checkpoints: groupItems
            )
            groups.append(group)
        }

        groupedCheckpoints = groups
        print("DEBUG: updateGroupedCheckpoints complete. Checkpoints: \(checkpoints.count) -> Groups: \(groups.count)")
    }
}

// CLLocationCoordinate2Dの距離計算用拡張
extension CLLocationCoordinate2D {
    func distance(to other: CLLocationCoordinate2D) -> CLLocationDistance {
        let from = CLLocation(latitude: self.latitude, longitude: self.longitude)
        let to = CLLocation(latitude: other.latitude, longitude: other.longitude)
        return from.distance(from: to)
    }
}
