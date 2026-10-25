# Plano de implementação — Sistema pericial de devoluções e trocas Levi's

## Contexto

O repositório contém apenas as convenções do projeto e `docs/01..06`. É preciso construir, de raiz, o sistema pericial
(Java 21 / Spring Boot 3 / Drools 8 / Angular) que decide devoluções, trocas e ajustes de preço e explica
cada decisão. Este plano, depois de aprovado, é gravado como `docs/07-plano.md` (primeiro passo da Fase 0)
e passa a ser seguido fase a fase: planear → implementar → `mvn clean verify` verde → fase seguinte.

Fonte de verdade: `01` > `02` > `03`/`04`. Nenhuma regra de negócio é inventada: onde a base é omissa,
implementa-se o comportamento hoje documentado (normalmente em `03`), marcado **"a validar"** no
`@descricao` da regra, no teste e no JSON do cenário, e registado em `docs/adr/0003-ambiguidades.md`.

---

## A. Ambiguidades encontradas nas regras

Legenda: **[B]** bloqueia o desenho (decidir antes da fase indicada); **[P]** tem solução provisória
documentada, a validar pela operação; **[D]** inconsistência interna dos documentos (decisão técnica).

### A1. Canal e comprovativo
1. **[P] Canal "desconhecido"** (IN-003). Nenhuma regra de `01`/`02` o trata. `03` (M2) manda seguir para M3
   e deixar o comprovativo decidir em M4. Em aberto: (a) se houver comprovativo válido, o canal passa a ser
   conhecido — usa-se o canal revelado ou continua "desconhecido"? (b) CH-001, CH-010 e EP-005/006/007 exigem
   saber se é "entre canais"; com canal desconhecido não disparam. Provisório: segue para M3; sem comprovativo
   → às cegas (PT-002/PT-005); com comprovativo → verificada pelo caminho de loja; `entreCanais` vem do input.
2. **[P] Canal BackPocket.** `03` M2 agrupa BackPocket com o caminho online, mas M4 só desvia levi.com/levi.ca.
   TN-012 fala em "compra em loja BackPocket". Provisório: canal BACKPOCKET segue o caminho de loja (M4/M5);
   só levi.com/levi.ca vão para ONLINE.
3. **[P] CH-003 "apenas quando o cenário da política o permitir"** — a política não enumera os cenários.
   Provisório: novo input booleano `politicaPermiteAsCegasOnline` (default `false` → RECUSAR). Exige alterar o modelo (ver A6).
4. **[P] Encomenda online encontrada mas portal indisponível** (cenário 10). CH-004 só está no ramo
   "encomenda não encontrada" de `03`; CH-002 exige BackPocket. Não há regra para "encontrada + portal em baixo".
5. **[P] CH-005 vs CH-006 vs TN-008** (cenário 10): online >30 dias → cartão de oferta (CH-005); troca online →
   saldo ao meio original (CH-006); PayPal → só fluxo da app, sem substituir o meio (TN-008/EX-006).
   `03` avalia CH-005 antes da troca, logo uma troca tardia daria cartão de oferta, o que colide com TN-008.
   Também não está definido o que fazer quando o cliente não consegue aceder à app PayPal/Venmo.
6. **[P] Online tardio vs PT-004.** Online verificado >30 dias vai para CH-005 (cartão de oferta, PERMITIR) e não
   para PT-004 (REVER, crédito de loja). Provisório: segue `03` (online nunca passa por PT-003/PT-004).
7. **[P] CH-007 e mercado.** `01` não exige Canadá; `02` exige IN-001 = Canadá. Produto de franquia numa loja dos
   EUA: CH-007, HS-004 ou HS-001? Provisório: segue `01` (prevalece) → CH-007 em qualquer mercado.
8. **[P] HS-002 vs CH-008** (cenário 5): ambos recusam produto grossista; reporta-se o primeiro a disparar (CH-008
   em M2) e HS-002 fica no "Porque não" como "módulo não alcançado".

### A2. Meio de reembolso
9. **[P] Compras pagas em numerário ou cartão de oferta.** Nenhuma regra TN as cobre; `03` (M7) usa PT-003 →
   meio original. Em aberto: reembolso em numerário acima de um limite? cartão de oferta novo ou recarregado?
   Compras online pagas com cartão de oferta? Provisório: `MEIO_ORIGINAL`, "a validar".
