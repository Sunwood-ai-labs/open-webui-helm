@echo off
echo "AWS EKSへのOpen WebUI Helm Chartのインストールを開始します..."

REM 必要なツールのチェック
echo "必要なツールを確認しています..."
where aws >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo "AWS CLIがインストールされていません。AWS CLIをインストールしてください。"
    exit /b 1
)

where kubectl >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo "kubectlがインストールされていません。kubectlをインストールしてください。"
    exit /b 1
)

where helm >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo "Helmがインストールされていません。Helmをインストールしてください。"
    exit /b 1
)

REM AWS認証情報の確認
echo.
echo "AWS認証情報を確認しています..."
aws sts get-caller-identity >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo "AWS認証に失敗しました。認証情報を確認してください。"
    exit /b 1
)

REM EKSクラスター名の入力
echo.
set /p cluster_name="EKSクラスター名を入力してください: "
if "%cluster_name%"=="" (
    echo "クラスター名が指定されていません。インストールを中止します。"
    exit /b 1
)

REM リージョンの入力
echo.
set /p region="AWSリージョンを入力してください（例: us-west-2）: "
if "%region%"=="" (
    echo "リージョンが指定されていません。インストールを中止します。"
    exit /b 1
)

REM kubeconfigの更新
echo.
echo "kubeconfigを更新しています..."
aws eks update-kubeconfig --region %region% --name %cluster_name%
if %ERRORLEVEL% neq 0 (
    echo "kubeconfigの更新に失敗しました。クラスター名とリージョンを確認してください。"
    exit /b 1
)

REM Helmリポジトリを追加
echo.
echo "Helmリポジトリを追加しています..."
helm repo add open-webui https://helm.openwebui.com/
helm repo update

REM インストールタイプの選択
echo.
echo "インストールタイプを選択してください："
echo "1) CPU専用モード"
echo "2) GPU対応モード"
set /p install_type="選択 (1 または 2): "

REM 名前空間の作成
echo.
echo "Kubernetes名前空間を作成しています..."
kubectl create namespace open-webui

REM 選択したタイプに基づいてインストール
if "%install_type%"=="1" (
    echo "CPU専用モードでインストールします..."
    helm install open-webui open-webui/open-webui -f values-eks.yaml -n open-webui
) else if "%install_type%"=="2" (
    echo "GPU対応モードでインストールします..."
    
    REM NVIDIA Device Pluginのインストール確認
    echo "NVIDIA Device Pluginがインストールされているか確認しています..."
    kubectl get daemonset -n kube-system nvidia-device-plugin-daemonset >nul 2>&1
    if %ERRORLEVEL% neq 0 (
        echo "NVIDIA Device Pluginがインストールされていません。インストールしますか？ (y/n): "
        set /p install_plugin="選択: "
        if "%install_plugin%"=="y" (
            echo "NVIDIA Device Pluginをインストールしています..."
            kubectl create -f https://raw.githubusercontent.com/NVIDIA/k8s-device-plugin/v0.14.0/nvidia-device-plugin.yml
        )
    )
    
    helm install open-webui open-webui/open-webui -f values-eks-gpu.yaml -n open-webui
) else (
    echo "無効な選択です。インストールを中止します。"
    exit /b 1
)

REM インストールステータスの確認
echo.
echo "インストールステータスを確認しています..."
helm status open-webui -n open-webui

REM ロードバランサーのエンドポイントを取得
echo.
echo "サービスが準備できるまで待機しています..."
timeout /t 30

echo "ロードバランサーのエンドポイントを取得しています..."
for /f %%i in ('kubectl get svc -n open-webui open-webui -o jsonpath="{.status.loadBalancer.ingress[0].hostname}"') do set lb_endpoint=%%i

if "%lb_endpoint%"=="" (
    echo "ロードバランサーのエンドポイントがまだ利用できません。"
    echo "しばらく待ってから以下のコマンドで確認してください："
    echo "kubectl get svc -n open-webui open-webui"
) else (
    echo.
    echo "Open WebUIにアクセスするには、以下のURLをブラウザで開いてください："
    echo "http://%lb_endpoint%:3000"
)

echo.
echo "インストールが完了しました。"
pause
