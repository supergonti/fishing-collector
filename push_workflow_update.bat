@echo off
setlocal

cd /d "%~dp0"

echo === Step 1: remove stale .git/index.lock if exists ===
if exist ".git\index.lock" (
    del /f /q ".git\index.lock"
    echo removed .git\index.lock
) else (
    echo no stale lock file
)
echo.

echo === Step 2: show current status for the workflow file ===
git status --short .github/workflows/update-conditions.yml
echo.

echo === Step 3: stage only update-conditions.yml ===
git add .github/workflows/update-conditions.yml
if errorlevel 1 goto :fail_stage
echo.

echo === Step 4: show staged diff ===
git diff --staged --stat
echo.

echo === Step 5: commit (skip if nothing to commit) ===
git diff --staged --quiet
if errorlevel 1 (
    git commit -m "workflow: add push trigger for fishing_data.csv"
    if errorlevel 1 goto :fail_commit
) else (
    echo nothing new to commit, proceeding to pull/push
)
echo.

echo === Step 6a: fetch remote and rebase (autostash local CRLF noise) ===
git pull --rebase --autostash origin main
if errorlevel 1 goto :fail_pull
echo.

echo === Step 6b: push ===
git push
if errorlevel 1 goto :fail_push
echo.

echo ================================================================
echo  DONE. workflow updated on GitHub.
echo  Next: press the "GitHub save" button in V5.5 again, then check Actions:
echo    https://github.com/supergonti/fishing-collector/actions
echo ================================================================
pause
exit /b 0

:fail_stage
echo [!] git add failed.
pause
exit /b 1

:fail_commit
echo [!] git commit failed. See messages above.
pause
exit /b 1

:fail_pull
echo [!] git pull --rebase failed.
echo     If rebase is in progress, run: git rebase --abort
echo     then re-run this bat.
pause
exit /b 1

:fail_push
echo [!] git push failed. Sign in via GitHub Desktop or browser once, then re-run.
pause
exit /b 1
