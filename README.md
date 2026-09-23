# Sistema Pericial de Diagnóstico para Devoluções e Trocas no Retalho
### *Retail Returns & Exchanges Diagnostic Expert System*

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Prolog](https://img.shields.io/badge/SWI--Prolog-v9%2B%20%7C%20v10%2B-red.svg)](https://www.swi-prolog.org/)
[![Docker](https://img.shields.io/badge/Docker-Enabled-2496ED.svg?logo=docker&logoColor=white)](https://www.docker.com/)
[![Tests](https://img.shields.io/badge/Tests-12%2F12%20Passing-brightgreen.svg)]()
[![Clean Architecture](https://img.shields.io/badge/Architecture-Clean%20%2F%20Decoupled-orange.svg)]()

> **Mestrado em Engenharia de Inteligência Artificial (MEIA)**  
> **Unidades Curriculares:** Engenharia do Conhecimento em IA (ENGCIA) & Paradigmas de Programação em IA (PPROGIA)  
> **Desafio:** Challenges 4Teams — **Equipa 3** (Ano Letivo 2026/2027)  
> **Perito de Domínio:** Dustin Hopper (Especialista em fluxos operacionais e atendimento de retalho)

---

## 1. Visão Geral do Projeto

O objetivo basilar deste projeto consiste em **incorporar conhecimento humano especializado em sistemas modernos de Inteligência Artificial**, traduzindo a experiência operacional de retalho na linha da frente em decisões de triagem automatizadas, determinísticas, instantâneas e plenamente auditáveis.

O caso de uso modelado incide sobre o fluxo de **Devoluções e Trocas no Retalho** (*Returns & Exchanges*), abordando os múltiplos fatores operacionais com que os colaboradores de loja se deparam diariamente:
* **Elegibilidade do Artigo:** Categoria do produto, peças íntimas (*bodywear* / restrições de higiene e *biohazard*), estado de conservação (usado, lavado, danificado ou com defeito de fabrico) e integridade de etiquetas originais.
* **Comprovativo de Compra:** Recibo físico ou digital, ausência de comprovativo (*blind return*), compras em regime de presente (*gift receipt*).
* **Prazos Operacionais:** Janela normal de devolução (ex.: 30 dias), prazos para ajuste de preço (*price adjustment*, ex.: 14 dias) ou transações fora de prazo com conversão em crédito de loja.
* **Canais e Pontos de Venda:** Loja física, *outlet* ou comércio eletrónico (*online*).
* **Métodos de Pagamento (*Tenders*):** Dinheiro, cartão bancário, plataformas diferidas (*Afterpay*, *Klarna*), vales de loja ou *PayPal*.

### Requisito Primordial: Explicabilidade (*Explainability & Transparency*)
O sistema transcende o modelo de decisão de "caixa opaca". Não se limita a gerar uma ação binária (`approved`, `rejected`, `store_credit_only`, `manager_override`); gera obrigatoriamente uma **cadeia de justificações explícita** (*Why / Why not*), permitindo que clientes e gerentes compreendam de forma transparente as políticas e regras de negócio que fundamentaram a decisão.

---

## 2. Arquitetura da Solução Global

O sistema assenta numa arquitetura modular de micro-serviços orientada a orquestração e inferência baseada em regras:

```mermaid
flowchart TD
    subgraph UI ["Camada de Apresentação"]
        Frontend["Frontend Web / POS App\n(Interface de Atendimento de Loja)"]
    end

    subgraph Orchestration ["Orquestração de Negócio"]
        FastAPI["Backend Orquestrador\n(Python / FastAPI)\nValidação de Schemas, DTOs & Coordenação"]
    end

    subgraph InferenceEngines ["Motores de Inferência Periciais"]
        Prolog["Micro-serviço SWI-Prolog\n(REST API Daemon Contentorizado)\nMotor Lógico Dedutivo & Explicabilidade"]
        Drools["Micro-serviço Drools\n(Java Rule Engine)\nMotor Rete / Regras de Produção"]
    end

    Frontend <-->|HTTP POST / JSON| FastAPI
    FastAPI <-->|POST /evaluate (JSON)| Prolog
    FastAPI <-->|HTTP / REST (JSON)| Drools
```

* **Frontend:** Interface com o utilizador que submete o cenário da devolução exclusivamente ao backend orquestrador.
* **Backend Orquestrador (FastAPI):** Atua como o ponto central de encaminhamento, agrega respostas e valida dados sem embutir regras de diagnóstico de retalho.
* **Motores de Inferência Periciais:**
  1. **SWI-Prolog Engine (Implementado):** Motor dedutivo exposto como micro-serviço HTTP REST, focado na inferência lógica e geração explicativa de diagnósticos.
  2. **Drools Engine (Próxima Fase):** Segundo motor de inferência baseado em regras de produção para comparação, auditoria cruzada e robustez.

---

## 3. Micro-Serviço SWI-Prolog (Estado Atual)

O micro-serviço localizado em [`prolog_engine/`](file:///c:/Users/santi/Desktop/meia-equipa3-challenge1-26_27/prolog_engine) implementa a prova de conceito (POC) da infraestrutura de inferência, desenhado segundo os princípios de **Clean Architecture**:

```text
prolog_engine/
├── Dockerfile                  # Contentorização oficial baseada em swipl:latest
├── .dockerignore               # Otimização do contexto de build
├── src/
│   ├── api/                    # Camada de Transporte HTTP e I/O
│   │   ├── server.pl           # Gestão do daemon HTTP multi-threaded (thread_httpd)
│   │   └── routes.pl           # Endpoints REST e desserialização/serialização JSON
│   ├── core/                   # Camada de Domínio / Lógica Pura (Prolog Puro)
│   │   └── rules.pl            # Predicados de inferência e regras de explicabilidade
│   └── main.pl                 # Entry point, leitura de variáveis de ambiente e ciclo de vida
└── tests/                      # Suíte de Testes Automatizados (library(plunit))
    ├── test_rules.pl           # Testes unitários do motor core (7 cenários)
    └── test_api.pl             # Testes de integração HTTP e rotas (5 cenários)
```

### Características e Decisões de Engenharia
1. **Separação Rígida de Camadas:** A camada `core/rules.pl` não possui qualquer dependência de bibliotecas web ou de rede, garantindo portabilidade, facilidade de manutenção e testes unitários instantâneos.
2. **Transferência de Dados via *Prolog Dicts*:** A comunicação entre o router HTTP e as regras de domínio faz-se exclusivamente através de dicionários nativos (`_{...}`), permitindo acesso declarativo seguro via `get_dict/3`.
3. **Servidor HTTP Multi-Threaded:** Implementado com as bibliotecas nativas `library(http/thread_httpd)` e `library(http/http_dispatch)`, suportando concorrência elevada em produção.
4. **Tratamento de Exceções Gracioso:** Intercetação com `catch/3` de JSONs malformados, retornando códigos de estado conformes (`HTTP 400 Bad Request` vs `HTTP 200 OK`).

---

## 4. Contratos de API (`POST /evaluate`)

O serviço expõe a rota REST `POST /evaluate` para avaliação de cenários:

### 4.1 Exemplo de Pedido de Sucesso
* **Endpoint:** `POST http://localhost:8080/evaluate`
* **Headers:** `Content-Type: application/json`

**Corpo do Pedido:**
```json
{
  "scenario": "test",
  "value": 42
}
```

**Resposta (HTTP 200 OK):**
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

### 4.2 Exemplo de Rejeição Determinística
**Corpo do Pedido:**
```json
{
  "scenario": "test",
  "value": 15
}
```

**Resposta (HTTP 200 OK):**
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

### 4.3 Exemplo de Tratamento de Erro (JSON Inválido)
**Resposta (HTTP 400 Bad Request):**
```json
{
  "status": "error",
  "decision": "rejected",
  "justification": [
    "Invalid JSON payload: malformed syntax or bad formatting"
  ]
}
```

*(Consulte [`docs/api_contracts.md`](file:///c:/Users/santi/Desktop/meia-equipa3-challenge1-26_27/docs/api_contracts.md) para a especificação completa e contratos de evolução para o domínio do retalho).*

---

## 5. Como Executar e Testar

### Pré-requisitos
* **Opção Contentorizada (Recomendada):** [Docker Desktop](https://www.docker.com/) instalado e em execução.
* **Opção Nativa Local:** [SWI-Prolog](https://www.swi-prolog.org/) (versão 9.x ou 10.x de 64 bits).

---

### 5.1 Execução com Docker

1. **Construir a Imagem:**
   ```bash
   # A partir da raiz do repositório
   docker build -t prolog-engine -f prolog_engine/Dockerfile prolog_engine
   ```

2. **Iniciar o Contentor:**
   ```bash
   docker run -d --name prolog-service -p 8080:8080 prolog-engine
   ```

3. **Verificar os Registos (Logs):**
   ```bash
   docker logs -f prolog-service
   ```

4. **Parar e Limpar o Contentor:**
   ```bash
   docker stop prolog-service
   docker rm prolog-service
   ```

---

### 5.2 Execução Local Direta (SWI-Prolog)

1. Navegar para a pasta do motor:
   ```bash
   cd prolog_engine
   ```
2. Iniciar o micro-serviço (porta padrão 8080):
   ```bash
   swipl src/main.pl
   ```
   *(Para definir uma porta alternativa em ambiente local, defina a variável `PORT=8085` antes da execução).*

---

### 5.3 Executar a Suíte de Testes Automatizados

O projeto inclui cobertura integral com a biblioteca `library(plunit)`:

* **Testes Unitários da Lógica Core (`rules.pl`):**
  ```bash
  swipl -g "run_tests, halt" -s prolog_engine/tests/test_rules.pl
  ```
  *(Valida 7/7 casos de teste: números inteiros, floats, valores não numéricos, omissão de chaves e salvaguardas).*

* **Testes de Integração da API HTTP (`routes.pl` & `server.pl`):**
  ```bash
  swipl -g "run_tests, halt" -s prolog_engine/tests/test_api.pl
  ```
  *(Valida 5/5 casos de teste: despacho HTTP, respostas canónicas, fallbacks e interceção de JSON malformado).*

---

### 5.4 Testar via Linha de Comandos (cURL / PowerShell)

Com o servidor ativo na porta 8080:

* **No Linux / macOS / Bash:**
  ```bash
  curl -X POST http://localhost:8080/evaluate \
    -H "Content-Type: application/json" \
    -d '{"scenario": "test", "value": 42}'
  ```

* **No Windows (PowerShell):**
  ```powershell
  Invoke-RestMethod -Uri "http://localhost:8080/evaluate" `
    -Method Post `
    -ContentType "application/json" `
    -Body '{"scenario": "test", "value": 42}' | ConvertTo-Json
  ```

---

## 6. Estrutura de Ficheiros do Repositório

```text
meia-equipa3-challenge1-26_27/
├── .gitignore                      # Regras de exclusão Git (Prolog, Docker, Python, Java, SO)
├── Implementation_plan_start.md    # Plano de implementação do POC e relatório de execução
├── README.md                       # Documentação principal e guia de onboarding
├── docs/                           # Documentação arquitetural e de engenharia
│   ├── Main_context.md             # Contexto pericial, académico e regras brutas de retalho
│   ├── architecture.md             # Arquitetura detalhada, Clean Architecture e diagramas
│   └── api_contracts.md            # Especificação dos contratos JSON de entrada e saída
└── prolog_engine/                  # Micro-serviço SWI-Prolog
    ├── Dockerfile                  # Imagem de produção baseada em swipl:latest
    ├── .dockerignore               # Otimização do build Docker
    ├── src/
    │   ├── api/
    │   │   ├── server.pl           # Configuração do daemon HTTP (thread_httpd)
    │   │   └── routes.pl           # Handlers de rota REST e serialização JSON
    │   ├── core/
    │   │   └── rules.pl            # Base de conhecimento e inferência de domínio pura
    │   └── main.pl                 # Bootstrap da aplicação e ciclo de vida
    └── tests/
        ├── test_rules.pl           # Testes unitários PLUnit para o core
        └── test_api.pl             # Testes de integração PLUnit para a API HTTP
```

---

## 7. Documentação de Apoio

* [`docs/Main_context.md`](file:///c:/Users/santi/Desktop/meia-equipa3-challenge1-26_27/docs/Main_context.md) — Contexto de negócio, enquadramento curricular MEIA e heurísticas do perito de retalho.
* [`docs/architecture.md`](file:///c:/Users/santi/Desktop/meia-equipa3-challenge1-26_27/docs/architecture.md) — Desenho arquitetural, Clean Architecture, diagramas de sequência e guia operacional.
* [`docs/api_contracts.md`](file:///c:/Users/santi/Desktop/meia-equipa3-challenge1-26_27/docs/api_contracts.md) — Contratos JSON formais de comunicação entre componentes.
* [`Implementation_plan_start.md`](file:///c:/Users/santi/Desktop/meia-equipa3-challenge1-26_27/Implementation_plan_start.md) — Histórico de execução de cada fase da infraestrutura base.

---

## 8. Próximos Passos (Roadmap)

1. **Desenvolvimento do Orquestrador FastAPI:** Criação do serviço Python para intermediação entre o cliente e os motores de regras.
2. **Formalização da Base de Regras de Retalho:** Modelação em Prolog das árvores de decisão recolhidas com o perito Dustin Hopper (análise de artigos de vestuário, *tags*, etiquetas, recibos, prazos de 30/14 dias e métodos de pagamento).
3. **Integração do Motor Drools:** Implementação do micro-serviço em Java/Drools e testes comparativos de inferência diagnóstica.
4. **Frontend de Simulação:** Desenvolvimento de uma interface gráfica para operadores de loja simularem devoluções em tempo real com auditoria explicativa.
