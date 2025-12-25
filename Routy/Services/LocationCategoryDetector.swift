//
//  LocationCategoryDetector.swift
//  Routy
//
//  位置情報から施設カテゴリを自動判定するサービス
//

import Foundation
import MapKit
import CoreLocation

/// 位置情報から施設のカテゴリを判定するサービス
class LocationCategoryDetector {
    static let shared = LocationCategoryDetector()

    private init() {}

    /// 位置情報から施設カテゴリを自動判定
    /// - Parameters:
    ///   - coordinate: 座標
    ///   - timestamp: 写真の撮影時刻（オプション）
    ///   - completion: 判定結果のコールバック（nilの場合は判定不可）
    func detectCategory(at coordinate: CLLocationCoordinate2D, timestamp: Date? = nil, completion: @escaping (CheckpointCategory?) -> Void) {
        // 検索範囲を100mに縮小して高速化
        let region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: 100,
            longitudinalMeters: 100
        )

        let request = MKLocalPointsOfInterestRequest(coordinateRegion: region)
        let search = MKLocalSearch(request: request)

        // タイムアウト処理（5秒）
        var hasCompleted = false
        let timeoutWorkItem = DispatchWorkItem {
            if !hasCompleted {
                hasCompleted = true
                search.cancel()
                completion(.other)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: timeoutWorkItem)

        search.start { response, error in
            guard !hasCompleted else { return }
            hasCompleted = true
            timeoutWorkItem.cancel()

            guard let response = response, error == nil else {
                completion(.other)
                return
            }

            // 最も近い施設を取得（最大3件まで確認して高速化）
            let targetLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            let sortedItems = response.mapItems
                .prefix(3)
                .sorted { item1, item2 in
                    let location1 = item1.placemark.location ?? CLLocation(latitude: 0, longitude: 0)
                    let location2 = item2.placemark.location ?? CLLocation(latitude: 0, longitude: 0)
                    return location1.distance(from: targetLocation) < location2.distance(from: targetLocation)
                }

            // 施設が見つからない場合は時刻とコンテキストで推測
            guard let nearestItem = sortedItems.first else {
                let guessedCategory = self.guessCategoryByContext(
                    itemCount: response.mapItems.count,
                    timestamp: timestamp
                )
                completion(guessedCategory)
                return
            }

            // 名前ベースの判定を優先、その後MapKitのカテゴリで補完
            var category = self.categorizeByName(nearestItem) ?? self.categorizeByPOI(nearestItem)

            // 「その他」と判定された場合は、時刻情報で補完を試みる
            if category == .other, let timestamp = timestamp {
                if let timeBasedCategory = self.guessCategoryByTime(timestamp) {
                    category = timeBasedCategory
                }
            }

            completion(category)
        }
    }

