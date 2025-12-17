//
//  RouteAnimationView.swift
//  Routy
//
//  Created by 垣原親伍 on 2025/12/18.
//

import SwiftUI
import MapKit

/// 経路アニメーション画面
struct RouteAnimationView: View {
    let checkpoints: [Checkpoint]
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: RouteAnimationViewModel
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var cameraDistance: Double = 2000.0

    init(checkpoints: [Checkpoint]) {
        self.checkpoints = checkpoints
        _viewModel = State(initialValue: RouteAnimationViewModel(checkpoints: checkpoints))
    }

    var body: some View {
        ZStack {
            // 地図
            Map(position: $cameraPosition) {
                // 全体の経路（薄く表示）
                MapPolyline(coordinates: viewModel.routeCoordinates)
                    .stroke(.gray.opacity(0.5), lineWidth: 3)
                
                // 通過済みの経路（濃く表示） + 現在のセグメント
                if !viewModel.routeCoordinates.isEmpty, let currentPos = viewModel.currentCoordinate {
                    // 線形補間を使っているため「通過済みのポイント」は描画せず、
                    // シンプルに「全行程薄いグレー」の上に「現在地ポインタ」だけにします。
                }

                // チェックポイントのマーカー
                ForEach(viewModel.checkpoints) { checkpoint in
                    Marker(
                        "",
                        systemImage: checkpoint.type == .photo ? "camera.fill" : "mappin.circle.fill",
                        coordinate: checkpoint.coordinate()
                    )
                    .tint(.blue)
                }
                
                // 現在地マーカー（動く）
                if let currentCoordinate = viewModel.currentCoordinate {
                    Annotation("現在地", coordinate: currentCoordinate) {
                        Image(systemName: "figure.walk.circle.fill")
                            .font(.system(size: 30))
                            .foregroundStyle(.white, .red)
                            .shadow(radius: 2)
                    }
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            
            // コントロールバー
            VStack {
                Spacer()
                
                VStack(spacing: 16) {
                    // 進捗表示
                    if !viewModel.checkpoints.isEmpty {
                        ProgressView(value: viewModel.progressValue, total: 1.0)
                            .tint(.blue)
                            .padding(.horizontal)
                    }
                    
                    // コントロールボタン
                    HStack(spacing: 20) {
                        Button(action: {
                            viewModel.resetAnimation()
                        }) {
                            Image(systemName: "backward.end.fill")
                                .font(.title2)
                        }
                        
                        Button(action: {
                            if viewModel.isPlaying {
                                viewModel.pauseAnimation()
                            } else {
                                viewModel.startAnimation()
                            }
                        }) {
                            Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                                .font(.title)
                        }
                        
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                        }
                    }
                    
                    // ズーム（高度）調整
                    // 右に行くとズームイン（高度が下がる）、左に行くとズームアウト（高度が上がる）
                    HStack {
                        Image(systemName: "minus.magnifyingglass")
                        Slider(
                            value: Binding(
                                get: {
                                    // 距離 10000 -> 0.0 (Min Zoom)
                                    // 距離 500   -> 1.0 (Max Zoom)
                                    return 1.0 - ((cameraDistance - 500) / 9500.0)
                                },
                                set: { newValue in
                                    // 0.0 -> 10000
                                    // 1.0 -> 500
                                    let inverted = 1.0 - newValue
                                    cameraDistance = 500 + (inverted * 9500.0)
                                }
                            ),
                            in: 0...1
                        )
                        Image(systemName: "plus.magnifyingglass")
                    }
                    .padding(.horizontal)
                    
                    // 速度選択
                    Picker("速度", selection: $viewModel.animationSpeed) {
                        Text("0.25x").tag(0.25)
                        Text("0.5x").tag(0.5)
                        Text("1x").tag(1.0)
                        Text("2x").tag(2.0)
                        Text("5x").tag(5.0)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: viewModel.animationSpeed) { _, newValue in
                        viewModel.setSpeed(newValue)
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding()
            }
        }
        .onChange(of: viewModel.progressValue) { _, _ in
            if let coordinate = viewModel.currentCoordinate {
                // カメラを現在地に追従させる
                cameraPosition = .camera(
                    MapCamera(
                        centerCoordinate: coordinate,
                        distance: cameraDistance,
                        heading: 0,
                        pitch: 45
                    )
                )
            }
        }
        // ... (onChange of cameraDistance to update immediately if paused?)
        .onChange(of: cameraDistance) { _, _ in
            if let coordinate = viewModel.currentCoordinate {
                 cameraPosition = .camera(
                    MapCamera(
                        centerCoordinate: coordinate,
                        distance: cameraDistance,
                        heading: 0,
                        pitch: 45
                    )
                )
            }
        }
        .onAppear {
            if let first = viewModel.checkpoints.first {
                cameraPosition = .camera(
                    MapCamera(
                        centerCoordinate: first.coordinate(),
                        distance: cameraDistance,
                        heading: 0,
                        pitch: 45
                    )
                )
            }
        }
        .onDisappear {
            // 画面を閉じるときにアニメーションを停止してタイマーを破棄
            viewModel.pauseAnimation()
        }
    }

    private func updateCameraPosition() {
        // 未使用（onChangeで制御）
    }
}

#Preview {
    RouteAnimationView(checkpoints: [])
}
