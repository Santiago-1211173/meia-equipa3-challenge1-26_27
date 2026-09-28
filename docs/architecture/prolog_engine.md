# Arquitetura Interna: Micro-serviço SWI-Prolog
### *Motor de Inferência Dedutiva em Clean Architecture*

---

## 1. Visão Geral e Papel no Sistema

O micro-serviço **SWI-Prolog** ([`prolog_engine/`](../../prolog_engine)) constitui o motor de inferência pericial baseado em lógica declarativa de primeira ordem.

A sua responsabilidade primordial consiste em receber representações factuais de cenários de devolução e troca, submetê-las à base de regras de negócio e deduzir deterministicamente o desfecho normativo acompanhado de uma cadeia estruturada de justificações (*Explicabilidade / Transparência*).

---

## 2. Princípios de Clean Architecture e Organização do Código

Para assegurar independência de protocolos de transporte, facilidade de manutenção e suporte a testes unitários ultrarrápidos, o micro-serviço adota os princípios de **Clean Architecture**:

```text
prolog_engine/
├── Dockerfile                  # Contentorização baseada na imagem oficial swipl:latest
├── .dockerignore               # Otimização do contexto de build da imagem Docker
├── src/
│   ├── api/                    # Camada de Transporte HTTP / Rede (I/O)
│   │   ├── server.pl           # Gestão do daemon HTTP multi-threaded (thread_httpd)
│   │   ├── routes.pl           # Endpoints REST e serialização/desserialização JSON (POC)
│   │   └── inference_routes.pl # Endpoints REST do motor de inferência pericial (/inference/*)
│   ├── core/                   # Camada de Domínio / Regras de Negócio Puras
│   │   ├── rules.pl            # Base de conhecimento declarativa e motor de inferência (POC)
│   │   └── inference/          # Motor pericial forward-chaining modular
│   │       ├── engine.pl       # Motor sp_exp2 adaptado (não-interativo, dados estruturados)
│   │       └── kb/             # Bases de conhecimento declarativas
│   │           └── vehicles.pl # Base de conhecimento de veículos com metaconhecimento
│   └── main.pl                 # Entry point, bootstrapping e leitura de ambiente
└── tests/                      # Suíte de Testes Automatizados (PLUnit)
    ├── test_rules.pl           # Testes unitários do core de regras (7 cenários)
    ├── test_api.pl             # Testes de integração HTTP e despacho (5 cenários)
    └── test_inference_engine.pl# Testes unitários do motor pericial forward-chaining (8 cenários)
```

### 2.1 Camada de Domínio / Lógica Pura (`src/core/`)
* **Isolamento Total:** A camada Core desconhece por completo a existência de sockets TCP, portas de rede, servidores HTTP ou formatos de transmissão como JSON.
* **Prolog Declarativo Puro:** Opera unicamente com termos nativos do Prolog e dicionários abstratos (*Prolog Dicts*).
* **Módulos:**
  * `rules.pl`: Regras determinísticas da POC inicial (`evaluate_scenario/3`).
  * `inference/engine.pl`: Motor de inferência pericial baseado em encadeamento para a frente (*forward-chaining*), não-interativo e desacoplado de I/O.
  * `inference/kb/vehicles.pl`: Base de conhecimento de teste contendo factos, regras e metaconhecimento de disparo.
* **Testabilidade:** Pode ser testada diretamente na consola interativa `swipl` ou através de testes unitários PLUnit sem necessidade de iniciar o servidor web.

### 2.2 Camada de Transporte e Rede (`src/api/`)
* **Isolamento de I/O:** É a única secção do serviço com conhecimento de rede, protocolos HTTP e formatação de dados.
* **Módulos:**
  * `server.pl`: Inicializa o servidor HTTP concorrente através das bibliotecas nativas `library(http/thread_httpd)` e `library(http/http_dispatch)`.
  * `routes.pl`: Mapeia o caminho `/evaluate`, lê o fluxo JSON recebido, invoca a camada de domínio e converte a dedução num payload JSON de saída.
  * `inference_routes.pl`: Mapeia a família de rotas REST `/inference/*` (`load`, `run`, `facts`, `how`, `whynot`, `reset`), gerindo a deserialização segura e resposta em JSON.
