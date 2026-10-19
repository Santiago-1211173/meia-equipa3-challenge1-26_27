# Plano de Implementação: Motor Pericial de Retalho em Prolog
### *Adaptação Modular do sp_exp2 com Explicabilidade em 5 Vias e Isolamento por Paridade*
#### *MEIA 2026/2027 — Challenge 1 (Grupo 3: SmartCloth AI)*

---

## 1. Justificação Arquitetural da Estratégia de Isolamento e Paridade

A decisão de **isolar o motor pericial adaptado num novo diretório** (`prolog_engine/src/core/retail_engine/`) em vez de sobrescrever o motor de apoio original assenta em três princípios sólidos de engenharia de software e avaliação académica:

```mermaid
flowchart TD
    subgraph Motores ["Coexistência e Isolamento de Motores em Prolog"]
        direction TB
        
        ACAD["<b>1. Motor Académico Original (sp_exp2)</b><br/><code>src/core/inference/</code><br/>• Base: vehicles.pl (veiculos2.txt)<br/>• Endpoints: /inference/*<br/>• Propósito: Referência pura dos professores e testes de regressão"]
        
        RETAIL["<b>2. Motor Pericial de Retalho Adaptado</b><br/><code>src/core/retail_engine/</code><br/>• Base: retail_rules.pl (71 regras Levi's)<br/>• Mecânica ACM: obtem_facto/2, perguntavel/1<br/>• 5 Vias: How, Why Ask, Output Why, Why Not, What-If<br/>• Endpoints: /retail/*"]
    end

    TOGGLE["<b>Mecanismo de Despacho & Feature Toggle</b><br/>• Variável: PROLOG_ENGINE_MODE (retail / academic / dual)<br/>• Desacoplamento: colegas podem experimentar soluções alternativas sem quebrar o core<br/>• Paridade: demonstração aos professores do 'Antes vs. Depois' lado a lado"]

    ACAD --> TOGGLE
    RETAIL --> TOGGLE
```

### Vantagens Estratégicas:
1. **Preservação da Linha de Base (*Baseline*):** O motor de veículos fornecido pelos professores ([`sp_exp2.pl`](../../prolog_engine/Ficheiros%20de%20Apoio%20Sistemas%20Periciais_%20sp_exp1.pl,%20sp_exp2.pl%20e%20base%20de%20conhecimento-20260928/sp_exp2.pl) / [`inference/engine.pl`](../../prolog_engine/src/core/inference/engine.pl)) permanece 100% funcional e compilável, com os seus testes unitários em [`tests/test_inference_engine.pl`](../../prolog_engine/tests/test_inference_engine.pl) a passar incondicionalmente.
2. **Defesa e Comparação Oral Perfeita:** Na apresentação de 50% de avaliação prática ([`Challenges4Teams-26-27.md`](../material_aulas/Challenges4Teams-26-27.md)), podes demonstrar ao docente: *“Aqui está o motor que nos deram a classificar camiões; e aqui está a evolução que desenhámos a resolver devoluções da Levi's com as suas perguntas e simulações contrafactuais”*.
3. **Colaboração em Equipa (*Pluggable Engines*):** Se outro elemento do Grupo 3 quiser testar um meta-intérprete alternativo (ex.: puramente orientado a *Backward-Chaining* ou com lógica difusa), o sistema suporta ligar e desligar módulos através de configuração sem conflitos no Git.

---

## 2. Mapa das Fontes da Verdade e Citações Oficiais

Todas as decisões técnicas deste plano derivam estritamente dos artefactos fornecidos:

