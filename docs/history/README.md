# Histórico e Planos de Implementação
### *Arquivo de Engenharia, Roteiros de Execução e Relatórios de Progresso*

---

## 1. Visão Geral da Secção

Esta secção preserva a memória histórica e os artefactos de planeamento de engenharia que guiaram a construção iterativa do **Sistema Pericial de Diagnóstico para Devoluções e Trocas no Retalho**.

Aqui residem os planos de implementação faseados originais, os critérios de validação utilizados em cada etapa e os relatórios de execução técnica que registaram a transição desde as provas de conceito (POC) iniciais até à maturidade dos micro-serviços.

> [!NOTE]
> **Estatuto dos Documentos:** Os documentos nesta pasta são de cariz **histórico e imutável**. Servem para auditoria académica, rastreabilidade de decisões e consulta de como o sistema foi desenvolvido fase a fase. Para o desenvolvimento ativo e operação contínua do sistema, utilize a documentação técnica consolidada nas secções temáticas (`architecture/`, `api/`, `deployment/`, `domain/`, `development/`).

---

## 2. Índice de Documentos Históricos

| Documento | Fases Cobertas | Estado | Resumo e Conteúdo |
|:---|:---:|:---:|:---|
| [Plano de Implementação do Prolog (`prolog_implementation_plan.md`)](prolog_implementation_plan.md) | Fases 1 a 4 | **100% Concluído** | Setup base, regras de inferência pura (`rules.pl`), camada de transporte HTTP (`server.pl`, `routes.pl`), testes PLUnit (12 testes) e contentorização Docker (`swipl:latest`). |
| [Plano de Implementação do Orquestrador FastAPI (`fastapi_implementation_plan.md`)](fastapi_implementation_plan.md) | Fases 1 a 6 | **100% Concluído** | Setup de configurações tipadas, schemas Pydantic DTOs, cliente HTTP assíncrono `httpx`, endpoints REST v1, suíte de 53 testes Pytest e orquestração integrada via Docker Compose. |
| [Plano de Implementação da Documentação (`documentation_implementation_plan.md`)](documentation_implementation_plan.md) | Fases 0 a 7 | **100% Concluído** | Reorganização da documentação técnica profissional em subdiretórios temáticos, redação de guias de arquitetura, contratos de APIs, deploy, domínio, desenvolvimento e revisão final. |
| [Plano do Motor de Inferência Pericial (`inference_engine_implementation_plan.md`)](inference_engine_implementation_plan.md) | Fases 1 a 5 | **100% Concluído** | Adaptação modular de `sp_exp2.pl` para microserviços, base de conhecimento `vehicles`, rotas REST Prolog `/inference/*`, cliente e serviço Python, schemas Pydantic v2, endpoints FastAPI `/api/v1/inference/*`, toggle `INFERENCE_ENGINE_ENABLED`, testes automatizados PLUnit + Pytest e documentação. |
| [Plano de Implementação do Motor Drools (`drools_implementation_plan.md`)](drools_implementation_plan.md) | Fases 1 a 6 | **100% Concluído** | Micro-serviço Java 21 / Spring Boot 3 / Drools 8.44: modelos de domínio, base de regras DRL de hemorragia com explicabilidade (`firedRules`), endpoints REST, suíte de testes JUnit 5 e contentorização multi-stage. |
| [Plano do Motor de Retalho em Prolog (`retail_prolog_implementation_plan.md`)](../development/retail_prolog_implementation_plan.md) | Fases 1 a 5 | **100% Concluído** | Adaptação integral do motor pericial em SWI-Prolog para retalho Levi's: 71 regras normativas em 9 famílias, mecânica dialógica ACM com `obtem_facto/2` e `perguntavel/1`, 5 vias de explicabilidade pericial (`como`, `why_ask`, `output_why`, `whynot`, `what_if` em sandbox transacional), 7 endpoints REST `/retail/*`, cliente Python assíncrono, rotas FastAPI `/api/v1/retail/*`, toggle `PROLOG_ENGINE_MODE`, 81 testes PLUnit e 153 testes Pytest. |

---

## 3. Relação entre o Histórico e a Documentação Ativa

O diagrama abaixo ilustra como o trabalho documentado nos planos históricos migrou e foi formalizado na atual estrutura de documentação técnica profissional:

```mermaid
flowchart LR
    subgraph PlanosHistoricos ["Planos de Execução (Histórico)"]
        H_PL["prolog_implementation_plan.md<br>(POC Prolog Fases 1-4)"]
        H_PY["fastapi_implementation_plan.md<br>(Orquestrador FastAPI Fases 1-6)"]
        H_DOC["documentation_implementation_plan.md<br>(Documentação Fases 0-7)"]
        H_INF["inference_engine_implementation_plan.md<br>(Motor de Inferência Fases 1-5)"]
        H_DRL["drools_implementation_plan.md<br>(Motor Drools Fases 1-6)"]
        H_RET["retail_prolog_implementation_plan.md<br>(Motor Retalho Prolog Fases 1-5)"]
    end

    subgraph DocsAtivos ["Documentação Técnica Ativa"]
        ARCH["docs/architecture/<br>Visão Global e Micro-serviços"]
        API["docs/api/<br>Endpoints REST e Schemas"]
        DEP["docs/deployment/<br>Docker e Docker Compose"]
        DEV["docs/development/<br>Setup, Testes e Convenções"]
        DOM["docs/domain/<br>Negócio, Perito e Explicabilidade"]
    end

    H_PL --> ARCH
    H_PL --> API
    H_PL --> DEV

    H_PY --> ARCH
    H_PY --> API
    H_PY --> DEP
    H_PY --> DEV

    H_DOC --> DOM
    H_DOC --> ARCH
    H_DOC --> API
    H_DOC --> DEP
    H_DOC --> DEV

    H_INF --> ARCH
    H_INF --> API
    H_INF --> DEP
    H_INF --> DEV

    H_DRL --> ARCH
    H_DRL --> API
    H_DRL --> DEP
    H_DRL --> DEV

    H_RET --> ARCH
    H_RET --> API
    H_RET --> DEP
    H_RET --> DEV
    H_RET --> DOM
```

---

## 4. Navegação no Repositório de Documentação

* **Arquitetura:** [Visão Global da Arquitetura](../architecture/README.md)
* **APIs & Contratos:** [Referência de APIs e Schemas](../api/README.md)
* **Deploy & Operações:** [Guia de Deploy e Docker](../deployment/README.md)
* **Domínio:** [Domínio de Negócio e Conhecimento Pericial](../domain/README.md)
* **Desenvolvimento:** [Guias de Desenvolvimento e Testes](../development/README.md)
* **Índice Geral:** [Documentação do Projeto](../README.md)

---

## 5. Documentos Relacionados

* [Plano de Implementação do Motor de Retalho em Prolog](../development/retail_prolog_implementation_plan.md) — Roteiro técnico completo de 5 fases de adaptação do motor pericial.
* [Plano de Atualização da Documentação Técnica](../development/retail_prolog_documentation_update_plan.md) — Roteiro de atualização documental do motor de retalho Prolog.
* [Dissecação do Motor sp_exp2](../architecture/sp_exp2_engine_analysis.md) — Análise técnica do motor pedagógico de suporte.
* [Estratégia e Execução de Testes](../development/testing.md) — Especificação das suítes de testes PLUnit, Pytest e JUnit 5.
* [Índice Geral da Documentação Técnica](../README.md) — Portal central da documentação técnica.
