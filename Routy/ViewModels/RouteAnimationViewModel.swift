//
//  RouteAnimationViewModel.swift
//  Routy
//
//  Created by 垣原親伍 on 2025/12/18.
//

import Foundation
import MapKit
import Observation

/// 経路アニメーションのViewModel
@Observable
@MainActor
class RouteAnimationViewModel {
    /// チェックポイントのリスト
    var checkpoints: [Checkpoint] = []
    
    /// 現在の補間された座標
    var currentCoordinate: CLLocationCoordinate2D?
    
    /// 再生中かどうか
    var isPlaying: Bool = false
    /// アニメーション速度倍率 (1.0 = 標準速度)
    var animationSpeed: Double = 1.0
    
    /// 経路の全座標リスト
    var routeCoordinates: [CLLocationCoordinate2D] = []
    
    /// 各区間の移動手段リスト (routeCoordinatesの要素数 - 1)
    var routeSegmentTypes: [TransportMode] = []
    
    /// 進捗 (0.0 - 1.0) - View側（SmoothRouteMapView）から更新される
    var progressValue: Double = 0.0

    // MARK: - Transport Mode
    enum TransportMode: String, CaseIterable, Identifiable {
        case straight = "直線"
        case walk = "徒歩"
        case car = "車"
        case train = "電車"
        case plane = "飛行機"
        
        var id: String { rawValue }
        
        var systemIcon: String {
            switch self {
            case .straight: return "line.diagonal"
            case .walk: return "figure.walk"
            case .car: return "car.fill"
            case .train: return "tram.fill"
            case .plane: return "airplane"
            }
        }
    }
    
    var transportMode: TransportMode = .straight {
        didSet {
            // Reset animation when transport mode changes
            isPlaying = false
            progressValue = 0.0
            if let first = checkpoints.first {
                currentCoordinate = first.coordinate()
            }
            Task { await calculateRoute() }
        }
    }
    
    var isCalculating: Bool = false
    
    init(checkpoints: [Checkpoint] = []) {
        self.checkpoints = checkpoints.sorted { $0.timestamp < $1.timestamp }
        let coords = self.checkpoints.map { $0.coordinate() }
        self.routeCoordinates = coords
        if coords.count > 1 {
            self.routeSegmentTypes = Array(repeating: .straight, count: coords.count - 1)
        }
        
        if let first = self.checkpoints.first {
            currentCoordinate = first.coordinate()
        }
    }

    // MARK: - API
    
    func startAnimation() {
        if routeCoordinates.isEmpty {
            Task { await calculateRoute() }
        }
        isPlaying = true
    }
    
    /// ルート再計算
    func calculateRoute() async {
        guard checkpoints.count > 1 else { return }
        isCalculating = true
        defer { isCalculating = false }
        
        // 直線の場合は単純な座標リスト
        if transportMode == .straight {
            let coords = checkpoints.map { $0.coordinate() }
            self.routeCoordinates = coords
            self.routeSegmentTypes = Array(repeating: .straight, count: max(0, coords.count - 1))
            return
        }
        
        // Segments to calculate
        let segmentsCount = checkpoints.count - 1
        // Placeholder for results: [Index: (Coordinates, Types)]
        // Serial processing to avoid "Throttled Directions request" (Limit: 50 req/60s)
        var segmentResults: [Int: ([CLLocationCoordinate2D], [TransportMode])] = [:]
        
        for i in 0..<segmentsCount {
            let start = checkpoints[i]
            let end = checkpoints[i+1]
            let mode = transportMode
            
            // Check cancellation
            if Task.isCancelled { return }
            
            let result = await self.fetchSegment(start: start, end: end, mode: mode)
            segmentResults[i] = result
            
            // Add minimal delay for API-based modes to prevent throttling
            // Apple Maps limit: 50 req/60s = ~1.2s per request worst case
            // Using 50ms delay allows ~20 req/s, well within limits
            if mode == .walk || mode == .car || mode == .train {
                try? await Task.sleep(nanoseconds: 50_000_000) // 0.05s delay
            }
        }
        
        // Assemble sorted segments
        var finalCoordinates: [CLLocationCoordinate2D] = []
        var finalTypes: [TransportMode] = []
        
        if let first = checkpoints.first {
            finalCoordinates.append(first.coordinate())
        }
        
        for i in 0..<segmentsCount {
            if let (coords, types) = segmentResults[i] {
                if coords.count > 1 {
                    finalCoordinates.append(contentsOf: coords.dropFirst())
                    finalTypes.append(contentsOf: types)
                } else if let end = coords.last {
                     if finalCoordinates.last?.latitude != end.latitude {
                         finalCoordinates.append(end)
                         finalTypes.append(transportMode)
                     }
                }
            }
        }
        
        self.routeCoordinates = finalCoordinates
        self.routeSegmentTypes = finalTypes
        
        // Reset current coordinate to start
        if let first = finalCoordinates.first {
            currentCoordinate = first
        }
    }
    
