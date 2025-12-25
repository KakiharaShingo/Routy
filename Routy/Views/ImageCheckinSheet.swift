//
//  ImageCheckinSheet.swift
//  Routy
//
//  Created by 垣原親伍 on 2025/12/18.
//

import SwiftUI
import PhotosUI
import SwiftData

/// 画像選択チェックインシート
struct ImageCheckinSheet: View {
    let trip: Trip
    @Binding var isPresented: Bool

    @Environment(\.modelContext) private var modelContext
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var extractedLocation: (latitude: Double, longitude: Double)?
    @State private var address: String?
    @State private var note = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 画像選択エリア
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "photo.badge.plus")
                                .font(.system(size: 60))
                                .foregroundColor(.blue)

                            Text("写真を選択")
                                .font(.headline)
                                .foregroundColor(.blue)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 250)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .onChange(of: selectedItem) { _, newValue in
                    Task {
                        await loadImage(from: newValue)
                    }
                }

                if isLoading {
                    ProgressView("位置情報を取得中...")
                } else if let extractedLocation = extractedLocation {
                    // 位置情報表示
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "location.fill")
                                .foregroundColor(.green)
                            Text("位置情報を取得しました")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                        }

                        if let address = address {
                            Text(address)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("緯度: \(String(format: "%.6f", extractedLocation.latitude)), 経度: \(String(format: "%.6f", extractedLocation.longitude))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    // メモ入力
                    VStack(alignment: .leading, spacing: 8) {
                        Text("メモ（任意）")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        TextEditor(text: $note)
                            .frame(height: 80)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    // チェックインボタン
                    Button(action: saveCheckin) {
                        Text("チェックイン")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                } else if let errorMessage = errorMessage {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                }

                Spacer()
            }
            .padding()
            .navigationTitle("画像からチェックイン")
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

    private func loadImage(from item: PhotosPickerItem?) async {
        guard let item = item else { return }

        isLoading = true
        errorMessage = nil

        // 画像を読み込む
        if let data = try? await item.loadTransferable(type: Data.self),
           let image = UIImage(data: data) {
            await MainActor.run {
                selectedImage = image
            }
        }

        // PHAssetから位置情報を取得
        if let assetIdentifier = item.itemIdentifier {
            let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [assetIdentifier], options: nil)
            if let asset = fetchResult.firstObject {
                if let coordinate = await EXIFReader.extractLocation(from: asset) {
                    await MainActor.run {
                        extractedLocation = (coordinate.latitude, coordinate.longitude)
                    }

                    // 住所を取得
                    let geocoder = GeocodingService()
                    if let addr = await geocoder.getAddress(for: coordinate) {
                        await MainActor.run {
                            address = addr
                        }
                    }
                } else {
                    await MainActor.run {
                        errorMessage = "この写真には位置情報が含まれていません"
                    }
                }
            }
        }

        await MainActor.run {
            isLoading = false
        }
    }

    private func saveCheckin() {
        guard let location = extractedLocation else { return }

        let checkpoint = Checkpoint(
            latitude: location.latitude,
            longitude: location.longitude,
            timestamp: Date(),
            type: .photo,
            photoAssetID: selectedItem?.itemIdentifier,
            note: note.isEmpty ? nil : note,
            address: address,
            trip: trip
        )

        // カテゴリを自動判定（非同期）
        Task {
            let coordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
            await withCheckedContinuation { continuation in
                LocationCategoryDetector.shared.detectCategory(at: coordinate) { category in
                    checkpoint.category = category
                    continuation.resume()
                }
            }

            modelContext.insert(checkpoint)
            trip.checkpoints.append(checkpoint)

            do {
                try modelContext.save()
                await MainActor.run {
                    isPresented = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "保存に失敗しました: \(error.localizedDescription)"
                }
            }
        }
    }
}

#Preview {
    ImageCheckinSheet(
        trip: Trip(name: "テスト旅行", startDate: Date(), endDate: Date()),
        isPresented: .constant(true)
    )
    .modelContainer(for: [Trip.self, Checkpoint.self])
}
