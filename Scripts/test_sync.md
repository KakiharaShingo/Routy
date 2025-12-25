# データ同期テスト手順

## テスト1: ログイン状態でのデータ保存

1. アプリを起動
2. アカウント設定から本登録（メールアドレス登録）
3. 新しい旅を作成
4. コンソールログを確認:
   ```
   📤 [SyncManager] アップロード開始: Trip X件
   📤 [SyncManager] Trip新規作成: 旅行名
   ✅ [SyncManager] Trip作成完了: ID=xxx
   ```

## テスト2: ログアウト→ログインでデータ復元

1. ログアウト（確認ダイアログが表示される）
2. コンソールログを確認:
   ```
   👋 [DataSyncService] ログアウト検出
   🗑️ [DataSyncService] ローカルデータを削除しました
   ```
3. 旅ログが空になることを確認
4. 同じアカウントでログイン
5. コンソールログを確認:
   ```
   🔐 [DataSyncService] ログイン検出: xxx
   📥 [SyncManager] ダウンロード開始: Trip X件
   📥 [SyncManager] Trip新規作成: 旅行名
   ✅ [SyncManager] Trip作成完了（Checkpoint含む）
   ```
6. 旅ログが復元されることを確認

## テスト3: 匿名→本登録でデータ保持

1. アプリをアンインストールして再インストール
2. 匿名ユーザーとして旅を作成
3. コンソールログを確認（初回匿名ログインはスキップされる）:
   ```
   👤 [AuthService] 初回匿名ログイン - 通知スキップ
   ```
4. アカウント設定から本登録
5. コンソールログを確認（ログアウトイベントは発生しない）:
   ```
   👤 [AuthService] ユーザー状態変更: xxx, 匿名: false
   🔐 [DataSyncService] ログイン検出: xxx
   📤 [SyncManager] アップロード開始: Trip X件
   ```
6. 旅ログが保持されていることを確認

## 期待される動作

✅ ログイン状態で作成したデータはクラウドに保存される
✅ ログアウト時はローカルデータが削除される
✅ 再ログイン時にクラウドからデータが復元される
✅ 匿名→本登録時はデータが保持される

## デバッグコマンド

シミュレータのログをリアルタイムで確認:
```bash
xcrun simctl spawn booted log stream --predicate 'processImagePath contains "Routy"' --level debug
```