    /// Calculate single segment
    private func fetchSegment(start: Checkpoint, end: Checkpoint, mode: TransportMode) async -> ([CLLocationCoordinate2D], [TransportMode]) {
        let startCoord = start.coordinate()
        let endCoord = end.coordinate()
        
        switch mode {
        case .walk, .car:
            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: startCoord))
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: endCoord))
            request.transportType = mode == .walk ? .walking : .automobile
            
            do {
                let directions = MKDirections(request: request)
                let response = try await directions.calculate()
                if let route = response.routes.first {
                    let coords = route.polyline.coordinates()
                    let types = Array(repeating: mode, count: max(0, coords.count - 1))
                    return (coords, types)
                }
            } catch {
                // Ignore error
            }
            return ([startCoord, endCoord], [mode])
            
        case .plane:
            let geodesic = MKGeodesicPolyline(coordinates: [startCoord, endCoord], count: 2)
            let coords = geodesic.coordinates()
            let types = Array(repeating: mode, count: max(0, coords.count - 1))
            return (coords, types)
            
        case .train:
            // Try Transit API first (may not be available in all regions)
            let transitRequest = MKDirections.Request()
            transitRequest.source = MKMapItem(placemark: MKPlacemark(coordinate: startCoord))
            transitRequest.destination = MKMapItem(placemark: MKPlacemark(coordinate: endCoord))
            transitRequest.transportType = .transit
            transitRequest.requestsAlternateRoutes = true

            do {
                let directions = MKDirections(request: transitRequest)
                let response = try await directions.calculate()

                // Find route with most transit steps
                var bestRoute: MKRoute?
                var maxTransitSteps = 0

                for route in response.routes {
                    let transitStepCount = route.steps.filter { $0.transportType == .transit }.count
                    if transitStepCount > maxTransitSteps {
                        maxTransitSteps = transitStepCount
                        bestRoute = route
                    }
                }

                if let route = bestRoute ?? response.routes.first, maxTransitSteps > 0 {
                    var fullCoords: [CLLocationCoordinate2D] = []
                    var fullTypes: [TransportMode] = []

                    print("🚉 Real transit route: \(route.steps.count) steps (\(maxTransitSteps) transit)")

                    for (index, step) in route.steps.enumerated() {
                        let stepCoords = step.polyline.coordinates()
                        if stepCoords.isEmpty { continue }

                        var stepMode: TransportMode = .train
                        if step.transportType == .walking {
                            stepMode = .walk
                        } else if step.transportType == .transit {
                            stepMode = .train
                        }

                        if index == 0 {
                            fullCoords.append(contentsOf: stepCoords)
                            fullTypes.append(contentsOf: Array(repeating: stepMode, count: max(0, stepCoords.count - 1)))
                        } else {
                            if stepCoords.count > 0 {
                                fullCoords.append(contentsOf: stepCoords.dropFirst())
                                fullTypes.append(contentsOf: Array(repeating: stepMode, count: max(0, stepCoords.count - 1)))
                            }
                        }
                    }

                    if !fullCoords.isEmpty {
                        let walkCount = fullTypes.filter { $0 == .walk }.count
                        let trainCount = fullTypes.filter { $0 == .train }.count
                        print("✅ Transit: Walk \(walkCount), Train \(trainCount)")
                        return (fullCoords, fullTypes)
                    }
                }
            } catch {
                // Transit API failed - fall through to walking route
            }

            // Fallback: Use walking route with simulated train sections
            print("🚇 Transit unavailable, using walking route with train simulation")

            let walkRequest = MKDirections.Request()
            walkRequest.source = MKMapItem(placemark: MKPlacemark(coordinate: startCoord))
            walkRequest.destination = MKMapItem(placemark: MKPlacemark(coordinate: endCoord))
            walkRequest.transportType = .walking

            do {
                let directions = MKDirections(request: walkRequest)
                let response = try await directions.calculate()

                if let route = response.routes.first {
                    let allCoords = route.polyline.coordinates()

                    // Simulate train route: walk 10% → train 80% → walk 10%
                    var fullTypes: [TransportMode] = []
                    let totalPoints = allCoords.count

                    for i in 0..<(totalPoints - 1) {
                        let progress = Double(i) / Double(totalPoints - 1)
                        if progress < 0.1 {
                            fullTypes.append(.walk)
                        } else if progress < 0.9 {
                            fullTypes.append(.train)
                        } else {
                            fullTypes.append(.walk)
                        }
                    }

                    let walkCount = fullTypes.filter { $0 == .walk }.count
                    let trainCount = fullTypes.filter { $0 == .train }.count
                    print("✅ Simulated: Walk \(walkCount) (\(walkCount*100/totalPoints)%), Train \(trainCount) (\(trainCount*100/totalPoints)%)")
                    return (allCoords, fullTypes)
                }
            } catch {
                // Walking also failed
            }

            // Final fallback
            print("⚠️ All routing failed, using straight line")
            return ([startCoord, endCoord], [.straight])
            
        case .straight:
            return ([startCoord, endCoord], [.straight])
        }
    }

    /// 速度を設定
    func setSpeed(_ speed: Double) {
        animationSpeed = speed
    }

    /// アニメーションを一時停止
    func pauseAnimation() {
        isPlaying = false
    }

    /// アニメーションをリセット
    func resetAnimation() {
        isPlaying = false
        progressValue = 0.0
        if let first = routeCoordinates.first {
            currentCoordinate = first
        }
    }
}

// Helper Extension for MKPolyline
extension MKPolyline {
    func coordinates() -> [CLLocationCoordinate2D] {
        var coords = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid, count: pointCount)
        getCoordinates(&coords, range: NSRange(location: 0, length: pointCount))
        return coords
    }
}
