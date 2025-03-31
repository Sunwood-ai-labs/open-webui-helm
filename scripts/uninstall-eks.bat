@echo off
chcp 932
echo Open WebUI EKSアンインストールツール

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

rem アンインストールの確認
echo.
set /p confirm=本当にアンインストールしますか？ (y/n): 

if not "%confirm%"=="y" (
    echo アンインストールを中止しました。
    exit /b 0
)

rem Helmリリースのアンインストール
echo.
echo Helmリリースをアンインストールしています...
helm uninstall open-webui -n open-webui

rem PVCの削除を確認
echo.
set /p delete_pvc=永続ボリューム要求(PVC)も削除しますか？データが失われます (y/n): 

if "%delete_pvc%"=="y" (
    echo PVCを削除しています...
    kubectl delete pvc --all -n open-webui
)

rem ロードバランサーの削除を確認
echo.
set /p delete_lb=AWS Load Balancerも削除しますか？ (y/n): 

if "%delete_lb%"=="y" (
    echo Load Balancerを削除しています...
    kubectl delete svc open-webui -n open-webui
)

rem 名前空間の削除を確認
echo.
set /p delete_ns=名前空間も削除しますか？ (y/n): 

if "%delete_ns%"=="y" (
    echo 名前空間を削除しています...
    kubectl delete namespace open-webui
)

echo.
echo アンインストールが完了しました。
pause
