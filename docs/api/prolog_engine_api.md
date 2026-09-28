# API Interna do Motor de Inferência (SWI-Prolog)
### *Sistema Pericial de Diagnóstico para Devoluções e Trocas no Retalho*

---

## 1. Visão Geral e Natureza da API

O micro-serviço **Prolog Engine** disponibiliza uma API HTTP/JSON mínima e especializada para execução de inferência dedutiva e geração de justificações lógicas (*Why / Why not*).

> [!IMPORTANT]
> **API Exclusivamente Interna:** Este serviço não deve ser exposto diretamente a clientes externos ou ao *Frontend*. Apenas o **Backend Orquestrador (FastAPI)** comunica com este micro-serviço. O orquestrador atua como fachada, camada de validação e agregador.

```mermaid
flowchart LR
    Orch["Backend Orquestrador\n(FastAPI :8000)"]
    Prolog["Motor SWI-Prolog\n(:8080)"]
    Rules["Base de Conhecimento\n(rules.pl)"]

    Orch -->|"POST /evaluate (JSON)"| Prolog
    Prolog -->|"Consulta Predicados"| Rules
    Rules -->|"Unificação e Prova"| Prolog
    Prolog -->|"JSON (decision + justification)"| Orch
```

### 1.1 Configuração Base e Resolução de Rede

| Ambiente | URL Base | Contexto de Execução |
|:---|:---|:---|
| **Ambiente Local (Host)** | `http://localhost:8080` | Executado diretamente na máquina host via `swipl src/main.pl` |
| **Ambiente Docker (Inter-contentor)** | `http://prolog-engine:8080` | Resolução de nome de serviço interna na rede `retail-network` |

O servidor é implementado em SWI-Prolog utilizando as bibliotecas nativas `library(http/thread_httpd)` e `library(http/http_dispatch)`, operando em modo multi-threaded.

---

## 2. Endpoint de Avaliação de Regras

### 2.1 `POST /evaluate`

Avalia um conjunto de factos contra a base de conhecimento dedutiva carregada no motor lógico e devolve uma decisão determinística acompanhada pela respetiva cadeia de justificação.

* **Método HTTP:** `POST`
* **Caminho:** `/evaluate`
* **Headers Obrigatórios:**
  * `Content-Type: application/json`
  * `Accept: application/json`

---

## 3. Especificação do Contrato POC Inicial

### 3.1 Pedido (Request Body)

O payload submetido deve ser um objeto JSON com o cenário de teste e o valor numérico a testar pelas regras lógicas de demonstração:

```json
{
  "scenario": "test",
  "value": 42
}
```

#### Tabela de Campos do Pedido:

| Campo | Tipo JSON | Unificação Prolog | Obrigatório | Descrição |
|:---|:---|:---|:---:|:---|
| `scenario` | `string` | Átomo ou String Prolog (`Request.scenario`) | **Sim** | Identificador do tipo de cenário a processar (ex.: `"test"`). |
| `value` | `number` / `integer` | Número Prolog (`Request.value`) | **Sim** | Valor numérico sujeito às cláusulas e predicados de validação. |

---

### 3.2 Respostas do Motor

#### 3.2.1 Resposta de Sucesso — Aprovação (`HTTP 200 OK`)

Quando os factos unificam com uma regra positiva de decisão (ex.: `value =:= 42`):

```json
{
  "status": "success",
  "decision": "approved",
  "justification": [
    "Value is 42",
    "Dummy rule matched"
  ]
}
```

#### 3.2.2 Resposta de Sucesso — Rejeição / Fallback (`HTTP 200 OK`)

Quando a condição de aprovação falha, o predicado `evaluate_scenario/3` dispara a regra alternativa de salvaguarda (*fallback rule*):

```json
{
  "status": "success",
  "decision": "rejected",
  "justification": [
    "Value is not 42",
    "Default fallback rule applied"
  ]
}
```

#### Tabela de Campos da Resposta de Sucesso:

| Campo | Tipo JSON | Mapeamento Prolog | Descrição |
|:---|:---|:---|:---|
| `status` | `string` | Átomo `"success"` | Indica que a inferência foi executada sem erros no motor. |
| `decision` | `string` | Átomo (`approved` ou `rejected`) | Veredito final determinado pelas regras lógicas. |
| `justification` | `array[string]` | Lista de termos convertida para JSON | Lista sequencial dos passos de prova e regras aplicadas (*Explainability*). |

---

### 3.3 Respostas de Erro

#### 3.3.1 Payload Inválido ou Parâmetros Ausentes (`HTTP 400 Bad Request`)

Gerado quando o leitor JSON do Prolog (`http_read_json_dict/3`) falha ao descodificar o payload ou quando a estrutura de dados não contém as chaves exigidas:

```json
{
  "status": "error",
  "message": "Invalid JSON payload or missing required parameters",
  "decision": "error",
  "justification": []
}
```

#### 3.3.2 Erro Interno do Motor (`HTTP 500 Internal Server Error`)

