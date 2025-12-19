# TravelLogApp - Firebase データベース設計・実装ガイド

このドキュメントは、旅ログアプリ「Antigravity」のFirebase実装のための完全ガイドです。

---

## 🎯 データベース戦略の概要

### アーキテクチャ
```
ローカルストレージ（SwiftData）
    ↕️ 同期
クラウドストレージ（Firebase）
```

### データ配置戦略
- **ローカル（SwiftData）**: メインデータストア、オフライン動作
- **Firebase Firestore**: バックアップ、デバイス間同期、共有機能
- **Firebase Storage**: 写真サムネイルのみ（オリジナルはiCloud/ローカル）
- **Firebase Authentication**: ユーザー認証

---

## 📊 Firebaseの制限とスケール

### 無料枠（Spark Plan）
```
Firestore:
├─ 書込: 20,000 / 日
├─ 読取: 50,000 / 日
├─ 削除: 20,000 / 日
└─ ストレージ: 1GB

Storage:
├─ 保存: 5GB
└─ ダウンロード: 1GB / 日

Authentication:
└─ 無制限
```

### 対応可能なスケール

#### 無料枠
```
✅ デイリーアクティブユーザー: 300-1,500人
✅ 総登録ユーザー: 1,000-10,000人
✅ 個人開発・MVP: 十分
```

#### 有料プラン移行時のコスト
```
100 DAU:      月 75円
1,000 DAU:    月 500円
10,000 DAU:   月 3,800円
100,000 DAU:  月 30,000円
```

### ユーザー1人あたりの使用量（目安）
```
1日の操作:
├─ 読取: 60回（地図・タイムライン表示）
├─ 書込: 10回（平均）
└─ 写真アップロード: 5枚（旅行作成時）

1ヶ月の累積:
├─ ストレージ: 15MB（サムネイル300枚 × 50KB）
└─ 通信量: 50MB
```

---

## 🗂️ Firestore データモデル設計

### コレクション構造

```
firestore/
├─ users/{userId}
│   ├─ email: string
│   ├─ displayName: string
│   ├─ photoURL: string?
│   ├─ createdAt: timestamp
│   └─ lastLoginAt: timestamp
│
├─ trips/{tripId}
│   ├─ userId: string (owner)
│   ├─ name: string
│   ├─ startDate: timestamp
│   ├─ endDate: timestamp
│   ├─ coverPhotoURL: string?
│   ├─ coverPhotoThumbnailURL: string?
│   ├─ checkpointCount: number
│   ├─ isPublic: boolean
│   ├─ sharedWith: array<string> (userIds)
│   ├─ createdAt: timestamp
│   └─ updatedAt: timestamp
│
└─ checkpoints/{checkpointId}
    ├─ tripId: string (reference)
    ├─ userId: string
    ├─ latitude: number
    ├─ longitude: number
    ├─ timestamp: timestamp
    ├─ type: string ("photo" | "manualCheckin")
    ├─ photoAssetId: string? (ローカルPhotoKit ID)
    ├─ photoURL: string? (Firebase Storage URL)
    ├─ photoThumbnailURL: string? (サムネイル)
    ├─ note: string?
    ├─ address: string?
    ├─ createdAt: timestamp
    └─ updatedAt: timestamp
```

### インデックス設計

```javascript
// firestore.indexes.json
{
  "indexes": [
    {
      "collectionGroup": "trips",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "startDate", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "checkpoints",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "tripId", "order": "ASCENDING" },
        { "fieldPath": "timestamp", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "checkpoints",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "timestamp", "order": "DESCENDING" }
      ]
    }
  ]
}
```

---

## 🔐 セキュリティルール

