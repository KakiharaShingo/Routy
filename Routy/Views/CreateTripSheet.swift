//
//  CreateTripSheet.swift
//  Routy
//
//  Created by 垣原親伍 on 2025/12/18.
//

import SwiftUI
import SwiftData

/// 新しいTrip作成シート
struct CreateTripSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Binding var isPresented: Bool

    @State private var tripName = ""
    @State private var startDate = Date().addingTimeInterval(-7 * 24 * 60 * 60)
    @State private var endDate = Date()
    @State private var creationMethod: CreationMethod = .fromPhotos

    enum CreationMethod {
        case fromPhotos
        case manual
    }

    private let photoService = PhotoService()
    private let geocodingService = GeocodingService()

    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("旅行情報")) {
                    TextField("旅行名", text: $tripName)
                        .autocorrectionDisabled()

                    DatePicker("開始日", selection: $startDate, in: ...Date(), displayedComponents: .date)
                    DatePicker("終了日", selection: $endDate, in: startDate...Date(), displayedComponents: .date)
                }

                Section(header: Text("作成方法")) {
                    Picker("作成方法", selection: $creationMethod) {
                        Label("写真から自動作成", systemImage: "photo.on.rectangle")
                            .tag(CreationMethod.fromPhotos)
                        Label("手動で作成", systemImage: "hand.tap")
                            .tag(CreationMethod.manual)
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    Button(action: {
                        Task {
                            await createTrip()
                        }
                    }) {
                        if isLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                        } else {
                            HStack {
                                Spacer()
                                Text(creationMethod == .fromPhotos ? "写真を読込んで作成" : "作成")
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                        }
                    }
                    .disabled(tripName.isEmpty || isLoading)
                }
            }
            .navigationTitle("新しい旅")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        isPresented = false
                    }
                    .disabled(isLoading)
                }
            }
            .alert("エラー", isPresented: $showError) {
                Button("OK") { errorMessage = nil }
            } message: {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }

    @MainActor
    private func createTrip() async {
        isLoading = true
        errorMessage = nil

        let defaultName = tripName.isEmpty ? "旅行 \(DateFormatter.dateOnly.string(from: startDate))" : tripName

        var checkpoints: [Checkpoint] = []

        if creationMethod == .fromPhotos {
            // 写真から作成
            let hasAccess = await photoService.requestPhotoLibraryAccess()
            guard hasAccess else {
                errorMessage = "写真ライブラリへのアクセスが許可されていません"
                showError = true
                isLoading = false
                return
            }

            let assets = await photoService.fetchPhotos(from: startDate, to: endDate)
            if assets.isEmpty {
                errorMessage = "指定期間内に位置情報付きの写真が見つかりませんでした"
                showError = true
                isLoading = false
                return
            }

            checkpoints = await photoService.extractCheckpoints(from: assets)
            
            // 住所取得 (オプション: 時間がかかるので非同期でやるか、ここではスキップするか)
            // ここではユーザー体験のため、まずは保存を優先し、あとで詳細を開いたときに住所取得などを検討
            // 今回はとりあえずそのまま保存
        }

        let trip = Trip(
            name: defaultName,
            startDate: startDate,
            endDate: endDate,
            checkpoints: checkpoints
        )

        modelContext.insert(trip)
        
        // Relationship設定
        for checkpoint in checkpoints {
            checkpoint.trip = trip
        }

        do {
            // 同期フラグの設定
            trip.markNeedsSync()
            for checkpoint in checkpoints {
                checkpoint.markNeedsSync()
            }
            
            try modelContext.save()
            
            // クラウドへの同期開始
            Task {
                await SyncManager.shared.syncAll(modelContext: modelContext)
            }
            
            isPresented = false
        } catch {
            errorMessage = "保存に失敗しました: \(error.localizedDescription)"
            showError = true
        }

        isLoading = false
    }
}

#Preview {
    CreateTripSheet(isPresented: .constant(true))
        .modelContainer(for: [Trip.self, Checkpoint.self])
}
