# Plano de Implementação: Integração do Motor de Inferência Pericial
### *Forward-Chaining Expert System — sp_exp2.pl adaptado para microserviços*

> [!NOTE]
> **Documento de Plano de Implementação para Agente LLM (Antigravity).**
> Este plano deve ser executado fase a fase. O agente **NÃO deve implementar todas as fases de uma vez** — deve aguardar que o utilizador peça a "Fase X" e fornecer os ficheiros completos e compiláveis para essa fase.

---

## CONTEXTO GLOBAL DO SISTEMA

O repositório apresenta a seguinte estrutura relevante:

```text
meia-equipa3-challenge1-26_27/
├── docker-compose.yml                          # Orquestração Docker (2 serviços)
├── backend_orchestrator/                       # Microserviço Python FastAPI (:8000)
│   ├── app/
│   │   ├── main.py                             # Entry point FastAPI + lifespan
│   │   ├── api/
│   │   │   ├── deps.py                         # Injeção de dependências (Depends)
│   │   │   └── v1/
│   │   │       ├── router.py                   # Agregador de rotas v1
│   │   │       └── endpoints/
│   │   │           ├── evaluate.py             # POST /api/v1/evaluate (POC)
│   │   │           └── health.py               # GET /api/v1/health
│   │   ├── clients/
│   │   │   └── prolog_client.py                # Cliente HTTP async para Prolog
│   │   ├── core/
│   │   │   ├── config.py                       # Settings (Pydantic Settings)
│   │   │   └── exceptions.py                   # Exceções de domínio tipadas
│   │   ├── schemas/
│   │   │   ├── common.py                       # EvaluationResponse, DecisionEnum, EngineSourceEnum
│   │   │   ├── health.py                       # HealthResponse
│   │   │   ├── retail.py                       # RetailReturnScenarioInput (preparado)
│   │   │   └── scenario.py                     # ScenarioInput (POC)
│   │   └── services/
│   │       └── orchestrator_service.py         # Orquestração entre motores
│   └── tests/
│       ├── conftest.py                         # Fixtures pytest (mocks, async_client)
│       ├── test_health.py
│       ├── test_orchestrator.py
│       ├── test_prolog_client.py
│       └── test_schemas.py
├── prolog_engine/                              # Microserviço SWI-Prolog (:8080)
│   ├── Dockerfile
│   ├── src/
│   │   ├── main.pl                             # Entry point + bootstrap
│   │   ├── api/
│   │   │   ├── server.pl                       # Daemon HTTP multi-threaded
│   │   │   └── routes.pl                       # POST /evaluate (POC)
│   │   └── core/
│   │       └── rules.pl                        # Regras POC (evaluate_scenario/3)
│   └── tests/
│       ├── test_rules.pl                       # 7 testes unitários PLUnit
│       └── test_api.pl                         # 5 testes de integração HTTP
└── docs/                                       # Documentação técnica em pt-PT
    ├── architecture/
    │   ├── system_overview.md                  # Visão global da arquitetura
    │   ├── prolog_engine.md                    # Clean Architecture do Prolog
    │   ├── fastapi_orchestrator.md             # Camadas do FastAPI
    │   └── service_interactions.md             # Fluxos e pipeline de dados
    ├── api/
    │   ├── orchestrator_api_v1.md              # Referência da API pública
    │   ├── prolog_engine_api.md                # API interna do Prolog
    │   └── schemas.md                          # Catálogo de modelos Pydantic
    ├── development/
    │   ├── coding_conventions.md               # Convenções obrigatórias
    │   ├── getting_started.md
    │   └── testing.md                          # Estratégia de testes
    └── history/
        ├── prolog_implementation_plan.md       # Plano histórico do Prolog POC
        └── fastapi_implementation_plan.md      # Plano histórico do FastAPI
```

### Material de Referência dos Professores

Os ficheiros fornecidos pelos professores estão em:
`prolog_engine/Ficheiros de Apoio Sistemas Periciais_ sp_exp1.pl, sp_exp2.pl e base de conhecimento-20260928/`

Contém:
- **`sp_exp1.pl`** — Motor forward-chaining básico (sem negação nem metaconhecimento)
- **`sp_exp2.pl`** — Motor forward-chaining completo com negação (`nao`), metaconhecimento (`facto_dispara_regras/2`), explicações `como/1` (how) e `whynot/1` (why not)
- **`veiculos1.txt`** — Base de conhecimento simples (6 factos, 8 regras, sem metaconhecimento)
- **`veiculos2.txt`** — Base de conhecimento com metaconhecimento (3 factos, 8 regras, `facto_dispara_regras/2`)

> [!IMPORTANT]
> **Usamos `sp_exp2.pl` como base** porque é a versão completa. O motor `sp_exp2.pl` DEVE ser usado com bases de conhecimento que incluam metaconhecimento (formato `veiculos2.txt`).

### Semântica do Motor sp_exp2.pl

O motor define operadores custom que criam uma DSL em Prolog:
```prolog
:-op(220,xfx,entao).   % operador infix: LHS entao RHS
:-op(35,xfy,se).        % operador: regra ID se LHS entao RHS
:-op(240,fx,regra).     % operador prefix: regra N
:-op(500,fy,nao).       % operador prefix: nao X (negação)
:-op(600,xfy,e).        % operador infix: X e Y (conjunção)
```

Uma regra fica assim:
```prolog
regra 1
    se [tipo(Veiculo,passageiros) e classe(Veiculo,ligeiro)]
    entao [cria_facto(ligeiro(Veiculo,carro))].
```

**Predicados-chave do motor:**
| Predicado | Função |
|:---|:---|
| `arranca_motor/0` | Iteração principal: para cada facto, encontra regras que dispara via metaconhecimento |
| `facto_dispara_regras/2` | Metaconhecimento: mapeia padrões de factos → lista de IDs de regras |
| `verifica_condicoes/2` | Verifica se TODAS as condições do LHS são satisfeitas |
| `cria_facto/3` | Assertz de novo facto + justificação (`justifica/3`) |
| `como/1` | Explicação recursiva "how" — mostra cadeia de justificações |
| `whynot/1` | Explicação "why not" — mostra premissas que falharam |
| `mostra_factos/0` | Lista todos os factos na base |

**O problema principal para integração:** O motor é interativo — usa `write/1`, `read/1`, `get0/1` para I/O de consola. Precisamos de o adaptar para retornar dados estruturados em vez de escrever no terminal.

---

## REGRAS OBRIGATÓRIAS (extraídas de coding_conventions.md)

O agente DEVE seguir rigorosamente estas regras (definidas em [`docs/development/coding_conventions.md`](../../docs/development/coding_conventions.md)):

