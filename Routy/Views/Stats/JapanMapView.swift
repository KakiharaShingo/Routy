//
//  JapanMapView.swift
//  Routy
//
//  Created by Auto-generated on 2025/12/19.
//

import SwiftUI

struct JapanMapView: View {
    @Binding var stats: [Int: PrefectureLevel] // Key: Prefecture ID (1-47)
    var onSelect: (Prefecture) -> Void
    
    // グリッド定数
    let gridSize: CGFloat = 35
    let spacing: CGFloat = 4
    
    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            ZStack(alignment: .topLeading) {
                ForEach(japanPrefectures) { pref in
                    PrefectureBlock(
                        prefecture: pref,
                        level: stats[pref.id] ?? .none,
                        size: gridSize
                    )
                    .onTapGesture {
                        onSelect(pref)
                    }
                    .position(
                        x: CGFloat(pref.x) * (gridSize + spacing) + gridSize/2,
                        y: CGFloat(pref.y) * (gridSize + spacing) + gridSize/2
                    )
                }
            }
            .frame(
                width: 15 * (gridSize + spacing), // Max X is 14 (Iwate etc) -> 15 blocks width
                height: 15 * (gridSize + spacing) // Max Y is 13 (Okinawa) -> 14 blocks height
            )

            .padding()
            .padding(.top, 60) // マップ全体を下に移動
        }
    }
}

struct PrefectureBlock: View {
    let prefecture: Prefecture
    let level: PrefectureLevel
    let size: CGFloat
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(level.color)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 1, y: 1)
            
            Text(simplifyName(prefecture.name))
                .font(.system(size: size * 0.35, weight: .bold))
                .foregroundColor(level == .none ? .gray : .white)
                .minimumScaleFactor(0.5)
        }
        .frame(width: size, height: size)
    }
    
    // 長い名前を短縮（画面スペース節約のため）
    func simplifyName(_ name: String) -> String {
        if name.hasSuffix("県") { return String(name.dropLast()) }
        if name.hasSuffix("府") { return String(name.dropLast()) }
        if name == "東京都" { return "東京" }
        return name
    }
}

#Preview {
    JapanMapView(stats: .constant([1: .visited, 13: .stayed, 47: .landed])) { _ in }
}
