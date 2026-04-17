@echo off
chcp 65001 > nul
echo ==========================================================
echo  git ロックファイル清掃
echo  対象: 釣果データ収集ソフトV6.0開発
echo ==========================================================
echo.

cd /d "%~dp0"

if exist ".git\index.lock" (
  echo - .git\index.lock を削除します
  del /F /Q ".git\index.lock"
) else (
  echo - .git\index.lock なし
)

if exist ".git\objects\maintenance.lock" (
  echo - .git\objects\maintenance.lock を削除します
  del /F /Q ".git\objects\maintenance.lock"
) else (
  echo - .git\objects\maintenance.lock なし
)

if exist ".git\HEAD.lock" (
  echo - .git\HEAD.lock を削除します
  del /F /Q ".git\HEAD.lock"
) else (
  echo - .git\HEAD.lock なし
)

echo.
echo ==========================================================
echo  完了。Cowork に戻って push 操作を続行してください。
echo ==========================================================
pause
