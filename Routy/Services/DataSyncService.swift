//
//  DataSyncService.swift
//  Routy
//
//  ログイン/ログアウト時のデータ同期を管理するサービス
//

import Foundation
import SwiftData
import Observation

/// ログイン/ログアウト時のデータ同期を管理
@MainActor
@Observable
class DataSyncService {
    static let shared = DataSyncService()

    private let authService = AuthService.shared
    private let syncManager = SyncManager.shared
    private var authStateObserver: Any?

    var isProcessing = false

    private init() {}

    /// 認証状態の監視を開始
    func startMonitoring(modelContext: ModelContext) {
        // AuthServiceの認証状態変更を監視
        // authStateListenerHandleで既に監視されているので、currentUserの変化を監視
        observeAuthStateChanges(modelContext: modelContext)
    }

    private func observeAuthStateChanges(modelContext: ModelContext) {
        // AuthServiceを拡張してNotificationを送信する方式を採用
        NotificationCenter.default.addObserver(
            forName: .authStateDidChange,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self else { return }

            if let userInfo = notification.userInfo,
               let isLogin = userInfo["isLogin"] as? Bool,
               let userId = userInfo["userId"] as? String {

                Task {
                    if isLogin {
                        await self.handleLogin(userId: userId, modelContext: modelContext)
                    } else {
                        await self.handleLogout(modelContext: modelContext)
                    }
                }
            }
        }
    }

    /// ログイン時の処理
    private func handleLogin(userId: String, modelContext: ModelContext) async {
        guard !isProcessing else { return }
        isProcessing = true
        defer { isProcessing = false }

        print("🔐 [DataSyncService] ログイン検出: \(userId)")

        // 1. ローカルの既存データをクラウドにアップロード
        await syncManager.syncAll(modelContext: modelContext)

        // 2. クラウドからデータをダウンロード（既に syncAll で実行済み）
        print("✅ [DataSyncService] ログイン時のデータ同期完了")
    }

    /// ログアウト時の処理
    private func handleLogout(modelContext: ModelContext) async {
        guard !isProcessing else { return }
        isProcessing = true
        defer { isProcessing = false }

        print("👋 [DataSyncService] ログアウト検出")

        // ローカルの全データを削除
        await clearLocalData(modelContext: modelContext)

        print("✅ [DataSyncService] ローカルデータをクリア完了")
    }

    /// ローカルデータを全削除
    func clearLocalData(modelContext: ModelContext) async {
        do {
            // 全Tripを削除
            try modelContext.delete(model: Trip.self)

            // 全Checkpointを削除
            try modelContext.delete(model: Checkpoint.self)

            try modelContext.save()

            print("🗑️ [DataSyncService] ローカルデータを削除しました")
        } catch {
            print("❌ [DataSyncService] データ削除エラー: \(error)")
        }
    }

    /// 手動で同期を実行
    func manualSync(modelContext: ModelContext) async {
        guard authService.isAuthenticated else {
            print("⚠️ [DataSyncService] 認証されていないため同期できません")
            return
        }

        await syncManager.syncAll(modelContext: modelContext)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let authStateDidChange = Notification.Name("authStateDidChange")
}
