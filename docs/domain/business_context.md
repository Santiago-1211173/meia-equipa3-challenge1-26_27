# Contexto de Negócio e Enquadramento Académico
### *Sistema Pericial de Diagnóstico para Devoluções e Trocas no Retalho*

---

## 1. Enquadramento Académico

Este projeto insere-se no âmbito do **Mestrado em Engenharia de Inteligência Artificial (MEIA)**, integrando de forma sinérgica duas unidades curriculares estruturantes:

* **Engenharia do Conhecimento em IA (ENGCIA):** Modelação de ontologias, aquisição de conhecimento pericial, estruturação de regras de inferência e validação de consistência lógica.
* **Paradigmas de Programação em IA (PPROGIA):** Implementação prática de sistemas baseados em conhecimento através de programação em lógica declarativa (Prolog) e sistemas de regras de produção orientados a objetos (Drools / Java), orquestrados por uma arquitetura moderna e escalável de micro-serviços.

O desenvolvimento decorre no contexto do desafio **Challenges 4Teams**, sob a responsabilidade da **Equipa 3** durante o ano letivo de **2026/2027**.

---

## 2. Objetivo Central do Projeto

O objetivo basilar consiste em **incorporar conhecimento humano especializado em sistemas modernos de Inteligência Artificial**, transformando a heurística e a experiência acumulada de operadores na linha da frente de retalho em decisões de triagem automatizadas, instantâneas, determinísticas e plenamente auditáveis.

Ao contrário de abordagens puramente conexionistas (*black-box machine learning*), onde o processo de raciocínio interno é opaco e probabilístico, este sistema baseia-se em **representação explícita do conhecimento e inferência simbólica**. Tal garantia é vital em ambientes empresariais onde cada decisão tem impacto financeiro direto e exige justificação regulamentar, jurídica e de relacionamento com o consumidor.

```mermaid
flowchart LR
    A["Perito de Domínio<br/>(Experiência Operacional)"] --> B["Aquisição & Formalização<br/>(Engenharia do Conhecimento)"]
    B --> C["Base de Regras Lógicas<br/>(Prolog & Drools)"]
    C --> D["Decisão Determinística<br/>+ Explicabilidade (Why / Why not)"]
```

---

## 3. O Caso de Uso: Devoluções e Trocas no Retalho (*Returns & Exchanges*)

O fluxo de devoluções e trocas de artigos (*Retail Returns & Exchanges*) representa um dos pontos de maior atrito operacional e financeiro no setor retalhista global:

1. **Volume e Complexidade Operacional:** Os balcões de atendimento ao cliente processam diariamente centenas de solicitações sob restrições de tempo, com clientes em espera presencial e políticas de loja multifacetadas.
2. **Prevenção de Fraude e Abuso:** Fenómenos como *wardrobing* (compra de vestuário com o intuito de o usar uma única vez e devolver como novo), devoluções de artigos contrafeitos ou devoluções de peças roubadas sem recibo (*blind returns*) causam prejuízos avultados.
3. **Salvaguarda de Saúde Pública e Higiene:** Certas categorias de mercadorias (artigos de uso íntimo, roupa interior, cosmética) estão sujeitas a restrições legais e de higiene rigorosas (*biohazard* / contaminação), sendo estritamente proibida a sua reintegração em inventário se violado o selo protetor.
4. **Consistência de Marca e Justiça no Atendimento:** Em redes de retalho com dezenas ou centenas de lojas, a aplicação discricionária ou inconsistente de regras por operadores individuais gera insatisfação no cliente e vulnerabilidades operacionais.

O sistema pericial atua como um consultor em tempo real para os operadores de loja (POS - *Point of Sale*), analisando as características do artigo e a transação de compra para emitir uma decisão fundamentada.

---

## 4. O Perito de Domínio: Dustin Hopper

O conhecimento empírico incorporado no sistema tem como fonte o especialista de retalho **Dustin Hopper**, cuja carreira profissional se foca na gestão de equipas de atendimento ao público, resolução de conflitos em balcão e estruturação de procedimentos operacionais de retalho.

### Contribuições Fundamentais do Perito:
* **Identificação de Variáveis Críticas:** Mapeamento de quais os fatores determinantes que um colaborador de loja realmente avalia visual e documentalmente antes de aceitar um artigo.
* **Hierarquia de Exceções:** Definição de situações de fronteira (ex.: etiquetas cortadas mas talão presente; produtos com defeito de fabrico versus artigos danificados por mau uso ou lavagem).
* **Níveis de Decisão Operacional:** Estabelecimento dos desfechos possíveis além do binário "aprovar/rejeitar", incluindo alternativas como *crédito exclusivo em loja* ou *escalamento para gerente de turno* (*manager override*).

Para detalhes exatos sobre a base de regras recolhida, consulte [Base de Conhecimento e Heurísticas do Perito](expert_knowledge.md).

---

## 5. Fatores Operacionais Modelados no Domínio

A triagem pericial avalia simultaneamente cinco dimensões operacionais:

| Dimensão | Fatores Avaliados | Impacto na Decisão |
|:---|:---|:---|
| **Elegibilidade do Artigo** | Categoria do produto, peça íntima (*bodywear/underwear*), presença de etiquetas originais intactas (*tags*), estado de conservação (novo, usado, lavado, danificado, defeito de fabrico). | Determina a viabilidade sanitária e comercial de aceitação do produto em loja. |
| **Comprovativo de Compra** | Presença de recibo fiscal original (físico ou eletrónico), talão de oferta (*gift receipt*) ou ausência total de recibo (*blind return*). | Define se o cliente tem direito a estorno financeiro direto, apenas troca, crédito de loja ou se requer validação de preço mínimo histórico. |
| **Prazos Operacionais** | Dias decorridos desde a data da transação original (janela padrão de 30 dias, janela reduzida de ajuste de preço de 14 dias, janela alargada até 60 dias para crédito). | Delimita se o pedido está em conformidade temporal com a política contratual de devoluções. |
| **Canal de Aquisição** | Loja física da rede, loja de desconto (*outlet* / venda final sem devolução) ou plataforma de comércio eletrónico (*online*). | Governa regras especiais de logística inversa e políticas restritivas de liquidação de stock. |
| **Método de Pagamento (*Tender*)** | Numerário, cartão de crédito/débito, plataformas de pagamento diferido (*Buy Now Pay Later* — ex.: Klarna, Afterpay), cartão de oferta ou saldo de loja. | Obriga a que o estorno seja canalizado exclusivamente pelo mesmo meio de liquidação original para evitar lavagem de capitais. |

---

## 6. Documentos Relacionados

* [Base de Conhecimento e Heurísticas do Perito](expert_knowledge.md) — Árvore concetual de decisão e regras do perito.
* [Requisito Primordial: Explicabilidade e Transparência](explainability.md) — Estrutura e exemplos da cadeia de justificações (*Why / Why not*).
* [Visão Geral da Arquitetura do Sistema](../architecture/system_overview.md) — Organização dos serviços e orquestração.
* [Especificação de Schemas Pydantic / DTOs](../api/schemas.md) — Modelação formal de dados em código.