    /// 名前から施設カテゴリを判定（優先）
    private func categorizeByName(_ mapItem: MKMapItem) -> CheckpointCategory? {
        let name = mapItem.name?.lowercased() ?? ""

        // 交通機関（駅・空港）- 最優先で判定
        if name.contains("駅") || (name.contains("station") && !name.contains("gas") && !name.contains("ガソリン")) {
            return .transport
        }
        if name.contains("空港") || name.contains("airport") {
            return .transport
        }
        if name.contains("バスターミナル") || name.contains("bus terminal") || name.contains("bus stop") {
            return .transport
        }
        if name.contains("高速バス") || name.contains("highway bus") {
            return .transport
        }

        // ビル・オフィス・駐車場 - 「その他」として判定
        if name.contains("ビル") || name.contains("building") || name.contains("オフィス") || name.contains("office") {
            return .other
        }
        if name.contains("駐車場") || name.contains("parking") || name.contains("パーキング") {
            return .other
        }

        // 飲食店（麺類）
        if name.contains("ラーメン") || name.contains("ramen") || name.contains("らーめん") {
            return .restaurant
        }
        if name.contains("うどん") || name.contains("udon") || name.contains("そば") || name.contains("蕎麦") || name.contains("soba") {
            return .restaurant
        }
        if name.contains("パスタ") || name.contains("pasta") || name.contains("スパゲッティ") || name.contains("spaghetti") {
            return .restaurant
        }

        // 飲食店（肉料理）
        if name.contains("焼肉") || name.contains("焼き肉") || name.contains("yakiniku") {
            return .restaurant
        }
        if name.contains("ステーキ") || name.contains("steak") {
            return .restaurant
        }
        if name.contains("とんかつ") || name.contains("豚カツ") || name.contains("tonkatsu") {
            return .restaurant
        }
        if name.contains("から揚げ") || name.contains("からあげ") || name.contains("唐揚げ") {
            return .restaurant
        }

        // 飲食店（和食）
        if name.contains("寿司") || name.contains("すし") || name.contains("sushi") {
            return .restaurant
        }
        if name.contains("天ぷら") || name.contains("天麩羅") || name.contains("tempura") {
            return .restaurant
        }
        if name.contains("定食") || name.contains("teishoku") {
            return .restaurant
        }
        if name.contains("和食") || name.contains("日本料理") {
            return .restaurant
        }

        // 飲食店（洋食・中華）
        if name.contains("イタリアン") || name.contains("italian") || name.contains("フレンチ") || name.contains("french") {
            return .restaurant
        }
        if name.contains("中華") || name.contains("chinese") || name.contains("餃子") || name.contains("gyoza") {
            return .restaurant
        }

        // 飲食店（ファストフード・チェーン）
        if name.contains("マクドナルド") || name.contains("mcdonald") || name.contains("マック") {
            return .restaurant
        }
        if name.contains("ケンタッキー") || name.contains("kfc") {
            return .restaurant
        }
        if name.contains("モスバーガー") || name.contains("mos burger") {
            return .restaurant
        }
        if name.contains("すき家") || name.contains("sukiya") || name.contains("吉野家") || name.contains("yoshinoya") || name.contains("松屋") || name.contains("matsuya") {
            return .restaurant
        }

        // 飲食店（その他）
        if name.contains("居酒屋") || name.contains("izakaya") {
            return .restaurant
        }
        if name.contains("レストラン") || name.contains("restaurant") || name.contains("食堂") || name.contains("dining") {
            return .restaurant
        }
        if name.contains("ビストロ") || name.contains("bistro") || name.contains("バル") || name.contains("bar") && !name.contains("バス") {
            return .restaurant
        }

        // カフェ・喫茶店
        if name.contains("カフェ") || name.contains("cafe") || name.contains("喫茶") {
            return .cafe
        }
        if name.contains("コーヒー") || name.contains("coffee") || name.contains("珈琲") {
            return .cafe
        }
        if name.contains("スタバ") || name.contains("starbucks") {
            return .cafe
        }
        if name.contains("ドトール") || name.contains("doutor") {
            return .cafe
        }
        if name.contains("コメダ") || name.contains("komeda") {
            return .cafe
        }
        if name.contains("タリーズ") || name.contains("tully") {
            return .cafe
        }
        if name.contains("サンマルク") || name.contains("saint marc") {
            return .cafe
        }

        // 観光地（文化施設）
        if name.contains("博物館") || name.contains("museum") {
            return .tourist
        }
        if name.contains("美術館") || name.contains("gallery") || name.contains("ギャラリー") {
            return .tourist
        }
        if name.contains("科学館") || name.contains("プラネタリウム") || name.contains("planetarium") {
            return .tourist
        }

        // 観光地（宗教施設）
        if name.contains("神社") || name.contains("shrine") || name.contains("大社") {
            return .tourist
        }
        if name.contains("寺") || name.contains("temple") || name.contains("お寺") {
            return .tourist
        }
        if name.contains("教会") || name.contains("church") {
            return .tourist
        }

        // 観光地（歴史的建造物）
        if name.contains("城") || name.contains("castle") {
            return .tourist
        }
        if name.contains("タワー") || name.contains("tower") {
            return .tourist
        }
        if name.contains("展望台") || name.contains("observatory") {
            return .tourist
        }

        // 観光地（自然・レジャー）
        if name.contains("水族館") || name.contains("aquarium") {
            return .tourist
        }
        if name.contains("動物園") || name.contains("zoo") {
            return .tourist
        }
        if name.contains("植物園") || name.contains("botanical") {
            return .tourist
        }
        if name.contains("遊園地") || name.contains("amusement") || name.contains("テーマパーク") {
            return .tourist
        }
        if name.contains("道の駅") {
            return .tourist
        }

        // 公園
        if name.contains("公園") || (name.contains("park") && !name.contains("parking")) {
            return .park
        }
        if name.contains("広場") || name.contains("plaza") {
            return .park
        }

        // ホテル・宿泊施設
        if name.contains("ホテル") || name.contains("hotel") {
            return .hotel
        }
        if name.contains("旅館") || name.contains("ryokan") {
            return .hotel
        }
        if name.contains("民宿") || name.contains("ゲストハウス") || name.contains("guest house") {
            return .hotel
        }
        if name.contains("リゾート") || name.contains("resort") {
            return .hotel
        }

        // ショッピング（モール・百貨店）
        if name.contains("イオン") || name.contains("aeon") {
            return .shopping
        }
        if name.contains("ららぽーと") || name.contains("lalaport") {
            return .shopping
        }
        if name.contains("モール") || name.contains("mall") {
            return .shopping
        }
        if name.contains("アウトレット") || name.contains("outlet") {
            return .shopping
        }
        if name.contains("百貨店") || name.contains("デパート") || name.contains("department") {
            return .shopping
        }
        if name.contains("そごう") || name.contains("sogo") || name.contains("西武") || name.contains("seibu") {
            return .shopping
        }

        // ショッピング（専門店）
        if name.contains("コンビニ") || name.contains("convenience") || name.contains("セブン") || name.contains("seven") || name.contains("ローソン") || name.contains("lawson") || name.contains("ファミマ") || name.contains("familymart") {
            return .shopping
        }
        if name.contains("スーパー") || name.contains("supermarket") {
            return .shopping
        }
        if name.contains("ドラッグストア") || name.contains("drug store") || name.contains("薬局") {
            return .shopping
        }

        // ガソリンスタンド
        if name.contains("ガソリン") || name.contains("gas station") || name.contains("給油") {
            return .gasStation
        }
        if name.contains("エネオス") || name.contains("eneos") {
            return .gasStation
        }
        if name.contains("出光") || name.contains("idemitsu") || name.contains("コスモ") || name.contains("cosmo") {
            return .gasStation
        }

        return nil // 名前から判定できない場合はnil
    }

