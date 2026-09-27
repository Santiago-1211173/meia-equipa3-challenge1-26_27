# Orquestração com Docker Compose
### *Sistema Pericial de Diagnóstico para Devoluções e Trocas no Retalho*

---

## 1. Visão Geral

A orquestração do ecossistema de micro-serviços é gerida declarativamente pelo ficheiro [`docker-compose.yml`](../../docker-compose.yml) localizado na raiz do projeto. O Docker Compose permite:
1. **Compilar e levantar todo o sistema com um único comando.**
2. **Criar uma rede bridge privada (`retail-network`)** onde os contentores comunicam por DNS interno sem depender de endereços IP estáticos.
3. **Controlar a ordem de inicialização** através da diretiva `depends_on`.
4. **Garantir alta disponibilidade local** com políticas automáticas de reinício (`unless-stopped`).

```mermaid
flowchart TD
    subgraph Host["Máquina Anfitriã (Host)"]
        Browser["Cliente / Frontend / cURL"]
    end

    subgraph DockerNetwork["Rede Privada Docker: retail-network (driver: bridge)"]
        subgraph OrchContainer["Contentor: retail-backend-orchestrator"]
            FastAPI["FastAPI Orchestrator\nEscuta em 0.0.0.0:8000"]
        end

        subgraph PrologContainer["Contentor: retail-prolog-engine"]
            Prolog["SWI-Prolog Engine\nEscuta em 0.0.0.0:8080"]
        end
    end

    Browser -->|"http://localhost:8000\n(Porta 8000:8000)"| FastAPI
    Browser -.->|"http://localhost:8080 (Opcional)\n(Porta 8080:8080)"| Prolog
    FastAPI -->|"DNS: http://prolog-engine:8080\n(Comunicação Interna)"| Prolog
```

---

## 2. Anatomia do `docker-compose.yml`

Ficheiro de referência: [`docker-compose.yml`](../../docker-compose.yml)

```yaml
services:
  prolog-engine:
    build:
      context: ./prolog_engine
      dockerfile: Dockerfile
    container_name: retail-prolog-engine
    ports:
      - "8080:8080"
    environment:
      - PORT=8080
    restart: unless-stopped
    networks:
      - retail-network

  orchestrator:
    build:
      context: ./backend_orchestrator
      dockerfile: Dockerfile
    container_name: retail-backend-orchestrator
    ports:
      - "8000:8000"
    environment:
      - PORT=8000
      - PROLOG_ENGINE_URL=http://prolog-engine:8080
      - PROLOG_TIMEOUT_SECONDS=5.0
      - DEBUG=true
      - CORS_ORIGINS=["http://localhost:3000","http://localhost:5173","http://localhost:8000"]
    depends_on:
      - prolog-engine
    restart: unless-stopped
    networks:
      - retail-network

networks:
  retail-network:
    driver: bridge
```

### 2.1 Análise dos Serviços

#### 1. Serviço `prolog-engine`
* **Nome do contentor:** `retail-prolog-engine`.
* **Contexto de build:** `./prolog_engine` utilizando o `Dockerfile` correspondente.
* **Mapeamento de portas:** `"8080:8080"` expõe o serviço para permitir testes individuais diretos no host, embora em produção apenas o orquestrador necessite de comunicar com ele.
* **Rede:** Associado à rede bridge `retail-network`. O nome do serviço (`prolog-engine`) serve de hostname DNS automático para outros contentores da mesma rede.

#### 2. Serviço `orchestrator`
* **Nome do contentor:** `retail-backend-orchestrator`.
* **Contexto de build:** `./backend_orchestrator`.
* **Mapeamento de portas:** `"8000:8000"` (porta de entrada para a API pública).
* **Dependência (`depends_on`):** Declara explicitamente que o contentor `prolog-engine` deve ser iniciado antes do `orchestrator`.
* **Injeção de Ambiente:** Sobrescreve a variável `PROLOG_ENGINE_URL` para o endereço de rede interno: `http://prolog-engine:8080`.

### 2.2 Rede e Resolução DNS (`retail-network`)
A rede `retail-network` utiliza o driver `bridge`. O Docker configura um servidor DNS interno (no IP `127.0.0.11`) que resolve os nomes dos serviços do compose diretamente para o IP interno do contentor correspondente. Isto assegura que mesmo que os contentores reiniciem e mudem de IP, a comunicação mantém-se inalterada.

---

## 3. Guia Operacional Passo-a-Passo

Todos os comandos devem ser executados a partir da **raiz do repositório**.

### Passo 1: Construir e Iniciar os Serviços

Para compilar as imagens a partir do código atualizado e iniciar os contentores em segundo plano (*detached mode*):

