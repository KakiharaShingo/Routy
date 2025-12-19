//
//  SyncManager.swift
//  Routy
//
//  Created by Auto-generated on 2025/12/18.
//

import Foundation
import SwiftData
import Observation

/// データ同期を管理するマネージャ
@Observable
@MainActor
class SyncManager {
    static let shared = SyncManager()
    
    var isSyncing: Bool = false
    var lastSyncDate: Date?
    var syncError: Error?
    
    private let firestore = FirestoreService.shared
    private let auth = AuthService.shared
    
    private init() {}
    
    /// 全データを同期する
    func syncAll(modelContext: ModelContext) async {
        guard !isSyncing else { 
            print("⚠️ [SyncManager] 既に同期中です")
            return 
        }
        guard auth.isAuthenticated, let userId = auth.currentUser?.uid else {
            print("⚠️ [SyncManager] 同期スキップ: 認証されていません")
            // 未認証ならログイン試行するロジックを入れても良いが、まずはログのみ
            return
        }
            
        isSyncing = true
        print("🔄 [SyncManager] 同期開始...UserId: \(userId)")
        defer { 
            isSyncing = false 
            print("✅ [SyncManager] 同期処理終了")
        }
        
        do {
            // 1. アップロード（ローカルの未同期変更を送信）
            try await uploadPendingItems(userId: userId, context: modelContext)
            
            // 2. ダウンロード（クラウドの変更を受信）
            try await downloadUpdates(userId: userId, context: modelContext)
            
            lastSyncDate = Date()
        } catch {
            print("❌ [SyncManager] 同期エラー: \(error)")
            self.syncError = error
        }
    }
    
