//
//  TripDetailView.swift
//  Routy
//
//  Created by 垣原親伍 on 2025/12/18.
//

import SwiftUI
import SwiftData

/// Trip詳細画面（Redesigned）
struct TripDetailView: View {
    let trip: Trip

    @State private var showAddPhotos = false
    @State private var showManualCheckin = false
    @State private var showLocationSearch = false
    @State private var showImageCheckin = false
    
    // Environment
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // Background
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header Card
                    TripHeaderCard(trip: trip)
                    
                    // Actions Grid
                    VStack(alignment: .leading, spacing: 16) {
                        Text("メニュー")
                            .font(.headline)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 4)
                        
                        // Viewing Options
                        VStack(spacing: 12) {
                            NavigationLink(destination: MapView(trip: trip)) {
                                ActionCard(icon: "map.fill", title: "地図で見る", subtitle: "思い出を地図上に表示", color: .blue)
                            }
                            .buttonStyle(.plain)
                            
                            NavigationLink(destination: TimelineView(trip: trip, onCheckpointTap: { _ in })) {
                                ActionCard(icon: "list.bullet", title: "タイムライン", subtitle: "時系列で振り返る", color: .green)
                            }
                            .buttonStyle(.plain)
                            
                            NavigationLink(destination: RouteAnimationView(checkpoints: trip.checkpoints)) {
                                ActionCard(icon: "play.circle.fill", title: "経路再生", subtitle: "旅の軌跡をアニメーション再生", color: .orange)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Add Content
                    VStack(alignment: .leading, spacing: 16) {
                        Text("記録を追加")
                            .font(.headline)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 4)
                        
                        Button(action: { showAddPhotos = true }) {
                            ActionCard(icon: "photo.on.rectangle", title: "写真から追加", subtitle: "カメラロールからまとめて追加", color: .purple)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 40)
                }
                .padding(.top, 20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
//        .navigationTitle(trip.name) // Optional: Hide title for cleaner look? Keeping it for navigation context.
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

// MARK: - Subviews

struct TripHeaderCard: View {
    let trip: Trip
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title & Date
            VStack(alignment: .leading, spacing: 6) {
                Text(trip.name)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.gray)
                    Text("\(DateFormatter.dateOnly.string(from: trip.startDate)) - \(DateFormatter.dateOnly.string(from: trip.endDate))")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            
            Divider()
            
            // Stats Row
            HStack(spacing: 40) {
                VStack(alignment: .leading) {
                    Text("\(trip.checkpoints.count)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                    Text("スポット")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                }
                
                // Future stats can go here (e.g. Distance)
                
                Spacer()
                
                // Cover Image (Small thumbnail if available)
                if let first = trip.checkpoints.first, let assetID = first.photoAssetID {
                     PhotoThumbnail(assetID: assetID, size: CGSize(width: 60, height: 60))
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding(24)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 20)
    }
}

struct ActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(color.opacity(0.1))
                    .frame(width: 56, height: 56)
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(Color(.systemGray4))
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
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
