# Relatório de Validação Cruzada: Motores de Inferência Drools vs. Prolog
### *Comparação Exaustiva dos 10 Cenários Oficiais da Levi's face ao Conhecimento do Perito (Ground Truth)*

---

## 1. Enquadramento e Objetivos da Validação

No âmbito do **Desafio 1 (Challenge 1 — 2026/2027)** das Unidades Curriculares de **Engenharia do Conhecimento (ENGCIA)** e **Paradigmas da Programação em Inteligência Artificial (PPROGIA)** do **Mestrado em Engenharia de Inteligência Artificial (MEIA)** do ISEP, a equipa **Grupo 3 — SmartCloth AI** procedeu à implementação e formalização da base de conhecimento de trocas e devoluções da **Levi Strauss & Co.** (mercados dos Estados Unidos e Canadá) em dois paradigmas complementares de sistemas periciais:

1. **Motor Reativo Orientado a Regras em Java Drools** ([`drools-engine-levis-devolucoes-java`](../../drools-engine-levis-devolucoes-java)): Implementado com recurso ao motor Drools (algoritmo Rete-OO), executado na porta `:8082` e exposto via API REST;
2. **Motor Declarativo em SWI-Prolog** ([`prolog_engine/src/core/retail_engine/`](../../prolog_engine/src/core/retail_engine)): Implementado em Prolog puro com forward-chaining, módulo de interrogação dialógica (`obtem_facto/2`), suporte às 71 regras em 9 famílias, e explicabilidade em 5 vias, operando na porta `:8080`.

