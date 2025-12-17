//
//  AddPhotosSheet.swift
//  Routy
//
//  Created by 垣原親伍 on 2025/12/18.
//

import SwiftUI
import SwiftData

/// 写真追加シート（DateSelectionSheetの改良版）
struct AddPhotosSheet: View {
    let trip: Trip
    @Binding var isPresented: Bool

    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: MapViewModel?
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if isLoading {
                    ProgressView("写真を読み込み中...")
                        .padding()
                } else if let errorMessage = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button("再試行") {
                            loadPhotos()
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                } else {
                    VStack(spacing: 24) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 80))
                            .foregroundColor(.purple.opacity(0.7))

                        VStack(spacing: 12) {
                            Text("この旅行期間の写真を読み込みます")
                                .font(.headline)

                            Text("\(DateFormatter.dateOnly.string(from: trip.startDate)) - \(DateFormatter.dateOnly.string(from: trip.endDate))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Text("位置情報が含まれる写真から自動的にチェックポイントを作成します")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Button(action: loadPhotos) {
                            Text("写真を読込")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.purple)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal)
                    }
                }

                Spacer()
            }
            .padding()
            .navigationTitle("写真から追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        isPresented = false
                    }
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = MapViewModel(modelContext: modelContext)
            }
        }
    }

    private func loadPhotos() {
        guard let viewModel = viewModel else { return }

        isLoading = true
        errorMessage = nil

        Task {
            await viewModel.loadPhotosForTrip(trip: trip, startDate: trip.startDate, endDate: trip.endDate)

            await MainActor.run {
                isLoading = false
                if let error = viewModel.errorMessage {
                    errorMessage = error
                } else {
                    isPresented = false
                }
            }
        }
    }
}

#Preview {
    AddPhotosSheet(
        trip: Trip(name: "テスト旅行", startDate: Date(), endDate: Date()),
        isPresented: .constant(true)
    )
    .modelContainer(for: [Trip.self, Checkpoint.self])
}
