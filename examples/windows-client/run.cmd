@echo off
REM Spustac interaktivneho menu na Windowse (cmd / dvojklik).
REM Zobrazi vyber projektu z projects.json a spusti session.
REM Volitelne: run.cmd 2  -> rovno vyber projekt cislo 2.

cd /d "%~dp0"

where node >nul 2>nul
if errorlevel 1 (
  echo [x] Node.js nie je nainstalovany alebo nie je v PATH.
  echo     Nainstaluj Node 20+ z https://nodejs.org a spusti znova.
  pause
  exit /b 1
)

if not exist "node_modules" (
  echo [i] Instalujem zavislosti ^(npm install^)...
  call npm install
)

node "%~dp0menu.mjs" %*
pause
