//
//  FAQView.swift
//  Routy
//
//  よくある質問画面
//

import SwiftUI

/// FAQ表示画面
struct FAQView: View {
    @State private var expandedItems: Set<Int> = []

    private let faqs: [FAQItem] = [
        FAQItem(
            question: "Routyとは何ですか？",
            answer: "Routyは、写真から旅行の記録を自動的に作成するアプリです。位置情報付きの写真から、訪問した場所やルートをマップ上に表示し、旅の思い出を振り返ることができます。"
        ),
        FAQItem(
            question: "アカウント登録は必要ですか？",
            answer: "基本機能はアカウント登録なしで利用できます。ただし、データのクラウド同期や複数端末での利用には、アカウント登録が必要です。"
        ),
        FAQItem(
            question: "写真はクラウドにアップロードされますか？",
            answer: "いいえ、写真自体はデバイス内に保存されます。クラウドには、位置情報・撮影日時・メモなどのメタデータのみが保存されます。"
        ),
        FAQItem(
            question: "位置情報のない写真も使えますか？",
            answer: "位置情報のない写真は自動的にマップ上に表示されませんが、手動でチェックインを追加することで記録できます。"
        ),
        FAQItem(
            question: "過去の旅行も記録できますか？",
            answer: "はい、写真ライブラリから期間を指定して写真を取り込むことで、過去の旅行も記録できます。"
        ),
        FAQItem(
            question: "データのバックアップはできますか？",
            answer: "設定画面から、旅行データをCSV形式でエクスポートできます。エクスポートしたデータは、後で復元（インポート）することも可能です。"
        ),
        FAQItem(
            question: "同じ場所の写真はどうなりますか？",
            answer: "同じ場所（15m以内）の写真は自動的にグループ化され、マップ上に1つのピンとして表示されます。ピンをタップすると、訪問回数や写真一覧を確認できます。"
        ),
        FAQItem(
            question: "カテゴリは自動で判定されますか？",
            answer: "はい、写真の位置情報から自動的にカテゴリ（レストラン、カフェ、ホテルなど）を判定します。手動で変更することも可能です。"
        ),
        FAQItem(
            question: "データを削除するとどうなりますか？",
            answer: "アプリ内のデータを削除しても、写真ライブラリの写真は削除されません。ただし、クラウド上の旅行記録データは削除されます。削除前に必要に応じてエクスポートしてください。"
        ),
        FAQItem(
            question: "複数の端末で同期できますか？",
            answer: "はい、アカウント登録を行うことで、複数の端末でデータを同期できます。ただし、写真自体は各端末のライブラリから参照されます。"
        ),
        FAQItem(
            question: "オフラインでも使えますか？",
            answer: "はい、オフラインでも基本機能は利用できます。ただし、クラウド同期やカテゴリの自動判定には、インターネット接続が必要です。"
        ),
        FAQItem(
            question: "アカウントを削除するとどうなりますか？",
            answer: "アカウント削除後、30日以内にクラウド上のすべてのデータが削除されます。削除前に必要なデータをエクスポートしてください。"
        ),
        FAQItem(
            question: "プライバシーは保護されますか？",
            answer: "はい、本アプリはプライバシーを重視しています。写真自体はクラウドにアップロードされず、メタデータのみが暗号化されて保存されます。詳しくはプライバシーポリシーをご確認ください。"
        ),
        FAQItem(
            question: "不具合を見つけた場合はどうすればいいですか？",
            answer: "お問い合わせ（support@routy.app）までご連絡ください。スクリーンショットや詳細な手順を添えていただけると、より早く対応できます。"
        ),
        FAQItem(
            question: "新機能のリクエストはできますか？",
            answer: "はい、お問い合わせ（support@routy.app）または公式Twitterまでご連絡ください。すべてのリクエストを検討し、可能な限り実装いたします。"
        )
    ]

    var body: some View {
        List {
            ForEach(Array(faqs.enumerated()), id: \.offset) { index, faq in
                FAQItemView(
                    faq: faq,
                    isExpanded: expandedItems.contains(index)
                ) {
                    withAnimation {
                        if expandedItems.contains(index) {
                            expandedItems.remove(index)
                        } else {
                            expandedItems.insert(index)
                        }
                    }
                }
            }

            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("上記で解決しない場合")
                        .font(.headline)

                    Link(destination: URL(string: "mailto:support@routy.app")!) {
                        HStack {
                            Image(systemName: "envelope.fill")
                            Text("お問い合わせ")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                        }
                        .foregroundColor(.blue)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("よくある質問")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// FAQ項目データ
struct FAQItem: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
}

/// FAQ項目表示コンポーネント
struct FAQItemView: View {
    let faq: FAQItem
    let isExpanded: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: onTap) {
                HStack {
                    Image(systemName: "questionmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title3)

                    Text(faq.question)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }

            if isExpanded {
                Text(faq.answer)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.leading, 32)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    NavigationStack {
        FAQView()
    }
}
