//
//  PinAnnotation.swift
//  Routy
//
//  Created by 垣原親伍 on 2025/12/18.
//

import SwiftUI

/// カスタムピンAnnotation
struct PinAnnotation: View {
    let checkpoint: Checkpoint
    let isSelected: Bool

    var body: some View {
        ZStack {
            // ピンの影
            Circle()
                .fill(.black.opacity(0.2))
                .frame(width: isSelected ? 12 : 8, height: isSelected ? 12 : 8)
                .offset(y: isSelected ? 20 : 16)

            // ピン本体
            VStack(spacing: 0) {
                Circle()
                    .fill(pinColor)
                    .frame(width: isSelected ? 36 : 28, height: isSelected ? 36 : 28)
                    .overlay(
                        Image(systemName: pinIcon)
                            .font(.system(size: isSelected ? 16 : 12))
                            .foregroundColor(.white)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)

                // ピンの先端
                Triangle()
                    .fill(pinColor)
                    .frame(width: isSelected ? 12 : 8, height: isSelected ? 12 : 8)
                    .offset(y: -1)
            }
        }
        .scaleEffect(isSelected ? 1.2 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }

    private var pinColor: Color {
        switch checkpoint.type {
        case .photo:
            return .blue
        case .manualCheckin:
            return .green
        }
    }

    private var pinIcon: String {
        switch checkpoint.type {
        case .photo:
            return "camera.fill"
        case .manualCheckin:
            return "mappin"
        }
    }
}

/// 三角形のShape
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    VStack(spacing: 40) {
        PinAnnotation(
            checkpoint: Checkpoint(
                latitude: 35.6812,
                longitude: 139.7671,
                timestamp: Date(),
                type: .photo
            ),
            isSelected: false
        )

        PinAnnotation(
            checkpoint: Checkpoint(
                latitude: 35.6812,
                longitude: 139.7671,
                timestamp: Date(),
                type: .photo
            ),
            isSelected: true
        )

        PinAnnotation(
            checkpoint: Checkpoint(
                latitude: 35.6812,
                longitude: 139.7671,
                timestamp: Date(),
                type: .manualCheckin
            ),
            isSelected: false
        )
    }
    .padding()
}
