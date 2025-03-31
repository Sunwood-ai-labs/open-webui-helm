# Open WebUI - AWS EKS デプロイ詳細ガイド

## 🌟 設定ファイルの詳細

### CPU用の設定（values-eks.yaml）

```yaml
# リソース設定
resources:
  limits:
    cpu: 1000m    # CPU制限: 1コア
    memory: 2Gi   # メモリ制限: 2GB
  requests:
    cpu: 500m     # 最小CPU要求: 0.5コア
    memory: 1Gi   # 最小メモリ要求: 1GB

# Ollama設定
ollama:
  resources:
    limits:
      cpu: 2000m    # CPU制限: 2コア
      memory: 4Gi   # メモリ制限: 4GB
    requests:
      cpu: 1000m    # 最小CPU要求: 1コア
      memory: 2Gi   # 最小メモリ要求: 2GB
  persistence:
    enabled: true
    size: 20Gi      # ストレージサイズ: 20GB
    storageClass: "gp3"  # AWSのEBSストレージクラス
```

## 🚀 手動デプロイの詳細手順

### 1. EKSクラスターの準備

#### EKSクラスターの作成
```bash
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

#### GPUノードの追加（オプション）
```bash
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

### 2. 各種設定の適用

#### NVIDIA Device Pluginのインストール（GPUノードの場合）
```bash
kubectl create -f https://raw.githubusercontent.com/NVIDIA/k8s-device-plugin/v0.14.0/nvidia-device-plugin.yml
```

#### kubeconfigの更新
```bash
aws eks update-kubeconfig --region us-west-2 --name open-webui-cluster
```

#### Helmリポジトリの追加
```bash
helm repo add open-webui https://helm.openwebui.com/
helm repo update
```

### 3. デプロイ実行

#### CPU専用の場合
```bash
helm install open-webui open-webui/open-webui -f values-eks.yaml -n open-webui --create-namespace
```

#### GPUを有効にする場合
```bash
helm install open-webui open-webui/open-webui -f values-eks-gpu.yaml -n open-webui --create-namespace
```

### 4. デプロイ後の設定

#### ロードバランサーのエンドポイント取得
```bash
kubectl get svc -n open-webui open-webui -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

## 🔧 トラブルシューティング

### ポッドのステータス確認
```bash
kubectl get pods -n open-webui
```

### ログの確認
```bash
kubectl logs -n open-webui deployment/open-webui
kubectl logs -n open-webui deployment/open-webui-ollama
```

### 再起動
```bash
kubectl rollout restart deployment/open-webui -n open-webui
kubectl rollout restart deployment/open-webui-ollama -n open-webui
