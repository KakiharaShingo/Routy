# Routy - ドキュメントサイト

Routyアプリのプライバシーポリシー、利用規約、サポートページを提供する静的サイトです。

## 技術スタック

- Next.js 14 (App Router)
- React 18
- TypeScript
- Vercel (ホスティング)

## ローカル開発

### 1. 依存関係のインストール

```bash
cd docs
npm install
```

### 2. 開発サーバーの起動

```bash
npm run dev
```

ブラウザで http://localhost:3000 を開いてください。

### 3. ビルド

```bash
npm run build
```

静的ファイルが `out` ディレクトリに生成されます。

## Vercelへのデプロイ

### 方法1: Vercel CLIを使用

```bash
# Vercel CLIをインストール
npm i -g vercel

# デプロイ
cd docs
vercel
```

### 方法2: GitHubと連携

1. このリポジトリをGitHubにプッシュ
2. [Vercel](https://vercel.com)にログイン
3. "New Project" をクリック
4. GitHubリポジトリをインポート
5. プロジェクトルートを `docs` に設定
6. デプロイ

## ページ構成

- `/` - トップページ
- `/privacy` - プライバシーポリシー
- `/terms` - 利用規約
- `/support` - サポート・お問い合わせ

## 更新方法

1. 各ページファイル（`app/*/page.tsx`）を編集
2. 必要に応じて最終更新日を変更
3. GitHubにプッシュ（Vercelと連携している場合は自動デプロイ）

## App Store審査用

Apple App Storeの審査には、以下のURLを提供してください：

- プライバシーポリシー: `https://your-domain.vercel.app/privacy`
- 利用規約: `https://your-domain.vercel.app/terms`
- サポート: `https://your-domain.vercel.app/support`

※ `your-domain` はVercelで生成されたドメインまたはカスタムドメインに置き換えてください。

## ライセンス

Private