| Documento de Referência | Âmbito | Citações e Requisitos Incorporados |
|:---|:---|:---|
| **[`MI_Perguntas_ACM.md`](../material_aulas/MI_Perguntas_ACM.md)** | Teoria PPROGIA (ACM) | • Substituição de `facto(N, X)` por `obtem_facto(X, N)` no `verifica_condicoes/2` (Secção 15).<br/>• Metaconhecimento de atributos perguntáveis `perguntavel/1` (Secção 9).<br/>• Tratamento defensivo de `nao_sei` com `ja_perguntado/1` (Secção 8 e 16).<br/>• Justificação bidirecional da pergunta ativa (*“Porquê?”*) (Secção 12). |
| **[`RPAC-Team3.md`](../material_aulas/RPAC-Team3.md)** | Relatório Oficial Grupo 3 | • 4 Desfechos Canónicos: `PERMITIR`, `RECUSAR`, `REVER`, `ENCAMINHAR` (Tabela 5).<br/>• Ordem estrita de prioridade entre regras (Precedência 1 a 7, Secção 4.6).<br/>• Entradas observáveis `IN-001` a `IN-010` (Tabela 6).<br/>• 10 Fluxogramas de decisão (Figuras 1 a 10). |
| **[`Returns & Exchanges Knowledge Base.md`](../material_aulas/Returns%20&%20Exchanges%20Knowledge%20Base.md)** | Fonte Normativa de Negócio | • As 71 regras de negócio distribuídas por 9 famílias (`HS`, `PC`, `PT`, `CH`, `TN`, `EP`, `EX`, `CT`, `BW`).<br/>• Critérios de exceção da gerência e tratamento de Afterpay e franquia canadiana. |
| **[`Challenges4Teams-26-27.md`](../material_aulas/Challenges4Teams-26-27.md)** | Critérios de Avaliação | • Demonstração prática do sistema pericial (50% do Challenge 1).<br/>• Explicabilidade e rastreabilidade total das deduções. |
| **[`sp_exp2_engine_analysis.md`](../architecture/sp_exp2_engine_analysis.md)** | Engenharia Interna | • Dissecação técnica dos 6 blocos do motor original e otimização por metaconhecimento `facto_dispara_regras/2`. |
| **[`prolog_expert_system_adaptation.md`](../architecture/prolog_expert_system_adaptation.md)** | Arquitetura Consolidada | • Arquitetura dual (Modo Batch REST vs. Modo Dialógico interativo) e 5 vias de explicabilidade. |

---

## 3. Estrutura de Diretórios Alvo

A arquitetura do micro-serviço SWI-Prolog ([`prolog_engine/`](../../prolog_engine)) evoluirá para a seguinte organização modular:

```text
prolog_engine/
├── src/
│   ├── api/
│   │   ├── server.pl                 # Gestão do daemon HTTP (thread_httpd)
│   │   ├── routes.pl                 # Endpoints legados (POC /evaluate)
│   │   ├── inference_routes.pl       # Endpoints do motor académico (/inference/*)
│   │   └── retail_routes.pl          # Endpoints do motor pericial de retalho (/retail/*)
│   ├── core/
│   │   ├── rules.pl                  # Regras simples da POC inicial
│   │   ├── inference/                # Motor Académico dos Professores (sp_exp2 preservado)
│   │   │   ├── engine.pl             # Motor sp_exp2 desacoplado de terminal
│   │   │   └── kb/
│   │   │       └── vehicles.pl       # Base de veículos (veiculos2.txt)
│   │   └── retail_engine/            # Motor Pericial de Retalho Adaptado (Levi's)
│   │       ├── engine.pl             # Motor evoluído (obtem_facto, 5 vias, what-if sandbox)
│   │       ├── interactive.pl        # Gestor de diálogo, perguntas dinâmicas e 'porquê?'
│   │       └── kb/
│   │           └── retail_rules.pl   # Base oficial de 71 regras Levi's + metaconhecimento
│   └── main.pl                       # Bootstrapping e registo condicional de módulos
└── tests/
    ├── test_inference_engine.pl      # Testes de regressão do motor académico (8 testes)
    ├── test_retail_rules.pl          # Testes unitários das 71 regras de retalho
    ├── test_retail_interactive.pl    # Testes do diálogo dinâmico e tratamento 'não sei'
    └── test_retail_explainability.pl # Testes das 5 vias de explicabilidade
```

---

## 4. Fases de Execução do Plano

O desenvolvimento está estruturado em **cinco fases incrementais**, permitindo validação e testes automatizados no final de cada etapa:

