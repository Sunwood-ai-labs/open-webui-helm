# Open WebUI Helm Chart 🚀

このリポジトリは、Kubernetes上にOpen WebUIをデプロイするためのHelmチャートとデプロイスクリプト一式です。

## 💻 クイックスタート

### ローカルKubernetesへのインストール

```bash
# インストール
scripts/install.bat

# ポートフォワード設定
scripts/port-forward.bat

# アンインストール
scripts/uninstall.bat
```

バッチファイルを実行すると、対話形式で必要な情報を入力しながら自動でデプロイを行います。

## ☁️ AWS EKSへのデプロイ

```bash
# EKSへのインストール
scripts/install-eks.bat

# ポートフォワード設定（ローカルアクセス用）
scripts/port-forward-eks.bat

# アンインストール
scripts/uninstall-eks.bat
```

詳細は [EKSデプロイガイド](docs-eks.md) を参照してください。

## 📁 ディレクトリ構成

```
.
├── scripts/              # デプロイ用スクリプト
│   ├── install.bat          # ローカルKubernetes用インストール
│   ├── install-eks.bat      # EKS用インストール
│   ├── port-forward.bat     # ローカルポートフォワード
│   ├── port-forward-eks.bat # EKS用ポートフォワード
│   ├── uninstall.bat        # ローカルKubernetes用アンインストール
│   └── uninstall-eks.bat    # EKS用アンインストール
├── values.yaml          # 基本設定
├── values-gpu.yaml      # GPU有効設定
├── values-eks.yaml      # EKS用基本設定
└── values-eks-gpu.yaml  # EKS用GPU有効設定
```

各種設定ファイルの詳細については [EKSデプロイガイド](docs-eks.md) を参照してください。
