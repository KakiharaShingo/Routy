# GitHub Pages セットアップガイド

このガイドでは、RoutyのドキュメントサイトをGitHub Pagesで公開する手順を説明します。

## 📋 前提条件

- GitHubアカウント
- このリポジトリをGitHubにプッシュ済み
- Node.js 20以上がインストール済み

## 🚀 セットアップ手順

### ステップ1: GitHubリポジトリの設定

1. GitHubでリポジトリを開く
2. **Settings** タブをクリック
3. 左メニューから **Pages** を選択
4. **Source** を **GitHub Actions** に設定
5. 保存

![GitHub Pages設定](https://docs.github.com/assets/cb-48868/mw-1440/images/help/pages/create-page-from-actions.webp)

### ステップ2: ワークフローファイルの確認

以下のファイルがリポジトリに存在することを確認:
- `.github/workflows/deploy-docs.yml`

このファイルは既に作成済みなので、何もする必要はありません。

### ステップ3: 初回デプロイ

プロジェクトルートで以下のコマンドを実行:

```bash
# 依存関係をインストール
make docs-install

# ローカルでビルドテスト（オプション）
make docs-build

# GitHub Pagesにデプロイ
make docs-deploy
```

または手動で:

```bash
git add docs .github/workflows/deploy-docs.yml
git commit -m "Setup GitHub Pages for documentation"
git push origin main
```

### ステップ4: デプロイの確認

1. GitHubリポジトリの **Actions** タブを開く
2. **Deploy Docs to GitHub Pages** ワークフローが実行中であることを確認
3. ワークフローが完了するまで待つ（通常1-2分）
4. 緑のチェックマークが表示されれば成功

### ステップ5: サイトにアクセス

デプロイが完了したら、以下のURLでアクセスできます:

```
https://ユーザー名.github.io/リポジトリ名/
```

例:
- トップページ: `https://shingo.github.io/Routy/`
- プライバシーポリシー: `https://shingo.github.io/Routy/privacy`
- 利用規約: `https://shingo.github.io/Routy/terms`
- サポート: `https://shingo.github.io/Routy/support`

## 🔄 更新方法

ドキュメントを更新する場合:

1. `docs/app/` 内のファイルを編集
2. 最終更新日を変更（必要に応じて）
3. デプロイ:

```bash
make docs-deploy
```

または:

```bash
git add docs
git commit -m "Update documentation"
git push origin main
```

プッシュすると自動的にビルド＆デプロイされます。

## 🛠️ トラブルシューティング

### デプロイが失敗する

**原因1: GitHub Actionsの権限不足**

1. GitHubリポジトリの **Settings** → **Actions** → **General** を開く
2. **Workflow permissions** を **Read and write permissions** に設定
3. 保存して再度プッシュ

**原因2: Node.jsのバージョン**

`.github/workflows/deploy-docs.yml` でNode.jsのバージョンを確認:
```yaml
node-version: '20'
```

**原因3: ビルドエラー**

ローカルでビルドテスト:
```bash
cd docs
npm install
npm run build
```

エラーメッセージを確認して修正してください。

### サイトが表示されない

1. GitHub Pagesの設定を確認（Settings → Pages）
2. **Source** が **GitHub Actions** になっているか確認
3. デプロイのステータスを確認（Actions タブ）
4. ブラウザのキャッシュをクリア

### 404エラーが出る

リポジトリ名がURLに含まれているか確認:
```
https://ユーザー名.github.io/リポジトリ名/privacy
                             ^^^^^^^^^^^ これが必要
```

## 🎨 カスタマイズ

### カスタムドメインを設定する

1. GitHubリポジトリの **Settings** → **Pages** を開く
2. **Custom domain** に自分のドメインを入力（例: `docs.routy.app`）
3. DNSレコードを設定:
   - Aレコード: GitHubのIPアドレス
   - または CNAMEレコード: `ユーザー名.github.io`
4. **Enforce HTTPS** にチェック

詳細: [GitHub Docs - Custom domains](https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site)

### デザインの変更

`docs/app/globals.css` を編集してスタイルをカスタマイズできます。

## 📱 App Store Connect での設定

デプロイ後、App Store Connectで以下のURLを設定:

1. **App Privacy** (アプリのプライバシー)
   - Privacy Policy URL: `https://ユーザー名.github.io/リポジトリ名/privacy`

2. **App Information** (アプリの情報)
   - Privacy Policy URL: `https://ユーザー名.github.io/リポジトリ名/privacy`
   - Terms of Use URL: `https://ユーザー名.github.io/リポジトリ名/terms`
   - Support URL: `https://ユーザー名.github.io/リポジトリ名/support`

## ✅ チェックリスト

- [ ] GitHub Pagesの設定完了（Settings → Pages → Source: GitHub Actions）
- [ ] ワークフローファイルが存在（`.github/workflows/deploy-docs.yml`）
- [ ] 初回デプロイ完了（Actions タブで確認）
- [ ] サイトにアクセス可能（ブラウザで確認）
- [ ] プライバシーポリシーページが表示される
- [ ] 利用規約ページが表示される
- [ ] サポートページが表示される
- [ ] App Store ConnectにURLを設定

## 📚 参考リンク

- [GitHub Pages Documentation](https://docs.github.com/en/pages)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Next.js Static Exports](https://nextjs.org/docs/app/building-your-application/deploying/static-exports)
- [App Store Connect Help](https://developer.apple.com/help/app-store-connect/)

## 💡 ヒント

- ドキュメントの変更は、mainブランチにプッシュすると自動的にデプロイされます
- デプロイには通常1-2分かかります
- GitHub Actionsのログで詳細なエラー情報を確認できます
- カスタムドメインを設定すると、よりプロフェッショナルな印象になります
