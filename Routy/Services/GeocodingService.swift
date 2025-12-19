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
    
    /// 座標から場所情報（名前と住所）を取得
    /// - Parameter coordinate: CLLocationCoordinate2D
    /// - Returns: (name: String?, address: String?)
    func getLocationInfo(for coordinate: CLLocationCoordinate2D) async -> (name: String?, address: String?) {
        let cacheKey = "\(coordinate.latitude),\(coordinate.longitude)"
        
        // 注: キャッシュは住所のみ保持しているため、ここでは単純にキャッシュヒットしても住所しか返せない
        // ただし、整合性を保つため、キャッシュがあればそれを使うが、nameは取れない可能性がある
        // 今回の要件（名前が欲しい）を優先し、キャッシュがあっても名前取得のために再リクエストも検討すべきだが
        // ここでは簡単に実装する
        
        // レート制限を考慮
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            guard let placemark = placemarks.first else {
                return (nil, nil)
            }
            
            let address = formatAddress(from: placemark)
            cache[cacheKey] = address
            
            // 名前（POI名や建物名）の取得
            // placemark.name は「東京都港区...」のような住所を含む場合もあるが、
            // areasOfInterestやnameが特定の建物名を示す場合がある
            var name: String? = nil
            
            if let areasOfInterest = placemark.areasOfInterest, let firstInterest = areasOfInterest.first {
                name = firstInterest
            } else if let placeName = placemark.name, placeName != placemark.thoroughfare, placeName != placemark.subThoroughfare {
                // nameが番地情報と一致しない場合、建物名である可能性が高い
                name = placeName
            }
            
            return (name, address)
            
        } catch {
            print("[GeocodingService] エラー: \(error.localizedDescription)")
            return (nil, nil)
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
