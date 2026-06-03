@echo off
REM ============================================================
REM  activate.bat - Ativa o venv neste terminal CMD
REM  Execute: activate.bat
REM ============================================================

if not exist "%~dp0venv\Scripts\activate.bat" (
    echo ERRO: venv nao encontrado. Execute setup_windows.bat primeiro.
    pause
    exit /b 1
)

REM Garante Docker no PATH
set "DOCKER_BIN=C:\Program Files\Docker\Docker\resources\bin"
if exist "%DOCKER_BIN%\docker.exe" set "PATH=%DOCKER_BIN%;%PATH%"

REM Forca encoding UTF-8 para o psycopg2 nao quebrar com mensagens em portugues
REM Code page 850 (padrao do Windows BR) faz o psycopg2 falhar no SCRAM auth
chcp 65001 >nul
set PGCLIENTENCODING=UTF8
set PYTHONIOENCODING=utf-8

call "%~dp0venv\Scripts\activate.bat"

echo.
echo venv ativado. dbt disponivel neste terminal.
echo.
dbt --version
