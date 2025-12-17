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
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            ForEach(viewModel.sortedDates(), id: \.self) { date in
                Section(header: Text(viewModel.formatDate(date))) {
                    if let checkpoints = viewModel.groupedCheckpoints[date] {
                        ForEach(checkpoints, id: \.id) { checkpoint in
                            CheckpointRow(checkpoint: checkpoint)
                                .onTapGesture {
                                    onCheckpointTap(checkpoint)
                                    dismiss()
                                }
                        }
                    }
                }
            }
        }
        .navigationTitle("タイムライン")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadCheckpoints(from: trip)
        }
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