```mermaid
gantt
    title Fases de Execução: Motor Pericial de Retalho em Prolog
    dateFormat  YYYY-MM-DD
    section Fase 1: Fundação
    Isolamento modular e estrutura de diretórios       :p1, 2026-10-14, 1d
    section Fase 2: Conhecimento
    Codificação das 71 regras da Levi's               :p2_1, after p1, 2d
    Metaconhecimento de disparo e perguntáveis        :p2_2, after p2_1, 1d
    section Fase 3: Motor Dialógico
    Implementação de obtem_facto/2 e ja_perguntado/1  :p3_1, after p2_2, 2d
    Gestão de 'não sei' e 'porquê da pergunta'        :p3_2, after p3_1, 1d
    section Fase 4: Explicabilidade 5 Vias
    Como (how) e Porque Não (whynot) em retalho       :p4_1, after p3_2, 1d
    Porquê do Output e What-If em sandbox             :p4_2, after p4_1, 2d
    section Fase 5: API & Integração
    Endpoints REST (/retail/*) e DTOs                 :p5_1, after p4_2, 1d
    Suíte PLUnit integrada e validação FastAPI        :p5_2, after p5_1, 2d
```

---

### FASE 1: Isolamento Modular e Preservação de Paridade
* **Objetivo:** Estabelecer o novo diretório `retail_engine` sem interferir com `core/inference/`, assegurando que o motor original de veículos continua 100% operacional.
* **Tarefas Concretas:**
  1. Criar a estrutura `prolog_engine/src/core/retail_engine/` e `prolog_engine/src/core/retail_engine/kb/`.
  2. Criar o módulo base `retail_engine` herdando os operadores canónicos (`regra`, `se`, `entao`, `e`, `nao`).
  3. Atualizar `src/main.pl` para carregar ambos os módulos em namespaces isolados.
  4. Executar a suíte de testes de regressão [`test_inference_engine.pl`](../../prolog_engine/tests/test_inference_engine.pl) e comprovar que os 8 testes continuam a passar com 0 falhas.

---

### FASE 2: Modelação da Base de Conhecimento de Retalho (`retail_rules.pl`)
* **Objetivo:** Traduzir formalmente as **71 regras de negócio** e a ordem de prioridade de [`RPAC-Team3.md`](../material_aulas/RPAC-Team3.md) para a DSL do motor.
* **Tarefas Concretas:**
  1. **Codificar as 9 Famílias com Prefixos Oficiais:**
     * `HS-001` a `HS-006`: Paragens obrigatórias (credenciais do operador, SKU, marcas excluídas, personalização).
     * `PC-001` a `PC-008`: Condição física da peça (etiquetas, lavado, usado, defeito de fabrico, risco biológico e regime especial de *bodywear*).
     * `PT-001` a `PT-008`: Comprovativos e prazos (recibo fiscal, 30 dias, devolução às cegas, ajuste de preço até 14 dias).
     * `CH-001` a `CH-010`: Canais de venda (Mainline, Outlet, Online levi.com/ca, grossista, franquia canadiana).
     * `TN-001` a `TN-012`: Meios de reembolso (meio original, cartões, Afterpay, vales de compras).
     * `EP-001` a `EP-007`: Trocas e preservação de promoções de compra.
     * `EX-001` a `EX-008`: Regras de intervenção e exceção da gerência.
     * `CT-001` a `CT-008`: Auditoria, controlos de sessão e documentação.
     * `BW-001` a `BW-004`: Destino pós-devolução de vestuário íntimo.
  2. **Implementar a Ordem de Precedência (RPAC Secção 4.6):**
     * Garantir que `HS-006` avalia antes de qualquer outra regra;
     * Assegurar que regras de salubridade (`PC-008`) e paragens obrigatórias (`HS-001` a `HS-004`) sobrepõem-se a quaisquer exceções de gerência (`EX-001` a `EX-008`).
  3. **Mapear Metaconhecimento de Disparo:**
     * Definir `facto_dispara_regras/2` indexando os padrões dos factos de entrada `IN-001` a `IN-010` às regras candidatas correspondentes.
  4. **Declarar Atributos Perguntáveis:**
     * Mapear `perguntavel/1` para factos observáveis pelo colaborador de loja, proibindo expressamente a interrogação de conclusões diagnósticas.

