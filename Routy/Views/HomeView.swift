//
//  HomeView.swift
//  Routy
//
//  Created by 垣原親伍 on 2025/12/18.
//

import SwiftUI
import SwiftData

/// ホーム画面
struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    // @QueryはTripListViewに移動したため削除
    
    @State private var searchText = ""
    @State private var showCreateTrip = false
    @State private var showCheckinSheet = false
    @State private var showJapanStats = false // 日本制覇マップ遷移用
    @State private var selectedTrip: Trip?

    var body: some View {
        NavigationStack {
            List {
                // ダッシュボード（クイックアクション）
                Section {
                    VStack(spacing: 12) {
                        // チェックインボタン（最優先）
                        Button(action: {
                            showCheckinSheet = true
                        }) {
                            HStack {
                                Spacer()
                                VStack(spacing: 4) {
                                    Image(systemName: "location.fill")
                                        .font(.system(size: 28))
                                    Text("今すぐチェックイン")
                                        .font(.headline)
                                    Text("現在地を記録")
                                        .font(.caption)
                                        .opacity(0.8)
                                }
                                .foregroundColor(.white)
                                .padding(.vertical, 16)
                                Spacer()
                            }
                            .background(Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(radius: 2, y: 2)
                        }
                        .buttonStyle(.plain)

                        HStack(spacing: 12) {
                            // マイマップボタン
                            NavigationLink(destination: GlobalMapView()) {
                                HStack {
                                    Spacer()
                                    VStack(spacing: 4) {
                                        Image(systemName: "map.fill")
                                            .font(.title3)
                                            .foregroundStyle(.purple)
                                        Text("マイマップ")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                    }
                                    .padding(.vertical, 12)
                                    Spacer()
                                }
                                .background(Color(.secondarySystemGroupedBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .shadow(radius: 1, y: 1)
                            }
                            .buttonStyle(.plain)

                            // 新しい旅ボタン
                            Button(action: {
                                showCreateTrip = true
                            }) {
                                HStack {
                                    Spacer()
                                    VStack(spacing: 4) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.title3)
                                            .foregroundStyle(.orange)
                                        Text("新しい旅")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                    }
                                    .padding(.vertical, 12)
                                    Spacer()
                                }
                                .background(Color(.secondarySystemGroupedBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .shadow(radius: 1, y: 1)
                            }
                            .buttonStyle(.plain)
                        }
                        
                        // 日本制覇マップボタン
                        Button(action: {
                            showJapanStats = true
                        }) {
                            HStack {
                                Spacer()
                                VStack(spacing: 4) {
                                    Image(systemName: "trophy.fill")
                                        .font(.title3)
                                        .foregroundStyle(.yellow)
                                    Text("日本制覇マップ")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                }
                                .padding(.vertical, 12)
                                Spacer()
                            }
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(radius: 1, y: 1)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 8)
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

                // 旅のリスト
                Section(header: Text("旅の記録")) {
                    TripListView(searchText: searchText)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("ホーム")
            .searchable(text: $searchText, prompt: "旅の名前で検索")
            .navigationDestination(for: Trip.self) { trip in
                TripDetailView(trip: trip)
            }
            .navigationDestination(isPresented: $showJapanStats) {
                JapanStatsView()
            }
            .sheet(isPresented: $showCreateTrip) {
                CreateTripSheet(isPresented: $showCreateTrip)
            }
            .sheet(isPresented: $showCheckinSheet) {
                CheckinSheet(trip: nil, isPresented: $showCheckinSheet)
            }
            .task {
                await SyncManager.shared.syncAll(modelContext: modelContext)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: AccountView()) {
                        Image(systemName: "person.crop.circle")
                            .font(.title2)
                    }
                }
            }
        }
    }

    private func deleteTrip(_ trip: Trip) {
        modelContext.delete(trip)
        try? modelContext.save()
    }
}

/// 検索対応の旅リスト
struct TripListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var trips: [Trip]
    
    init(searchText: String) {
        let sortDescriptors = [SortDescriptor(\Trip.startDate, order: .reverse)]
        
        if searchText.isEmpty {
            _trips = Query(sort: sortDescriptors)
        } else {
            _trips = Query(filter: #Predicate<Trip> {
                $0.name.localizedStandardContains(searchText)
            }, sort: sortDescriptors)
        }
    }
    
    var body: some View {
        if trips.isEmpty {
            ContentUnavailableView {
                Label("記録なし", systemImage: "airplane.departure")
            } description: {
                Text("一致する旅が見つかりません")
            }
        } else {
            ForEach(trips) { trip in
                NavigationLink(value: trip) {
                    TripRowView(trip: trip)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        deleteTrip(trip)
                    } label: {
                        Label("削除", systemImage: "trash")
                    }
                }
            }
        }
    }
    
    private func deleteTrip(_ trip: Trip) {
        modelContext.delete(trip)
        try? modelContext.save()
    }
}

/// Trip行表示
struct TripRowView: View {
    let trip: Trip

    var body: some View {
        HStack(spacing: 16) {
            // サムネイル
            if let firstCheckpoint = trip.checkpoints.first,
               let assetID = firstCheckpoint.photoAssetID {
                PhotoThumbnail(assetID: assetID, size: CGSize(width: 60, height: 60))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "map.fill")
                            .foregroundColor(.blue)
                    )
            }

            // 情報
            VStack(alignment: .leading, spacing: 4) {
                Text(trip.name)
                    .font(.headline)

                Text("\(DateFormatter.dateOnly.string(from: trip.startDate)) - \(DateFormatter.dateOnly.string(from: trip.endDate))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text("\(trip.checkpoints.count)箇所")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [Trip.self, Checkpoint.self])
}
