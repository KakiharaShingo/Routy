# Routy - ドキュメントサイト

Routyアプリのプライバシーポリシー、利用規約、サポートページを提供する静的サイトです。

## 技術スタック

- Next.js 14 (App Router)
- React 18
- TypeScript
- GitHub Pages (ホスティング)

## ローカル開発

### 1. 依存関係のインストール

```bash
# プロジェクトルートから
make docs-install

# または手動で
cd docs
npm install
```

### 2. 開発サーバーの起動

```bash
# プロジェクトルートから
make docs-dev

# または手動で
cd docs
npm run dev
```

ブラウザで http://localhost:3000 を開いてください。

### 3. ビルド

```bash
# プロジェクトルートから
make docs-build

# または手動で
cd docs
npm run build
```

静的ファイルが `docs/out` ディレクトリに生成されます。

## GitHub Pagesへのデプロイ（推奨）

### 初回設定

1. GitHubリポジトリの設定を開く
2. **Settings** → **Pages** に移動
3. **Source** を **GitHub Actions** に設定
4. 保存

### デプロイ方法

#### 方法1: Makefileを使用（推奨）

```bash
# プロジェクトルートから
make docs-deploy
```

これにより、以下が自動的に実行されます:
1. docsディレクトリをgitに追加
2. コミット作成
3. mainブランチにプッシュ
4. GitHub Actionsが自動的にビルド＆デプロイ

#### 方法2: 手動でプッシュ

```bash
git add docs .github/workflows/deploy-docs.yml
git commit -m "Update documentation"
git push origin main
```

プッシュすると、`.github/workflows/deploy-docs.yml` のワークフローが自動的に実行されます。

### デプロイ状況の確認

1. GitHubリポジトリの **Actions** タブを開く
2. **Deploy Docs to GitHub Pages** ワークフローを確認
3. デプロイ完了後、以下のURLでアクセス可能:
   - `https://ユーザー名.github.io/リポジトリ名/`

### GitHub Pagesの利点

- ✅ 無料
- ✅ 自動デプロイ（mainブランチにプッシュするだけ）
- ✅ HTTPS対応
- ✅ カスタムドメイン設定可能

## Vercelへのデプロイ（代替手段）

Vercelを使用したい場合は、以下の手順でデプロイできます。

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

### GitHub Pagesを使用する場合
- プライバシーポリシー: `https://ユーザー名.github.io/リポジトリ名/privacy`
- 利用規約: `https://ユーザー名.github.io/リポジトリ名/terms`
- サポート: `https://ユーザー名.github.io/リポジトリ名/support`

### Vercelを使用する場合
- プライバシーポリシー: `https://your-domain.vercel.app/privacy`
- 利用規約: `https://your-domain.vercel.app/terms`
- サポート: `https://your-domain.vercel.app/support`

### カスタムドメインを設定する場合
GitHub PagesまたはVercelでカスタムドメインを設定すると、よりプロフェッショナルなURLになります。
例: `https://routy.app/privacy`

## ライセンス

Private