* **Regra Fundamental:** A camada de API **não** aplica nem contém regras de negócio; a sua única função é o transporte e adaptação de dados.

### 2.3 Ponto de Entrada (`src/main.pl`)
* Responsável pelo carregamento de todos os módulos (`api/server`, `api/routes`, `api/inference_routes`, `core/rules`, `core/inference/engine`).
* Lê a variável de ambiente `PORT` (por omissão `8080`).
* Inicializa o daemon na porta configurada e bloqueia a thread principal para manter o contentor Docker em execução contínua.

---

## 3. O Papel dos *Prolog Dicts* como DTOs Internos

A fronteira entre a Camada de Transporte (`src/api/routes.pl`) e a Camada de Domínio (`src/core/rules.pl`) assenta exclusivamente no uso de **Prolog Dicts** (dicionários nativos com tag, ex.: `json{scenario: "test", value: 42}`):

1. **Desserialização Segura:**  
   A camada de rotas recorre ao predicado nativo `http_read_json_dict/3` da biblioteca `library(http/http_json)`. O stream de bytes do corpo HTTP é imediatamente transformado num dicionário estruturado.
2. **Acesso Declarativo e Defensivo:**  
   Na camada de regras, a inspeção dos dados faz-se com `is_dict/1` e `get_dict/3`:
   ```prolog
   get_dict(value, ScenarioDict, Value)
   ```
   Caso uma chave obrigatória esteja ausente, o operador de unificação falha graciosamente, acionando de forma determinística os predicados de fallback sem lançar erros fatais de execução.
3. **Serialização Limpa:**  
   Após a conclusão da inferência, a camada de transporte constrói um novo dicionário de resposta e emite-o via `reply_json_dict/1` ou `reply_json_dict/2` com os cabeçalhos HTTP adequados (`application/json; charset=UTF-8`).

---

## 4. Ciclo de Vida do Pedido (Request-Response Lifecycle)

O diagrama abaixo detalha a sequência completa de execução de um pedido de inferência dentro do micro-serviço Prolog:

```mermaid
sequenceDiagram
    autonumber
    actor Orch as Orquestrador (FastAPI)
    participant Srv as Servidor HTTP (server.pl / thread_httpd)
    participant Disp as Despachador & Rotas (routes.pl)
    participant Core as Motor de Domínio (rules.pl)

    Orch->>Srv: HTTP POST /evaluate (Payload JSON)
    activate Srv
    Srv->>Disp: Aloca Worker Thread & Aciona http_dispatch
    activate Disp

    rect rgb(240, 245, 255)
        note over Disp: Desserialização e Validação do Envelope
        Disp->>Disp: http_read_json_dict(Request, ScenarioDict)
    end

    alt Payload JSON Válido
        Disp->>Core: rules:evaluate_scenario(+ScenarioDict, -Decision, -ExplanationList)
        activate Core
        rect rgb(245, 255, 245)
            note over Core: Dedução Declarativa Pura
            Core->>Core: get_dict/3, matching de cláusulas e justificações
        end
        Core-->>Disp: Decision (approved / rejected / etc.), ExplanationList
        deactivate Core

        Disp->>Disp: format_response(Decision, ExplanationList, ResponseDict)
        Disp->>Srv: reply_json_dict(ResponseDict) [HTTP 200 OK]
    else JSON Malformado / Sintaxe Inválida
        rect rgb(255, 240, 240)
            note over Disp: Interceção com catch/3
        end
        Disp->>Srv: reply_json_dict(ErrorDict, [status(400)]) [HTTP 400 Bad Request]
    end

    Srv-->>Orch: Resposta HTTP/JSON (application/json)
    deactivate Disp
    deactivate Srv
```

### Tratamento Defensivo de Erros de Sintaxe
A leitura do fluxo de entrada em `routes.pl` está protegida por um bloco `catch/3`:
```prolog
catch(
    http_read_json_dict(Request, DictIn),
    _Error,
    (
        reply_json_dict(json{
            status: "error",
            decision: "rejected",
            justification: ["Invalid JSON payload: malformed syntax or bad formatting"]
        }, [status(400)]),
        !
    )
)
```
Isto assegura que pedidos com JSON corrompido ou corpos vazios não provocam o encerramento do daemon nem lançam exceções não tratadas.

---

