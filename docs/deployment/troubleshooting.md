# Resolução de Problemas (Troubleshooting)
### *Sistema Pericial de Diagnóstico para Devoluções e Trocas no Retalho*

---

## 1. Visão Geral

A arquitetura distribuída do sistema é composta por três micro-serviços interdependentes: **FastAPI Orchestrator**, **SWI-Prolog Engine** e **Drools Engine**. Este guia compila os cenários mais frequentes de erro operacional, anomalias de rede, problemas de inicialização da JVM, falhas de compilação de regras e conflitos de portas, fornecendo procedimentos de diagnóstico e soluções passo-a-passo.

---

## 2. Diagnóstico Rápido: Comandos Essenciais

Antes de investigar causas específicas, utilize estes comandos para obter visibilidade imediata sobre o estado do sistema:

```bash
# 1. Verificar o estado de todos os contentores
docker compose ps -a

# 2. Consultar os últimos 100 registos de logs unificados com timestamp
docker compose logs --tail=100 -t

# 3. Testar a ligação ao healthcheck do Orquestrador
curl -X GET http://localhost:8000/health

# 4. Testar o healthcheck direto do Motor Drools (porta 8082 no host)
curl -X GET http://localhost:8082/api/v1/inference/health

# 5. Inspecionar a rede bridge privada
docker network inspect retail-network
```

---

## 3. Problemas Comuns e Resoluções

### 3.1 Conflito de Portas no Host (`Port 8000/8080/8082 already in use`)

#### Sintoma:
O comando `docker compose up` falha com mensagem semelhante a:
```text
Error response from daemon: driver failed programming external connectivity on endpoint retail-backend-orchestrator: Bind for 0.0.0.0:8000 failed: port is already allocated
```
Ou para a porta do Drools:
```text
Bind for 0.0.0.0:8082 failed: port is already allocated
```

#### Causa:
Outro processo na máquina anfitriã (ex.: outro servidor Web, Uvicorn local, Tomcat, Jenkins, base de dados ou outra instância Java) está a ocupar a porta `8000`, `8080` ou `8082`.

#### Resolução:

1. **Identificar o Processo em Conflito:**
   * **No Windows (PowerShell):**
     ```powershell
     # Substituir a porta conforme o conflito (8000, 8080 ou 8082)
     Get-NetTCPConnection -LocalPort 8082 -ErrorAction SilentlyContinue | Select-Object LocalAddress, LocalPort, OwningProcess
     ```
   * **No Linux / macOS:**
     ```bash
     lsof -i :8082
     # ou
     ss -lptn 'sport = :8082'
     ```

2. **Terminar o Processo ou Reconfigurar:**
   * Termine o processo identificado pelo seu PID:
     ```powershell
     Stop-Process -Id <PID> -Force
     ```
   * *Em alternativa,* altere o mapeamento da porta no `docker-compose.yml`:
     ```yaml
     # Exemplo para o Drools Engine:
     ports:
       - "8085:8080"  # O host usará a 8085, o contentor mantém a 8080 interna
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
   Entre no contentor do orquestrador e tente contactar os motores diretamente:
   ```bash
   # Teste ao Prolog:
   docker compose exec orchestrator python -c "import httpx, asyncio; asyncio.run(httpx.AsyncClient().get('http://prolog-engine:8080/'))"

   # Teste ao Drools Engine:
   docker compose exec orchestrator python -c "import httpx, asyncio; asyncio.run(httpx.AsyncClient().get('http://drools-engine:8080/api/v1/inference/health'))"
   ```

3. **Verificar as variáveis de ambiente de rede:**
   No `docker-compose.yml`, confirme que os URLs apontam para os hostnames internos:
   * `PROLOG_ENGINE_URL=http://prolog-engine:8080` (e **não** `http://localhost:8080`).
   * `DROOLS_ENGINE_URL=http://drools-engine:8080` (e **não** `http://localhost:8082`).

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

### 3.6 Erro de Compilação de Regras DRL (`KieBuilder` / `Results.hasMessages(ERROR)`)

#### Sintoma:
O micro-serviço Drools falha no arranque ou os logs exibem uma exceção no momento do bootstrap:
```text
java.lang.IllegalStateException: Error compiling Drools rules: [Message [id=1, level=ERROR, path=rules/haemorrhage_rules.drl, line=42, column=12, text=Unknown variable or field 'unknownField'...]]
```

#### Causa:
Existe um erro sintático ou semântico no ficheiro de regras [`drools_engine/src/main/resources/rules/haemorrhage_rules.drl`](../../drools_engine/src/main/resources/rules/haemorrhage_rules.drl), tal como:
* Palavra-chave `end` em falta no fecho de uma regra.
* Acesso a um campo que não existe na classe de facto correspondente (`Evidences`, `Hypothesis` ou `Conclusion`).
* Import em falta no cabeçalho DRL.
* Condição RHS com sintaxe Java inválida.

