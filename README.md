# Open WebUI Helm Chart デプロイガイド

このリポジトリは、Kubernetes上にOpen WebUIをHelmチャートを使ってデプロイするためのファイル一式を含んでいます。

## 前提条件

- Kubernetesクラスターが設定済みであること
- Helmがインストール済みであること
- GPUリソースがある場合は、NVIDIA GPUドライバーとDevice Pluginが設定済みであること

## インストール手順

### 1. Helmリポジトリの追加

```bash
helm repo add open-webui https://helm.openwebui.com/
helm repo update
```

### 2. カスタム値ファイルの設定

`values.yaml`ファイルでは、Open WebUIの設定をカスタマイズできます。

### 3. Helmチャートのインストール

```bash
# CPU専用の場合
helm install open-webui open-webui/open-webui -f values.yaml -n open-webui --create-namespace

# GPUを有効にする場合
helm install open-webui open-webui/open-webui -f values-gpu.yaml -n open-webui --create-namespace
```

### 4. アクセス方法

インストール後、サービスにアクセスするには以下の方法があります：

- Port Forwardを使用する場合：
  ```bash
  kubectl port-forward -n open-webui svc/open-webui 3000:3000
  ```
  その後、ブラウザで `http://localhost:3000` にアクセス

- Ingressを設定している場合は、設定したホスト名でアクセス

## AWS EKSへのデプロイ方法

Open WebUIはAmazon EKS (Elastic Kubernetes Service)にも簡単にデプロイできます。

### 1. EKSクラスターの準備

#### EKSクラスターの作成
```bash
# eksctlを使用する場合の例
eksctl create cluster \
  --name open-webui-cluster \
  --version 1.29 \
  --region us-west-2 \
  --nodegroup-name standard-nodes \
  --node-type t3.large \
  --nodes 2 \
  --nodes-min 1 \
  --nodes-max 3 \
  --managed
```

#### GPUノードを追加（オプション）
```bash
# GPUノードグループを追加
eksctl create nodegroup \
  --cluster open-webui-cluster \
  --region us-west-2 \
  --name gpu-nodes \
  --node-type g4dn.xlarge \
  --nodes 1 \
  --nodes-min 1 \
  --nodes-max 2 \
  --managed
```

#### NVIDIA Device Pluginのインストール（GPUノードの場合）
```bash
kubectl create -f https://raw.githubusercontent.com/NVIDIA/k8s-device-plugin/v0.14.0/nvidia-device-plugin.yml
```

### 2. EKS用のvalues.yamlの修正

EKS用の設定を`values.yaml`および`values-gpu.yaml`に追加します：

#### ストレージクラスの設定
```yaml
# EKSのストレージクラス設定
ollama:
  persistence:
    storageClass: "gp3"  # AWSのEBSストレージクラス
```

#### ロードバランサーの設定（外部公開する場合）
```yaml
# サービスタイプをLoadBalancerに変更
service:
  type: LoadBalancer
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"  # Network Load Balancer
    service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled: "true"
```

### 3. EKSクラスターへのデプロイ

AWS CLIで認証情報を設定後、kubeconfigを更新します：
```bash
aws eks update-kubeconfig --region us-west-2 --name open-webui-cluster
```

Helmでデプロイ：
```bash
# CPU専用の場合
helm install open-webui open-webui/open-webui -f values-eks.yaml -n open-webui --create-namespace

# GPUを有効にする場合
helm install open-webui open-webui/open-webui -f values-eks-gpu.yaml -n open-webui --create-namespace
```

### 4. アクセス情報の取得

```bash
# ロードバランサーのエンドポイントを取得
kubectl get svc -n open-webui open-webui -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

このエンドポイントをブラウザで開き、Open WebUIにアクセスできます。

## アンインストール

```bash
helm uninstall open-webui -n open-webui
```

## 構成ファイルについて

- `values.yaml`: 基本的な設定を含むカスタム値ファイル
- `values-gpu.yaml`: GPU対応の設定を含むカスタム値ファイル
- `values-eks.yaml`: AWS EKS向けの設定を含むカスタム値ファイル（必要に応じて作成）
- `values-eks-gpu.yaml`: AWS EKS + GPU向けの設定を含むカスタム値ファイル（必要に応じて作成）
