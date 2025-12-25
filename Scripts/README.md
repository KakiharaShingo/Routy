# テスト画像生成スクリプトについて

## 問題

Pythonスクリプト `generate_test_photos.py` は、アーキテクチャの不一致により実行できません。
- Pillowライブラリがarm64でビルドされている
- システムのPython3がx86_64（Rosetta経由）で実行されている

## 解決策

以下の3つの方法でテストデータを生成できます：

### 方法1: アプリ内機能を使用（最も簡単・推奨）

1. アプリを起動
2. プロフィールタブ → デバッグ機能
3. 「テスト写真を生成」ボタンをタップ

詳細は `README_TEST_DATA.md` を参照してください。

### 方法2: Pythonの依存関係を修正して実行

```bash
# Pillowを再インストール
python3 -m pip uninstall Pillow
python3 -m pip install --user Pillow piexif

# スクリプトを実行
python3 Scripts/generate_test_photos.py
```

### 方法3: Homebrewのpython3を使用

```bash
# Homebrewでpython3をインストール（arm64ネイティブ）
brew install python3

# 依存関係をインストール
/opt/homebrew/bin/python3 -m pip install Pillow piexif

# スクリプトを実行
/opt/homebrew/bin/python3 Scripts/generate_test_photos.py
```

## 推奨

**アプリ内機能を使用**することを強く推奨します。
- 依存関係なし
- セットアップ不要
- UIで簡単に操作
- 確実に動作

Pythonスクリプトは参考実装として残しています。