1. **Idioma do Código:** Todo o código (variáveis, funções, predicados, classes) em **INGLÊS**. Docstrings e comentários técnicos em **INGLÊS**. Documentação em `docs/` em **Português (pt-PT)**.
2. **Clean Architecture:** A camada `core/` NÃO deve ter dependências HTTP/JSON. A camada `api/` NÃO contém lógica de negócio.
3. **Prolog Modular:** Todo ficheiro `.pl` deve declarar `:- module(nome, [exportados]).` com `/** <module> ... */` docstring.
4. **Prolog Dicts como DTOs:** Dados entre camadas usam Prolog Dicts (`_{chave: valor}`).
5. **Python Type Hints:** Toda função com `from __future__ import annotations`, tipo de retorno, `Field(...)` em Pydantic.
6. **FastAPI Depends:** Injeção de dependências via `Depends()` para testabilidade.
7. **Async Python:** Todos os endpoints e chamadas HTTP são `async def` + `await`.
8. **Commits:** Formato Conventional Commits em inglês: `feat(scope): description`.

---

## ESTRUTURA ALVO APÓS IMPLEMENTAÇÃO

```text
prolog_engine/src/
├── api/
│   ├── server.pl                    # (SEM ALTERAÇÃO)
│   ├── routes.pl                    # (SEM ALTERAÇÃO)
│   └── inference_routes.pl          # 🆕 Endpoints HTTP REST para motor de inferência
├── core/
│   ├── rules.pl                     # (SEM ALTERAÇÃO)
│   └── inference/                   # 🆕 Motor pericial modular
│       ├── engine.pl                # Motor sp_exp2 adaptado (não-interativo, estruturado)
│       └── kb/                      # Bases de conhecimento carregáveis
│           └── vehicles.pl          # Base de conhecimento de veículos (adaptada de veiculos2.txt)
└── main.pl                          # MODIFICAÇÃO MÍNIMA: +1 use_module

backend_orchestrator/app/
├── api/v1/
│   ├── endpoints/
│   │   ├── evaluate.py              # (SEM ALTERAÇÃO)
│   │   ├── health.py                # (SEM ALTERAÇÃO)
│   │   └── inference.py             # 🆕 Endpoints FastAPI para motor de inferência
│   └── router.py                    # MODIFICAÇÃO MÍNIMA: inclusão condicional
├── clients/
│   ├── prolog_client.py             # (SEM ALTERAÇÃO)
│   └── inference_client.py          # 🆕 Cliente HTTP async para /inference/*
├── schemas/
│   └── inference.py                 # 🆕 Schemas Pydantic para motor de inferência
├── services/
│   └── inference_service.py         # 🆕 Camada de serviço para inferência
└── core/
    └── config.py                    # MODIFICAÇÃO MÍNIMA: +1 campo INFERENCE_ENGINE_ENABLED
```

---

# FASE 1: Motor de Inferência Core (Prolog Puro — Domínio) `[CONCLUÍDA]`

> [!NOTE]
> **Estado:** Concluída com sucesso em 2026-09-28.
> Todos os testes unitários e de integração de domínio foram validados em SWI-Prolog.

**Objetivo:** Adaptar o motor `sp_exp2.pl` dos professores para funcionar como módulo Prolog não-interativo, retornando dados estruturados em vez de escrever no terminal.

**Ficheiros a criar:**
- `prolog_engine/src/core/inference/engine.pl`
- `prolog_engine/src/core/inference/kb/vehicles.pl`

**Ficheiros de referência a ler:**
- Material dos professores: `sp_exp2.pl` (motor completo com `nao`, metaconhecimento, `como/1`, `whynot/1`)
- Material dos professores: `veiculos2.txt` (base de conhecimento com metaconhecimento)
- Padrão de módulo: [`prolog_engine/src/core/rules.pl`](../../prolog_engine/src/core/rules.pl) (como modelo de estrutura)
- Convenções: [`docs/development/coding_conventions.md`](../../docs/development/coding_conventions.md) (secção 4)

---

### Subfase 1.1 — Base de Conhecimento (`vehicles.pl`)

**Ficheiro a criar:** `prolog_engine/src/core/inference/kb/vehicles.pl`

**O que fazer:**
Converter o ficheiro `veiculos2.txt` dos professores num módulo Prolog limpo. Este ficheiro é uma base de conhecimento que contém:
- Declarações `dynamic` para `facto/2` e `ultimo_facto/1`
- Metaconhecimento: `facto_dispara_regras/2` — mapeia padrões de factos para listas de IDs de regras
- Regras no formato DSL: `regra N se [...] entao [...]`
- Factos iniciais: `facto(N, termo).`

**Instruções precisas:**

1. Criar o ficheiro como módulo Prolog:
```prolog
:- module(vehicles_kb, []).
```

2. Copiar TODO o conteúdo de `veiculos2.txt` para dentro do módulo, MAS:
   - NÃO alterar os nomes dos predicados em português (`facto`, `regra`, `tipo`, `peso`, `lotacao`, etc.) — estes são termos do domínio da base de conhecimento que pertencem à DSL dos professores e DEVEM ser mantidos em português para compatibilidade com o motor
   - O nome do módulo (`vehicles_kb`) e os comentários do cabeçalho em inglês
   - Adicionar docstring `/** <module> ... */`

3. Os operadores custom (`regra`, `se`, `entao`, `e`, `nao`) NÃO devem ser definidos aqui — serão definidos no `engine.pl` e importados

4. Manter os factos iniciais do `veiculos2.txt` como default:
```prolog
facto(1, lotacao(meu_veiculo, 3)).
facto(2, peso(meu_veiculo, 4500)).
facto(3, tipo(meu_veiculo, mercadorias)).
```

**Conteúdo-fonte de `veiculos2.txt`** (copiar e adaptar):
```prolog
:-dynamic facto/2,ultimo_facto/1.

% Metaconhecimento
facto_dispara_regras(tipo(_, passageiros), [1, 3, 8]).
facto_dispara_regras(tipo(_, mercadorias), [2, 8]).
facto_dispara_regras(tipo(_, misto), [4]).
facto_dispara_regras(lotacao(_, _), [5, 7]).
facto_dispara_regras(peso(_, _), [6, 7]).
facto_dispara_regras(classe(_, ligeiro), [1]).
facto_dispara_regras(classe(_, pesado), [2, 3, 4]).

ultimo_facto(3).

regra 1 se [tipo(V,passageiros) e classe(V,ligeiro)] entao [cria_facto(ligeiro(V,carro))].
regra 2 se [tipo(V,mercadorias) e classe(V,pesado)] entao [cria_facto(pesado(V,camiao))].
regra 3 se [tipo(V,passageiros) e classe(V,pesado)] entao [cria_facto(pesado(V,autocarro))].
regra 4 se [tipo(V,misto) e classe(V,pesado)] entao [cria_facto(pesado(V,camioneta))].
regra 5 se [avalia(lotacao(V,>,9))] entao [cria_facto(classe(V,pesado))].
regra 6 se [avalia(peso(V,>,3500))] entao [cria_facto(classe(V,pesado))].
regra 7 se [avalia(lotacao(V,=<,9)) e avalia(peso(V,=<,3500))] entao [cria_facto(classe(V,ligeiro))].
regra 8 se [tipo(V,mercadorias) e tipo(V,passageiros)] entao [cria_facto(tipo(V,misto))].

facto(1, lotacao(meu_veiculo, 3)).
facto(2, peso(meu_veiculo, 4500)).
facto(3, tipo(meu_veiculo, mercadorias)).
```