```bash
docker compose up --build -d
```

> [!TIP]
> A flag `--build` garante que quaisquer alterações recentes no código Python ou Prolog são incorporadas nas imagens recém-construídas.

---

### Passo 2: Verificar o Estado dos Contentores

Para validar se os dois contentores estão em estado operacional (`Up` / `healthy`):

```bash
docker compose ps
```

**Resultado esperado:**
```text
NAME                           IMAGE                               COMMAND                  SERVICE         STATUS         PORTS
retail-backend-orchestrator    meia-equipa3-...-orchestrator       "uvicorn app.main:ap…"   orchestrator    Up 2 minutes   0.0.0.0:8000->8000/tcp
retail-prolog-engine           meia-equipa3-...-prolog-engine      "swipl -s src/main.p…"   prolog-engine   Up 2 minutes   0.0.0.0:8080->8080/tcp
```

---

### Passo 3: Acompanhar os Registos de Execução (Logs)

Para seguir em tempo real a emissão de logs de ambos os serviços:

```bash
docker compose logs -f
```

Para filtrar apenas os logs de um serviço específico:
```bash
# Registos do FastAPI Orchestrator
docker compose logs -f orchestrator

# Registos do micro-serviço Prolog
docker compose logs -f prolog-engine
```

---

### Passo 4: Verificar a Saúde do Sistema (Healthcheck)

Com os contentores ativos, execute o healthcheck via terminal para verificar se o orquestrador consegue alcançar o Prolog:

**Em Bash / cURL:**
```bash
curl -X GET http://localhost:8000/health
```

**Em PowerShell (Windows):**
```powershell
curl.exe -X GET http://localhost:8000/health
```
*Ou via `Invoke-RestMethod`:*
```powershell
(Invoke-RestMethod -Uri http://localhost:8000/health) | ConvertTo-Json
```

**Resposta esperada (`HTTP 200 OK`):**
```json
{
  "status": "healthy",
  "prolog_engine": "connected",
  "timestamp": "2026-09-27T20:00:00.123456Z"
}
```

---

### Passo 5: Testar Avaliação de Cenários via cURL

Submeta um teste de aprovação de inferência lógica:

**Bash / Linux / macOS:**
```bash
curl -X POST http://localhost:8000/api/v1/evaluate \
  -H "Content-Type: application/json" \
  -d '{"scenario": "test", "value": 42}'
```

**PowerShell (Windows):**
```powershell
curl.exe -X POST http://localhost:8000/api/v1/evaluate `
  -H "Content-Type: application/json" `
  -d '{\"scenario\": \"test\", \"value\": 42}'
```

**Resposta esperada (`HTTP 200 OK`):**
```json
{
  "status": "success",
  "decision": "approved",
  "justification": [
    "Value is 42",
    "Dummy rule matched"
  ],
  "engine": "prolog",
  "timestamp": "2026-09-27T19:35:00.000000Z",
  "message": null
}
```

---

### Passo 6: Parar e Destruir os Serviços

Para parar a execução de forma graciosa e libertar os recursos de rede e portas 8000 e 8080:

```bash
docker compose down
```

Para parar os serviços e **eliminar também as imagens compiladas localmente** (útil para limpeza completa de espaço em disco ou rebuild limpo):

```bash
docker compose down --rmi local
```

---

## 4. Tabela Rápida de Comandos Operacionais

| Operação | Comando | Descrição |
|:---|:---|:---|
| **Subida Completa** | `docker compose up --build -d` | Compila e arranca todos os serviços em background. |
| **Listar Serviços** | `docker compose ps` | Exibe o estado e mapeamento de portas dos contentores. |
| **Logs Contínuos** | `docker compose logs -f` | Transmite logs unificados de todos os serviços. |
| **Reiniciar Serviço** | `docker compose restart orchestrator` | Reinicia apenas o contentor do orquestrador. |
| **Parar Serviços** | `docker compose stop` | Interrompe a execução preservando os contentores. |
| **Destruir Serviços** | `docker compose down` | Para e remove contentores e rede bridge criada. |
| **Limpeza Completa** | `docker compose down --rmi local -v` | Remove contentores, redes, volumes e imagens locais. |

---

## 5. Documentos Relacionados

* [Contentorização e Imagens Docker](docker.md) — Especificação individual de cada Dockerfile.
* [Variáveis de Ambiente](environment_variables.md) — Configurações suportadas por cada serviço.
* [Resolução de Problemas (Troubleshooting)](troubleshooting.md) — Diagnóstico de falhas de portas ou DNS.
* [API Pública v1](../api/orchestrator_api_v1.md) — Especificação de todos os endpoints expostos pelo Compose.