10. **[P] Interac com cartão de substituição** (cenário 7). TN-011 exige "o mesmo cartão físico"; TN-002 permite
    reembolso à conta quando o cartão foi perdido mas a conta está ativa — mas TN-002 é para cartões tokenizados
    e o Interac não é tokenizado. Sem o cartão, `03` diz "não processar", sem alternativa (crédito de loja? TN-003?).
    Provisório: TN-011 prevalece → não processar reembolso ao Interac; resultado REVER sem meio definido.
11. **[P] Interac é "débito"?** TN-004 (débito sem numerário) aplica-se a compras Interac? Provisório: não (enum separado).
12. **[P] TN-007 devolução de oferta**: "reembolso ao comprador **ou** crédito de loja" — quem escolhe? Provisório:
    o sistema devolve as duas opções permitidas; a escolha é input (`resolucaoPedida`).
13. **[P] Devolução de oferta sem recibo** (cenário 3): TN-007 exige recibo; aplica-se PT-005 (crédito de loja ao
    preço atual). Coerente, mas confirmar.
14. **[P] Ajuste de preço**: meio de pagamento da diferença não definido (cenário 8 pede cartão de oferta); ajuste
    de compras online não coberto (PT-007 só "loja", PT-008 só prazo/recibo); "artigo idêntico" a um preço
    anunciado online vs preço na loja não definido. "Recibo original" vs fotografia/recibo digital: decidido pelo
    input `reciboOriginal`; provisório: fotografia ≠ original.

### A3. Estado do produto, prazo e valor
15. **[P] PC-008 em artigo que não é bodywear** (cenário 6, mancha visível): PC-008 define o manuseamento mas não a
    elegibilidade. Aceita-se a devolução (e isola-se) ou recusa-se? E "mancha" é `sujoOuInseguro` ou `danificado`?
    Provisório: PC-008 não altera a elegibilidade; o destino passa a RISCO_BIOLOGICO.
16. **[P] Prazo nas devoluções às cegas**: PT-005 não tem limite; cenário 3 ("vários meses", data desconhecida).
    Provisório: sem prazo; `dataCompra` nula permitida só quando não há comprovativo.
17. **[P] PT-004 "baixo risco"**: sem input. Provisório: baixo risco = nenhum `IndicadorFraude` com nível ≥ SIGNIFICATIVO.
18. **[P] PC-004 aprovação da gestão** e **EX-004 "concluível no sistema"**: não há atributo no modelo.
    Provisório: PC-004 usa `PedidoExcecao.aprovada`; EX-004 novo booleano `concluivelNoSistema`.
19. **[P] Nível de aprovação para REVER de PC-002/PC-003/PC-004/PT-004**: `NivelAprovacao` não tem "Gestão da Loja"
    (só XSTORE_MANAGER, RESPONSAVEL_SENIOR, DISTRICT_AREA). Provisório: RESPONSAVEL_SENIOR.
20. **[P] Bodywear com conjunto incompleto** (cenário 9): PC-007 aceita; o valor a reembolsar é o do conjunto ou
    proporcional às unidades devolvidas? Provisório: `precoPago` do artigo tal como registado.
21. **[P] CH-010 "quando permitido pelo POS e pela política"** e **CH-009 vs EP-003** em simultâneo: sem input para a
    permissão do POS. Provisório: valor vem do adaptador POS (`valorCalculadoPos`); CH-009 define a base, EP-003 o escalão.
22. **[P] Contagem dos dias**: "dentro de 30 dias" = `≤ 30` (como em `02`); online usa a data de envio (CH-005) —
    PT-003 online também? Provisório: online usa `dataEnvio`, loja usa `dataCompra`.

### A4. Autorização e controlos
23. **[P] XSTORE_MANAGER** existe no enum `Funcao` mas não consta de HS-006 como processador autorizado.
    Provisório: autorizado (é gestão) — **a validar**.
24. **[P] Origem da identidade do colaborador**: HS-006 avaliado sobre dados do pedido ou do token JWT? Provisório:
    o `Colaborador` é sempre construído a partir do JWT (nunca do corpo do pedido); HS-006 continua a ser regra DRL.

### A5. Decisões com vários artigos (estrutural)
25. **[B] Resultado por artigo** (cenário 6: três artigos em estados diferentes; DTO `ResultadoArtigoResponse`).
    O modelo de `04` só tem uma `Decisao` por pedido, com um único `terminal` e uma única `elegibilidade`: um HS-003
    num artigo terminaria o pedido inteiro. Falta também a regra de agregação (o pedido é PERMITIR se um artigo é
    RECUSAR?). → **pergunta ao utilizador** (ver secção C).

