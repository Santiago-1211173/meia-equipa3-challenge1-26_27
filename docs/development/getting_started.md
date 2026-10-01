# Guia de Primeiros Passos e Ambiente de Desenvolvimento
### *Sistema Pericial de Diagnóstico para Devoluções e Trocas no Retalho — MEIA 2026/2027*

---

## 1. Visão Geral

Este documento orienta novos programadores e investigadores no processo de configuração do ambiente de desenvolvimento local para o projeto **Retail Returns & Exchanges Diagnostic Expert System**.

O sistema pode ser executado em dois modos complementares:
1. **Modo Local Nativo:** Execução direta dos processos SWI-Prolog e FastAPI na máquina anfitriã, ideal para iteração rápida no código-fonte, desenvolvimento de regras e depuração interativa.
2. **Modo Contentorizado (Docker Compose):** Orquestração completa dos serviços em contentores isolados interligados por rede interna privada, ideal para validação integrada e reprodução exata do ambiente de produção.

Para aprofundar a orquestração contentorizada, consulte [Orquestração com Docker Compose](../deployment/docker_compose.md).

---

## 2. Pré-requisitos de Sistema

Antes de iniciar a configuração, certifique-se de que dispõe das seguintes ferramentas instaladas e operacionais no seu sistema operativo (Windows, Linux ou macOS):

| Ferramenta | Versão Mínima | Finalidade | Verificação de Instalação |
|:---|:---:|:---|:---|
| **Git** | 2.30+ | Controlo de versões e clonagem do repositório | `git --version` |
| **Python** | 3.11+ *(suporta 3.9+)* | Runtime do backend orquestrador FastAPI | `python --version` |
| **SWI-Prolog** | 9.x ou 10.x (64-bit) | Interpretador do motor de inferência dedutiva | `swipl --version` |
| **Java JDK** *(Opcional se Docker)* | 21 LTS | Runtime e compilação do motor Drools Engine | `java -version` |
| **Apache Maven** *(Opcional se Docker)* | 3.9+ | Gestor de dependências e build do motor Drools | `mvn -version` |
| **Docker Desktop** *(Opcional)* | 24.0+ | Contentorização e execução via Docker Compose | `docker --version` |
| **Docker Compose** *(Opcional)* | v2.20+ | Orquestração multi-contentor dos micro-serviços | `docker compose version` |

> [!NOTE]
> No Windows, certifique-se de que os executáveis `swipl.exe`, `java.exe` e `mvn.cmd` se encontram adicionados à variável de ambiente `PATH` do sistema durante as respetivas instalações.

---

## 3. Obtenção do Código-Fonte

Clone o repositório Git para a sua máquina local e aceda à pasta raiz do projeto:

```bash
# Clonar o repositório
git clone https://github.com/Santiago-1211173/meia-equipa3-challenge1-26_27.git

# Aceder à diretoria do projeto
cd meia-equipa3-challenge1-26_27
```

A estrutura de alto nível do repositório organiza-se da seguinte forma:

```text
meia-equipa3-challenge1-26_27/
├── backend_orchestrator/ # Serviço FastAPI (Python)
├── drools_engine/        # Motor de Inferência Drools (Java 21 / Spring Boot 3)
├── prolog_engine/        # Serviço de Inferência (SWI-Prolog)
├── docs/                 # Documentação técnica e arquitetural
├── docker-compose.yml    # Definição multi-serviço Docker Compose
├── pyrightconfig.json    # Configuração de type checking Pyright
└── README.md             # Visão geral do repositório
```

---

## 4. Configuração do Ambiente Python (Backend Orquestrador)

O backend orquestrador utiliza dependências modernas de Python, incluindo FastAPI, Uvicorn, Pydantic v2 e HTTPX. Recomenda-se vivamente o isolamento das dependências através de um ambiente virtual (`.venv`).

### 4.1 Criação e Ativação do Ambiente Virtual

A partir da raiz do repositório:

**No Windows (PowerShell):**
```powershell
# 1. Criar o ambiente virtual na pasta .venv
python -m venv .venv

# 2. Ativar o ambiente virtual
.\.venv\Scripts\Activate.ps1
```

*(Se o PowerShell bloquear a execução de scripts, execute previamente `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass`).*

