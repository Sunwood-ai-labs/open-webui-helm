@echo off
chcp 932
echo Open WebUI EKSポートフォワード設定ツール

rem EKSクラスター名の入力
set /p cluster_name=EKSクラスター名を入力してください: 
if "%cluster_name%"=="" (
    echo クラスター名が指定されていません。処理を中止します。
    exit /b 1
)

rem リージョンの入力
set /p region=AWSリージョンを入力してください（例: us-west-2）: 
if "%region%"=="" (
    echo リージョンが指定されていません。処理を中止します。
    exit /b 1
)

rem kubeconfigの更新
echo.
echo kubeconfigを更新しています...
aws eks update-kubeconfig --region %region% --name %cluster_name%
if %ERRORLEVEL% neq 0 (
    echo kubeconfigの更新に失敗しました。
    exit /b 1
)

echo.
echo Open WebUIにポートフォワードを設定しています...
echo ブラウザで http://localhost:3000 にアクセスしてください
echo このウィンドウを閉じるとポートフォワードが終了します
echo.
kubectl port-forward -n open-webui svc/open-webui 3000:3000
