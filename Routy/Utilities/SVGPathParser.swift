//
//  SVGPathParser.swift
//  Routy
//
//  Created by Claude on 2025/12/20.
//

import UIKit
import SwiftUI

/// SVGパス文字列をUIBezierPathに変換するパーサー
struct SVGPathParser {
    /// SVGパス文字列をUIBezierPathに変換
    static func parse(_ pathString: String) -> UIBezierPath {
        let path = UIBezierPath()
        var currentPoint = CGPoint.zero
        var startPoint = CGPoint.zero

        // パスコマンドをパース
        let scanner = Scanner(string: pathString)
        scanner.charactersToBeSkipped = CharacterSet.whitespacesAndNewlines

        while !scanner.isAtEnd {
            guard let command = scanner.scanCharacters(from: CharacterSet.letters),
                  let firstChar = command.first else {
                continue
            }

            switch firstChar {
            case "M": // Move to (absolute)
                if let point = scanPoint(scanner) {
                    path.move(to: point)
                    currentPoint = point
                    startPoint = point
                }

            case "m": // Move to (relative)
                if let point = scanPoint(scanner) {
                    let newPoint = CGPoint(x: currentPoint.x + point.x, y: currentPoint.y + point.y)
                    path.move(to: newPoint)
                    currentPoint = newPoint
                    startPoint = newPoint
                }

            case "L": // Line to (absolute)
                while let point = scanPoint(scanner) {
                    path.addLine(to: point)
                    currentPoint = point
                }

            case "l": // Line to (relative)
                while let point = scanPoint(scanner) {
                    let newPoint = CGPoint(x: currentPoint.x + point.x, y: currentPoint.y + point.y)
                    path.addLine(to: newPoint)
                    currentPoint = newPoint
                }

            case "H": // Horizontal line (absolute)
                if let x = scanNumber(scanner) {
                    let newPoint = CGPoint(x: x, y: currentPoint.y)
                    path.addLine(to: newPoint)
                    currentPoint = newPoint
                }

            case "h": // Horizontal line (relative)
                if let x = scanNumber(scanner) {
                    let newPoint = CGPoint(x: currentPoint.x + x, y: currentPoint.y)
                    path.addLine(to: newPoint)
                    currentPoint = newPoint
                }

            case "V": // Vertical line (absolute)
                if let y = scanNumber(scanner) {
                    let newPoint = CGPoint(x: currentPoint.x, y: y)
                    path.addLine(to: newPoint)
                    currentPoint = newPoint
                }

            case "v": // Vertical line (relative)
                if let y = scanNumber(scanner) {
                    let newPoint = CGPoint(x: currentPoint.x, y: currentPoint.y + y)
                    path.addLine(to: newPoint)
                    currentPoint = newPoint
                }

            case "Z", "z": // Close path
                path.close()
                currentPoint = startPoint

            default:
                break
            }
        }

        return path
    }

    private static func scanPoint(_ scanner: Scanner) -> CGPoint? {
        // 数値間の区切り文字をスキップ（スペース、改行、カンマ）
        scanner.charactersToBeSkipped = CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: ","))

        guard let x = scanner.scanDouble(),
              let y = scanner.scanDouble() else {
            return nil
        }
        return CGPoint(x: CGFloat(x), y: CGFloat(y))
    }

    private static func scanNumber(_ scanner: Scanner) -> CGFloat? {
        scanner.charactersToBeSkipped = CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: ","))
        if let number = scanner.scanDouble() {
            return CGFloat(number)
        }
        return nil
    }
}