    /// POIカテゴリから施設カテゴリを判定（補助）
    private func categorizeByPOI(_ mapItem: MKMapItem) -> CheckpointCategory {
        guard let category = mapItem.pointOfInterestCategory else {
            return .other
        }

        switch category {
        case .restaurant:
            return .restaurant
        case .cafe, .bakery:
            return .cafe
        case .gasStation, .evCharger:
            return .gasStation
        case .hotel:
            return .hotel
        case .museum, .aquarium, .zoo, .amusementPark, .campground, .landmark, .stadium, .movieTheater, .theater:
            return .tourist
        case .park, .beach, .nationalPark:
            return .park
        case .store, .foodMarket, .brewery, .winery:
            return .shopping
        case .airport, .publicTransport:
            return .transport
        default:
            return .other
        }
    }

    /// 時刻から施設カテゴリを推測
    private func guessCategoryByTime(_ timestamp: Date) -> CheckpointCategory? {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: timestamp)

        // 深夜・早朝（0-6時、23時以降）→ ホテル可能性高
        if hour < 6 || hour >= 23 {
            return .hotel
        }

        // 朝食時間（7-9時）→ カフェまたはレストラン
        if (7...9).contains(hour) {
            return .cafe
        }

        // 昼食時間（11-14時）→ レストラン
        if (11...14).contains(hour) {
            return .restaurant
        }

        // カフェ時間（15-17時）→ カフェ
        if (15...17).contains(hour) {
            return .cafe
        }

        // 夕食時間（18-21時）→ レストラン
        if (18...21).contains(hour) {
            return .restaurant
        }

        // 日中（10-17時）→ 観光地可能性高
        if (10...17).contains(hour) {
            return .tourist
        }

        return nil
    }

    /// コンテキストから施設カテゴリを推測
    private func guessCategoryByContext(itemCount: Int, timestamp: Date?) -> CheckpointCategory {
        // 周辺に施設が全くない場合
        if itemCount == 0 {
            // 時刻で判定
            if let timestamp = timestamp, let timeCategory = guessCategoryByTime(timestamp) {
                return timeCategory
            }
            // それでも判定できない場合は自然スポット扱い
            return .park
        }

        // 周辺に多数の施設がある場合（5件以上）→ 複合施設やビルの可能性
        if itemCount >= 5 {
            // 時刻で推測してみる
            if let timestamp = timestamp, let timeCategory = guessCategoryByTime(timestamp) {
                return timeCategory
            }
            return .other
        }

        // それ以外
        return .other
    }
}
