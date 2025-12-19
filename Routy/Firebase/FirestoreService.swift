//
//  FirestoreService.swift
//  Routy
//
//  Created by Auto-generated on 2025/12/18.
//

import Foundation
import FirebaseFirestore

/// Firestoreへのデータアクセスを提供するサービス
class FirestoreService {
    /// 共有インスタンス
    static let shared = FirestoreService()
    
    private let db = Firestore.firestore()
    
    private init() {
        let settings = FirestoreSettings()
        // オフラインキャッシュを有効化（推奨される新しい設定方法）
        settings.cacheSettings = PersistentCacheSettings()
        db.settings = settings
    }
    
    // MARK: - Trips
    
    /// Tripを作成する
    func createTrip(_ trip: Trip) async throws -> String {
        guard let userId = AuthService.shared.currentUser?.uid else {
            throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "ユーザーがログインしていません"])
        }
        
        let data: [String: Any] = [
            "userId": userId,
            "name": trip.name,
            "startDate": Timestamp(date: trip.startDate),
            "endDate": Timestamp(date: trip.endDate),
            "coverPhotoURL": trip.coverPhotoURL as Any,
            "isPublic": trip.isPublic,
            // "sharedWith": trip.sharedWith,
            "createdAt": Timestamp(date: trip.createdAt),
            "updatedAt": Timestamp(date: trip.updatedAt)
        ]
        
        // 新しいドキュメント参照を作成
        let ref = db.collection("trips").document()
        try await ref.setData(data)
        
        return ref.documentID
    }
    
    /// Tripを更新する
    func updateTrip(_ trip: Trip) async throws {
        guard let tripId = trip.firebaseId else {
            throw NSError(domain: "DataError", code: 404, userInfo: [NSLocalizedDescriptionKey: "FirebaseIDがありません"])
        }
        
        let data: [String: Any] = [
            "name": trip.name,
            "startDate": Timestamp(date: trip.startDate),
            "endDate": Timestamp(date: trip.endDate),
            "coverPhotoURL": trip.coverPhotoURL as Any,
            "isPublic": trip.isPublic,
            // "sharedWith": trip.sharedWith,
            "updatedAt": Timestamp(date: Date()) // 更新時は現在時刻
        ]
        
        try await db.collection("trips").document(tripId).updateData(data)
    }
    
    /// ユーザーの旅行一覧を取得する
    func getUserTrips(userId: String) async throws -> [TripDTO] {
        let snapshot = try await db.collection("trips")
            .whereField("userId", isEqualTo: userId)
            .order(by: "startDate", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc -> TripDTO? in
            let data = doc.data()
            return TripDTO(id: doc.documentID, data: data)
        }
    }
    
    // MARK: - Checkpoints
    
    /// Checkpointを作成する
    func createCheckpoint(_ checkpoint: Checkpoint, tripId: String?) async throws -> String {
        guard let userId = AuthService.shared.currentUser?.uid else {
            throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "ログインしていません"])
        }
        
        var data: [String: Any] = [
            "userId": userId,
            "latitude": checkpoint.latitude,
            "longitude": checkpoint.longitude,
            "timestamp": Timestamp(date: checkpoint.timestamp),
            "type": checkpoint.type.rawValue, // CheckpointTypeがString RawRepresentableである前提
            "photoAssetID": checkpoint.photoAssetID as Any,
            "photoThumbnailURL": checkpoint.photoThumbnailURL as Any,
            "photoURL": checkpoint.photoURL as Any,
            "name": checkpoint.name as Any,
            "note": checkpoint.note as Any,
            "address": checkpoint.address as Any,
            "createdAt": Timestamp(date: Date())
        ]
        
        if let tripId = tripId {
            data["tripId"] = tripId
        } else {
             data["tripId"] = NSNull()
        }
        
        let ref = db.collection("checkpoints").document()
        try await ref.setData(data)
        
        return ref.documentID
    }
    
    /// Checkpointを更新する
    func updateCheckpoint(_ checkpoint: Checkpoint) async throws {
        guard let checkpointId = checkpoint.firebaseId else {
            throw NSError(domain: "DataError", code: 404, userInfo: [NSLocalizedDescriptionKey: "FirebaseIDがありません"])
        }
        
        // 更新対象のフィールドのみ更新（マージ）
        let data: [String: Any] = [
            "latitude": checkpoint.latitude,
            "longitude": checkpoint.longitude,
            "timestamp": Timestamp(date: checkpoint.timestamp),
            "type": checkpoint.type.rawValue,
            "photoAssetID": checkpoint.photoAssetID as Any,
            "photoThumbnailURL": checkpoint.photoThumbnailURL as Any,
            "photoURL": checkpoint.photoURL as Any,
            "name": checkpoint.name as Any,
            "note": checkpoint.note as Any,
            "address": checkpoint.address as Any
            // "updatedAt": Timestamp(date: Date()) // CheckpointにupdatedAtがあれば更新
        ]
        
        try await db.collection("checkpoints").document(checkpointId).updateData(data)
    }
    
    /// 複数のCheckpointを一括作成
    func batchCreateCheckpoints(_ checkpoints: [Checkpoint], tripId: String) async throws {
        guard let userId = AuthService.shared.currentUser?.uid else { return }
        
        let batch = db.batch()
        
        for checkpoint in checkpoints {
            let ref = db.collection("checkpoints").document()
            let data: [String: Any] = [
                "userId": userId,
                "tripId": tripId,
                "latitude": checkpoint.latitude,
                "longitude": checkpoint.longitude,
                "timestamp": Timestamp(date: checkpoint.timestamp),
                "type": checkpoint.type.rawValue, // Assuming CheckpointType is String enum
                "photoAssetID": checkpoint.photoAssetID as Any,
                "photoThumbnailURL": checkpoint.photoThumbnailURL as Any,
                "photoURL": checkpoint.photoURL as Any,
                "name": checkpoint.name as Any,
                "note": checkpoint.note as Any,
                "address": checkpoint.address as Any,
                "createdAt": Timestamp(date: Date())
            ]
            batch.setData(data, forDocument: ref)
        }
        
        try await batch.commit()
    }
    
    /// Tripに関連するCheckpointを取得
    func getCheckpoints(forTrip tripId: String) async throws -> [CheckpointDTO] {
        let snapshot = try await db.collection("checkpoints")
            .whereField("tripId", isEqualTo: tripId)
            .order(by: "timestamp", descending: false)
            .getDocuments()
            
        return snapshot.documents.compactMap { doc -> CheckpointDTO? in
            let data = doc.data()
            return CheckpointDTO(id: doc.documentID, data: data)
        }
    }
    // MARK: - Users
    
    /// ユーザープロフィールを保存する
    /// - Parameters:
    ///   - userId: ユーザーID (Auth.uid)
    ///   - data: 保存するデータ (dateOfBirthなど)
    func saveUserProfile(userId: String, data: [String: Any]) async throws {
        // マージオプションで保存（既存データを消さない）
        try await db.collection("users").document(userId).setData(data, merge: true)
    }
    
    /// ユーザープロフィールを取得する
    /// - Parameter userId: ユーザーID
    /// - Returns: プロフィールデータ (Dictionary)
    func getUserProfile(userId: String) async throws -> [String: Any]? {
        let doc = try await db.collection("users").document(userId).getDocument()
        return doc.data()
    }
}

