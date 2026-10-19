# Sistema pericial de devoluções e trocas Levi's — motor SWI-Prolog

Réplica em SWI-Prolog do sistema pericial `drools-engine-levis-devolucoes-java`. Decide devoluções,
trocas e ajustes de preço nas lojas Levi's Mainline e Outlet (EUA e Canadá) e explica cada decisão.
A base de conhecimento é a do Relatório Prévio de Aquisição de Conhecimento (71 regras em nove
famílias) e o comportamento é o da implementação Drools: as mesmas 98 regras (variantes e regras de
suporte), a decisão por artigo e as 31 ambiguidades com comportamento provisório (ADR 0002–0004).

| | Drools (Java) | Prolog |
|---|---|---|
| Regras | 98 regras DRL, 76 IDs | 98 regras, 76 IDs (`src/bc/regras.pl`) |
| Motor | Drools 10 (Phreak), agenda-groups e salience | motor de encadeamento progressivo próprio (`src/motor/motor.pl`) |
| Explicações | Como, Porquê, Porque não, E se, O que falta | as mesmas (`src/explicacoes/explicacoes.pl`) |
| Interface | API Spring + JWT + PostgreSQL, frontend Angular | interface web (servida pelo próprio servidor Prolog), API REST com os mesmos caminhos e formatos, e consola interativa |
| Testes | 10 cenários + testes por regra | os mesmos 10 cenários (JSON copiados) + os testes por regra e das explicações portados |

## Requisitos

- SWI-Prolog 9 ou superior (testado com 10.0.2 em Windows). Não há outras dependências.

## Como usar

### Interface web (sem terminal)

Duplo clique em **`iniciar.bat`**. Abre uma janela com o servidor e o browser em
`http://localhost:8090/`. Para parar, fecha-se essa janela. O ficheiro usa o `swipl` do PATH ou, se
não estiver lá, o de `C:\Program Files\swipl\bin`.

Na página:

- **Pedido.** Preenche-se por grupos de perguntas (colaborador, loja, compra, comprovativo,
  pagamento, artigos, cliente, exceção, indícios de fraude). Também se pode carregar um dos 10
  cenários de teste ou colar um pedido em JSON.
- **Porquê?** Cada grupo, e os campos com o seu próprio dado, tem um botão que explica porque é que o
  sistema pergunta isso, dado o que já foi preenchido.
- **O que falta?** Atualiza-se a cada alteração: assinala os dados obrigatórios em falta e os que
  decidem uma revisão (ex.: IN-010).
- **Decisão.** Depois de **Avaliar pedido**, mostra OUT-001 a OUT-008, o resultado por artigo e as
  regras com comportamento provisório. Cada conclusão tem **Como?** e **Porque não…?**.
- **Explicações.** O separador **Como?** mostra o caminho completo, regra a regra. **Porque não?**
  aceita uma conclusão ou uma regra. **E se?** reavalia o pedido com alterações.
- **Outros separadores.** **Histórico** lista as avaliações feitas desde que o servidor arrancou.
  **Regras** mostra o catálogo com as variantes, as condições e as conclusões.

A página usa só HTML, CSS e JavaScript (pasta `web/`), sem dependências nem acesso à internet.

### Linha de comandos

```bash
swipl testes/executar.pl
```

```bash
swipl main.pl web
```

```bash
swipl main.pl consola
```

```bash
swipl main.pl avaliar testes/cenarios/cenario-01.json
```

- `swipl testes/executar.pl` corre todos os testes (código de saída 0 se passarem). Os comandos
  `swipl` correm-se na pasta `prolog-engine-levis-devolucoes`. Se o `swipl` não estiver no PATH,
  usa-se `"C:\Program Files\swipl\bin\swipl.exe"`.
- `swipl main.pl web` inicia o servidor e abre a interface no browser. `swipl main.pl` inicia o
  servidor sem abrir o browser. Em ambos os casos a interface fica em `http://localhost:8090/` e a
  API REST em `/api/v1`, e a porta vem da variável `PORT`.
- `swipl main.pl consola` abre a consulta interativa: o sistema faz as perguntas e, em qualquer uma,
  `porque` (ou `?`) explica porque a faz.
- `swipl main.pl avaliar F.json` avalia um pedido em JSON e abre o menu de explicações.

No interpretador: `swipl carregar.pl` e depois `?- consulta.`, `?- avaliar_ficheiro('...').` ou
`?- iniciar_servidor(8090).`.

## Estrutura