> [!WARNING]
> Os caracteres acentuados do ficheiro original (`lotação`, `veículo`, `camião`) foram substituídos por versões sem acento (`lotacao`, `veiculo`, `camiao`) para evitar problemas de encoding no SWI-Prolog em contentores Docker. Esta normalização é intencional.

**Critério de validação:** O ficheiro deve ser carregável sem erros após o `engine.pl` definir os operadores.

---

### Subfase 1.2 — Motor de Inferência Adaptado (`engine.pl`)

**Ficheiro a criar:** `prolog_engine/src/core/inference/engine.pl`

**O que fazer:**
Adaptar o motor `sp_exp2.pl` dos professores para funcionar como módulo Prolog **não-interativo**. O motor original usa `write/1`, `read/1`, `get0/1` para I/O de consola — precisamos que TODOS os predicados retornem dados estruturados (listas, dicts, termos) em vez de escreverem output.

**Ficheiro de referência:** O conteúdo completo de `sp_exp2.pl` está documentado na secção "Semântica do Motor sp_exp2.pl" acima neste plano.

**Instruções precisas:**

1. Declarar como módulo com os predicados públicos que a camada HTTP vai precisar:
```prolog
:- module(inference_engine, [
    load_knowledge_base/1,      % +KBName — carrega uma BC por nome
    run_engine/1,               % -ResultDict — executa motor e retorna resultado
    get_all_facts/1,            % -FactsList — lista todos os factos
    explain_how/2,              % +FactId, -ExplanationList — como?
    explain_whynot/2,           % +FactTerm, -ExplanationList — porque não?
    reset_engine/0              % limpa sessão (retract tudo)
]).
```

2. Definir os operadores custom DENTRO deste módulo (copiados de `sp_exp2.pl`):
```prolog
:-op(220,xfx,entao).
:-op(35,xfy,se).
:-op(240,fx,regra).
:-op(500,fy,nao).
:-op(600,xfy,e).
```

3. Declarar predicados dinâmicos:
```prolog
:-dynamic facto/2, ultimo_facto/1, justifica/3.
```

4. **`load_knowledge_base/1`**: Substituir `carrega_bc/0` (que usava `read/1`). Recebe o nome da BC como átomo, resolve o caminho do ficheiro em `kb/` e faz `consult`:
```prolog
load_knowledge_base(KBName) :-
    reset_engine,
    atomic_list_concat(['src/core/inference/kb/', KBName, '.pl'], Path),
    consult(Path).
```

5. **`run_engine/1`**: Adaptar `arranca_motor/0`. Em vez de fazer `write(...)` e `get0(_)` quando cria um facto, deve simplesmente criar o facto silenciosamente. Retornar um dicionário com:
   - `initial_facts_count`: número de factos antes de executar
   - `derived_facts`: lista de dicionários `_{id: N, fact: FactString, rule_id: RuleID, justified_by: LFactos}` para cada facto derivado
   - `total_facts`: número total de factos após execução

6. **`get_all_facts/1`**: Adaptar `mostra_factos/0`. Em vez de `write/1`, usar `findall/3` para retornar lista de dicionários:
```prolog
get_all_facts(FactsList) :-
    findall(
        _{id: N, fact: FactAtom},
        (facto(N, F), term_to_atom(F, FactAtom)),
        FactsList
    ).
```

7. **`explain_how/2`**: Adaptar `como/1`. Em vez de `write/1` + `nl`, construir recursivamente uma lista de strings de explicação. Cada passo deve produzir strings como:
   - `"Fact 4 -> classe(meu_veiculo,pesado) concluded by rule 6"`
   - `"Based on facts: [2]"`
   - `"Fact 2 -> peso(meu_veiculo,4500) was an initial fact"`

8. **`explain_whynot/2`**: Adaptar `whynot/1`. Em vez de `write/1`, construir lista de strings explicando quais premissas falharam e em que regras.

9. **`reset_engine/0`**: Limpar toda a sessão:
```prolog
reset_engine :-
    retractall(facto(_, _)),
    retractall(ultimo_facto(_)),
    retractall(justifica(_, _, _)).
```

10. **MANTER os predicados internos do motor** (`verifica_condicoes/2`, `facto_esta_numa_condicao/2`, `dispara_regras/3`, `facto_dispara_regras1/2`, `concluir/2`, `avalia/2`, `compara/2`) — adaptar apenas o `cria_facto/3` para NÃO fazer `write/1` nem `get0/1`.

**Adaptação crítica de `cria_facto/3`:**

Original (interativo):
```prolog
cria_facto(F,ID,LFactos):-
    retract(ultimo_facto(N1)),
    N is N1+1,
    asserta(ultimo_facto(N)),
    assertz(justifica(N,ID,LFactos)),
    assertz(facto(N,F)),
    write('Foi concluído o facto nº '),write(N),write(' -> '),write(F),get0(_),!.
```

Adaptado (silencioso):
```prolog
cria_facto(F,ID,LFactos):-
    retract(ultimo_facto(N1)),
    N is N1+1,
    asserta(ultimo_facto(N)),
    assertz(justifica(N,ID,LFactos)),
    assertz(facto(N,F)),
    !.
```

**Critério de validação:**
Deve ser possível executar na consola `swipl` interativa:
```prolog
?- use_module('src/core/inference/engine').
?- load_knowledge_base(vehicles).
?- run_engine(Result).
?- get_all_facts(Facts).
?- explain_how(4, Explanation).
?- explain_whynot(classe(meu_veiculo, ligeiro), Explanation).
```

Resultado esperado com factos de `veiculos2.txt` (meu_veiculo: lotacao=3, peso=4500, tipo=mercadorias):
- Facto 4 derivado: `classe(meu_veiculo, pesado)` (via regra 6, porque peso > 3500)
- Facto 5 derivado: `pesado(meu_veiculo, camiao)` (via regra 2, porque tipo=mercadorias + classe=pesado)

### Detalhes da Implementação Realizada (Fase 1)

A Fase 1 foi integralmente implementada com sucesso nos seguintes ficheiros:
- [`vehicles.pl`](../../prolog_engine/src/core/inference/kb/vehicles.pl) — Base de conhecimento de veículos adaptada de `veiculos2.txt`.
- [`engine.pl`](../../prolog_engine/src/core/inference/engine.pl) — Motor pericial forward-chaining não-interativo adaptado de `sp_exp2.pl`.
- [`.gitignore`](../../.gitignore) — Correção da exclusão de pastas `core`.