### firestore.rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // ユーザー認証チェック
    function isAuthenticated() {
      return request.auth != null;
    }
    
    // オーナーチェック
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    // users コレクション
    match /users/{userId} {
      // 自分のユーザー情報のみ読み書き可能
      allow read, write: if isOwner(userId);
    }
    
    // trips コレクション
    match /trips/{tripId} {
      allow read: if isAuthenticated() && (
        // オーナー
        resource.data.userId == request.auth.uid ||
        // 公開設定
        resource.data.isPublic == true ||
        // 共有されている
        request.auth.uid in resource.data.sharedWith
      );
      
      allow create: if isAuthenticated() && 
        request.resource.data.userId == request.auth.uid;
      
      allow update, delete: if isOwner(resource.data.userId);
    }
    
    // checkpoints コレクション
    match /checkpoints/{checkpointId} {
      allow read: if isAuthenticated() && (
        // オーナー
        resource.data.userId == request.auth.uid ||
        // Tripが公開されている（要: 事前にTripを読み込む）
        get(/databases/$(database)/documents/trips/$(resource.data.tripId)).data.isPublic == true
      );
      
      allow create: if isAuthenticated() && 
        request.resource.data.userId == request.auth.uid;
      
      allow update, delete: if isOwner(resource.data.userId);
    }
  }
}
```

### storage.rules

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    
    // ユーザーごとのフォルダ
    match /users/{userId}/photos/{photoId} {
      // 読取: 認証済みユーザーなら誰でも（公開設定を考慮）
      allow read: if request.auth != null;
      
      // 書込: 自分のフォルダのみ
      allow write: if request.auth != null && request.auth.uid == userId;
      
      // ファイルサイズ制限（5MB）
      allow write: if request.resource.size < 5 * 1024 * 1024;
      
      // 画像ファイルのみ
      allow write: if request.resource.contentType.matches('image/.*');
    }
    
    // サムネイルフォルダ
    match /users/{userId}/thumbnails/{photoId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
      allow write: if request.resource.size < 500 * 1024; // 500KB制限
    }
  }
}
```

---

## 🔄 SwiftData との同期戦略

### 同期のタイミング

```
【ローカル優先】
1. ユーザー操作 → SwiftData に即座に保存
2. バックグラウンドで Firebase に同期
3. 同期失敗時はキューに保存して後でリトライ

【同期トリガー】
- アプリ起動時
- 旅行作成/編集時
- バックグラウンド復帰時
- ネットワーク復旧時
```

### 競合解決ルール

```
Last-Write-Wins（最終書込優先）
├─ updatedAt タイムスタンプで比較
├─ サーバー側が新しい → ローカルを上書き
└─ ローカルが新しい → サーバーに送信
```

### 同期ステータス管理

```swift
// SwiftData モデルに追加するプロパティ
@Model
class Trip {
    // 既存プロパティ...
    
    // 同期管理用
    var firebaseId: String?  // Firebase上のドキュメントID
    var syncStatus: SyncStatus = .synced
    var lastSyncedAt: Date?
    var needsSync: Bool = false
}

enum SyncStatus: String, Codable {
    case synced       // 同期済み
    case pending      // 同期待ち
    case syncing      // 同期中
    case failed       // 同期失敗
}
```

---

## 💾 Firebase Storage 設計

### ディレクトリ構造

```
storage/
└─ users/{userId}/
    ├─ photos/
    │   └─ {photoId}.jpg          (オリジナル、最大5MB)
    └─ thumbnails/
        └─ {photoId}_thumb.jpg    (サムネイル、50KB目標)
```

### 画像処理フロー

```
1. ユーザーが写真選択
   ↓
2. ローカルで圧縮・リサイズ
   ├─ オリジナル: iCloud Photos（変更なし）
   └─ サムネイル: 200x200px, JPEG 80%品質
   ↓
3. サムネイルのみFirebase Storageにアップロード
   ↓
4. ダウンロードURLをFirestoreに保存
   ↓
5. 他デバイスでサムネイルURL経由で表示
```

### URL管理

```swift
// Firestore Checkpoint ドキュメント
{
  "photoAssetId": "L8B7C/UUID",  // ローカルPhotoKit ID
  "photoThumbnailURL": "https://firebasestorage.googleapis.com/.../thumb.jpg",
  "photoURL": null  // オリジナルは保存しない
}

// 表示時の優先順位
1. ローカルにPhotoAssetIdがある → ローカル表示
2. なければphotoThumbnailURL → Firebase表示
3. どちらもなければ → プレースホルダー
```

---

## 📦 必要なパッケージ

### Swift Package Manager

