//
//  HomeView.swift
//  Routy
//
//  Created by 垣原親伍 on 2025/12/18.
//

import SwiftUI
import SwiftData

/// ホーム画面 (Redesigned)
struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    
    // Navigation States
    @State private var searchText = ""
    @State private var showCreateTrip = false
    @State private var showCheckinSheet = false
    @State private var showJapanStats = false
    @State private var selectedTab: String = "home" // home, map, trips, profile
    
    // Data States
    @State private var conquestRate: Int = 0
    @State private var conquestCount: Int = 0
    
    // User Profile Stub
    private var userName: String {
        AuthService.shared.currentUser?.displayName ?? "ゲスト"
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // Background
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                // Main Content
                VStack(spacing: 0) {
                    if selectedTab == "home" {
                        HomeContent(
                            conquestRate: conquestRate,
                            conquestCount: conquestCount,
                            userName: userName,
                            showJapanStats: $showJapanStats,
                            showCreateTrip: $showCreateTrip,
                            selectedTab: $selectedTab
                        )
                        .padding(.bottom, 90) // Add padding for TabBar
                        .transition(.opacity)
                    } else if selectedTab == "map" {
                        GlobalMapView()
                            // Map extends to bottom, no padding needed for the view itself
                            .transition(.opacity)
                    } else if selectedTab == "trips" {
                        TripListContent(searchText: $searchText)
                            .padding(.bottom, 90) // Add padding for TabBar
                            .transition(.opacity)
                    } else if selectedTab == "profile" {
                        AccountView()
                            .padding(.bottom, 90) // Add padding for TabBar
                            .transition(.opacity)
                    }
                }
                // Removed global padding(.bottom, 90) to allow Map to extend fully
                
                // Custom Tab Bar
                CustomTabBar(selectedTab: $selectedTab, showCheckinSheet: $showCheckinSheet)
                    .zIndex(1) // Ensure it's above everything including Map
            }
            .navigationBarHidden(true)
            .ignoresSafeArea(.keyboard)
            .sheet(isPresented: $showCreateTrip) {
                CreateTripSheet(isPresented: $showCreateTrip)
            }
            .sheet(isPresented: $showCheckinSheet) {
                CheckinSheet(trip: nil, isPresented: $showCheckinSheet)
            }
            .navigationDestination(isPresented: $showJapanStats) {
                JapanStatsView()
            }
            .navigationDestination(for: Trip.self) { trip in
                TripDetailView(trip: trip)
            }
            .task {
                await loadStats()
                await SyncManager.shared.syncAll(modelContext: modelContext)
            }
        }
    }
    
    // Stats Loading Logic
    private func loadStats() async {
        guard let userId = AuthService.shared.currentUser?.uid else { return }
        do {
            if let profile = try await FirestoreService.shared.getUserProfile(userId: userId),
               let savedStats = profile["prefectureStats"] as? [String: Int] {
                // Count visited (level > 0)
                let visited = savedStats.values.filter { $0 > 0 }.count
                self.conquestCount = visited
                self.conquestRate = Int((Double(visited) / 47.0) * 100)
            }
        } catch {
            print("Failed to load stats: \(error)")
        }
    }
}

// MARK: - Subviews

struct HomeContent: View {
    let conquestRate: Int
    let conquestCount: Int
    let userName: String
    @Binding var showJapanStats: Bool
    @Binding var showCreateTrip: Bool
    @Binding var selectedTab: String
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Header
                HStack {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 44, height: 44)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(.white)
                            )
                            .overlay(
                                Circle().stroke(Color.white, lineWidth: 2)
                            )
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(userName)
                                .font(.system(size: 16, weight: .bold))
                            Text("Lv. \(conquestCount / 5 + 1) トラベラー")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.gray)
                        }
                    }
                    Spacer()
                    
                    // Settings Button stub (leads to Profile tab effectively)
                    Button(action: { selectedTab = "profile" }) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.gray)
                            .padding(8)
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                // Conquest Card
                Button(action: { showJapanStats = true }) {
                    ZStack {
                        Color(red: 28/255, green: 28/255, blue: 30/255)
                        
                        // Abstract Pattern
                        HStack {
                            Spacer()
                            Image(systemName: "map")
                                .font(.system(size: 160))
                                .foregroundColor(.white.opacity(0.05))
                                .rotationEffect(.degrees(12))
                                .offset(x: 40, y: -20)
                        }
                        
                        VStack(alignment: .leading, spacing: 0) {
                            Text("日本制覇率")
                                .font(.system(size: 10, weight: .bold))
                                .tracking(2)
                                .foregroundColor(.gray)
                                .padding(.bottom, 8)
                            
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text("\(conquestRate)%")
                                    .font(.system(size: 42, weight: .black))
                                    .foregroundColor(.white)
                                
                                Text("\(conquestCount) / 47 都道府県")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.gray)
                            }
                            .padding(.bottom, 16)
                            
                            // Progress Bar
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.white.opacity(0.1))
                                    
                                    Capsule()
                                        .fill(Color.orange)
                                        .frame(width: geo.size.width * (Double(conquestRate) / 100.0))
                                }
                            }
                            .frame(height: 8)
                            .padding(.bottom, 24)
                            
                            HStack(spacing: 6) {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.system(size: 12, weight: .bold))
                                Text("詳細を見る")
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Capsule())
                        }
                        .padding(24)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 32))
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
                
                // Quick Actions Grid
                HStack(spacing: 16) {
                    // New Trip
                    Button(action: { showCreateTrip = true }) {
                        VStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(Color.blue.opacity(0.1))
                                    .frame(width: 48, height: 48)
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.blue)
                            }
                            Text("新しい旅")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
                    }
                    
                    // My Map (Switch Tab)
                    Button(action: { selectedTab = "map" }) {
                        VStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(Color.purple.opacity(0.1))
                                    .frame(width: 48, height: 48)
                                Image(systemName: "map.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.purple)
                            }
                            Text("マイマップ")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
                    }
                }
                .padding(.horizontal, 24)
                
                // Recent Trips List
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("旅の記録")
                            .font(.system(size: 18, weight: .bold))
                        Spacer()
                        Button("すべて見る") { 
                            selectedTab = "trips"
                        }
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.orange)
                    }
                    .padding(.horizontal, 24)
                    
                    TripListContent(searchText: .constant(""), limit: 3, isScrollable: false)
                        .padding(.horizontal, 24)
                }
                
                Spacer(minLength: 40)
            }
            .padding(.top, 8)
        }
    }
}

