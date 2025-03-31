@echo off
echo "Open WebUIへのポートフォワードを設定します..."
echo.
echo "Open WebUIにポートフォワードを設定しています..."
echo "ブラウザで http://localhost:3000 にアクセスしてください"
echo "このウィンドウを閉じるとポートフォワードが終了します"
echo.
kubectl port-forward -n open-webui svc/open-webui 3000:3000
