@echo off
REM ============================================================
REM  setup_windows.bat  - Executar UMA VEZ apos clonar o repo
REM
REM  Pre-requisitos:
REM    - Docker Desktop instalado e rodando
REM    - Python 3.9-3.13 instalado (3.14+ nao suportado pelo dbt)
REM      Download: https://www.python.org/downloads/release/python-3130/
REM ============================================================

echo.
echo [1/4] Verificando pre-requisitos...

REM --- Procura Python 3.13, 3.12, 3.11, 3.10 ou 3.9 (nessa ordem) ---
set PYTHON_CMD=
for %%v in (3.13 3.12 3.11 3.10 3.9) do (
    if not defined PYTHON_CMD (
        py -%%v --version >nul 2>&1
        if not errorlevel 1 set PYTHON_CMD=py -%%v
    )
)

if not defined PYTHON_CMD (
    echo ERRO: Python 3.9-3.13 nao encontrado.
    echo O dbt ainda nao suporta Python 3.14+.
    echo Instale Python 3.13: https://www.python.org/downloads/release/python-3130/
    echo Marque "Add Python to PATH" durante a instalacao.
    pause & exit /b 1
)
%PYTHON_CMD% --version
echo Usando: %PYTHON_CMD%

REM --- Forca UTF-8 para psycopg2/PostgreSQL no Windows ---
REM Code page 850 (padrao do Windows BR) faz o psycopg2 falhar no SCRAM auth
chcp 65001 >nul
set PGCLIENTENCODING=UTF8
set PYTHONIOENCODING=utf-8

REM --- Docker: adiciona ao PATH se necessario ---
set "DOCKER_BIN=C:\Program Files\Docker\Docker\resources\bin"
if exist "%DOCKER_BIN%\docker.exe" set "PATH=%DOCKER_BIN%;%PATH%"

docker info >nul 2>&1
if errorlevel 1 (
    echo ERRO: Docker nao esta respondendo.
    echo Verifique se o Docker Desktop esta aberto e com o icone da baleia verde.
    echo Se acabou de abrir, aguarde alguns segundos e tente novamente.
    pause & exit /b 1
)
echo Docker OK.

echo.
echo [2/4] Criando ambiente virtual com %PYTHON_CMD%...
if exist venv (
    echo Removendo venv anterior...
    rmdir /s /q venv 2>nul
    if exist venv (
        echo ERRO: Nao foi possivel remover a pasta venv.
        echo Feche qualquer terminal que tenha o venv ativado e tente novamente.
        pause & exit /b 1
    )
)
%PYTHON_CMD% -m venv venv
if errorlevel 1 ( echo ERRO ao criar venv. & pause & exit /b 1 )

echo.
echo [3/4] Instalando dbt no venv...
venv\Scripts\python.exe -m pip install --upgrade pip --quiet
venv\Scripts\pip.exe install -r requirements.txt
if errorlevel 1 ( echo ERRO ao instalar dependencias. & pause & exit /b 1 )
echo dbt instalado com sucesso.
venv\Scripts\dbt.exe --version

echo.
echo [4/4] Configurando profiles.yml e subindo PostgreSQL...
if not exist "%USERPROFILE%\.dbt" mkdir "%USERPROFILE%\.dbt"
if not exist "%USERPROFILE%\.dbt\profiles.yml" (
    copy /y profiles.yml.example "%USERPROFILE%\.dbt\profiles.yml" >nul
    echo profiles.yml criado em %USERPROFILE%\.dbt\
) else (
    echo profiles.yml ja existe em %USERPROFILE%\.dbt\ - mantendo existente.
)

docker compose up -d --remove-orphans
if errorlevel 1 ( echo ERRO ao subir PostgreSQL. & pause & exit /b 1 )

echo Aguardando PostgreSQL...
:wait
docker compose exec postgres pg_isready -U dbt_user -d dbt_demo >nul 2>&1
if errorlevel 1 ( timeout /t 2 /nobreak >nul & goto wait )
echo PostgreSQL pronto.

echo.
echo ============================================================
echo  Setup concluido!
echo.
echo  Para comecar a usar o dbt, execute:
echo.
echo    activate.bat
echo.
echo  Isso abre um terminal CMD com dbt pronto para usar.
echo  Depois rode os comandos normalmente:
echo    dbt debug
echo    dbt seed
echo    dbt run
echo    dbt test
echo.
echo  Para parar o PostgreSQL: docker compose down
echo ============================================================
echo.
pause
