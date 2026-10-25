# ADR 0003 — Ambiguidades da base de conhecimento e comportamento provisório

- **Estado:** aceite como provisório (2026-10-04); cada linha fica **a validar** pela operação
- **Data:** 2026-10-04

## Contexto

As convenções do projeto (README) proíbem inventar regras de negócio. A base de conhecimento (`01`) e a sua reescrita (`02`) são
omissas ou contraditórias em vários pontos. O utilizador decidiu (2026-10-04) que estes pontos não bloqueiam a
implementação: implementa-se o comportamento hoje documentado (sobretudo em `03`), marcado "a validar".

## Decisão

Cada ponto abaixo:
- tem a regra DRL com `@descricao` terminada em `[a validar: A-xx]`;
- tem o teste com `@DisplayName` que inclui `a validar A-xx`;
- aparece no JSON do cenário afetado em `"aValidar": ["A-xx"]`.

Quando a operação responder, atualiza-se a coluna **Resposta**, a regra, o teste e o cenário, e retira-se a marca.

| ID | Tema | Regras | Pergunta para a operação | Comportamento provisório | Cenários | Resposta |
|---|---|---|---|---|---|---|
| A-01 | Canal "desconhecido" | IN-003, CH-001, EP-005..007 | Como se trata um artigo de canal desconhecido? Se o comprovativo revelar o canal, usa-se esse canal? | Segue para M3; sem comprovativo → às cegas (PT-002/PT-005); com comprovativo → caminho de loja; `entreCanais` vem do input (`03`, M2) | — | |
| A-02 | Canal BackPocket | CH-002, TN-012 | Uma compra BackPocket segue o caminho online ou o de loja? | Caminho de loja (M4/M5); só levi.com/levi.ca vão para ONLINE (`03`, M4) | — | |
| A-03 | Às cegas online permitida | CH-003 | Que cenários da política permitem uma devolução online às cegas? | Input `politicaPermiteAsCegasOnline`; por omissão `false` → RECUSAR | — | |
| A-04 | Encomenda encontrada com portal em baixo | CH-002, CH-004 | Encomenda online encontrada mas o portal (BackPocket) está indisponível: o que fazer? | Nenhum documento cobre o caso → REVER (critério da gestão, EX-001), sem meio de reembolso definido | 10 | |
| A-05 | Troca online tardia com PayPal | CH-005, CH-006, TN-008, EX-006 | Troca online após 30 dias paga com PayPal: cartão de oferta (CH-005) ou fluxo da app (TN-008)? E se o cliente não acede à app? | TN-008 prevalece (EX-006 proíbe substituir o meio); sem acesso à app → REVER, sem meio alternativo | 10 | |
| A-06 | Online verificado após 30 dias | CH-005, PT-004 | O online tardio é REVER (PT-004) ou cartão de oferta direto (CH-005)? | CH-005 (cartão de oferta, PERMITIR); online não passa por PT-003/PT-004 (`03`). Uma troca online tardia também recebe cartão de oferta (CH-005 é avaliada antes da troca em `03`) | 10 | |
| A-07 | Produto de franquia nos EUA | CH-007, HS-004 | CH-007 aplica-se em qualquer mercado? | Sim (`01` não exige Canadá e prevalece sobre `02`) | — | |
| A-08 | Grossista: CH-008 vs HS-002 | CH-008, HS-002 | Qual o ID a reportar? | O primeiro a disparar (CH-008 em M2); HS-002 aparece como "módulo não alcançado" | 5 | |
| A-09 | Numerário e cartão de oferta | PT-003, TN-* | Compras pagas em numerário ou cartão de oferta: reembolso no meio original? Há limite de numerário? Cartão novo ou recarregado? | `MEIO_ORIGINAL` (`03`, M7) | — | |
| A-10 | Interac de substituição | TN-002, TN-011 | Cartão Interac de substituição da mesma conta é aceite? Sem o cartão, há alternativa? | TN-011 prevalece: sem o mesmo cartão físico não se processa o reembolso Interac → REVER, sem meio definido | 7 | |
| A-11 | Interac como débito | TN-004 | A proibição de numerário de TN-004 aplica-se ao Interac? | Não (Interac é um meio distinto) | 7 | |
| A-12 | Escolha em TN-007 | TN-007 | Quem escolhe entre reembolso ao comprador e crédito de loja? | O sistema devolve as duas opções; a escolha é o input `resolucaoPedida` | — | |
| A-13 | Oferta sem recibo | TN-007, PT-005 | Uma devolução de oferta sem recibo é uma devolução às cegas normal? | Sim: PT-005 (troca ou crédito de loja ao preço atual) | 3 | |
| A-14 | Ajuste de preço | PT-007, PT-008 | Meio da diferença? Ajuste de compras online? Preço anunciado online conta? Fotografia do recibo é "recibo original"? | Meio original; compra fora da loja (online, BackPocket) → RECUSAR com PT-008 se faltar prazo/recibo, caso contrário REVER; fotografia ≠ original; ajuste já aplicado → recusar (PT-007 diz "único"); "artigo idêntico" = o próprio artigo da compra; num ajuste o artigo não é entregue, por isso não tem destino (M9) | 8 | |
| A-15 | PC-008 fora do bodywear | PC-008 | Um artigo sujo/inseguro que não é bodywear é aceite? Uma mancha é "sujo" ou "danificado"? | PC-008 não altera a elegibilidade; destino `RISCO_BIOLOGICO`; a classificação é do colaborador (input) | 6 | |
| A-16 | Prazo às cegas | PT-005 | As devoluções às cegas têm prazo? | Sem prazo; `dataCompra` pode ser nula quando não há comprovativo | 3, 6 | |
| A-17 | "Baixo risco" em PT-004 | PT-004 | Como se mede o baixo risco? | Nenhum `IndicadorFraude` com nível SIGNIFICATIVO ou CONFIRMADO | — | |
| A-18 | Aprovação PC-004 e EX-004 | PC-004, EX-004 | Onde se regista a aprovação da gestão e o "concluível no sistema"? | PC-004 usa `PedidoExcecao.aprovada`; EX-004 usa o novo input `concluivelNoSistema` | 2 | |
| A-19 | Nível de aprovação da gestão | PC-002..004, PT-004 | Que nível de aprovação exigem estes REVER? (`NivelAprovacao` não tem "Gestão da Loja") | `RESPONSAVEL_SENIOR` | 1, 6 | |
| A-20 | Conjunto de bodywear incompleto | PC-007, BW-003 | O reembolso é do conjunto ou proporcional? | `precoPago` do artigo, tal como registado | 9 | |
| A-21 | CH-010 e CH-009 com EP-003 | CH-009, CH-010, EP-003 | Como se sabe que o POS permite o PVP original? Como se combinam CH-009 e EP-003? | Valor do adaptador POS (`valorCalculadoPos`); CH-009 define a base, EP-003 o escalão | 3 | |
| A-22 | Contagem de dias | PT-003, PT-004, CH-005 | "Dentro de 30 dias" inclui o dia 30? Online conta da data de envio? | `≤ 30`; online usa `dataEnvio`, loja usa `dataCompra` | 1, 10 | |
| A-23 | XStore Manager em HS-006 | HS-006 | O XStore Manager é processador autorizado? | Sim | — | |
| A-24 | Identidade do colaborador | HS-006, CT-001, CT-003 | — (decisão técnica de segurança) | O `Colaborador` vem sempre do token JWT, nunca do corpo do pedido | — | n/a |
| A-25 | Agregação multi-artigo | — | Um pedido com artigos aceites e recusados processa-se em parte? | Ver ADR 0002: elegibilidade do pedido = a mais severa | 6 | |
| A-26 | Que indícios suspendem | EX-008, PT-004 | Qualquer indício de fraude suspende a transação, ou só os relevantes? | Só SIGNIFICATIVO ou CONFIRMADO suspendem; um indício BAIXO não suspende e conta para o "baixo risco" de PT-004 | 6 | |
| A-27 | Comportamento do cliente como indício | EX-008, IU-01..IU-11 | Não saber explicar onde e quando comprou os artigos (cenário 6) é um indício de fraude? | Desde a Fase 11 (`docs/08`, ADR 0012): é a evidência EF-04 (`explicaOrigemCompra = NAO`, CF demonstrativo), combinada com as outras por fatores de certeza; no cenário 6 o CF chega a 0,8354 e a IU-11 regista o indício SIGNIFICATIVO → EX-008. O nervosismo e a contestação nunca são evidência | 6 | |
| A-29 | Usado com dano sem defeito confirmado | PC-004, PC-006 | PC-004 exclui "dano ou defeito confirmado" e nenhuma regra cobre um artigo usado com dano mas sem defeito de fabrico confirmado. Que regra se aplica? | PC-004 (o defeito não está confirmado); sem decisão da gestão fica REVER | — | |
| A-30 | Promoção por escalões numa devolução às cegas | EP-003 | EP-003 refere-se a uma promoção por escalões ativa, mas sem comprovativo não se conhece a compra. Como se sabe que se aplica? | Usa-se o indicador `promocaoEscaloes` da compra original (registado pelo colaborador); o valor do escalão vem do POS | — | |
| A-28 | Artigo inseguro em transação recusada ou suspensa | PC-008, M9 | Um artigo sujo/inseguro numa transação recusada ou suspensa é isolado ou devolvido ao cliente? | É isolado (PC-008 é independente da elegibilidade, `02`); destino `RISCO_BIOLOGICO` prevalece sobre `DEVOLUCAO_CLIENTE` | 6, 9 | |
| A-31 | Acesso ao histórico de avaliações | — (acesso, não regra) | Que funções podem consultar o histórico de avaliações da loja? | GESTAO_LOJA, XSTORE_MANAGER e KEY_HOLDER (ADR 0008); as restantes funções avaliam e consultam uma avaliação pelo seu identificador | — | |
| A-32 | Revendibilidade calculada (fuzzy) | IN-010, PC-002, PC-003, IU-30..IU-33 | O grau de revendibilidade calculado pode decidir sozinho o IN-010 (e passar PC-002/PC-003 de REVER a PERMITIR)? | Não: REVENDIVEL e INDETERMINADA são só recomendação e `revendivel` fica por decidir pela gestão; NAO_REVENDIVEL fixa `revendivel = FALSE` (mais cauteloso). Desvio ao `docs/08` §4.1 (ADR 0012) | 1 | |
| A-33 | Momento do cálculo de defeito (Bayes) | IU-20..IU-23, HS-001..HS-004, PC-004..PC-006 | O cálculo de defeito de fabrico corre depois das paragens HS, como exige o `docs/08` §3.2? | Sim: IU-20..IU-23 correm no M3, depois das HS e antes da PC-004/PC-005 (o `docs/08` §5.3 punha-as antes do M3) | 4 | |
| A-34 | Aprovação exigida pela incerteza | IU-12, IU-21, OUT-005 | O risco médio e a proposta de PC-006 exigem aprovação de que nível? (`docs/08` pede "Gestão da Loja", que o OUT-005 não tem) | `RESPONSAVEL_SENIOR`, como na A-19 | — | |

## Ponto de situação (2026-10-06, fim da implementação inicial)

- Nenhuma resposta da operação até esta data: todas as linhas continuam **a validar** (A-24 é uma decisão técnica).
- Os 10 cenários de `docs/06` mantêm `"estado": "a validar"`; cada um lista em `aValidar` as linhas de que depende.
- A decisão mostra as regras com comportamento provisório (`regrasAValidar`), e a interface assinala-as ("a validar"),
  para que a operação as veja ao usar o sistema.
- Para cada resposta: atualizar a coluna **Resposta**, a regra DRL (`@descricao`), o teste, o JSON dos cenários
  afetados e retirar a marca; o CI (`.github/workflows/ci.yml`) confirma regras, serviço, API e interface.

## Consequências

- Os resultados esperados dos cenários afetados mudam quando a operação responder; os testes estão marcados para facilitar a revisão.
- Novos inputs no modelo (`politicaPermiteAsCegasOnline`, `concluivelNoSistema`, `valorCalculadoPos`, `acessoAplicacaoPagamento`) são
  acrescentados ao `pericial-model` e documentados aqui, sem alterar `docs/04` até pedido explícito.