---

### FASE 3: Motor Core Adaptado com a Mecânica de ACM [CONCLUÍDA]
* **Objetivo:** Implementar o algoritmo proposto pelo Professor ACM em [`MI_Perguntas_ACM.md`](../material_aulas/MI_Perguntas_ACM.md), capacitando o motor para interrogar ativamente o operador perante dados omissos.
* **Estado:** **100% Concluído e Validado** (12/12 testes em [`tests/test_retail_interactive.pl`](../../prolog_engine/tests/test_retail_interactive.pl) aprovados sem falhas).
* **Tarefas Concretas:**
  1. [x] **Predicado `obtem_facto/2`:**
     * Substituição da pesquisa estática `facto(N, X)` no `verifica_condicoes/2` e `avalia/2` por `obtem_facto(X, N)` em [`src/core/retail_engine/engine.pl`](../../prolog_engine/src/core/retail_engine/engine.pl).
     * Interceção de premissas ausentes com `e_perguntavel/2` protegido contra variáveis não instanciadas e verificação de `perguntavel/1`.
  2. [x] **Gestão de Sessão e Prevenção de Loops:**
     * Registo atómico `assertz(ja_perguntado(Template))` antes da interrogação, garantindo que cada atributo é questionado no máximo 1 vez.
     * Tratamento defensivo de respostas `"não sei"` (*nao_sei*): falha graciosa da regra sem asserir negações lógicas, permitindo caminhos alternativos de inferência.
  3. [x] **Rastreabilidade da Regra Ativa e Resposta "Porquê?":**
     * Armazenamento contextual de `regra_ativa(RegraID, Objetivo)` durante `dispara_regras` via `setup_call_cleanup/3`.
     * Intercetação de respostas `"porquê?"` (*Why Ask*), gerando fundamentação com identificador da regra, família (`regra_info/3`), objetivo em teste e fundamento normativo.
  4. [x] **Origem do Facto e Explicabilidade:**
     * Asserção de `justifica(N, utilizador, [])` para factos recolhidos via diálogo.
     * Integração em `como/1` e `explain_how/2` discriminando premissas fornecidas pelo utilizador de factos inferidos por regras.
  5. [x] **Módulo de Diálogo e Suíte de Testes:**
     * Criação de [`src/core/retail_engine/interactive.pl`](../../prolog_engine/src/core/retail_engine/interactive.pl) com formulação em português para os 41 atributos observáveis e suporte a mock queues (`set_mock_answers/1`).
     * Suíte [`tests/test_retail_interactive.pl`](../../prolog_engine/tests/test_retail_interactive.pl) com 12 testes PLUnit cobrindo todos os fluxos normativos e de exceção.

---

