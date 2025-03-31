@echo off
chcp 932
echo Open WebUI アンインストールツール

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
