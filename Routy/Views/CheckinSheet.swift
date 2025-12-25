//
//  CheckinSheet.swift
//  Routy
//
//  Created by 垣原親伍 on 2025/12/18.
//

import SwiftUI
import CoreLocation
import SwiftData
import MapKit

import PhotosUI

/// チェックイン追加シート
struct CheckinSheet: View {
    let trip: Trip?
    @Binding var isPresented: Bool
    let mode: CheckinMode
    let onSave: ((CLLocationCoordinate2D, String?) -> Void)?

    enum CheckinMode {
        case currentLocation
        case manual
    }

    @Environment(\.modelContext) private var modelContext
    @StateObject private var locationService = LocationService()
    @StateObject private var searchService = LocationSearchService()
    
    @State private var note: String = ""
    @State private var isLoadingLocation = true
    @State private var currentAddress: String = "取得中..."
    @State private var locationName: String? // チェックイン場所の名前（POI名など）
    @State private var showPermissionAlert = false
    @State private var showSuccessMessage = false // 完了メッセージ表示フラグ
    
    // Photo selection
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var selectedAssetID: String?
    
    // Map control
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var showSearchSheet = false // 検索シート表示用

    init(trip: Trip? = nil, isPresented: Binding<Bool>, mode: CheckinMode = .currentLocation, onSave: ((CLLocationCoordinate2D, String?) -> Void)? = nil) {
        self.trip = trip
        self._isPresented = isPresented
        self.mode = mode
        self.onSave = onSave
    }

