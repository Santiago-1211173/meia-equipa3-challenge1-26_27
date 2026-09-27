# Resolução de Problemas (Troubleshooting)
### *Sistema Pericial de Diagnóstico para Devoluções e Trocas no Retalho*

---

## 1. Visão Geral

Este guia compila os cenários mais frequentes de erro operacional, anomalias de rede, problemas de configuração e conflitos de portas entre os micro-serviços (**FastAPI Orchestrator** e **SWI-Prolog Engine**), fornecendo procedimentos de diagnóstico e soluções passo-a-passo.

---

## 2. Diagnóstico Rápido: Comandos Essenciais

Antes de investigar causas específicas, utilize estes comandos para obter visibilidade imediata sobre o estado do sistema:

```bash
# 1. Verificar o estado de todos os contentores
docker compose ps -a

# 2. Consultar os últimos 100 registos de logs com timestamp
docker compose logs --tail=100 -t

# 3. Testar a ligação ao healthcheck do Orquestrador
curl -X GET http://localhost:8000/health

# 4. Inspecionar a rede bridge privada
docker network inspect retail-network
```

---

## 3. Problemas Comuns e Resoluções

### 3.1 Conflito de Portas no Host (`Port 8000/8080 already in use`)

#### Sintoma:
O comando `docker compose up` falha com mensagem semelhante a:
```text
Error response from daemon: driver failed programming external connectivity on endpoint retail-backend-orchestrator: Bind for 0.0.0.0:8000 failed: port is already allocated
```

#### Causa:
Outro processo na máquina anfitriã (ex.: outro servidor Web, Uvicorn local, Tomcat, Jenkins) está a ocupar a porta `8000` ou `8080`.

#### Resolução:

1. **Identificar o Processo em Conflito:**
   * **No Windows (PowerShell):**
     ```powershell
     Get-NetTCPConnection -LocalPort 8000 -ErrorAction SilentlyContinue | Select-Object LocalAddress, LocalPort, OwningProcess
     ```
   * **No Linux / macOS:**
     ```bash
     lsof -i :8000
     # ou
     ss -lptn 'sport = :8000'
     ```

2. **Terminar o Processo ou Reconfigurar:**
   * Termine o processo identificado pelo seu PID:
     ```powershell
     Stop-Process -Id <PID> -Force
     ```
   * *Em alternativa,* altere a porta do host no `docker-compose.yml`:
     ```yaml
     ports:
       - "8005:8000"  # O host usará a 8005, o contentor mantém a 8000
     ```

---

### 3.2 O Orquestrador Retorna `HTTP 503` ao Avaliar Cenários

#### Sintoma:
Ao chamar `POST /api/v1/evaluate` ou verificar `GET /health`, o sistema responde com:
```json
{
  "status": "healthy",
  "prolog_engine": "disconnected"
}
```
E na avaliação de regras:
```json
{
  "detail": "Failed to connect to Prolog engine at http://prolog-engine:8080: [Errno 111] Connection refused"
}
```

#### Causa:
O micro-serviço Prolog não está em execução, ainda não terminou o arranque, ou o orquestrador não consegue resolver o nome DNS `prolog-engine`.

#### Resolução:

1. **Verificar os logs do contentor Prolog:**
   ```bash
   docker compose logs prolog-engine
   ```
   Certifique-se de que a última linha indica que o servidor HTTP está ativo:
   ```text
   % Started server at http://localhost:8080/
   ```

2. **Verificar a conectividade de rede interna:**
   Entre no contentor do orquestrador e tente contactar o Prolog diretamente:
   ```bash
   docker compose exec orchestrator python -c "import httpx, asyncio; asyncio.run(httpx.AsyncClient().get('http://prolog-engine:8080/'))"
   ```

3. **Verificar a variável `PROLOG_ENGINE_URL`:**
   No `docker-compose.yml`, confirme que o valor é `http://prolog-engine:8080` (e **não** `http://localhost:8080`, que apontaria para o próprio contentor do orquestrador).

---

### 3.3 Alterações no Código não Têm Efeito no Contentor

#### Sintoma:
Fez alterações a regras Prolog ou endpoints FastAPI, executou `docker compose up -d`, mas o comportamento mantém-se antigo.

#### Causa:
O Docker reutilizou a imagem anterior a partir da cache local sem a recompilar com os novos ficheiros.