### A6. Inconsistências internas dos documentos [D]
26. `04` diz que EX-008 é terminal, mas `aplicar()` só marca `terminal` em RECUSAR/ENCAMINHAR e EX-008 aplica REVER.
    Decisão: EX-008 marca `suspenso` e `terminal` explicitamente.
27. `aplicar(regra, r, msg)` não sabe se a regra é paragem obrigatória. Decisão: `Decisao` mantém o conjunto de IDs de
    paragem (HS-001..006, CH-007, CH-008) — `aplicar` marca `terminal` quando o ID pertence ao conjunto e o resultado é
    RECUSAR/ENCAMINHAR. CH-002 (ENCAMINHAR para BackPocket) não é terminal.
28. Sobreposição de elegibilidade: regras posteriores sobrescrevem (PC-001 PERMITIR → PT-004 REVER). Decisão técnica:
    `aplicar` nunca baixa a severidade (RECUSAR > ENCAMINHAR > REVER > PERMITIR) exceto quando a regra seguinte
    resolve uma revisão (ex.: PC-002 com IN-010 = sim). Fica em ADR.
29. Exemplo DRL em `04` importa `com.levis.devolucoes.modelo.*`, mas o pacote é `...model`. Usa-se `model`.
30. As convenções do projeto pedem "um DRL e um agenda-group por módulo", mas `05` junta M4+M5 num ficheiro, divide M7 em dois e não
    tem M1. Decisão: seguir os ficheiros de `05`; cada regra declara o seu `agenda-group` (M4, M5, M7…); M1 não tem
    regras (IN são dados, validados pelo `DetetorDadosEmFalta`).
31. Atributos em falta no modelo para as soluções provisórias (A1.3, A3.18) → acrescentar ao `pericial-model` com ADR,
    sem alterar `docs/04` até pedido explícito.

---

## B. Fases

Convenções transversais a todas as fases: cada regra com metadados `@id @modulo @descricao @condicoes`,
`Decisao( terminal == false )`, nome `"<ID> <descrição>"`; cada teste de regra anotado com `@Regra("PT-003")`.

### Fase 0 — Plano e decisões de arquitetura
**Ficheiros:** `docs/07-plano.md`; `docs/adr/0001-estrutura-modulos.md`, `0002-decisao-por-artigo.md`,
`0003-ambiguidades.md` (lista A, estado "a validar"), `0004-semantica-aplicar-e-terminal.md`.
**Aceitação:** ADR revistos pelo utilizador. **Cenários:** nenhum.

### Fase 1 — Esqueleto Maven
**Ficheiros:** `pom.xml` (pai: Spring Boot 3.5.x BOM, `drools-bom` 8.44.2.Final (última da linha 8), MapStruct, ArchUnit,
Testcontainers; plugins Spotless, Checkstyle, JaCoCo, Surefire/Failsafe, `kie-maven-plugin`), `.gitignore`,
`.editorconfig`, `README.md`, `config/checkstyle.xml`, e `backend/pericial-{model,rules,explanation,dto,persistence,service,api}/pom.xml`
com as dependências de `05` (só numa direção).
**Aceitação:** `mvn clean verify` verde com módulos vazios; Spotless e Checkstyle a correr; Drools 8.44 compila com Java 21.
**Cenários:** nenhum.

### Fase 2 — `pericial-model`
**Ficheiros:** `model/pedido/*` (8 classes), `model/produto/*` (4), `model/decisao/*` (4 + `DecisaoArtigo`),
`model/enums/*` (22 enums); métodos auxiliares (`getDiasDesdeCompra`, `getDiasDesdeEnvio`, `isCompraOnline`,
`estaNoSortido`, `isAutorizado`, `isValido`, `isModificado`, `aplicar`); atributos extra da secção A6.
Testes: `src/test/.../model/*Test.java` + `ArquiteturaModelTest` (sem Spring/JPA) + `PedidoBuilder`
publicado como `test-jar` para reutilizar nos módulos seguintes.
**Aceitação:** POJO conforme `04`; `Boolean` para `revendivel`/`aprovada`; `BigDecimal`/`LocalDate`; `aplicar` regista
`RegistoRegra` e marca `terminal` segundo ADR 0004; cobertura ≥ 90 %. **Cenários:** nenhum.

