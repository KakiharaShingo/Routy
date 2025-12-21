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
    @State private var showList = false // デフォルトは非表示（マップ優先）
    @State private var showPhotoPopup = false // 画像ポップアップの表示状態
    
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
                            // シンプルなピン表示（画像表示なし）
                            VStack(spacing: 0) {
                                Circle()
                                    .fill(checkpoint.type == .photo ? Color.blue : Color.green)
                                    .frame(width: viewModel.selectedCheckpoint?.id == checkpoint.id ? 36 : 28,
                                           height: viewModel.selectedCheckpoint?.id == checkpoint.id ? 36 : 28)
                                    .overlay(
                                        Image(systemName: checkpoint.type == .photo ? "camera.fill" : "mappin")
                                            .font(.system(size: viewModel.selectedCheckpoint?.id == checkpoint.id ? 16 : 12))
                                            .foregroundColor(.white)
                                    )
                                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)

                                PinTriangle()
                                    .fill(checkpoint.type == .photo ? Color.blue : Color.green)
                                    .frame(width: viewModel.selectedCheckpoint?.id == checkpoint.id ? 12 : 8,
                                           height: viewModel.selectedCheckpoint?.id == checkpoint.id ? 12 : 8)
                                    .offset(y: -1)
                            }
                            .scaleEffect(viewModel.selectedCheckpoint?.id == checkpoint.id ? 1.2 : 1.0)
                            .animation(.spring(response: 0.3), value: viewModel.selectedCheckpoint?.id == checkpoint.id)
                            .onTapGesture {
                                withAnimation {
                                    viewModel.selectCheckpoint(checkpoint)
                                    showPhotoPopup = true
                                }
                            }
                        }
                        .tag(checkpoint.id)
                    }
                }
                .mapStyle(.standard)

                // 選択されたピンの上に画像を表示
                if showPhotoPopup, let selectedCheckpoint = viewModel.selectedCheckpoint {
                    ZStack {
                        // 背景タップで閉じる
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation {
                                    showPhotoPopup = false
                                }
                            }

                        GeometryReader { geometry in
                            VStack(spacing: 8) {
                                // 大きな画像
                                if let assetID = selectedCheckpoint.photoAssetID {
                                    PhotoAssetView(assetID: assetID)
                                        .frame(width: 200, height: 200)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .shadow(radius: 10)
                                } else if let url = selectedCheckpoint.photoThumbnailURL, let imageURL = URL(string: url) {
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
                                    Text(selectedCheckpoint.name ?? "スポット")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.primary)
                                        .lineLimit(1)

                                    Text(DateFormatter.japaneseDateTime.string(from: selectedCheckpoint.timestamp))
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
                    .zIndex(100)
                }
                
                // リスト表示/非表示ボタン
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            withAnimation(.spring()) {
                                showList.toggle()
                            }
                        }) {
                            Image(systemName: showList ? "map" : "list.bullet")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(Color.blue)
                                .clipShape(Circle())
                                .shadow(radius: 6)
                        }
                        .padding(.trailing, 24)
                        // リストが表示されているときは、リストの分だけ上にずらす、そうでなければタブバーの少し上
                        .padding(.bottom, showList ? 270 : 100)
                    }
                }
                .zIndex(2) // シートより上に表示
                
                // カスタムボトムシート（リスト表示）
                if showList {
                    VStack(spacing: 0) {
                        Spacer()
                        
                        VStack(spacing: 0) {
                            // 情報バー (閉じるボタン含む)
                            HStack {
                                Text("記録一覧")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Button(action: {
                                    withAnimation {
                                        showList = false
                                    }
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(Color(.systemGray3))
                                        .font(.title3)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                            .padding(.bottom, 8)
                            
                            // フィルター (横スクロール)
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
                                    .padding(.horizontal, 20)
                                }
                                .padding(.bottom, 10)
                            }
                            
                            // リスト (縦スクロール)
                            if viewModel.checkpoints.isEmpty {
                                ContentUnavailableView("データがありません", systemImage: "mappin.slash")
                                    .frame(height: 120)
                            } else {
                                ScrollViewReader { proxy in
                                    List {
                                        ForEach(viewModel.checkpoints) { checkpoint in
                                            HStack(spacing: 12) {
                                            // サムネイル
                                            if let assetID = checkpoint.photoAssetID {
                                                PhotoThumbnail(assetID: assetID, size: CGSize(width: 44, height: 44))
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(width: 44, height: 44)
                                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                            } else if let url = checkpoint.photoThumbnailURL, let imageURL = URL(string: url) {
                                                AsyncImage(url: imageURL) { image in
                                                    image.resizable().aspectRatio(contentMode: .fill)
                                                } placeholder: {
                                                    Color.gray.opacity(0.3)
                                                }
                                                .frame(width: 44, height: 44)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                            } else {
                                                ZStack {
                                                    Color(.systemGray6)
                                                    Image(systemName: "mappin")
                                                        .font(.caption2)
                                                        .foregroundColor(.gray)
                                                }
                                                .frame(width: 44, height: 44)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                            }
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(checkpoint.name ?? "スポット")
                                                    .font(.system(size: 13, weight: .semibold))
                                                    .foregroundColor(.primary)
                                                    .lineLimit(1)
                                                
                                                Text(DateFormatter.japaneseDateTime.string(from: checkpoint.timestamp))
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                            }
                                            
                                            Spacer()
                                            
                                            if viewModel.selectedCheckpoint?.id == checkpoint.id {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(.blue)
                                                    .font(.caption)
                                            }
                                        }
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            withAnimation {
                                                viewModel.selectCheckpoint(checkpoint)
                                                // リストが表示されているときは画像も表示
                                                if showList {
                                                    showPhotoPopup = true
                                                }
                                            }
                                        }
                                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                        .listRowBackground(
                                            viewModel.selectedCheckpoint?.id == checkpoint.id
                                                ? Color.blue.opacity(0.1)
                                                : Color(UIColor.secondarySystemGroupedBackground)
                                        )
                                        .id(checkpoint.id)
                                    }
                                    }
                                    .listStyle(.plain)
                                    .frame(height: 200)
                                    .onAppear {
                                        // リスト表示時に選択されたアイテムまでスクロール
                                        if let selectedId = viewModel.selectedCheckpoint?.id {
                                            withAnimation {
                                                proxy.scrollTo(selectedId, anchor: .center)
                                            }
                                        }
                                    }
                                    .onChange(of: viewModel.selectedCheckpoint?.id) { _, newId in
                                        // 選択が変わったときにスクロール
                                        if let newId = newId {
                                            withAnimation {
                                                proxy.scrollTo(newId, anchor: .center)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(24) // 角丸を強める
                        .shadow(color: .black.opacity(0.15), radius: 15, y: -2)
                        .padding(.horizontal, 16) // 左右に余白を持たせて「浮いている」感を出す
                        .padding(.bottom, 90) // TabBarの高さ分
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(1)
                    .ignoresSafeArea(edges: .bottom)
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

/// カルーセル用のカードビュー
struct CheckpointCard: View {
    let checkpoint: Checkpoint
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // サムネイル
            if let assetID = checkpoint.photoAssetID {
                PhotoThumbnail(assetID: assetID, size: CGSize(width: 80, height: 80))
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else if let url = checkpoint.photoThumbnailURL, let imageURL = URL(string: url) {
                AsyncImage(url: imageURL) { image in
                     image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                     Color.gray.opacity(0.3)
                }
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                ZStack {
                    Color(.systemGray6)
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(.gray)
                }
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // 情報
            VStack(alignment: .leading, spacing: 4) {
                Text(checkpoint.name ?? "スポット")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(DateFormatter.japaneseDateTime.string(from: checkpoint.timestamp))
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
                
                if let address = checkpoint.address {
                    Text(address)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            .frame(width: 140) // テキスト幅固定
            
            Spacer()
        }
        .padding(10)
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: isSelected ? .blue.opacity(0.3) : .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
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
                        Text(DateFormatter.japaneseDateTime.string(from: checkpoint.timestamp))
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

/// ピン用三角形のShape
struct PinTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

// 日本語の日付フォーマッター拡張
extension DateFormatter {
    static let japaneseDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年M月d日"
        return formatter
    }()
    
    static let japaneseDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年M月d日 H:mm"
        return formatter
    }()
    
    static let monthDay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M/d"
        return formatter
    }()
}

#Preview {
    GlobalMapView()
        .modelContainer(for: [Trip.self, Checkpoint.self])
}