### FASE 4: Módulo de Explicabilidade em 5 Vias [CONCLUÍDA]
* **Objetivo:** Implementar as 5 perspetivas analíticas de diagnóstico pericial requeridas para nota máxima no Challenge 1.
* **Estado:** **100% Concluído e Validado** (18/18 testes em [`tests/test_retail_explainability.pl`](../../prolog_engine/tests/test_retail_explainability.pl) aprovados sem falhas).
* **Tarefas Concretas:**
  1. [x] **Via 1: Como? (`como/1` e `explain_how/2` — How):**
     * Predicados adaptados para aceitar tanto identificadores numéricos de factos (`FactId`) como termos compósitos (ex.: `decisao(permitir)`).
     * Formatação formal das regras citadas entre parêntesis retos (ex.: `[PC-001]`, `[PT-003]`) e discriminação rigorosa da proveniência: `utilizador (operador de balcão)` vs. `inicial da base` vs. `conclusão por regra`.
  2. [x] **Via 2: Porquê da Pergunta? (`why_ask/1`, `why_ask/2`, `why_ask/0` — Why Ask):**
     * Resolução contextual direta da regra ativa (`regra_ativa/2`) e do metaconhecimento normativo (`regra_info/3`).
     * Exposição de família formal, objetivo em teste e fundamento normativo tanto via diálogo terminal como chamada programática.
  3. [x] **Via 3: Porquê da Decisão? (`output_why/1`, `output_why/0`, `decision_justification/2` — Output Why):**
     * Predicado de síntese que compila os factos terminais `motivo/1` e `regra_disparada/1` num vetor de strings `justification: list[str]`.
     * Integração direta no retorno do dicionário de `run_engine/1` (`decision` e `justification`), garantindo conformidade imediata com o DTO canónico `EvaluationResponse`.
  4. [x] **Via 4: Porque Não? (`whynot/1` e `explain_whynot/2` — Why Not):**
     * Adaptação de `encontra_regras_whynot/2` e `encontra_premissas_falsas/2` com suporte a cadeias de conjunção `e` e listas multi-elemento.
     * Árvore recursiva de falhas: quando um desfecho (`decisao(permitir)`) não é alcançado, decompõe exatamente que premissas falharam (`elegibilidade_produto(aprovada)`, `nao decisao(recusar)`) e analisa os antecedentes que as originaram (`PC-001`, `PC-006`, `PC-007`).
     * Suporte a atalhos atómicos canónicos: `whynot(permitir)`, `whynot(recusar)`, etc.
  5. [x] **Via 5: E Se? (`what_if/3` — What-If Sandbox):**
     * Implementação do padrão de sandbox transacional com snapshot dinâmico e operador ISO `setup_call_cleanup/3`:
       ```prolog
       what_if(+FactosAdicionar, +FactosRemover, -ResultadoComparativo)
       ```
     * Execução contrafactual sobre memória volátil, cálculo do diferencial de desfecho (`baseline_decision`, `simulated_decision`, `decision_changed`, `impact_summary`) e garantia estrita de reposição com **zero poluição** de memória na sessão persistente.

---

