//
//  GeocodingService.swift
//  Routy
//
//  Created by 垣原親伍 on 2025/12/18.
//

import Foundation
import CoreLocation

/// 逆ジオコーディングサービス
class GeocodingService {
    private let geocoder = CLGeocoder()
    private var cache: [String: String] = [:]

    /// 座標から住所を取得
    /// - Parameter coordinate: CLLocationCoordinate2D
    /// - Returns: 住所文字列、取得できない場合はnil
    func getAddress(for coordinate: CLLocationCoordinate2D) async -> String? {
        let cacheKey = "\(coordinate.latitude),\(coordinate.longitude)"

        // キャッシュをチェック
        if let cachedAddress = cache[cacheKey] {
            return cachedAddress
        }

        // レート制限を考慮して少し待つ
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5秒

        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            guard let placemark = placemarks.first else {
                return nil
            }

            // 日本の住所フォーマット対応
            let address = formatAddress(from: placemark)
            cache[cacheKey] = address
            return address
        } catch {
            print("[GeocodingService] エラー: \(error.localizedDescription)")
            return nil
        }
    }

    /// Placemarkから住所文字列をフォーマット
    /// - Parameter placemark: CLPlacemark
    /// - Returns: フォーマットされた住所文字列
    private func formatAddress(from placemark: CLPlacemark) -> String {
        var addressComponents: [String] = []

        // 日本の住所の場合
        if placemark.isoCountryCode == "JP" {
            if let administrativeArea = placemark.administrativeArea {
                addressComponents.append(administrativeArea)
            }
            if let locality = placemark.locality {
                addressComponents.append(locality)
            }
            if let subLocality = placemark.subLocality {
                addressComponents.append(subLocality)
            }
            if let thoroughfare = placemark.thoroughfare {
                addressComponents.append(thoroughfare)
            }
        } else {
            // 海外の住所の場合
            if let name = placemark.name {
                addressComponents.append(name)
            }
            if let locality = placemark.locality {
                addressComponents.append(locality)
            }
            if let country = placemark.country {
                addressComponents.append(country)
            }
        }

        return addressComponents.isEmpty ? "不明な場所" : addressComponents.joined(separator: " ")
    }
}
