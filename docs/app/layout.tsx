import type { Metadata } from 'next'
import './globals.css'

export const metadata: Metadata = {
  title: 'Routy - 旅の記録アプリ',
  description: '写真から自動で旅のルートを記録するアプリ',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="ja">
      <body>{children}</body>
    </html>
  )
}