#### Resolução:
Forçar a reconstrução das imagens com a flag `--build`:
```bash
docker compose up --build -d
```

Se persistir, limpe a imagem antiga e reconstrua do zero:
```bash
docker compose down --rmi local
docker compose up --build -d
```

---

### 3.4 Contentor a Reiniciar em Ciclo Contínuo (*CrashLoop*)

#### Sintoma:
O comando `docker compose ps` mostra o estado `Restarting (1) x seconds ago`.

#### Causa:
O processo principal no contentor terminou com erro fatal imediatamente após o arranque (ex.: erro sintático no ficheiro de regras Prolog ou dependência Python em falta).

#### Resolução:

1. **Inspecionar os logs de terminação do contentor:**
   ```bash
   docker compose logs --tail=50 prolog-engine
   # ou
   docker compose logs --tail=50 orchestrator
   ```

2. **Causa típica em Prolog:**
   Erro sintático em `src/core/rules.pl` (ex.: ponto final `.` esquecido ou parêntesis não balanceado). O interpretador SWI-Prolog aborta o arranque com erro de compilação.
   * *Correção:* Execute os testes unitários locais com `swipl -s prolog_engine/tests/test_rules.pl` para detetar o erro antes de construir o contentor.

3. **Causa típica em FastAPI:**
   Falta de variável de ambiente ou erro de validação do Pydantic no carregamento de `Settings`.
   * *Correção:* Verifique se as variáveis no `docker-compose.yml` respeitam os tipos exigidos.

---

### 3.5 Bloqueio por CORS (*Cross-Origin Resource Sharing*) no Frontend

#### Sintoma:
No browser, a consola exibe:
```text
Access to fetch at 'http://localhost:8000/api/v1/evaluate' from origin 'http://localhost:5173' has been blocked by CORS policy: No 'Access-Control-Allow-Origin' header is present on the requested resource.
```

#### Causa:
A origem do Frontend (ex.: Vite na porta `5173` ou Next.js na `3000`) não consta da lista `CORS_ORIGINS`.

#### Resolução:

1. Verifique a configuração de `CORS_ORIGINS` no `docker-compose.yml`:
   ```yaml
   environment:
     - CORS_ORIGINS=["http://localhost:3000","http://localhost:5173","http://localhost:8000"]
   ```
2. Adicione a porta/domínio da sua aplicação web à lista.
3. Reinicie o orquestrador para aplicar a nova configuração:
   ```bash
   docker compose restart orchestrator
   ```

---

## 4. Matriz Rápida de Resolução de Falhas

| Erro / Mensagem | Componente | Causa Provável | Ação de Correção |
|:---|:---|:---|:---|
| `port is already allocated` | Docker Daemon | Porta 8000 ou 8080 em uso no anfitrião. | Fechar processo que ocupa a porta ou alterar o mapeamento no Compose. |
| `[Errno 111] Connection refused` | FastAPI Client | Prolog fora de serviço ou URL de rede incorreto. | Verificar `docker compose ps` e confirmar que `PROLOG_ENGINE_URL=http://prolog-engine:8080`. |
| `ReadTimeout / ConnectTimeout` | FastAPI Client | Inferência demorou mais de 5s ou Prolog congelado. | Aumentar `PROLOG_TIMEOUT_SECONDS` ou verificar predicados com ciclo infinito no Prolog. |
| `HTTP 422 Unprocessable Entity` | FastAPI / Pydantic | Payload JSON não cumpre o modelo `ScenarioInput`. | Verificar estrutura do JSON: garantir que `scenario` é string e `value` é numérico. |
| `HTTP 400 Bad Request` | Prolog Routes | JSON malformado ou parâmetros obrigatórios ausentes. | Verificar cabeçalho `Content-Type: application/json` e campos da mensagem. |

---

## 5. Documentos Relacionados

* [Orquestração com Docker Compose](docker_compose.md) — Comandos e ciclo de vida dos contentores.
* [Variáveis de Ambiente](environment_variables.md) — Mapeamento e valores suportados.
* [API Pública v1 do Orquestrador](../api/orchestrator_api_v1.md) — Códigos de resposta e contratos de teste.
* [Guia de Testes Automatizados](../development/testing.md) — Execução preventiva de testes para evitar falhas em contentor.
