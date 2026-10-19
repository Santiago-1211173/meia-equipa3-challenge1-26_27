# Sistema Pericial de Diagnóstico para Devoluções e Trocas no Retalho (Levi's)
### *Entrega Curricular de Paradigmas de Programação em Inteligência Artificial (PPROGIA)*
#### *Mestrado em Engenharia de Inteligência Artificial (MEIA 2026/2027) — Desafio 1 · Equipa 3*

---

## 1. Identificação e Enquadramento

* **Unidade Curricular:** Paradigmas de Programação em Inteligência Artificial (PPROGIA)
* **Docente Responsável:** Prof. ACM
* **Curso:** Mestrado em Engenharia de Inteligência Artificial (MEIA), Instituto Superior de Engenharia do Porto (ISEP)
* **Desafio:** Desafio 1 — Sistema Pericial de Devoluções e Trocas no Retalho (Caso de Uso: *Levi Strauss & Co.*)
* **Equipa 3:** SmartCloth AI
* **Perito de Domínio Humano:** Dustin Hopper (Especialista em Políticas Globais de Retalho Levi's)

Este pacote de entrega é **100% autónomo**, focado exclusivamente na programação lógica declarativa em **SWI-Prolog**, sem qualquer dependência de ferramentas externas (dispensa Java, Maven, Python, Node.js ou bases de dados relacionais).

---

## 2. Requisitos de Execução

* **SWI-Prolog:** Versão 9.0 ou superior (testado e validado em SWI-Prolog 9.2.x e 9.3.x).
  ```bash
  swipl --version
  ```

Nenhuma biblioteca externa de terceiros é necessária: todas as funcionalidades recorrem exclusivamente a bibliotecas nativas do SWI-Prolog (`lists`, `plunit`, `http/http_server`, `http/http_json`).

---

## 3. Arranque Rápido da Consola Interativa (1 Linha)

Para iniciar imediatamente a consola pericial interativa no terminal:

```bash
cd prolog_engine
swipl -s run_console.pl
```

Ao carregar, o sistema exibe automaticamente a mensagem de boas-vindas e o menu com os comandos disponíveis:

```text
================================================================================
  MEIA 2026/2027 · PPROGIA · Desafio 1 (Equipa 3)
  SISTEMA PERICIAL DE DEVOLUÇÕES E TROCAS LEVI STRAUSS & CO. (71 REGRAS)
================================================================================

Bem-vindo à consola pericial declarativa em SWI-Prolog.
O motor implementa inferência dedutiva (forward-chaining), raciocínio dialógico
segundo o modelo do Prof. ACM e 5 vias formais de explicabilidade pericial.

COMANDOS DISPONÍVEIS NA CONSOLA:
  ?- avaliar_interativo.   -> Inicia triagem guiada com perguntas e respostas.
  ?- cenario(N).           -> Executa um dos 10 cenários de teste oficiais (1 a 10).
  ?- listar_cenarios.      -> Lista os 10 cenários de retalho pré-configurados.
  ?- como(Facto).          -> Explicação causal retrospetiva (Como o facto foi deduzido).
  ?- whynot(Facto).        -> Explicação contrafactual (Porque é que o facto falhou).
  ?- output_why.           -> Mostra as justificações executivas da decisão final.
  ?- factos.               -> Lista todos os factos presentes na memória de trabalho.
  ?- limpar.               -> Limpa a memória da sessão atual para novo teste.
  ?- testar.               -> Executa a suite completa de 91 testes automatizados PLUnit.
  ?- ajuda.                -> Exibe este resumo de comandos.
```

---

## 4. Guia de Operação e Funcionalidades

### 4.1 Triagem Guiada Interativa (`?- avaliar_interativo.`)
Ativa o modo dialógico concebido segundo a metodologia de interrogação dinâmica do **Prof. ACM**:
* As premissas em falta são questionadas passo-a-passo ao operador em linguagem natural (pt-PT).
* São apresentadas sugestões de valores aceites entre parênteses.
* Em perguntas binárias, aceita: `sim`, `nao`, `s`, `n`, `true`, `false`.
* Conclusões diagnósticas nunca são questionadas diretamente (apenas atributos observáveis da loja declarados em `perguntavel/1`).
* Prevenção estrita de ciclos (`ja_perguntado/1`): nenhum atributo é questionado mais do que uma vez na mesma sessão.

### 4.2 Inquirição Bidirecional: Resposta ao "Porquê?"
A qualquer momento durante a triagem, o utilizador pode responder com `porquê?` (ou `porque`, `why`). O motor suspende momentaneamente a interrogação e apresenta a justificação normativa da pergunta:
1. **Identificador da Regra Candidata:** Ex.: `[PC-008]`, `[PT-001]`, `[HS-003]`.
2. **Família Normativa:** Ex.: *Product Condition*, *Proof & Timeframe*, *Hard Stops*.
3. **Objetivo em Avaliação:** Meta dedutiva que a regra está a tentar provar.
4. **Fundamento da Política:** Descrição em texto claro da política de retalho que fundamenta a exigência daquela premissa.

Em seguida, o motor repete a questão sem perder o estado da sessão.

### 4.3 Gestão Defensiva de Incerteza: Resposta "Não Sei"
Caso o operador não disponha da informação solicitada, pode responder `nao_sei` (ou `não sei`, `?`, `ns`). O motor:
* **Não afirma falsidades lógicas:** Evita asserções arbitrárias de negação.
* **Progride com segurança:** Aciona vias dedutivas alternativas (ex.: devolução sem recibo / *blind return*, ou escalamento para a gerência de loja).

### 4.4 Execução Pedagógica dos 10 Cenários Oficiais (`?- cenario(N).`)
Permite ao docente avaliar instantaneamente qualquer um dos **10 cenários normativos da Levi's** formulados em articulação com o perito de retalho Dustin Hopper:

| Nº | Título do Cenário | Família Principal | Decisão Concluída |
|:--:|:---|:---|:---:|
| **1** | As etiquetas soltas, troca ao 29.º dia | `PC-002`, `EX-001` | `rever` (Revisão da Gestão) |
| **2** | O cliente irritado com Afterpay | `CH-002`, `TN-010`, `EX-006` | `recusar` (Processo BackPocket / HS-005) |
| **3** | A devolução de oferta na Outlet sem recibo | `PT-002`, `PT-005`, `CH-009` | `permitir` (Crédito de Loja) |
| **4** | As calças com bainha e defeito de fabrico | `HS-003` | `recusar` (Hard Stop - Alterado) |
| **5** | A disputa sobre produto grossista (*Wholesale*) | `CH-008`, `EX-002` | `recusar` (Canal de Compra Não Aceite) |
| **6** | Devolução sem recibo com risco biológico e fraude | `PC-008`, `EX-008` | `rever` (Escalamento Distrital) |
| **7** | A substituição do cartão de débito Interac no Canadá | `PT-001`, `EX-002` | `rever` (Autorização de Gerência) |
| **8** | Ajuste de preço com fotografia de recibo | `PT-008` | `recusar` (Foto Não Aceite) |
| **9** | Conjunto de bodywear com risco de segurança e garantia | `PC-008`, `BW-004` | `permitir` (Estorno + Destruição) |
| **10** | Troca online tardia com PayPal durante falha do portal | `CH-004`, `TN-008`, `EX-001` | `rever` (Aprovação de Responsável Sénior) |

Para listar os cenários: `?- listar_cenarios.`  
Para executar o cenário 1: `?- cenario(1).`

---

## 5. As 5 Vias Formais de Explicabilidade Pericial

O motor implementa as 5 vias de explicabilidade pericial da literatura de Sistemas Baseados em Conhecimento:

1. **Via 1: Como? (`?- como(Facto).`):** Árvore dedutiva causal retrospetiva que reconstrói a cadeia exata de regras e factos que conduziram à conclusão. Distingue univocamente entre factos fornecidos pelo operador (`utilizador`), factos iniciais e factos inferidos por regras com identificadores canónicos (`[PC-001]`, `[PT-003]`).
2. **Via 2: Porquê da Pergunta? (`?- why_ask.` ou `porquê?` no diálogo):** Justificação contextualizada durante a interrogação de premissas em falta.
3. **Via 3: Porquê da Decisão? (`?- output_why.`):** Síntese executiva dos fundamentos normativos das regras que dispararam.
4. **Via 4: Porque Não? (`?- whynot(Facto).`):** Diagnóstico contrafactual quando um objetivo não é alcançado (ex.: `?- whynot(decisao(permitir)).`), decompondo conjunções e apontando as premissas em falta em cada ramo alternativo.
5. **Via 5: E Se? (What-If Sandbox):** Simulação contrafactual transacional via `what_if/3` em sandbox com `setup_call_cleanup/3`, garantindo zero poluição da memória de trabalho.

---

## 6. Execução Automatizada da Suíte de Testes PLUnit

O projeto inclui **91 testes automatizados com 100% de aprovação**, cobrindo todas as dimensões do motor dedutivo.

### Comando em Linha de Comandos (Modo Batch com Exit Code):
```bash
cd prolog_engine
swipl -s run_tests.pl
```

### Comando a Partir da Consola Interativa:
```prolog
?- testar.
```

### Composição da Suíte de Testes (91 Testes):
* `tests/test_retail_rules.pl` (31 testes): Validação exaustiva das 71 regras da Levi's e da hierarquia de 7 precedências estritas.
* `tests/test_retail_interactive.pl` (12 testes): Validação do fluxo dialógico ACM, aquisição com `obtem_facto/2`, tratamento de `nao_sei`, resposta ao `porquê?` e prevenção de ciclos.
* `tests/test_retail_explainability.pl` (18 testes): Validação formal das 5 vias de explicabilidade (`como/1`, `why_ask/1..2`, `output_why/1`, `whynot/1`, `what_if/3`).
* `tests/test_retail_expert_scenarios.pl` (10 testes): Validação dos 10 cenários normativos oficiais estabelecidos com o perito de retalho.
* `tests/test_retail_api.pl` (12 testes): Testes de integração HTTP do servidor REST nativo em porta TCP dedicada (`8992`).
* `tests/test_inference_engine.pl` (8 testes): Preservação académica da prova de conceito e paridade com o motor `sp_exp2.pl`.

---

## 7. Valorização Adicional: Servidor REST HTTP e Docker

Embora o foco principal da avaliação de PPROGIA seja o terminal interativo de SWI-Prolog, a equipa desenvolveu uma **camada de transporte HTTP REST nativa em SWI-Prolog** para integração no ecossistema completo:

### 7.1 Arranque do Servidor HTTP
```bash
cd prolog_engine
swipl -s src/main.pl
```
O servidor arranca por defeito na porta `8080`.

### 7.2 Catálogo dos 7 Endpoints REST HTTP

| Rota | Método | Função |
|:---|:---:|:---|
| `/retail/evaluate` | POST | Avaliação dedutiva em lote com payload JSON de factos, retornando decisão e array `justification[]`. |
| `/retail/interactive` | POST | Execução ou simulação passo-a-passo de triagem dialógica com perguntas estruturadas. |
| `/retail/whatif` | POST | Simulação contrafactual What-If com factos a adicionar e remover em sandbox volátil. |
| `/retail/how` | POST | Rasto dedutivo completo em JSON para qualquer facto inferido. |
| `/retail/whynot` | POST | Árvore estruturada de falha contrafactual para decisões não atingidas. |
| `/retail/facts` | GET | Listagem de todos os factos ativos na memória de trabalho. |
| `/retail/reset` | POST | Reinicialização atómica da sessão e histórico de diálogo. |

### 7.3 Execução em Contentor Docker
```bash
# Construção da imagem Docker autónoma
docker build -t prolog-engine .

# Execução do contentor na porta 8080
docker run -d --name prolog-engine -p 8080:8080 prolog-engine

# Teste de saúde
curl -s http://127.0.0.1:8080/retail/facts
```

---

## 8. Estrutura de Ficheiros do Pacote `prolog_engine/`

```text
prolog_engine/
├── run_console.pl                       # Launcher de consola interativa SWI-Prolog (iniciar, cenario, avaliar_interativo)
├── run_tests.pl                         # Executor batch da suite de 91 testes PLUnit
├── README_ENTREGA.md                    # Este manual de avaliação orientado a PPROGIA
├── Dockerfile                           # Descritor Docker autónomo baseado em swipl:latest
│
├── src/
│   ├── main.pl                          # Bootstrap do micro-serviço HTTP REST (porta 8080)
│   ├── api/                             # Camada de transporte HTTP
│   │   ├── server.pl                    # Servidor HTTP nativo SWI-Prolog
│   │   ├── routes.pl                    # Rotas preliminares de validação
│   │   ├── inference_routes.pl          # Rotas do motor de veículos (sp_exp2)
│   │   └── retail_routes.pl             # 7 rotas REST especializadas de retalho Levi's
│   │
│   └── core/                            # Camada de domínio e inferência
│       ├── retail_engine/               # Motor de inferência pericial de retalho
│       │   ├── engine.pl                # Forward-chaining, 5 vias de explicabilidade e precedências
│       │   ├── interactive.pl           # Mecânica dialógica ACM, perguntas em pt-PT e gestão de não sei
│       │   └── kb/
│       │       └── retail_rules.pl      # Base de conhecimento: 71 regras da Levi's e 9 famílias
│       │
│       ├── inference/                   # Motor académico de referência
│       │   ├── engine.pl                # sp_exp2 (Clean Architecture)
│       │   └── kb/vehicles.pl           # Base de conhecimento académica de veículos
│       └── rules.pl                     # DSL e operadores lógicos
│
└── tests/                               # Suíte com 91 testes automatizados PLUnit
    ├── test_retail_rules.pl             # 31 testes das 71 regras e 7 precedências
    ├── test_retail_interactive.pl       # 12 testes do diálogo dialógico ACM
    ├── test_retail_explainability.pl    # 18 testes das 5 vias de explicabilidade
    ├── test_retail_expert_scenarios.pl  # 10 testes dos cenários oficiais da Levi's
    ├── test_retail_api.pl               # 12 testes de integração REST HTTP
    └── test_inference_engine.pl         # 8 testes de preservação académica
```

---

## 9. Conformidade com a Definition of Done (Fase 2)

```bash
cd prolog_engine

# 1. Executar os 91 testes automatizados PLUnit (100% de sucesso)
swipl -s run_tests.pl

# 2. Validar arranque da consola sem avisos nem erros de compilação
swipl -q -s run_console.pl -g "iniciar, halt."

# 3. Confirmar presença do ficheiro de entrega
test -f README_ENTREGA.md && echo "OK: README_ENTREGA.md presente"
```
