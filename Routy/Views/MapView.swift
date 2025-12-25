//
//  MapView.swift
//  Routy
//
//  Created by 垣原親伍 on 2025/12/18.
//

import SwiftUI
import MapKit
import SwiftData

/// メイン地図画面
struct MapView: View {
    let trip: Trip?

    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: MapViewModel?

    @State private var showDateSelection = false
    @State private var showCheckinSheet = false
    @State private var showRouteAnimation = false
    @State private var showTimeline = false
    @State private var showErrorAlert = false

    init(trip: Trip? = nil) {
        print("DEBUG: MapView init with trip: \(trip?.name ?? "nil")")
        self.trip = trip
    }

    var body: some View {
        ZStack {
            if let viewModel = viewModel {
                mapContent(viewModel: viewModel)
                    
                    // ボトムバー
                    VStack {
                        Spacer()
                        HStack(spacing: 16) {
                            // tripがない場合のみ日付選択を表示（レガシーモード）
                            if trip == nil {
                                Button(action: {
                                    showDateSelection = true
                                }) {
                                    Label("日付選択", systemImage: "calendar")
                                        .font(.subheadline)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(.ultraThinMaterial)
                                        .clipShape(Capsule())
                                }
                            }

                            if !viewModel.checkpoints.isEmpty {
                                Button(action: {
                                    showRouteAnimation = true
                                }) {
                                    Label("経路再生", systemImage: "play.circle")
                                        .font(.subheadline)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(.ultraThinMaterial)
                                        .clipShape(Capsule())
                                }

                                Button(action: {
                                    showTimeline = true
                                }) {
                                    Label("タイムライン", systemImage: "list.bullet")
                                        .font(.subheadline)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(.ultraThinMaterial)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding()
                    }

                    // CalloutViewのオーバーレイ
                    if let selectedGroup = viewModel.selectedGroup {
                        GeometryReader { geometry in
                            CalloutView(group: selectedGroup)
                                .position(x: geometry.size.width / 2, y: geometry.size.height / 3)
                                .transition(.scale.combined(with: .opacity))
                                .id(selectedGroup.id)
                        }
                        .allowsHitTesting(true)
                        .zIndex(100)
                    }

                    // ローディング表示
                    if viewModel.isLoading {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()

                        ProgressView("読み込み中...")
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                } else {
                    ProgressView()
                }
            }

            .navigationTitle(trip?.name ?? "TravelLog")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // tripがない場合のみチェックインボタンを表示（レガシーモード）
                if trip == nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showCheckinSheet = true
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                        }
                    }
                }
            }
            .sheet(isPresented: $showDateSelection) {
                if let viewModel = viewModel {
                    DateSelectionSheet(isPresented: $showDateSelection) { startDate, endDate in
                        Task {
                            await viewModel.loadPhotos(startDate: startDate, endDate: endDate)
                        }
                    }
                }
            }
            .sheet(isPresented: $showCheckinSheet) {
                CheckinSheet(trip: trip, isPresented: $showCheckinSheet, onSave: { coordinate, note in
                    Task {
                        if let viewModel = viewModel {
                            await viewModel.addCheckin(coordinate: coordinate, note: note)
                        }
                    }
                })
            }
            .sheet(isPresented: $showRouteAnimation) {
                if let viewModel = viewModel {
                    RouteAnimationView(checkpoints: viewModel.checkpoints)
                }
            }
            .sheet(isPresented: $showTimeline) {
                NavigationStack {
                    if let trip = viewModel?.currentTrip {
                        TimelineView(trip: trip) { checkpoint in
                            // チェックポイントが含まれるグループを探して選択
                            if let group = viewModel?.groupedCheckpoints.first(where: { $0.checkpoints.contains(where: { $0.id == checkpoint.id }) }) {
                                viewModel?.selectGroup(group)
                            }
                        }
                    }
                }
            }
            .alert("エラー", isPresented: $showErrorAlert) {
                Button("OK") {
                    if let viewModel = viewModel {
                        viewModel.errorMessage = nil
                    }
                }
            } message: {
                if let errorMessage = viewModel?.errorMessage {
                    Text(errorMessage)
                }
            }
            .onChange(of: viewModel?.errorMessage) { _, newValue in
                showErrorAlert = newValue != nil
            }
            .onAppear {
                print("DEBUG: MapView onAppear")
                if viewModel == nil {
                    print("DEBUG: Initializing MapViewModel")
                    viewModel = MapViewModel(modelContext: modelContext)
                }
                if let trip = trip {
                    print("DEBUG: Setting trip to viewModel: \(trip.name)")
                    viewModel?.currentTrip = trip
                    viewModel?.checkpoints = trip.checkpoints
                    viewModel?.centerMapOnCheckpoints()
                }
            }
    }

    @ViewBuilder
    private func mapContent(viewModel: MapViewModel) -> some View {
        MapReader { proxy in
            let cameraBinding = Binding(
                get: { viewModel.cameraPosition },
                set: { viewModel.cameraPosition = $0 }
            )

            Map(position: cameraBinding) {
                ForEach(viewModel.groupedCheckpoints) { group in
                    Annotation("", coordinate: group.coordinate) {
                        annotationContent(for: group, viewModel: viewModel)
                    }
                }
            }
            .mapStyle(.standard)
            .onTapGesture {
                viewModel.selectedGroup = nil
            }
            .onChange(of: viewModel.selectedGroup) { _, newGroup in
                handleGroupSelection(newGroup: newGroup, proxy: proxy)
            }
        }
    }

    @ViewBuilder
    private func annotationContent(for group: MapViewModel.GroupedCheckpoint, viewModel: MapViewModel) -> some View {
        PinAnnotation(
            group: group,
            isSelected: viewModel.selectedGroup?.id == group.id
        )
        .onTapGesture {
            viewModel.selectGroup(group)
        }
    }

    private func handleGroupSelection(newGroup: MapViewModel.GroupedCheckpoint?, proxy: MapProxy) {
        if let group = newGroup {
            // MapProxyを使わずにviewModelのcameraPositionを更新
            if let viewModel = viewModel {
                withAnimation(.easeInOut(duration: 1.0)) {
                    viewModel.cameraPosition = .camera(
                        MapCamera(
                            centerCoordinate: group.coordinate,
                            distance: 500,
                            heading: 0,
                            pitch: 0
                        )
                    )
                }
            }
        }
    }
}

#Preview {
    MapView()
        .modelContainer(for: [Trip.self, Checkpoint.self])
}