```swift
// Package.swift または Xcode Project Settings
dependencies: [
    .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "10.20.0")
]

// Targets に追加
.product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
.product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
.product(name: "FirebaseStorage", package: "firebase-ios-sdk"),
```

### Info.plist 設定

```xml
<!-- Firebase設定ファイル -->
<!-- GoogleService-Info.plist をプロジェクトに追加 -->

<!-- バックグラウンド同期（オプション）-->
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
```

---

## 🛠️ 実装ファイル構成

```
TravelLogApp/
├── Firebase/
│   ├── FirebaseManager.swift           # Firebase初期化
│   ├── FirestoreService.swift          # Firestore CRUD操作
│   ├── StorageService.swift            # Storage アップロード/ダウンロード
│   ├── AuthService.swift               # 認証管理
│   └── SyncManager.swift               # SwiftData ⟷ Firebase 同期
├── Models/
│   ├── Trip.swift                      # SwiftData Model（同期機能追加）
│   ├── Checkpoint.swift                # SwiftData Model（同期機能追加）
│   └── SyncStatus.swift                # 同期ステータス enum
└── ViewModels/
    ├── MapViewModel.swift              # Firebase連携追加
    └── SyncViewModel.swift             # 同期状態管理
```

---

## 🚀 段階的実装手順

### Phase 1: Firebase初期設定（手動）

```bash
# 1. Firebase Console でプロジェクト作成
# https://console.firebase.google.com/

# 2. iOSアプリを追加
# Bundle ID: jp.yourdomain.antigravity

# 3. GoogleService-Info.plist をダウンロード
# Xcodeプロジェクトのルートに配置

# 4. Firebase CLIインストール（ローカル）
npm install -g firebase-tools

# 5. ログイン
firebase login

# 6. プロジェクト初期化
firebase init firestore
firebase init storage
```

### Phase 2: SwiftコードでFirebase初期化

**指示 Firebase-1: FirebaseManager.swift 作成**

```
Firebase/FirebaseManager.swiftを作成してください。

要件:
- Singleton パターン
- Firebase初期化処理
- configure() メソッド（アプリ起動時に1回呼ぶ）
- 初期化済みチェック

実装:
import FirebaseCore

class FirebaseManager {
    static let shared = FirebaseManager()
    
    private(set) var isConfigured = false
    
    private init() {}
    
    func configure() {
        guard !isConfigured else { return }
        FirebaseApp.configure()
        isConfigured = true
        print("[Firebase] 初期化完了")
    }
}

使用方法:
// App Entry Pointで呼ぶ
init() {
    FirebaseManager.shared.configure()
}
```

### Phase 3: 認証機能実装

**指示 Firebase-2: AuthService.swift 作成**

```
Firebase/AuthService.swiftを作成してください。

要件:
- @Observable マクロ使用
- プロパティ:
  - currentUser: User?
  - isAuthenticated: Bool
  - authStateDidChangePublisher: AsyncStream<User?>
  
- メソッド:
  1. signInAnonymously() async throws -> User
     - 匿名ログイン（初期実装）
  
  2. signInWithApple() async throws -> User
     - Apple Sign In（将来実装）
  
  3. signOut() throws
  
  4. deleteAccount() async throws
  
- FirebaseAuth使用
- エラーハンドリング
- 日本語コメント

補足:
初期実装は匿名認証のみ。
Apple Sign In は Phase 3 で追加。
```

### Phase 4: Firestore操作実装

**指示 Firebase-3: FirestoreService.swift 作成**

