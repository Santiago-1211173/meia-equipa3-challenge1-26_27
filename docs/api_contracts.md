# Contratos de API (JSON Input/Output)

Este documento especifica os contratos de comunicação HTTP/JSON entre o orquestrador (FastAPI) e o motor de inferência SWI-Prolog.

---

## 1. Endpoint de Avaliação de Cenários

* **Rota:** `/evaluate`
* **Método:** `POST`
* **Headers Obrigatórios:**
  * `Content-Type: application/json`
  * `Accept: application/json`

---

## 2. Contrato Base de Teste (POC Inicial)

### 2.1 Pedido (Request)

Submete um cenário de teste com atributos a serem avaliados pelo motor de regras.

```json
{
  "scenario": "test",
  "value": 42
}
```

#### Especificação dos Campos

| Campo | Tipo | Obrigatório | Descrição |
| :--- | :--- | :--- | :--- |
| `scenario` | `string` | Sim | Identificador ou nome do tipo de cenário a avaliar (ex: `"test"`). |
| `value` | `integer` / `number` | Sim | Valor numérico utilizado pelas regras lógicas de demonstração. |

---

### 2.2 Resposta de Sucesso (Response - HTTP 200 OK)

Retorna a decisão calculada pelo motor Prolog e a lista de justificações que fundamentam a conclusão.

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

#### Especificação dos Campos

| Campo | Tipo | Descrição |
| :--- | :--- | :--- |
| `status` | `string` | Estado do processamento (`"success"` ou `"error"`). |
| `decision` | `string` | Decisão apurada pelo motor lógico (ex: `"approved"`, `"rejected"`). |
| `justification` | `array[string]` | Lista de motivos/regras que conduziram à decisão tomada (Explicabilidade). |

---

### 2.3 Exemplo de Rejeição (HTTP 200 OK)

Quando o valor não satisfaz a regra esperada (ex: `value` diferente de `42`):

#### Request:
```json
{
  "scenario": "test",
  "value": 15
}
```

#### Response:
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

---

### 2.4 Resposta de Erro no Pedido (HTTP 400 / 500)

Se o payload JSON for malformado ou se ocorrer uma falha não tratada durante o processamento:

```json
{
  "status": "error",
  "message": "Invalid JSON payload or missing required parameters",
  "decision": "error",
  "justification": []
}
```

---

## 3. Evolução Futura: Cenários do Domínio de Retalho

Nas fases subsequentes de desenvolvimento, este contrato será estendido para suportar os atributos reais do domínio de devoluções e trocas:

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
    "days_since_purchase": 18,
    "channel": "physical_store",
    "payment_method": "credit_card"
  }
}
```
