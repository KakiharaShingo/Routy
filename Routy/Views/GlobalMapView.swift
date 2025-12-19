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
/// 全てのチェックポイントを表示する地図画面
struct GlobalMapView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Checkpoint.timestamp, order: .reverse) private var allCheckpoints: [Checkpoint]
    
    @State private var viewModel: MapViewModel?
    @State private var showErrorAlert = false
    @State private var selectedDate: Date? // 選択中の日付（nilの場合は全期間）
    @State private var isSheetPresented = true
    
    // 日付のリストを生成
    private var availableDates: [Date] {
        let calendar = Calendar.current
        let dates = allCheckpoints.map { calendar.startOfDay(for: $0.timestamp) }
        return Array(Set(dates)).sorted().reversed() // 新しい順
    }

    var body: some View {
        ZStack(alignment: .top) {
            if let viewModel = viewModel {
                // 地図
                Map(position: Binding(
                    get: { viewModel.cameraPosition },
                    set: { viewModel.cameraPosition = $0 }
                ), selection: Binding(
                    get: { viewModel.selectedCheckpoint?.id },
                    set: { id in
                        if let id = id, let checkpoint = viewModel.checkpoints.first(where: { $0.id == id }) {
                            viewModel.selectCheckpoint(checkpoint)
                        } else {
                            viewModel.selectedCheckpoint = nil
                        }
                    }
                )) {
                    ForEach(viewModel.checkpoints) { checkpoint in
                        Annotation("", coordinate: checkpoint.coordinate()) {
                            PinAnnotation(
                                checkpoint: checkpoint,
                                isSelected: viewModel.selectedCheckpoint?.id == checkpoint.id
                            )
                        }
                        .tag(checkpoint.id)
                    }
                }
                .mapStyle(.standard)
                .sheet(isPresented: $isSheetPresented) {
                    NavigationStack {
                        VStack(spacing: 0) {
                            // 日付フィルター（シート内上部）
                            if !availableDates.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        FilterChip(title: "全期間", isSelected: selectedDate == nil) {
                                            selectedDate = nil
                                            updateFilteredCheckpoints()
                                        }
                                        
                                        ForEach(availableDates, id: \.self) { date in
                                            FilterChip(
                                                title: DateFormatter.monthDay.string(from: date),
                                                isSelected: selectedDate == date
                                            ) {
                                                selectedDate = date
                                                updateFilteredCheckpoints()
                                            }
                                        }
                                    }
                                    .padding()
                                }
                                .background(Color(.systemBackground))
                                .shadow(radius: 1)
                            }
                            
                            // チェックポイント一覧
                            if viewModel.checkpoints.isEmpty {
                                ContentUnavailableView("データがありません", systemImage: "mappin.slash")
                            } else {
                                ScrollViewReader { proxy in
                                    List(viewModel.checkpoints) { checkpoint in
                                        NavigationLink(destination: CheckpointDetailView(checkpoint: checkpoint)) {
                                            HStack {
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(DateFormatter.localizedString(from: checkpoint.timestamp, dateStyle: .short, timeStyle: .short))
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                    
                                                    // 名前があれば名前、なければ住所
                                                    Text(checkpoint.name ?? checkpoint.address ?? "場所不明")
                                                        .font(.body)
                                                        .fontWeight(.medium)
                                                        .lineLimit(2)
                                                }
                                                
                                                if viewModel.selectedCheckpoint?.id == checkpoint.id {
                                                    Spacer()
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .foregroundColor(.blue)
                                                }
                                            }
                                        }
                                        .id(checkpoint.id)
                                        .listRowBackground(viewModel.selectedCheckpoint?.id == checkpoint.id ? Color.blue.opacity(0.1) : nil)
                                        .onTapGesture {
                                            // リストタップで地図も選択
                                            viewModel.selectCheckpoint(checkpoint)
                                        }
                                    }
                                    .listStyle(.plain)
                                    .onChange(of: viewModel.selectedCheckpoint) { _, newCheckpoint in
                                        if let checkpoint = newCheckpoint {
                                            withAnimation {
                                                proxy.scrollTo(checkpoint.id, anchor: .center)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .navigationTitle("記録一覧")
                        .navigationBarTitleDisplayMode(.inline)
                    }
                    .presentationDetents([.fraction(0.3), .medium, .large])
                    .presentationBackgroundInteraction(.enabled(upThrough: .medium))
                    .interactiveDismissDisabled()
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
        .navigationTitle("マイマップ")
        .navigationBarTitleDisplayMode(.inline)
        .alert("エラー", isPresented: $showErrorAlert) {
            Button("OK") {
                viewModel?.errorMessage = nil
            }
        } message: {
            if let errorMessage = viewModel?.errorMessage {
                Text(errorMessage)
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = MapViewModel(modelContext: modelContext)
            }
            // 初期データセット
            updateFilteredCheckpoints()
        }
        .onChange(of: allCheckpoints) { _, _ in
             updateFilteredCheckpoints()
        }
    }
    
    private func updateFilteredCheckpoints() {
        guard let viewModel = viewModel else { return }
        
        if let date = selectedDate {
            let calendar = Calendar.current
            viewModel.checkpoints = allCheckpoints.filter {
                calendar.isDate($0.timestamp, inSameDayAs: date)
            }
        } else {
            viewModel.checkpoints = allCheckpoints
        }
        
        // フィルタリング後に地図中心を合わせる
        viewModel.centerMapOnCheckpoints()
    }
}

/// フィルター用チップ
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .bold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}

/// チェックポイント詳細ビュー
struct CheckpointDetailView: View {
    let checkpoint: Checkpoint
    @State private var localImage: UIImage?
    @State private var isLoadingImage = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 大きな画像表示
                Group {
                    if let urlString = checkpoint.photoThumbnailURL, let url = URL(string: urlString) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable()
                                     .aspectRatio(contentMode: .fit)
                                     .frame(maxWidth: .infinity)
                                     .cornerRadius(12)
                                     .shadow(radius: 5)
                            case .failure:
                                Image(systemName: "photo.badge.exclamationmark")
                                    .font(.system(size: 50))
                                    .foregroundColor(.gray)
                                    .frame(height: 200)
                                    .frame(maxWidth: .infinity)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                            case .empty:
                                ProgressView()
                                    .frame(height: 200)
                                    .frame(maxWidth: .infinity)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                            @unknown default:
                                 EmptyView()
                            }
                        }
                    } else if let localImage = localImage {
                        Image(uiImage: localImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity)
                            .cornerRadius(12)
                            .shadow(radius: 5)
                    } else if isLoadingImage {
                         ProgressView()
                            .frame(height: 200)
                            .frame(maxWidth: .infinity)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    } else {
                         HStack {
                            Spacer()
                            VStack {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.system(size: 50))
                                    .foregroundColor(.gray)
                                Text("写真なし")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .frame(height: 200)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
                
                VStack(alignment: .leading, spacing: 15) {
                    // 名前
                    if let name = checkpoint.name {
                        Text(name)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    
                    // 日時と住所
                    VStack(alignment: .leading, spacing: 4) {
                        Text(DateFormatter.localizedString(from: checkpoint.timestamp, dateStyle: .full, timeStyle: .short))
                            .font(.headline)
                            .foregroundColor(.blue)
                        
                        HStack(alignment: .top) {
                            Image(systemName: "mappin.and.ellipse")
                                .foregroundColor(.gray)
                            Text(checkpoint.address ?? "住所不明")
                        }
                        .font(.body)
                    }
                    
                    Divider()
                    
                    // メモ
                    if let note = checkpoint.note, !note.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("メモ")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(note)
                                .font(.body)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                    }
                }
                .padding()
            }
            .padding()
        }
        .navigationTitle("詳細")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            // ローカル画像の読み込み試行
            if checkpoint.photoThumbnailURL == nil, let assetID = checkpoint.photoAssetID {
                isLoadingImage = true
                let service = PhotoService() // 簡易的にインスタンス化
                localImage = await service.fetchImage(for: assetID)
                isLoadingImage = false
            }
        }
    }
}

extension DateFormatter {
    static let monthDay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter
    }()
}

#Preview {
    GlobalMapView()
        .modelContainer(for: [Trip.self, Checkpoint.self])
}
