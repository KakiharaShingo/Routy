import Link from 'next/link'

export default function Privacy() {
  return (
    <>
      <header className="header">
        <div className="header-content">
          <Link href="/" className="logo">Routy</Link>
          <nav className="nav">
            <Link href="/privacy">プライバシーポリシー</Link>
            <Link href="/terms">利用規約</Link>
            <Link href="/support">サポート</Link>
          </nav>
        </div>
      </header>

      <main className="container">
        <div className="content-box">
          <h1>プライバシーポリシー</h1>
          <p>Routy（以下「本アプリ」）は、ユーザーの皆様のプライバシーを尊重し、個人情報の保護に努めています。本プライバシーポリシーでは、本アプリにおける情報の取り扱いについて説明します。</p>

          <h2>1. 収集する情報</h2>

          <h3>1.1 写真ライブラリへのアクセス</h3>
          <p>本アプリは、旅のルートを自動作成するために、ユーザーの写真ライブラリにアクセスします。アクセスする情報は以下の通りです：</p>
          <ul>
            <li>写真の撮影日時</li>
            <li>写真の位置情報（緯度・経度）</li>
            <li>写真の画像データ</li>
          </ul>
          <p>写真ライブラリへのアクセスは、ユーザーが明示的に許可した場合のみ行われます。</p>

          <h3>1.2 位置情報</h3>
          <p>本アプリは、以下の目的で位置情報を使用します：</p>
          <ul>
            <li>チェックポイントの住所取得</li>
            <li>施設カテゴリの自動判定</li>
            <li>地図上での表示</li>
          </ul>
          <p>位置情報は、写真に含まれるEXIFデータから取得されます。アプリが独自に位置情報を追跡することはありません。</p>

          <h3>1.3 ユーザーアカウント情報</h3>
          <p>本アプリでは、データの同期とバックアップのために以下の認証方法を提供しています：</p>
          <ul>
            <li>匿名認証（デフォルト）</li>
            <li>メールアドレス認証</li>
            <li>Google認証</li>
            <li>Apple ID認証</li>
          </ul>
          <p>認証時には、選択した方法に応じた最小限の情報（メールアドレス、ユーザーID等）が収集されます。</p>

          <h3>1.4 旅行データ</h3>
          <p>本アプリは、ユーザーが作成した以下の情報を保存します：</p>
          <ul>
            <li>旅行名、開始日、終了日</li>
            <li>チェックポイント（名前、位置情報、日時、カテゴリ、メモ）</li>
            <li>アップロードされた写真のURL</li>
          </ul>

          <h2>2. 情報の利用目的</h2>
          <p>収集した情報は、以下の目的でのみ使用されます：</p>
          <ul>
            <li>旅のルートの自動作成と表示</li>
            <li>チェックポイントのカテゴリ自動判定</li>
            <li>地図上での位置表示</li>
            <li>訪問した都道府県の統計表示</li>
            <li>データの同期とバックアップ</li>
            <li>アプリの機能改善</li>
          </ul>

          <h2>3. 情報の保存と管理</h2>

          <h3>3.1 ローカルストレージ</h3>
          <p>旅行データは、ユーザーのデバイス上にSwiftDataを使用して安全に保存されます。</p>

          <h3>3.2 クラウドストレージ</h3>
          <p>ユーザーが認証を行った場合、データはGoogle Firebase（Firestore、Cloud Storage）に保存されます。Firebaseのセキュリティルールにより、ユーザー自身のデータのみにアクセスできるよう制限されています。</p>

          <h3>3.3 写真のアップロード</h3>
          <p>写真は、ユーザーが明示的にアップロードを選択した場合のみ、Firebase Cloud Storageに保存されます。無料ユーザーの場合、写真は圧縮されて保存されます。</p>

          <h2>4. 情報の第三者提供</h2>
          <p>本アプリは、以下の場合を除き、ユーザーの個人情報を第三者に提供することはありません：</p>
          <ul>
            <li>ユーザーの同意がある場合</li>
            <li>法令に基づく場合</li>
            <li>人の生命、身体または財産の保護のために必要がある場合</li>
          </ul>

          <h2>5. 第三者サービスの利用</h2>
          <p>本アプリは、以下の第三者サービスを利用しています：</p>

          <h3>5.1 Google Firebase</h3>
          <ul>
            <li>用途: ユーザー認証、データ同期、写真ストレージ</li>
            <li>プライバシーポリシー: <a href="https://policies.google.com/privacy" target="_blank" rel="noopener noreferrer">https://policies.google.com/privacy</a></li>
          </ul>

          <h3>5.2 Apple MapKit</h3>
          <ul>
            <li>用途: 地図表示、住所取得、施設情報取得</li>
            <li>プライバシーポリシー: <a href="https://www.apple.com/legal/privacy/" target="_blank" rel="noopener noreferrer">https://www.apple.com/legal/privacy/</a></li>
          </ul>

          <h2>6. データの削除</h2>
          <p>ユーザーは、いつでも以下の方法でデータを削除できます：</p>
          <ul>
            <li>アプリ内から個別の旅行データを削除</li>
            <li>設定画面からアカウントを削除（ローカルおよびクラウドの全データが削除されます）</li>
          </ul>

          <h2>7. データのエクスポート</h2>
          <p>ユーザーは、設定画面からCSV形式で自分のデータをエクスポートできます。</p>

          <h2>8. セキュリティ</h2>
          <p>本アプリは、ユーザーの情報を保護するため、以下の対策を講じています：</p>
          <ul>
            <li>Firebase Authentication による安全な認証</li>
            <li>Firestore Security Rules によるアクセス制御</li>
            <li>HTTPS通信による暗号化</li>
            <li>デバイス上のデータの暗号化（iOS標準機能）</li>
          </ul>

          <h2>9. 子供のプライバシー</h2>
          <p>本アプリは、13歳未満の子供を対象としていません。13歳未満の子供から意図的に個人情報を収集することはありません。</p>

          <h2>10. プライバシーポリシーの変更</h2>
          <p>本プライバシーポリシーは、法令の変更やサービスの改善に伴い、予告なく変更される場合があります。重要な変更がある場合は、アプリ内で通知します。</p>

          <h2>11. お問い合わせ</h2>
          <p>本プライバシーポリシーに関するご質問は、<Link href="/support">サポートページ</Link>からお問い合わせください。</p>

          <p className="last-updated">最終更新日: 2025年12月25日</p>
        </div>
      </main>

      <footer className="footer">
        <p>&copy; 2025 Routy. All rights reserved.</p>
      </footer>
    </>
  )
}