## 5. Especificação dos Predicados de Domínio

O ficheiro [`prolog_engine/src/core/rules.pl`](../../prolog_engine/src/core/rules.pl) exporta formalmente o predicado dedutivo:

```prolog
:- module(rules, [
    evaluate_scenario/3
]).
```

### Assinatura e Comportamento
```prolog
%!  evaluate_scenario(+ScenarioDict, -Decision, -ExplanationList) is det.
```

* **`+ScenarioDict`:** Dicionário nativo do SWI-Prolog contendo os factos do cenário a avaliar.
* **`-Decision`:** Átomo simbólico representativo da decisão deduzida (`approved`, `rejected` ou `error`).
* **`-ExplanationList`:** Lista de cadeias de caracteres contendo as justificações lógicas da dedução.

### Regras Implementadas na Prova de Conceito (POC)
1. **Regra 1 (Aprovação por valor exato):**  
   Se `value =:= 42`, deduz `approved` com justificações `["Value is 42", "Dummy rule matched"]`.
2. **Regra 2 (Rejeição por valor incorreto):**  
   Se `value` estiver presente mas for diferente de 42, deduz `rejected` com justificações `["Value is not 42", "Default fallback rule applied"]`.
3. **Regra 3 (Rejeição por ausência de atributo):**  
   Se a chave `value` estiver em falta no dicionário, deduz `rejected` com justificações `["Missing 'value' field in scenario", "Default fallback rule applied"]`.
4. **Regra 4 (Erro por tipo inválido):**  
   Se o argumento de entrada não for um dicionário Prolog (`\+ is_dict(ScenarioDict)`), deduz `error` com justificação `["Scenario payload is not a valid Prolog dictionary"]`.

*(Na evolução para o domínio de retalho, este predicado será expandido com cláusulas para avaliar itens de vestuário, recibos, prazos e higiene, conforme detalhado em [Heurísticas do Perito](../domain/expert_knowledge.md)).*

---

## 6. Diferenciação dos Motores Prolog: Exemplo dos Professores (sp_exp2) vs. Domínio do Retalho

O micro-serviço SWI-Prolog aloja dois motores distintos, com propósitos e ciclos de vida claramente segmentados:

| Dimensão | 1. Motor de Exemplo dos Professores (`sp_exp2.pl` / Moodle) | 2. Motor de Domínio de Negócio (Retalho / Dustin Hopper) |
|:---|:---|:---|
| **Origem e Providência** | Ficheiros de apoio do Moodle: `prolog_engine/Ficheiros de Apoio Sistemas Periciais_ sp_exp1.pl, sp_exp2.pl e base de conhecimento-20260928/` (`sp_exp2.pl`, `veiculos2.txt`). | Desenho de domínio do projeto MEIA (Challenges 4Teams, Equipa 3) baseado nas entrevistas com o perito Dustin Hopper. |
| **Módulos Core** | `src/core/inference/engine.pl`<br/>`src/core/inference/kb/vehicles.pl` | `src/core/rules.pl` |
| **Camada de Transporte (API)** | `src/api/inference_routes.pl` (`/inference/*`) | `src/api/routes.pl` (`/evaluate`) |
| **Exposição no Orquestrador** | `/api/v1/inference/*` (controlado por `INFERENCE_ENGINE_ENABLED`) | `/api/v1/evaluate` (endpoint principal de negócio) |
| **Mecanismo de Raciocínio** | Encadeamento para a frente (*forward-chaining*) guiado por metaconhecimento (`facto_dispara_regras/2`), operadores DSL (`regra`, `se`, `entao`, `e`, `nao`). | Avaliação determinística baseada em cláusulas e pattern matching sobre *Prolog Dicts*. |
| **Explicabilidade** | Rastreabilidade recursiva bidirecional: `como/1` (*How*) e `whynot/1` (*Why Not*). | Vetor sequencial de justificações auditáveis (`justification[]`). |
| **Bases de Conhecimento** | Modulares e dinâmicas (`vehicles.pl` adaptada de `veiculos2.txt`, expansível a novas KBs). | Regras estáticas da POC de devoluções (expansão pericial completa planeada para fases subsequentes). |
| **Estado Atual** | **Concluído e 100% Funcional** (adaptado para micro-serviço não-interativo com DTOs). | **POC Inicial Concluída** (o desenvolvimento pericial aprofundado do retalho fica para a fase seguinte). |

