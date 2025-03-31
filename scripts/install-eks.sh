#!/bin/bash

# Open WebUI EKSインストールツール

echo "[Open WebUI EKSインストールツール]"

# 必要なツールのチェック
echo
echo "必要なツールを確認しています..."

# AWS CLIのチェック
if ! command -v aws &> /dev/null; then
    echo "AWS CLIがインストールされていません。AWS CLIをインストールしてください。"
    exit 1
fi

# kubectlのチェック
if ! command -v kubectl &> /dev/null; then
    echo "kubectlがインストールされていません。kubectlをインストールしてください。"
    exit 1
fi

# Helmのチェック
if ! command -v helm &> /dev/null; then
    echo "Helmがインストールされていません。Helmをインストールしてください。"
    exit 1
fi

# AWS認証情報の確認
echo
echo "AWS認証情報を確認しています..."
if ! aws sts get-caller-identity &> /dev/null; then
    echo "AWS認証に失敗しました。認証情報を確認してください。"
    exit 1
fi

# EKSクラスター名の入力
echo
read -p "EKSクラスター名を入力してください: " cluster_name
if [ -z "$cluster_name" ]; then
    echo "クラスター名が指定されていません。処理を中止します。"
    exit 1
fi

# リージョンの入力
echo
read -p "AWSリージョンを入力してください（例: us-west-2）: " region
if [ -z "$region" ]; then
    echo "リージョンが指定されていません。処理を中止します。"
    exit 1
fi

# kubeconfigの更新
echo
echo "kubeconfigを更新しています..."
if ! aws eks update-kubeconfig --region "$region" --name "$cluster_name"; then
    echo "kubeconfigの更新に失敗しました。"
    exit 1
fi

# Helmリポジトリを追加
echo
echo "Helmリポジトリを追加しています..."
helm repo add open-webui https://helm.openwebui.com/
helm repo update

# インストールタイプの選択
echo
echo "インストールタイプを選択してください:"
echo "1) CPU専用モード"
echo "2) GPU対応モード"
read -p "選択 (1 または 2): " install_type

# 名前空間の作成
echo
echo "Kubernetes名前空間を作成しています..."
kubectl create namespace open-webui

# 選択したタイプに基づいてインストール
if [ "$install_type" = "1" ]; then
    echo "CPU専用モードでインストールします..."
    helm install open-webui open-webui/open-webui -f values-eks.yaml -n open-webui
elif [ "$install_type" = "2" ]; then
    echo "GPU対応モードでインストールします..."
    
    # NVIDIA Device Pluginのインストール確認
    echo "NVIDIA Device Pluginがインストールされているか確認しています..."
    if ! kubectl get daemonset -n kube-system nvidia-device-plugin-daemonset &> /dev/null; then
        echo -n "NVIDIA Device Pluginがインストールされていません。インストールしますか？ (y/n): "
        read install_plugin
        if [ "$install_plugin" = "y" ]; then
            echo "NVIDIA Device Pluginをインストールしています..."
            kubectl create -f https://raw.githubusercontent.com/NVIDIA/k8s-device-plugin/v0.14.0/nvidia-device-plugin.yml
        fi
    fi
    
    helm install open-webui open-webui/open-webui -f values-eks-gpu.yaml -n open-webui
else
    echo "無効な選択です。インストールを中止します。"
    exit 1
fi

# インストールステータスの確認
echo
echo "インストールステータスを確認しています..."
helm status open-webui -n open-webui

# サービスが準備できるまで待機
echo
echo "サービスが準備できるまで待機しています..."
sleep 30

# ロードバランサーのエンドポイントを取得
echo "ロードバランサーのエンドポイントを取得しています..."
lb_endpoint=$(kubectl get svc -n open-webui open-webui -o jsonpath="{.status.loadBalancer.ingress[0].hostname}")

if [ -z "$lb_endpoint" ]; then
    echo "ロードバランサーのエンドポイントがまだ利用できません。"
    echo "しばらく待ってから以下のコマンドで確認してください:"
    echo "kubectl get svc -n open-webui open-webui"
else
    echo
    echo "Open WebUIにアクセスするには、以下のURLをブラウザで開いてください:"
    echo "http://${lb_endpoint}:3000"
fi

echo
echo "インストールが完了しました。"
echo "Enterキーを押して終了してください..."
read
