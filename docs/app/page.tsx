import Link from 'next/link'

export default function Home() {
  return (
    <>
      <header className="header">
        <div className="header-content">
          <div className="logo">Routy</div>
          <nav className="nav">
            <Link href="/privacy">プライバシーポリシー</Link>
            <Link href="/terms">利用規約</Link>
            <Link href="/support">サポート</Link>
          </nav>
        </div>
      </header>

      <main className="container">
        <div className="content-box">
          <h1>Routy</h1>
          <p>写真から自動で旅のルートを記録するアプリ</p>

          <h2>主な機能</h2>
          <ul>
            <li>写真の位置情報から自動的に旅のルートを作成</li>
            <li>訪れた場所を地図上で可視化</li>
            <li>カテゴリ別にチェックポイントを自動分類</li>
            <li>旅の思い出をタイムラインで振り返り</li>
            <li>訪問した都道府県の統計を表示</li>
          </ul>

          <h2>ドキュメント</h2>
          <ul>
            <li><Link href="/privacy">プライバシーポリシー</Link></li>
            <li><Link href="/terms">利用規約</Link></li>
            <li><Link href="/support">サポート・お問い合わせ</Link></li>
          </ul>
        </div>
      </main>

      <footer className="footer">
        <p>&copy; 2025 Routy. All rights reserved.</p>
      </footer>
    </>
  )
}
