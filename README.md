# Open WebUI Helm Chart 🚀

![Image](https://github.com/user-attachments/assets/6b896cc6-34d4-402c-b407-7ba20b0c1afb)

このリポジトリは、Kubernetes上にOpen WebUIをデプロイするためのHelmチャートとデプロイスクリプト一式です。

## 構成図

![](docs/architect.svg)


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

### 🚀 クイックスタート（自動セットアップ）

```bash
# 1. EKSクラスターの作成（約15-20分かかります）
eksctl create cluster -f ./config/eks/cluster-config.yaml

# 2. Open WebUIのインストール（CPU版）
./scripts/install-eks.sh

# アクセス方法
# LoadBalancerのエンドポイント確認
kubectl get -n open-webui svc open-webui --watch

# または以下のコマンドで直接URLを取得
export EXTERNAL_IP=$(kubectl get -n open-webui svc open-webui -o jsonpath="{.status.loadBalancer.ingress[0].hostname}")
echo http://$EXTERNAL_IP:3000

# ローカルから接続する場合（オプション）：
./scripts/port-forward-eks.sh

# アンインストール時
./scripts/uninstall-eks.sh
```

### 📝 マニュアルセットアップ手順

1. EKSクラスターの作成

```bash
# クラスター作成
eksctl create cluster -f ./config/eks/cluster-config.yaml

# kubeconfigの更新
aws eks update-kubeconfig \
  --region ap-northeast-1 \
  --name open-webui-helm-cluster
```

2. Helmリポジトリの追加

```bash
helm repo add open-webui https://helm.openwebui.com/
helm repo update
```

3. Open WebUIのデプロイ

```bash
# CPU版のインストール
helm install open-webui open-webui/open-webui \
  -f config/helm/values-eks.yaml \
  -n open-webui \
  --create-namespace

# GPU版のインストール（オプション）
helm install open-webui open-webui/open-webui \
  -f config/helm/values-eks-gpu.yaml \
  -n open-webui \
  --create-namespace
```

4. デプロイ状態の確認

```bash
# Podの状態確認
kubectl get pods -n open-webui

# サービスのエンドポイント確認
kubectl get svc -n open-webui
```

5. アンインストール手順

```bash
# Helm リリースの削除
helm uninstall open-webui -n open-webui

# 名前空間の削除
kubectl delete namespace open-webui

# クラスターの削除
eksctl delete cluster -f ./config/eks/cluster-config.yaml \
  --force --disable-nodegroup-eviction
```

詳細は [EKSデプロイガイド](docs-eks.md) を参照してください。

## 📁 ディレクトリ構成

```
.
├── config/                # 設定ファイル
│   ├── eks/              # EKS関連設定
│   │   └── cluster-config.yaml  # EKSクラスター設定
│   └── helm/             # Helm値設定
│       ├── values.yaml         # 基本設定
│       ├── values-gpu.yaml     # GPU有効設定
│       ├── values-eks.yaml     # EKS用基本設定
│       └── values-eks-gpu.yaml # EKS用GPU有効設定
│
├── docs/                 # ドキュメント
│   ├── architect.dio     # アーキテクチャ図(draw.io)
│   ├── architect.svg     # アーキテクチャ図(SVG)
│   └── docs-eks.md      # EKSデプロイガイド
│
└── scripts/             # デプロイスクリプト
    ├── install.sh         # ローカルKubernetes用インストール
    ├── install-eks.sh     # EKS用インストール
    ├── port-forward.sh    # ローカルポートフォワード
    ├── port-forward-eks.sh # EKS用ポートフォワード
    ├── uninstall.sh       # ローカルKubernetes用アンインストール
    └── uninstall-eks.sh   # EKS用アンインストール
```

各種設定ファイルの詳細については [EKSデプロイガイド](docs-eks.md) を参照してください。

## 🔧 環境変数の設定

### 必須の環境変数

```bash
# AWS認証情報の設定
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="ap-northeast-1"

# kubectlのコンテキスト設定
export KUBECONFIG=~/.kube/config
```

### オプションの環境変数

```bash
# Open WebUIの設定
export OPENAI_API_KEY="your-api-key"  # OpenAI APIキー（オプション）
export OLLAMA_BASE_URL="http://open-webui-ollama:11434"  # Ollamaサーバーのアドレス

# GPUサポート設定（GPU版を使用する場合）
export NVIDIA_VISIBLE_DEVICES="all"    # 利用可能なGPUデバイス
```

## 🌟 機能と特徴

- ✨ EKSクラスターの自動セットアップ
- 🚀 簡単なデプロイプロセス
- 🎮 CPUモードとGPUモードの選択可能
- 🔄 オートスケーリングのサポート
- 💾 永続的なデータストレージ（EBS）
- 🔒 セキュアなネットワーク設定
