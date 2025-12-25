//
//  TestPhotoGenerator.swift
//  Routy
//
//  テスト用の位置情報付き写真を生成
//

import UIKit
import Photos
import CoreLocation
import ImageIO
import UniformTypeIdentifiers

/// テスト用の位置情報付き写真を生成してフォトライブラリに保存
class TestPhotoGenerator {

    /// カテゴリーテスト用の写真をフォトライブラリに保存
    static func generateCategoryTestPhotos(completion: @escaping (Result<Int, Error>) -> Void) {
        // フォトライブラリへのアクセス権限をリクエスト
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else {
                completion(.failure(NSError(domain: "TestPhotoGenerator", code: 1, userInfo: [NSLocalizedDescriptionKey: "写真ライブラリへのアクセスが許可されていません"])))
                return
            }

            let testLocations: [(String, CLLocationCoordinate2D, CheckpointCategory, UIColor)] = [
                ("レストラン", CLLocationCoordinate2D(latitude: 35.6585805, longitude: 139.7454329), .restaurant, .orange),
                ("カフェ", CLLocationCoordinate2D(latitude: 35.6617773, longitude: 139.7040506), .cafe, .brown),
                ("ガソリンスタンド", CLLocationCoordinate2D(latitude: 35.6938107, longitude: 139.7033677), .gasStation, .red),
                ("ホテル", CLLocationCoordinate2D(latitude: 35.6812362, longitude: 139.7671248), .hotel, .purple),
                ("浅草寺", CLLocationCoordinate2D(latitude: 35.7147651, longitude: 139.7966553), .tourist, .blue),
                ("上野公園", CLLocationCoordinate2D(latitude: 35.7148245, longitude: 139.7738466), .park, .green),
                ("銀座三越", CLLocationCoordinate2D(latitude: 35.6718285, longitude: 139.7654424), .shopping, .systemPink),
                ("東京駅", CLLocationCoordinate2D(latitude: 35.6812362, longitude: 139.7671248), .transport, .cyan),
                ("皇居", CLLocationCoordinate2D(latitude: 35.6851915, longitude: 139.7527995), .other, .gray),
            ]

            var savedCount = 0
            let group = DispatchGroup()

            for (index, (name, coordinate, category, color)) in testLocations.enumerated() {
                group.enter()

                // カテゴリーに応じた画像を生成
                let image = generateTestImage(
                    title: name,
                    subtitle: category.displayName,
                    icon: category.icon,
                    color: color,
                    index: index + 1
                )

                // 位置情報付きで保存
                saveImageToPhotoLibrary(
                    image: image,
                    location: coordinate,
                    date: Date().addingTimeInterval(TimeInterval(index * 1800))
                ) { success in
                    if success {
                        savedCount += 1
                    }
                    group.leave()
                }
            }

            group.notify(queue: .main) {
                print("✅ \(savedCount)枚の写真をフォトライブラリに保存しました")
                completion(.success(savedCount))
            }
        }
    }

    /// 拡張テスト用の写真を生成
    static func generateExtendedTestPhotos(completion: @escaping (Result<Int, Error>) -> Void) {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else {
                completion(.failure(NSError(domain: "TestPhotoGenerator", code: 1, userInfo: [NSLocalizedDescriptionKey: "写真ライブラリへのアクセスが許可されていません"])))
                return
            }

            let testLocations: [(String, CLLocationCoordinate2D, CheckpointCategory, UIColor)] = [
                // レストラン
                ("すし処 築地", CLLocationCoordinate2D(latitude: 35.6654861, longitude: 139.7706672), .restaurant, .orange),
                ("ラーメン一蘭", CLLocationCoordinate2D(latitude: 35.6617773, longitude: 139.7040506), .restaurant, .orange),
                ("鳥貴族", CLLocationCoordinate2D(latitude: 35.6938107, longitude: 139.7033677), .restaurant, .orange),

                // カフェ
                ("ブルーボトル", CLLocationCoordinate2D(latitude: 35.6658968, longitude: 139.7287262), .cafe, .brown),
                ("猿田彦珈琲", CLLocationCoordinate2D(latitude: 35.6617773, longitude: 139.7040506), .cafe, .brown),

                // ガソリンスタンド
                ("ENEOS", CLLocationCoordinate2D(latitude: 35.6851915, longitude: 139.6529773), .gasStation, .red),
                ("Shell", CLLocationCoordinate2D(latitude: 35.6585805, longitude: 139.7454329), .gasStation, .red),

                // ホテル
                ("ニューオータニ", CLLocationCoordinate2D(latitude: 35.6838107, longitude: 139.7395677), .hotel, .purple),
                ("パークハイアット", CLLocationCoordinate2D(latitude: 35.6855897, longitude: 139.6917064), .hotel, .purple),

                // 観光
                ("スカイツリー", CLLocationCoordinate2D(latitude: 35.7100627, longitude: 139.8107004), .tourist, .blue),
                ("明治神宮", CLLocationCoordinate2D(latitude: 35.6763976, longitude: 139.6993259), .tourist, .blue),
                ("江戸東京博物館", CLLocationCoordinate2D(latitude: 35.6965515, longitude: 139.7935626), .tourist, .blue),

                // 公園
                ("代々木公園", CLLocationCoordinate2D(latitude: 35.6719627, longitude: 139.6960553), .park, .green),
                ("お台場海浜公園", CLLocationCoordinate2D(latitude: 35.6300968, longitude: 139.7737262), .park, .green),

                // ショッピング
                ("東急ハンズ", CLLocationCoordinate2D(latitude: 35.6617773, longitude: 139.7040506), .shopping, .systemPink),
                ("ドン・キホーテ", CLLocationCoordinate2D(latitude: 35.6938107, longitude: 139.7033677), .shopping, .systemPink),

                // 交通
                ("新宿駅", CLLocationCoordinate2D(latitude: 35.6896342, longitude: 139.7005511), .transport, .cyan),
                ("羽田空港", CLLocationCoordinate2D(latitude: 35.5493932, longitude: 139.7798386), .transport, .cyan),

                // その他
                ("国会議事堂", CLLocationCoordinate2D(latitude: 35.6750396, longitude: 139.7449906), .other, .gray),
                ("東京タワー", CLLocationCoordinate2D(latitude: 35.6585805, longitude: 139.7454329), .other, .gray),
            ]

            var savedCount = 0
            let group = DispatchGroup()

            for (index, (name, coordinate, category, color)) in testLocations.enumerated() {
                group.enter()

                let image = generateTestImage(
                    title: name,
                    subtitle: category.displayName,
                    icon: category.icon,
                    color: color,
                    index: index + 1
                )

                saveImageToPhotoLibrary(
                    image: image,
                    location: coordinate,
                    date: Date().addingTimeInterval(TimeInterval(index * 1800))
                ) { success in
                    if success {
                        savedCount += 1
                    }
                    group.leave()
                }
            }

            group.notify(queue: .main) {
                print("✅ \(savedCount)枚の写真をフォトライブラリに保存しました")
                completion(.success(savedCount))
            }
        }
    }

    /// テスト用の画像を生成
    private static func generateTestImage(title: String, subtitle: String, icon: String, color: UIColor, index: Int) -> UIImage {
        let size = CGSize(width: 800, height: 600)

        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            // グラデーション背景
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [color.withAlphaComponent(0.8).cgColor, color.withAlphaComponent(0.4).cgColor] as CFArray,
                locations: [0.0, 1.0]
            )!

            context.cgContext.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: size.width, y: size.height),
                options: []
            )

            // アイコン
            if let iconImage = UIImage(systemName: icon) {
                let iconSize: CGFloat = 120
                let iconRect = CGRect(
                    x: (size.width - iconSize) / 2,
                    y: size.height * 0.25,
                    width: iconSize,
                    height: iconSize
                )

                let config = UIImage.SymbolConfiguration(pointSize: iconSize, weight: .light)
                let scaledIcon = iconImage.applyingSymbolConfiguration(config)

                UIColor.white.withAlphaComponent(0.9).setFill()
                scaledIcon?.draw(in: iconRect, blendMode: .normal, alpha: 0.9)
            }

            // タイトル
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 48),
                .foregroundColor: UIColor.white
            ]
            let titleString = NSAttributedString(string: title, attributes: titleAttributes)
            let titleRect = CGRect(
                x: 40,
                y: size.height * 0.55,
                width: size.width - 80,
                height: 60
            )
            titleString.draw(in: titleRect)

            // サブタイトル
            let subtitleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 32),
                .foregroundColor: UIColor.white.withAlphaComponent(0.8)
            ]
            let subtitleString = NSAttributedString(string: subtitle, attributes: subtitleAttributes)
            let subtitleRect = CGRect(
                x: 40,
                y: size.height * 0.65,
                width: size.width - 80,
                height: 40
            )
            subtitleString.draw(in: subtitleRect)

            // インデックス番号
            let indexAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedSystemFont(ofSize: 24, weight: .medium),
                .foregroundColor: UIColor.white.withAlphaComponent(0.6)
            ]
            let indexString = NSAttributedString(string: "#\(index)", attributes: indexAttributes)
            let indexRect = CGRect(
                x: size.width - 100,
                y: size.height - 50,
                width: 80,
                height: 30
            )
            indexString.draw(in: indexRect)
        }

        return image
    }

    /// 位置情報付きで画像をフォトライブラリに保存
    private static func saveImageToPhotoLibrary(image: UIImage, location: CLLocationCoordinate2D, date: Date, completion: @escaping (Bool) -> Void) {
        PHPhotoLibrary.shared().performChanges({
            let creationRequest = PHAssetCreationRequest.forAsset()
            creationRequest.addResource(with: .photo, data: image.jpegData(compressionQuality: 0.9)!, options: nil)
            creationRequest.location = CLLocation(latitude: location.latitude, longitude: location.longitude)
            creationRequest.creationDate = date
        }) { success, error in
            if let error = error {
                print("❌ 写真の保存に失敗: \(error)")
            }
            completion(success)
        }
    }
}
