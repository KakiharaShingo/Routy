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
    
    // MARK: - Logic Properties
    
    /// 全行程の総距離 (メートル)
    private var totalDistance: Double = 0.0
    /// 各区間の距離 (メートル)
    private var segmentDistances: [Double] = []
    
    /// 現在の経過距離 (メートル)
    private var currentDistance: Double = 0.0
    
    /// アニメーションの基準速度 (メートル/秒)
    /// 例えば、地図上の距離感として「秒速500km」相当で進むなど
    /// ここでは、総距離を「デフォルト10秒」で走破する速度を基準とする
    private var baseSpeedMPS: Double = 0.0

    private var timer: Timer?
    /// フレームレート (秒)
    private let frameRate: TimeInterval = 0.02

    init(checkpoints: [Checkpoint] = []) {
        self.checkpoints = checkpoints.sorted { $0.timestamp < $1.timestamp }
        self.routeCoordinates = self.checkpoints.map { $0.coordinate() }
        
        calculateDistances()
        
        if let first = self.checkpoints.first {
            self.currentCoordinate = first.coordinate()
        }
    }
    
    /// 距離計算
    private func calculateDistances() {
        guard routeCoordinates.count > 1 else { return }
        
        segmentDistances = []
        totalDistance = 0.0
        
        for i in 0..<routeCoordinates.count - 1 {
            let start = routeCoordinates[i]
            let end = routeCoordinates[i+1]
            let distance = distanceBetween(start, end)
            segmentDistances.append(distance)
            totalDistance += distance
        }
        
        // 基準速度: 全行程を45秒で完走する速度 (だいぶゆっくりに)
        if totalDistance > 0 {
            baseSpeedMPS = totalDistance / 45.0 // 45秒
        }
    }

    /// アニメーションを開始
    func startAnimation() {
        guard !checkpoints.isEmpty, totalDistance > 0 else { return }

        isPlaying = true
        timer?.invalidate()

        // let lastUpdate = Date() // This line was in the provided snippet but not used. Removed for cleanliness.
        
        timer = Timer.scheduledTimer(withTimeInterval: frameRate, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateAnimation()
            }
        }
    }

    /// アニメーション更新（1フレームごと）
    private func updateAnimation() {
        guard currentDistance < totalDistance else {
            pauseAnimation()
            currentDistance = totalDistance
            currentCoordinate = routeCoordinates.last
            return
        }

        // 進む距離 = 速度 * 時間 * 倍率
        let stepDistance = baseSpeedMPS * frameRate * animationSpeed
        currentDistance += stepDistance
        
        if currentDistance >= totalDistance {
            currentDistance = totalDistance
            currentCoordinate = routeCoordinates.last
            pauseAnimation()
            return
        }
        
        // 現在の距離に対応する座標を計算
        updateCoordinate(for: currentDistance)
    }
    
    /// 距離から座標を特定する
    private func updateCoordinate(for distance: Double) {
        var distanceRemaining = distance
        
        for (index, segmentDist) in segmentDistances.enumerated() {
            if distanceRemaining <= segmentDist {
                // このセグメント内にいる
                let progress = distanceRemaining / segmentDist
                let start = routeCoordinates[index]
                let end = routeCoordinates[index+1]
                
                currentCoordinate = interpolateHelper(from: start, to: end, fraction: progress)
                return
            } else {
                distanceRemaining -= segmentDist
            }
        }
        
        // 誤差対策（最後）
        currentCoordinate = routeCoordinates.last
    }
    
    /// 2点間の距離 (メートル) - 簡易計算 (Haversine相当あるいはMKMapPoint)
    private func distanceBetween(_ c1: CLLocationCoordinate2D, _ c2: CLLocationCoordinate2D) -> Double {
        let p1 = MKMapPoint(c1)
        let p2 = MKMapPoint(c2)
        return p1.distance(to: p2)
    }
    
    /// 座標の線形補間
    private func interpolateHelper(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D, fraction: Double) -> CLLocationCoordinate2D {
        let lat = start.latitude + (end.latitude - start.latitude) * fraction
        let lon = start.longitude + (end.longitude - start.longitude) * fraction
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    /// アニメーションを一時停止
    func pauseAnimation() {
        isPlaying = false
        timer?.invalidate()
        timer = nil
    }

    /// アニメーションをリセット
    func resetAnimation() {
        pauseAnimation()
        currentDistance = 0.0
        if let first = checkpoints.first {
            currentCoordinate = first.coordinate()
        }
    }

    /// 速度を設定
    func setSpeed(_ speed: Double) {
        animationSpeed = speed
    }
    
    // View側で進捗バーを出すためのヘルパー
    var progressValue: Double {
        guard totalDistance > 0 else { return 0 }
        return currentDistance / totalDistance
    }
}