```text
prolog-engine-levis-devolucoes/
├── iniciar.bat                  # duplo clique: inicia o servidor e abre a interface web
├── main.pl                      # ponto de entrada (web, API, consola, avaliar ficheiro)
├── carregar.pl                  # carrega tudo no interpretador
├── web/                         # interface web, Swagger UI e especificação OpenAPI (openapi.json)
├── ferramentas/gerar_openapi.py # gera web/openapi.json
├── src/
│   ├── motor/
│   │   ├── operadores.pl        # regra, se, entao, e, nao (sp_exp2.pl) e com (metadados)
│   │   ├── motor.pl             # motor de inferência: agenda, prioridades, refração, ações
│   │   └── memoria.pl           # memória de trabalho: pedido, decisões, registos, rasto
│   ├── bc/                      # base de conhecimento (separada do motor)
│   │   ├── regras.pl            # as 98 regras
│   │   ├── condicoes.pl         # vocabulário das condições (com descrições e dados que leem)
│   │   └── pedido.pl            # modelo do pedido: normalização do JSON e acesso aos factos
│   ├── explicacoes/explicacoes.pl   # Como, Porquê, Porque não, E se, O que falta
│   ├── servico.pl               # preparar o pedido, avaliar e montar a decisão (DecisaoResponse)
│   ├── interface/consola.pl     # modo interativo
│   └── api/servidor.pl          # API REST e ficheiros da interface web
└── testes/
    ├── cenarios/                # os 10 cenários de docs/06 (cópia dos JSON do projeto Drools)
    ├── executar.pl              # corre todos os testes
    └── testes_*.pl              # PLUnit
```

## A linguagem das regras

As regras usam os operadores do `sp_exp2.pl` (material de apoio da UC): `regra`, `se`, `entao`, `e` e
`nao`. Acrescenta-se `com`, que junta os metadados (o equivalente às anotações do DRL):

```prolog
regra 'PC-002 Etiquetas soltas: rever a possibilidade de revenda'
    se [ artigo(A) e pedidoAtivo e artigoAtivo(A) e naoDisparou(artigo(A), 'PC-002')
         e naoUsado(A) e etiquetasSoltas(A) e semDefeito(A) e naoBodywear(A) e revendivelPorAvaliar(A) ]
    entao [ definir(artigo(A), aprovacao, responsavel_senior),
            aplicar(artigo(A), rever, "Etiquetas soltas: a gestão aprova só se ...") ]
    com [ modulo(m3), prioridade(50),
          conclusoes(['OUT-001'=rever, 'OUT-005'=responsavel_senior]),
          descricao("Não usado com etiquetas soltas: rever ... [a validar: A-19].") ].
```

- **Nome e ID.** O nome é o da regra DRL e começa pelo ID da base de conhecimento. Um ID pode ter
  várias variantes (ex.: PC-002 rever / aprovado / recusado).
- **Condições.** As condições são predicados de `src/bc/condicoes.pl`, com os nomes do metadado
  `@condicoes` do Drools. Assim o rasto e as explicações dos dois motores usam o mesmo vocabulário.
  As regras por artigo começam por `artigo(A)`, que percorre os artigos do pedido.
- **Ações:**
  - `aplicar(Alvo, Resultado, Mensagem)` nunca baixa a severidade (RECUSAR > ENCAMINHAR > REVER >
    PERMITIR); as paragens obrigatórias (HS-001..004, HS-006, CH-007, CH-008) terminam o fluxo.
  - `registar`, `definir`, `suspender` (EX-008), `recusar_excecao` (HS-005, EX-004, EX-005, EX-006)
    e `agregar_artigos` (OUT-001) têm a mesma semântica que os métodos de `DecisaoBase`/`Decisao`
    (ADR 0004).
  - `calcular(Objetivo)` calcula os valores usados nas mensagens.

### Correspondência com o DRL

| DRL (Drools) | Prolog |
|---|---|
| `agenda-group "M3"` | `modulo(m3)` |
| `salience 50` | `prioridade(50)` |
| `auto-focus true` | `auto_foco` |
| `Decisao( terminal == false )` | condição `pedidoAtivo` (`artigoAtivo(A)` para `DecisaoArtigo`) |
| `disparou( "ID" ) == false` | condição `naoDisparou(Alvo, 'ID')` |
| `exists` / `not` / `collect` sobre artigos | condições do estado (ex.: `artigoElegivel`, `artigoRevendivel`) |
| `modify( $d ) { setX(..), aplicar(..) }` | `definir(pedido, x, ..)`, `aplicar(pedido, ..)` |
| `function` do DRL | predicados no fim de `regras.pl` (ex.: `valor_da_base/3`) |
| `@conclusoes`, `@descricao` | `conclusoes([...])`, `descricao("...")` |

