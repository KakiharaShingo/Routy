//
//  MultiPhotoCheckinSheet.swift
//  Routy
//
//  複数写真選択チェックインシート
//

import SwiftUI
import PhotosUI
import SwiftData
import CoreLocation
import Photos

/// 複数写真選択チェックインシート
struct MultiPhotoCheckinSheet: View {
    let trip: Trip
    @Binding var isPresented: Bool

    @Environment(\.modelContext) private var modelContext
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var isProcessing = false
    @State private var processedCount = 0
    @State private var totalCount = 0
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                if selectedItems.isEmpty {
                    // 写真未選択状態
                    VStack(spacing: 16) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 80))
                            .foregroundColor(.purple.opacity(0.7))

                        Text("写真を選択してください")
                            .font(.headline)

                        Text("複数の写真を選択できます")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        PhotosPicker(selection: $selectedItems, maxSelectionCount: 50, matching: .images) {
                            Text("写真を選択")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.purple)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal, 40)
                    }
                } else if isProcessing {
                    // 処理中
                    VStack(spacing: 20) {
                        ProgressView(value: Double(processedCount), total: Double(totalCount))
                            .progressViewStyle(.linear)
                            .frame(width: 200)

                        Text("写真を追加中...")
                            .font(.headline)

                        Text("\(processedCount) / \(totalCount)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    // 写真選択完了
                    VStack(spacing: 16) {
                        Image(systemName: "photo.stack.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.purple)

                        Text("\(selectedItems.count)枚の写真を選択しました")
                            .font(.headline)

                        Text("位置情報が含まれる写真のみが追加されます")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)

                        HStack(spacing: 12) {
                            Button("再選択") {
                                selectedItems.removeAll()
                            }
                            .buttonStyle(.bordered)

                            Button("追加") {
                                Task {
                                    await processPhotos()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.purple)
                        }
                        .padding(.top)
                    }
                    .padding()
                }

                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                }

                Spacer()
            }
            .padding()
            .navigationTitle("写真から追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        isPresented = false
                    }
                }
            }
        }
    }

    private func processPhotos() async {
        print("🔍 MultiPhotoCheckinSheet.processPhotos() 実行開始")
        isProcessing = true
        totalCount = selectedItems.count
        processedCount = 0
        errorMessage = nil
        print("🔍 処理対象の写真数: \(totalCount)")

        var addedCount = 0

        for item in selectedItems {
            // 写真のAsset IDを取得
            guard let assetID = item.itemIdentifier else {
                processedCount += 1
                continue
            }

            // EXIFから位置情報を取得
            guard let location = await extractLocation(from: item) else {
                processedCount += 1
                continue
            }

            // 住所を取得
            let address = await GeocodingService().getAddress(for: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude))

            // Checkpointを作成
            let checkpoint = Checkpoint(
                latitude: location.latitude,
                longitude: location.longitude,
                timestamp: Date(),
                type: .photo,
                photoAssetID: assetID,
                address: address,
                trip: trip
            )

            // カテゴリを自動判定
            let coordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
            await withCheckedContinuation { continuation in
                LocationCategoryDetector.shared.detectCategory(at: coordinate) { category in
                    checkpoint.category = category
                    if let category = category {
                        print("✅ カテゴリー判定成功: \(category.displayName) at \(coordinate)")
                    } else {
                        print("⚠️ カテゴリー判定失敗 at \(coordinate)")
                    }
                    continuation.resume()
                }
            }

            modelContext.insert(checkpoint)
            trip.checkpoints.append(checkpoint)
            addedCount += 1

            processedCount += 1
        }

        do {
            try modelContext.save()
            await MainActor.run {
                isPresented = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "保存に失敗しました: \(error.localizedDescription)"
                isProcessing = false
            }
        }
    }

    private func extractLocation(from item: PhotosPickerItem) async -> (latitude: Double, longitude: Double)? {
        // PhotosPickerItemからPHAssetを取得
        guard let assetID = item.itemIdentifier else {
            return nil
        }

        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [assetID], options: nil)
        guard let asset = fetchResult.firstObject else {
            return nil
        }

        // EXIFから位置情報を取得
        guard let coordinate = await EXIFReader.extractLocation(from: asset) else {
            return nil
        }

        return (latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
}

#Preview {
    MultiPhotoCheckinSheet(
        trip: Trip(name: "テスト旅行", startDate: Date(), endDate: Date()),
        isPresented: .constant(true)
    )
    .modelContainer(for: [Trip.self, Checkpoint.self])
}
