# Arquitetura do Sistema
### *Retail Returns & Exchanges Diagnostic Expert System*

---

## 1. Visão Geral da Secção

Esta secção contém a documentação técnica aprofundada da arquitetura da solução, cobrindo o ecossistema global de micro-serviços, o desenho interno do motor de raciocínio dedutivo em SWI-Prolog, a camada de orquestração assíncrona em FastAPI e o fluxo detalhado de dados entre componentes.

O sistema baseia-se em princípios sólidos de engenharia de software: **Clean Architecture**, **separação estrita de responsabilidades**, **desacoplamento de protocolos de transporte**, **tolerância a falhas** e **explicabilidade nativa** (*Why / Why not*).

---

## 2. Índice de Documentos de Arquitetura

| Documento | Propósito | Conteúdo Central |
|:---|:---|:---|
| [Visão Global do Sistema (`system_overview.md`)](system_overview.md) | Visão macro e ecossistema | Diagrama de arquitetura global, descrição das camadas, princípios de desenho ("Regra de Ouro"), stack tecnológica completa e portas de serviço. |
| [Arquitetura do Motor Prolog (`prolog_engine.md`)](prolog_engine.md) | Desenho do micro-serviço SWI-Prolog | Clean Architecture (api vs core), ciclo de vida do pedido, isolamento de I/O, papel dos *Prolog Dicts* como DTOs nativos e predicados de domínio. |
| [Arquitetura do Orquestrador FastAPI (`fastapi_orchestrator.md`)](fastapi_orchestrator.md) | Desenho do backend orquestrador | Arquitetura em camadas (core, schemas, clients, services, api), gestão de ciclo de vida (*lifespan*), connection pooling com `httpx`, CORS e injeção de dependências. |
| [Interações entre Serviços e Fluxos de Dados (`service_interactions.md`)](service_interactions.md) | Comunicação e integração ponta-a-ponta | Diagrama de sequência detalhado (Cliente $\rightarrow$ FastAPI $\rightarrow$ Prolog $\rightarrow$ FastAPI $\rightarrow$ Cliente), pipeline de transformação de dados, DNS Docker, matriz de erros e extensão multi-motor. |

---

## 3. Mapa Visual de Componentes e Documentos

```mermaid
graph TD
    subgraph DocsArch ["docs/architecture/"]
        OVERVIEW["system_overview.md<br/>(Visão Global)"]
        PROLOG_DOC["prolog_engine.md<br/>(Clean Architecture Prolog)"]
        FASTAPI_DOC["fastapi_orchestrator.md<br/>(Camadas & Pools FastAPI)"]
        FLOW_DOC["service_interactions.md<br/>(Sequência & Pipeline)"]
    end

    OVERVIEW --> PROLOG_DOC
    OVERVIEW --> FASTAPI_DOC
    FASTAPI_DOC --> FLOW_DOC
    PROLOG_DOC --> FLOW_DOC
```

---

## 4. Navegação no Repositório de Documentação

* **Domínio & Conhecimento:** [Conhecimento de Negócio e Heurísticas](../domain/README.md)
* **APIs & Contratos:** [Referência de APIs e Schemas](../api/README.md)
* **Deploy & Operações:** [Guia de Deploy e Docker](../deployment/README.md)
* **Desenvolvimento:** [Guias de Desenvolvimento e Testes](../development/README.md)
* **Histórico:** [Planos e Histórico de Implementação](../history/README.md)