### Fase 3 — Infraestrutura de regras (`pericial-rules`)
**Ficheiros:** `META-INF/kmodule.xml` (kbase `pericial`, ksession stateful `sessaoPericial` e stateless),
`regras/transversais.drl` (EX-008, PC-008, `auto-focus`, salience 1000), `regras/consultas.drl`;
testes: `MotorTeste` (insere pedido, artigos e `Decisao`; foco M9→M0), `@Regra`, `MetadadosRegrasTest`
(todas as regras têm os 4 metadados e o ID existe em `01`), `CoberturaRegrasTest` (cada regra da kbase tem ≥ 1 teste `@Regra`
— ativo com lista de exclusões que diminui fase a fase), `CenariosEsforcoTest` (parametrizado) e
`cenarios/cenario-01.json … cenario-10.json` só com os dados de entrada e `esperado` vazio, `"estado": "a validar"`.
**Aceitação:** EX-008 e PC-008 testadas (interrompem qualquer módulo). **Cenários:** 6 (suspensão EX-008) e 9 (PC-008), parcial.

### Fase 4 — Regras por módulo (uma subfase por DRL, cada uma com `<Modulo>Test`)
Em cada subfase: escrever as regras de `02`, testes positivos e negativos por ID (incluindo precedências), e
preencher no JSON dos cenários as chaves `esperado` que esse módulo determina, com as regras justificativas.

| Sub | DRL | Regras | Precedências testadas | Cenários (parcial → completo) |
|---|---|---|---|---|
| 4.1 | `m0-autorizacao.drl`, `m2-canal.drl` | HS-006, CT-003, CH-007, CH-008, CH-001 (+ canal desconhecido A1.1) | HS-006 raiz | **5 elegibilidade completa** (CH-008); 1 (CH-001) |
| 4.2 | `m3-elegibilidade.drl` | HS-001..HS-004, PC-001..PC-007 | PC-007 > PC-004/005; HS-003 > PC-006; HS-001→HS-004→CH-007 | **4 completo** (HS-003); 1 (PC-002); 6 (PC-003/PC-004 por artigo); 9 (PC-007) |
| 4.3 | `m4-m5-comprovativo-prazo.drl` | PT-001..PT-008 | PT-007/PT-008 complementares; desvio online | **8 completo** (PT-008); 3 (PT-002/PT-005); 6 (PT-005); 7 (PT-003) |
| 4.4 | `online.drl` | CH-002..CH-006, TN-010, HS-005 | TN-010/HS-005 > CH-006; CH-004 > CH-003 | 2 (CH-002, TN-010, HS-005); 10 (CH-005/CH-004 — A1.4/A1.5) |
| 4.5 | `m6-resultado-excecoes.drl` | EP-001, EP-002, EX-001..EX-006 | EX-006 > EX-004/EX-005 | 1 (EP-001); **2 completo até M6** (EX-003/004/006); 5 (EX-002); 10 (EP-002) |
| 4.6 | `m7-valor.drl` | CH-009, CH-010, EP-003, EP-004 (+ base de valor PT-003/PT-005) | CH-009 vs EP-003 | **3 completo** (CH-009); 1 (valor promocional) |
| 4.7 | `m7-meio-reembolso.drl` | TN-001..TN-009, TN-011, TN-012 (+ numerário/cartão de oferta A2.9) | TN-003 antes de alternativo; TN-004 | **7 completo** (TN-011); 9 (TN-001); 10 (TN-008) |
| 4.8 | `m8-controlos.drl` | CT-001, CT-002, CT-004..CT-007, EX-007 | CT-007 depois de EX-007 | 1, 3 (CT-002), 7 |
| 4.9 | `m9-destino.drl` | CT-008, EP-005..EP-007, BW-001..BW-004 | BW-004 > BW-003 > BW-001 > BW-002; EP-007 > EP-006 | **9 completo** (BW-004); **6 completo**; 1 (EP-005) |
| 4.10 | — | fecho | — | **10/10 completos**: OUT-001..OUT-008 esperados em todos os JSON |

**Aceitação de cada subfase:** cada regra do DRL tem ≥ 1 teste `@Regra`; exclusões do `CoberturaRegrasTest`
removidas para o módulo; `mvn -pl backend/pericial-rules verify` verde; JaCoCo ≥ 85 % em `pericial-rules`.
**Aceitação 4.10:** `CenariosEsforcoTest` verde com os 10 cenários; cada JSON lista `regrasEsperadas` e
`"estado": "a validar"`; nenhuma exclusão no `CoberturaRegrasTest`.

