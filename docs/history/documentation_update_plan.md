# Plano de Atualização da Documentação Técnica -- Motor Drools
### *Integração do Micro-serviço `drools_engine` (Java 21 / Spring Boot 3 / Apache KIE Drools 8+)*

---

## 0. Contexto e Motivação

O repositório **meia-equipa3-challenge1-26_27** incorporou recentemente um terceiro micro-serviço -- o motor de inferência baseado em regras de produção **Drools** (`drools_engine/`). O micro-serviço está funcional, contentorizado e já integrado no `docker-compose.yml`, porém a documentação técnica centralizada em `docs/` ainda não reflete esta adição.

A documentação existente segue normas rigorosas e consistentes que devem ser preservadas:

- **Idioma:** Português de Portugal (pt-PT) para toda a prosa; identificadores e código em inglês.
- **Estrutura de secções numerada:** Cada documento usa cabeçalhos numerados hierarquicamente (ex.: `## 1. Visão Geral`, `### 2.1 Subitem`).
- **Subtítulo padronizado:** Linha 2 de cada documento com o formato `### *Sistema Pericial de Diagnóstico para Devoluções e Trocas no Retalho*` (itálico).
- **Diagramas Mermaid integrados:** Usados extensivamente para fluxogramas, diagramas de sequência, class diagrams e grafos de navegação.
- **Tabelas detalhadas:** Campos, tipos, validações e descrições em formato de tabela Markdown.
- **Exemplos cURL/PowerShell:** Todos os endpoints incluem exemplos de teste em Bash e PowerShell.
- **Referências cruzadas:** Cada documento termina com secção "Documentos Relacionados" com links relativos.
- **Ausência de emojis:** Nenhum documento existente utiliza emojis; esta regra deve ser mantida estritamente.
- **Blocos de código anotados:** Com linguagem identificada (`json`, `bash`, `java`, `yaml`, etc.).

### Inventário de Gaps Identificados

| Secção (`docs/`) | Documento(s) Afetado(s) | Gap |
|:---|:---|:---|
| `docs/README.md` | Indice geral | Não menciona o Drools Engine; diagrama Mermaid não inclui o servico; catalogo de documentos desatualizado. |
| `docs/architecture/` | `system_overview.md` | Drools marcado como "Futuro/Roadmap" (porta 8090, tracejado); deveria estar como implementado (porta 8082, linha solida). |
| `docs/architecture/` | **Novo:** `drools_engine.md` | Nao existe. Documento de arquitetura interna do Drools paralelo a `prolog_engine.md`. |
| `docs/architecture/` | `README.md` | Indice nao lista documento do Drools Engine. |
| `docs/architecture/` | `service_interactions.md` | Nao documenta o fluxo Orchestrator -> Drools. |
| `docs/api/` | **Novo:** `drools_engine_api.md` | Nao existe. Especificacao REST do Drools Engine paralela a `prolog_engine_api.md`. |
| `docs/api/` | `README.md` | Indice nao lista a API do Drools; resumo de endpoints incompleto. |
| `docs/api/` | `schemas.md` | Nao documenta os DTOs Java do Drools nem os contratos JSON do motor. |
| `docs/deployment/` | `docker.md` | Nao documenta o Dockerfile multi-stage do Drools Engine. |
| `docs/deployment/` | `docker_compose.md` | Nao documenta o servico `drools-engine` adicionado ao `docker-compose.yml`. |
| `docs/deployment/` | `environment_variables.md` | Nao documenta `DROOLS_ENGINE_URL` e as propriedades Spring Boot (`application.properties`). |
| `docs/deployment/` | `troubleshooting.md` | Nao inclui cenarios de troubleshooting especificos do Drools / JVM / Maven. |
| `docs/development/` | `getting_started.md` | Nao menciona pre-requisitos Java/Maven nem o arranque do Drools Engine. |
| `docs/development/` | `testing.md` | Nao documenta os testes JUnit/Spring Boot Test do Drools Engine. |
| `docs/development/` | `coding_conventions.md` | Nao abrange convencoes Java/Spring Boot/Lombok. |
| `docs/history/` | **Novo:** `drools_implementation_plan.md` | Nao existe. Plano historico de implementacao do motor Drools. |
| `docs/history/` | `README.md` | Indice nao referencia o plano do Drools. |
| `README.md` (raiz) | README raiz do projeto | Nao documenta o Drools Engine na estrutura do projeto. |

