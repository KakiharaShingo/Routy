//
//  DateSelectionSheet.swift
//  Routy
//
//  Created by 垣原親伍 on 2025/12/18.
//

import SwiftUI

/// 日付選択シート
struct DateSelectionSheet: View {
    @Binding var isPresented: Bool
    let onLoadPhotos: (Date, Date) -> Void

    @State private var startDate = Date().addingTimeInterval(-7 * 24 * 60 * 60) // 1週間前
    @State private var endDate = Date()

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("旅行期間を選択")) {
                    DatePicker("開始日", selection: $startDate, in: ...Date(), displayedComponents: .date)
                    DatePicker("終了日", selection: $endDate, in: startDate...Date(), displayedComponents: .date)
                }

                Section {
                    Button(action: {
                        onLoadPhotos(startDate, endDate)
                        isPresented = false
                    }) {
                        HStack {
                            Spacer()
                            Text("写真を読込")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(endDate < startDate)
                }
            }
            .navigationTitle("日付選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

#Preview {
    DateSelectionSheet(isPresented: .constant(true)) { _, _ in }
}
