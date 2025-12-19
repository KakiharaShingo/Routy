//
//  FirebaseManager.swift
//  Routy
//
//  Created by Auto-generated on 2025/12/18.
//

import Foundation
import FirebaseCore

/// Firebaseの初期化と構成を管理するシングルトン
class FirebaseManager {
    /// 共有インスタンス
    static let shared = FirebaseManager()
    
    /// 設定済みかどうか
    private(set) var isConfigured = false
    
    private init() {}
    
    /// Firebaseを構成する
    /// アプリ起動時に呼び出してください
    func configure() {
        guard !isConfigured else { return }
        
        // GoogleService-Info.plistの存在チェック（オプション：デバッグ用）
        if Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") == nil {
            print("⚠️ [FirebaseManager] GoogleService-Info.plistが見つかりません。Firebaseの初期化に失敗する可能性があります。")
        }
        
        FirebaseApp.configure()
        isConfigured = true
        print("✅ [FirebaseManager] Firebase初期化完了")
    }
}