#### 1. Encapsulamento Modular e Operadores DSL
- **Import de Operadores:** O ficheiro `vehicles.pl` declara `:- module(vehicles_kb, []).` e importa os operadores periciais através de `:- use_module('../engine').`. Isto garante que termos com a sintaxe DSL (`regra ... se ... entao ...`, `... e ...`, `nao ...`) são corretamente reconhecidos pelo parser do SWI-Prolog no momento do carregamento.
- **Carregamento Unificado de KBs:** No [`engine.pl`](../../prolog_engine/src/core/inference/engine.pl), o predicado [`load_knowledge_base/1`](../../prolog_engine/src/core/inference/engine.pl#L34) utiliza `load_files(Path, [module(inference_engine)])`. Desta forma, factos dinâmicos (`facto/2`, `ultimo_facto/1`), regras (`(regra)/1`) e metaconhecimento (`facto_dispara_regras/2`) são compilados diretamente no contexto do módulo `inference_engine`, viabilizando asserções dinâmicas e limpezas completas via [`reset_engine/0`](../../prolog_engine/src/core/inference/engine.pl#L64).
- **Resolução Resiliente de Caminhos:** O predicado interno `resolve_kb_path/2` pesquisa em quatro localizações candidatas:
  1. Caminho relativo de execução (`src/core/inference/kb/<KB>.pl`);
  2. Caminho relativo à localização física do módulo `engine.pl` (`<EngineDir>/kb/<KB>.pl`, obtido via `source_file/2`);
  3. Caminho a partir da raiz do repositório (`prolog_engine/src/core/inference/kb/<KB>.pl`);
  4. Ficheiro direto local (`<KB>.pl`).
  Isto permite que o motor funcione tanto dentro do contentor Docker (`/app`), como em testes executados a partir de `prolog_engine/` ou da raiz do repositório.

#### 2. Adaptação do Forward-Chaining para Semântica ISO / SWI-Prolog
- **O Desafio:** O motor original `sp_exp2.pl` dependia de um loop baseado em backtracking sobre o predicado dinâmico `facto(N, Facto)`. Contudo, o SWI-Prolog implementa a *visão lógica de atualização* do padrão ISO: um iterador aberto sobre um predicado dinâmico não visita cláusulas assinaladas após a abertura da consulta.
- **A Solução:** Implementou-se um ciclo recursivo indexado `arranca_motor/1` que avalia sequencialmente o facto $N$, consulta o metaconhecimento `facto_dispara_regras/2`, dispara as regras candidatas via `dispara_regras/3` e avança deterministicamente para $N+1$ até esgotar todos os factos:
  ```prolog
  arranca_motor :- arranca_motor(1).

  arranca_motor(N) :-
      facto(N, Facto),
      !,
      facto_dispara_regras1(Facto, LRegras),
      dispara_regras(N, Facto, LRegras),
      N1 is N + 1,
      arranca_motor(N1).
  arranca_motor(_).
  ```
- **Conclusão Determinística:** O predicado [`cria_facto/3`](../../prolog_engine/src/core/inference/engine.pl#L286) verifica previamente a existência do facto (`facto(_, F), !.`), evitando duplicações, e atualiza `ultimo_facto(N)` e `justifica(N, ID, LFactos)` sem recorrer a qualquer chamada interativa (`write/1`, `get0/1`).

#### 3. DTOs Estruturados e Normalização JSON
- [`run_engine/1`](../../prolog_engine/src/core/inference/engine.pl#L78): Retorna um dicionário SWI-Prolog com a contagem de factos iniciais, factos derivados, total e a lista detalhada de cada facto inferido:
  ```prolog
  ResultDict = _{
      status: "success",
      initial_facts_count: InitialCount,
      derived_facts_count: DerivedCount,
      total_facts: TotalCount,
      derived_facts: DerivedFacts
  }.
  ```
- **Normalização de Justificações:** O predicado interno `normalize_justification/2` assegura que elementos não-inteiros nas justificações (como condições negativas `nao X`) são convertidos para strings/átomos antes da serialização, prevenindo falhas de serialização no `http_json`.

#### 4. Motor de Explicabilidade (How & Why Not)
- **`explain_how/2`:** Percorre a cadeia de derivação a partir de `justifica(FactId, RuleId, LFactos)`. Para factos derivados, indica a regra e factos de suporte, descendo recursivamente na árvore com registo de nós visitados (`Visited`) para imunidade a ciclos. Para factos de entrada, reporta que foram conhecidos inicialmente.
- **`explain_whynot/2`:** Aceita termos Prolog, átomos ou strings formatadas. Identifica todas as regras cujas conclusões unificam com o facto alvo (`encontra_regras_whynot/2`) e detalha exatamente que premissas falharam (`encontra_premissas_falsas/2`), quer sejam comparações numéricas (`avalia/2`) quer sejam factos ausentes.

#### 5. Correção de Configuração do Repositório (`.gitignore`)
- A diretiva genérica `core` na linha 46 do [`.gitignore`](../../.gitignore) fazia com que o Git ignorasse qualquer pasta de nome `core` (`prolog_engine/src/core/` e `backend_orchestrator/app/core/`). A regra foi refinada para `/core` e `core.[0-9]*`, mantendo a exclusão de core dumps mas permitindo o versionamento normal do código-fonte.

---

# FASE 2: Camada HTTP do Motor de Inferência (Prolog API) `[CONCLUÍDA]`

> [!NOTE]
> **Estado:** Concluída com sucesso em 2026-09-28.
> Endpoints REST `/inference/*` implementados, integrados no `main.pl` e validados via HTTP contra o daemon SWI-Prolog.

**Objetivo:** Expor o motor de inferência via endpoints HTTP REST no microserviço Prolog existente.

**Ficheiros a criar:**
- `prolog_engine/src/api/inference_routes.pl`

**Ficheiros a modificar (MÍNIMO):**
- `prolog_engine/src/main.pl` — adicionar 1 linha de `use_module`

**Ficheiros de referência a ler:**
- Padrão de rotas: [`prolog_engine/src/api/routes.pl`](../../prolog_engine/src/api/routes.pl) (como modelo de estrutura, parsing JSON, reply_json_dict)
- Padrão de server: [`prolog_engine/src/api/server.pl`](../../prolog_engine/src/api/server.pl)
- Arquitetura do Prolog: [`docs/architecture/prolog_engine.md`](../../docs/architecture/prolog_engine.md) (secções 2.1 e 2.2 — separação transporte vs. domínio)

---

### Subfase 2.1 — Rotas HTTP de Inferência (`inference_routes.pl`)

**Ficheiro a criar:** `prolog_engine/src/api/inference_routes.pl`

**O que fazer:**
Criar um módulo Prolog de rotas HTTP que regista endpoints para o motor de inferência, seguindo exatamente o mesmo padrão de [`routes.pl`](../../prolog_engine/src/api/routes.pl):
- Usa `library(http/http_dispatch)` e `library(http/http_json)` para registar handlers
- Lê JSON de entrada com `http_read_json_dict/2`
- Invoca o módulo core (`inference_engine`) para lógica
- Responde com `reply_json_dict/1` ou `reply_json_dict/2`
- Protege leituras JSON com `catch/3`

**Endpoints a registar:**

```prolog
:- http_handler(root('inference/load'), handle_inference_load, [method(post)]).
:- http_handler(root('inference/run'), handle_inference_run, [method(post)]).
:- http_handler(root('inference/facts'), handle_inference_facts, [method(get)]).
:- http_handler(root('inference/how'), handle_inference_how, [method(post)]).
:- http_handler(root('inference/whynot'), handle_inference_whynot, [method(post)]).
:- http_handler(root('inference/reset'), handle_inference_reset, [method(post)]).
```

**Contratos JSON de cada endpoint:**

**POST /inference/load**
- Entrada: `{"knowledge_base": "vehicles"}`
- Sucesso: `{"status": "success", "message": "Knowledge base 'vehicles' loaded successfully", "initial_facts_count": 3}`
- Erro: `{"status": "error", "message": "Knowledge base 'xyz' not found"}` com HTTP 400

**POST /inference/run**
- Entrada: `{}` (body vazio ou vazio — executa sobre a BC carregada)
- Sucesso:
```json
{
  "status": "success",
  "initial_facts_count": 3,
  "derived_facts_count": 2,
  "total_facts": 5,
  "derived_facts": [
    {"id": 4, "fact": "classe(meu_veiculo,pesado)", "rule_id": 6, "justified_by": [2]},
    {"id": 5, "fact": "pesado(meu_veiculo,camiao)", "rule_id": 2, "justified_by": [3, 4]}
  ]
}
```

**GET /inference/facts**
- Sem body
- Sucesso:
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

**POST /inference/how**
- Entrada: `{"fact_id": 4}`
- Sucesso: `{"status": "success", "fact_id": 4, "explanation": ["Fact 4 -> classe(meu_veiculo,pesado) concluded by rule 6", "Based on facts: [2]", "Fact 2 -> peso(meu_veiculo,4500) was an initial fact"]}`

**POST /inference/whynot**
- Entrada: `{"fact": "classe(meu_veiculo,ligeiro)"}`
- Sucesso: `{"status": "success", "fact": "classe(meu_veiculo,ligeiro)", "explanation": [...]}`

**POST /inference/reset**
- Entrada: `{}` (body vazio)
- Sucesso: `{"status": "success", "message": "Inference engine session reset"}`

---

### Subfase 2.2 — Integração no Entry Point (`main.pl`)

**Ficheiro a modificar:** [`prolog_engine/src/main.pl`](../../prolog_engine/src/main.pl)

**O que fazer:**
Adicionar **exatamente 1 linha** de `use_module` para carregar o novo módulo de rotas de inferência. O registo dos handlers HTTP no dispatch é automático pelas diretivas `:- http_handler(...)` no ficheiro `inference_routes.pl`.

**Modificação precisa:**

Na secção de imports do `main.pl` (após a linha 16), adicionar:
```prolog
:- use_module(api/inference_routes, []).   % Inference engine HTTP endpoints (modular plug-in)
```

> [!TIP]
> **Para desativar o motor:** Comentar esta única linha com `%` desativa completamente todos os endpoints `/inference/*`, sem qualquer efeito colateral nos endpoints POC existentes (`/evaluate`).

### Detalhes da Implementação Realizada (Fase 2)

A Fase 2 foi concluída com êxito:
1. **Módulo de Transporte [`inference_routes.pl`](../../prolog_engine/src/api/inference_routes.pl):**
   - Registados os 6 handlers REST via `http_dispatch:http_handler/3`:
     - `POST /inference/load`: Carrega a base de conhecimento dinâmica (e.g. `vehicles`), validando existência e retornando a contagem de factos iniciais.
     - `POST /inference/run`: Executa o ciclo de dedução forward-chaining, suportando pedidos com body vazio ou `{}` e retornando os factos derivados e métricas de execução.
     - `GET /inference/facts`: Devolve o conjunto integral de factos ativos na memória de trabalho.
     - `POST /inference/how`: Constrói a cadeia de rastreabilidade causal recursiva de um facto (`fact_id`).
     - `POST /inference/whynot`: Identifica regras candidatas e premisas falsas para um termo de facto (`fact`).
     - `POST /inference/reset`: Limpa factos dinâmicos e metaconhecimento em sessão.
   - Robustez de deserialização com predicado auxiliar `read_json_or_empty/3` que tolera payloads vazios (EOF de stream) sem erro e rejeita JSONs sintaticamente malformados com HTTP 400.
2. **Integração no Entry Point [`main.pl`](../../prolog_engine/src/main.pl):**
   - Adicionada a diretiva `:- use_module(api/inference_routes, []).` sem conflito com o endpoint legado `/evaluate`.
3. **Validação de Testes:**
   - Testes unitários de regras ([`test_rules.pl`](../../prolog_engine/tests/test_rules.pl)) e integração da API legada ([`test_api.pl`](../../prolog_engine/tests/test_api.pl)) passaram a 100%.
   - Execução de testes HTTP contra o servidor local validando o ciclo completo (`load` -> `run` -> `facts` -> `how` -> `whynot` -> `reset` -> `facts vazio` -> `load inexistente 400`).

---

# FASE 3: Backend Python (Proxy e Orquestração) `[CONCLUÍDA]`

> [!NOTE]
> **Estado:** Concluída com sucesso em 2026-09-29.
> Todos os schemas Pydantic v2, cliente HTTP assíncrono `InferenceClient`, serviço `InferenceService`, endpoints FastAPI `/api/v1/inference/*`, toggle `INFERENCE_ENGINE_ENABLED` e injeção de dependências foram implementados e validados.

**Objetivo:** Criar a camada de proxy no backend FastAPI para expor os endpoints do motor de inferência com validação Pydantic, toggle ON/OFF e injeção de dependências.

**Ficheiros a criar:**
- `backend_orchestrator/app/schemas/inference.py`
- `backend_orchestrator/app/clients/inference_client.py`
- `backend_orchestrator/app/services/inference_service.py`
- `backend_orchestrator/app/api/v1/endpoints/inference.py`

**Ficheiros a modificar (MÍNIMO):**
- `backend_orchestrator/app/core/config.py` — adicionar campo `INFERENCE_ENGINE_ENABLED`
- `backend_orchestrator/app/api/v1/router.py` — inclusão condicional do router
- `backend_orchestrator/app/api/deps.py` — adicionar dependency provider
- `backend_orchestrator/app/main.py` — adicionar inference_client ao lifespan

**Ficheiros de referência (padrões a copiar):**
- Schema pattern: [`app/schemas/common.py`](../../backend_orchestrator/app/schemas/common.py)
- Client pattern: [`app/clients/prolog_client.py`](../../backend_orchestrator/app/clients/prolog_client.py)
- Service pattern: [`app/services/orchestrator_service.py`](../../backend_orchestrator/app/services/orchestrator_service.py)
- Endpoint pattern: [`app/api/v1/endpoints/evaluate.py`](../../backend_orchestrator/app/api/v1/endpoints/evaluate.py)
- Dependencies: [`app/api/deps.py`](../../backend_orchestrator/app/api/deps.py)
- Config: [`app/core/config.py`](../../backend_orchestrator/app/core/config.py)
- Exceptions: [`app/core/exceptions.py`](../../backend_orchestrator/app/core/exceptions.py)
- Lifespan: [`app/main.py`](../../backend_orchestrator/app/main.py) linhas 19-51

---

### Subfase 3.1 — Schemas Pydantic (`inference.py`)

**Ficheiro a criar:** `backend_orchestrator/app/schemas/inference.py`

**O que fazer:**
Criar os modelos Pydantic v2 para validação de entrada/saída dos endpoints de inferência. Seguir exatamente o padrão de [`app/schemas/common.py`](../../backend_orchestrator/app/schemas/common.py).

**Modelos a criar:**
```python
class LoadKnowledgeBaseRequest(BaseModel):
    knowledge_base: str = Field(..., min_length=1, description="Name of the knowledge base to load")

class LoadKnowledgeBaseResponse(BaseModel):
    status: str
    message: str
    initial_facts_count: int

class DerivedFactSchema(BaseModel):
    id: int
    fact: str
    rule_id: int
    justified_by: List[int | str]

class RunEngineResponse(BaseModel):
    status: str
    initial_facts_count: int
    derived_facts_count: int
    total_facts: int
    derived_facts: List[DerivedFactSchema]

class FactSchema(BaseModel):
    id: int
    fact: str

class GetFactsResponse(BaseModel):
    status: str
    facts_count: int
    facts: List[FactSchema]

class ExplainHowRequest(BaseModel):
    fact_id: int = Field(..., ge=1, description="ID of the fact to explain")

class ExplainHowResponse(BaseModel):
    status: str
    fact_id: int
    explanation: List[str]

class ExplainWhynotRequest(BaseModel):
    fact: str = Field(..., min_length=1, description="Prolog term of the fact to investigate")

class ExplainWhynotResponse(BaseModel):
    status: str
    fact: str
    explanation: List[str]

class ResetEngineResponse(BaseModel):
    status: str
    message: str
```

Todos com `from __future__ import annotations`, `Field(...)` com descriptions, `model_config` com `json_schema_extra` examples.

---

### Subfase 3.2 — Cliente HTTP (`inference_client.py`)

**Ficheiro a criar:** `backend_orchestrator/app/clients/inference_client.py`

**O que fazer:**
Criar classe `InferenceClient` seguindo EXATAMENTE o padrão de [`PrologClient`](../../backend_orchestrator/app/clients/prolog_client.py):
- Constructor com `base_url`, `timeout`, `client` opcional
- `_get_client()` com lazy initialization
- `async close()` + context manager (`__aenter__`/`__aexit__`)
- Métodos async: `load_kb()`, `run()`, `get_facts()`, `explain_how()`, `explain_whynot()`, `reset()`
- Cada método faz `client.post()`/`client.get()` contra os endpoints `/inference/*` do Prolog
- Transforma exceções `httpx` em exceções tipadas do domínio (reutilizar `PrologConnectionError`, `PrologTimeoutError`, `PrologResponseError`)

---

### Subfase 3.3 — Serviço de Inferência (`inference_service.py`)

**Ficheiro a criar:** `backend_orchestrator/app/services/inference_service.py`

**O que fazer:**
Criar classe `InferenceService` que encapsula a lógica de orquestração, seguindo o padrão de [`OrchestratorService`](../../backend_orchestrator/app/services/orchestrator_service.py):
- Recebe `InferenceClient` por injeção
- Métodos async para cada operação: `load_knowledge_base()`, `run_engine()`, `get_facts()`, `explain_how()`, `explain_whynot()`, `reset()`
- Cada método chama o cliente, mapeia a resposta raw para o schema Pydantic correspondente
- Retorna instâncias tipadas dos schemas da Subfase 3.1

---

### Subfase 3.4 — Endpoints FastAPI (`inference.py`)

**Ficheiro a criar:** `backend_orchestrator/app/api/v1/endpoints/inference.py`

**O que fazer:**
Criar o router FastAPI com os endpoints que fazem proxy para o motor Prolog, seguindo o padrão de [`evaluate.py`](../../backend_orchestrator/app/api/v1/endpoints/evaluate.py):

```python
router = APIRouter(prefix="/inference", tags=["Inference Engine"])

@router.post("/load", response_model=LoadKnowledgeBaseResponse)
@router.post("/run", response_model=RunEngineResponse)
@router.get("/facts", response_model=GetFactsResponse)
@router.post("/how", response_model=ExplainHowResponse)
@router.post("/whynot", response_model=ExplainWhynotResponse)
@router.post("/reset", response_model=ResetEngineResponse)
```

Cada endpoint:
- Usa `Depends(get_inference_service)` para injeção
- Trata `PrologConnectionError`/`PrologTimeoutError` → HTTP 503
- Trata `PrologResponseError` → HTTP 400

---

### Subfase 3.5 — Integração e Toggle

**Ficheiros a modificar:**

**1. [`app/core/config.py`](../../backend_orchestrator/app/core/config.py)** — Adicionar campo na classe `Settings` (após linha 29):
```python
INFERENCE_ENGINE_ENABLED: bool = True
```

**2. [`app/api/v1/router.py`](../../backend_orchestrator/app/api/v1/router.py)** — Inclusão condicional (após linha 12):
```python
from app.core.config import settings

if settings.INFERENCE_ENGINE_ENABLED:
    from app.api.v1.endpoints import inference
    api_v1_router.include_router(inference.router)
```

**3. [`app/api/deps.py`](../../backend_orchestrator/app/api/deps.py)** — Adicionar provider:
```python
from app.clients.inference_client import InferenceClient
from app.services.inference_service import InferenceService

def get_inference_client(request: Request) -> InferenceClient:
    if hasattr(request.app.state, "inference_client") and request.app.state.inference_client is not None:
        return request.app.state.inference_client
    return InferenceClient()

def get_inference_service(
    request: Request,
    inference_client: InferenceClient = Depends(get_inference_client),
) -> InferenceService:
    if hasattr(request.app.state, "inference_service") and request.app.state.inference_service is not None:
        return request.app.state.inference_service
    return InferenceService(inference_client=inference_client)
```

**4. [`app/main.py`](../../backend_orchestrator/app/main.py)** — Adicionar ao lifespan (após linha 44, antes do `yield`):
```python
if settings.INFERENCE_ENGINE_ENABLED:
    from app.clients.inference_client import InferenceClient
    from app.services.inference_service import InferenceService

    inference_client = InferenceClient(
        base_url=settings.PROLOG_ENGINE_URL,
        timeout=settings.PROLOG_TIMEOUT_SECONDS,
        client=http_client,
    )
    inference_service = InferenceService(inference_client=inference_client)
    app.state.inference_client = inference_client
    app.state.inference_service = inference_service
```

**Critério de validação:**
```bash
# Com INFERENCE_ENGINE_ENABLED=true (default):
curl http://localhost:8000/api/v1/inference/facts  # → 200 OK

# Com INFERENCE_ENGINE_ENABLED=false:
curl http://localhost:8000/api/v1/inference/facts  # → 404 Not Found
```

### Detalhes da Implementação Realizada (Fase 3)

A Fase 3 foi integralmente implementada com sucesso:

1. **Modelos Pydantic v2 ([`app/schemas/inference.py`](../../backend_orchestrator/app/schemas/inference.py)):**
   - Implementados 11 schemas canónicos com validação estrita, exemplos OpenAPI ricos (`json_schema_extra`), restrições numéricas (`ge=1`, `ge=0`) e de comprimento (`min_length=1`):
     - `LoadKnowledgeBaseRequest` e `LoadKnowledgeBaseResponse`
     - `DerivedFactSchema` e `RunEngineResponse`
     - `FactSchema` e `GetFactsResponse`
     - `ExplainHowRequest` e `ExplainHowResponse`
     - `ExplainWhynotRequest` e `ExplainWhynotResponse`
     - `ResetEngineResponse`

2. **Cliente HTTP Assíncrono ([`app/clients/inference_client.py`](../../backend_orchestrator/app/clients/inference_client.py)):**
   - Implementada a classe `InferenceClient` com connection pooling, suporte a context manager assíncrono (`__aenter__`/`__aexit__`), timeouts configuráveis e tradução resiliente de exceções de rede/HTTP em exceções tipadas de domínio (`PrologConnectionError`, `PrologTimeoutError`, `PrologResponseError`).
   - Métodos expostos: `load_kb/1`, `run/0`, `get_facts/0`, `explain_how/1`, `explain_whynot/1` e `reset/0`.

3. **Camada de Serviço ([`app/services/inference_service.py`](../../backend_orchestrator/app/services/inference_service.py)):**
   - Implementada a classe `InferenceService` isolando a lógica de negócio e convertendo payloads de transporte não tipados em instâncias tipadas e validadas dos schemas Pydantic correspondentes.

4. **Endpoints FastAPI ([`app/api/v1/endpoints/inference.py`](../../backend_orchestrator/app/api/v1/endpoints/inference.py)):**
   - Criado o router `/inference` com 6 operações REST documentadas para Swagger/OpenAPI:
     - `POST /api/v1/inference/load`
     - `POST /api/v1/inference/run`
     - `GET /api/v1/inference/facts`
     - `POST /api/v1/inference/how`
     - `POST /api/v1/inference/whynot`
     - `POST /api/v1/inference/reset`
   - Injeção via `Depends(get_inference_service)` e mapeamento robusto de erros: falhas de conectividade/timeout produzem HTTP 503, erros reportados pelo motor produzem HTTP 400 e violações de contrato produzem HTTP 422.

5. **Injeção de Dependências e Configuração de Toggle:**
   - [`app/core/config.py`](../../backend_orchestrator/app/core/config.py): Adicionada a flag de configuração `INFERENCE_ENGINE_ENABLED: bool = True`.
   - [`app/api/deps.py`](../../backend_orchestrator/app/api/deps.py): Implementados os providers `get_inference_client` e `get_inference_service`.
   - [`app/api/v1/router.py`](../../backend_orchestrator/app/api/v1/router.py): Montagem condicional do router de inferência conforme o valor de `settings.INFERENCE_ENGINE_ENABLED`.
   - [`app/main.py`](../../backend_orchestrator/app/main.py): Registo de `inference_client` e `inference_service` no ciclo de vida `lifespan` (`app.state`).

---

# FASE 4: Testes Automatizados `[CONCLUÍDA]`

> [!NOTE]
> **Estado:** Concluída com sucesso em 2026-09-29.
> Suíte completa de 8 testes PLUnit em SWI-Prolog e 36 testes Pytest em Python cobrindo cliente, serviço e endpoints da inferência, totalizando 89 testes automatizados no orquestrador (100% aprovados).

**Objetivo:** Criar testes unitários e de integração para o motor de inferência, em ambas as camadas (Prolog + Python).

**Ficheiros a criar:**
- `prolog_engine/tests/test_inference_engine.pl`
- `backend_orchestrator/tests/test_inference_client.py`
- `backend_orchestrator/tests/test_inference_service.py`
- `backend_orchestrator/tests/test_inference_endpoints.py`

**Ficheiros de referência (padrões a copiar):**
- Prolog tests: [`prolog_engine/tests/test_rules.pl`](../../prolog_engine/tests/test_rules.pl)
- Python conftest: [`backend_orchestrator/tests/conftest.py`](../../backend_orchestrator/tests/conftest.py)
- Client tests: [`backend_orchestrator/tests/test_prolog_client.py`](../../backend_orchestrator/tests/test_prolog_client.py)
- Service tests: [`backend_orchestrator/tests/test_orchestrator.py`](../../backend_orchestrator/tests/test_orchestrator.py)
- Testing strategy: [`docs/development/testing.md`](../../docs/development/testing.md)

---

### Subfase 4.1 — Testes PLUnit do Motor de Inferência

**Ficheiro a criar:** `prolog_engine/tests/test_inference_engine.pl`

**Cenários de teste a cobrir:**
1. `load_knowledge_base(vehicles)` carrega sem erros
2. `run_engine(Result)` com factos de veiculos2 — resultado tem 2 factos derivados
3. `get_all_facts(Facts)` retorna 5 factos (3 iniciais + 2 derivados)
4. `explain_how(4, Explanation)` retorna explicação não-vazia
5. `explain_how(1, Explanation)` para facto inicial retorna "initial fact"
6. `explain_whynot(classe(meu_veiculo,ligeiro), Explanation)` retorna premissas falsas
7. `reset_engine` limpa todos os factos
8. `load_knowledge_base(inexistente)` falha graciosamente

---

### Subfase 4.2 — Testes Pytest do Backend Python

**Ficheiros a criar:**

**`test_inference_client.py`** — Testes unitários com mocks httpx:
- `test_load_kb_success`, `test_load_kb_connection_error`, `test_load_kb_timeout`
- `test_run_engine_success`
- `test_get_facts_success`
- `test_explain_how_success`
- `test_explain_whynot_success`

**`test_inference_service.py`** — Testes unitários com mock InferenceClient:
- Cada operação retorna o schema tipado correto

**`test_inference_endpoints.py`** — Testes de integração com async_client:
- Cada endpoint responde com o status code e schema esperado
- Endpoint desativado retorna 404 quando `INFERENCE_ENGINE_ENABLED=false`

Adicionar ao `conftest.py` as fixtures de mock:
```python
@pytest.fixture
def mock_inference_client() -> AsyncMock:
    mock = AsyncMock(spec=InferenceClient)
    # ... configure default returns
    return mock
```

**Critério de validação:**
```bash
cd prolog_engine && swipl -g "run_tests" -t halt tests/test_inference_engine.pl
cd backend_orchestrator && python -m pytest tests/test_inference*.py -v
```

### Detalhes da Implementação Realizada (Fase 4)

A Fase 4 foi integralmente implementada com sucesso:

1. **Testes Unitários PLUnit do Motor de Inferência ([`test_inference_engine.pl`](../../prolog_engine/tests/test_inference_engine.pl)):**
   - Implementados 8 testes validando o ciclo completo de inferência determinística (sem choicepoints residuais):
     - `load_vehicles_kb_success`: Carrega base `vehicles` e afere 3 factos iniciais.
     - `run_engine_derives_facts`: Executa dedução com 2 factos inferidos e 5 factos no total.
     - `get_all_facts_after_run`: Valida presença de factos iniciais e deduzidos (`classe/2`, `pesado/2`).
     - `explain_how_derived_fact`: Verifica rastreio causal recursivo e referência à regra 6.
     - `explain_how_initial_fact`: Confirma identificação de factos primários/iniciais.
     - `explain_whynot_false_premise`: Valida deteção de falha na premissa da regra 7 (`peso =< 3500`).
     - `reset_engine_clears_facts`: Assegura limpeza total de memória de trabalho.
     - `load_nonexistent_kb_fails_gracefully`: Confirma captura graciosa de `existence_error`.
   - Execução: 8 testes aprovados em 0.034s (`swipl -g "run_tests" -t halt tests/test_inference_engine.pl`).

2. **Fixtures Pytest Partilhadas ([`conftest.py`](../../backend_orchestrator/tests/conftest.py)):**
   - Adicionadas fixtures `mock_inference_client` (com retornos estruturados pré-configurados) e `inference_service`.
   - Registadas sobreposições de dependências `app.dependency_overrides` e limpeza em `async_client`.

3. **Testes Unitários de Cliente HTTP ([`test_inference_client.py`](../../backend_orchestrator/tests/test_inference_client.py)):**
   - 14 testes cobrindo `load_kb`, `run`, `get_facts`, `explain_how`, `explain_whynot`, `reset`, tradução de exceções (`PrologConnectionError`, `PrologTimeoutError`, `PrologResponseError`), tratamento de erros de rede genéricos e ciclo de vida de context manager assíncrono.

4. **Testes Unitários de Camada de Serviço ([`test_inference_service.py`](../../backend_orchestrator/tests/test_inference_service.py)):**
   - 7 testes validando o mapeamento estrito dos payloads não tipados para instâncias tipadas dos schemas Pydantic v2 correspondentes e inicialização resiliente.

5. **Testes de Integração de Endpoints REST ([`test_inference_endpoints.py`](../../backend_orchestrator/tests/test_inference_endpoints.py)):**
   - 15 testes de integração cobrindo respostas 200 OK para todas as rotas `/api/v1/inference/*`, validações de modelo 422, mapeamentos de erro HTTP 400 e 503, e validação de toggle `INFERENCE_ENGINE_ENABLED=False` resultando em HTTP 404.

6. **Validação Global:**
   - Suíte de testes do backend orquestrador: **89 testes aprovados** (53 existentes + 36 novos) em 1.55s.
   - Suíte de testes do motor Prolog: **8 novos testes PLUnit aprovados**, juntamente com os testes legados de regras e API.

---

# FASE 5: Documentação e Docker `[CONCLUÍDA]`

> [!NOTE]
> **Estado:** Concluída com sucesso em 2026-09-29.
> Atualizada toda a documentação técnica de arquitetura, contratos de API e variáveis de ambiente, verificado o Dockerfile do Prolog, adicionada a variável `INFERENCE_ENGINE_ENABLED` ao `docker-compose.yml` e arquivado o plano em `docs/history/inference_engine_implementation_plan.md`.

**Objetivo:** Atualizar a documentação técnica existente e o Dockerfile para incluir os novos ficheiros.

**Ficheiros a criar:**
- `docs/history/inference_engine_implementation_plan.md` — mover este plano para o arquivo histórico

**Ficheiros a modificar:**
- `docs/architecture/prolog_engine.md` — adicionar secção sobre o motor de inferência forward-chaining
- `docs/architecture/system_overview.md` — atualizar diagrama com novos endpoints
- `docs/api/prolog_engine_api.md` — documentar endpoints `/inference/*`
- `docs/api/orchestrator_api_v1.md` — documentar endpoints `/api/v1/inference/*`
- `docs/api/schemas.md` — adicionar novos schemas Pydantic
- `docs/deployment/environment_variables.md` — documentar `INFERENCE_ENGINE_ENABLED`
- `prolog_engine/Dockerfile` — garantir que copia `src/core/inference/` para o contentor
- `docker-compose.yml` — adicionar `INFERENCE_ENGINE_ENABLED=true` às env vars do orchestrator

---

### Subfase 5.1 — Atualizar Dockerfile do Prolog

**Ficheiro:** `prolog_engine/Dockerfile`

O Dockerfile atual já copia `src/` inteiro com `COPY src/ /app/src/` (linha 15), portanto os novos ficheiros em `src/core/inference/` são automaticamente incluídos de forma recursiva. Verificado e validado sem necessidade de alterações.

### Subfase 5.2 — Atualizar `docker-compose.yml`

**Ficheiro:** `docker-compose.yml`

Adicionada a variável `INFERENCE_ENGINE_ENABLED=true` à secção `environment` do serviço `orchestrator` no ficheiro `docker-compose.yml`, e sincronizado também o ficheiro `backend_orchestrator/.env.example`.

### Subfase 5.3 — Atualizar Documentação Técnica

Documentação técnica atualizada em português (pt-PT) com hiperligações relativas ao repositório:
- `docs/architecture/prolog_engine.md`: Atualizada a árvore de ficheiros, descrições de camadas e adicionada a Secção 6 detalhando o motor pericial forward-chaining, operadores customizados, ciclo dedutivo e predicados públicos.
- `docs/architecture/system_overview.md`: Atualizado o diagrama Mermaid com as rotas `/api/v1/inference/*` e `/inference/*`, e documentadas as novas responsabilidades do orquestrador e motor Prolog.
- `docs/api/prolog_engine_api.md`: Documentada a Secção 5 com todos os 6 endpoints `/inference/*` (`load`, `run`, `facts`, `how`, `whynot`, `reset`) com exemplos de pedidos e respostas.
- `docs/api/orchestrator_api_v1.md`: Documentada a Secção 4 cobrindo os 6 endpoints `/api/v1/inference/*`, o comportamento do feature toggle `INFERENCE_ENGINE_ENABLED` (HTTP 404 quando desativado) e tratamento de erros.
- `docs/api/schemas.md`: Documentada a Secção 6 detalhando os 11 modelos Pydantic v2 do ficheiro `backend_orchestrator/app/schemas/inference.py`.
- `docs/deployment/environment_variables.md`: Documentada a variável `INFERENCE_ENGINE_ENABLED` na tabela de configurações do orquestrador.

### Subfase 5.4 — Arquivar Plano de Implementação

Criada a cópia histórica do plano de implementação integralmente validado em `docs/history/inference_engine_implementation_plan.md`.

---

## RESUMO DE TODAS AS FASES

| Fase | Descrição | Subfases | Ficheiros Novos | Ficheiros Modificados |
|:---:|:---|:---:|:---:|:---:|
| **1** | Motor Core Prolog (Domínio) | 1.1–1.2 | 2 | 0 |
| **2** | Camada HTTP Prolog (API) | 2.1–2.2 | 1 | 1 |
| **3** | Backend Python (Proxy) | 3.1–3.5 | 4 | 4 |
| **4** | Testes Automatizados | 4.1–4.2 | 4 | 1 |
| **5** | Documentação e Docker | 5.1–5.4 | 1 | ~8 |
| **Total** | | **15** | **12** | **~14** |