### Fase 5 — Explicações (`pericial-explanation`)
**Ficheiros:** `rastreio/RastreioListener` (AgendaEventListener + RuleRuntimeEventListener), `RastreioExecucao`,
`EventoRegra`; `catalogo/CatalogoRegras` (lido dos metadados da kbase), `MetadadosRegra`, `CondicaoRegra`;
`como/ExplicadorComo`; `porque/ExplicadorPorque`; `porquenao/ExplicadorPorqueNao`, `AvaliadorCondicoes`,
`RegistoPredicados` (cada nome em `@condicoes` → `Predicate<PedidoDevolucao>` em Java; teste garante que
todos os nomes usados nos DRL estão registados); `esenao/SimuladorCenario` (clonagem profunda via Jackson,
sessão stateless, diferença de OUT); `emfalta/DetetorDadosEmFalta` (IN-001..IN-010 por caminho);
`texto/GeradorTexto`; `i18n/explicacoes_pt_PT.properties`, `explicacoes_en.properties`.
**Aceitação:** "Porque não" distingue as três causas (módulo não alcançado / cancelada por precedência /
condições falhadas) — testado com cenário 4 (PC-006 cancelada por HS-003) e cenário 5 (HS-002 módulo não alcançado);
"E se" no cenário 10 (portal disponível) e cenário 8 (recibo original = sim → PT-007); "O que falta" no cenário 3.
**Cenários:** 3, 4, 5, 8, 10 (explicações).

> **Revisão de 2026-10-05 (ADR 0006):** as explicações seguem as definições do utilizador — Como (caminho até uma conclusão), Porque não (razão de uma conclusão não ter sido obtida, com `@conclusoes` nas regras) e Porquê (razão de uma pergunta ao colaborador). Os endpoints de `docs/05` foram atualizados.

### Fase 6 — Persistência (`pericial-persistence`)
**Ficheiros:** `entidade/AvaliacaoEntity` (pedido e decisão em JSONB, versão do kjar `groupId:artifactId:version`),
`RegistoRegraEntity`, `ExcecaoAprovadaEntity`; `repositorio/*`; `db/migration/V1__esquema_inicial.sql`.
**Aceitação:** teste Testcontainers PostgreSQL: Flyway aplica, grava e lê avaliação com rasto. **Cenários:** nenhum.

### Fase 7 — DTO e serviço (`pericial-dto`, `pericial-service`)
**Ficheiros:** DTO de `05` como `record` com Bean Validation; `motor/MotorRegrasConfig`, `MotorRegrasService`,
`SessaoFactory`, `OrdemModulos`; `avaliacao/AvaliacaoService`, `ValidadorPedido`; `explicacao/ExplicacaoService`;
`simulacao/SimulacaoService`; `regra/CatalogoRegrasService`; `auditoria/AuditoriaService`;
`mapeamento/PedidoMapper`, `DecisaoMapper`, `ExplicacaoMapper` (MapStruct); `integracao/porta/{PosGateway,
BackPocketGateway, CatalogoProdutoGateway, PagamentoGateway}` + `adaptador/simulado/*` (perfis dev/test);
`excecao/*`.
**Aceitação:** os 10 cenários passam pelo `AvaliacaoService` (DTO → modelo → regras → DTO) com o mesmo resultado
de `CenariosEsforcoTest`; cada avaliação persiste versão do kjar e rasto. **Cenários:** 1–10 (camada de serviço).

### Fase 8 — API (`pericial-api`)
**Ficheiros:** `PericialApplication`; `controller/{Avaliacao,Explicacao,Simulacao,Regra}Controller` com os endpoints
de `05`; `config/{Security,OpenApi,Cors,Jackson}Config`; `seguranca/ConversorJwtPapeis` (papéis do enum `Funcao`;
`Colaborador` construído a partir do token — A4.24); `erro/GlobalExceptionHandler` (ProblemDetail);
`observabilidade/CorrelationIdFilter`; `application{,-dev,-prod}.yml`, `logback-spring.xml`; `Dockerfile`;
`docker-compose.yml` (PostgreSQL + API); testes MockMvc por controller, `ArquiteturaTest` (ArchUnit: controllers só
DTO, sem `model`/`org.kie`; model sem Spring), `CenariosApiIT` (Testcontainers, 10 cenários via HTTP);
`openapi.json` exportado no build para o frontend.
**Aceitação:** `mvn clean verify` verde na raiz; Swagger UI em dev; `docker compose up` arranca API + BD.
**Cenários:** 1–10 (via REST).

