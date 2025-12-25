//
//  SettingsView.swift
//  Routy
//
//  設定画面
//

import SwiftUI
import SwiftData

/// 設定画面
struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var showExportSheet = false
    @State private var showImportSheet = false
    @State private var showDeleteConfirmation = false
    @State private var showAlert = false
    @State private var alertMessage = ""

    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    private let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

    var body: some View {
        List {
            // バックアップセクション
            Section {
                Button(action: {
                    showExportSheet = true
                }) {
                    Label("データをエクスポート", systemImage: "square.and.arrow.up")
                }

                Button(action: {
                    showImportSheet = true
                }) {
                    Label("データをインポート", systemImage: "square.and.arrow.down")
                }
            } header: {
                Text("バックアップ")
            } footer: {
                Text("旅行データをCSV形式でエクスポート・インポートできます")
            }

            // サポートセクション
            Section {
                NavigationLink(destination: PrivacyPolicyView()) {
                    Label("プライバシーポリシー", systemImage: "hand.raised")
                }

                NavigationLink(destination: TermsOfServiceView()) {
                    Label("利用規約", systemImage: "doc.text")
                }

                NavigationLink(destination: FAQView()) {
                    Label("よくある質問", systemImage: "questionmark.circle")
                }

                Link(destination: URL(string: "mailto:support@routy.app")!) {
                    Label("お問い合わせ", systemImage: "envelope")
                }
            } header: {
                Text("サポート")
            }

            // アプリ情報セクション
            Section {
                HStack {
                    Text("バージョン")
                    Spacer()
                    Text("\(appVersion) (\(buildNumber))")
                        .foregroundColor(.secondary)
                }

                Link(destination: URL(string: "https://apps.apple.com/app/idXXXXXXXXXX")!) {
                    Label("App Storeでレビュー", systemImage: "star")
                }

                Link(destination: URL(string: "https://twitter.com/routy_app")!) {
                    Label("公式Twitter", systemImage: "at")
                }
            } header: {
                Text("アプリ情報")
            }

            // デバッグセクション（DEBUGビルドのみ）
            #if DEBUG
            Section {
                Button(action: {
                    TestDataGenerator.createCategoryTestTrip(modelContext: modelContext)
                    alertMessage = "カテゴリーテストデータを作成しました"
                    showAlert = true
                }) {
                    Label("カテゴリーテストデータ作成", systemImage: "plus.circle")
                }

                Button(action: {
                    TestDataGenerator.createExtendedCategoryTestTrip(modelContext: modelContext)
                    alertMessage = "拡張テストデータを作成しました（20件）"
                    showAlert = true
                }) {
                    Label("拡張テストデータ作成（20件）", systemImage: "plus.circle.fill")
                }

                Button(action: {
                    TestPhotoGenerator.generateCategoryTestPhotos { result in
                        switch result {
                        case .success(let count):
                            alertMessage = "\(count)枚のテスト写真を生成しました"
                            showAlert = true
                        case .failure(let error):
                            alertMessage = "エラー: \(error.localizedDescription)"
                            showAlert = true
                        }
                    }
                }) {
                    Label("テスト写真を生成（9枚）", systemImage: "photo")
                }

                Button(action: {
                    TestPhotoGenerator.generateExtendedTestPhotos { result in
                        switch result {
                        case .success(let count):
                            alertMessage = "\(count)枚のテスト写真を生成しました"
                            showAlert = true
                        case .failure(let error):
                            alertMessage = "エラー: \(error.localizedDescription)"
                            showAlert = true
                        }
                    }
                }) {
                    Label("拡張テスト写真を生成（20枚）", systemImage: "photo.stack")
                }
            } header: {
                Text("デバッグ機能")
            }
            #endif

            // 危険な操作セクション
            Section {
                Button(role: .destructive, action: {
                    showDeleteConfirmation = true
                }) {
                    Label("全データを削除", systemImage: "trash")
                }
            } header: {
                Text("危険な操作")
            } footer: {
                Text("この操作は取り消せません。慎重に行ってください。")
            }
        }
        .navigationTitle("設定")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showExportSheet) {
            DataExportView()
        }
        .sheet(isPresented: $showImportSheet) {
            DataImportView()
        }
        .alert("確認", isPresented: $showDeleteConfirmation) {
            Button("キャンセル", role: .cancel) { }
            Button("削除", role: .destructive) {
                deleteAllData()
            }
        } message: {
            Text("本当に全てのデータを削除しますか？この操作は取り消せません。")
        }
        .alert("完了", isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }

    private func deleteAllData() {
        do {
            try modelContext.delete(model: Trip.self)
            try modelContext.delete(model: Checkpoint.self)
            try modelContext.save()
            alertMessage = "全てのデータを削除しました"
            showAlert = true
        } catch {
            alertMessage = "削除に失敗しました: \(error.localizedDescription)"
            showAlert = true
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .modelContainer(for: [Trip.self, Checkpoint.self])
    }
}