---

## Fase 1 -- Documentação Arquitectural (Novos Documentos e Atualizações Core)

**Prioridade:** Critica
**Dependências:** Nenhuma
**Estimativa:** 4 documentos (1 novo + 3 atualizacoes)

### Tarefa 1.1 -- Criar `docs/architecture/drools_engine.md`

**Tipo:** Criacao de ficheiro novo
**Ficheiro:** `docs/architecture/drools_engine.md`
**Modelo de referencia:** `docs/architecture/prolog_engine.md`

Conteudo obrigatorio a incluir:

1. **Titulo e subtitulo** seguindo o padrao (`# Arquitetura Interna: Micro-servico Drools Engine` / `### *Motor de Inferencia Baseado em Regras de Producao*`).
2. **Secção 1 -- Visão Geral e Papel no Sistema:** Posicionamento do Drools Engine como segundo motor de inferencia pericial, baseado no algoritmo Rete-OO, complementar ao motor Prolog.
3. **Secção 2 -- Principios de Arquitectura e Organizacao do Codigo:** Diagrama `text` da arvore de pastas do `drools_engine/` com anotacoes por camada:
   - `config/` -- Configuracao Spring e KieContainer (`DroolsConfig.java`)
   - `controllers/` -- Camada REST (`InferenceController.java`, `HealthController.java`, `GlobalExceptionHandler.java`)
   - `services/` -- Camada de servico e logica de orquestracao Drools (`InferenceService.java`, `InferenceServiceImpl.java`)
   - `models/` -- Factos Drools (domain objects inseridos no Working Memory): `Evidences.java`, `Hypothesis.java`, `Conclusion.java`
   - `dtos/` -- Data Transfer Objects para API REST: `EvidencesRequestDto.java`, `EvaluationResponseDto.java`, `HealthResponseDto.java`, `ErrorResponseDto.java`
   - `resources/rules/` -- Ficheiros `.drl` (Drools Rule Language): `haemorrhage_rules.drl`
   - `resources/META-INF/kmodule.xml` -- Definicao de KieBase e KieSession
4. **Secção 3 -- Separacao entre Factos de Dominio e DTOs de Transporte:** Explicar o isolamento entre `models/` (Drools Working Memory facts) e `dtos/` (contratos JSON), incluindo o metodo `toDomain()` com normalizacao defensiva.
5. **Secção 4 -- Configuracao e Inicializacao do KieContainer:** Explicar a estrategia dual (`KieClasspathContainer` com fallback para `KieFileSystem`), carregamento dinamico de `.drl` e verificacao de erros de compilacao.
6. **Secção 5 -- Base de Regras de Hemorragia (`haemorrhage_rules.drl`):** Documentar hierarquia de regras com prioridades (`salience`), regras de classificacao (upper/lower), regras diagnosticas e fallback. Incluir diagrama Mermaid da arvore de decisao.
7. **Secção 6 -- Ciclo de Vida do Pedido (Request-Response Lifecycle):** Diagrama de sequencia Mermaid mostrando: Controller -> Service -> KieSession (insert facts, fireAllRules, extract conclusions) -> Response DTO. Incluir tracking de `firedRules` para explicabilidade.
8. **Secção 7 -- Tratamento Global de Erros:** Documentar `GlobalExceptionHandler` com as tres categorias: `MethodArgumentNotValidException` (400), `HttpMessageNotReadableException` (400), `Exception` generico (500).
9. **Secção 8 -- Documentos Relacionados:** Links para `system_overview.md`, `service_interactions.md`, `drools_engine_api.md`, `docker.md`.

### Tarefa 1.2 -- Atualizar `docs/architecture/system_overview.md`

**Tipo:** Edicao de ficheiro existente
**Ficheiro:** `docs/architecture/system_overview.md`

Alteracoes obrigatorias:

1. **Secção 1 (Visão Geral):** Atualizar a prosa para indicar que o motor Drools esta **implementado e operacional**, removendo referencias a "fase subsequente" ou "futuro".
2. **Diagrama Mermaid (flowchart):** Alterar `DROOLS` de linha tracejada (`-.->`) para linha solida (`-->`). Atualizar a label para `Porta 8082 (Host) / 8080 (Contentor) (Implementado)`. Atualizar o URL de comunicacao para `http://drools-engine:8080`.
3. **Secção 2.4 (Drools Engine -- Futuro):** Reescrever completamente para refletir o estado implementado. Incluir: tecnologia (Java 21, Spring Boot 3.3, Apache KIE Drools 8.44), dominio clinico de hemorragias, endpoints REST, factos de dominio (Evidences, Hypothesis, Conclusion) e explicabilidade via `firedRules`.
4. **Secção 4 (Stack Tecnologica):** Adicionar linha na tabela para o Motor Drools: `Java 21 / Spring Boot 3 / Drools 8.44`, imagem `eclipse-temurin:21`, porta `8080` (contentor) / `8082` (host).

### Tarefa 1.3 -- Atualizar `docs/architecture/service_interactions.md`

**Tipo:** Edicao de ficheiro existente
**Ficheiro:** `docs/architecture/service_interactions.md`

Alteracoes obrigatorias:

1. Adicionar novo diagrama de sequencia Mermaid documentando o fluxo `Orchestrator -> Drools Engine -> Working Memory -> Response`.
2. Documentar o pipeline de transformacao de dados: `EvidencesRequestDto` (JSON) -> `toDomain()` -> `Evidences` (Drools fact) -> `KieSession.fireAllRules()` -> `Hypothesis` + `Conclusion` -> `EvaluationResponseDto` (JSON).
3. Documentar o tratamento de erros: 400 (validacao Bean Validation), 400 (JSON malformado), 500 (erro interno Drools).
4. Atualizar secção de extensao multi-motor com informacao concreta em vez de planeada.

### Tarefa 1.4 -- Atualizar `docs/architecture/README.md`

**Tipo:** Edicao de ficheiro existente
**Ficheiro:** `docs/architecture/README.md`

Alteracoes obrigatorias:

1. Adicionar entrada na tabela do indice para `drools_engine.md`.
2. Atualizar diagrama Mermaid adicionando no `DROOLS_DOC["drools_engine.md<br/>(Arquitectura Drools)"]` com ligacoes adequadas.
3. Atualizar prosa da Secção 1 para mencionar ambos os motores como implementados.

---

## Fase 2 -- Referencia de APIs e Contratos de Dados

**Prioridade:** Critica
**Dependências:** Fase 1 (para referências cruzadas correctas)
**Estimativa:** 3 documentos (1 novo + 2 atualizacoes)

### Tarefa 2.1 -- Criar `docs/api/drools_engine_api.md`

**Tipo:** Criacao de ficheiro novo
**Ficheiro:** `docs/api/drools_engine_api.md`
**Modelo de referencia:** `docs/api/prolog_engine_api.md`

Conteudo obrigatorio:

1. **Titulo e subtitulo** padronizado.
2. **Secção 1 -- Visao Geral e Natureza da API:** API interna consumida pelo Orchestrator. Diagrama Mermaid `flowchart` do fluxo Orch -> Drools.
3. **Secção 1.1 -- Configuracao Base:** Tabela com URL base em ambiente local (`http://localhost:8082`) e Docker (`http://drools-engine:8080`).
4. **Secção 2 -- Health Check (`GET /api/v1/inference/health`):** Especificacao completa com tabela de campos da resposta (`status`, `service`, `version`, `activeKieBase`, `totalRules`, `timestamp`), exemplo JSON.
5. **Secção 3 -- Avaliacao de Evidencias Clinicas (`POST /api/v1/inference/evaluate`):**
   - Tabela de campos do pedido (`EvidencesRequestDto`): todos os 13 campos clinicos com validacao `@Pattern(yes|no)`, default behaviour (campos ausentes tratados como `"no"`).
   - Tabela de campos da resposta (`EvaluationResponseDto`): `status`, `primaryDiagnosis`, `conclusions`, `hypothesis`, `firedRules`, `timestamp`, `evidencesEvaluated`.
   - Exemplos JSON de request/response para cada tipo de diagnostico (upper type, lower type, fallback).
