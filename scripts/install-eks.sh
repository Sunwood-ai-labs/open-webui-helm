#!/bin/bash

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Open WebUI EKSインストールツール

echo -e "${CYAN}[Open WebUI EKSインストールツール]${NC}"

# 必要なツールのチェック
echo
echo -e "${BLUE}必要なツールを確認しています...${NC}"

# AWS CLIのチェック
if ! command -v aws &> /dev/null; then
    echo -e "${RED}AWS CLIがインストールされていません。AWS CLIをインストールしてください。${NC}"
    exit 1
fi

# kubectlのチェック
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}kubectlがインストールされていません。kubectlをインストールしてください。${NC}"
    exit 1
fi

# Helmのチェック
if ! command -v helm &> /dev/null; then
    echo -e "${RED}Helmがインストールされていません。Helmをインストールしてください。${NC}"
    exit 1
fi

# AWS認証情報の確認
echo
echo -e "${BLUE}AWS認証情報を確認しています...${NC}"
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}AWS認証に失敗しました。認証情報を確認してください。${NC}"
    exit 1
fi

# EKSクラスター名の設定
cluster_name=${1:-"open-webui-helm-cluster"}
echo -e "${CYAN}使用するクラスター名: ${cluster_name}${NC}"

# リージョンの設定（デフォルト値: ap-northeast-1）
region=${2:-"ap-northeast-1"}
echo -e "${CYAN}使用するリージョン: ${region}${NC}"

# kubeconfigの更新
echo
echo -e "${BLUE}kubeconfigを更新しています...${NC}"
if ! aws eks update-kubeconfig --region "$region" --name "$cluster_name"; then
    echo -e "${RED}kubeconfigの更新に失敗しました。${NC}"
    exit 1
fi

# Helmリポジトリを追加
echo
echo -e "${BLUE}Helmリポジトリを追加しています...${NC}"
helm repo add open-webui https://helm.openwebui.com/
helm repo update

# インストールタイプの選択
echo
echo -e "${MAGENTA}インストールタイプを選択してください:${NC}"
echo -e "${CYAN}1) CPU専用モード${NC}"
echo -e "${CYAN}2) GPU対応モード${NC}"
echo -e -n "${YELLOW}選択 (1 または 2): ${NC}"
read install_type

# 名前空間の作成
echo
echo -e "${BLUE}Kubernetes名前空間を作成しています...${NC}"
kubectl create namespace open-webui

# 選択したタイプに基づいてインストール
if [ "$install_type" = "1" ]; then
    echo -e "${GREEN}CPU専用モードでインストールします...${NC}"
    helm install open-webui open-webui/open-webui -f values-eks.yaml -n open-webui
elif [ "$install_type" = "2" ]; then
    echo -e "${GREEN}GPU対応モードでインストールします...${NC}"
    
    # NVIDIA Device Pluginのインストール確認
    echo -e "${BLUE}NVIDIA Device Pluginがインストールされているか確認しています...${NC}"
    if ! kubectl get daemonset -n kube-system nvidia-device-plugin-daemonset &> /dev/null; then
        echo -e -n "${YELLOW}NVIDIA Device Pluginがインストールされていません。インストールしますか？ (y/n): ${NC}"
        read install_plugin
        if [ "$install_plugin" = "y" ]; then
            echo -e "${BLUE}NVIDIA Device Pluginをインストールしています...${NC}"
            kubectl create -f https://raw.githubusercontent.com/NVIDIA/k8s-device-plugin/v0.14.0/nvidia-device-plugin.yml
        fi
    fi
    
    helm install open-webui open-webui/open-webui -f values-eks-gpu.yaml -n open-webui
else
    echo -e "${RED}無効な選択です。インストールを中止します。${NC}"
    exit 1
fi

# インストールステータスの確認
echo
echo -e "${BLUE}インストールステータスを確認しています...${NC}"
helm status open-webui -n open-webui

# サービスが準備できるまで待機
echo
echo -e "${BLUE}サービスが準備できるまで待機しています...${NC}"
sleep 30

# ロードバランサーのエンドポイントを取得
echo -e "${BLUE}ロードバランサーのエンドポイントを取得しています...${NC}"
lb_endpoint=$(kubectl get svc -n open-webui open-webui -o jsonpath="{.status.loadBalancer.ingress[0].hostname}")

if [ -z "$lb_endpoint" ]; then
    echo -e "${YELLOW}ロードバランサーのエンドポイントがまだ利用できません。${NC}"
    echo -e "${YELLOW}しばらく待ってから以下のコマンドで確認してください:${NC}"
    echo -e "${CYAN}kubectl get svc -n open-webui open-webui${NC}"
else
    echo
    echo -e "${GREEN}Open WebUIにアクセスするには、以下のURLをブラウザで開いてください:${NC}"
    echo -e "${CYAN}http://${lb_endpoint}:3000${NC}"
fi

echo
echo -e "${GREEN}インストールが完了しました。${NC}"
echo -e "${YELLOW}Enterキーを押して終了してください...${NC}"
read
