//
//  LocationSearchSheet.swift
//  Routy
//
//  Created by 垣原親伍 on 2025/12/18.
//

import SwiftUI
import MapKit
import SwiftData

/// 場所検索シート
struct LocationSearchSheet: View {
    let trip: Trip
    @Binding var isPresented: Bool

    @Environment(\.modelContext) private var modelContext
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var selectedLocation: MKMapItem?
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var note = ""
    @State private var isSearching = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 検索バー
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("場所を検索", text: $searchText)
                        .textFieldStyle(.plain)
                        .submitLabel(.search)
                        .onSubmit {
                            searchLocation()
                        }
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            searchResults = []
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))

                // 地図
                Map(position: $cameraPosition) {
                    if let selected = selectedLocation {
                        Marker(selected.name ?? "選択した場所", coordinate: selected.placemark.coordinate)
                            .tint(.red)
                    }
                }
                .frame(height: 300)

                // 検索結果
                if !searchResults.isEmpty {
                    List(searchResults, id: \.self) { item in
                        Button(action: {
                            selectLocation(item)
                        }) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.name ?? "不明")
                                    .font(.headline)

                                if let address = item.placemark.title {
                                    Text(address)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                } else if selectedLocation != nil {
                    // 選択した場所の詳細
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(selectedLocation?.name ?? "選択した場所")
                                .font(.headline)

                            if let address = selectedLocation?.placemark.title {
                                Text(address)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

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

                        Button(action: saveCheckin) {
                            Text("チェックイン")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        Spacer()
                    }
                    .padding()
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("場所を検索してください")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationTitle("場所を検索")
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

    private func searchLocation() {
        isSearching = true
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText

        let search = MKLocalSearch(request: request)
        search.start { response, error in
            isSearching = false
            if let response = response {
                searchResults = response.mapItems
            }
        }
    }

    private func selectLocation(_ item: MKMapItem) {
        selectedLocation = item
        searchResults = []
        cameraPosition = .camera(
            MapCamera(
                centerCoordinate: item.placemark.coordinate,
                distance: 1000
            )
        )
    }

    private func saveCheckin() {
        guard let location = selectedLocation else { return }

        let checkpoint = Checkpoint(
            latitude: location.placemark.coordinate.latitude,
            longitude: location.placemark.coordinate.longitude,
            timestamp: Date(),
            type: .manualCheckin,
            note: note.isEmpty ? nil : note,
            address: location.placemark.title,
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

#Preview {
    LocationSearchSheet(
        trip: Trip(name: "テスト旅行", startDate: Date(), endDate: Date()),
        isPresented: .constant(true)
    )
    .modelContainer(for: [Trip.self, Checkpoint.self])
}
