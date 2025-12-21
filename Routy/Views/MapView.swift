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
        // NavigationStack { // Removed nested NavigationStack
            ZStack {
                if let viewModel = viewModel {
                    // 地図
                    Map(position: Binding(
                        get: { viewModel.cameraPosition },
                        set: { viewModel.cameraPosition = $0 }
                    )) {
                        ForEach(viewModel.checkpoints) { checkpoint in
                            Annotation("", coordinate: checkpoint.coordinate()) {
                                PinAnnotation(
                                    checkpoint: checkpoint,
                                    isSelected: viewModel.selectedCheckpoint?.id == checkpoint.id
                                )
                                .onTapGesture {
                                    viewModel.selectCheckpoint(checkpoint)
                                }
                            }
                        }
                    }
                    .mapStyle(.standard)

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
                
                // MARK: - Photo Popup Overlay
                if let viewModel = viewModel, let cp = viewModel.selectedCheckpoint {
                    ZStack {
                        Color.black.opacity(0.4)
                            .edgesIgnoringSafeArea(.all)
                            .onTapGesture {
                                withAnimation {
                                    viewModel.selectedCheckpoint = nil
                                }
                            }
                        
                        VStack(spacing: 12) {
                            if let assetID = cp.photoAssetID {
                                PhotoAssetView(assetID: assetID)
                                    .frame(width: 250, height: 250)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .shadow(radius: 10)
                            } else if let url = cp.photoURL, let imageURL = URL(string: url) {
                                AsyncImage(url: imageURL) { image in
                                    image.resizable().scaledToFill()
                                } placeholder: {
                                    ProgressView()
                                }
                                .frame(width: 250, height: 250)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            } else {
                                Image(systemName: "photo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 100, height: 100)
                                    .foregroundColor(.gray)
                                    .frame(width: 250, height: 250)
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            
                            Text(cp.name ?? "Checkpoint")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Material.ultraThin)
                                .cornerRadius(8)
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                    .zIndex(100)
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
                            viewModel?.selectCheckpoint(checkpoint)
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
}

#Preview {
    MapView()
        .modelContainer(for: [Trip.self, Checkpoint.self])
}
