//
//  TripDetailView.swift
//  Routy
//
//  Created by 垣原親伍 on 2025/12/18.
//

import SwiftUI
import SwiftData

/// Trip詳細画面（メニュー形式）
struct TripDetailView: View {
    let trip: Trip

    @State private var showAddPhotos = false
    @State private var showManualCheckin = false
    @State private var showLocationSearch = false
    @State private var showImageCheckin = false

    var body: some View {
        List {
            // 旅行情報セクション
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(trip.name)
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("\(DateFormatter.dateOnly.string(from: trip.startDate)) - \(DateFormatter.dateOnly.string(from: trip.endDate))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Text("\(trip.checkpoints.count)箇所記録済み")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 8)
            }

            // 閲覧メニュー
            Section(header: Text("閲覧")) {
                NavigationLink {
                    MapView(trip: trip)
                    // Text("Map Test View")
                    //    .onAppear { print("DEBUG: Map Test View Appeared") }
                } label: {
                    MenuRowView(
                        icon: "map.fill",
                        title: "地図で見る",
                        description: "すべてのチェックポイントを地図上に表示",
                        color: .blue
                    )
                }

                NavigationLink {
                    TimelineView(trip: trip, onCheckpointTap: { _ in })
                } label: {
                    MenuRowView(
                        icon: "list.bullet",
                        title: "タイムライン",
                        description: "時系列で記録を確認",
                        color: .green
                    )
                }

                NavigationLink {
                    RouteAnimationView(checkpoints: trip.checkpoints)
                } label: {
                    MenuRowView(
                        icon: "play.circle.fill",
                        title: "経路再生",
                        description: "旅のルートをアニメーションで再生",
                        color: .orange
                    )
                }
            }

            // チェックイン追加メニュー
            Section(header: Text("記録を追加")) {
                Button(action: {
                    showAddPhotos = true
                }) {
                    MenuRowView(
                        icon: "photo.on.rectangle",
                        title: "写真から追加",
                        description: "カメラロールの写真から位置情報を取得",
                        color: .purple
                    )
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAddPhotos) {
            AddPhotosSheet(trip: trip, isPresented: $showAddPhotos)
        }
        .sheet(isPresented: $showManualCheckin) {
            CheckinSheet(trip: trip, isPresented: $showManualCheckin, mode: .currentLocation)
        }
        .sheet(isPresented: $showLocationSearch) {
            LocationSearchSheet(trip: trip, isPresented: $showLocationSearch)
        }
        .sheet(isPresented: $showImageCheckin) {
            ImageCheckinSheet(trip: trip, isPresented: $showImageCheckin)
        }
    }
}

/// メニュー行表示コンポーネント
struct MenuRowView: View {
    let icon: String
    let title: String
    let description: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        TripDetailView(
            trip: Trip(
                name: "大阪・京都旅行",
                startDate: Date(),
                endDate: Date()
            )
        )
    }
    .modelContainer(for: [Trip.self, Checkpoint.self])
}
