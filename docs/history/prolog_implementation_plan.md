# Histórico de Implementação: Micro-serviço SWI-Prolog (POC)
### *Plano de Execução e Registo de Fases — 100% Concluído e Validado*

> [!NOTE]
> **Documento de Arquivo Histórico:** Este documento constitui o registo histórico do plano de implementação e relatório de execução da Prova de Conceito (POC) do micro-serviço SWI-Prolog (Fases 1 a 4, concluídas a 23 de Setembro de 2026).
> Para a documentação técnica consolidada e atualizada de referência, consulte:
> * [Arquitetura Interna do Motor Prolog](../architecture/prolog_engine.md)
> * [API Interna do Motor Prolog (POST /evaluate)](../api/prolog_engine_api.md)
> * [Contentorização e Dockerfiles](../deployment/docker.md)
> * [Estratégia e Execução de Testes](../development/testing.md)

---

# PLANO DE IMPLEMENTAÇÃO ORIGINAL: MICRO-SERVIÇO PROLOG (REST API POC)

**Instruções para o Agente IA:**
Atua como um Engenheiro de Software Sénior. Este documento descreve o plano passo-a-passo para criar a infraestrutura de um motor de inferência em SWI-Prolog, exposto como uma REST API dentro de um contentor Docker. 
* **Princípios:** Aplica Clean Architecture, separação de preocupações (Rotas != Lógica de Negócio) e código modular.
* **Idioma do Código e Commits:** Inglês para código/variáveis; Português (pt-PT) para documentação e respostas no chat.
* **Execução:** Não implementes todas as fases de uma vez. Aguarda que o utilizador peça a "Fase X" e fornece os ficheiros completos e compiláveis para essa fase.

---

## Estrutura de Diretórios Alvo
O repositório deverá obedecer à seguinte estrutura base:

```text
/
├── docs/
│ ├── architecture.md # Desenho da solução e decisões arquiteturais
│ └── api_contracts.md # Contratos JSON (Input/Output)
├── prolog_engine/
│ ├── Dockerfile
│ └── src/
│ ├── api/ # Camada de transporte HTTP
│ │ ├── server.pl # Configuração do daemon HTTP
│ │ └── routes.pl # Definição de endpoints e parsing de JSON
│ ├── core/ # Camada de domínio / regras de negócio
│ │ └── rules.pl # Regras lógicas (Prolog puro, sem dependências web)
│ └── main.pl # Entry point da aplicação Prolog
```

---

## FASE 1: Setup Base e Documentação [CONCLUÍDO]
**Status:** Concluído
**Objetivo:** Criar a fundação do projeto e iniciar a documentação arquitetural.

* [x] **Subfase 1.1:** Cria a árvore de diretórios descrita acima. Deixa os ficheiros `.pl` vazios por agora.
* [x] **Subfase 1.2:** Cria o ficheiro `docs/architecture.md`. Documenta que o sistema usa SWI-Prolog para expor uma API REST, isolando a camada HTTP (`api/`) da camada lógica (`core/`).
* [x] **Subfase 1.3:** Cria o ficheiro `docs/api_contracts.md`. Define um contrato JSON genérico de teste:
    * *Request:* `{"scenario": "test", "value": 42}`
    * *Response:* `{"status": "success", "decision": "approved", "justification": ["Value is 42", "Dummy rule matched"]}`

### Relatório de Implementação da Fase 1:
1. **Estrutura de Diretórios e Ficheiros Base (Subfase 1.1):**
   * Criadas as pastas `docs/`, `prolog_engine/`, `prolog_engine/src/api/` e `prolog_engine/src/core/`.
   * Inicializados os ficheiros base:
     * `prolog_engine/src/api/server.pl`: Ficheiro destinado à inicialização do servidor HTTP e gestão do daemon.
     * `prolog_engine/src/api/routes.pl`: Ficheiro destinado ao registo dos endpoints e tratamento de I/O em JSON.
     * `prolog_engine/src/core/rules.pl`: Ficheiro destinado à base de conhecimento e regras de diagnóstico puras em Prolog.
     * `prolog_engine/src/main.pl`: Ponto de entrada da aplicação para arranque do micro-serviço.
     * `prolog_engine/Dockerfile`: Ficheiro base inicial reservado para a contentorização (Fase 4).
