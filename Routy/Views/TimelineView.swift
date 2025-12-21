//
//  TimelineView.swift
//  Routy
//
//  Created by 垣原親伍 on 2025/12/18.
//

import SwiftUI
import Photos

/// タイムライン画面
struct TimelineView: View {
    let trip: Trip
    let onCheckpointTap: (Checkpoint) -> Void

    @State private var viewModel = TimelineViewModel()
    @State private var editMode: EditMode = .inactive
    @State private var selectedCheckpoints: Set<Checkpoint.ID> = []
    @State private var showDeleteConfirmation = false

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        List(selection: $selectedCheckpoints) {
            ForEach(viewModel.sortedDates(), id: \.self) { date in
                Section(header: Text(viewModel.formatDate(date))) {
                    if let checkpoints = viewModel.groupedCheckpoints[date] {
                        ForEach(checkpoints, id: \.id) { checkpoint in
                            CheckpointRow(checkpoint: checkpoint)
                                .onTapGesture {
                                    if editMode == .inactive {
                                        onCheckpointTap(checkpoint)
                                        dismiss()
                                    }
                                }
                        }
                    }
                }
            }
        }
        .navigationTitle("タイムライン")
        .navigationBarTitleDisplayMode(.inline)
        .environment(\.editMode, $editMode)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if editMode == .active {
                    Button("完了") {
                        editMode = .inactive
                        selectedCheckpoints.removeAll()
                    }
                } else {
                    Button("編集") {
                        editMode = .active
                    }
                }
            }

            if editMode == .active && !selectedCheckpoints.isEmpty {
                ToolbarItem(placement: .bottomBar) {
                    Button(role: .destructive, action: {
                        showDeleteConfirmation = true
                    }) {
                        Label("削除 (\(selectedCheckpoints.count))", systemImage: "trash")
                    }
                }
            }
        }
        .confirmationDialog("選択した項目を削除しますか？", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("削除", role: .destructive) {
                deleteSelectedCheckpoints()
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("\(selectedCheckpoints.count)件の記録が削除されます。この操作は取り消せません。")
        }
        .onAppear {
            viewModel.loadCheckpoints(from: trip)
        }
    }

    private func deleteSelectedCheckpoints() {
        trip.checkpoints.removeAll(where: { selectedCheckpoints.contains($0.id) })

        for checkpointID in selectedCheckpoints {
            if let checkpoint = viewModel.groupedCheckpoints.values
                .flatMap({ $0 })
                .first(where: { $0.id == checkpointID }) {
                modelContext.delete(checkpoint)
            }
        }

        do {
            try modelContext.save()
            viewModel.loadCheckpoints(from: trip)
        } catch {
            print("Error deleting checkpoints: \(error)")
        }

        selectedCheckpoints.removeAll()
        editMode = .inactive
    }
}

/// チェックポイント行
struct CheckpointRow: View {
    let checkpoint: Checkpoint

    var body: some View {
        HStack(spacing: 12) {
            // サムネイル
            if checkpoint.type == .photo, let assetID = checkpoint.photoAssetID {
                PhotoThumbnail(assetID: assetID, size: CGSize(width: 80, height: 80))
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.green)
                    .frame(width: 80, height: 80)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(DateFormatter.timeOnly.string(from: checkpoint.timestamp))
                    .font(.headline)

                if let address = checkpoint.address {
                    Text(address)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                if let note = checkpoint.note {
                    Text(note)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        TimelineView(
            trip: Trip(
                name: "テスト旅行",
                startDate: Date(),
                endDate: Date(),
                checkpoints: []
            ),
            onCheckpointTap: { _ in }
        )
    }
}