    var body: some View {
        NavigationView {
            Form {
                // マップ＆場所セクション
                Section(header: Text("場所")) {
                    ZStack(alignment: .bottomTrailing) {
                        Map(coordinateRegion: $region, showsUserLocation: true, annotationItems: getAnnotations()) { item in
                            MapMarker(coordinate: item.coordinate, tint: .red)
                        }
                        .frame(height: 200)
                        .cornerRadius(8)
                        .onChange(of: region.center.latitude) { _ in
                            searchService.setRegion(region)
                        }
                        
                        // 現在地に戻るボタン
                        Button(action: {
                            Task { await loadCurrentLocation() }
                        }) {
                            Image(systemName: "location.fill")
                                .padding(8)
                                .background(Color(UIColor.secondarySystemGroupedBackground))
                                .clipShape(Circle())
                                .shadow(radius: 2)
                        }
                        .padding(8)
                    }
                    
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading) {
                            if let name = locationName {
                                Text(name)
                                    .font(.headline)
                                Text(currentAddress)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Text(currentAddress)
                                    .foregroundColor(isLoadingLocation ? .gray : .primary)
                            }
                        }
                        Spacer()
                    }
                    
                    // 検索バー（のようなボタン）
                    Button(action: { showSearchSheet = true }) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                            Text("場所を検索・変更")
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }

                // Photo Section
                Section(header: Text("写真")) {
                    if let image = selectedImage {
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 200)
                                .frame(maxWidth: .infinity)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            
                            Button(action: {
                                selectedImage = nil
                                selectedPhotoItem = nil
                                selectedAssetID = nil
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title)
                                    .foregroundColor(.white)
                                    .shadow(radius: 2)
                            }
                            .padding(8)
                        }
                    } else {
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images, photoLibrary: .shared()) {
                            HStack {
                                Image(systemName: "photo")
                                Text("写真を選択")
                                Spacer()
                            }
                        }
                        .onChange(of: selectedPhotoItem) { newItem in
                            Task {
                                if let item = newItem {
                                    if let data = try? await item.loadTransferable(type: Data.self),
                                       let image = UIImage(data: data) {
                                        selectedImage = image
                                        // itemIdentifier is the local identifier (asset ID)
                                        selectedAssetID = item.itemIdentifier
                                    }
                                }
                            }
                        }
                    }
                }

                Section(header: Text("メモ")) {
                    TextEditor(text: $note)
                        .frame(height: 100)
                }

                Section {
                    Button(action: saveCheckin) {
                        HStack {
                            Spacer()
                            Text("保存")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(isLoadingLocation && selectedCoordinate == nil)
                }
            }
            .navigationTitle("チェックイン")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        isPresented = false
                    }
                }
            }
            .task {
                await loadCurrentLocation()
            }
            .sheet(isPresented: $showSearchSheet) {
                LocationSearchSheet(searchService: searchService) { result in
                    selectLocation(result)
                }
            }
            .alert("位置情報へのアクセスが許可されていません", isPresented: $showPermissionAlert) {
                Button("OK", role: .cancel) { }
            }
        }
        .overlay {
            if showSuccessMessage {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                            .symbolEffect(.bounce, value: showSuccessMessage)
                        
                        Text("チェックイン完了")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .padding(40)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(radius: 10)
                }
                .transition(.opacity)
                .zIndex(100)
            }
        }
    }
    
    private func getAnnotations() -> [SingleAnnotation] {
        if let coord = selectedCoordinate {
            return [SingleAnnotation(coordinate: coord)]
        }
        return []
    }
    
    struct SingleAnnotation: Identifiable {
        let id = UUID()
        let coordinate: CLLocationCoordinate2D
    }

    private func loadCurrentLocation() async {
        isLoadingLocation = true

        guard let coordinate = await locationService.getCurrentLocation() else {
            showPermissionAlert = true
            isLoadingLocation = false
            return
        }
        
        // 座標更新
        selectedCoordinate = coordinate
        region.center = coordinate
        searchService.setRegion(region)

        // 住所と場所名を取得
        // まず住所（県・市など）
        let geocoder = GeocodingService()
        let info = await geocoder.getLocationInfo(for: coordinate)
        
        // 次にPOI名（駅名・店名など）をMapKit検索で試みる
        // Geocoderよりもこちらの方が正確な施設名を返すことが多い
        let poiName = await searchService.lookupPOI(at: coordinate)
        
        if let address = info.address {
            currentAddress = address
            
            // 名前決定ロジック:
            // 1. MapKitのPOI名があればそれを最優先（例：「泉中央駅」）
            // 2. なければGeocoderのname（例：「泉中央」）
            // 3. なければnil
            locationName = poiName ?? info.name
            
        } else {
            currentAddress = "不明な場所"
            locationName = poiName // 住所不明でもPOIだけ取れる場合もある
        }

        isLoadingLocation = false
    }
    
    // 検索結果から場所を選択
    private func selectLocation(_ result: LocationSearchResult) {
        selectedCoordinate = result.coordinate
        region.center = result.coordinate
        locationName = result.title
        currentAddress = result.subtitle.isEmpty ? result.title : result.subtitle
        
        showSearchSheet = false
    }

    private func saveCheckin() {
        guard let coordinate = selectedCoordinate else { return }

        // onSaveコールバックがある場合はそれを使用（後方互換性）
        if let onSave = onSave {
            onSave(coordinate, note.isEmpty ? nil : note)
            isPresented = false
            return
        }

        // Checkpointを作成
        let checkpoint = Checkpoint(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            timestamp: Date(),
            type: .manualCheckin,
            photoAssetID: selectedAssetID,
            name: locationName,
            note: note.isEmpty ? nil : note,
            address: currentAddress != "取得中..." ? currentAddress : nil,
            trip: trip
        )

        // カテゴリを自動判定（非同期）
        Task {
            await withCheckedContinuation { continuation in
                LocationCategoryDetector.shared.detectCategory(at: coordinate) { category in
                    checkpoint.category = category
                    continuation.resume()
                }
            }

            // 同期のためにフラグを立てる
            checkpoint.markNeedsSync()

            modelContext.insert(checkpoint)

            if let trip = trip {
                trip.checkpoints.append(checkpoint)
            }

            do {
                try modelContext.save()

                await MainActor.run {
                    // 完了メッセージを表示して少し待ってから閉じる
                    withAnimation {
                        showSuccessMessage = true
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        isPresented = false
                    }
                }
            } catch {
                print("保存エラー: \(error)")
            }
        }
    }
}



#Preview {
    CheckinSheet(trip: nil, isPresented: .constant(true)) { _, _ in }
        .modelContainer(for: [Trip.self, Checkpoint.self])
}