// MARK: - DTOs
// SwiftDataモデルに依存せず、Firestoreデータを扱いやすくするための中間オブジェクト

struct TripDTO {
    let id: String
    let name: String
    let startDate: Date
    let endDate: Date
    let coverPhotoURL: String?
    let isPublic: Bool
    // let sharedWith: [String]
    let createdAt: Date
    let updatedAt: Date
    
    init?(id: String, data: [String: Any]) {
        self.id = id
        guard
            let name = data["name"] as? String,
            let startTs = data["startDate"] as? Timestamp,
            let endTs = data["endDate"] as? Timestamp,
            let createdTs = data["createdAt"] as? Timestamp,
            let updatedTs = data["updatedAt"] as? Timestamp
        else { return nil }
        
        self.name = name
        self.startDate = startTs.dateValue()
        self.endDate = endTs.dateValue()
        self.coverPhotoURL = data["coverPhotoURL"] as? String
        self.isPublic = data["isPublic"] as? Bool ?? false
        // self.sharedWith = data["sharedWith"] as? [String] ?? []
        self.createdAt = createdTs.dateValue()
        self.updatedAt = updatedTs.dateValue()
    }
}

struct CheckpointDTO {
    let id: String
    let latitude: Double
    let longitude: Double
    let timestamp: Date
    let typeRawValue: String // CheckpointTypeの変換は呼び出し元で行う
    let photoAssetID: String?
    let photoThumbnailURL: String?
    let photoURL: String?
    let name: String?
    let note: String?
    let address: String?
    
    init?(id: String, data: [String: Any]) {
        self.id = id
        guard
            let lat = data["latitude"] as? Double,
            let lon = data["longitude"] as? Double,
            let ts = data["timestamp"] as? Timestamp,
            let type = data["type"] as? String
        else { return nil }
        
        self.latitude = lat
        self.longitude = lon
        self.timestamp = ts.dateValue()
        self.typeRawValue = type
        self.photoAssetID = data["photoAssetID"] as? String
        self.photoThumbnailURL = data["photoThumbnailURL"] as? String
        self.photoURL = data["photoURL"] as? String
        self.name = data["name"] as? String
        self.note = data["note"] as? String
        self.address = data["address"] as? String
    }
}
