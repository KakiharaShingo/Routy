//
//  DataImportView.swift
//  Routy
//
//  データインポート画面
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

/// データインポート画面
struct DataImportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var isImporting = false
    @State private var showFilePicker = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var importedCount = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "square.and.arrow.down.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                    .padding(.top, 40)

                VStack(spacing: 12) {
                    Text("データをインポート")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("エクスポートしたCSVファイルから旅行データを復元します")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(alignment: .leading, spacing: 16) {
                    InfoRow(icon: "doc.text.fill", text: "CSVファイルを選択", color: .blue)
                    InfoRow(icon: "arrow.triangle.2.circlepath", text: "既存データに追加", color: .blue)
                    InfoRow(icon: "exclamationmark.triangle.fill", text: "重複データに注意", color: .orange)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

                VStack(alignment: .leading, spacing: 8) {
                    Text("注意事項")
                        .font(.headline)

                    Text("• 写真自体は復元されません\n• 同じ旅行を複数回インポートすると重複します\n• インポート前にバックアップを推奨")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

                Spacer()

                if isImporting {
                    ProgressView("インポート中...")
                        .padding()
                } else {
                    Button(action: {
                        showFilePicker = true
                    }) {
                        Text("CSVファイルを選択")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.bottom, 20)
                }
            }
            .padding()
            .navigationTitle("データインポート")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [.commaSeparatedText, .plainText],
                allowsMultipleSelection: false
            ) { result in
                handleFileSelection(result)
            }
            .alert("完了", isPresented: $showAlert) {
                Button("OK") {
                    if !alertMessage.contains("エラー") {
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
        }
    }

    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            importData(from: url)
        case .failure(let error):
            alertMessage = "ファイル選択エラー: \(error.localizedDescription)"
            showAlert = true
        }
    }

    private func importData(from url: URL) {
        isImporting = true

        Task {
            do {
                guard url.startAccessingSecurityScopedResource() else {
                    throw ImportError.accessDenied
                }
                defer { url.stopAccessingSecurityScopedResource() }

                let csvContent = try String(contentsOf: url, encoding: .utf8)
                let count = try await parseAndImportCSV(csvContent)

                await MainActor.run {
                    importedCount = count
                    alertMessage = "\(count)件のチェックポイントをインポートしました"
                    showAlert = true
                    isImporting = false
                }
            } catch {
                await MainActor.run {
                    alertMessage = "インポートに失敗しました: \(error.localizedDescription)"
                    showAlert = true
                    isImporting = false
                }
            }
        }
    }

    private func parseAndImportCSV(_ content: String) async throws -> Int {
        let lines = content.components(separatedBy: .newlines)
        guard lines.count > 1 else {
            throw ImportError.invalidFormat
        }

        // ヘッダー行をスキップ
        let dataLines = lines.dropFirst().filter { !$0.isEmpty }

        var tripCache: [String: Trip] = [:]
        var checkpointCount = 0

        for line in dataLines {
            let columns = parseCSVLine(line)
            guard columns.count >= 13 else { continue }

            let tripID = columns[0]
            let tripName = columns[1]
            let startDateStr = columns[2]
            let endDateStr = columns[3]
            _ = columns[4] // checkpointID（未使用）
            let name = columns[5]
            let latitude = Double(columns[6]) ?? 0
            let longitude = Double(columns[7]) ?? 0
            let timestampStr = columns[8]
            let typeStr = columns[9]
            let categoryStr = columns[10]
            let address = columns[11]
            let note = columns[12]

            // Tripを取得または作成
            let trip: Trip
            if let cachedTrip = tripCache[tripID] {
                trip = cachedTrip
            } else {
                guard let startDate = DateFormatter.isoDate.date(from: startDateStr),
                      let endDate = DateFormatter.isoDate.date(from: endDateStr) else {
                    continue
                }

                trip = Trip(name: tripName, startDate: startDate, endDate: endDate)
                modelContext.insert(trip)
                tripCache[tripID] = trip
            }

            // Checkpointを作成
            guard let timestamp = DateFormatter.isoDateTime.date(from: timestampStr),
                  let type = CheckpointType(rawValue: typeStr) else {
                continue
            }

            let checkpoint = Checkpoint(
                latitude: latitude,
                longitude: longitude,
                timestamp: timestamp,
                type: type,
                trip: trip
            )

            if !name.isEmpty {
                checkpoint.name = name
            }

            if !categoryStr.isEmpty {
                checkpoint.category = CheckpointCategory(rawValue: categoryStr)
            }

            if !address.isEmpty {
                checkpoint.address = address
            }

            if !note.isEmpty {
                checkpoint.note = note
            }

            modelContext.insert(checkpoint)
            trip.checkpoints.append(checkpoint)
            checkpointCount += 1
        }

        try modelContext.save()
        return checkpointCount
    }

    private func parseCSVLine(_ line: String) -> [String] {
        var columns: [String] = []
        var currentColumn = ""
        var insideQuotes = false

        for char in line {
            if char == "\"" {
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                columns.append(currentColumn.replacingOccurrences(of: "\"\"", with: "\""))
                currentColumn = ""
            } else {
                currentColumn.append(char)
            }
        }

        columns.append(currentColumn.replacingOccurrences(of: "\"\"", with: "\""))
        return columns
    }
}

enum ImportError: LocalizedError {
    case accessDenied
    case invalidFormat

    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "ファイルへのアクセスが拒否されました"
        case .invalidFormat:
            return "CSVファイルの形式が不正です"
        }
    }
}

#Preview {
    DataImportView()
        .modelContainer(for: [Trip.self, Checkpoint.self])
}