#### Resolução:
1. Inspecione a linha e o erro exato através dos logs do contentor:
   ```bash
   docker compose logs drools-engine | grep -A 10 "Error compiling Drools rules"
   ```
2. Abra [`haemorrhage_rules.drl`](../../drools_engine/src/main/resources/rules/haemorrhage_rules.drl) na linha indicada e corrija a regra.
3. Valide a sintaxe executando a suite de testes unitários localmente antes de reconstruir a imagem Docker:
   ```bash
   cd drools_engine && mvn test -Dtest=InferenceServiceTest
   ```

---

### 3.7 Falha de Inicialização do `KieContainer` (Classpath vs Filesystem Fallback)

#### Sintoma:
Os logs apresentam o aviso:
```text
WARN ... DroolsConfig : Failed to create KieClasspathContainer, falling back to KieFileSystem: ...
```
Ou no pior cenário:
```text
java.lang.RuntimeException: Cannot find a default KieBase or KieSession
```

#### Causa:
O Apache KIE Drools não encontrou o ficheiro de metadados [`META-INF/kmodule.xml`](../../drools_engine/src/main/resources/META-INF/kmodule.xml) no classpath de execução da aplicação ou os ficheiros `.drl` não foram empacotados dentro do diretório `rules/`.

#### Resolução:
1. Confirme que o ficheiro `kmodule.xml` existe exatamente em `drools_engine/src/main/resources/META-INF/kmodule.xml` e define a base `haemorrhageKBase`:
   ```xml
   <kmodule xmlns="http://www.drools.org/xsd/kmodule">
       <kbase name="haemorrhageKBase" packages="rules" default="true">
           <ksession name="haemorrhageKSession" type="stateful" default="true"/>
       </kbase>
   </kmodule>
   ```
2. A classe [`DroolsConfig.java`](../../drools_engine/src/main/java/com/expert/drools/config/DroolsConfig.java) inclui uma estratégia dual resiliente: se o `KieClasspathContainer` falhar, o sistema ativa automaticamente o fallback para `KieFileSystem` recorrendo ao `ResourcePatternResolver` do Spring para ler `classpath*:rules/**/*.drl`.
3. Verifique se o artefacto empacotado contém as regras executando:
   ```bash
   jar tf drools_engine/target/*.jar | grep haemorrhage_rules.drl
   ```

---

### 3.8 Tempo de Inicialização da JVM (*Cold Start*) vs `depends_on`

#### Sintoma:
Imediatamente após `docker compose up -d`, chamadas ao Orquestrador que invoquem o Drools retornam `HTTP 503` ou `Connection refused` durante os primeiros 5 a 15 segundos.

#### Causa:
A diretiva `depends_on` do Docker Compose padrão apenas assegura que o contentor `expert-drools-engine` foi iniciado, mas não aguarda até que a Máquina Virtual Java (JVM) termine o bootstrap do Spring Boot, inicialize o Tomcat e compile a base de regras Drools na memória de trabalho.

#### Resolução:
1. Aguarde alguns segundos após a inicialização antes de submeter os primeiros pedidos de produção.
2. Monitorize a conclusão do arranque do Drools Engine:
   ```bash
   docker compose logs -f drools-engine
   ```
   Aguarde pela mensagem do log:
   ```text
   Started DroolsEngineApplication in X.XXX seconds
   ```
3. Valide a disponibilidade consultando o healthcheck:
   ```bash
   curl -X GET http://localhost:8082/api/v1/inference/health
   ```

---

### 3.9 Esgotamento de Memória na JVM (`java.lang.OutOfMemoryError`)

#### Sintoma:
O contentor `expert-drools-engine` encerra inesperadamente com exit code `137` (SIGKILL / OOMKilled do Linux) ou o log exibe:
```text
java.lang.OutOfMemoryError: Java heap space
# ou
java.lang.OutOfMemoryError: Metaspace
```

#### Causa:
A quota de memória RAM atribuída ao contentor ou ao Docker Desktop é insuficiente para comportar a JVM 21, as classes do Spring Boot e a rede Rete-OO compilada pelo Drools.

#### Resolução:
1. O `Dockerfile` já inclui a configuração defensiva:
   ```dockerfile
   ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0"
   ```
2. Caso o anfitrião tenha recursos limitados, defina um limite estrito de heap via `JAVA_OPTS` no `docker-compose.yml`:
   ```yaml
   drools-engine:
     environment:
       - PORT=8080
       - JAVA_OPTS=-XX:+UseContainerSupport -Xms256m -Xmx512m
   ```
3. Se estiver a utilizar Docker Desktop no Windows/macOS, aumente a memória RAM alocada ao WSL2/máquina virtual nas definições do Docker (mínimo recomendado: 4 GB para o ecossistema completo).

---

### 3.10 Falha no Passo `mvn dependency:go-offline` Durante o Build Docker