### Fase 9 — Frontend Angular
**Ficheiros:** `frontend/` (Angular atual, standalone + signals), `angular.json`, `package.json`, `proxy.conf.json`,
`Dockerfile`, `nginx.conf`; `src/app/api/` gerado com `openapi-generator` (typescript-angular) a partir de
`openapi.json`; `core/` (auth OIDC, interceptor de correlação, guards); `shared/` (cartão com cores do fluxograma,
pipes); `features/avaliacao/` (assistente: transacao, produto, comprovativo, pagamento, excecao; `avaliacao.store.ts`
com signals; chama `dados-em-falta` a cada passo); `features/resultado/` (OUT-001..OUT-008 e resultado por artigo);
`features/explicacoes/` (Como, Porquê, Porque não, E se); `features/historico/`; `features/regras/`;
`locale/messages.pt-PT.xlf`, `messages.en.xlf`; `e2e/cenario-01.spec.ts … cenario-10.spec.ts` (Playwright,
reutilizam os JSON de `pericial-rules`); `docker-compose.yml` passa a incluir o frontend.
**Aceitação:** `npm test` e `npx playwright test` verdes; cliente regenerado sem diferenças no CI; i18n pt-PT/en.
**Cenários:** 1–10 (E2E).

### Fase 10 — CI e fecho
**Ficheiros:** `.github/workflows/ci.yml` (mvn verify, npm test, Playwright, imagens Docker), atualização de `README.md`.
**Aceitação:** Definição de concluído (README) cumprida; lista de ambiguidades atualizada com o que a operação confirmou.

---

## C. Decisões tomadas com o utilizador
1. **Multi-artigo → `DecisaoArtigo`.** Novo facto por artigo (`artigoId`, `elegibilidade`, `tipoTransacao`,
   `valorDevolucao`, `baseValor`, `destino`, `terminal`, `registos`). Regras de HS/PC/BW/EP-005..007/CT-008 atuam
   sobre `DecisaoArtigo( terminal == false )`; regras de pedido (HS-006, CH-007/008, PT, ONLINE, TN, CT, EX)
   atuam sobre `Decisao`. A `Decisao` agrega: elegibilidade global = a mais severa entre artigos
   (provisório, "a validar"). ADR `0002-decisao-por-artigo.md`; `docs/04` fica inalterado até pedido.
2. **Ambiguidades [P] → comportamento provisório "a validar"**, sem bloquear as fases: marcado no `@descricao`
   da regra, no `@DisplayName` do teste e no JSON do cenário, e listado em `docs/adr/0003-ambiguidades.md`
   com a pergunta exata para a operação.

## Verificação
- Por fase: `mvn clean verify` na raiz (Spotless, Checkstyle, ArchUnit, JaCoCo incluídos).
- Regras: `mvn -pl backend/pericial-rules verify` → `<Modulo>Test`, `CoberturaRegrasTest`, `CenariosEsforcoTest`.
- Ponta a ponta: `docker compose up`, Swagger UI em dev, `cd frontend && npm ci && npm test && npx playwright test`.

## D. Estado e fecho (2026-10-06)

Todas as fases foram implementadas, verificadas e aprovadas uma a uma pelo utilizador.

| Fase | Commit | Notas |
|---|---|---|
| 0 Plano e ADR | `f1c38bd` | ADR 0001–0004 |
| 1 Esqueleto Maven | `e174f31` | |
| 2 `pericial-model` | `58b19d8` | `DecisaoArtigo` (ADR 0002) |
| 3 Infraestrutura de regras | `56fd000` | |
| 4.1–4.10 Regras por módulo | `8b86268` … `72c74b7` | 10 cenários completos |
| 5 Explicações | `7a8f45a`, `9014b26` | definições do utilizador (ADR 0006) |
| 6 Persistência | `59c6ad4` | PostgreSQL + Flyway, auditoria |
| 7 DTO e serviço | `a8d440f` | ADR 0007 |
| 8 API | `a379f8f` | ADR 0008 |
| 9 Frontend | `4323477` | ADR 0009 |
| 10 CI e fecho | este commit | `.github/workflows/ci.yml` |

Desvios ao plano, todos registados em ADR:
- o serviço usa o executor do módulo de explicações em vez de `SessaoFactory`/`OrdemModulos` (ADR 0007);
- o cliente do frontend é gerado com `ng-openapi-gen` em vez do `openapi-generator` (ADR 0009);
- os E2E estão em `e2e/cenarios.spec.ts` (um teste por cenário) e `e2e/explicacoes.spec.ts`;
- a ligação a um fornecedor OIDC de produção ficou fora do âmbito (decisão do utilizador).

### Definição de concluído (README)

