# Open WebUI Helm Chart 🚀

このリポジトリは、Kubernetes上にOpen WebUIをデプロイするためのHelmチャートとデプロイスクリプト一式です。

## 💻 クイックスタート

### ローカルKubernetesへのインストール

```bash
# インストール
install.bat

# ポートフォワード設定
port-forward.bat

# アンインストール
uninstall.bat
```

バッチファイルを実行すると、対話形式で必要な情報を入力しながら自動でデプロイを行います。

## ☁️ AWS EKSへのデプロイ

```bash
# EKSへのインストール
install-eks.bat
```

詳細は [EKSデプロイガイド](docs-eks.md) を参照してください。

## 📁 構成ファイル

各種設定ファイルの詳細については [EKSデプロイガイド](docs-eks.md) を参照してください。