#### Sintoma:
A construção da imagem Docker falha durante o Stage 1 de compilação com erros como:
```text
[ERROR] Plugin org.apache.maven.plugins:... or one of its dependencies could not be resolved
# ou
Could not transfer artifact ... from/to central: Connection timed out
```

#### Causa:
Instabilidade temporária de rede, firewall/proxy corporativo bloqueando o acesso ao Maven Central (`repo.maven.apache.org`), ou cache de DNS corrompida no daemon Docker.

#### Resolução:
1. O `Dockerfile` inclui tolerância defensiva `RUN mvn dependency:go-offline -B || true`, garantindo que eventuais falhas parciais no download antecipado não abortam o processo, permitindo ao `mvn clean package` tentar descarregar as dependências necessárias diretamente.
2. Teste a conectividade externa a partir do Docker:
   ```bash
   docker run --rm alpine ping -c 3 repo.maven.apache.org
   ```
3. Limpe a cache do Docker BuildKit para forçar uma nova tentativa de rede limpa:
   ```bash
   docker builder prune -f
   docker compose build --no-cache drools-engine
   ```

---

## 4. Matriz Rápida de Resolução de Falhas

| Erro / Mensagem | Componente | Causa Provável | Ação de Correção |
|:---|:---|:---|:---|
| `port is already allocated (8000/8080/8082)` | Docker Daemon | Porta 8000, 8080 ou 8082 em uso no anfitrião. | Fechar processo que ocupa a porta ou alterar o mapeamento no `docker-compose.yml`. |
| `[Errno 111] Connection refused (Prolog)` | FastAPI Client | Prolog fora de serviço ou URL de rede incorreto. | Verificar `docker compose ps` e confirmar `PROLOG_ENGINE_URL=http://prolog-engine:8080`. |
| `[Errno 111] Connection refused (Drools)` | FastAPI Client | Drools ainda em inicialização da JVM ou parado. | Verificar logs com `docker compose logs drools-engine` e confirmar `DROOLS_ENGINE_URL=http://drools-engine:8080`. |
| `Error compiling Drools rules` | Drools Engine | Erro de sintaxe DRL ou tipos em falta em `haemorrhage_rules.drl`. | Inspecionar linha indicada no log; validar regras localmente com `cd drools_engine && mvn test`. |
| `Cannot find a default KieBase` | Drools Engine | `kmodule.xml` ausente ou regras fora de `rules/`. | Confirmar localização de `META-INF/kmodule.xml` e ficheiros `.drl` nos resources. |
| `Exit Code 137 / OutOfMemoryError` | JVM / Kernel | Contentor excedeu o limite de memória RAM alocada. | Ajustar `JAVA_OPTS` (`-Xmx512m`) ou aumentar memória atribuída ao Docker Desktop / WSL2. |
| `Could not transfer artifact (Maven build)` | Docker Build | Falha de rede ao descarregar dependências do Maven Central. | Verificar ligação à Internet / proxy; executar `docker builder prune -f` e reconstruir. |
| `ReadTimeout / ConnectTimeout` | FastAPI Client | Inferência demorou mais de 5s ou motor congelado. | Aumentar `PROLOG_TIMEOUT_SECONDS` / `DROOLS_TIMEOUT_SECONDS` ou verificar ciclo infinito. |
| `HTTP 422 Unprocessable Entity` | FastAPI / Pydantic | Payload JSON não cumpre o modelo `ScenarioInput`. | Verificar estrutura do JSON: garantir que `scenario` é string e `value` é numérico. |
| `HTTP 400 Bad Request (Validation)` | Drools Controller | Campo clínico não cumpre `@Pattern(regexp = "yes\|no")`. | Enviar apenas valores `"yes"` ou `"no"` para os campos de evidências clínicas. |
| `HTTP 400 Bad Request` | Prolog Routes | JSON malformado ou parâmetros obrigatórios ausentes. | Verificar cabeçalho `Content-Type: application/json` e sintaxe do JSON. |

---

## 5. Documentos Relacionados

* [Orquestração com Docker Compose](docker_compose.md) — Comandos e ciclo de vida dos contentores.
* [Variáveis de Ambiente](environment_variables.md) — Mapeamento e valores suportados por cada serviço.
* [Contentorização e Imagens Docker](docker.md) — Especificação dos Dockerfiles e permissões não-root.
* [Arquitetura do Motor Drools](../architecture/drools_engine.md) — Estrutura interna e compilação do KieContainer.
* [API Interna do Motor Drools](../api/drools_engine_api.md) — Códigos de resposta e contratos de teste do Drools.
* [API Pública v1 do Orquestrador](../api/orchestrator_api_v1.md) — Códigos de resposta e contratos de teste.
* [Guia de Testes Automatizados](../development/testing.md) — Execução preventiva de testes para evitar falhas em contentor.