6. **Secção 4 -- Respostas de Erro:** Documentar `ErrorResponseDto` com campos (`status`, `error`, `message`, `details`, `timestamp`). Exemplos para 400 (validacao), 400 (JSON malformado), 500 (erro interno).
7. **Secção 5 -- Exemplos Praticos (Bash e PowerShell):** Comandos cURL e PowerShell para health check e cada cenario de diagnostico.
8. **Secção 6 -- Documentos Relacionados.**

### Tarefa 2.2 -- Atualizar `docs/api/schemas.md`

**Tipo:** Edicao de ficheiro existente
**Ficheiro:** `docs/api/schemas.md`

Alteracoes obrigatorias:

1. Adicionar nova secção (ex.: Secção 7) dedicada aos **Contratos de Dados do Motor Drools (Java / Spring Boot)**.
2. Documentar `EvidencesRequestDto` com tabela de campos, validacoes `@Pattern`, metodo `toDomain()` e comportamento de normalizacao.
3. Documentar `EvaluationResponseDto` com tabela de campos e exemplo JSON.
4. Documentar `HealthResponseDto` com tabela de campos e exemplo JSON.
5. Documentar `ErrorResponseDto` com tabela de campos.
6. Documentar os factos de dominio Drools (`Evidences`, `Hypothesis`, `Conclusion`) e explicar a sua relacao com os DTOs.
7. Atualizar o diagrama de classes Mermaid existente adicionando os modelos Drools.

### Tarefa 2.3 -- Atualizar `docs/api/README.md`

**Tipo:** Edicao de ficheiro existente
**Ficheiro:** `docs/api/README.md`

Alteracoes obrigatorias:

1. Adicionar `drools_engine_api.md` na tabela do indice.
2. Adicionar subsecção 3.3 com resumo dos endpoints Drools (porta 8082 host / 8080 contentor).
3. Atualizar diagrama Mermaid adicionando camada Drools.
4. Atualizar links de referencia cruzada.

---

## Fase 3 -- Documentação de Deploy e Operações

**Prioridade:** Alta
**Dependências:** Fase 1
**Estimativa:** 4 atualizacoes de ficheiros existentes

### Tarefa 3.1 -- Atualizar `docs/deployment/docker.md`

**Tipo:** Edicao de ficheiro existente
**Ficheiro:** `docs/deployment/docker.md`

Alteracoes obrigatorias:

1. **Secção 1 (Visao Geral):** Atualizar prosa e diagrama Mermaid para incluir o contentor `expert-drools-engine` com imagem base `maven:3.9-eclipse-temurin-21-alpine` (build) e `eclipse-temurin:21-jre-alpine` (runtime).
2. **Secção 2 (Tabela de Servicos):** Adicionar linha: `Drools Engine | drools_engine/ | eclipse-temurin:21-jre-alpine | expert-drools-engine | 8080/tcp | 8082`.
3. **Nova subsecção 3.3 -- Drools Engine (`drools_engine/Dockerfile`):** Documentar o Dockerfile multi-stage:
   - Stage 1 (Build): Maven + Temurin JDK 21 Alpine, `dependency:go-offline`, `mvn clean package`.
   - Stage 2 (Runtime): JRE 21 Alpine, utilizador nao-privilegiado `appuser`, `JAVA_OPTS` com `-XX:+UseContainerSupport`.
   - Exclusoes `.dockerignore`.
4. **Secção 4 (Instrucoes CLI individuais):** Adicionar subsecção 4.3 com comandos de build, run, verificacao e limpeza para o Drools Engine.

### Tarefa 3.2 -- Atualizar `docs/deployment/docker_compose.md`

**Tipo:** Edicao de ficheiro existente
**Ficheiro:** `docs/deployment/docker_compose.md`

Alteracoes obrigatorias:

1. **Secção 1 (Visao Geral):** Atualizar prosa e diagrama Mermaid adicionando contentor `expert-drools-engine` na rede `retail-network`, com ligacao DNS `drools-engine:8080`.
2. **Secção 2 (Anatomia):** Atualizar bloco YAML para refletir o `docker-compose.yml` atual (3 servicos). Adicionar subsecção 2.1.2 analisando o servico `drools-engine` (contexto, portas 8082:8080, rede).
3. **Secção 2.1 (Servico orchestrator):** Documentar a nova variavel `DROOLS_ENGINE_URL=http://drools-engine:8080` e a dependencia `depends_on: drools-engine`.
4. **Secção 3 (Guia Operacional):** Atualizar outputs esperados de `docker compose ps` para 3 contentores. Adicionar exemplo de smoke test do Drools via porta 8082.
5. **Secção 4 (Tabela Rapida):** Verificar que os comandos continuam validos para 3 servicos.

