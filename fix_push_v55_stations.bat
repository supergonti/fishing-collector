@echo off
chcp 65001 > nul

echo ==========================================================
echo  V5.5 observation-point fix - commit / pull / push
echo ==========================================================
echo.

cd /d "%~dp0"

echo [1/8] git lock cleanup
if exist ".git\index.lock"                    del /F /Q ".git\index.lock"
if exist ".git\HEAD.lock"                     del /F /Q ".git\HEAD.lock"
if exist ".git\objects\maintenance.lock"      del /F /Q ".git\objects\maintenance.lock"
echo       OK
echo.

echo [2/8] git status before
git status --short
echo.

echo [3/8] git add all changes
git add -A
if errorlevel 1 goto :err
echo       OK
echo.

echo [4/8] git commit
git commit -m "fix: V5.5 STATIONS use short names to match condition DB"
if errorlevel 1 (
  echo       nothing to commit, continuing
)
echo.

echo [5/8] git pull --rebase origin main
git pull --rebase origin main
if errorlevel 1 (
  echo.
  echo  ERROR: rebase conflict
  git rebase --abort
  goto :err
)
echo.

echo [6/8] Normalize pulled fishing_data.csv and regenerate integrated CSV
where python >nul 2>&1 && (set "PY=python") || (set "PY=py")
%PY% _normalize_stations.py
if errorlevel 1 goto :err
node scripts\merge-data.js
if errorlevel 1 goto :err
echo.

echo [7/8] Commit any regenerated changes
git add fishing_data.csv fishing_integrated.csv
git diff --cached --quiet
if errorlevel 1 (
  git commit -m "fix: normalize pulled nearest_station and regenerate integrated"
) else (
  echo       no further changes
)
echo.

echo [8/8] git push origin main
git push origin main
if errorlevel 1 goto :err
echo.

echo ==========================================================
echo  DONE.
echo ==========================================================
goto :end

:err
echo.
echo ==========================================================
echo  FAILED. See messages above.
echo ==========================================================

:end
pause