struct TripListContent: View {
    @Binding var searchText: String
    var limit: Int? = nil
    var isScrollable: Bool = true
    
    @Environment(\.modelContext) private var modelContext
    @Query private var trips: [Trip]
    
    init(searchText: Binding<String>, limit: Int? = nil, isScrollable: Bool = true) {
        self._searchText = searchText
        self.limit = limit
        self.isScrollable = isScrollable
        
        let sortDescriptors = [SortDescriptor(\Trip.startDate, order: .reverse)]
        _trips = Query(sort: sortDescriptors) 
    }
    
    var filteredTrips: [Trip] {
        let all = trips
        let filtered = searchText.isEmpty ? all : all.filter { $0.name.localizedStandardContains(searchText) }
        if let limit = limit {
            return Array(filtered.prefix(limit))
        }
        return filtered
    }
    
    var body: some View {
        if isScrollable {
            ScrollView {
                LazyVStack(spacing: 16) {
                    listContent
                }
                .padding(24)
            }
        } else {
            VStack(spacing: 16) {
                listContent
            }
        }
    }
    
    var listContent: some View {
        Group {
            // Empty State Check
            if trips.isEmpty && limit == nil {
                 VStack(spacing: 20) {
                     Image(systemName: "airplane.departure")
                         .font(.system(size: 50))
                         .foregroundColor(.gray.opacity(0.5))
                     Text("旅の記録がまだありません")
                         .font(.subheadline)
                         .foregroundColor(.gray)
                 }
                 .frame(maxWidth: .infinity)
                 .padding(.top, 40)
            } else {
                ForEach(filteredTrips, id: \.persistentModelID) { trip in
                    NavigationLink(value: trip) {
                        TripCardView(trip: trip)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct TripCardView: View {
    let trip: Trip
    
    var body: some View {
        HStack(spacing: 16) {
            // Thumbnail
            if let firstCheckpoint = trip.checkpoints.first,
               let assetID = firstCheckpoint.photoAssetID {
                PhotoThumbnail(assetID: assetID, size: CGSize(width: 64, height: 64))
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 64, height: 64)
                    .overlay(
                        Image(systemName: "map")
                            .foregroundColor(.blue)
                    )
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(trip.name)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text("\(DateFormatter.dateOnly.string(from: trip.startDate))")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Stats
            VStack(alignment: .trailing, spacing: 0) {
                Text("\(trip.checkpoints.count)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
                Text("スポット")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.gray)
            }
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color(.systemGray4))
        }
        .padding(12)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: String
    @Binding var showCheckinSheet: Bool
    
    var body: some View {
        ZStack(alignment: .top) {
            // Bar Background
            Rectangle()
                .fill(Color(UIColor.secondarySystemGroupedBackground).opacity(0.9))
                .frame(height: 80)
                .background(.ultraThinMaterial)
                .mask(
                    CustomTabShape()
                )
                .shadow(color: .black.opacity(0.05), radius: 10, y: -5)
            
            HStack(spacing: 0) {
                // Left Tabs
                TabBarButton(icon: "trophy", label: "制覇", isSelected: selectedTab == "home") {
                    selectedTab = "home"
                }
                .frame(maxWidth: .infinity)
                
                TabBarButton(icon: "map", label: "マップ", isSelected: selectedTab == "map") {
                    selectedTab = "map"
                }
                .frame(maxWidth: .infinity)
                
                // Center Space for FAB
                Spacer().frame(width: 80)
                
                // Right Tabs
                TabBarButton(icon: "list.bullet.rectangle", label: "旅ログ", isSelected: selectedTab == "trips") {
                    selectedTab = "trips"
                }
                .frame(maxWidth: .infinity)
                
                TabBarButton(icon: "gearshape", label: "設定", isSelected: selectedTab == "profile") {
                    selectedTab = "profile"
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.top, 12)
            .padding(.horizontal, 16)
            
            // Floating Action Button
            Button(action: { showCheckinSheet = true }) {
                ZStack {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 64, height: 64)
                        .shadow(color: .orange.opacity(0.4), radius: 10, y: 5)
                    Image(systemName: "plus")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .offset(y: -32)
            
            // Label for FAB
            Text("チェックイン")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.orange)
                .offset(y: 38)
        }
        .frame(maxHeight: 80)
    }
}

struct TabBarButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: isSelected ? icon + ".fill" : icon)
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? .orange : .gray)
                Text(label)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(isSelected ? .orange : .gray)
            }
        }
    }
}

struct CustomTabShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        return path
    }
}