### Tarefa 3.3 -- Atualizar `docs/deployment/environment_variables.md`

**Tipo:** Edicao de ficheiro existente
**Ficheiro:** `docs/deployment/environment_variables.md`

Alteracoes obrigatorias:

1. Adicionar nova **Secção 2.5** (ou renumerar) para variaveis do Drools Engine:
   - `server.port` (default: 8080)
   - `logging.level.com.expert.drools` (default: DEBUG)
   - `logging.level.org.drools` (default: INFO)
   - `spring.jackson.deserialization.fail-on-unknown-properties` (default: false)
   - `JAVA_OPTS` (default: `-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0`)
2. Na secção de variaveis do Orchestrator, adicionar `DROOLS_ENGINE_URL` com valor local (`http://localhost:8082`) e Docker (`http://drools-engine:8080`).
3. Atualizar secção de diferenca entre ambiente local e Docker para incluir `DROOLS_ENGINE_URL`.

### Tarefa 3.4 -- Atualizar `docs/deployment/troubleshooting.md`

**Tipo:** Edicao de ficheiro existente
**Ficheiro:** `docs/deployment/troubleshooting.md`

Alteracoes obrigatorias:

1. Adicionar cenarios de troubleshooting especificos do Drools Engine:
   - Erro de compilacao de regras DRL (logs `KieBuilder` / `Results.hasMessages(ERROR)`).
   - Falha de inicializacao do `KieContainer` (classpath vs filesystem fallback).
   - Contentor Drools nao responde ao health check (JVM startup time vs `depends_on`).
   - Conflito de portas 8082 no host.
   - OutOfMemoryError na JVM (ajustar `JAVA_OPTS`).
   - Maven `dependency:go-offline` falha durante build Docker (rede/proxy).

---

## Fase 4 -- Guias de Desenvolvimento e Testes

**Prioridade:** Alta
**Dependências:** Fases 1-3
**Estimativa:** 3 atualizacoes de ficheiros existentes

### Tarefa 4.1 -- Atualizar `docs/development/getting_started.md`

**Tipo:** Edicao de ficheiro existente
**Ficheiro:** `docs/development/getting_started.md`

Alteracoes obrigatorias:

1. **Secção 2 (Pre-requisitos):** Adicionar na tabela: `Java JDK 21+`, `Maven 3.9+` (ambos opcionais se usar Docker), `Docker Desktop 24.0+`.
2. **Secção 3 (Estrutura):** Atualizar arvore de diretorios do projeto para incluir `drools_engine/`.
3. **Nova subsecção (Passo 1b):** Instrucoes de arranque do Drools Engine em modo local nativo (alternativa a Docker):
   - Navegar para `drools_engine/`
   - `mvn clean package -DskipTests`
   - `java -jar target/*.jar`
   - Output esperado do Spring Boot.
4. **Secção 5 (Execução Local):** Atualizar diagrama Mermaid para 3 terminais (Prolog :8080, Drools :8082 via redirecionamento, FastAPI :8000). Corrigir o fluxo para incluir `POST http://drools-engine:8080/api/v1/inference/evaluate`.
5. **Secção 6 (Docker Compose):** Verificar que os comandos continuam corretos para 3 servicos.
6. **Secção 7 (Smoke Tests):** Adicionar subsecção 7.4 com smoke test do Drools Engine.
7. **Secção 8 (Resumo URLs):** Adicionar linhas para os endpoints do Drools Engine na porta 8082.

### Tarefa 4.2 -- Atualizar `docs/development/testing.md`

**Tipo:** Edicao de ficheiro existente
**Ficheiro:** `docs/development/testing.md`

Alteracoes obrigatorias:

1. **Secção 1 (Visao Geral):** Atualizar contagem total de testes e adicionar terceiro dominio tecnologico: **Motor Drools (Java / Spring Boot)** com testes JUnit 5 e Spring Boot Test.
2. **Diagrama Mermaid:** Adicionar subgrafo para testes Drools (`InferenceServiceImplTest`, `InferenceControllerTest`, `DroolsEngineApplicationTests`).
3. **Nova secção:** Documentar os testes do Drools Engine:
   - Testes unitarios do servico (`InferenceServiceImplTest`): cenarios de diagnostico por tipo de hemorragia.
   - Testes de integracao do controlador (`InferenceControllerTest`): validacao de endpoints REST com MockMvc.
   - Testes de contexto Spring (`DroolsEngineApplicationTests`): verificacao de bootstrap.
4. **Comando de execucao:** `cd drools_engine && mvn test` ou `mvn -pl drools_engine test`.
5. Atualizar piramide de testes total do projeto.

### Tarefa 4.3 -- Atualizar `docs/development/coding_conventions.md`

**Tipo:** Edicao de ficheiro existente
**Ficheiro:** `docs/development/coding_conventions.md`

Alteracoes obrigatorias:

1. Adicionar subsecção para convencoes Java/Spring Boot:
   - Uso de Lombok (`@Data`, `@Builder`, `@RequiredArgsConstructor`).
   - Separacao `models/` (factos Drools) vs `dtos/` (contratos REST).
   - Bean Validation com `@Pattern` e `@Valid`.
   - Convencoes de nomeacao de regras DRL (`r1_nome_descritivo`).
   - Javadoc obrigatorio em classes publicas.
   - `@JsonInclude(NON_NULL)` em DTOs de resposta.

---

## Fase 5 -- Indices Gerais, README Raiz e Historico

**Prioridade:** Media-Alta
**Dependências:** Fases 1-4 (todos os documentos ja devem existir para linkagem)
**Estimativa:** 4 atualizacoes + 1 novo ficheiro

### Tarefa 5.1 -- Atualizar `docs/README.md` (Indice Geral)

**Tipo:** Edicao de ficheiro existente
**Ficheiro:** `docs/README.md`

Alteracoes obrigatorias:

1. **Secção 1 (Visao Geral):** Atualizar prosa substituindo "na próxima fase, regras de produção em Java/Drools" por referencia ao motor implementado.
2. **Diagrama Mermaid (Mapa Estrutural):** Sem alteracao estrutural necessaria (as 6 areas tematicas mantem-se).
3. **Secção 3.2 (Arquitectura):** Adicionar entrada na tabela: `Arquitetura do Motor Drools | drools_engine.md | ...`.
4. **Secção 3.3 (APIs):** Adicionar entrada na tabela: `API Interna do Motor Drools | drools_engine_api.md | ...`.
5. **Secção 3.4 (Deploy):** Verificar que as descricoes dos documentos refletem 3 servicos.
6. **Secção 4 (Roteiros de Leitura):** Atualizar os percursos recomendados para mencionar o Drools quando relevante.
7. **Secção 5 (Resumo Rapido de Execucao):** Adicionar exemplo de smoke test do Drools na porta 8082.

### Tarefa 5.2 -- Atualizar `README.md` (Raiz do Projeto)

**Tipo:** Edicao de ficheiro existente
**Ficheiro:** `README.md` (raiz)

Alteracoes obrigatorias:

1. Atualizar estrutura de alto nivel do repositorio para incluir `drools_engine/`.
2. Adicionar descricao do Drools Engine na secção de componentes do sistema.
3. Atualizar instrucoes de arranque rapido (Docker Compose) para refletir 3 servicos.
4. Atualizar tabela de portas.

### Tarefa 5.3 -- Criar `docs/history/drools_implementation_plan.md`

**Tipo:** Criacao de ficheiro novo
**Ficheiro:** `docs/history/drools_implementation_plan.md`
**Modelo de referencia:** `docs/history/inference_engine_implementation_plan.md`

Conteudo obrigatorio:

1. Roteiro historico de implementacao do motor Drools com as fases executadas.
2. Registo do que foi concretizado: setup Spring Boot, configuracao KieContainer, modelos de dominio, regras DRL de hemorragia, controladores REST, tratamento de erros, testes automatizados, contentorizacao Docker e integracao no Compose.
3. Criterios de validacao utilizados em cada fase.

### Tarefa 5.4 -- Atualizar `docs/history/README.md`

**Tipo:** Edicao de ficheiro existente
**Ficheiro:** `docs/history/README.md`

