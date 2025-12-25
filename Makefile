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

.PHONY: help
help:
	@echo "Routy 開発用コマンド"
	@echo ""
	@echo "make test-photos       - テスト写真を生成してシミュレータに追加"
	@echo "make clean-test-photos - 生成したテスト写真を削除"
