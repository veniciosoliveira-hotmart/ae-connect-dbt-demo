# ae-connect-dbt-demo

Projeto dbt de demonstração usando PostgreSQL como data warehouse, com dados fictícios de clientes, pedidos e produtos.

---

## Pré-requisitos

| Ferramenta | Versão | Notas |
|---|---|---|
| Python | 3.9 – 3.13 | **dbt-core 1.10.x não suporta Python 3.14+** |
| Docker Desktop | qualquer recente | Para subir o PostgreSQL localmente |
| DBeaver | qualquer recente | Para visualizar os modelos criados |

> **Windows:** durante a instalação do Python, marque **"Add Python to PATH"** e instale o **Python Launcher (`py`)**. O script de setup usa `py -3.13`, `py -3.12` etc. para encontrar a versão correta.

---

## Setup no Windows

Execute **uma única vez** após clonar o repositório. Abra o **CMD como usuário normal** (não precisa de administrador) na pasta do projeto:

```cmd
setup_windows.bat
```

O script realiza automaticamente:
1. Detecta Python 3.9–3.13 via Python Launcher (`py`)
2. Cria o ambiente virtual em `venv\`
3. Instala `dbt-core` e `dbt-postgres` via `pip`
4. Copia `profiles.yml.example` para `%USERPROFILE%\.dbt\profiles.yml` (apenas se ainda não existir)
5. Sobe o PostgreSQL via `docker compose up -d`
6. Aguarda o banco estar pronto antes de sair

Ao final, você verá:

```
Setup concluido!
Para comecar a usar o dbt, execute:
  activate.bat
```

### Usando o dbt no Windows

A cada nova sessão de terminal, execute `activate.bat` para ativar o venv e configurar o encoding correto:

```cmd
activate.bat
```

Depois rode os comandos normalmente:

```cmd
dbt debug
dbt seed
dbt run
dbt test
```

> **Por que `activate.bat` e não o activate padrão do venv?**
> O `activate.bat` força o code page UTF-8 (`chcp 65001`) e define `PGCLIENTENCODING=UTF8`. Sem isso, o `psycopg2` pode falhar na autenticação SCRAM com o PostgreSQL quando o Windows está configurado para português (code page 850).

---

## Setup no macOS

Execute **uma única vez** após clonar o repositório. Abra o **Terminal** na pasta do projeto:

```bash
chmod +x setup_macos.sh
./setup_macos.sh
```

O script realiza automaticamente:
1. Detecta Python 3.9–3.13 (tenta `python3.13`, `python3.12`, depois `python3` genérico)
2. Se não encontrar Python compatível, tenta instalar `python@3.13` via Homebrew
3. Cria o ambiente virtual em `venv/`
4. Instala `dbt-core` e `dbt-postgres` via `pip`
5. Copia `profiles.yml.example` para `~/.dbt/profiles.yml` (apenas se ainda não existir)
6. Verifica o Docker e sobe o PostgreSQL via `docker compose up -d`

Se o Docker não estiver instalado, o script tenta instalá-lo via `brew install --cask docker`. Caso o Homebrew também não esteja presente, serão exibidas instruções manuais.

### Usando o dbt no macOS

A cada nova sessão de terminal, ative o venv:

```bash
source venv/bin/activate
```

Depois rode os comandos normalmente:

```bash
dbt debug
dbt seed
dbt run
dbt test
```

Para desativar o venv quando terminar:

```bash
deactivate
```

---

## Comandos dbt essenciais

| Comando | O que faz |
|---|---|
| `dbt debug` | Testa a conexão com o PostgreSQL e valida o projeto |
| `dbt seed` | Carrega os arquivos CSV de `data/` nas tabelas do banco |
| `dbt run` | Executa todos os modelos SQL (cria views e tabelas) |
| `dbt test` | Roda os testes definidos nos modelos |
| `dbt run --select staging` | Executa apenas os modelos da camada staging |
| `dbt run --select marts` | Executa apenas os modelos da camada marts |
| `docker compose down` | Para e remove o container do PostgreSQL |
| `docker compose up -d` | Sobe o PostgreSQL novamente |

---

## Conexão com o PostgreSQL

O PostgreSQL sobe na porta **5433** (não 5432, para evitar conflito com instalações locais).

| Parâmetro | Valor padrão |
|---|---|
| Host | `localhost` |
| Porta | `5433` |
| Banco | `dbt_demo` |
| Usuário | `dbt_user` |
| Senha | `dbt_pass` |

O arquivo `profiles.yml` é gerado pelo script de setup em `~/.dbt/profiles.yml` (macOS/Linux) ou `%USERPROFILE%\.dbt\profiles.yml` (Windows). Edite-o diretamente se precisar ajustar as credenciais, ou defina variáveis de ambiente para sobrescrever os valores padrão:

| Variável | Padrão |
|---|---|
| `DBT_PG_HOST` | `localhost` |
| `DBT_PG_USER` | `dbt_user` |
| `DBT_PG_PASSWORD` | `dbt_pass` |
| `DBT_PG_DATABASE` | `dbt_demo` |
| `DBT_PG_SCHEMA` | `public` |

---

## Conectando ao banco pelo DBeaver

### 1. Criar nova conexão

Abra o DBeaver e clique em **Database → New Database Connection** (ou `Ctrl+Shift+N`). Selecione **PostgreSQL** e clique em **Next**.

### 2. Preencher as credenciais

| Campo | Valor |
|---|---|
| Host | `localhost` |
| Port | `5433` |
| Database | `dbt_demo` |
| Username | `dbt_user` |
| Password | `dbt_pass` |

> **Atenção:** o campo **Database** deve ser `dbt_demo`, não `postgres`. Conectar no banco `postgres` (banco padrão do PostgreSQL) não mostrará nenhuma tabela criada pelo dbt.

### 3. Testar e finalizar

Clique em **Test Connection** para validar. Se aparecer "Connected", clique em **Finish**.

### 4. Onde estão as tabelas

Após rodar `dbt seed` e `dbt run`, navegue no painel esquerdo do DBeaver:

```
dbt_demo
└── Schemas
    ├── public_staging   ← modelos da camada staging
    │   ├── stg_clientes
    │   ├── stg_pedidos
    │   └── stg_produtos
    └── public_marts     ← modelos da camada marts
