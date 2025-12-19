//
//  LocationSearchService.swift
//  Routy
//
//  Created by Auto-generated on 2025/12/19.
//

import Foundation
import MapKit
import Combine

/// 場所検索結果を表す構造体
struct LocationSearchResult: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let subtitle: String
    let coordinate: CLLocationCoordinate2D
    let mapItem: MKMapItem
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // Equatable conformance
    static func == (lhs: LocationSearchResult, rhs: LocationSearchResult) -> Bool {
        return lhs.id == rhs.id
    }
}

/// 場所検索サービス
@MainActor
class LocationSearchService: NSObject, ObservableObject {
    @Published var searchResults: [LocationSearchResult] = []
    @Published var searchQuery = ""
    
    private var cancellables = Set<AnyCancellable>()
    private var region: MKCoordinateRegion?
    
    override init() {
        super.init()
        
        // 検索クエリの変更を監視して検索実行（デバウンス付）
        $searchQuery
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                Task {
                    await self?.search(query: query)
                }
            }
            .store(in: &cancellables)
    }
    
    /// 検索範囲を設定
    func setRegion(_ region: MKCoordinateRegion) {
        self.region = region
    }
    
    /// 検索を実行
    func search(query: String) async {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = .pointOfInterest
        
        if let region = region {
            request.region = region
        }
        
        let search = MKLocalSearch(request: request)
        
        do {
            let response = try await search.start()
            
            searchResults = response.mapItems.map { item in
                LocationSearchResult(
                    title: item.name ?? "名称不明",
                    subtitle: item.placemark.title ?? "",
                    coordinate: item.placemark.coordinate,
                    mapItem: item
                )
            }
        } catch {
            print("Search error: \(error.localizedDescription)")
            searchResults = []
        }
    }
    
    /// 特定の場所（周辺スポット）を検索
    /// - Parameter query: 検索キーワード（例："カフェ", "駅"）
    func searchNearby(query: String, region: MKCoordinateRegion) async {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = region
        
        let search = MKLocalSearch(request: request)
        
        do {
            let response = try await search.start()
            searchResults = response.mapItems.map { item in
                LocationSearchResult(
                    title: item.name ?? "名称不明",
                    subtitle: item.placemark.title ?? "",
                    coordinate: item.placemark.coordinate,
                    mapItem: item
                )
            }
        } catch {
            print("Nearby search error: \(error.localizedDescription)")
            // エラー時はリストをクリアしない（前回の結果を残すか、空にするかは要件次第だが、空にする）
            searchResults = []
        }
    }

    
    /// 座標から周辺のPOI（施設名）を検索する（逆ジオコードの代替）
    func lookupPOI(at coordinate: CLLocationCoordinate2D) async -> String? {
        // iOS 14+ MKLocalPointsOfInterestRequest
        let request = MKLocalPointsOfInterestRequest(center: coordinate, radius: 100) // 半径100m
        request.pointOfInterestFilter = .init(excluding: []) // 全て含める
        
        do {
            let search = MKLocalSearch(request: request)
            let response = try await search.start()
            
            // 最も近い場所を探す
            if let firstItem = response.mapItems.first {
                return firstItem.name
            }
            return nil
        } catch {
            print("POI lookup error: \(error.localizedDescription)")
            return nil
        }
    }
}