---

### 6.1 Arquitetura do Motor de Exemplo dos Professores (`src/core/inference/`)

Este motor corresponde à adaptação direta, limpa e modular do ficheiro `sp_exp2.pl` fornecido no Moodle, preservando a sua semântica original e tornando-o operável num contexto de micro-serviços:

#### Desacoplamento e Operação Não-Interativa
O código original dos professores foi transformado para dispensar I/O de consola:
* **Eliminação de I/O em Terminal:** Substituição de chamadas interativas (`write/1`, `read/1`, `get0/1`) por estruturas de dados puras (termos, listas e Prolog Dicts).
* **Normalização DTO:** Todos os resultados, factos inferidos e justificações são normalizados antes da transmissão, convertendo termos e condições negativas (`nao Cond`) em strings legíveis para serialização JSON via `library(http/http_json)`.

### 6.2 DSL Declarativa e Operadores Customizados
O motor define operadores que criam uma Domain-Specific Language (DSL) expressiva para regras periciais:
```prolog
:- op(220, xfx, entao).   % Conclusão de regra: LHS entao RHS
:- op(35,  xfy, se).      % Corpo de regra: regra ID se LHS entao RHS
:- op(240, fx,  regra).   % Identificador prefixo: regra N
:- op(500, fy,  nao).     % Negação por falha: nao Cond
:- op(600, xfy, e).       % Conjunção lógica: Cond1 e Cond2
```

Exemplo canónico de regra na DSL:
```prolog
regra 2 se [tipo(V, mercadorias) e classe(V, pesado)] entao [cria_facto(pesado(V, camiao))].
```

### 6.3 Ciclo de Dedução e Resolução Dinâmica
O ciclo de inferência assenta no padrão ISO de atualização lógica:
1. **Predicados Dinâmicos:** A memória de trabalho gere `facto/2`, `ultimo_facto/1` e `justifica/3`.
2. **Metaconhecimento (`facto_dispara_regras/2`):** Mapeia padrões estruturais de factos para as listas de identificadores de regras candidatas, otimizando drasticamente o espaço de procura.
3. **Ciclo Recursivo Indexado (`arranca_motor/1`):** Itera sequencialmente pelos factos $N = 1, 2, \dots$, acionando regras candidatas via `dispara_regras/3` e asserindo novos factos através de `cria_facto/3` sem loops infinitos nem duplicações.
4. **Avaliação Numérica (`avalia/2`):** Permite expressões relacionais (`lotacao(V, >, 9)`, `peso(V, =<, 3500)`).

### 6.4 Módulos e Predicados Públicos
O módulo `inference_engine` em [`prolog_engine/src/core/inference/engine.pl`](../../prolog_engine/src/core/inference/engine.pl) expõe:
* `load_knowledge_base(+KBName)`: Carrega e compila dinamicamente bases de conhecimento localizadas em `kb/` (ex.: `vehicles`).
* `run_engine(-ResultDict)`: Executa a dedução forward-chaining e devolve métricas e factos inferidos em formato dict.
* `get_all_facts(-FactsList)`: Enumera todos os factos ativos na memória de trabalho.
* `explain_how(+FactId, -ExplanationList)`: Constrói recursivamente a árvore causal de justificação para um facto derivado ou inicial.
* `explain_whynot(+FactTerm, -ExplanationList)`: Identifica as regras candidatas para um facto e discrimina as premissas em falta ou não satisfeitas.
* `reset_engine`: Repõe a memória de trabalho num estado limpo.

---

## 7. Documentos Relacionados

* [Visão Global da Arquitetura do Sistema](system_overview.md) — Posicionamento do micro-serviço no ecossistema global.
* [Arquitetura do Orquestrador FastAPI](fastapi_orchestrator.md) — Camada cliente que consome este serviço.
* [Interações entre Serviços e Fluxos de Dados](service_interactions.md) — Comunicação e contratos de transporte.
* [Referência da API do Motor Prolog](../api/prolog_engine_api.md) — Especificação técnica dos endpoints `/evaluate` e `/inference/*`.
* [Contentorização e Dockerfiles](../deployment/docker.md) — Configuração do contentor `swipl:latest`.
