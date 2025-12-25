//
//  PrivacyPolicyView.swift
//  Routy
//
//  プライバシーポリシー画面
//

import SwiftUI

/// プライバシーポリシー表示画面
struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("プライバシーポリシー")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.bottom, 8)

                Text("最終更新日：2025年12月25日")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 16)

                Group {
                    SectionView(
                        title: "1. 収集する情報",
                        content: """
                        Routyアプリ（以下「本アプリ」）は、以下の情報を収集します：

                        • 位置情報付き写真のメタデータ（撮影日時、位置情報）
                        • 旅行記録データ（チェックポイント、メモ、日付）
                        • アカウント情報（メールアドレス、表示名）※任意登録
                        • 端末情報（OSバージョン、アプリバージョン）※クラッシュレポート用
                        """
                    )

                    SectionView(
                        title: "2. 情報の利用目的",
                        content: """
                        収集した情報は以下の目的で利用します：

                        • 旅行記録の作成・保存・表示
                        • マップ上での位置情報の表示
                        • データのクラウド同期（アカウント登録時）
                        • アプリの改善・不具合の修正
                        • お問い合わせへの対応
                        """
                    )

                    SectionView(
                        title: "3. 情報の共有",
                        content: """
                        本アプリは、以下の場合を除き、ユーザーの情報を第三者に提供しません：

                        • ユーザーの同意がある場合
                        • 法令に基づく場合
                        • 人の生命、身体または財産の保護のために必要な場合

                        本アプリは以下のサービスを利用しています：
                        • Firebase（Google LLC）- 認証・データ保存
                        • Apple Photos - 写真へのアクセス
                        """
                    )

                    SectionView(
                        title: "4. 写真へのアクセス",
                        content: """
                        本アプリは、ユーザーの写真ライブラリから位置情報付きの写真を読み込みます。

                        • 写真の読み込みには、ユーザーの明示的な許可が必要です
                        • アプリが選択した写真のみアクセスします
                        • 写真そのものはデバイス内に保存され、クラウドにアップロードされません
                        • 位置情報・撮影日時などのメタデータのみがクラウドに保存されます
                        """
                    )

                    SectionView(
                        title: "5. データの保存期間",
                        content: """
                        • デバイス内のデータ：アプリを削除するまで保存されます
                        • クラウドのデータ：アカウント削除まで保存されます
                        • アカウント削除後、30日以内にすべてのデータを削除します
                        """
                    )

                    SectionView(
                        title: "6. セキュリティ",
                        content: """
                        本アプリは、ユーザーの情報を保護するため、以下の対策を講じています：

                        • Firebase Authenticationによる安全な認証
                        • 通信の暗号化（SSL/TLS）
                        • アクセス制御によるデータ保護
                        """
                    )

                    SectionView(
                        title: "7. ユーザーの権利",
                        content: """
                        ユーザーは以下の権利を有します：

                        • 自身のデータへのアクセス・確認
                        • データの修正・削除
                        • データのエクスポート（CSV形式）
                        • アカウントの削除

                        これらの操作は、アプリの設定画面から行えます。
                        """
                    )

                    SectionView(
                        title: "8. お問い合わせ",
                        content: """
                        プライバシーポリシーに関するご質問は、以下までお問い合わせください：

                        メール：support@routy.app
                        """
                    )

                    SectionView(
                        title: "9. ポリシーの変更",
                        content: """
                        本プライバシーポリシーは、法令の変更やサービスの改善に伴い、予告なく変更されることがあります。

                        重要な変更がある場合は、アプリ内で通知いたします。
                        """
                    )
                }
            }
            .padding()
        }
        .navigationTitle("プライバシーポリシー")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// セクション表示用コンポーネント
struct SectionView: View {
    let title: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)

            Text(content)
                .font(.body)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.bottom, 8)
    }
}

#Preview {
    NavigationStack {
        PrivacyPolicyView()
    }
}
