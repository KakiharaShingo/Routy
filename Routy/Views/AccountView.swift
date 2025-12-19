//
//  AccountView.swift
//  Routy
//
//  Created by Auto-generated on 2025/12/19.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth
import AuthenticationServices
import GoogleSignIn
import CryptoKit

import FirebaseFirestore

/// アカウント情報・設定画面
struct AccountView: View {
    @Environment(\.dismiss) private var dismiss
    private let authService = AuthService.shared
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = "" // 確認用パスワード
    @State private var displayName = ""      // お名前
    @State private var residence = ""        // 居住地
    @State private var dateOfBirth = Date()  // 生年月日
    @State private var isPremium = false     // プレミアム会員かどうか
    
    @State private var fetchedDOB: Date?     // 表示用の取得した生年月日
    @State private var fetchedResidence: String? // 表示用の取得した居住地
    @State private var fetchedIsPremium = false // 表示用のプレミアム状態
    
    @State private var isRegistering = false
    @State private var isEditing = false     // 編集モード
    @State private var errorMessage: String?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showSignIn = false // 既存アカウントへの切り替え
    @State private var currentNonce: String?
    @State private var showForgotPassword = false // パスワード忘れ
    @State private var resetEmail = ""

    var body: some View {
        Form {
            Section(header: Text("アカウントステータス")) {
                if authService.isAnonymous {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("未保護（匿名）")
                            .foregroundColor(.orange)
                    }
                    Text("現在、データはこの端末にのみ保存されています。アプリを削除するとデータは消えます。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("保護済み")
                            .foregroundColor(.green)
                    }
                    
                    if isEditing {
                        // 編集モード
                        TextField("お名前", text: $displayName)
                            .textContentType(.name)
                        TextField("居住地（都道府県）", text: $residence)
                        DatePicker("生年月日", selection: $dateOfBirth, displayedComponents: .date)
                        
                        Button("保存") {
                            saveProfileChanges()
                        }
                        .disabled(displayName.isEmpty)
                        
                        Button("キャンセル") {
                            isEditing = false
                            // 編集用変数を元に戻す（再取得）
                            Task { await fetchUserProfile() }
                        }
                        .foregroundColor(.red)
                        
                    } else {
                        // 表示モード
                        VStack(alignment: .leading, spacing: 4) {
                            if let currentUser = authService.currentUser {
                                // お名前
                                HStack {
                                    if let name = currentUser.displayName, !name.isEmpty {
                                        Text(name)
                                            .font(.headline)
                                    } else {
                                        Text("（お名前未設定）")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Button("編集") {
                                        // 編集モード開始時に現在の値をセット
                                        displayName = currentUser.displayName ?? ""
                                        if let dob = fetchedDOB { dateOfBirth = dob }
                                        if let res = fetchedResidence { residence = res }
                                        isEditing = true
                                    }
                                    .font(.caption)
                                    .buttonStyle(.bordered)
                                }
                                
                                // メール
                                if let email = currentUser.email {
                                    Text(email)
                                        .foregroundColor(.secondary)
                                }
                                // 居住地
                                if let res = self.fetchedResidence, !res.isEmpty {
                                    Text("居住地: \(res)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                // 生年月日
                                if let dob = self.fetchedDOB {
                                    Text("生年月日: \(DateFormatter.dateOnly.string(from: dob))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.top, 4)
                    }
                    
                    // プレミアム状態表示
                    HStack {
                        if fetchedIsPremium {
                            Image(systemName: "crown.fill")
                                .foregroundColor(.yellow)
                            Text("プレミアムプラン")
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                        } else {
                            Image(systemName: "person.fill")
                                .foregroundColor(.gray)
                            Text("無料プラン")
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .onAppear {
                Task { await fetchUserProfile() }
            }
            
            
            // プレミアムプラン切替（シミュレーション用）
            if !authService.isAnonymous {
                Section(header: Text("設定")) {
                    Toggle("プレミアムモード（高画質保存）", isOn: $isPremium)
                        .onChange(of: isPremium) { newValue in
                            savePremiumStatus(newValue)
                        }
                }
            }
            
            if authService.isAnonymous {
                Section(header: Text(showSignIn ? "ログイン（データ復元）" : "アカウント登録（データを保護）")) {
                    if !showSignIn {
                        // 登録時のみ表示
                        TextField("お名前", text: $displayName)
                            .textContentType(.name)
                        
                        TextField("居住地（都道府県）", text: $residence)

                        DatePicker("生年月日", selection: $dateOfBirth, displayedComponents: .date)
                    }

                    TextField("メールアドレス", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .textContentType(.emailAddress)
                    
                    SecureField("パスワード", text: $password)
                        .textContentType(showSignIn ? .password : .newPassword)
                    
                    if !showSignIn {
                        // 登録時のみ確認用パスワード
                        SecureField("パスワード（確認）", text: $confirmPassword)
                            .textContentType(.newPassword)
                    }
                    
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    if showSignIn {
                        Button("パスワードをお忘れですか？") {
                            resetEmail = email
                            showForgotPassword = true
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    
                    Button(action: performAction) {
                        if isRegistering {
                            ProgressView()
                        } else {
                            Text(showSignIn ? "ログイン" : "登録して保護する")
                                .frame(maxWidth: .infinity)
                                .foregroundColor(showSignIn ? .blue : .green)
                        }
                    }
                    .disabled(!isValidForm || isRegistering)
                }
                
                Section(header: Text("または")) {
                    // Google Sign-In
                    Button(action: {
                        Task {
                            do {
                                try await authService.linkWithGoogle()
                                await fetchUserProfile() // 成功時にプロフィール取得
                                dismiss()
                            } catch {
                                // リンク失敗時の処理
                                let nsError = error as NSError
                                if nsError.domain == AuthErrorDomain, nsError.code == AuthErrorCode.credentialAlreadyInUse.rawValue {
                                    // すでに他のアカウントで使われている場合 -> ログインに切り替え
                                    errorMessage = "このGoogleアカウントは既に使用されています。ログインします..."
                                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                                    do {
                                        try await authService.signInWithGoogle()
                                        await fetchUserProfile()
                                        dismiss()
                                    } catch {
                                        errorMessage = "ログインに失敗しました: \(error.localizedDescription)"
                                    }
                                } else {
                                    errorMessage = "Google連携に失敗しました: \(error.localizedDescription)"
                                }
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: "g.circle.fill") // 簡易アイコン
                            Text("Googleで保護")
                        }
                    }
                    
                    /* Apple Sign-In Disabled */
                    /*
                    SignInWithAppleButton(...)
                    */
                    Text("Appleログインは一時的に無効")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section {
                    Button(showSignIn ? "アカウント登録はこちら" : "すでにアカウントをお持ちの方") {
                        withAnimation {
                            showSignIn.toggle()
                            errorMessage = nil
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            } else {
                Section {
                    Button("ログアウト", role: .destructive) {
                        try? authService.signOut()
                    }
                }
            }
        }
        .navigationTitle("アカウント設定")
        .alert("完了", isPresented: $showingAlert) {
            Button("OK") {
                if !showForgotPassword {
                     dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
        .alert("パスワード再設定", isPresented: $showForgotPassword) {
            TextField("メールアドレス", text: $resetEmail)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
            Button("送信") {
                Task {
                    do {
                        try await authService.sendPasswordReset(email: resetEmail)
                        alertMessage = "再設定メールを送信しました。\nメールを確認してください。"
                        showingAlert = true
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }
            }
            Button("キャンセル", role: .cancel) { }
        } message: {
            Text("登録したメールアドレスを入力してください。")
        }
    }
    
    private var isValidForm: Bool {
        if showSignIn {
            return !email.isEmpty && password.count >= 6
        } else {
            return !displayName.isEmpty &&
                   !email.isEmpty &&
                   password.count >= 6 &&
                   password == confirmPassword
        }
    }
    
    private func savePremiumStatus(_ newValue: Bool) {
        Task {
            guard let uid = authService.currentUser?.uid else { return }
            do {
                let data: [String: Any] = ["isPremium": newValue]
                try await FirestoreService.shared.saveUserProfile(userId: uid, data: data)
                await fetchUserProfile()
            } catch {
                print("Failed to save premium status: \(error)")
                // ロールバック
                isPremium = !newValue
            }
        }
    }
    
    private func saveProfileChanges() {
        Task {
            do {
                // 表示名更新
                try await authService.updateUserProfile(displayName: displayName)
                
                // Firestore更新
                if let uid = authService.currentUser?.uid {
                    let profileData: [String: Any] = [
                        "dateOfBirth": Timestamp(date: dateOfBirth),
                        "residence": residence,
                        "displayName": displayName,
                        "updatedAt": Timestamp(date: Date())
                    ]
                    try await FirestoreService.shared.saveUserProfile(userId: uid, data: profileData)
                }
                
                isEditing = false
                await fetchUserProfile() // 最新状態を反映
            } catch {
                errorMessage = "保存に失敗しました: \(error.localizedDescription)"
            }
        }
    }
    
    private func performAction() {
        isRegistering = true
        errorMessage = nil
        
        Task {
            do {
                if showSignIn {
                    // ログイン
                    try await authService.signInWithEmail(email: email, password: password)
                    alertMessage = "ログインしました。"
                } else {
                    // 登録
                    try await authService.linkWithEmail(email: email, password: password)
                    
                    // プロフィール初期保存
                    if let uid = authService.currentUser?.uid {
                         // 表示名更新
                        try await authService.updateUserProfile(displayName: displayName)
                        
                        let profileData: [String: Any] = [
                            "dateOfBirth": Timestamp(date: dateOfBirth),
                            "residence": residence,
                            "email": email,
                            "displayName": displayName,
                            "updatedAt": Timestamp(date: Date())
                        ]
                        try await FirestoreService.shared.saveUserProfile(userId: uid, data: profileData)
                    }
                    
                    alertMessage = "登録が完了しました。\nデータは保護されています。"
                }
                
                // プロフィール再取得
                await fetchUserProfile()
                
                showingAlert = true
            } catch {
                errorMessage = error.localizedDescription
                // 日本語翻訳ロジック...
                if let err = error as NSError? {
                    if err.code == AuthErrorCode.emailAlreadyInUse.rawValue {
                        errorMessage = "このメールアドレスは既に使用されています。ログインしてください。"
                    }
                }
            }
            isRegistering = false
        }
    }
    
    private func handleAppleSignIn(authorization: ASAuthorization) async {
        // ... Disabled ...
    }
    
    private func fetchUserProfile() async {
        guard let uid = authService.currentUser?.uid, !authService.isAnonymous else { return }
        do {
            if let data = try await FirestoreService.shared.getUserProfile(userId: uid) {
                if let timestamp = data["dateOfBirth"] as? Timestamp {
                    self.fetchedDOB = timestamp.dateValue()
                }
                if let res = data["residence"] as? String {
                    self.fetchedResidence = res
                }
                if let premium = data["isPremium"] as? Bool {
                    self.fetchedIsPremium = premium
                    self.isPremium = premium
                }
            }
        } catch {
            print("Failed to fetch profile: \(error)")
        }
    }
}

#Preview {
    NavigationView {
        AccountView()
    }
}
