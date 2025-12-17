//
//  CheckinSheet.swift
//  Routy
//
//  Created by 垣原親伍 on 2025/12/18.
//

import SwiftUI
import CoreLocation
import SwiftData

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
    @State private var note: String = ""
    @State private var isLoadingLocation = true
    @State private var currentAddress: String = "取得中..."
    @State private var showPermissionAlert = false

    init(trip: Trip? = nil, isPresented: Binding<Bool>, mode: CheckinMode = .currentLocation, onSave: ((CLLocationCoordinate2D, String?) -> Void)? = nil) {
        self.trip = trip
        self._isPresented = isPresented
        self.mode = mode
        self.onSave = onSave
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("現在地")) {
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.blue)
                        Text(currentAddress)
                            .foregroundColor(isLoadingLocation ? .gray : .primary)
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
                    .disabled(locationService.currentLocation == nil)
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
            .alert("位置情報へのアクセスが許可されていません", isPresented: $showPermissionAlert) {
                Button("OK") {
                    isPresented = false
                }
            }
        }
    }

    private func loadCurrentLocation() async {
        isLoadingLocation = true

        guard let coordinate = await locationService.getCurrentLocation() else {
            showPermissionAlert = true
            isLoadingLocation = false
            return
        }

        // 住所を取得
        let geocoder = GeocodingService()
        if let address = await geocoder.getAddress(for: coordinate) {
            currentAddress = address
        } else {
            currentAddress = "不明な場所"
        }

        isLoadingLocation = false
    }

    private func saveCheckin() {
        guard let coordinate = locationService.currentLocation else { return }

        // onSaveコールバックがある場合はそれを使用（後方互換性）
        if let onSave = onSave {
            onSave(coordinate, note.isEmpty ? nil : note)
            isPresented = false
            return
        }

        // Tripに直接保存
        if let trip = trip {
            let checkpoint = Checkpoint(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                timestamp: Date(),
                type: .manualCheckin,
                note: note.isEmpty ? nil : note,
                address: currentAddress != "取得中..." ? currentAddress : nil,
                trip: trip
            )

            modelContext.insert(checkpoint)
            trip.checkpoints.append(checkpoint)

            do {
                try modelContext.save()
                isPresented = false
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