### FASE 5: Camada de Transporte REST, Toggle e Testes PLUnit [CONCLUÍDA]
* **Objetivo:** Expor o motor adaptado via HTTP, criar testes automatizados completos e integrar com o ecossistema FastAPI.
* **Estado:** **100% Concluído e Validado** (81/81 testes PLUnit no Prolog e 153/153 testes Pytest no FastAPI orquestrador aprovados com 0 falhas).
* **Tarefas Concretas:**
  1. [x] **Endpoints REST do Motor de Retalho (`src/api/retail_routes.pl` e `src/main.pl`):**
     * `POST /retail/evaluate`: Avaliação batch canónica com serialização estrita para `EvaluationResponse` canónico (`decision`, `confidence`, `engine`, `facts_count`, `justification[]`).
     * `POST /retail/interactive`: Sessão de interrogação passo-a-passo sem bloqueio de I/O em threads daemon HTTP, retornando estado de conclusão ou perguntas pendentes estruturadas.
     * `POST /retail/whatif`: Simulação contrafactual atómica em sandbox com `setup_call_cleanup/3`, retornando delta comparativo (`decision_changed`, `impact_summary`).
     * `POST /retail/how`: Trajeto causal de dedução por ID numérico de facto ou termo compósito.
     * `POST /retail/whynot`: Análise recursiva da árvore de falhas com regras candidatas e premissas não satisfeitas.
     * `GET /retail/facts` e `POST /retail/reset`: Inspeção e limpeza segura de memória volátil da sessão.
  2. [x] **Feature Toggle no Orquestrador FastAPI:**
     * Adicionada configuração `PROLOG_ENGINE_MODE: Literal["retail", "academic", "dual"] = "retail"` em [`backend_orchestrator/app/core/config.py`](../../backend_orchestrator/app/core/config.py), `.env` e `.env.example`.
     * `PrologClient` atualizado com métodos assíncronos para todos os endpoints `/retail/*` e chaveamento automático baseado no parâmetro `mode` ou na variável de ambiente.
     * `OrchestratorService` com mapeamento canónico de decisões em português (`permitir`, `recusar`, `rever`, `encaminhar`, `vale_loja`, `credito_loja`) para o enum canónico (`approved`, `rejected`, `manager_override`, `store_credit_only`).
     * Rota dedicada `/api/v1/retail/*` implementada em [`backend_orchestrator/app/api/v1/endpoints/retail.py`](../../backend_orchestrator/app/api/v1/endpoints/retail.py) e suporte a query param `?mode=` no endpoint principal `/api/v1/evaluate`.
  3. [x] **Suíte de Testes Automatizados (PLUnit e Pytest):**
     * [`tests/test_retail_rules.pl`](../../prolog_engine/tests/test_retail_rules.pl): 31 testes cobrindo todas as 9 famílias normativas e prioridades de desempate (31/31 aprovados).
     * [`tests/test_retail_explainability.pl`](../../prolog_engine/tests/test_retail_explainability.pl): 18 testes cobrindo os 5 modos de explicabilidade pericial (18/18 aprovados).
     * [`tests/test_retail_interactive.pl`](../../prolog_engine/tests/test_retail_interactive.pl): 12 testes cobrindo interrogação dinâmica e metaconhecimento normativo (12/12 aprovados).
     * [`tests/test_inference_engine.pl`](../../prolog_engine/tests/test_inference_engine.pl): 8 testes do motor académico de veículos preservados sem regressões (8/8 aprovados).
     * [`tests/test_retail_api.pl`](../../prolog_engine/tests/test_retail_api.pl): 12 testes HTTP REST validando todos os 7 endpoints de retalho (12/12 aprovados).
     * **Total PLUnit:** 81/81 testes aprovados (100%).
     * [`backend_orchestrator/tests/test_retail_prolog.py`](../../backend_orchestrator/tests/test_retail_prolog.py): 24 novos testes de integração e unitários cobrindo cliente, toggle, rotas e mapeamento.
     * **Total Pytest:** 153/153 testes aprovados (100%).

---

## 5. Critérios de Sucesso e Validação Final

O projeto cumpre com distinção todos os requisitos pedagógicos e práticos quando:
* [x] O motor académico original de veículos continua a passar nos 8 testes em `test_inference_engine.pl`;
* [x] A nova suíte de testes de retalho valida todas as 71 regras e as 7 prioridades sem ambiguidades lógicas;
* [x] O comando `como/1` detalha a cadeia dedutiva identificando a intervenção do operador e os IDs normativos;
* [x] O comando `whynot/1` identifica corretamente as premissas falhadas em pedidos recusados;
* [x] A interrogação dinâmica formula perguntas perante factos omissos e responde a *"porquê?"*;
* [x] O teste de simulação *What-If* calcula o impacto de hipóteses sem corromper o estado persistente da sessão;
* [x] Todos os contratos JSON cumprem as especificações canónicas de [`schemas.md`](../api/schemas.md).

---

## 6. Documentos Relacionados

* [Plano de Atualização da Documentação Técnica](retail_prolog_documentation_update_plan.md) — Plano mestre de documentação das capacidades do motor de retalho.
* [Arquitetura do Motor Prolog](../architecture/prolog_engine.md) — Clean Architecture, isolamento por paridade e ciclo ACM.
* [Dissecação do Motor sp_exp2](../architecture/sp_exp2_engine_analysis.md) — Análise técnica dos 6 blocos estruturais do motor académico de apoio.
* [Base de Conhecimento Pericial](../domain/expert_knowledge.md) — As 71 regras da Levi's e 7 precedências estritas.
* [Explicabilidade Pericial](../domain/explainability.md) — Modelo formal das 5 vias de explicabilidade implementadas.
* [API Interna do Motor SWI-Prolog](../api/prolog_engine_api.md) — Especificação técnica dos 7 endpoints `/retail/*`.
* [Estratégia e Execução de Testes](testing.md) — Detalhes das suítes de testes PLUnit e Pytest.

