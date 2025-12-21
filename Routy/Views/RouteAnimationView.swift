
import SwiftUI
import MapKit
import AVKit

/// 経路アニメーション画面
struct RouteAnimationView: View {
    let checkpoints: [Checkpoint]
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: RouteAnimationViewModel
    @StateObject private var videoManager = VideoGenerationManager()
    
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var cameraDistance: Double = 2000.0
    
    // Preview
    @State private var showPreview = false
    @State private var showExportOptions = false
    @State private var selectedCheckpoint: Checkpoint? // For Photo Popup
    @State private var cameraFollowEnabled = true // カメラ追跡ON/OFF
    @State private var currentDateString: String? // For Date Popup

    init(checkpoints: [Checkpoint]) {
        self.checkpoints = checkpoints
        _viewModel = State(initialValue: RouteAnimationViewModel(checkpoints: checkpoints))
    }

    var body: some View {
        ZStack {
            // Smooth Map View
            SmoothRouteMapView(
                checkpoints: viewModel.checkpoints,
                routeCoordinates: viewModel.routeCoordinates,
                routeSegmentTypes: viewModel.routeSegmentTypes,
                transportMode: viewModel.transportMode,
                isPlaying: $viewModel.isPlaying,
                progress: $viewModel.progressValue,
                animationSpeed: $viewModel.animationSpeed,
                currentCoordinate: $viewModel.currentCoordinate,
                selectedCheckpoint: $selectedCheckpoint,
                currentDateString: $currentDateString,
                cameraFollowEnabled: $cameraFollowEnabled,
                videoManager: videoManager
            )
            .edgesIgnoringSafeArea(.all)
            // Hide map interaction when generating or calculating
            .allowsHitTesting(!videoManager.isGenerating && !viewModel.isCalculating)
            
            // Calculating Overlay (semi-transparent)
            if viewModel.isCalculating && !videoManager.isGenerating {
                Color.black.opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                    .allowsHitTesting(false)

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                                .scaleEffect(1.5)
                            Text("経路計算中...")
                                .font(.subheadline)
                                .foregroundColor(.white)
                        }
                        .padding(24)
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                        Spacer()
                    }
                    Spacer()
                }
                .allowsHitTesting(false)
            }

            // UI Layer (Only visible when NOT generating)
            if !videoManager.isGenerating {
                // Top Left Dismiss Button
                VStack {
                    HStack {
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title)
                                .foregroundStyle(.white, .gray)
                                .background(Circle().fill(.black.opacity(0.4)))
                        }

                        Spacer()

                        // Camera Follow Toggle
                        Button(action: {
                            cameraFollowEnabled.toggle()
                        }) {
                            Image(systemName: cameraFollowEnabled ? "video.fill" : "video.slash.fill")
                                .font(.title2)
                                .foregroundStyle(.white, cameraFollowEnabled ? .green : .gray)
                                .background(Circle().fill(.black.opacity(0.4)))
                        }
                        .disabled(viewModel.isCalculating)

                        // Top Right Export Button
                        Button(action: {
                            showExportOptions = true
                        }) {
                            Image(systemName: "square.and.arrow.up.circle.fill")
                                .font(.title)
                                .foregroundStyle(.white, .blue)
                                .background(Circle().fill(.white))
                        }
                        .disabled(viewModel.isCalculating)
                        .confirmationDialog("動画の長さを選択", isPresented: $showExportOptions, titleVisibility: .visible) {
                            Button("15秒 (高速生成)") {
                                videoManager.startGeneration(duration: 15.0)
                            }
                            Button("30秒 (標準)") {
                                videoManager.startGeneration(duration: 30.0)
                            }
                            Button("60秒 (高画質)") {
                                videoManager.startGeneration(duration: 60.0)
                            }
                            Button("現在の再生速度に合わせる (\(Int(180.0 / viewModel.animationSpeed))秒)") {
                                let duration = 180.0 / viewModel.animationSpeed
                                videoManager.startGeneration(duration: duration)
                            }
                            Button("キャンセル", role: .cancel) {}
                        } message: {
                            Text("動画の長さが長いほど、生成に時間がかかります。")
                        }

                    }
                    .padding()
                    Spacer()
                }

                // コントロールバー
                VStack {
                    Spacer()

                    VStack(spacing: 16) {
                        // プログレスバー
                        HStack(spacing: 12) {
                            Text("\(Int(viewModel.progressValue * 100))%")
                                .font(.caption)
                                .foregroundColor(.white)
                                .frame(width: 40)

                            Slider(value: $viewModel.progressValue, in: 0...1)
                                .tint(.white)
                                .disabled(viewModel.isCalculating)

                            Text("\(Int((1 - viewModel.progressValue) * 180 / viewModel.animationSpeed))s")
                                .font(.caption)
                                .foregroundColor(.white)
                                .frame(width: 40)
                        }
                        .padding(.horizontal)

                        // 再生コントロール
                        HStack(spacing: 24) {
                            // リセットボタン
                            Button(action: {
                                viewModel.resetAnimation()
                            }) {
                                Image(systemName: "backward.end.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                            .disabled(viewModel.isCalculating)

                            // 再生/一時停止ボタン
                            Button(action: {
                                if viewModel.isPlaying {
                                    viewModel.pauseAnimation()
                                } else {
                                    viewModel.startAnimation()
                                }
                            }) {
                                Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.white)
                            }
                            .disabled(viewModel.isCalculating)

                            // 速度調整
                            Menu {
                                Button("0.5x") { viewModel.setSpeed(0.5) }
                                Button("1x (標準)") { viewModel.setSpeed(1.0) }
                                Button("2x") { viewModel.setSpeed(2.0) }
                                Button("3x") { viewModel.setSpeed(3.0) }
                                Button("5x") { viewModel.setSpeed(5.0) }
                            } label: {
                                HStack {
                                    Image(systemName: "speedometer")
                                        .font(.title2)
                                    Text("\(String(format: "%.1f", viewModel.animationSpeed))x")
                                        .font(.caption)
                                }
                                .foregroundColor(.white)
                            }
                            .disabled(viewModel.isCalculating)
                        }

                        // 移動手段選択
                        HStack {
                            Picker("移動手段", selection: $viewModel.transportMode) {
                                ForEach(RouteAnimationViewModel.TransportMode.allCases) { mode in
                                    Label(mode.rawValue, systemImage: mode.systemIcon)
                                        .tag(mode)
                                }
                            }
                            .pickerStyle(.segmented)
                            .disabled(viewModel.isCalculating)

                            if viewModel.isCalculating {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(.white)
                                    .scaleEffect(0.8)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(20)
                    .padding()
                }
                .opacity(selectedCheckpoint != nil ? 0 : 1) // Hide controls when popup is open
            } else {
                // GENERATING OVERLAY
                ZStack {
                    Color.black.opacity(0.8)
                        .edgesIgnoringSafeArea(.all)
                    
                    VStack(spacing: 20) {
                        ProgressView(value: videoManager.progress, total: 1.0)
                            .progressViewStyle(.linear)
                            .frame(width: 200)
                            .tint(.blue)
                        
                        Text("動画生成中...")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("\(Int(videoManager.progress * 100))%")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            // MARK: - Photo Popup Overlay (Checkpoint Arrival)
            if let cp = selectedCheckpoint {
                ZStack {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation { selectedCheckpoint = nil }
                        }

                    GeometryReader { geometry in
                        VStack(spacing: 8) {
                            // 大きな画像
                            if let assetID = cp.photoAssetID {
                                PhotoAssetView(assetID: assetID)
                                    .frame(width: 200, height: 200)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .shadow(radius: 10)
                            } else if let url = cp.photoURL, let imageURL = URL(string: url) {
                                AsyncImage(url: imageURL) { image in
                                    image.resizable().scaledToFill()
                                } placeholder: {
                                    ProgressView()
                                }
                                .frame(width: 200, height: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .shadow(radius: 10)
                            } else {
                                ZStack {
                                    Color(.systemGray6)
                                    Image(systemName: "photo")
                                        .font(.largeTitle)
                                        .foregroundColor(.gray)
                                }
                                .frame(width: 200, height: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .shadow(radius: 10)
                            }

                            // 情報カード
                            VStack(spacing: 4) {
                                Text(cp.name ?? "スポット")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.primary)
                                    .lineLimit(1)

                                Text(DateFormatter.japaneseDateTime.string(from: cp.timestamp))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .frame(width: 200)
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(10)
                            .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
                        }
                        .position(x: geometry.size.width / 2, y: 150)
                        .transition(.scale.combined(with: .opacity))
                    }
                    .allowsHitTesting(false)
                }
                .zIndex(200) // Above everything
            }

            // MARK: - Date Popup (Date Change)
            if let dateStr = currentDateString {
                VStack {
                    HStack {
                        Text(dateStr)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                Capsule()
                                    .fill(Color.blue.opacity(0.9))
                                    .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                            )
                    }
                    .padding(.top, 80)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(250) // Above photo popup
            }
        }
        .onDisappear {
            viewModel.pauseAnimation()
        }
        .onChange(of: videoManager.generatedVideoURL) { _, url in
            if url != nil {
                showPreview = true
            }
        }
        .onChange(of: videoManager.error) { _, error in
            // Handle error alert if needed
        }
        .sheet(isPresented: $showPreview) {
            if let url = videoManager.generatedVideoURL {
                VideoPreviewView(videoURL: url)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    private func updateCameraPosition() {
        // 未使用（onChangeで制御）
    }
}



// Preview Sheet
struct VideoPreviewView: View {
    let videoURL: URL
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VideoPlayer(player: AVPlayer(url: videoURL))
                .edgesIgnoringSafeArea(.all)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("閉じる") { dismiss() }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        ShareLink(item: videoURL) {
                            Label("保存/共有", systemImage: "square.and.arrow.up")
                        }
                    }
                }
        }
    }
}

#Preview {
    RouteAnimationView(checkpoints: [])
}
