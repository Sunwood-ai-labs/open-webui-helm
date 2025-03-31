::
:: Open WebUI Helmインストールツール
::

@echo off
chcp 932 > nul

echo [Open WebUI Helmインストールツール]

:: Helmリポジトリを追加
echo.
echo Helmリポジトリを追加しています...
helm repo add open-webui https://helm.openwebui.com/
helm repo update

:: インストールタイプの選択
echo.
echo インストールタイプを選択してください:
echo 1) CPU専用モード
echo 2) GPU対応モード
set /p "install_type=選択 (1 または 2): "

:: 名前空間の作成
echo.
echo Kubernetes名前空間を作成しています...
kubectl create namespace open-webui

:: 選択したタイプに基づいてインストール
if "%install_type%"=="1" (
    echo CPU専用モードでインストールします...
    helm install open-webui open-webui/open-webui -f values.yaml -n open-webui
) else if "%install_type%"=="2" (
    echo GPU対応モードでインストールします...
    helm install open-webui open-webui/open-webui -f values-gpu.yaml -n open-webui
) else (
    echo 無効な選択です。インストールを中止します。
    exit /b 1
)

echo.
echo インストールが完了しました。
echo サービスの準備ができるまで少し待ってください...
echo.
echo アクセス方法:
echo 1) Port Forwardを使用する場合:
echo    kubectl port-forward -n open-webui svc/open-webui 3000:3000
echo    その後、ブラウザで http://localhost:3000 にアクセスしてください。
echo.
echo 2) サービスのステータスを確認するには:
echo    kubectl get pods,svc -n open-webui

pause