**No Linux / macOS (Bash / Zsh):**
```bash
# 1. Criar o ambiente virtual na pasta .venv
python3 -m venv .venv

# 2. Ativar o ambiente virtual
source .venv/bin/activate
```

### 4.2 Instalação das Dependências

Com o ambiente virtual ativo, instale as bibliotecas necessárias para execução e testes:

```bash
pip install --upgrade pip
pip install -r backend_orchestrator/requirements.txt
```

As principais bibliotecas instaladas incluem:
- `fastapi`: Framework web assíncrono de alto desempenho.
- `uvicorn[standard]`: Servidor ASGI para produção e desenvolvimento.
- `pydantic` & `pydantic-settings`: Validação robusta de esquemas de dados e gestão de definições.
- `httpx`: Cliente HTTP assíncrono para comunicação com o motor Prolog.
- `pytest`, `pytest-asyncio`, `pytest-mock`: Ferramentas para a suíte de testes automatizados.

### 4.3 Configuração de Variáveis de Ambiente

O backend orquestrador suporta parametrização via variáveis de ambiente com carregamento automático a partir de ficheiro `.env`. Copie o modelo de exemplo fornecido:

**No Windows (PowerShell):**
```powershell
Copy-Item "backend_orchestrator\.env.example" "backend_orchestrator\.env"
```

**No Linux / macOS (Bash):**
```bash
cp backend_orchestrator/.env.example backend_orchestrator/.env
```

O ficheiro `.env` pré-configura as portas padrão para desenvolvimento local na máquina anfitriã (`http://127.0.0.1:8080` para o Prolog). Para a lista completa de variáveis suportadas, consulte [Variáveis de Ambiente](../deployment/environment_variables.md).

---

## 5. Execução Local Passo-a-Passo (Sem Docker)

Para depurar e iterar rapidamente no código, os três serviços podem ser executados lado a lado em três terminais distintos.

```mermaid
flowchart LR
    subgraph "Terminal 1 (Porta 8080)"
        PL["SWI-Prolog Engine\nswipl src/main.pl"]
    end

    subgraph "Terminal 2 (Porta 8082)"
        DR["Drools Engine\njava -jar ... --server.port=8082"]
    end

    subgraph "Terminal 3 (Porta 8000)"
        FA["FastAPI Orchestrator\nuvicorn app.main:app --reload"]
    end

    FA -->|"POST http://127.0.0.1:8080/evaluate"| PL
    FA -.->|"DROOLS_ENGINE_URL :8082"| DR
    Client["Cliente HTTP / Browser"] -->|"http://localhost:8000"| FA
    Client -->|"POST http://localhost:8082/api/v1/inference/evaluate"| DR
```

### Passo 1: Iniciar o Motor SWI-Prolog (Terminal 1)

Abra o primeiro terminal, navegue para o diretório `prolog_engine` e inicie o servidor HTTP Prolog:

```bash
cd prolog_engine
swipl src/main.pl
```

Deverá observar a seguinte confirmação nos registos do terminal:

```text
[CONFIG] Loading environment configuration...
[CONFIG] Port: 8080
[SERVER] Initializing Prolog HTTP server daemon on port 8080...
[SERVER] Prolog HTTP server daemon successfully started on port 8080
[ROUTES] Registering POST handler for /evaluate
[MAIN] System initialization complete. Ready for queries.
```

O micro-serviço Prolog permanece ativo e à escuta de pedidos HTTP na porta `8080`.

### Passo 2: Iniciar o Motor Drools Engine (Terminal 2)

Abra um segundo terminal, navegue para o diretório `drools_engine` e inicie o servidor Spring Boot na porta `8082` (evitando conflito com a porta `8080` do Prolog):

**Opção A — Compilação e execução do JAR (Recomendado):**
```bash
cd drools_engine
mvn clean package -DskipTests
java -jar target/drools-engine-0.0.1-SNAPSHOT.jar --server.port=8082
```

**Opção B — Execução direta via Spring Boot Maven Plugin:**
```bash
cd drools_engine
mvn spring-boot:run -Dspring-boot.run.arguments=--server.port=8082
```

Deverá observar a confirmação de arranque do Spring Boot nos registos do terminal:

