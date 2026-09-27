# Deploy, Contentorização e Operações
### *Sistema Pericial de Diagnóstico para Devoluções e Trocas no Retalho*

---

## 1. Visão Geral

Esta secção contém toda a documentação operacional e de infraestrutura necessária para compilar, configurar, orquestrar e manter os serviços do sistema, tanto em ambientes de desenvolvimento local como em preparação para cenários de integração contínua (CI/CD) e produção.

O sistema baseia-se numa arquitetura de micro-serviços contentorizados em **Docker**, garantindo consistência estrita de runtime entre o interpretador **SWI-Prolog** e o ecossistema assíncrono **Python / FastAPI**.

```mermaid
flowchart LR
    subgraph "Ambiente Docker Compose"
        direction TB
        DC["docker-compose.yml\n(Orquestração Global)"]
        Net["retail-network\n(Bridge Network)"]
        
        Prolog["retail-prolog-engine\n(swipl:latest :8080)"]
        FastAPI["retail-backend-orchestrator\n(python:3.11-slim :8000)"]
        
        DC --> Net
        Net --- Prolog
        Net --- FastAPI
        FastAPI -->|"http://prolog-engine:8080"| Prolog
    end

    Host["Anfitrião / Cliente"] -->|":8000 (API v1 / Swagger)"| FastAPI
    Host -.->|":8080 (Prolog isolado)"| Prolog
```

---

## 2. Índice de Documentos da Secção

| Documento | Ficheiro | Descrição e Propósito |
|:---|:---|:---|
| **Contentorização e Dockerfiles** | [`docker.md`](docker.md) | Especificação detalhada dos Dockerfiles de cada serviço (`prolog_engine` e `backend_orchestrator`), imagens base, otimizações de cache de camadas, regras de `.dockerignore` e instruções de build individual. |
| **Orquestração com Docker Compose** | [`docker_compose.md`](docker_compose.md) | Guia operacional completo do `docker-compose.yml`: resolução de rede bridge (`retail-network`), ordem de arranque (`depends_on`), ciclo de vida e comandos práticos (`up`, `logs`, `ps`, `down`). |
| **Variáveis de Ambiente e Configuração** | [`environment_variables.md`](environment_variables.md) | Mapeamento exaustivo de todas as variáveis suportadas (`PORT`, `PROLOG_ENGINE_URL`, `PROLOG_TIMEOUT_SECONDS`, `CORS_ORIGINS`, etc.), ordem de precedência e tratamento de origens CORS. |
| **Resolução de Problemas (Troubleshooting)** | [`troubleshooting.md`](troubleshooting.md) | Catálogo de erros comuns (portas ocupadas, falhas de conectividade DNS, timeouts, bloqueios de CORS, loops de reinício) e procedimentos de diagnóstico e mitigação. |

---

## 3. Guia de Início Rápido (Quick Start em 3 Comandos)

A partir da raiz do repositório:

```bash
# 1. Compilar as imagens e iniciar todo o ecossistema em segundo plano
docker compose up --build -d

# 2. Validar a saúde dos serviços e conectividade entre contentores
curl -X GET http://localhost:8000/health

# 3. Testar a avaliação de regras com explicabilidade (POC)
curl -X POST http://localhost:8000/api/v1/evaluate \
  -H "Content-Type: application/json" \
  -d '{"scenario": "test", "value": 42}'
```

---

## 4. Portas e Resoluções de Rede

| Serviço | Porta Host | Porta Contentor | Hostname Interno Docker | Finalidade |
|:---|:---:|:---:|:---|:---|
| **FastAPI Orchestrator** | `8000` | `8000` | `orchestrator` | Ponto de entrada da API REST pública e Swagger UI (`/docs`). |
| **SWI-Prolog Engine** | `8080` | `8080` | `prolog-engine` | Motor de inferência dedutiva (comunicação interna). |

---

## 5. Referências Cruzadas

* [Visão Geral da Arquitetura](../architecture/system_overview.md) — Diagrama e princípios estruturais do sistema.
* [Referência de APIs](../api/README.md) — Documentação dos endpoints expostos pelos contentores.
* [Guia de Primeiros Passos (Local)](../development/getting_started.md) — Execução em ambiente de desenvolvimento sem Docker.
* [Estratégia de Testes](../development/testing.md) — Validação automatizada antes de construir as imagens.