2. **Documentação Arquitetural (Subfase 1.2):**
   * Criado o ficheiro `docs/architecture.md` em português (pt-PT), detalhando:
     * Princípios de *Clean Architecture* e separação estrita de preocupações (a camada `api/` gere o transporte HTTP e serialização; a camada `core/` detém a lógica de negócio pura sem dependências externas).
     * O papel do micro-serviço SWI-Prolog como motor de diagnóstico pericial integrado com o backend orquestrador (FastAPI).
     * Diagrama de comunicação entre Frontend, Orquestrador FastAPI e o motor Prolog.
     * O requisito crítico de explicabilidade e transparência através de justificações explícitas no diagnóstico.
3. **Contratos de API (Subfase 1.3):**
   * Criado o ficheiro `docs/api_contracts.md` formalizando a interface JSON do endpoint `POST /evaluate`.
   * Especificados esquemas, tipos de dados e exemplos completos para o caso base de teste:
     * Pedido: `{"scenario": "test", "value": 42}`
     * Resposta: `{"status": "success", "decision": "approved", "justification": ["Value is 42", "Dummy rule matched"]}`
     * Exemplo adicional de resposta para rejeição, formato de respostas de erro e mapeamento futuro para cenários de retalho.

## FASE 2: Lógica Core (Domain Layer) [CONCLUÍDO]
**Status:** Concluído
**Objetivo:** Criar o motor lógico isolado, sem qualquer conhecimento de HTTP ou JSON.

* [x] **Subfase 2.1:** Implementa `src/core/rules.pl`.
    * Define o módulo: `:- module(rules, [evaluate_scenario/3]).`
    * Cria um predicado `evaluate_scenario(+ScenarioDict, -Decision, -ExplanationList)`.
    * Implementa uma regra simples de *dummy match* (ex: se o valor for 42, aprova e gera justificação; caso contrário, rejeita). Usa *dicts* nativos do Prolog para ler os dados de entrada.
* [x] **Subfase 2.2:** Atualiza o `docs/architecture.md` para refletir o uso de *Prolog Dicts* na passagem de dados entre a camada API e a camada Core.

### Relatório de Implementação da Fase 2:
1. **Implementação da Camada de Domínio (`prolog_engine/src/core/rules.pl` - Subfase 2.1):**
   * Definido o módulo Prolog modular e isolado: `:- module(rules, [evaluate_scenario/3]).` sem dependências de bibliotecas HTTP ou de transporte.
   * Implementado o predicado principal de inferência `evaluate_scenario(+ScenarioDict, -Decision, -ExplanationList)` suportando dados baseados em dicionários nativos SWI-Prolog (*dicts*):
     * **Regra de Aprovação (*Dummy Match*):** Avalia se o dicionário é válido (`is_dict/1`) e se a propriedade `value` extraída de forma segura via `get_dict/3` é numericamente igual a 42 (`Value =:= 42`). Retorna a decisão `approved` e as justificações `["Value is 42", "Dummy rule matched"]`.
     * **Regra de Rejeição por Valor Incorreto:** Acionada quando `value` está presente mas difere de 42. Retorna a decisão `rejected` e `["Value is not 42", "Default fallback rule applied"]`.
     * **Regra de Rejeição por Campo Ausente:** Acionada deterministicamente quando o atributo `value` não é fornecido no dicionário de entrada. Retorna `rejected` e `["Missing 'value' field in scenario", "Default fallback rule applied"]`.
     * **Regra de Salvaguarda Estrutural:** Trata entradas malformadas que não sejam dicionários Prolog, retornando a decisão `error` e mensagem explicativa de formato inválido.
   * Criada a suíte de testes unitários automatizados com a biblioteca `library(plunit)` em `prolog_engine/tests/test_rules.pl`, cobrindo 7 cenários distintos (aprovação inteira/float, rejeição por valor divergente, rejeição por tipo não-numérico, ausência de chave e argumentos inválidos), todos validados com 100% de sucesso.