| Critério | Verificação |
|---|---|
| Cada regra tem pelo menos um teste unitário que referencia o ID | 98 regras DRL de 76 IDs; os 76 IDs têm testes `@Regra`; o `CoberturaRegrasTest` falha se uma regra da kbase não tiver teste |
| Os 10 cenários de `docs/06` como testes de aceitação em JSON | `pericial-rules/src/test/resources/cenarios/cenario-01..10.json`, todos `"a validar"`; corridos pelas regras (`CenariosEsforcoTest`), pelo serviço (`ServicoPericialIT`), pela API (`CenariosApiIT`) e pela interface (Playwright) |
| Build e testes verdes; sem violações de ArchUnit, Checkstyle ou Spotless | `mvn clean verify` e o frontend (`npm run verificar`, `npm test`, `npm run build`, Playwright) verdes; o CI repete tudo em cada push |

### Por fazer (fora do âmbito desta implementação)

- Respostas da operação às ambiguidades A-01 a A-31 (ADR 0003): todas continuam "a validar".
- Adaptadores reais das integrações (POS, BackPocket, Afterpay, PayPal/Venmo, Interac/VeriFone): hoje há só o
  adaptador simulado (ADR 0007).
- Fornecedor OIDC de produção e a correspondência dos seus grupos com as funções (ADR 0008).
- Explicar avaliações feitas com uma versão anterior da base de conhecimento (hoje recusado com 409, ADR 0007).
- Textos da base de conhecimento (nomes e mensagens das regras, perguntas) em inglês (ADR 0009).

## E. Fase 11 — Camada de tratamento da incerteza (`docs/08-incerteza.md`)

Começa depois da Fase 10: precisa do `pericial-model` (com `Decisao.aplicar()` e `DecisaoArtigo`), das regras M3 e M5
e do `RastreioListener`, que já existem. Todos os parâmetros numéricos são **demonstrativos**, ficam só no ficheiro de
parâmetros e nos ficheiros FCL, e a camada nunca transforma um RECUSAR num PERMITIR. Decisões em ADR 0011
(metodologia bayesiana, em análise) e ADR 0012 (camada de incerteza).

### E1. Decisões do utilizador (2026-10-15)
1. **Revendibilidade só recomenda.** REVENDIVEL e INDETERMINADA ficam como `GrauCrenca`; `revendivel` continua `null`
   e PC-002/PC-003 ficam em REVER (a gestão decide). NAO_REVENDIVEL fixa `revendivel = FALSE`. Desvio ao `docs/08`
   §4.1 e §8 (cenário 1 não passa a `revendivel = TRUE`).
2. **Aprovação RESPONSAVEL_SENIOR** nas regras IU-12 e IU-21, sem acrescentar `GESTAO_LOJA` a `NivelAprovacao`:
   o OUT-005 de `01` prevalece (como a A-19).
3. **Motor fuzzy jFuzzyLogic**, fora do Maven Central: jar do SourceForge (LGPL-3.0) num repositório Maven dentro do
   projeto (`backend/repo-local/`), atrás da interface `MotorFuzzy`.
4. **O cálculo de um grau explica-se no "Como?"** (`conclusao=INCERTEZA.<HIPOTESE>`), coerente com a ADR 0006.
   "Porque não?" e "E se?" seguem o `docs/08`.

### E2. Decisões técnicas
1. IU-20 a IU-23 (Bayes) correm no agenda-group **M3**, entre as HS-001..004 e a PC-004/PC-005: o §3.2 exige a porta
   G2, e as HS estão no M3.
2. EF-05 e EF-06 derivam dos factos (comprovativo ausente ou válido), não do disparo de PT-001/PT-002 (M4 corre
   depois de EVIDENCIA).
3. IU-50 atua sobre cada `DecisaoArtigo` (M8); a agregação OUT-001 (M9) propaga o resultado.
4. As respostas de inspeção ficam no modelo (`EstadoProduto.inspecaoDefeito`, `Cliente.explicaOrigemCompra`,
   `pedeNumerario`); as `Evidencia` são criadas por uma `FabricaEvidencias`, chamada pelo `ExecutorSessao`.
5. Cenário 6: o indício manual (A-27) é substituído por `explicaOrigemCompra = NAO`, `pedeNumerario = true` e
   `grauUso` 0/1/2; CF = 0,8354 e a IU-11 insere o `IndicadorFraude`.
6. `grauUso` é independente de `condicaoUso`; A-17 (PT-004 "baixo risco") mantém-se.
7. Regressão verificada: cenários 2, 5, 7, 8, 9 e 10 em RISCO_BAIXO, sem `grauUso` nem `alegaDefeito`.

### E3. Passos