```
Firebase/FirestoreService.swiftを作成してください。

要件:
- Firestoreへの CRUD 操作
- プロパティ:
  - db: Firestore インスタンス
  
- Trip 操作:
  1. createTrip(_ trip: Trip) async throws -> String
     - Tripを作成、ドキュメントIDを返す
  
  2. getTrip(id: String) async throws -> Trip?
  
  3. updateTrip(_ trip: Trip) async throws
  
  4. deleteTrip(id: String) async throws
  
  5. getUserTrips(userId: String) async throws -> [Trip]
     - ユーザーの全Tripを取得、startDateでソート
  
- Checkpoint 操作:
  1. createCheckpoint(_ checkpoint: Checkpoint) async throws -> String
  
  2. getCheckpoint(id: String) async throws -> Checkpoint?
  
  3. updateCheckpoint(_ checkpoint: Checkpoint) async throws
  
  4. deleteCheckpoint(id: String) async throws
  
  5. getCheckpoints(forTrip tripId: String) async throws -> [Checkpoint]
     - Trip配下の全Checkpointを取得、timestampでソート
  
  6. batchCreateCheckpoints(_ checkpoints: [Checkpoint]) async throws
     - 複数Checkpointを一括作成（写真読込時）
  
- バッチ書込使用（複数ドキュメント操作時）
- タイムスタンプ自動設定（createdAt, updatedAt）
- エラーハンドリング
- 日本語コメント

データ変換:
- SwiftData Model ⟷ Firestore Document の変換ロジック
- Codable準拠のDTO（Data Transfer Object）使用推奨
```

### Phase 5: Storage操作実装

**指示 Firebase-4: StorageService.swift 作成**

```
Firebase/StorageService.swiftを作成してください。

要件:
- Firebase Storage への画像アップロード/ダウンロード
- プロパティ:
  - storage: Storage インスタンス
  
- メソッド:
  1. uploadThumbnail(
       image: UIImage, 
       userId: String, 
       photoId: String
     ) async throws -> String
     - サムネイル画像をアップロード
     - 圧縮処理（JPEG 80%品質）
     - ダウンロードURLを返す
  
  2. downloadThumbnail(url: String) async throws -> UIImage
     - URLから画像をダウンロード
     - キャッシュ機構（NSCache使用）
  
  3. deleteThumbnail(url: String) async throws
     - 画像を削除
  
  4. compressImage(_ image: UIImage, targetSizeKB: Int) -> Data?
     - 画像圧縮ヘルパー
     - 目標サイズ（KB）まで品質を下げる
  
- プログレス通知（AsyncStream）
- キャンセル対応
- エラーハンドリング
- 日本語コメント

パス設計:
users/{userId}/thumbnails/{photoId}_thumb.jpg
```

### Phase 6: 同期マネージャー実装

**指示 Firebase-5: SyncManager.swift 作成**

```
Firebase/SyncManager.swiftを作成してください。

要件:
- SwiftData ⟷ Firebase の双方向同期
- @Observable マクロ
- プロパティ:
  - isSyncing: Bool
  - lastSyncDate: Date?
  - syncProgress: Double (0.0-1.0)
  - pendingSyncCount: Int
  
- メソッド:
  1. syncAll() async throws
     - 全データを同期
     - ローカル → Firebase（needsSync = true のみ）
     - Firebase → ローカル（updatedAt 比較）
  
  2. syncTrip(_ trip: Trip) async throws
     - 単一Tripを同期
  
  3. syncCheckpoints(forTrip tripId: String) async throws
     - Trip配下の全Checkpointを同期
  
  4. uploadPendingItems() async throws
     - 同期待ちアイテムをアップロード
     - リトライロジック（最大3回）
  
  5. downloadUpdates(since date: Date) async throws
     - 指定日時以降の変更を取得
  
- 競合解決:
  - Last-Write-Wins（updatedAt 比較）
  
- エラーハンドリング:
  - ネットワークエラー時はキューに保存
  - 次回同期時にリトライ
  
- 依存注入:
  - FirestoreService
  - StorageService
  - SwiftData ModelContext
  
- 日本語コメント

同期ロジック:
1. ローカルの needsSync = true を取得
2. Firebase に送信
3. syncStatus = .syncing
4. 成功: syncStatus = .synced, needsSync = false
5. 失敗: syncStatus = .failed, リトライキューに追加
```

### Phase 7: SwiftDataモデルの拡張

**指示 Firebase-6: Trip.swift を更新**

```
Models/Trip.swiftに以下のプロパティを追加してください。

追加プロパティ:
// Firebase 同期用
var firebaseId: String?           // FirestoreドキュメントID
var syncStatus: String = "synced" // "synced" | "pending" | "syncing" | "failed"
var lastSyncedAt: Date?           // 最終同期日時
var needsSync: Bool = false       // 同期が必要か

// 共有機能用
var isPublic: Bool = false        // 公開設定
var sharedWith: [String] = []     // 共有先ユーザーIDリスト

computed property:
var isSynced: Bool {
    return syncStatus == "synced" && !needsSync
}

メソッド:
func markNeedsSync() {
    needsSync = true
    syncStatus = "pending"
    updatedAt = Date()
}
```

