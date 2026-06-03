#!/bin/bash
# ============================================================
#  setup_macos.sh — Configuracao do ambiente dbt no macOS
#  Prerequisito: Python 3.9-3.13 (dbt-core 1.10.x nao suporta 3.14+)
# ============================================================

set -e

echo ""
echo "[0/5] Verificando versao do Python..."

# Tenta encontrar python3.13 ou 3.12 como fallback
PYTHON=""
for candidate in python3.13 python3.12; do
    if command -v "$candidate" > /dev/null 2>&1; then
        PYTHON="$candidate"
        break
    fi
done

# Fallback: checa se python3 generico esta na faixa 3.9-3.13
if [ -z "$PYTHON" ] && command -v python3 > /dev/null 2>&1; then
    version=$(python3 -c "import sys; print(sys.version_info.minor)")
    major=$(python3 -c "import sys; print(sys.version_info.major)")
    if [ "$major" = "3" ] && [ "$version" -ge 9 ] && [ "$version" -le 13 ]; then
        PYTHON="python3"
    fi
fi

if [ -z "$PYTHON" ]; then
    echo "Python 3.9-3.13 nao encontrado. Tentando instalar Python 3.13 via Homebrew..."
    if ! command -v brew > /dev/null 2>&1; then
        echo ""
        echo "ATENCAO: Homebrew nao encontrado."
        echo "Instale o Homebrew primeiro:"
        echo '  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
        echo "Depois execute: brew install python@3.13"
        exit 1
    fi
    brew install python@3.13
    PYTHON=$(brew --prefix python@3.13)/bin/python3.13
fi

echo "Usando: $PYTHON ($($PYTHON --version))"

echo ""
echo "[1/5] Criando ambiente virtual (venv)..."
if [ -d "venv" ]; then
    echo "Removendo venv antigo..."
    rm -rf venv
fi
"$PYTHON" -m venv venv || {
    echo "ERRO: Falha ao criar venv."
    exit 1
}

echo ""
echo "[2/5] Ativando venv e instalando dependencias..."
source venv/bin/activate
pip install --upgrade pip --quiet
pip install -r requirements.txt
echo ""
echo "[3/5] Copiando profiles.yml para ~/.dbt/ ..."
mkdir -p "$HOME/.dbt"
if [ ! -f "$HOME/.dbt/profiles.yml" ]; then
    cp profiles.yml.example "$HOME/.dbt/profiles.yml"
    echo "profiles.yml copiado para $HOME/.dbt/profiles.yml"
else
    echo "profiles.yml ja existe em $HOME/.dbt/ — pulando copia."
fi

echo ""
echo "[4/5] Verificando instalacao do dbt..."
dbt --version

echo ""
echo "[5/5] Verificando Docker..."

# Desativa o set -e para tratar erros manualmente nesta secao
set +e

if docker --version > /dev/null 2>&1; then
    echo "Docker ja instalado:"
    docker --version
    echo ""
    echo "Subindo PostgreSQL via Docker..."
    docker compose up -d
    if [ $? -ne 0 ]; then
        echo "AVISO: Falha ao subir o container."
        echo "       Verifique se o Docker Desktop esta rodando (icone na barra de menu)."
    else
        echo "PostgreSQL disponivel em localhost:5432"
    fi
else
    echo "Docker nao encontrado. Tentando instalar via Homebrew..."

    if ! command -v brew > /dev/null 2>&1; then
        echo ""
        echo "ATENCAO: Homebrew nao encontrado."
        echo "Instale o Homebrew primeiro:"
        echo '  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
        echo ""
        echo "Depois instale o Docker Desktop manualmente:"
        echo "  brew install --cask docker"
        echo "  Ou: https://www.docker.com/products/docker-desktop/"
    else
        echo "Instalando Docker Desktop via Homebrew..."
        brew install --cask docker
        if [ $? -ne 0 ]; then
            echo ""
            echo "ATENCAO: Falha ao instalar Docker automaticamente."
            echo "Instale manualmente em: https://www.docker.com/products/docker-desktop/"
        else
            echo ""
            echo "Docker Desktop instalado com sucesso."
            echo "IMPORTANTE: Abra o Docker Desktop pelo Launchpad ou Spotlight"
            echo "            e aguarde ele inicializar antes de continuar."
            echo "Depois execute: docker-compose up -d"
        fi
    fi
fi

echo ""
echo "============================================================"
echo " Setup concluido!"
echo ""
echo " Proximos passos:"
echo "   1. Suba o PostgreSQL (se ainda nao fez):  docker compose up -d"
echo "   2. Ative o venv:                          source venv/bin/activate"
echo "   3. Teste a conexao:                       dbt debug"
echo "   4. Carregue os seeds:                     dbt seed"
echo "   5. Execute os modelos:                    dbt run"
echo "   6. Rode os testes:                        dbt test"
echo "============================================================"
echo ""