Alteracoes obrigatorias:

1. Adicionar entrada na tabela para `drools_implementation_plan.md`.
2. Atualizar diagrama Mermaid adicionando no de `H_DRL` com ligacoes para `ARCH`, `API`, `DEP`, `DEV`.

---

## Fase 6 -- Revisao Final e Validacao de Integridade

**Prioridade:** Critica (bloqueante para entrega)
**Dependências:** Fases 1-5 concluidas
**Estimativa:** Revisao transversal

### Tarefa 6.1 -- Validacao de Links e Referências Cruzadas

Para cada ficheiro em `docs/`:
- Verificar que todos os links relativos Markdown (`[texto](caminho)`) apontam para ficheiros existentes.
- Verificar que referências a "Futuro", "Roadmap" ou "Planeado" relativos ao Drools foram removidas ou corrigidas.
- Verificar que os diagramas Mermaid renderizam sem erros de sintaxe.

### Tarefa 6.2 -- Validacao de Consistencia Terminologica

- **Nome do servico:** `drools-engine` (Docker Compose / DNS) vs `drools_engine` (diretorio).
- **Nome do contentor:** `expert-drools-engine` (conforme `docker-compose.yml`).
- **Portas:** `8080` (interno/contentor) e `8082` (host mapeado).
- **Dominio clinico:** "Haemorrhage" / "Hemorragia" (uso consistente em EN e PT).

### Tarefa 6.3 -- Verificacao de Ausencia de Emojis

Executar busca global em todos os ficheiros `.md` dentro de `docs/` para garantir ausencia total de emojis ou caracteres Unicode decorativos.

### Tarefa 6.4 -- Verificacao de Conformidade com Normas de Escrita

Para cada novo documento ou secção adicionada:
- Confirmar que os cabeçalhos seguem numeracao hierarquica (`## N.`, `### N.M`).
- Confirmar subtitulo em italico na linha 2.
- Confirmar presenca de secção "Documentos Relacionados" no final.
- Confirmar exemplos de teste em Bash e PowerShell (quando aplicavel).
- Confirmar ausencia de emojis.

---

## Resumo Executivo por Fase

| Fase | Descricao | Ficheiros Novos | Ficheiros Atualizados | Prioridade |
|:---:|:---|:---:|:---:|:---:|
| 1 | Documentacao Arquitectural | 1 | 3 | Critica |
| 2 | Referencia de APIs e Contratos | 1 | 2 | Critica |
| 3 | Deploy e Operacoes | 0 | 4 | Alta |
| 4 | Guias de Desenvolvimento e Testes | 0 | 3 | Alta |
| 5 | Indices, README Raiz e Historico | 1 | 3 | Media-Alta |
| 6 | Revisao Final e Validacao | 0 | Transversal | Critica |
| **Total** | | **3** | **15** | |

---

## Instrucoes para Agentes de Execucao

1. **Executar as fases pela ordem definida** (1 -> 2 -> 3 -> 4 -> 5 -> 6). As dependencias de referencia cruzada exigem esta sequencia.
2. **Antes de editar qualquer ficheiro existente**, ler o ficheiro completo para compreender a estrutura, estilo e convencoes de escrita locais.
3. **Usar como modelo** os documentos paralelos indicados em cada tarefa (ex.: `prolog_engine.md` como modelo para `drools_engine.md`).
4. **Toda a prosa deve ser escrita em Portugues de Portugal (pt-PT)**. Identificadores de codigo, nomes de classes, endpoints e comandos mantem-se em ingles.
5. **Proibicao absoluta de emojis.** Nem nos titulos, nem nos blocos de texto, nem nas tabelas.
6. **Diagramas Mermaid** devem ser testados para garantir renderizacao correta; evitar caracteres especiais nao quotados em labels.
7. **Todos os exemplos de endpoints** devem incluir variantes cURL (Bash) e PowerShell (Windows).
8. **Referências cruzadas** devem usar caminhos relativos Markdown (ex.: `[texto](../api/drools_engine_api.md)`).
9. **Cada documento novo** deve terminar com secção "Documentos Relacionados" contendo links para documentos adjacentes na hierarquia.
10. **Na Fase 6**, a validacao deve ser exaustiva e transversal a todos os ficheiros em `docs/`.