**指示 Firebase-7: Checkpoint.swift を更新**

```
Models/Checkpoint.swiftに以下のプロパティを追加してください。

追加プロパティ:
// Firebase 同期用
var firebaseId: String?
var syncStatus: String = "synced"
var lastSyncedAt: Date?
var needsSync: Bool = false

// Storage URL
var photoThumbnailURL: String?    // Firebase Storage URL

computed property:
var isSynced: Bool {
    return syncStatus == "synced" && !needsSync
}

メソッド:
func markNeedsSync() {
    needsSync = true
    syncStatus = "pending"
    updatedAt = Date()
}
```

### Phase 8: ViewModelへの統合

**指示 Firebase-8: MapViewModel に同期機能追加**

```
ViewModels/MapViewModel.swiftに以下を追加してください。

プロパティ:
private let syncManager: SyncManager
private let storageService: StorageService
var isSyncing: Bool = false

イニシャライザ:
init(
    syncManager: SyncManager = SyncManager.shared,
    storageService: StorageService = StorageService.shared
) {
    self.syncManager = syncManager
    self.storageService = storageService
}

メソッド:
1. syncToCloud() async throws
   - 現在のTripとCheckpointsを同期
   - サムネイルアップロード
   - 同期状態の更新
   
2. downloadFromCloud() async throws
   - Firebaseから最新データを取得
   - ローカルに反映

3. uploadPhotoThumbnails(for checkpoints: [Checkpoint]) async throws
   - 各CheckpointのphotoAssetIdから画像取得
   - サムネイル生成・アップロード
   - URLをCheckpointに保存

使用例:
loadPhotos()実行後に自動でsyncToCloud()を呼ぶ
```

---

## 🧪 テストデータ作成

### 開発用スクリプト

```swift
// Utilities/FirebaseTestData.swift

class FirebaseTestData {
    static func createSampleTrip(userId: String) async throws {
        let trip = Trip(
            name: "北海道旅行",
            startDate: Date().addingTimeInterval(-7*24*60*60),
            endDate: Date()
        )
        trip.userId = userId
        
        let checkpoint1 = Checkpoint(
            latitude: 43.0642,
            longitude: 141.3469,
            timestamp: Date().addingTimeInterval(-6*24*60*60),
            type: .photo
        )
        checkpoint1.address = "札幌駅"
        
        // Firestoreに保存
        let firestoreService = FirestoreService.shared
        let tripId = try await firestoreService.createTrip(trip)
        checkpoint1.tripId = tripId
        try await firestoreService.createCheckpoint(checkpoint1)
    }
}
```

---

## 📈 パフォーマンス最適化

### 1. バッチ書込の活用

```swift
// ❌ 悪い例: 30回の個別書込
for checkpoint in checkpoints {
    try await firestoreService.createCheckpoint(checkpoint)
}
// → 30 writes

// ✅ 良い例: 1回のバッチ書込
try await firestoreService.batchCreateCheckpoints(checkpoints)
// → 1 write
```

### 2. クエリの最適化

```swift
// ❌ 悪い例: 全データ取得
let allTrips = try await firestoreService.getAllTrips()
let myTrips = allTrips.filter { $0.userId == currentUserId }

// ✅ 良い例: フィルタ付きクエリ
let myTrips = try await firestoreService.getUserTrips(userId: currentUserId)
```

### 3. キャッシュの活用

```swift
// Firestore のキャッシュ設定
let settings = FirestoreSettings()
settings.cacheSettings = PersistentCacheSettings(
    sizeBytes: 100 * 1024 * 1024  // 100MB
)
Firestore.firestore().settings = settings

// Storage のキャッシュ
class ImageCache {
    static let shared = NSCache<NSString, UIImage>()
    
    func get(url: String) -> UIImage? {
        return ImageCache.shared.object(forKey: url as NSString)
    }
    
    func set(url: String, image: UIImage) {
        ImageCache.shared.setObject(image, forKey: url as NSString)
    }
}
```

