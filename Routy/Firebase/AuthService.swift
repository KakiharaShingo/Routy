//
//  AuthService.swift
//  Routy
//
//  Created by Auto-generated on 2025/12/18.
//

import Foundation
import NotificationCenter
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import AuthenticationServices
import CryptoKit
import Observation

/// 認証関連の操作を提供するサービス
@Observable
class AuthService {
    /// 現在のユーザー
    var currentUser: User?
    /// 認証済みかどうか
    var isAuthenticated: Bool = false
    /// 匿名アカウントかどうか
    var isAnonymous: Bool {
        currentUser?.isAnonymous ?? true
    }
    
    /// 共有インスタンス
    static let shared = AuthService()
    
    private var authStateListenerHandle: AuthStateDidChangeListenerHandle?
    
    private init() {
        // 認証状態の変更を監視
        self.authStateListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            let previousUser = self?.currentUser
            let previousUserId = previousUser?.uid
            let previousIsAnonymous = previousUser?.isAnonymous ?? false
            let newUserId = user?.uid
            let newIsAnonymous = user?.isAnonymous ?? true

            self?.currentUser = user
            self?.isAuthenticated = (user != nil)
            print("👤 [AuthService] ユーザー状態変更: \(user?.uid ?? "nil"), 匿名: \(newIsAnonymous)")

            // ログイン/ログアウトイベントを通知
            if let newUserId = newUserId, previousUserId != newUserId {
                // 匿名→匿名の場合はスキップ（アプリ起動時の初回匿名ログイン）
                if previousIsAnonymous && newIsAnonymous {
                    print("👤 [AuthService] 初回匿名ログイン - 通知スキップ")
                    return
                }

                // ログインまたはユーザー切り替え
                // 匿名→本登録の場合もログインとして通知（データは保持）
                NotificationCenter.default.post(
                    name: .authStateDidChange,
                    object: nil,
                    userInfo: ["isLogin": true, "userId": newUserId, "isAnonymous": newIsAnonymous]
                )
            } else if newUserId == nil && previousUserId != nil {
                // ログアウト（明示的なサインアウト）
                NotificationCenter.default.post(
                    name: .authStateDidChange,
                    object: nil,
                    userInfo: ["isLogin": false, "userId": ""]
                )
            }
        }
    }
    
    deinit {
        if let handle = authStateListenerHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    /// 匿名ログインを行う
    @discardableResult
    func signInAnonymously() async throws -> User {
        let result = try await Auth.auth().signInAnonymously()
        print("✅ [AuthService] 匿名ログイン成功: \(result.user.uid)")
        return result.user
    }
    
    /// サインアウト
    func signOut() throws {
        try Auth.auth().signOut()
        print("👋 [AuthService] サインアウトしました")
    }
    
    /// アカウント削除
    func deleteAccount() async throws {
        guard let user = Auth.auth().currentUser else { return }
        try await user.delete()
        print("🗑️ [AuthService] アカウント削除完了")
    }
    
    /// メールアドレスでアカウントをリンク（登録）する
    func linkWithEmail(email: String, password: String) async throws {
        guard let user = Auth.auth().currentUser else { return }
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        let result = try await user.link(with: credential)
        print("✅ [AuthService] アカウントリンク成功: \(result.user.email ?? "")")
        self.currentUser = result.user
    }
    
    /// メールアドレスでログインする（機種変更時など）
    func signInWithEmail(email: String, password: String) async throws {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        print("✅ [AuthService] メールログイン成功: \(result.user.uid)")
        self.currentUser = result.user
    }
    
    /// ユーザープロフィール（表示名）を更新する
    func updateUserProfile(displayName: String) async throws {
        guard let user = Auth.auth().currentUser else { return }
        
        let changeRequest = user.createProfileChangeRequest()
        changeRequest.displayName = displayName
        try await changeRequest.commitChanges()
        
        // ローカルの状態を更新するためにリロード
        try await user.reload()
        self.currentUser = Auth.auth().currentUser
    }
    
    /// パスワード再設定メールを送信する
    func sendPasswordReset(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
        print("✅ [AuthService] パスワード再設定メール送信: \(email)")
    }
    
    // MARK: - Google Auth
    
    /// Googleアカウントをリンクする
    @MainActor
    func linkWithGoogle() async throws {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else { return }
        
        // Googleサインインフロー開始
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
        
        // idTokenとaccessTokenを取得 (SDKのバージョンによってはOptionalでない場合もあるため確認)
        let user = result.user
        guard let idToken = user.idToken?.tokenString else { return }
        let accessToken = user.accessToken.tokenString
        
        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
        
        // 既存ユーザーにリンク
        guard let user = Auth.auth().currentUser else { return }
        let authResult = try await user.link(with: credential)
        print("✅ [AuthService] Googleアカウントリンク成功: \(authResult.user.uid)")
        self.currentUser = authResult.user
    }

    /// Googleアカウントでログインする（既存アカウントへの切り替え）
    @MainActor
    func signInWithGoogle() async throws {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else { return }
        
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
        
        let user = result.user
        guard let idToken = user.idToken?.tokenString else { return }
        let accessToken = user.accessToken.tokenString
        
        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
        
        let authResult = try await Auth.auth().signIn(with: credential)
        print("✅ [AuthService] Googleログイン成功: \(authResult.user.uid)")
        self.currentUser = authResult.user
    }
    
    // MARK: - Apple Auth
    
    /// Apple IDでリンクするための nonce 生成ヘルパー
    func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }

            randoms.forEach { random in
                if remainingLength == 0 { return }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        return result
    }
    
    func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap {
            return String(format: "%02x", $0)
        }.joined()
    }
}