2. **Atualização da Arquitetura (`docs/architecture.md` - Subfase 2.2):**
   * Adicionada a secção 2.4 (*Passagem de Dados entre Camadas: O Papel dos Prolog Dicts*), documentando:
     * A adoção de *Prolog Dicts* como a estrutura canónica interna de transferência de dados (DTO) entre a camada de transporte e a camada core.
     * O desacoplamento absoluto da lógica de negócio em relação ao protocolo HTTP e à serialização JSON.
     * A extração declarativa e segura de atributos com `get_dict/3` e `is_dict/1`.
     * A rastreabilidade das justificações (`justification`) através de listas nativas de termos/strings, alinhando a implementação com o requisito primordial de explicabilidade no domínio pericial de retalho.

## FASE 3: Camada de API e Transporte [CONCLUÍDO]
**Status:** Concluído
**Objetivo:** Configurar o SWI-Prolog para escutar pedidos HTTP POST, converter JSON em *Prolog Dicts*, invocar a lógica e devolver JSON.

* [x] **Subfase 3.1:** Implementa `src/api/server.pl`.
    * Define o módulo e importa as bibliotecas necessárias: `http/thread_httpd`, `http/http_dispatch`.
    * Cria o predicado `server_start/1` para iniciar o servidor numa porta recebida como argumento.
* [x] **Subfase 3.2:** Implementa `src/api/routes.pl`.
    * Importa `http/http_json` e define a rota usando `:- http_handler(root(evaluate), handle_evaluate, [method(post)]).`
    * Cria o handler `handle_evaluate/1` que: lê o JSON de entrada (`http_read_json_dict`), chama `rules:evaluate_scenario/3`, e devolve a resposta com `reply_json_dict/1`.
* [x] **Subfase 3.3:** Implementa `src/main.pl`.
    * Este será o script de arranque. Deve carregar os ficheiros da `api` e do `core`.
    * Deve ler uma variável de ambiente `PORT` (com fallback para 8080) e invocar `server_start(Port)`.
    * Deve incluir uma diretiva de *loop* ou bloqueio para manter o processo Docker vivo (ex: `http_daemon` ou um simples `thread_get_message`).
* [x] **Subfase 3.4:** Adiciona no `docs/architecture.md` o fluxo do ciclo de vida do request.

### Relatório de Implementação da Fase 3:
1. **Gestão do Daemon HTTP (`prolog_engine/src/api/server.pl` - Subfase 3.1):**
   * Criado o módulo `server` com os predicados exportados `server_start/1` e `server_stop/1`.
   * Integradas as bibliotecas nativas de transporte do SWI-Prolog: `library(http/thread_httpd)` e `library(http/http_dispatch)`.
   * Suporte para inicialização e paragem robusta do servidor quer com portas inteiras quer com átomos numéricos, mantendo isolada a gestão do socket TCP e do daemon multi-threaded relativamente à definição de endpoints e à lógica de domínio.
2. **Encaminhamento e Despacho REST (`prolog_engine/src/api/routes.pl` - Subfase 3.2):**
   * Criado o módulo `routes` com exportação do predicado `handle_evaluate/1`.
   * Registada a rota POST via diretiva `:- http_handler(root(evaluate), handle_evaluate, [method(post)]).` utilizando o mecanismo de dispatch da biblioteca HTTP.
   * Desserialização automática do corpo HTTP JSON para dicionários Prolog através de `http_read_json_dict/2`.
   * Invocação determinística do motor pericial através de `rules:evaluate_scenario/3`.
   * Serialização e formatação da resposta canónica com `reply_json_dict/1` (e `reply_json_dict/2` para tratamento de erros com status HTTP 400 Bad Request em conformidade com o contrato em `docs/api_contracts.md`).
   * Mecanismo de salvaguarda via `catch/3` para intercetação e tratamento elegante de payloads JSON malformados ou corrompidos.
