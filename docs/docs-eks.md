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

1. まず、cluster-config.yamlを作成します：

```yaml
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: open-webui-helm-cluster
  region: ap-northeast-1

nodeGroups:
  - name: ng-1
    instanceType: t3.large
    desiredCapacity: 2
    minSize: 1
    maxSize: 3
```

2. クラスターを作成します：

```bash
eksctl create cluster -f cluster-config.yaml
```

クラスターの作成には15-20分程度かかります。完了するまでお待ちください。

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

### 4. クラスター情報の確認

作成したEKSクラスターの情報は以下のコマンドで確認できます：

```bash
# ノードの確認
kubectl get nodes -o wide

# クラスター情報の確認
eksctl get cluster --name=open-webui-helm-cluster --region=ap-northeast-1

# クラスターのステータス確認
aws eks describe-cluster --name open-webui-helm-cluster --region ap-northeast-1
```

### 5. デプロイ後の設定と確認

#### ロードバランサーのエンドポイント取得
```bash
# エンドポイントの確認
kubectl get svc -n open-webui open-webui --watch

# または以下のコマンドでURLを直接取得
export EXTERNAL_IP=$(kubectl get -n open-webui svc open-webui -o jsonpath="{.status.loadBalancer.ingress[0].hostname}")
echo http://$EXTERNAL_IP:3000
```

#### 初期設定
1. ブラウザでLoadBalancerのエンドポイントにアクセス
2. 管理者アカウントを作成
3. Ollamaモデルのダウンロードと設定

#### ヘルスチェック
```bash
# Podの状態確認
kubectl get pods -n open-webui

# イベントログの確認
kubectl get events -n open-webui

# Podの詳細情報
kubectl describe pod -n open-webui -l app.kubernetes.io/name=open-webui
```

## 🔧 トラブルシューティング

### よくある問題と解決方法

#### 1. Podが起動しない場合
```bash
# ログの確認
kubectl logs -n open-webui deployment/open-webui
kubectl logs -n open-webui deployment/open-webui-ollama

# Pod詳細の確認
kubectl describe pod -n open-webui -l app.kubernetes.io/name=open-webui
```

#### 2. LoadBalancerにアクセスできない場合
```bash
# LoadBalancerの状態確認
kubectl get svc -n open-webui
kubectl describe svc -n open-webui open-webui

# セキュリティグループの確認
aws ec2 describe-security-groups --filters Name=group-name,Values=*open-webui*
```

#### 3. モデルのダウンロードが失敗する場合
```bash
# Ollamaのログ確認
kubectl logs -f -n open-webui deployment/open-webui-ollama

# ストレージの使用状況確認
kubectl get pvc -n open-webui
```

### システムの再起動と更新

#### Podの再起動
```bash
# 特定のPodの再起動
kubectl rollout restart deployment/open-webui -n open-webui
kubectl rollout restart deployment/open-webui-ollama -n open-webui

# デプロイメントの状態確認
kubectl rollout status deployment/open-webui -n open-webui
```

#### Helmリリースの更新
```bash
# 設定の更新
helm upgrade open-webui open-webui/open-webui \
  -f config/helm/values-eks.yaml \
  -n open-webui

# リリース履歴の確認
helm history open-webui -n open-webui

# 前のリリースにロールバック（必要な場合）
helm rollback open-webui 1 -n open-webui
```

### リソースのクリーンアップ
```bash
# 特定のリソースの削除
kubectl delete pod <pod-name> -n open-webui
kubectl delete pvc <pvc-name> -n open-webui

# 名前空間ごと削除
kubectl delete namespace open-webui

# Helmリリースの削除
helm uninstall open-webui -n open-webui
```