Ocorre caso seja gerada uma exceção lógica não capturada durante o ciclo de prova no predicado Prolog. O servidor SWI-Prolog devolve uma resposta de erro HTTP com a descrição da anomalia.

---

## 4. Exemplos Práticos de Teste Direto (Host Local)

Estes comandos destinam-se a testes pontuais e validação operacional do micro-serviço Prolog de forma isolada (porta 8080):

### 4.1 Teste de Aprovação (`value = 42`)

**Em Bash / cURL:**
```bash
curl -X POST http://localhost:8080/evaluate \
  -H "Content-Type: application/json" \
  -d '{"scenario": "test", "value": 42}'
```

**Em PowerShell (Windows — `curl.exe`):**
```powershell
curl.exe -X POST http://localhost:8080/evaluate `
  -H "Content-Type: application/json" `
  -d '{\"scenario\": \"test\", \"value\": 42}'
```

**Em PowerShell (Windows — `Invoke-RestMethod`):**
```powershell
$body = @{ scenario = "test"; value = 42 } | ConvertTo-Json
Invoke-RestMethod -Uri http://localhost:8080/evaluate -Method Post -ContentType "application/json" -Body $body
```

### 4.2 Teste de Rejeição (`value = 15`)

**Em Bash / cURL:**
```bash
curl -X POST http://localhost:8080/evaluate \
  -H "Content-Type: application/json" \
  -d '{"scenario": "test", "value": 15}'
```

**Em PowerShell (Windows — `curl.exe`):**
```powershell
curl.exe -X POST http://localhost:8080/evaluate `
  -H "Content-Type: application/json" `
  -d '{\"scenario\": \"test\", \"value\": 15}'
```

---

---

## 5. Endpoints do Motor de Exemplo dos Professores (`sp_exp2.pl` do Moodle — `/inference/*`)

O módulo [`prolog_engine/src/api/inference_routes.pl`](../../prolog_engine/src/api/inference_routes.pl) expõe a API REST para o **motor pericial de exemplo dos professores (`sp_exp2.pl`)** fornecido no Moodle (`prolog_engine/Ficheiros de Apoio Sistemas Periciais_ sp_exp1.pl, sp_exp2.pl e base de conhecimento-20260928/`). 