    /// 未同期のアイテムをアップロード
    private func uploadPendingItems(userId: String, context: ModelContext) async throws {
        // 同期待ちのTripを取得
        let tripDescriptor = FetchDescriptor<Trip>(predicate: #Predicate { $0.needsSync })
        let pendingTrips = try context.fetch(tripDescriptor)
        
        for trip in pendingTrips {
            if trip.firebaseId == nil {
                // 新規作成
                let newId = try await firestore.createTrip(trip)
                trip.firebaseId = newId
            } else {
                // 更新
                try await firestore.updateTrip(trip)
            }
            // 同期完了状態にする
            trip.needsSync = false
            trip.syncStatus = .synced
            trip.lastSyncedAt = Date()
        }
        
        // 同期待ちのCheckpointを取得
        let checkpointDescriptor = FetchDescriptor<Checkpoint>(predicate: #Predicate { $0.needsSync })
        let pendingCheckpoints = try context.fetch(checkpointDescriptor)
        
        // ユーザープロファイルの取得（プレミアム状態確認のため）
        let profile = try await firestore.getUserProfile(userId: userId)
        let isPremium = profile?["isPremium"] as? Bool ?? false
        
        // 効率化のため、TripIDごとにグルーピングして処理可能だが、ここでは単純ループ
        for checkpoint in pendingCheckpoints {
            let tripId = checkpoint.trip?.firebaseId
            
            // 画像アップロード処理
            if let assetID = checkpoint.photoAssetID, checkpoint.photoURL == nil {
                if let image = await PhotoService().fetchImage(for: assetID) {
                    // CheckpointIDが必要なので、なければ生成しておく(あるいはUUID一時利用)
                    let pId = checkpoint.firebaseId ?? UUID().uuidString
                    do {
                        let url = try await StorageService.shared.uploadPhoto(
                            image: image,
                            userId: userId,
                            photoId: pId,
                            isPremium: isPremium
                        )
                        checkpoint.photoURL = url
                        // サムネイルも同じURLを入れるか、別途サムネイルを作るかだが、
                        // ここでは簡易的に同じURL、あるいはStorageServiceで分けるべきだが今回はphotoURLを優先
                    } catch {
                        print("⚠️ Upload failed: \(error)")
                        // アップロード失敗してもメタデータ同期は進めるか、リトライするか。
                        // ここではログ出して進める
                    }
                }
            }
            
            if checkpoint.firebaseId == nil {
                let newId = try await firestore.createCheckpoint(checkpoint, tripId: tripId)
                checkpoint.firebaseId = newId
            } else {
                // 更新を実行
                try await firestore.updateCheckpoint(checkpoint)
            }
            checkpoint.needsSync = false
            checkpoint.syncStatus = .synced
            checkpoint.lastSyncedAt = Date()
        }
        
        try context.save()
    }
    
    /// クラウドからの更新をダウンロード
    private func downloadUpdates(userId: String, context: ModelContext) async throws {
        // Firebaseから全Trip取得（最適化するなら updatedAfter クエリを使う）
        let cloudTrips = try await firestore.getUserTrips(userId: userId)
        
        for dto in cloudTrips {
            // ローカルに存在するか確認
            let tripId = dto.id
            let descriptor = FetchDescriptor<Trip>(predicate: #Predicate { $0.firebaseId == tripId })
            let existingTrips = try context.fetch(descriptor)
            
            if let existingTrip = existingTrips.first {
                // 競合解決: Last-Write-Wins
                // ローカルの方が新しい、かつまだ同期していない変更がある場合は上書きしない
                if existingTrip.updatedAt < dto.updatedAt && !existingTrip.needsSync {
                    updateLocalTrip(existingTrip, with: dto)
                }
            } else {
                // 新規作成
                let newTrip = createLocalTrip(from: dto, in: context)
                // Checkpointsも取得
                try await downloadCheckpoints(for: newTrip, context: context)
            }
        }
        try context.save()
    }
    
    private func updateLocalTrip(_ trip: Trip, with dto: TripDTO) {
        trip.name = dto.name
        trip.startDate = dto.startDate
        trip.endDate = dto.endDate
        trip.coverPhotoURL = dto.coverPhotoURL
        trip.isPublic = dto.isPublic
        // trip.sharedWith = dto.sharedWith
        trip.updatedAt = dto.updatedAt
        trip.lastSyncedAt = Date()
        trip.syncStatus = .synced
    }
    
    private func createLocalTrip(from dto: TripDTO, in context: ModelContext) -> Trip {
        let trip = Trip(
            name: dto.name,
            startDate: dto.startDate,
            endDate: dto.endDate,
            coverPhotoURL: dto.coverPhotoURL,
            createdAt: dto.createdAt,
            updatedAt: dto.updatedAt
        )
        trip.firebaseId = dto.id
        trip.isPublic = dto.isPublic
        // trip.sharedWith = dto.sharedWith
        trip.syncStatus = .synced
        trip.lastSyncedAt = Date()
        context.insert(trip)
        return trip
    }
    
    private func downloadCheckpoints(for trip: Trip, context: ModelContext) async throws {
        guard let tripId = trip.firebaseId else { return }
        let dtos = try await firestore.getCheckpoints(forTrip: tripId)
        
        for dto in dtos {
            // CheckpointTypeの変換
            guard let type = CheckpointType(rawValue: dto.typeRawValue) else { continue }
            
            let checkpoint = Checkpoint(
                latitude: dto.latitude,
                longitude: dto.longitude,
                timestamp: dto.timestamp,
                type: type,
                photoAssetID: dto.photoAssetID,
                photoThumbnailURL: dto.photoThumbnailURL, // Checkpoint init includes this
                photoURL: dto.photoURL,
                name: dto.name,
                note: dto.note,
                address: dto.address,
                trip: trip
            )
            checkpoint.firebaseId = dto.id
            checkpoint.photoThumbnailURL = dto.photoThumbnailURL
            checkpoint.syncStatus = .synced
            checkpoint.lastSyncedAt = Date()
            context.insert(checkpoint)
        }
    }
}