3. **Ponto de Entrada e Orquestração (`prolog_engine/src/main.pl` - Subfase 3.3):**
   * Criado o módulo `main` responsável pela inicialização do micro-serviço.
   * Carregamento modular das dependências das camadas de transporte (`api/server`, `api/routes`) e domínio (`core/rules`).
   * Implementado o predicado `get_port/1` com leitura dinâmica da variável de ambiente `PORT` e fallback seguro para a porta 8080 caso não esteja definida ou possua formato inválido.
   * Implementado o predicado `main/0` com banner informativo no arranque, inicialização do daemon com `server_start(Port)` e bloqueio da thread principal com `thread_get_message(_)` em conjunto com captura de sinal para paragem graciosa (`server_stop(Port)`), garantindo a persistência do processo em contentores Docker.
   * Adicionada a diretiva `:- initialization(main, main).` para execução direta via `swipl src/main.pl`.
4. **Atualização da Arquitetura e Ciclo de Vida do Pedido (`docs/architecture.md` - Subfase 3.4):**
   * Adicionada a nova secção 3 (*Fluxo do Ciclo de Vida do Pedido (Request-Response Lifecycle)*) contendo:
     * Diagrama de sequência completo em formato Mermaid ilustrando a interação temporal e divisão de responsabilidades entre o Orquestrador FastAPI, `server.pl` (`thread_httpd`), `routes.pl` (`http_dispatch`), e `rules.pl`.
     * Explicação passo-a-passo detalhada das 5 etapas: Receção e Alocação de Conexão na pool de threads, Encaminhamento de Rota, Leitura e Desserialização JSON, Dedução Lógica no Domínio e Formatação/Serialização da Resposta.
5. **Verificação e Testes Automatizados:**
   * Criada a suíte de testes de integração em `prolog_engine/tests/test_api.pl` recorrendo a `library(plunit)` e `library(http/http_client)`.
   * Validados 5 testes automatizados cobrindo pedidos com aprovação (`value = 42`), rejeição por valor divergente (`value = 15`), rejeição por omissão de atributo, intercetação de JSON inválido com HTTP 400 e fallback de porta do ambiente.
   * Teste de fumo ponta-a-ponta efetuado com arranque real do micro-serviço em daemon na porta 8085 e submissão de pedidos HTTP POST através de PowerShell / curl, confirmando total conformidade com a especificação da API.

## FASE 4: Contentorização (Docker) [CONCLUÍDO]
**Status:** Concluído
**Objetivo:** Isolar o serviço Prolog usando a imagem oficial para garantir consistência em qualquer ambiente.

* [x] **Subfase 4.1:** Implementa o `prolog_engine/Dockerfile`.
    * Usa a imagem base `swipl:latest`.
    * Copia a pasta `src` para `/app/src`.
    * Define `/app` como *working directory*.
    * Expõe a porta `8080`.
    * Define o comando de arranque (ex: `CMD ["swipl", "-s", "src/main.pl", "-g", "main", "-t", "halt"]` assumindo que criaste um predicado `main/0` no `main.pl`).
* [x] **Subfase 4.2:** Atualiza o `docs/architecture.md` com instruções práticas de linha de comandos (CLI) para construir a imagem Docker (`docker build ...`) e corrê-la, incluindo um exemplo de comando `curl` para testar o endpoint.

### Relatório de Implementação da Fase 4:
1. **Contentorização e Dockerfile (`prolog_engine/Dockerfile` - Subfase 4.1):**
   * Criado o [`prolog_engine/Dockerfile`](../../prolog_engine/Dockerfile) com base na imagem oficial `swipl:latest`.
   * Configurado o diretório de trabalho `/app` e cópia isolada do código-fonte da aplicação (`src/` para `/app/src/`).
   * Declarada a exposição da porta de rede `8080` e definida a variável de ambiente predefinida `ENV PORT=8080`.
   * Configurado o comando de arranque padrão `CMD ["swipl", "-s", "src/main.pl", "-g", "main", "-t", "halt"]` para acionar o predicado de orquestração `main:main/0` com paragem graciosa e determinística.
   * Criado o ficheiro [`prolog_engine/.dockerignore`](../../prolog_engine/.dockerignore) excluindo ficheiros temporários, testes, documentação e metadados de controlo de versões, otimizando o contexto do build.