### 4. 差分同期

```swift
// ❌ 悪い例: 毎回全データ同期
try await syncManager.syncAll()

// ✅ 良い例: 変更分のみ同期
if let lastSync = UserDefaults.standard.object(forKey: "lastSyncDate") as? Date {
    try await syncManager.downloadUpdates(since: lastSync)
}
```

---

## 🐛 デバッグとトラブルシューティング

### Firebase Console でのデバッグ

```
1. Firestore データブラウザ
   → コレクション・ドキュメントを直接確認

2. Storage ブラウザ
   → アップロードされた画像を確認

3. Authentication
   → ユーザーリストと認証状態

4. Firestore Usage
   → 読取・書込回数の確認
```

### ログ出力

```swift
#if DEBUG
// Firestore デバッグログ有効化
let settings = Firestore.firestore().settings
settings.isDebugModeEnabled = true
Firestore.firestore().settings = settings

// カスタムログ
func logFirebase(_ message: String, level: String = "INFO") {
    print("[\(level)] [Firebase] \(message)")
}
#endif
```

### よくあるエラー

```
1. "Permission denied"
   → firestore.rules を確認
   → 認証状態を確認

2. "Network error"
   → ネットワーク接続確認
   → Firebase Console でプロジェクト状態確認

3. "Quota exceeded"
   → Firebase Console で使用量確認
   → 無料枠を超えている可能性

4. "Document not found"
   → ドキュメントIDが正しいか確認
   → 削除されていないか確認
```

---

## ✅ 実装チェックリスト

### 初期設定
- [ ] Firebase Console でプロジェクト作成
- [ ] iOSアプリ追加
- [ ] GoogleService-Info.plist 配置
- [ ] Info.plist 権限設定
- [ ] Firebase SDK インストール

### コード実装
- [ ] FirebaseManager.swift
- [ ] AuthService.swift
- [ ] FirestoreService.swift
- [ ] StorageService.swift
- [ ] SyncManager.swift
- [ ] SwiftDataモデル拡張

### セキュリティ
- [ ] firestore.rules デプロイ
- [ ] storage.rules デプロイ
- [ ] インデックス作成

### テスト
- [ ] 認証フロー
- [ ] Trip CRUD
- [ ] Checkpoint CRUD
- [ ] 画像アップロード
- [ ] 同期処理
- [ ] オフライン動作

### 最適化
- [ ] バッチ書込実装
- [ ] キャッシュ設定
- [ ] 差分同期実装
- [ ] エラーハンドリング

---

## 🚀 リリース準備

### 本番環境への移行

```bash
# 1. 本番用Firebaseプロジェクト作成

# 2. 環境変数で切り替え
# Debug: 開発用プロジェクト
# Release: 本番用プロジェクト

# 3. GoogleService-Info.plist を環境別に用意
GoogleService-Info-Dev.plist
GoogleService-Info-Prod.plist

# 4. Build Settings で切り替え
```

### モニタリング設定

```
Firebase Console:
├─ Crashlytics: クラッシュレポート
├─ Performance: パフォーマンス監視
└─ Analytics: 使用状況分析
```

---

## 📚 参考リンク

- [Firebase iOS SDK ドキュメント](https://firebase.google.com/docs/ios/setup)
- [Firestore データモデリング](https://firebase.google.com/docs/firestore/data-model)
- [Firebase セキュリティルール](https://firebase.google.com/docs/rules)
- [Cloud Storage for iOS](https://firebase.google.com/docs/storage/ios/start)

---

## 🎯 実装の優先順位まとめ

```
Phase 1: 初期設定（手動）
  ↓
Phase 2: Firebase初期化（自動）
  ↓
Phase 3: 認証実装（匿名ログイン）
  ↓
Phase 4: Firestore CRUD（基本操作）
  ↓
Phase 5: Storage操作（サムネイルアップロード）
  ↓
Phase 6: 同期マネージャー（双方向同期）
  ↓
Phase 7: SwiftDataモデル拡張
  ↓
Phase 8: ViewModelへの統合
```

各Phaseごとにテストしながら進めることを強く推奨します。