## O motor de inferência

O motor (`src/motor/motor.pl`) faz encadeamento progressivo e reproduz a forma como o
`ExecutorSessao` do projeto Java usa o Drools:

1. **Agenda-groups.** Os grupos são avaliados por esta ordem: TRANSVERSAL, M0, M1, M2, M3, M4, M5,
   ONLINE, M6, M7, M8, M9. É a ordem do `OrdemAgenda`. Cada grupo corre até não ter ativações e não
   volta a ser avaliado.
2. **Resolução de conflitos.** Em cada ciclo dispara a ativação com mais prioridade. Em empate,
   dispara a regra declarada primeiro e, dentro da mesma regra, o primeiro artigo. Depois de cada
   disparo as ativações são recalculadas.
3. **Auto-focus.** EX-008 e PC-008 passam à frente de qualquer grupo.
4. **Refração.** Uma ativação (regra + ligações) só volta a disparar se uma decisão que lê tiver sido
   alterada depois do disparo, como acontece com um `modify` no Drools. Os ciclos são evitados pelas
   guardas `naoDisparou`. Mais de 1000 disparos levantam um erro.
5. **Rasto.** O motor guarda tudo o que as explicações usam:
   - os registos de cada regra (código, módulo, resultado, mensagem);
   - os eventos da agenda (ativação criada, disparada, cancelada);
   - cada alteração dos campos de saída (antes e depois).

## Explicações

As definições são as do ADR 0006. Todas estão disponíveis na API, na consola e como predicados.

| Explicação | Predicado | Responde a |
|---|---|---|
| Como? | `como/1`, `como_conclusao/3` | caminho completo; ou como se chegou a OUT-00n (valores, alterações, condições da regra que o fixou) |
| Porque não? | `porque_nao_regra/3`, `porque_nao_conclusao/4` | porque uma regra não disparou ou uma conclusão não foi obtida |
| Porquê? | `porque/2` | porque o sistema faz uma pergunta (IN-001..IN-010, HS-006, EX-001, EX-002, EX-008, CH-002) |
| O que falta? | `dados_em_falta/2` | dados obrigatórios em falta e dados que decidem uma revisão (IN-010), cada um com o seu Porquê |
| E se? | `e_se/4` | reavalia o pedido com alterações (`"artigos[0].revendivel": true`) e mostra as diferenças |

O "Porque não" de uma regra devolve uma de quatro causas:
- `DISPAROU`;
- `MODULO_NAO_ALCANCADO`: uma paragem obrigatória num módulo anterior terminou o fluxo;
- `CANCELADA_POR_PRECEDENCIA`: a regra foi ativada, mas uma regra com mais prioridade invalidou-a;
- `CONDICOES_FALHADAS`: as condições que falham na variante mais próxima de disparar.

Como no `sp_exp2.pl`, as condições são termos Prolog, por isso a explicação avalia-as diretamente.
O Java precisava de um registo de predicados à parte para isso.

## API REST

### Swagger

Com o servidor a correr, o Swagger UI está em **`http://localhost:8090/swagger-ui.html`** (também em
`/swagger`, ou pela ligação "API (Swagger)" da interface). A especificação OpenAPI 3 está em
`/v3/api-docs`, nos mesmos caminhos da API Drools. Para experimentar:

1. Abre `POST /api/v1/avaliacoes`.
2. Escolhe um dos 10 cenários de teste em *Examples* e carrega em *Execute*.
3. Usa o `avaliacaoId` da resposta nas explicações.

- **Internet.** O Swagger UI é carregado do CDN jsDelivr, por isso esta página precisa de internet.
  Sem internet, a especificação em `/v3/api-docs` pode ser importada no Postman ou no Insomnia.
- **Especificação.** A especificação é o ficheiro `web/openapi.json`. É gerada por
  `python ferramentas/gerar_openapi.py`, que usa os cenários de teste como exemplos. Se a API ou os
  cenários mudarem, volta a correr-se o script.

### Endpoints

Os caminhos e os formatos JSON são os da API Drools (`docs/05`, ADR 0008):