2. **Documentação e Guia Operacional CLI (`docs/architecture.md` - Subfase 4.2):**
   * Adicionada a Secção 6 (*Contentorização e Operação (Docker & CLI)*) ao documento arquitetural [`docs/architecture/prolog_engine.md`](../architecture/prolog_engine.md).
   * Disponibilizadas instruções passo-a-passo e comandos CLI completos para:
     * Construção da imagem Docker (`docker build`) a partir da raiz do repositório ou da pasta `prolog_engine/`.
     * Execução do contentor em modo *detached* (`docker run -d --name prolog-service -p 8080:8080 prolog-engine`), com suporte a portas customizadas via `PORT`.
     * Monitorização de logs em tempo real (`docker logs -f prolog-service`) e ciclo de vida de paragem e remoção do contentor (`docker stop`, `docker rm`).
     * Testes práticos com `curl` (para ambientes Bash/Linux/macOS) e `Invoke-RestMethod` / `curl.exe` (para Windows PowerShell), cobrindo aprovação (`value = 42`), rejeição (`value = 15`) e payload JSON malformado com HTTP 400 Bad Request.

---

## CONCLUSÃO GLOBAL DO POC [CONCLUÍDO A 100%]
**Status Geral:** 100% Concluído e Validado 
**Data de Conclusão:** 2026-09-23

Todas as 4 fases planeadas para a infraestrutura do micro-serviço SWI-Prolog (REST API POC) foram executadas com rigor e sucesso integral:

### Matriz de Conformidade e Entregáveis

| Entregável / Fase | Estado | Descrição / Ficheiros | Validação |
| :--- | :---: | :--- | :--- |
| **Fase 1: Setup e Docs** | Concluído | `docs/architecture.md`, `docs/api_contracts.md`, estrutura de pastas | Documentação arquitetural e contratos de API formalizados |
| **Fase 2: Lógica Core** | Concluído | `prolog_engine/src/core/rules.pl`, `prolog_engine/tests/test_rules.pl` | 7 testes unitários `plunit` validados (100% sucesso) |
| **Fase 3: API & Transporte** | Concluído | `prolog_engine/src/api/server.pl`, `routes.pl`, `main.pl`, `tests/test_api.pl` | 5 testes de integração `plunit` e teste de fumo REST |
| **Fase 4: Contentorização** | Concluído | `prolog_engine/Dockerfile`, `prolog_engine/.dockerignore`, secção CLI docs | Build e runtime Docker com comandos e exemplos curl documentados |

### Resultados da Suíte de Testes Automatizados
- **Testes Unitários da Camada Core (`tests/test_rules.pl`):** 7/7 passaram em 0.016s CPU (cenários de aprovação exata/float, rejeição por valor divergente, tipos não-numéricos, ausência de parâmetros e salvaguardas).
- **Testes de Integração da Camada de API (`tests/test_api.pl`):** 5/5 passaram em 0.125s CPU (rotas `/evaluate`, parsing JSON, respostas canónicas HTTP 200 e interceção de payloads malformados com HTTP 400 Bad Request).

### Próximos Passos (Transição para o Sistema Global de Retalho):
1. **Integração com Backend Orquestrador (FastAPI):** Ligação do cliente HTTP Python para submissão de cenários ao endpoint `/evaluate`.
2. **Expansão da Base de Conhecimento Pericial:** Evolução das regras de demonstração para as heurísticas reais de devoluções e trocas (prazos, recibos, estado do artigo, biohazard, etc., definidas com o perito Dustin Hopper em `docs/domain/expert_knowledge.md`).
3. **Motor Drools:** Implementação em paralelo do segundo motor pericial (Java/Drools) coordenado pelo FastAPI.