```

> O dbt gera os schemas com o prefixo do schema-alvo (`public`) concatenado com o schema customizado definido no `dbt_project.yml` (`staging`, `marts`), resultando em `public_staging` e `public_marts`. As tabelas **não** ficam no schema `public`.

Se os schemas não aparecerem após conectar, clique com o botão direito em **Schemas** e selecione **Refresh**.

---

## Estrutura de pastas

```
ae-connect-dbt-demo/
├── data/                   # Seeds: arquivos CSV carregados com `dbt seed`
│   ├── clientes.csv
│   ├── pedidos.csv
│   └── produtos.csv
├── models/
│   ├── staging/            # Camada staging: leitura dos seeds com tipagem básica
│   └── marts/              # Camada marts: modelos agregados e joins
├── macros/                 # Macros Jinja customizadas 
├── tests/                  # Testes customizados em SQL 
├── dbt_project.yml         # Configuração principal do projeto dbt
├── profiles.yml.example    # Template do profiles.yml 
├── docker-compose.yml      # Sobe o PostgreSQL local via Docker
├── requirements.txt        # Dependências Python pinadas
├── setup_windows.bat       # Script de setup para Windows (executar uma vez)
├── setup_macos.sh          # Script de setup para macOS (executar uma vez)
└── activate.bat            # Ativa o venv no Windows com encoding correto
```

### Sobre o `profiles.yml.example`

Este arquivo é um **template** e não contém credenciais reais. Ele é copiado para `~/.dbt/profiles.yml` pelo script de setup. O arquivo original nunca deve ser renomeado para `profiles.yml` no repositório — o `.gitignore` já bloqueia arquivos com esse nome para evitar commit acidental de credenciais.

---