| Passo | Ficheiros | Aceitação e testes |
|---|---|---|
| **11a Modelo** | `model/incerteza/{Evidencia, GrauCrenca, Contribuicao}`; enums `Hipotese`, `MetodoIncerteza`, `FonteEvidencia`, `ClassificacaoIncerteza`; `Modulo` + `EVIDENCIA`, `INCERTEZA` (entre M2 e M3); `EstadoProduto`, `Cliente`, `Decisao` (§5.1, E2.4); `docs/04` | `ArquiteturaModelTest` verde; `getIntegridadeEtiquetas()` = 1,0 / 0,6 / 0,0 |
| **11b `pericial-uncertainty`** | `CombinadorFatoresCerteza`, `ModeloBayesiano`/`ModeloRazoesVerosimilhanca`, `MotorFuzzy`/`MotorFuzzyFcl`, `ParametrosIncerteza`/`CarregadorParametros`, `FabricaEvidencias`, `ServicoIncerteza`; `parametros-incerteza.yml`; `fcl/revendibilidade.fcl`, `fcl/credito-pt004.fcl`; `backend/repo-local/` | Testes primeiro. CF: 0,8354 (cenário 6), −0,4286, 0 sem evidências, comutatividade. Bayes: A 0,8955, B 0,3000, C 0,7742, regra de grupo. Fuzzy (±0,02): 0,844, 0,500, 0,325, 0,675; crédito (±2): 84,4, 50,0, 32,3, 15,6, 50,0, com regras ativas e forças. Parâmetros inválidos rejeitados. Nenhum valor demonstrativo em `.java`/`.drl`. JaCoCo ≥ 90 % |
| **11c Regras** | `evidencia.drl` (IU-01..03, 05..07), `incerteza.drl` (IU-10..12, IU-30..33); IU-20..23 no M3, IU-40 no M5, IU-50 no M8; guarda na PC-004/PC-005 (§3.4) | `@Regra` por IU. Cenário 6: 0,8354 RISCO_ALTO, EX-008; não enviesamento (`agitado`/`contestaResultado`); cenário 3: 0,30 RISCO_BAIXO; cenário 4: sem `GrauCrenca` DEFEITO_FABRICO; variante sem bainha: 0,8955 PROPOR_PC006, final REVER; com defeito confirmado: PC-006; caso B: DESGASTE e PC-004; cenário 1: 0,844 REVENDIVEL, resultado REVER (E1.1); PT-004 casos A–E; HS mantêm RECUSAR; regressão 2, 5, 7, 8, 9, 10 |
| **11d Explicações** | "Como?" `INCERTEZA.*`; "Porque não?" `INCERTEZA.*:<CLASSE>`; "E se?" com `grauUso`, `alegaDefeito`, `inspecaoDefeito`, `explicaOrigemCompra`; "O que falta?" sugere `grauUso` e perguntas ED; textos pt_PT/en com o aviso demonstrativo | Textos do §7.2 (cenário 6, caso C 0,77 < 0,80, revendibilidade 0,33 com RV3 0,5 e RV5 0,5); um CF nunca é apresentado como probabilidade |
| **11e DTO, serviço e API** | `EstadoProdutoRequest`, `ClienteRequest`, `GrauCrencaDto`, `ContribuicaoDto`, `DecisaoResponse.incerteza`; `GET /api/v1/incerteza/parametros`; Flyway `V2` (versão dos parâmetros) | `CenariosApiIT` com os cenários 1, 3, 4 e 6; ArchUnit; `mvn clean verify` verde; OpenAPI atualizado no frontend |
| **11f Frontend** | Perguntas de inspeção (grau de uso, alega defeito, ED-01/02/05/06/07) e do cliente; cartão "Avaliação da incerteza"; faixa "Valores demonstrativos — não usar para decisões reais" | Teste de cobertura do formulário, Vitest do cartão e da faixa, i18n pt-PT/en, E2E do cenário 6 e do caso A |

### E4. Verificação
`mvn clean verify` (8 módulos), `npm run verificar && npm test && npm run build && npx playwright test`,
`docker compose up --build` com o cenário 6 na interface, e o CI verde.

### E5. Estado (2026-10-16)
Fase 11 concluída: 11a e 11b em `b8b167d`, 11c em `08ad826`, 11d em `c291037`, 11e em `49f7214` e 11f em
`0b4cd90`. `mvn clean install` verde nos 8 módulos (Spotless, Checkstyle, ArchUnit, JaCoCo, Testcontainers); frontend
com `npm run verificar`, 35 testes Vitest, `npm run build` e 17 testes Playwright verdes contra a API construída pelo
`docker compose --build`. Os valores da camada continuam demonstrativos e as decisões E1 e A-32 a A-34 "a validar".
