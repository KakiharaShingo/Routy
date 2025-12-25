//
//  DataExportView.swift
//  Routy
//
//  データエクスポート画面
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

/// データエクスポート画面
struct DataExportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var trips: [Trip]

    @State private var isExporting = false
    @State private var showShareSheet = false
    @State private var exportURL: URL?
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "square.and.arrow.up.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                    .padding(.top, 40)

                VStack(spacing: 12) {
                    Text("データをエクスポート")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("旅行データをCSV形式でエクスポートします")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(alignment: .leading, spacing: 16) {
                    InfoRow(icon: "checkmark.circle.fill", text: "全ての旅行データ", color: .green)
                    InfoRow(icon: "checkmark.circle.fill", text: "チェックポイント情報", color: .green)
                    InfoRow(icon: "checkmark.circle.fill", text: "位置情報・日時", color: .green)
                    InfoRow(icon: "xmark.circle.fill", text: "写真自体は含まれません", color: .orange)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

                Spacer()

                if isExporting {
                    ProgressView("エクスポート中...")
                        .padding()
                } else {
                    Button(action: exportData) {
                        Text("エクスポート")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(trips.isEmpty ? Color.gray : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .disabled(trips.isEmpty)
                    .padding(.bottom, 20)
                }
            }
            .padding()
            .navigationTitle("データエクスポート")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = exportURL {
                    ShareSheet(items: [url])
                }
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

    private func exportData() {
        isExporting = true

        Task {
            do {
                let csvContent = try await generateCSV()
                let fileName = "routy_backup_\(DateFormatter.fileNameDate.string(from: Date())).csv"
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

                try csvContent.write(to: tempURL, atomically: true, encoding: .utf8)

                await MainActor.run {
                    exportURL = tempURL
                    showShareSheet = true
                    isExporting = false
                }
            } catch {
                await MainActor.run {
                    alertMessage = "エクスポートに失敗しました: \(error.localizedDescription)"
                    showAlert = true
                    isExporting = false
                }
            }
        }
    }

    private func generateCSV() async throws -> String {
        var csv = "旅行ID,旅行名,開始日,終了日,チェックポイントID,名前,緯度,経度,日時,タイプ,カテゴリ,住所,メモ\n"

        for trip in trips {
            for checkpoint in trip.checkpoints {
                let row = [
                    trip.id.hashValue.description,
                    escapeCSV(trip.name),
                    DateFormatter.isoDate.string(from: trip.startDate),
                    DateFormatter.isoDate.string(from: trip.endDate),
                    checkpoint.id.hashValue.description,
                    escapeCSV(checkpoint.name ?? ""),
                    "\(checkpoint.latitude)",
                    "\(checkpoint.longitude)",
                    DateFormatter.isoDateTime.string(from: checkpoint.timestamp),
                    checkpoint.type.rawValue,
                    checkpoint.category?.rawValue ?? "",
                    escapeCSV(checkpoint.address ?? ""),
                    escapeCSV(checkpoint.note ?? "")
                ].joined(separator: ",")

                csv += row + "\n"
            }
        }

        return csv
    }

    private func escapeCSV(_ string: String) -> String {
        if string.contains(",") || string.contains("\"") || string.contains("\n") {
            return "\"" + string.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return string
    }
}

/// 情報行コンポーネント
struct InfoRow: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)

            Text(text)
                .font(.body)
                .foregroundColor(.primary)

            Spacer()
        }
    }
}

/// シェアシート
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// DateFormatter拡張
extension DateFormatter {
    static let fileNameDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return formatter
    }()

    static let isoDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static let isoDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
}

#Preview {
    DataExportView()
        .modelContainer(for: [Trip.self, Checkpoint.self])
}
