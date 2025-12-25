.PHONY: test-photos
test-photos:
	@echo "🎨 テスト写真を生成してシミュレータに追加します..."
	@python3 Scripts/generate_test_photos.py
	@echo "✅ 完了"

.PHONY: clean-test-photos
clean-test-photos:
	@echo "🗑️  テスト写真を削除します..."
	@rm -rf /tmp/routy_test_photos
	@echo "✅ 削除完了"

.PHONY: docs-install
docs-install:
	@echo "📦 ドキュメントサイトの依存関係をインストール..."
	@cd docs && npm install
	@echo "✅ 完了"

.PHONY: docs-dev
docs-dev:
	@echo "🚀 ドキュメントサイトの開発サーバーを起動..."
	@cd docs && npm run dev

.PHONY: docs-build
docs-build:
	@echo "🔨 ドキュメントサイトをビルド..."
	@cd docs && npm run build
	@echo "✅ ビルド完了 (docs/out)"

.PHONY: docs-deploy
docs-deploy:
	@echo "🚀 GitHub Pagesにデプロイ..."
	@git add docs
	@git commit -m "Update documentation" || true
	@git push origin main
	@echo "✅ プッシュ完了 - GitHub Actionsが自動的にデプロイします"

.PHONY: help
help:
	@echo "Routy 開発用コマンド"
	@echo ""
	@echo "【テスト写真】"
	@echo "make test-photos       - テスト写真を生成してシミュレータに追加"
	@echo "make clean-test-photos - 生成したテスト写真を削除"
	@echo ""
	@echo "【ドキュメントサイト】"
	@echo "make docs-install      - ドキュメントの依存関係をインストール"
	@echo "make docs-dev          - ドキュメントの開発サーバーを起動"
	@echo "make docs-build        - ドキュメントをビルド"
	@echo "make docs-deploy       - GitHub Pagesにデプロイ"