```text
  .   ____          _            __ _ _
 /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
 \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
  '  |____| .__|_| |_|_| |_\__, | / / / /
 =========|_|==============|___/=/_/_/_/
 :: Spring Boot ::                (v3.3.4)

... [main] c.e.d.config.DroolsConfig    : Successfully built KieContainer from KieFileSystem
... [main] o.s.b.w.embedded.tomcat.TomcatWebServer  : Tomcat started on port 8082 (http) with context path '/'
... [main] c.e.d.DroolsEngineApplication: Started DroolsEngineApplication in ... seconds
```

O micro-serviço Drools permanece ativo e à escuta de pedidos HTTP na porta `8082`.

### Passo 3: Iniciar o Backend Orquestrador FastAPI (Terminal 3)

Abra um terceiro terminal, ative o ambiente virtual e execute o servidor ASGI Uvicorn em modo de recarregamento automático (`--reload`):

**Opção A — A partir da raiz do repositório:**
```powershell
# Ativar venv (se necessário)
.\.venv\Scripts\Activate.ps1

# Executar Uvicorn apontando para a diretoria da aplicação
python -m uvicorn app.main:app --app-dir backend_orchestrator --reload --host 127.0.0.1 --port 8000
```

**Opção B — A partir da pasta `backend_orchestrator`:**
```powershell
cd backend_orchestrator
uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
```

Deverá observar a confirmação de arranque do Uvicorn e o registo do ciclo de vida (*lifespan*):

```text
INFO: Will watch for changes in 'backend_orchestrator'
INFO: Uvicorn running on http://127.0.0.1:8000 (Press CTRL+C to quit)
INFO: Started reloader process
INFO: Application startup complete.
```

---

## 6. Execução Alternativa com Docker Compose

Caso prefira não instalar localmente o interpretador SWI-Prolog e o JDK Java, ou pretenda testar a integração exata dos três contentores interligados em rede privada, utilize o Docker Compose:

```bash
# Compilar e arrancar os três contentores em background
docker compose up --build -d

# Visualizar o estado dos contentores
docker compose ps

# Acompanhar os registos unificados em tempo real
docker compose logs -f
```

O Docker Compose instancia automaticamente os três contentores (`expert-prolog-engine`, `expert-orchestrator`, `expert-drools-engine`) e configura a rede interna privada `retail-network`.

Para instruções completas de operações e comandos de paragem, consulte [Orquestração com Docker Compose](../deployment/docker_compose.md).

---

## 7. Verificação e Validação do Sistema (Smoke Tests)

Com os serviços em execução, execute os testes rápidos a seguir para validar a integridade da comunicação.

### 7.1 Teste de Diagnóstico e Saúde (Health Check)

Valide que o backend orquestrador está ativo e com ligação estabelecida ao motor Prolog:

**Via PowerShell:**
```powershell
Invoke-RestMethod -Uri "http://localhost:8000/health" -Method Get | ConvertTo-Json
```

**Via cURL (Bash):**
```bash
curl -X GET http://localhost:8000/health
```

**Resposta esperada (HTTP 200 OK):**
```json
{
  "status": "healthy",
  "prolog_engine": "connected",
  "timestamp": "2026-09-27T20:55:00.123456Z"
}
```

### 7.2 Teste de Avaliação Pericial (Cenário POC Aprovado)

Submeta um cenário de teste com valor `42` para validar o fluxo ponta-a-ponta de inferência e a cadeia de explicabilidade:

**Via PowerShell:**
```powershell
$payload = @{
    scenario = "test"
    value = 42
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:8000/api/v1/evaluate" `
  -Method Post `
  -ContentType "application/json" `
  -Body $payload | ConvertTo-Json
```

**Via cURL (Bash):**
```bash
curl -X POST http://localhost:8000/api/v1/evaluate \
  -H "Content-Type: application/json" \
  -d '{"scenario": "test", "value": 42}'