| Método | Caminho | Resposta |
|---|---|---|
| GET | `/api/v1/saude` | estado do serviço |
| POST | `/api/v1/avaliacoes` | 201 `DecisaoResponse` (422 se faltarem dados obrigatórios) |
| GET | `/api/v1/avaliacoes?loja=&pagina=&tamanho=` | página de avaliações |
| GET | `/api/v1/avaliacoes/{id}` | `DecisaoResponse` |
| POST | `/api/v1/avaliacoes/dados-em-falta` | "O que falta?" (aceita pedidos incompletos) |
| POST | `/api/v1/avaliacoes/porque?dado=IN-010` | "Porquê?" |
| GET | `/api/v1/avaliacoes/{id}/explicacoes/como[?conclusao=OUT-001&artigo=A-1]` | "Como?" |
| GET | `/api/v1/avaliacoes/{id}/explicacoes/porque-nao?conclusao=OUT-001:PERMITIR` ou `?regra=PT-003` | "Porque não?" |
| POST | `/api/v1/avaliacoes/{id}/simulacoes` com `{"alteracoes": {...}}` | "E se?" |
| GET | `/api/v1/regras`, `/api/v1/regras/{codigo}` | catálogo das regras e variantes |
| GET | `/api/v1/exemplos` | os 10 cenários de teste, para a interface (não existe na API Drools) |

Os erros seguem o formato ProblemDetail (`type`, `title`, `status`, `detail`, `erros`).

### Diferenças em relação à API Drools

Estas diferenças são opções de âmbito (núcleo + API, sem infraestrutura):

- **Sem autenticação JWT.** O colaborador vem no campo `colaborador` do próprio pedido
  (`{"funcao": "KEY_HOLDER", "aprovadoPeloDM": false, "idCredencialPOS": "POS-1", ...}`). A HS-006
  continua a decidir, como no Drools.
- **Sem PostgreSQL.** As avaliações ficam em memória enquanto o servidor corre. As explicações
  reavaliam o pedido gravado, porque o motor é determinístico.
- **Sem integrações simuladas.** Não há POS, BackPocket nem catálogo. Um campo em falta recebe o
  valor por omissão do modelo Java (ex.: `skuReconhecidoPOS = false`, `forneceDados = true`).
- **Textos só em português.** Os valores monetários aparecem nas mensagens com duas casas decimais.

## Testes

255 testes PLUnit (e 1836 sub-testes):

| Ficheiro | O que verifica | Origem no Drools |
|---|---|---|
| `testes_cenarios.pl` | os 10 cenários de `docs/06`, com o mesmo JSON e os mesmos resultados esperados | `CenariosEsforcoTest` |
| `testes_m0_m3.pl` | autorização, canal, paragens obrigatórias e estado do produto | `AutorizacaoECanalTest`, `ElegibilidadeProdutoTest` |
| `testes_m4_online.pl` | comprovativo, prazo, ajuste de preço e caminho online | `ComprovativoEPrazoTest`, `CaminhoOnlineTest` |
| `testes_m6_transversais.pl` | trocas, revisão, exceções, EX-008, PC-008 e robustez com dados em falta | `ResultadoEExcecoesTest`, `TransversaisTest`, `RobustezDadosEmFaltaTest` |
| `testes_m7.pl` | meio de reembolso e valor | `MeioReembolsoTest`, `ValorDevolucaoTest` |
| `testes_m8_m9.pl` | controlos, documentação, destino e agregação | `ControlosTest`, `DestinoProdutoTest` |
| `testes_explicacoes.pl` | Como, Porque não, Porquê, E se, O que falta | `ExplicadoresTest`, `SimulacaoEDadosEmFaltaTest` |
| `testes_coerencia.pl` | metadados, ver lista abaixo | `MetadadosRegrasTest`, `CoerenciaConclusoesTest`, `CoberturaRegrasTest` |
| `testes_consola.pl` | modo interativo, com respostas simuladas | — |
| `testes_api.pl` | a API por HTTP, incluindo os 10 cenários, os ficheiros da interface web e o Swagger | `CenariosApiIT` |

`testes_coerencia.pl` verifica que:
- cada condição está descrita e lê dados;
- as conclusões declaradas cobrem tudo o que as regras alteram;
- cada ID dispara em algum pedido de teste e é referido num teste.

Os testes do Drools foram portados um a um, com o mesmo pedido base (`PedidoBuilder` →
`testes/suporte.pl`) e as mesmas asserções. Ficaram de fora só os testes que dependem do Java ou do
Drools:
- os textos em inglês (`GeradorTexto`);
- a clonagem de factos (`ClonadorFactos`);
- as convenções do DRL e a disponibilidade do motor Drools;
- a arquitetura (ArchUnit).

## Ambiguidades por validar

As regras com comportamento provisório (ADR 0003, A-01 a A-31) têm a descrição terminada em
`[a validar: A-xx]`. A decisão lista-as em `regrasAValidar` e a consola assinala-as. Quando a
operação responder, altera-se a regra em `src/bc/regras.pl` e o teste correspondente, tal como no
projeto Drools.
