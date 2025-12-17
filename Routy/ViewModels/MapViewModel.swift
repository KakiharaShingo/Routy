//
//  MapViewModel.swift
//  Routy
//
//  Created by 垣原親伍 on 2025/12/18.
//

import Foundation
import SwiftData
import MapKit
import Observation
import SwiftUI

/// 地図画面のViewModel
@Observable
@MainActor
class MapViewModel {
    /// 現在の旅行
    var currentTrip: Trip?
    /// チェックポイントのリスト
    var checkpoints: [Checkpoint] = []
    /// 選択中のチェックポイント
    var selectedCheckpoint: Checkpoint?
    /// ローディング中かどうか
    var isLoading: Bool = false
    /// エラーメッセージ
    var errorMessage: String?
    /// カメラ位置
    var cameraPosition: MapCameraPosition = .automatic

    private let photoService: PhotoService
    private let geocodingService: GeocodingService
    private let modelContext: ModelContext

    init(modelContext: ModelContext, photoService: PhotoService = PhotoService(), geocodingService: GeocodingService = GeocodingService()) {
        self.modelContext = modelContext
        self.photoService = photoService
        self.geocodingService = geocodingService
    }

    /// 既存のTripに写真を追加
    /// - Parameters:
    ///   - trip: 対象のTrip
    ///   - startDate: 開始日
    ///   - endDate: 終了日
    func loadPhotosForTrip(trip: Trip, startDate: Date, endDate: Date) async {
        isLoading = true
        errorMessage = nil
        currentTrip = trip

        do {
            // 写真ライブラリの権限をリクエスト
            let hasAccess = await photoService.requestPhotoLibraryAccess()
            guard hasAccess else {
                errorMessage = "写真ライブラリへのアクセスが許可されていません"
                isLoading = false
                return
            }

            // 写真を取得
            let assets = await photoService.fetchPhotos(from: startDate, to: endDate)
            guard !assets.isEmpty else {
                errorMessage = "指定期間内に位置情報付きの写真が見つかりませんでした"
                isLoading = false
                return
            }

            // Checkpointを生成
            let newCheckpoints = await photoService.extractCheckpoints(from: assets)

            // 住所を取得(バッチ処理)
            for checkpoint in newCheckpoints {
                let address = await geocodingService.getAddress(for: checkpoint.coordinate())
                checkpoint.address = address
                checkpoint.trip = trip
                modelContext.insert(checkpoint)
                trip.checkpoints.append(checkpoint)
            }

            try modelContext.save()

            // 状態を更新
            checkpoints = trip.checkpoints

            // 地図の初期位置を設定
            centerMapOnCheckpoints()

        } catch {
            errorMessage = "写真の読み込みに失敗しました: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// 写真を読み込む（新規Trip作成）
    /// - Parameters:
    ///   - startDate: 開始日
    ///   - endDate: 終了日
    func loadPhotos(startDate: Date, endDate: Date) async {
        isLoading = true
        errorMessage = nil

        do {
            // 写真ライブラリの権限をリクエスト
            let hasAccess = await photoService.requestPhotoLibraryAccess()
            guard hasAccess else {
                errorMessage = "写真ライブラリへのアクセスが許可されていません"
                isLoading = false
                return
            }

            // 写真を取得
            let assets = await photoService.fetchPhotos(from: startDate, to: endDate)
            guard !assets.isEmpty else {
                errorMessage = "指定期間内に位置情報付きの写真が見つかりませんでした"
                isLoading = false
                return
            }

            // Checkpointを生成
            let newCheckpoints = await photoService.extractCheckpoints(from: assets)

            // 住所を取得(バッチ処理)
            for checkpoint in newCheckpoints {
                let address = await geocodingService.getAddress(for: checkpoint.coordinate())
                checkpoint.address = address
            }

            // SwiftDataに保存
            let trip = Trip(
                name: "旅行 \(DateFormatter.dateOnly.string(from: startDate))",
                startDate: startDate,
                endDate: endDate,
                checkpoints: newCheckpoints
            )

            modelContext.insert(trip)
            try modelContext.save()

            // 状態を更新
            currentTrip = trip
            checkpoints = newCheckpoints

            // 地図の初期位置を設定
            centerMapOnCheckpoints()

        } catch {
            errorMessage = "写真の読み込みに失敗しました: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// チェックポイントを選択
    /// - Parameter checkpoint: 選択するCheckpoint
    func selectCheckpoint(_ checkpoint: Checkpoint) {
        selectedCheckpoint = checkpoint

        // カメラ位置を調整
        cameraPosition = .camera(
            MapCamera(
                centerCoordinate: checkpoint.coordinate(),
                distance: 1000,
                heading: 0,
                pitch: 0
            )
        )
    }

    /// 全チェックポイントが見える範囲に地図を調整
    func centerMapOnCheckpoints() {
        guard !checkpoints.isEmpty else { return }
        print("DEBUG: centerMapOnCheckpoints called with \(checkpoints.count) checkpoints")

        let coordinates = checkpoints.map { $0.coordinate() }
        let rect = coordinates.reduce(MKMapRect.null) { rect, coordinate in
            let point = MKMapPoint(coordinate)
            let pointRect = MKMapRect(x: point.x, y: point.y, width: 0, height: 0)
            return rect.union(pointRect)
        }

        if rect.width == 0 || rect.height == 0 {
             // 1点のみ、または全ての点が同じ場所にある場合
            if let first = coordinates.first {
                print("DEBUG: Single point or zero size rect. Setting region.")
                let region = MKCoordinateRegion(center: first, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
                cameraPosition = .region(region)
            }
        } else {
             // 複数地点がある場合
            print("DEBUG: Setting rect with padding.")
            cameraPosition = .rect(rect.insetBy(dx: -rect.width * 0.1, dy: -rect.height * 0.1))
        }
    }

    /// チェックポイントを削除
    /// - Parameter checkpoint: 削除するCheckpoint
    func deleteCheckpoint(_ checkpoint: Checkpoint) {
        modelContext.delete(checkpoint)
        checkpoints.removeAll { $0.id == checkpoint.id }

        do {
            try modelContext.save()
        } catch {
            errorMessage = "チェックポイントの削除に失敗しました"
        }
    }

    /// チェックインを追加
    /// - Parameters:
    ///   - coordinate: 座標
    ///   - note: メモ
    func addCheckin(coordinate: CLLocationCoordinate2D, note: String?) async {
        isLoading = true

        let address = await geocodingService.getAddress(for: coordinate)

        let checkpoint = Checkpoint(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            timestamp: Date(),
            type: .manualCheckin,
            note: note,
            address: address,
            trip: currentTrip
        )

        modelContext.insert(checkpoint)
        checkpoints.append(checkpoint)

        do {
            try modelContext.save()
        } catch {
            errorMessage = "チェックインの保存に失敗しました"
        }

        isLoading = false
    }
}
