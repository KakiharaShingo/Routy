//
//  GlobalMapView.swift
//  Routy
//
//  Created by 垣原親伍 on 2025/12/18.
//

import SwiftUI
import MapKit
import SwiftData

/// 全てのチェックポイントを表示する地図画面
struct GlobalMapView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Checkpoint.timestamp, order: .reverse) private var allCheckpoints: [Checkpoint]
    
    @State private var viewModel: MapViewModel?
    @State private var showErrorAlert = false

    var body: some View {
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
        .navigationTitle("マイマップ")
        .navigationBarTitleDisplayMode(.inline)
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
            if viewModel == nil {
                viewModel = MapViewModel(modelContext: modelContext)
            }
            // 全てのチェックポイントをセット
            viewModel?.checkpoints = allCheckpoints
            viewModel?.centerMapOnCheckpoints()
        }
        .onChange(of: allCheckpoints) { _, newValue in
            // データ更新時に反映
            viewModel?.checkpoints = newValue
        }
    }
}

#Preview {
    GlobalMapView()
        .modelContainer(for: [Trip.self, Checkpoint.self])
}