Este subsistema opera sobre bases de conhecimento de teste (como `vehicles`, adaptada de `veiculos2.txt`), disponibilizando operações de *forward-chaining*, metaconhecimento e explicabilidade bidirecional (*How* / *Why Not*), mantendo-se perfeitamente isolado do motor de avaliação do retalho ([Secção 2](#2-endpoint-de-avaliação-de-regras)).

### 5.1 `POST /inference/load`
Carrega e compila uma base de conhecimento em memória dinâmica.

* **Método:** `POST`
* **Caminho:** `/inference/load`
* **Pedido (JSON):**
  ```json
  {
    "knowledge_base": "vehicles"
  }
  ```
* **Resposta de Sucesso (`HTTP 200 OK`):**
  ```json
  {
    "status": "success",
    "message": "Knowledge base 'vehicles' loaded successfully",
    "initial_facts_count": 3
  }
  ```
* **Resposta de Erro (`HTTP 400 Bad Request`):**
  ```json
  {
    "status": "error",
    "message": "Knowledge base 'inexistente' not found"
  }
  ```

---

### 5.2 `POST /inference/run`
Executa o ciclo de encadeamento para a frente (*forward-chaining*) sobre os factos correntes, acionando o metaconhecimento e derivando novos factos fundamentados.

* **Método:** `POST`
* **Caminho:** `/inference/run`
* **Pedido (JSON):** `{}` ou corpo vazio
* **Resposta de Sucesso (`HTTP 200 OK`):**
  ```json
  {
    "status": "success",
    "initial_facts_count": 3,
    "derived_facts_count": 2,
    "total_facts": 5,
    "derived_facts": [
      {
        "id": 4,
        "fact": "classe(meu_veiculo,pesado)",
        "rule_id": 6,
        "justified_by": [2]
      },
      {
        "id": 5,
        "fact": "pesado(meu_veiculo,camiao)",
        "rule_id": 2,
        "justified_by": [3, 4]
      }
    ]
  }
  ```

---

### 5.3 `GET /inference/facts`
Devolve a listagem integral de todos os factos atualmente presentes na memória de trabalho (iniciais e derivados).

* **Método:** `GET`
* **Caminho:** `/inference/facts`
* **Resposta de Sucesso (`HTTP 200 OK`):**
  ```json
  {
    "status": "success",
    "facts_count": 5,
    "facts": [
      {"id": 1, "fact": "lotacao(meu_veiculo,3)"},
      {"id": 2, "fact": "peso(meu_veiculo,4500)"},
      {"id": 3, "fact": "tipo(meu_veiculo,mercadorias)"},
      {"id": 4, "fact": "classe(meu_veiculo,pesado)"},
      {"id": 5, "fact": "pesado(meu_veiculo,camiao)"}
    ]
  }
  ```

---

### 5.4 `POST /inference/how`
Explica o raciocínio causal de derivação de um facto (*How*), construindo recursivamente a árvore de justificações a partir de `justifica/3`.

* **Método:** `POST`
* **Caminho:** `/inference/how`
* **Pedido (JSON):**
  ```json
  {
    "fact_id": 4
  }
  ```
* **Resposta de Sucesso (`HTTP 200 OK`):**
  ```json
  {
    "status": "success",
    "fact_id": 4,
    "explanation": [
      "Fact 4 -> classe(meu_veiculo,pesado) concluded by rule 6",
      "Based on facts: [2]",
      "Fact 2 -> peso(meu_veiculo,4500) was an initial fact"
    ]
  }
  ```
* **Resposta de Erro (`HTTP 400 Bad Request`):**
  ```json
  {
    "status": "error",
    "message": "Fact ID 99 not found"
  }
  ```

---

### 5.5 `POST /inference/whynot`
Explica por que razão um determinado facto não foi deduzido (*Why Not*), identificando as regras candidatas com essa conclusão e as premissas em falta ou não satisfeitas.

* **Método:** `POST`
* **Caminho:** `/inference/whynot`
* **Pedido (JSON):**
  ```json
  {
    "fact": "classe(meu_veiculo,ligeiro)"
  }
  ```
* **Resposta de Sucesso (`HTTP 200 OK`):**
  ```json
  {
    "status": "success",
    "fact": "classe(meu_veiculo,ligeiro)",
    "explanation": [
      "Investigating why 'classe(meu_veiculo,ligeiro)' was not concluded:",
      "Rule 7 could conclude 'classe(meu_veiculo,ligeiro)':",
      "  Failed premise: avalia(peso(meu_veiculo,=<,3500))"
    ]
  }
  ```

---

### 5.6 `POST /inference/reset`
Limpa toda a memória de trabalho do motor pericial (`facto/2`, `ultimo_facto/1`, `justifica/3`), restabelecendo uma sessão limpa.

* **Método:** `POST`
* **Caminho:** `/inference/reset`
* **Pedido (JSON):** `{}` ou corpo vazio
* **Resposta de Sucesso (`HTTP 200 OK`):**
  ```json
  {
    "status": "success",
    "message": "Inference engine session reset"
  }
  ```

---

## 6. Evolução Futura: Contrato do Domínio de Retalho

Com a formalização completa das heurísticas do perito Dustin Hopper para devoluções e trocas, o endpoint `/evaluate` suportará cenários ricos de retalho.

### 6.1 Proposta de Payload de Retalho (`scenario = "retail_return"`)

```json
{
  "scenario": "retail_return",
  "item": {
    "category": "apparel",
    "is_underwear": false,
    "has_tags": true,
    "condition": "unworn_clean"
  },
  "purchase": {
    "has_receipt": true,
    "is_gift_receipt": false,
    "days_since_purchase": 18,
    "channel": "physical_store",
    "payment_method": "credit_card"
  }
}
```

### 6.2 Mapeamento Interno em Prolog Dicts

O SWI-Prolog consome o payload diretamente como um dicionário estruturado:

```prolog
evaluate_scenario(Request, Decision, Justifications) :-
    Request.scenario == "retail_return",
    Item = Request.item,
    Purchase = Request.purchase,
    % Exemplo de unificação de regras do perito
    check_item_eligibility(Item, ItemJustifications),
    check_receipt_timeline(Purchase, TimelineJustifications),
    resolve_decision(ItemJustifications, TimelineJustifications, Decision, Justifications).
```

### 6.3 Proposta de Resposta com Decisões de Negócio

O contrato de resposta manterá a estrutura uniforme (`status`, `decision`, `justification`), expandindo os valores de `decision` para o domínio de retalho:

```json
{
  "status": "success",
  "decision": "approved",
  "justification": [
    "Item satisfies hygiene criteria (not underwear, original tags intact)",
    "Original purchase receipt verified",
    "Return requested within the 30-day policy window (18 elapsed days)",
    "Eligible for full refund via original tender (credit_card)"
  ]
}
```

Possíveis decisões suportadas pelo sistema pericial:
* `"approved"` — Devolução aprovada com reembolso total no método original.
* `"store_credit_only"` — Devolução aceite apenas como vale de loja (ex.: talão de oferta ou sem recibo com autorização).
* `"manager_override"` — Exceção que requer validação presencial do gerente de loja (ex.: defeito de fabrico).
* `"rejected"` — Devolução recusada com indicação clara dos motivos (*Why not*).

---

## 7. Documentos Relacionados

* [Arquitetura do Motor Prolog](../architecture/prolog_engine.md) — Camadas de transporte (`api/`) e domínio (`core/`).
* [API Pública v1 do Orquestrador](orchestrator_api_v1.md) — Ponto de entrada público do sistema.
* [Catálogo de Schemas Pydantic](schemas.md) — DTOs Python correspondentes a este contrato.
* [Requisito de Explicabilidade](../domain/explainability.md) — Princípios de transparência e estrutura de justificações.