```

**Resposta esperada (HTTP 200 OK):**
```json
{
  "status": "success",
  "decision": "approved",
  "justification": [
    "Value is 42",
    "Dummy rule matched"
  ],
  "engine": "prolog"
}
```

### 7.3 Acesso à Documentação Interativa OpenAPI

O FastAPI gera automaticamente interfaces gráficas interativas e esquemas OpenAPI baseados nos modelos Pydantic:

* **Swagger UI:** Aceda a [`http://localhost:8000/docs`](http://localhost:8000/docs) para explorar e disparar pedidos interativos.
* **ReDoc:** Aceda a [`http://localhost:8000/redoc`](http://localhost:8000/redoc) para leitura da documentação formal das APIs.
* **OpenAPI JSON:** Disponível em [`http://localhost:8000/openapi.json`](http://localhost:8000/openapi.json).

### 7.4 Smoke Test do Motor Drools Engine

Valide o estado do motor Drools e efetue uma avaliação clínica de teste:

**Health Check do Drools (PowerShell & cURL):**
```powershell
Invoke-RestMethod -Uri "http://localhost:8082/api/v1/inference/health" -Method Get | ConvertTo-Json
```
```bash
curl -X GET http://localhost:8082/api/v1/inference/health
```

**Resposta esperada (HTTP 200 OK):**
```json
{
  "status": "UP",
  "service": "drools-engine",
  "version": "1.0.0",
  "activeKieBase": "rulesKieBase",
  "totalRules": 13,
  "timestamp": "2026-10-01T14:00:00"
}
```

**Avaliação Clínica no Drools (PowerShell & cURL):**
```powershell
$payload = @{
    bloodEar = "yes"
    earAche = "yes"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:8082/api/v1/inference/evaluate" `
  -Method Post `
  -ContentType "application/json" `
  -Body $payload | ConvertTo-Json
```
```bash
curl -X POST http://localhost:8082/api/v1/inference/evaluate \
  -H "Content-Type: application/json" \
  -d '{"bloodEar": "yes", "earAche": "yes"}'
```

**Resposta esperada (HTTP 200 OK):**
```json
{
  "status": "COMPLETED",
  "primaryDiagnosis": "otorrhagia",
  "conclusions": [
    "otorrhagia"
  ],
  "hypothesis": "upper haemorrhage",
  "firedRules": [
    "r1_upper_type",
    "r3_otorrhagia_ear_ache"
  ],
  "timestamp": "2026-10-01T14:00:00",
  "evidencesEvaluated": 13
}
```

---

## 8. Resumo de URLs e Portas de Desenvolvimento

| Recurso | URL Local | Descrição |
|:---|:---|:---|
| **API Pública do Orquestrador** | `http://localhost:8000` | Ponto de entrada REST para o Frontend e clientes externos. |
| **Health Check Global** | `http://localhost:8000/health` | Diagnóstico de integridade e verificação de ping ao Prolog. |
| **Avaliação de Cenários** | `http://localhost:8000/api/v1/evaluate` | Endpoint principal de orquestração de inferência pericial. |
| **Swagger UI Interativo** | `http://localhost:8000/docs` | Interface gráfica OpenAPI para testes no navegador. |
| **API Interna SWI-Prolog** | `http://localhost:8080/evaluate` | Motor de inferência dedutiva (apenas comunicação interna). |
| **API Interna Drools Engine** | `http://localhost:8082/api/v1/inference/evaluate` | Motor de inferência por regras de produção (Spring Boot / Drools). |
| **Health Check Drools** | `http://localhost:8082/api/v1/inference/health` | Diagnóstico do KieContainer e total de regras ativas. |

---

## 9. Próximos Passos e Documentos Relacionados

Após confirmar a execução bem-sucedida do sistema em ambiente local:
* Consulte a [Estratégia e Execução de Testes](testing.md) para correr a suíte de testes automatizados (Pytest, PLUnit e JUnit 5).
* Consulte as [Convenções de Código e Boas Práticas](coding_conventions.md) antes de submeter alterações de código.
* Consulte a [Referência de APIs](../api/README.md), a [API do Orquestrador](../api/orchestrator_api_v1.md) e a [API do Drools Engine](../api/drools_engine_api.md) para conhecer em detalhe os contratos e modelos de dados do sistema.
* Consulte a [Arquitetura do Motor Drools](../architecture/drools_engine.md) e a [Arquitetura do Motor Prolog](../architecture/prolog_engine.md) para aprofundar os princípios de inferência.