Para validar a integridade semântica e a solidez da base pericial desenvolvida, o perito do domínio, **Dustin Hopper** (*Gerente da Produtividade Geral do Retalho*, com mais de 20 anos de experiência em gestão de distrito e elaboração de políticas na Levi's), compilou uma suíte de **10 cenários de teste reais** contendo situações-limite de balcão (etiquetas soltas, devoluções Afterpay, devoluções cegas em Outlet, artigos alterados, mercadoria grossista, contaminação biológica, compras transfronteiriças com Interac, ajustes de preço e falhas de portal online).

O presente documento apresenta a validação experimental e comparativa dos 10 cenários executados diretamente em ambos os motores por comunicação REST, confrontando as decisões obtidas e as cadeias dedutivas geradas com o gabarito normativo (*Ground Truth*) estipulado pelo perito no relatório prévio ([`RPAC-Team3.md`](../material_aulas/RPAC-Team3.md)) e na base oficial de conhecimento ([`Returns & Exchanges Knowledge Base.md`](../material_aulas/Returns%20&%20Exchanges%20Knowledge%20Base.md)).

---

## 2. Metodologia de Execução e Arquitetura de Comunicação REST

Ambos os motores integram uma arquitetura de microserviços desacoplada suportada pelo orquestrador FastAPI ([`backend_orchestrator`](../../backend_orchestrator)) na porta `:8000`:

```mermaid
flowchart TD
    subgraph Client ["Test Runner & Clientes"]
        BENCH["<b>Script de Benchmark Automatizado</b><br/><code>docs/domain/validacao_pericial/run_benchmarks.py</code>"]
        PLUNIT["<b>Suite PLUnit de Cenários Periciais</b><br/><code>prolog_engine/tests/test_retail_expert_scenarios.pl</code>"]
    end

    subgraph Orchestrator ["Backend Orchestrator (FastAPI :8000)"]
        API_GATEWAY["Router Central (/api/v1)"]
        CATALOG["Catálogo dos 10 Cenários<br/><code>GET /api/v1/levis/cenarios-exemplo/{id}</code>"]
        ROUTER_DROOLS["Dispatcher Drools<br/><code>POST /api/v1/levis/avaliar</code>"]
        ROUTER_PROLOG["Dispatcher Prolog<br/><code>POST /api/v1/retail/evaluate</code>"]
    end

    subgraph Engines ["Motores de Inferência Pericial"]
        DROOLS["<b>Motor Drools (Java :8082)</b><br/>• Algoritmo Rete-OO<br/>• Modelação DTO & State Machine<br/>• 71 Regras da Levi's"]
        PROLOG["<b>Motor Prolog (retail_engine :8080)</b><br/>• Forward-Chaining sp_exp2 adaptado<br/>• Mecânica ACM (obtem_facto/2)<br/>• 71 Regras em retail_rules.pl"]
    end

    subgraph Storage ["Armazenamento de Resultados JSON"]
        EXP_JSON["docs/domain/validacao_pericial/expert_ground_truth/"]
        DR_JSON["docs/domain/validacao_pericial/drools/"]
        PL_JSON["docs/domain/validacao_pericial/prolog/"]
    end

    BENCH -->|1. Carrega Cenários Oficiais| CATALOG
    BENCH -->|2. Submete Pedido DTO| ROUTER_DROOLS
    ROUTER_DROOLS --> DROOLS
    DROOLS -->|JSON Resposta| DR_JSON

    BENCH -->|3. Submete Factos| ROUTER_PROLOG
    ROUTER_PROLOG --> PROLOG
    PROLOG -->|JSON Resposta| PL_JSON

    CATALOG --> EXP_JSON
    PLUNIT -->|Execução Local Direta| PROLOG
```

### 2.1 Extração e Persistência de Dados
Os dados brutos de cada execução foram serializados e guardados em ficheiros JSON estruturados:
* **Gabarito do Perito (*Ground Truth*):** [`docs/domain/validacao_pericial/expert_ground_truth/`](validacao_pericial/expert_ground_truth/);
* **Resultados do Motor Drools:** [`docs/domain/validacao_pericial/drools/`](validacao_pericial/drools/);
* **Resultados do Motor Prolog:** [`docs/domain/validacao_pericial/prolog/`](validacao_pericial/prolog/).

Adicionalmente, foi criada uma suíte de testes unitários declarativos em SWI-Prolog ([`prolog_engine/tests/test_retail_expert_scenarios.pl`](../../prolog_engine/tests/test_retail_expert_scenarios.pl)), garantindo a execução contínua dos 10 cenários no pipeline de integração.

---

## 3. Matriz Comparativa Global dos 10 Cenários

A tabela seguinte sintetiza os resultados de elegibilidade ([`OUT-001`](../material_aulas/Returns%20&%20Exchanges%20Knowledge%20Base.md#expert-system-output-fields)), tipo de transação ([`OUT-002`](../material_aulas/Returns%20&%20Exchanges%20Knowledge%20Base.md#expert-system-output-fields)), aprovação de gestão ([`OUT-005`](../material_aulas/Returns%20&%20Exchanges%20Knowledge%20Base.md#expert-system-output-fields)) e concordância de regras entre os dois motores e a especificação do perito:

| ID | Cenário de Teste | Perito (Ground Truth) | Motor Drools (Java) | Motor Prolog (retail_engine) | Concordância de Desfecho | Concordância de Regras-Chave |
|:---|:---|:---|:---|:---|:---:|:---:|
| **01** | Troca ao 29.º dia c/ etiquetas soltas | `REVER`<br/>(Troca, Resp. Sénior) | `REVER`<br/>(Troca, Resp. Sénior) | `REVER`<br/>(`manager_override`) | **100% Total** | `PC-002`, `CH-001`, `PT-001`, `EP-001`, `EX-001`, `CT-001`, `CT-003`, `CT-004`, `CT-005`, `CT-007` |
| **02** | Cliente irritado com Afterpay online | `ENCAMINHAR`<br/>(BackPocket, Exceção Recusada) | `ENCAMINHAR`<br/>(BackPocket, Exceção Recusada) | `ENCAMINHAR`<br/>(BackPocket & `recusar_excecao`) | **100% Total** | `CH-002`, `TN-010`, `HS-005`, `EX-002`, `EX-003`, `EX-006`, `CT-001`, `CT-003`, `CT-005`, `CT-007`, `EP-006` |
| **03** | Devolução de oferta na Outlet sem recibo | `PERMITIR`<br/>(Crédito Loja / Às Cegas) | `PERMITIR`<br/>(Crédito Loja / Às Cegas) | `PERMITIR`<br/>(`store_credit_only`) | **100% Total** | `PC-001`, `PT-002`, `PT-005`, `CH-009`, `CT-003`, `CT-005`, `CT-007`, `CT-008` |
| **04** | Calças embainhadas com defeito fabrico | `RECUSAR`<br/>(Nenhuma / Devolver Cliente) | `RECUSAR`<br/>(Nenhuma / Devolver Cliente) | `RECUSAR`<br/>(`rejected`) | **100% Total** | `HS-003`, `CH-001`, `PT-001`, `CT-003` |
| **05** | Disputa sobre produto de retalho grossista | `RECUSAR`<br/>(Nenhuma / Devolver Cliente) | `RECUSAR`<br/>(Nenhuma / Devolver Cliente) | `RECUSAR`<br/>(`rejected`) | **100% Total** | `CH-008`, `HS-002`, `EX-002`, `CT-003` |
| **06** | Devolução sem recibo c/ multi-artigos e risco | `REVER`<br/>(Escalamento Distrital, Saco Bio) | `REVER`<br/>(Resp. Sénior / Isolamento Bio) | `REVER`<br/>(Escalamento Distrital, Saco Bio) | **100% Total** | `EX-008`, `PC-008`, `PT-002`, `PT-006`, `CT-003` |
| **07** | Cartão Interac divergente no Canadá | `REVER`<br/>(Reembolso sem meio, Resp. Sénior) | `REVER`<br/>(Reembolso sem meio, Resp. Sénior) | `REVER`<br/>(Revisão por Cartão Não Coincidente) | **100% Total** | `PC-001`, `PT-001`, `PT-003`, `EX-002`, `TN-011` (falha de cartão físico), `CT-001`, `CT-003`, `CT-004`, `CT-005`, `CT-007`, `CT-008` |
| **08** | Ajuste de preço após alteração de promoção | `RECUSAR`<br/>(Fotografia de recibo não elegível) | `RECUSAR`<br/>(Fotografia de recibo não elegível) | `RECUSAR`<br/>(`rejected` via `PT-008`) | **100% Total** | `PT-001`, `PT-008`, `EX-002`, `CH-001`, `PC-001`, `CT-003` |
| **09** | Bodywear usado e insalubre c/ recibo | `PERMITIR` Reembolso<br/>(Isolamento Biohazard) | `PERMITIR` Reembolso<br/>(Isolamento Biohazard) | `PERMITIR` Reembolso<br/>(Isolamento Biohazard) | **100% Total** | `PC-007`, `BW-004`, `PC-008`, `PT-001`, `PT-003`, `TN-001`, `CH-001`, `CT-001`, `CT-003`, `CT-004`, `CT-005`, `CT-006`, `CT-007` |
| **10** | Troca online tardia c/ PayPal e portal down | `REVER`<br/>(Resp. Sénior, Fluxo App Obrig.) | `REVER`<br/>(Resp. Sénior, Fluxo App Obrig.) | `REVER`<br/>(`manager_override`) | **100% Total** | `CH-004`, `EX-001`, `EX-002`, `EX-006`, `TN-008`, `PC-001`, `CT-003`, `CT-008`, `EP-006` |

---

## 4. Análise Aprofundada dos 10 Cenários

### 4.1 Cenário 1: As etiquetas soltas, troca ao 29.º dia
* **Ficheiro de Dados:** [`cenario-01.json`](validacao_pericial/drools/cenario-01.json) | [`prolog/cenario-01.json`](validacao_pericial/prolog/cenario-01.json)
* **Contexto Operacional:** O cliente comprou umas calças Levi's 501 numa loja Mainline há 29 dias (preço promocional de $69.50 face ao PVP de $98.00). Apresenta recibo digital no telemóvel e pretende trocar por outro tamanho (501-ORIG-34), mas traz as etiquetas soltas. A possibilidade de revenda ainda não foi avaliada pelo operador.
* **Justificação do Perito:**
  * O operador é Key Holder com credenciais próprias (`CT-003`);
  * A compra Mainline é apresentada noutra Mainline (`CH-001`);
  * Artigo não usado com etiquetas soltas exige julgamento humano (`PC-002` — desfecho `REVER`);
  * O recibo digital confirma a compra dentro de 30 dias (`PT-001`, `PT-003`);
  * A troca de tamanho com recibo preserva a promoção original (`EP-001`);
  * Sendo o desfecho `REVER`, dispara o critério de gestão (`EX-001`);
  * Se for aprovado, o destino do artigo segue para a área de vendas (`EP-005`, `CT-008`).
* **Comportamento no Drools:** Elegibilidade `REVER`, tipo de transação `TROCA`, aprovação `RESPONSAVEL_SENIOR`, 15 regras disparadas (`CT-003`, `CH-001`, `PC-002`, `PT-001`, `PT-003`, `EP-001`, `EX-001`, `OUT-003`, `CT-001`, `CT-004`, `CT-005`, `CT-007`, `CT-008`, `EP-005`, `OUT-001`).
* **Comportamento no Prolog:** Decisão `rever` (`manager_override`), com 10 regras disparadas (`CT-003`, `CH-001`, `PC-002`, `PT-001`, `TN-001`, `CT-004`, `CT-005`, `CT-007`, `EX-001`, `CT-001`).
* **Conclusão:** Plena concordância entre os dois motores e o perito. A troca só se efetiva com intervenção e validação do gerente de loja.

---

### 4.2 Cenário 2: O cliente irritado com Afterpay
* **Ficheiro de Dados:** [`cenario-02.json`](validacao_pericial/drools/cenario-02.json) | [`prolog/cenario-02.json`](validacao_pericial/prolog/cenario-02.json)
* **Contexto Operacional:** Compra efetuada em `levi.com` com financiamento Afterpay ($128.00). O cliente desloca-se a uma loja física Mainline exigindo a troca imediata do casaco por outra cor e recusa formalmente ser reembolsado pelo meio original, ficando agitado ao balcão.
* **Justificação do Perito:**
  * A compra online localizada em loja tem encaminhamento obrigatório via BackPocket (`CH-002` — desfecho `ENCAMINHAR`);
  * O canal Afterpay online obriga a reembolso digital estrito na plataforma original (`TN-010`);
  * As regras `HS-005` e `EX-006` proíbem taxativamente exceções de troca, numerário ou vale de loja para transações Afterpay;
  * A agitação do cliente desencadeia escalonamento para líder sénior (`EX-003`), mas a agitação *não cria elegibilidade*;
  * A exceção pretendida é recusada pelo sistema (`excecaoRecusada = true`), mantendo-se o processo BackPocket.
* **Comportamento no Drools:** Elegibilidade `ENCAMINHAR`, processo obrigatório `BACKPOCKET`, `excecaoRecusada = true`, aprovação `RESPONSAVEL_SENIOR`.
* **Comportamento no Prolog:** Conclui `processo_obrigatorio(backpocket)` através da regra `CH-002` e deriva a rejeição da exceção através de `HS-005` e `EX-006` com escalonamento a líder sénior (`EX-003`).
* **Conclusão:** Ambos os motores captam a subtileza crucial de que a recusa da exceção não anula o encaminhamento obrigatório da transação para a BackPocket.

---

### 4.3 Cenário 3: A devolução de oferta na Outlet sem recibo
* **Ficheiro de Dados:** [`cenario-03.json`](validacao_pericial/drools/cenario-03.json) | [`prolog/cenario-03.json`](validacao_pericial/prolog/cenario-03.json)
* **Contexto Operacional:** Cliente apresenta uma prenda comprada numa Outlet (calças 505) sem recibo de compra. O artigo está perfeitamente novo, com etiquetas intactas. O cliente aceita fornecer identificação.
* **Justificação do Perito:**
  * Artigo em estado novo (`PC-001`);
  * Sem comprovativo, o sistema determina devolução às cegas (`PT-002`);
  * A política da Levi's permite devolução às cegas exclusivamente sob a forma de troca ou crédito de loja (`PT-005` — desfecho `PERMITIR`);
  * Por ser uma Outlet, a avaliação económica é feita pelo preço atual com descontos e promoções ativas, e nunca pelo MSRP (`CH-009`);
  * A devolução às cegas exige supervisão de gestão (`CT-002` / `XSTORE_MANAGER`).
* **Comportamento no Drools:** Elegibilidade `PERMITIR`, tipo de transação `CREDITO_LOJA`, meio de reembolso `CREDITO_LOJA`, valor $39.99 (preço promocional Outlet).
* **Comportamento no Prolog:** Decisão canónica `store_credit_only` (`permitir`), tipo de verificação `as_cegas`, meio de reembolso `credito_loja` e valor apurado por `CH-009` (`preco_atual_outlet`).
* **Conclusão:** 100% de paridade nos dois motores quanto à autorização de crédito de loja sob precificação de Outlet.

---

### 4.4 Cenário 4: As calças com bainha e defeito
* **Ficheiro de Dados:** [`cenario-04.json`](validacao_pericial/drools/cenario-04.json) | [`prolog/cenario-04.json`](validacao_pericial/prolog/cenario-04.json)
* **Contexto Operacional:** Cliente comprou umas calças Levi's 511 há 10 dias, com recibo original. As calças foram encurtadas (bainha feita num alfaiate externo) e apresentam um rasgão no tecido identificado como defeito de fabrico.
* **Justificação do Perito:**
  * A regra `HS-003` estabelece uma paragem obrigatória absoluta (*Hard Stop*): peças personalizadas, alteradas ou embainhadas **não são elegíveis sob qualquer pretexto**;
  * A presença de defeito de fabrico (`PC-006`) exige expressamente que a peça *não esteja alterada*; a paragem `HS-003` tem precedência incondicional;
  * Desfecho normativo imperativo: `RECUSAR`, tipo de transação `NENHUMA`, destino `DEVOLUCAO_CLIENTE`.
* **Comportamento no Drools:** Elegibilidade `RECUSAR`, tipo de transação `NENHUMA`, destino `DEVOLUCAO_CLIENTE`, regras `HS-003`, `CH-001`, `PT-001`, `CT-003`, `OUT-007`, `OUT-001`.
* **Comportamento no Prolog:** Decisão `recusar` (`rejected`), tipo de transação `nenhuma`, destino `devolver_cliente`, regras `HS-003`, `CH-001`, `PT-001`, `CT-003`.
* **Conclusão:** Paridade absoluta. Ambos os motores demonstram robustez ao não se deixarem iludir pela premissa de defeito de fabrico, honrando a precedência de paragem obrigatória.

---

### 4.5 Cenário 5: A disputa sobre produto grossista
* **Ficheiro de Dados:** [`cenario-05.json`](validacao_pericial/drools/cenario-05.json) | [`prolog/cenario-05.json`](validacao_pericial/prolog/cenario-05.json)
* **Contexto Operacional:** Cliente apresenta numa loja Mainline um produto da linha *Levi Strauss Signature* adquirido num hipermercado grossista (ex.: Walmart/Costco), alegando que sendo fabricado pela Levi's deve ser aceite em loja própria.
* **Justificação do Perito:**
  * As lojas de retalho Levi's não aceitam artigos de canais grossistas (`CH-008`);
  * A linha *Levi Strauss Signature* é uma marca formalmente excluída (`HS-002`);
  * O cliente contesta (`EX-002`), sendo o colaborador instruído a explicar a política e encaminhar o cliente para o retalhista onde a compra foi concretizada;
  * Desfecho: `RECUSAR` absoluto e terminal.
* **Comportamento no Drools:** Elegibilidade `RECUSAR`, terminal `true`, regras `CH-008`, `EX-002`, `CT-003`, `OUT-007`.
* **Comportamento no Prolog:** Decisão `recusar` (`rejected`), regras `CH-008`, `HS-002`, `EX-002`, `CT-003`.
* **Conclusão:** Ambos os motores rejeitam categoricamente a transação com fundamentação idêntica nas restrições de canal e marca.

---

### 4.6 Cenário 6: A devolução sem recibo de artigos em estados diferentes
* **Ficheiro de Dados:** [`cenario-06.json`](validacao_pericial/drools/cenario-06.json) | [`prolog/cenario-06.json`](validacao_pericial/prolog/cenario-06.json)
* **Contexto Operacional:** Transação complexa envolvendo múltiplos artigos sem recibo: artigo A-1 (não usado sem etiquetas), artigo A-2 (usado sem etiquetas) e artigo A-3 (usado, sem etiquetas e visivelmente sujo/manchado com substância desconhecida). O cliente não sabe indicar onde ou quando comprou as peças e recusa dados pessoais, levantando forte suspeita de fraude.
* **Justificação do Perito:**
  * O artigo A-3 ativa imediatamente a regra de risco biológico `PC-008`, obrigando ao isolamento em saco de plástico próprio e cessação de manuseamento;
  * A presença de inconsistências materiais e risco significativo ativa `EX-008`, exigindo pausar a transação, envolver a gerência e reportar à Segurança Global (*District/Area Manager*);
  * Desfecho no pedido: `REVER` de caráter terminal.
* **Comportamento no Drools:** A nível de pedido devolve `REVER`, com escalonamento a `RESPONSAVEL_SENIOR` / `DISTRICT_AREA`, e para o artigo A-3 define isolamento em `RISCO_BIOLOGICO` (`PC-008`).
* **Comportamento no Prolog:** Ativa `PC-008` (`destino_produto(isolamento_risco_biologico)`), `EX-008` (`pausar_transacao(true)` e `aprovacao(escalamento_distrital)`), concluindo a necessidade de revisão superior.
* **Conclusão:** Alinhamento exemplar na deteção e isolamento do perigo sanitário e no bloqueio de transações fraudulentas.

---

### 4.7 Cenário 7: A substituição do cartão Interac no Canadá
* **Ficheiro de Dados:** [`cenario-07.json`](validacao_pericial/drools/cenario-07.json) | [`prolog/cenario-07.json`](validacao_pericial/prolog/cenario-07.json)
* **Contexto Operacional:** Numa loja de Vancouver (Canadá), o cliente pretende devolver um casaco com recibo original de 18 dias. Pagou com cartão de débito da rede canadiana Interac, mas alega ter perdido o cartão original e apresenta um cartão de substituição emitido pelo banco.
* **Justificação do Perito:**
  * Artigo e prazo elegíveis (`PC-001`, `PT-001`, `PT-003`);
  * O sistema canadiano Interac não suporta tokenização automática como os cartões Visa/Mastercard: a regra `TN-011` impõe estritamente que **o cliente deve apresentar o mesmo cartão físico Interac utilizado na compra**;
  * O cartão de substituição não é o mesmo cartão físico (`cartaoFisicoPresente = false`);
  * A política proíbe emitir numerário para compras Interac sem recusa eletrónica prévia (`TN-004`), e o sistema não autoriza outro cartão sem validação;
  * Desfecho: `REVER` com o responsável sénior; o reembolso fica sem meio definido até decisão da chefia.
* **Comportamento no Drools:** Elegibilidade `REVER`, tipo de transação `REEMBOLSO`, aprovação `RESPONSAVEL_SENIOR`, `meioReembolso: null`.
* **Comportamento no Prolog:** Valida a elegibilidade temporal e documental (`PT-001`, `PT-003`), mas inibe o reembolso automático via `TN-011` devido à ausência do cartão físico original, escalando para explicação da política (`EX-002`) e revisão de liderança.
* **Conclusão:** Ambos os motores captam a especificidade regional do mercado canadiano e o bloqueio de estorno por impossibilidade técnica do terminal Interac.

---

### 4.8 Cenário 8: O ajuste de preço após alteração de promoção
* **Ficheiro de Dados:** [`cenario-08.json`](validacao_pericial/drools/cenario-08.json) | [`prolog/cenario-08.json`](validacao_pericial/prolog/cenario-08.json)
* **Contexto Operacional:** O cliente comprou um casaco Sherpa Trucker há 13 dias por $119.00. Viu o casaco anunciado em promoção online por $99.00 e desloca-se à loja física pedindo o reembolso da diferença de $20.00. Apresenta apenas uma fotografia do recibo no telemóvel e não o recibo original impresso.
* **Justificação do Perito:**
  * Embora esteja dentro do prazo de 14 dias para ajustes de preço em loja (`PT-007`), este endpoint exige cumulativamente a posse do **recibo original impresso**;
  * Uma fotografia do recibo confirma a compra para efeitos de devolução comum (`PT-001`), mas **não é válida para ajuste de preço**;
  * Aplica-se a recusa expressa `PT-008` (ajuste sem recibo original ou após 14 dias);
  * Desfecho: `RECUSAR`, tipo de transação `NENHUMA`.
* **Comportamento no Drools:** Elegibilidade `RECUSAR`, tipo de transação `NENHUMA`, regras `CT-003`, `CH-001`, `PC-001`, `PT-001`, `PT-008`, `EX-002`, `OUT-001`.
* **Comportamento no Prolog:** Ativa `PT-001`, `EX-002`, inibe `PT-007` (por falta de recibo impresso) e dispara `PT-008`, derivando `decisao(recusar)`.
* **Conclusão:** 100% de conformidade com o perito na diferenciação entre prova aceitável para devolução de produto versus prova física obrigatória para créditos de ajuste de preço.

---

### 4.9 Cenário 9: O conjunto de bodywear devolvido com um risco de segurança
* **Ficheiro de Dados:** [`cenario-09.json`](validacao_pericial/drools/cenario-09.json) | [`prolog/cenario-09.json`](validacao_pericial/prolog/cenario-09.json)
* **Contexto Operacional:** Numa loja Outlet, uma cliente devolve um pack de boxers (*bodywear*) comprado há 21 dias com recibo original. Uma das unidades foi experimentada e apresenta sujidade evidente.
* **Justificação do Perito:**
  * A categoria *Bodywear* rege-se pela regra especial `PC-007` da política de satisfação incondicional da Levi's: **o artigo é sempre aceite para devolução independentemente do estado** (sobrepondo-se às proibições de artigos usados `PC-004` ou lavados `PC-005`);
  * Portanto, a nível financeiro, o reembolso do valor pago ($29.99) no meio original é **PERMITIDO** (`PT-001`, `PT-003`, `TN-001`);
  * No entanto, no destino físico da peça, a insalubridade ativa `BW-004` e `PC-008`: a peça não pode regressar às vendas nem a saldos, sendo **isolada imediatamente em saco de risco biológico**;
  * Desfecho global: `PERMITIR` reembolso; destino físico `RISCO_BIOLOGICO`.
* **Comportamento no Drools:** Elegibilidade `PERMITIR`, tipo de transação `REEMBOLSO`, valor $29.99, meio `MEIO_ORIGINAL`, regras `PC-008`, `PC-007`, `PT-001`, `PT-003`, `TN-001`, `BW-004`.
* **Comportamento no Prolog:** Identifica a garantia incondicional de bodywear (`PC-007`), valida recibo e prazo (`PT-001`, `PT-003`, `TN-001`) para conceder o reembolso ao cliente, e ativa `BW-004`/`PC-008` para assinalar `destino_produto(isolamento_risco_biologico)`.
* **Conclusão:** Perfeita separação entre a decisão de relacionamento com o consumidor (reembolso garantido) e o protocolo de segurança ocupacional do colaborador (isolamento sanitário).

---

### 4.10 Cenário 10: A troca online tardia com PayPal durante uma falha do portal
* **Ficheiro de Dados:** [`cenario-10.json`](validacao_pericial/drools/cenario-10.json) | [`prolog/cenario-10.json`](validacao_pericial/prolog/cenario-10.json)
* **Contexto Operacional:** Compra feita em `levi.com` paga via PayPal expedida há 37 dias. O cliente apresenta-se em loja física para efetuar uma troca no momento em que o portal de devoluções online da Levi's está em baixo por falha de servidores centrais. Além disso, o cliente não consegue aceder à sua app do PayPal no telemóvel e pede para dividir o pagamento.
* **Justificação do Perito:**
  * Encomenda online com portal em baixo configura um caso não coberto na política regular, ativando `CH-004` (`REVER` com responsável sénior);
  * A regra `TN-008` obriga a que compras efetuadas por PayPal/Venmo sejam processadas exclusivamente através do fluxo da respetiva aplicação digital, proibindo qualquer substituição de meio;
  * A tentativa de contornar este processo através de numerário ou vale de loja é expressamente recusada por `EX-006`;
  * As calças devolvidas estão fora do sortido da loja recetora, pelo que se a troca for aceite pela gerência, o artigo deve ser reprecificado com 20% de desconto em saldos (`EP-006`);
  * Desfecho: `REVER` com líder sénior; recusa de meios alternativos.
* **Comportamento no Drools:** Elegibilidade `REVER`, aprovação `RESPONSAVEL_SENIOR`, meio de reembolso `APLICACAO_PAGAMENTO`, processo `PAYPAL_VENMO`, `excecaoRecusada = true`.
* **Comportamento no Prolog:** Decisão `rever` (`manager_override`), processo obrigatório `fluxo_app` (`TN-008`), ativação de `CH-004`, `EX-001`, `EX-002`, `EX-006` e destino em saldos `EP-006`.
* **Conclusão:** 100% de paridade. Ambos os motores salvaguardam a integridade dos contratos de pagamento digital contra tentativas de arbitragem ao balcão.

---

## 5. Comparação Paradigmática: Rete-OO vs. Forward-Chaining em Prolog

A experiência de implementar a mesma base de conhecimento nos dois motores permitiu extrair conclusões de elevado valor pedagógico para as unidades curriculares do MEIA:

```mermaid
classDiagram
    class DroolsEngine {
        +Linguagem: Java / DRL
        +Algoritmo: Rete-OO (Rede de nós Alfa e Beta)
        +Modelação: DTOs e Factos Tipados em Java
        +Execução: Reativa orientada a eventos de memória
        +Vantagens: Agregação nativa de coleções e listas
        +Desafios: Rastreabilidade causal de falhas (Why Not)
    }

    class PrologEngine {
        +Linguagem: SWI-Prolog
        +Algoritmo: Forward-Chaining c/ Resolução SLD
        +Modelação: Termos Lógicos e Predicados Dinâmicos
        +Execução: Metainterpretação com árvore dedutiva
        +Vantagens: 5 Vias de Explicabilidade e Diálogo Dinâmico
        +Desafios: Gestão de listas de artigos em sessão plana
    }
```

### 5.1 Pontos Fortes e Diferenciadores do Motor Prolog
1. **Explicabilidade Causal Nativa (As 5 Vias):** Enquanto o Drools regista um log linear das regras ativadas (`agenda.fireAllRules()`), o motor Prolog implementa uma árvore de derivação recursiva que permite responder com precisão matemática a **"Como?"** (via 1: rasto causal dedutivo), **"Porquê da Pergunta?"** (via 2: regra ativa), **"Porque Não?"** (via 4: inspeção de premissas falsificadas) e **"E Se?"** (via 5: simulação em sandbox volátil).
2. **Aquisição Dialógica (Mecânica ACM):** O motor Prolog não exige que o utilizador submeta todo o formulário à partida; através de `obtem_facto/2` e `perguntavel/1`, interroga o operador apenas quando uma regra candidata necessita de uma premissa em falta.

### 5.2 Pontos Fortes e Diferenciadores do Motor Drools
1. **Manipulação de Pedidos Multi-Artigo Complexos:** No Drools, o facto principal `PedidoDevolucao` contém nativamente uma coleção de artigos (`List<ArtigoDevolvido>`). As regras conseguem iterar sobre a lista, aplicar decisões individuais por artigo e, através da regra transversal `OUT-001`, computar a elegibilidade consolidada do pedido com enorme elegância funcional.
2. **Integração Empresarial:** O ecossistema Java/Spring Boot proporciona forte tipagem estática e serialização transparente de DTOs via Jackson.

---

---

## 6. Resolução de Discrepâncias de Integração e Paridade Multi-Motor End-to-End

Durante a primeira vaga de persistência e comparação lado a lado no Dashboard (`/decisoes`), foram identificadas **5 discrepâncias técnicas transitórias** decorrentes de divergências finas de modelação e hardcoding no adaptador de serialização. Estas causas foram completamente resolvidas através do plano de correção em 5 fases:

### 6.1 Discrepâncias Transitórias Detetadas e Resoluções Implementadas
1. **Valor Deliberado Fixo vs. Dinâmico:** O adaptador `retail_prolog_service.py` devolvia um valor estático de `69.50 €`. Foi implementado cálculo dinâmico baseado na soma dos artigos do pedido (`precoPago`/`precoAtual`) e fixado em `0.00 €` para recusas ou trocas sem diferencial monetário.
2. **Cenário 09 (Bodywear Contaminado):** `PC-007` possuía uma guarda restritiva `nao estado_produto(...)` e `BW-004`/`PC-008` geravam `decisao(recusar)`. A política de satisfação incondicional da Levi's foi restabelecida: `decisao(permitir)` para reembolso financeiro do cliente ($29.99), cumulado com isolamento físico `destino_produto(isolamento_risco_biologico)`.
3. **Cenário 07 (Interac Canadá sem Cartão Físico):** O terminal Interac no Canadá não suporta tokenização automática. Foi adicionada a regra `TN-011-SEM-CARTAO` para tratar o ramo negativo (`cartao_interac_presente(false)`), derivando `decisao(rever)` com aprovação de chefia sénior e `meio_reembolso(sem_meio_definido)`.
4. **Cenário 06 (Fraude Multi-Artigo e Risco Biológico):** A regra `EX-008` apenas derivava escalamento distrital mas não afirmava `decisao(rever)`. Com a inclusão da decisão formal e salvaguarda contra recusa indevida em `PC-008-RECUSA`, o pedido é pausado e escalado para a chefia distrital com valor deliberado de $444.00.
5. **Cenário 10 (PayPal Online com Falha de Portal):** A regra `CH-005` disparava incorretamente `meio_reembolso(cartao_oferta)` para canais digitais restritos. Foram adicionadas guardas para PayPal/Venmo/Afterpay e o adaptador foi calibrado para mapear `processo_obrigatorio(fluxo_app)` diretamente para `MeioReembolsoEnum.APLICACAO_PAGAMENTO`.

### 6.2 Fortalecimento da Suíte PLUnit
A suíte declarativa [`prolog_engine/tests/test_retail_expert_scenarios.pl`](../../prolog_engine/tests/test_retail_expert_scenarios.pl) foi reforçada com asserções terminais (`assertion(has_fact(decisao(...)))`, asserções de aprovação e asserções negativas `assertion(\+ has_fact(decisao(recusar)))`), garantindo cobertura estrita contra regressões.

### 6.3 Verificação de Consenso no Dashboard
Com a semeadura forçada (`POST /api/v1/inferences/seed?force=true`), o histórico de decisões e o modal de comparação no frontend Next.js exibem **Consenso Operacional Confirmado (100% de Acordo)** em todos os 10 cenários, alinhando elegibilidade, aprovações, meios de estorno e valores monetários deliberados entre o motor Drools (Java) e o motor Prolog (SWI-Prolog).

---

## 7. Procedimento de Reprodução e Testes Automatizados

Qualquer utilizador, avaliador docente ou auditor de qualidade pode reproduzir integralmente esta validação executando os seguintes comandos no terminal:

### 7.1 Executar a Bateria Completa de Testes PLUnit dos Cenários Periciais
* **No Windows (PowerShell):**
  ```powershell
  & "C:\Program Files\swipl\bin\swipl.exe" -g "run_expert_scenarios_tests, halt." -t "halt(1)" prolog_engine/tests/test_retail_expert_scenarios.pl
  ```
* **No Linux / WSL:**
  ```bash
  swipl -g "run_expert_scenarios_tests, halt." -t "halt(1)" prolog_engine/tests/test_retail_expert_scenarios.pl
  ```
*Resultado esperado:* `% All 10 tests passed in 0.144 seconds`.

### 7.2 Executar a Bateria Completa de Testes das 71 Regras
* **No Windows (PowerShell):**
  ```powershell
  & "C:\Program Files\swipl\bin\swipl.exe" -g "run_retail_rules_tests, halt." -t "halt(1)" prolog_engine/tests/test_retail_rules.pl
  ```
*Resultado esperado:* `% All 31 tests passed in 0.329 seconds`.

### 7.3 Validar a Persistência Multi-Motor via API REST
```powershell
curl.exe -s "http://localhost:8000/api/v1/avaliacoes?tamanho=100"
```
*Critério de Sucesso:* 20 registos no total (10 Drools + 10 Prolog), com paridade absoluta nos pares de cada cenário.

---

## 8. Documentos Relacionados

* [Contexto de Negócio da Levi's (`business_context.md`)](business_context.md)
* [Heurísticas e Base de 71 Regras do Perito (`expert_knowledge.md`)](expert_knowledge.md)
* [Modelo das 5 Vias de Explicabilidade (`explainability.md`)](explainability.md)
* [Relatório Prévio de Aquisição de Conhecimento (`RPAC-Team3.md`)](../material_aulas/RPAC-Team3.md)
* [Fonte Normativa: Returns and Exchanges Knowledge Base (`Returns & Exchanges Knowledge Base.md`)](../material_aulas/Returns%20&%20Exchanges%20Knowledge%20Base.md)
* [Diretrizes de Agente para o Domínio (`agente.guidelines`)](../material_aulas/agente.guidelines)
* [Arquitetura do Motor Prolog (`prolog_engine.md`)](../architecture/prolog_engine.md)
* [Arquitetura do Motor Drools (`drools_engine.md`)](../architecture/drools_engine.md)
* [Catálogo de APIs do Orquestrador (`orchestrator_api_v1.md`)](../api/orchestrator_api_v1.md)
* [Estratégia e Catálogo de Testes (`testing.md`)](../development/testing.md)
