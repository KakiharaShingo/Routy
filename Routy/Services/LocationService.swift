//
//  LocationService.swift
//  Routy
//
//  Created by 垣原親伍 on 2025/12/18.
//

import Foundation
import CoreLocation

/// 位置情報サービスを管理するクラス
@MainActor
class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var currentLocation: CLLocationCoordinate2D?
    @Published var authorizationStatus: CLAuthorizationStatus

    override init() {
        self.authorizationStatus = locationManager.authorizationStatus
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    /// 位置情報権限をリクエスト
    /// - Returns: 権限が付与されたかどうか
    func requestLocationPermission() async -> Bool {
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            return true
        }

        locationManager.requestWhenInUseAuthorization()

        // 権限ダイアログの結果を待つ
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                let granted = self.authorizationStatus == .authorizedWhenInUse || self.authorizationStatus == .authorizedAlways
                continuation.resume(returning: granted)
            }
        }
    }

    /// 現在地を取得
    /// - Returns: CLLocationCoordinate2D、取得できない場合はnil
    func getCurrentLocation() async -> CLLocationCoordinate2D? {
        let hasPermission = await requestLocationPermission()
        guard hasPermission else {
            return nil
        }

        locationManager.startUpdatingLocation()

        // 最新の位置情報を待つ
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.locationManager.stopUpdatingLocation()
                continuation.resume(returning: self.currentLocation)
            }
        }
    }

    /// 位置情報の更新を開始
    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }

    /// 位置情報の更新を停止
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }

    // MARK: - CLLocationManagerDelegate

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            self.currentLocation = location.coordinate
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authorizationStatus = manager.authorizationStatus
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("[LocationService] エラー: \(error.localizedDescription)")
    }
}
