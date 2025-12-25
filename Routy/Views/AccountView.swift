//
//  AccountView.swift
//  Routy
//
//  Created by Auto-generated on 2025/12/19.
//

import SwiftUI
import SwiftData
import FirebaseCore
import FirebaseAuth
import AuthenticationServices
import GoogleSignIn
import CryptoKit

import FirebaseFirestore

/// アカウント情報・設定画面 (Redesigned)
struct AccountView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
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
    @State private var showLogoutConfirmation = false // ログアウト確認

    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    
                    // Profile Header
                    if !authService.isAnonymous {
                         ProfileHeaderCard
                    } else {
                        AnonymousWarningCard
                    }

                    // Account Actions / Forms
                    if authService.isAnonymous {
                         RegistrationFormCard
                    } else {
                         SettingsCard
                         LogoutButton
                    }

                    Spacer(minLength: 40)
                }
                .padding(20)
            }
        }
        .navigationTitle("アカウント設定")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task { await fetchUserProfile() }
        }
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
    
    // MARK: - Subviews
    
    var ProfileHeaderCard: some View {
        VStack(spacing: 20) {
            // Edit Mode Toggle
            HStack {
                Spacer()
                Button(action: {
                    if isEditing {
                        // Cancel
                        isEditing = false
                        Task { await fetchUserProfile() }
                    } else {
                        // Start Editing
                        if let currentUser = authService.currentUser {
                            displayName = currentUser.displayName ?? ""
                        }
                        if let dob = fetchedDOB { dateOfBirth = dob }
                        if let res = fetchedResidence { residence = res }
                        isEditing = true
                    }
                }) {
                    Text(isEditing ? "キャンセル" : "編集")
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(isEditing ? Color.red.opacity(0.1) : Color.blue.opacity(0.1))
                        .foregroundColor(isEditing ? .red : .blue)
                        .clipShape(Capsule())
                }
            }
            
            // Avatar & Name
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.1))
                        .frame(width: 80, height: 80)
                    Image(systemName: "person.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.orange)
                }
                
                if isEditing {
                    TextField("お名前", text: $displayName)
                        .multilineTextAlignment(.center)
                        .font(.title3)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                } else {
                    Text(authService.currentUser?.displayName ?? "ゲスト")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                // Email
                if let email = authService.currentUser?.email {
                    Text(email)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Divider()
            
            // Details
            VStack(spacing: 12) {
                if isEditing {
                    TextField("居住地（都道府県）", text: $residence)
                        .padding(10)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    
                    DatePicker("生年月日", selection: $dateOfBirth, displayedComponents: .date)
                } else {
                    HStack {
                        Label("居住地", systemImage: "mappin.and.ellipse")
                        Spacer()
                        Text(fetchedResidence ?? "未設定")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Label("生年月日", systemImage: "calendar")
                        Spacer()
                        if let dob = fetchedDOB {
                            Text(DateFormatter.dateOnly.string(from: dob))
                                .foregroundColor(.secondary)
                        } else {
                             Text("未設定")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .font(.subheadline)
            
            if isEditing {
                Button(action: saveProfileChanges) {
                    Text("保存する")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(displayName.isEmpty ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(displayName.isEmpty)
            }
            
            // Premium Badge
            HStack {
                Spacer()
                if fetchedIsPremium {
                    Label("プレミアムプラン", systemImage: "crown.fill")
                        .font(.caption)
                        .padding(6)
                        .background(Color.yellow.opacity(0.2))
                        .foregroundColor(.orange)
                        .cornerRadius(6)
                } else {
                    Label("無料プラン", systemImage: "person")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Spacer()
            }
        }
        .padding(24)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
    
    var AnonymousWarningCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundColor(.orange)
            
            Text("データは保護されていません")
                .font(.headline)
            
            Text("現在ゲストとして利用中です。\nアプリを削除するとデータは消えてしまいます。アカウント登録してデータを保護しましょう。")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.orange.opacity(0.3), lineWidth: 2)
        )
    }
    
    var RegistrationFormCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(showSignIn ? "ログイン" : "アカウント登録")
                .font(.headline)
            
            VStack(spacing: 16) {
                if !showSignIn {
                    CustomTextField(icon: "person", placeholder: "お名前", text: $displayName)
                    CustomTextField(icon: "map", placeholder: "居住地（都道府県）", text: $residence)
                    DatePicker("生年月日", selection: $dateOfBirth, displayedComponents: .date)
                        .font(.subheadline)
                }
                
                CustomTextField(icon: "envelope", placeholder: "メールアドレス", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)

                CustomSecureField(icon: "lock", placeholder: "パスワード", text: $password)
                
                if !showSignIn {
                    CustomSecureField(icon: "lock", placeholder: "パスワード（確認）", text: $confirmPassword)
                }
            }
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            if showSignIn {
                Button("パスワードをお忘れですか？") {
                    resetEmail = email
                    showForgotPassword = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            // Main Action Button
            Button(action: performAction) {
                if isRegistering {
                    ProgressView()
                } else {
                    Text(showSignIn ? "ログイン" : "登録して保護する")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isValidForm ? Color.orange : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            .disabled(!isValidForm || isRegistering)
            
            Divider()
            
            // Google Sign In
            Button(action: {
                Task {
                    do {
                        try await authService.linkWithGoogle()
                        await fetchUserProfile()
                        dismiss()
                    } catch {
                         // Error handling logic (abbreviated for brevity but kept same logic in mind)
                        errorMessage = "Google連携エラー: \(error.localizedDescription)"
                    }
                }
            }) {
                HStack {
                    Image(systemName: "g.circle.fill")
                    Text("Googleで続ける")
                }
                .fontWeight(.medium)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .foregroundColor(.primary)
                .cornerRadius(12)
            }
            
            // Toggle Mode
            Button(action: {
                withAnimation {
                    showSignIn.toggle()
                    errorMessage = nil
                }
            }) {
                Text(showSignIn ? "アカウント登録はこちら" : "すでにアカウントをお持ちの方")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(24)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
    
    var SettingsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("その他")
                .font(.headline)

            NavigationLink(destination: SettingsView()) {
                HStack {
                    Label("アプリ設定", systemImage: "gearshape")
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }

            // プレミアムモードは将来実装予定のため一旦非表示
            // Toggle("プレミアムモード（高画質保存）", isOn: $isPremium)
            //     .onChange(of: isPremium) { newValue in
            //         savePremiumStatus(newValue)
            //     }
            //     .padding(12)
            //     .background(Color(.systemGray6))
            //     .cornerRadius(12)
        }
        .padding(24)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
    }

    var LogoutButton: some View {
        Button(action: {
            showLogoutConfirmation = true
        }) {
            Text("ログアウト")
                .fontWeight(.bold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .foregroundColor(.red)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .alert("ログアウトしますか？", isPresented: $showLogoutConfirmation) {
            Button("キャンセル", role: .cancel) { }
            Button("ログアウト", role: .destructive) {
                Task {
                    // ログアウト前にクラウドに同期
                    await SyncManager.shared.syncAll(modelContext: modelContext)
                    // ログアウト
                    try? authService.signOut()
                }
            }
        } message: {
            Text("ログアウトすると、このデバイスのデータは削除されます。\n再度ログインすることでデータを復元できます。")
        }
    }
    
    // MARK: - Logic Helpers
    
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
                isPremium = !newValue
            }
        }
    }
    
    private func saveProfileChanges() {
        Task {
            do {
                try await authService.updateUserProfile(displayName: displayName)
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
                await fetchUserProfile()
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
                    try await authService.signInWithEmail(email: email, password: password)
                    alertMessage = "ログインしました。"
                } else {
                    try await authService.linkWithEmail(email: email, password: password)
                    if let uid = authService.currentUser?.uid {
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
                    alertMessage = "登録が完了しました。"
                }
                await fetchUserProfile()
                showingAlert = true
            } catch {
                errorMessage = error.localizedDescription
                // Simplified error translation
                if let err = error as NSError? {
                    if err.code == AuthErrorCode.emailAlreadyInUse.rawValue {
                        errorMessage = "このメールアドレスは既に使用されています。"
                    }
                }
            }
            isRegistering = false
        }
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

// MARK: - Components

struct CustomTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.gray)
                .frame(width: 24)
            TextField(placeholder, text: $text)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct CustomSecureField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.gray)
                .frame(width: 24)
            SecureField(placeholder, text: $text)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    NavigationView {
        AccountView()
    }
}
