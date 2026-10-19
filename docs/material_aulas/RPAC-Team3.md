# Sistema Pericial de Avaliação da Elegibilidade de Devoluções
### Lojas Levi’s — Estados Unidos e Canadá
**Relatório Prévio de Aquisição de Conhecimento**

**ISEP - MEIA – Engenharia do Conhecimento (2026/2027)**  
**Grupo 3 – SmartCloth AI**

* **Alexandre Teixeira** — nº 1230946
* **Álvaro Cardoso** — nº 1940052
* **Fernando Granjo** — nº 1260430
* **João Moreira** — nº 1260436
* **Rômulo Arantes** — nº 1260446
* **Santiago da Mata Bossa** — nº 1211173

**Data:** 07/10/2026

---

## Índice Geral

* [1. Objetivos do trabalho](#1-objetivos-do-trabalho)
  * [1.1. O problema](#11-o-problema)
  * [1.2. Objetivo geral e objetivos específicos](#12-objetivo-geral-e-objetivos-específicos)
  * [1.3. Estrutura do Relatório](#13-estrutura-do-relatório)
* [2. Fontes de conhecimento](#2-fontes-de-conhecimento)
  * [2.1. Fontes documentais](#21-fontes-documentais)
  * [2.2. Perito](#22-perito)
    * [2.2.1. Percurso e Responsabilidades](#221-percurso-e-responsabilidades)
    * [2.2.2. Adequação ao problema](#222-adequação-ao-problema)
    * [2.2.3. Papel no Projeto](#223-papel-no-projeto)
  * [2.3. Critério de seleção das fontes](#23-critério-de-seleção-das-fontes)
* [3. Sessões de aquisição de conhecimento](#3-sessões-de-aquisição-de-conhecimento)
* [4. Representação do conhecimento](#4-representação-do-conhecimento)
  * [4.1. Formalismo](#41-formalismo)
  * [4.2. Factos de entrada](#42-factos-de-entrada)
  * [4.3. Base de Regras](#43-base-de-regras)
  * [4.4. Estratégia de Inferência](#44-estratégia-de-inferência)
    * [4.4.1. Fluxo geral detalhado - Autorização, dados e canal](#441-fluxo-geral-detalhado---autorização-dados-e-canal)
    * [4.4.2. Elegibilidade do produto](#442-elegibilidade-do-produto)
    * [4.4.3. Comprovativo e prazo](#443-comprovativo-e-prazo)
    * [4.4.4. Caminho online da levi.com e levi.ca](#444-caminho-online-da-levicom-e-levica)
    * [4.4.5. Resultado, troca e exceções](#445-resultado-troca-e-exceções)
    * [4.4.6. Valor da devolução](#446-valor-da-devolução)
    * [4.4.8. Meio de reembolso](#448-meio-de-reembolso)
    * [4.4.9. Controlos e documentação](#449-controlos-e-documentação)
    * [4.4.10. Destino do produto](#4410-destino-do-produto)
  * [4.5. Exemplos de formalização](#45-exemplos-de-formalização)
  * [4.6. Prioridade entre regras](#46-prioridade-entre-regras)
* [5. Bibliografia](#5-bibliografia)
* [6. Terminologia específica](#6-terminologia-específica)

---

### Índice de Tabelas
* **Tabela 1:** Âmbito do sistema de avaliação de devoluções e justificações de exclusão.
* **Tabela 2:** Identificação das fontes estruturadas e do seu respetivo papel no sistema.
* **Tabela 3:** Perfil de atuação e adequação do perito ao domínio.
* **Tabela 4:** Resumo das sessões de recolha de conhecimento e de levantamento de requisitos e regras.
* **Tabela 5:** Tipos de desfecho possíveis no sistema e os respetivos significados.
* **Tabela 6:** Identificação dos factos de entrada e respetivos domínios de valores.
* **Tabela 7:** Estrutura da base de conhecimento e distribuição das categorias de regras.
* **Tabela 8:** Terminologia específica aplicada no contexto das devoluções.

### Índice das Figuras
* **Figura 1:** Fluxo sequencial das etapas de decisão para devoluções e trocas.
* **Figura 2:** Fluxograma da fase inicial: autorização do colaborador e tratamento do canal de compra.
* **Figura 3:** Processo de verificação de paragens obrigatórias e estado físico da peça.
* **Figura 4:** Fluxograma de validação de comprovativos, prazos e ajustes de preço.
* **Figura 5:** Tratamento de devoluções de compras online (levi.com e levi.ca) em loja física.
* **Figura 6:** Fluxo integrado para regras de troca, resolução de contestações e aprovação de exceções.
* **Figura 7:** Fluxograma de determinação do valor de reembolso conforme o tipo de comprovativo e promoções.
* **Figura 8:** Fluxograma de determinação do meio de reembolso com base no método de pagamento original.
* **Figura 9:** Fluxograma de controlos, aprovações e documentação da transação.
* **Figura 10:** Fluxograma de encaminhamento e destino do produto após devolução.

---

## 1. Objetivos do trabalho

### 1.1. O problema
Nas lojas Levi’s dos Estados Unidos e do Canadá, cada pedido de devolução obriga o colaborador a cruzar oito dimensões em simultâneo: mercado, tipo de loja, canal de compra, marca e SKU, estado físico da peça, comprovativo, prazo e meio de pagamento original [1] [2]. A política admite quatro desfechos (**PERMITIR**, **RECUSAR**, **REVER** e **ENCAMINHAR**) [3] e contém dezenas de casos particulares, como o *bodywear*, que é aceite em qualquer estado, as compras Afterpay, que não admitem exceções, ou os produtos da franquia canadiana, que seguem um processo próprio [2].

Este conhecimento está disperso entre a política formal, o texto do recibo e decisões operacionais que só os gestores de loja conhecem [1] [2] [4]. O resultado é uma decisão ao balcão que varia entre lojas, turnos e colaboradores, com três custos diretos: reembolsos indevidos e risco de fraude, recusas incorretas que prejudicam a relação com o cliente, e exceções mal documentadas que não resistem a auditoria [1].

Trata-se, por isso, de um problema adequado a um sistema pericial [5] [6]. As regras existem e são, na sua maioria, explícitas, mas estão fragmentadas, não têm uma ordem de prioridade definida e dependem, nos casos-limite, do critério de quem as aplica. O que falta é reuni-las, ordená-las e torná-las consultáveis e justificáveis no momento da decisão.

### 1.2. Objetivo geral e objetivos específicos
O **objetivo geral** do projeto é desenvolver um sistema pericial que, a partir dos dados de uma transação, determine se uma peça é elegível para devolução ou troca de forma consistente com a política e explicável, e que justifique cada decisão com as regras que a sustentam [1].

Surgem também alguns **objetivos específicos** que devem ser alcançados:
* Adquirir e validar o conhecimento junto do perito e da base documental (política de devoluções e trocas, texto do recibo e decisões operacionais confirmadas).
* Formalizar as **71 regras de decisão** identificadas, organizadas em nove famílias, numa base de conhecimento separada do motor de inferência.
* Determinar, como núcleo do sistema, a elegibilidade (**OUT-001**) e o tipo de transação (**OUT-002**). O valor, o meio de reembolso, as aprovações e o destino do produto (**OUT-003** a **OUT-008**) ficam como extensão.
* Apresentar em cada decisão os identificadores das regras disparadas, para que o colaborador a possa explicar ao cliente e a gestão a possa auditar.
* Detetar e resolver, com o perito, os conflitos e lacunas da política atual, definindo uma ordem de prioridade entre regras.
* Implementar a base de conhecimento em dois motores, **Drools** e **Prolog**, e validá-los com um conjunto de casos de teste partilhado.
* Disponibilizar uma interface web para introdução do caso e consulta do resultado.

#### Tabela 1: Âmbito do sistema de avaliação de devoluções e justificações de exclusão
| Dimensão | Dentro do âmbito | Fora do âmbito | Justificação |
| :--- | :--- | :--- | :--- |
| **Mercado** | Estados Unidos e Canadá, em lojas Mainline e Outlet e nos canais levi.com, levi.ca, BackPocket, franquia canadiana e grossista | Portugal e outros mercados | As políticas portuguesas diferem significativamente das dos EUA e do Canadá, e o perito só domina estas duas regiões. Limitar o âmbito garante a validação mútua entre a documentação e o perito. |
| **Decisão** | Elegibilidade e tipo de transação (núcleo); valor, meio de reembolso, aprovações e destino do produto (extensão) | Execução do reembolso ou da troca e integração com os sistemas de loja (POS/XStore, BackPocket) | O sistema apoia a decisão e não a executa. Não temos acesso a estes sistemas e a sua integração não faz parte do objetivo de aquisição e formalização do conhecimento. |
| **Juízos percetivos** | Perguntas fechadas ao colaborador sobre o estado da peça; devolução de REVER quando a política exige critério da gestão | Avaliação automática de termos como "lavado", "claramente usado" ou "vendável" | Estes juízos dependem de observação humana. O objetivo não é substituir o gestor, mas garantir que só lhe chegam as decisões que realmente precisam dele. |
| **Comportamento do cliente** | Escalonamento quando previsto na política | Modelar a agitação ou a atitude do cliente como facto de entrada | Por EX-003, a atitude do cliente não altera a elegibilidade, apenas desencadeia o escalonamento. |

### 1.3. Estrutura do Relatório
O relatório está organizado em seis capítulos:
* **Objetivos do trabalho:** Apresenta o problema, o objetivo geral e os objetivos específicos, e delimita o âmbito do sistema.
* **Fontes de conhecimento:** Identifica as fontes documentais, caracteriza o perito e explica o critério de seleção das fontes.
* **Sessões de aquisição de conhecimento:** Descreve as sessões realizadas, as técnicas usadas e os resultados de cada uma.
* **Representação do conhecimento:** Apresenta o formalismo, os factos de entrada, a base de regras, a estratégia de inferência, exemplos de formalização e a prioridade entre regras.
* **Bibliografia:** Reúne as referências que sustentam o trabalho.
* **Terminologia específica:** Define os termos técnicos e de domínio usados ao longo do relatório.

---

## 2. Fontes de conhecimento

O conhecimento necessário ao desenvolvimento do sistema foi obtido através de duas fontes que se complementam: a análise de documentos estruturados, nomeadamente uma adaptação da política de devoluções e trocas [2] [3], e do conhecimento geral do perito [1].

Esta combinação permitiu conciliar regras formalmente definidas internamente pela empresa com a forma como elas são efetivamente aplicadas em loja, sobretudo nas exceções e nos casos ambíguos que a documentação não resolve [1].

### 2.1. Fontes documentais

#### Tabela 2: Identificação das fontes estruturadas e do seu respetivo papel no sistema
| Fonte | Tipo | Contributo para a base de conhecimento |
| :--- | :--- | :--- |
| **Política de Devoluções e Trocas, EUA e Canadá (Levi Strauss & Co.)** | Documental, normativa | Fonte principal: paragens obrigatórias, estado do produto, prazos, meios de reembolso e controlos. |
| **Texto do recibo do cliente** | Documental | Condições comunicadas ao cliente, que delimitam o que lhe pode ser exigido (prazo, comprovativo). |
| **Decisões operacionais confirmadas** | Perito | Práticas de loja que complementam a política e clarificação dos casos que exigem critério. |
| **Proposta 1, versão EUA e Canadá 1.3, e documento de sequência por etapas** | Documentos de trabalho do grupo | Formalização das regras com identificadores e ordenação da inferência em etapas. |

### 2.2. Perito

#### Tabela 3: Perfil de atuação e adequação do perito ao domínio
| Campo | Descrição |
| :--- | :--- |
| **Nome** | Dustin Hopper |
| **Função e local** | Gerente da Produtividade Geral do Retalho |
| **Experiência em Retalho** | Mais de 20 anos: 16 anos em liderança de terreno (gestão de loja e de distrito) e cerca de 6 anos em funções corporativas |
| **Mercados e Lojas** | EUA e Canadá; Mainline e Outlet |
| **Disponibilidade** | Semanal ou Quinzenal |

#### 2.2.1. Percurso e Responsabilidades
O perito construiu a carreira de forma ascendente, das operações de loja à gestão regional e daí para funções corporativas em operações, logística e estratégia. No terreno, geriu diretamente transações de devolução e troca, exceções à política e cenários complexos ao balcão [1]. Como gestor de distrito, foi o ponto de escalonamento para as decisões que as lojas não conseguiam resolver sozinhas. Participou ainda, como especialista no assunto, na elaboração de políticas formais de devoluções e trocas, processos, materiais de formação e procedimentos operacionais normalizados.

#### 2.2.2. Adequação ao problema
O perito conhece a política em dois níveis distintos [2], que correspondem a três partes da base de conhecimento:
* **Como foi desenhada:** Por ter participado na escrita de políticas e procedimentos, consegue distinguir uma regra intencional de uma lacuna de redação.
* **Como é aplicada no terreno:** A experiência de loja e de escalonamento regional cobrem as decisões REVER e as regras de exceção (EX-001 a EX-006). É aí que está o conhecimento tácito que a política não escreve.
* **Que riscos envolve:** A perspetiva de prevenção de perdas e fraude permite operacionalizar critérios vagos como "baixo risco" (PT-004, EX-004) e definir indícios de fraude (EX-008). A perspetiva de experiência do cliente informa a ordem das alternativas oferecidas (EX-002, EX-005).

#### 2.2.3. Papel no Projeto
O perito validou as regras da proposta, confirmando que cada uma reflete tanto a política como a prática, e valida a hierarquia de prioridades [1]. Cabe-lhe também esclarecer as ambiguidades, resolvendo os conflitos e lacunas e traduzir termos vagos como "vendável", "claramente usado" ou "baixo risco" em critérios observáveis que o colaborador consiga avaliar [1] [3].

Fornece ainda casos reais que encontrou ou escalou, sobretudo exceções e cenários ambíguos ou únicos, indicando a decisão que considera correta em cada um [1]. Estes casos servem para testar o sistema e constituem o conjunto de casos de teste partilhado pelos motores Drools e Prolog [7] [8]. Por fim, participa na validação final, avaliando as decisões e explicações produzidas pelo sistema em casos que não foram usados no desenvolvimento.

### 2.3. Critério de seleção das fontes
Antes da primeira reunião com o especialista, a equipa analisou as políticas da Levi Strauss para Portugal [2] [4]. Durante o encontro, verificou-se que estas diferem significativamente das dos EUA e do Canadá. Dado que o especialista domina apenas as políticas destas duas regiões, e considerando as particularidades do contexto português, decidiu-se limitar o âmbito do projeto aos EUA e ao Canadá [1] [2]. Desta forma, assegura-se a validação mútua entre a documentação e o especialista.

---

## 3. Sessões de aquisição de conhecimento

A aquisição de conhecimento decorreu ao longo de várias sessões com o perito, realizadas através reuniões via Microsoft Teams e troca de e-mails [1]. Apesar das sessões terem decorrido num ambiente informal, a troca de informação foi colaborativa e estruturada: a equipa preparava previamente as questões e os casos a discutir, e cada sessão partia dos resultados da anterior. Este processo permitiu transformar o conhecimento prático do perito, em grande parte baseado na experiência e não documentado, num conjunto de regras estruturadas e formalizadas, que constitui a base de conhecimento do sistema.

#### Tabela 4: Resumo das sessões de recolha de conhecimento e de levantamento de requisitos e regras
| N.º | Data | Participantes | Técnica | Objetivo | Resultado |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **1** | 09/09/26 | Equipa | Análise documental | Obter as documentações para análise inicial e identificação de regras | Obtido as políticas da Levi's Strauss Portugal |
| **2** | 18/09/26 | Equipa + perito | Introdução do projeto ao perito | Explicar objetivo do projeto ao perito e apresentar propostas de tema | Buy-in do perito e tema escolhido – Sistema diagnóstico de devolução e trocas |
| **3** | 23/09/26 | Equipa + perito | Entrevista estruturada | Obter esclarecimento sobre o processo de devolução e esclarecer dúvidas | Obtenção do documento de Especificação de Regras de Negócio para Trocas e devoluções |

---

## 4. Representação do conhecimento

### 4.1. Formalismo
O conhecimento é representado em sua maioria pela regra **Se-Então** [5] [6], das regras de produção, organizado em nove etapas. Os quatro desfechos a seguir irão concluir as nove etapas.

#### Tabela 5: Tipos de desfecho possíveis no sistema e os respetivos significados
| Desfecho | Significado |
| :--- | :--- |
| **PERMITIR** | Processar segundo a regra padrão. |
| **RECUSAR** | Não processar. |
| **REVER** | É necessário critério ou aprovação da gestão, ou seja, o sistema não decide sozinho. |
| **ENCAMINHAR** | Usar um processo obrigatório separado (BackPocket, franquia do Canadá, aplicação de pagamento). |

### 4.2. Factos de entrada

#### Tabela 6: Identificação dos factos de entrada e respetivos domínios de valores
| ID | Facto | Domínio de valores |
| :--- | :--- | :--- |
| **IN-001** | Mercado | EUA, Canadá |
| **IN-002** | Tipo de loja | Mainline, Outlet |
| **IN-003** | Canal de compra | Mainline, Outlet, levi.com, levi.ca, BackPocket, franquia canadiana, grossista, desconhecido |
| **IN-004** | Comprovativo | Recibo impresso ou digital, confirmação de encomenda, recibo de oferta, consulta da transação, fotografia do recibo, consulta BackPocket, nenhum |
| **IN-005** | Pedido | Devolução, troca, troca pelo mesmo artigo, devolução de oferta, ajuste de preço |
| **IN-006** | Momento | Dias desde a compra ou o envio (numérico) |
| **IN-007** | Produto | Marca, SKU, personalização ou alteração, bodywear, estado no sortido |
| **IN-008** | Estado | Não usado com etiquetas, com etiquetas soltas, sem etiquetas, usado, lavado, defeituoso, sujo, contaminado, inseguro |
| **IN-009** | Meio de pagamento | Numerário, cartão de oferta, crédito, débito, contactless, PayPal, Venmo, Afterpay, Interac |
| **IN-010** | Revenda | Pode ser verificado, reetiquetado e revendido (sim/não) |

### 4.3. Base de Regras

#### Tabela 7: Estrutura da base de conhecimento e distribuição das categorias de regras
| Família | Prefixo | N.º | Função na inferência |
| :--- | :--- | :--- | :--- |
| **Paragens obrigatórias** | HS | 6 | Terminam o processo: SKU inválido, marca excluída, peça alterada, falta de autorização. |
| **Estado do produto** | PC | 8 | Avaliam a condição física, com regime especial para bodywear e para artigos insalubres. |
| **Comprovativo e prazo** | PT | 8 | Distinguem devolução verificada de às cegas e aplicam os prazos de 30 e 14 dias. |
| **Canal e tipo de loja** | CH | 10 | Tratam devoluções entre canais, online, franquia e grossista. |
| **Meio de reembolso** | TN | 12 | Determinam para onde vai o dinheiro, consoante o meio de pagamento original. |
| **Troca e promoção** | EP | 7 | Fixam o preço em trocas e promoções por escalões e o destino entre canais. |
| **Revisão pela gestão** | EX | 8 | Delimitam as exceções e o escalonamento de clientes. |
| **Autorização e conclusão** | CT | 8 | Definem quem processa, assinaturas, atribuição e retenção. |
| **Destino do bodywear** | BW | 4 | Decidem revenda, saldos, baixa por dano ou isolamento. |
| **Total** | | **71** | |

### 4.4. Estratégia de Inferência
No fluxo da aplicação, o motor de inferência irá percorrer cada etapa em sequência. Em cada posição do fluxo, o motor irá avaliar as memórias de trabalho e a base de conhecimento, podendo concluir imediatamente sem a necessidade de percorrer o fluxo completo.

#### Figura 1: Fluxo sequencial das etapas de decisão para devoluções e trocas

```mermaid
flowchart TD
    Start["Pedido do cliente (IN-001 a IN-010)"] --> S0{"0. Colaborador autorizado?<br/>(HS-006, CT-003)"}
    S0 -- "não" --> E0["ENCAMINHAR<br/>processador autorizado"]
    S0 -- "sim" --> S1["1. Mercado e tipo de loja<br/>(IN-001, IN-002)"]
    S1 --> S2{"2. Canal de compra<br/>(CH-001 a CH-008)"}
    S2 -- "grossista" --> R2["RECUSAR<br/>grossista (CH-008)"]
    S2 -- "franquia / online" --> ENC2["ENCAMINHAR<br/>Franquia CA / BackPocket"]
    S2 -- "loja física" --> S3a{"3a. Paragens obrigatórias<br/>(HS-001 a HS-004)"}
    S3a -- "dispara" --> R3a["RECUSAR<br/>SKU, marca, alteração"]
    S3a -- "nenhuma" --> S3b{"3b. Estado do produto<br/>(PC-001 a PC-008)"}
    S3b -- "não elegível" --> R3b["RECUSAR (lavado, usado)<br/>REVER (etiquetas)"]
    S3b -- "elegível" --> S4{"4. Comprovativo de compra<br/>(PT-001, PT-002, PT-006)"}
    S4 -- "não verificável" --> S4Blind["Devolução às cegas<br/>(só troca / crédito, PT-005)"]
    S4 -- "verificado" --> S5{"5. Prazo<br/>(PT-003 a PT-008, CH-005)"}
    S5 -- "> 30 dias" --> R5["REVER<br/>> 30 dias (PT-004)"]
    S5 -- "≤ 30 dias" --> S6["6. Resultado e exceções<br/>(EP-001, EP-002, EX-001 a EX-006)"]
    S4Blind --> S6
    S6 --> S7["7. Valor e meio de reembolso<br/>(CH-009, CH-010, EP-003, EP-004, TN-*)"]
    S7 --> S8["8. Controlos e destino do produto<br/>(CT-*, EP-005 a EP-007, BW-*)"]
    S8 --> Final["Decisão OUT-001 a OUT-008<br/>+ regras disparadas (justificação)"]
```

---

### 4.4.1. Fluxo geral detalhado - Autorização, dados e canal

#### Figura 2: Fluxograma da fase inicial: autorização do colaborador e tratamento do canal de compra

```mermaid
flowchart TD
    Init([Início]) --> HS006{"HS-006<br/>Colaborador autorizado?"}
    HS006 -- "Não" --> EncAuth["ENCAMINHAR<br/>Gestão da Loja, Key Holder, ou Lead Cashier<br/>ou Elevated Stylist aprovado pelo DM"]
    HS006 -- "Sim" --> CT003["CT-003<br/>Sessão própria no POS<br/>do início ao fim"]
    CT003 --> Inputs["IN-001 a IN-009<br/>Mercado, tipo de loja, canal, comprovativo,<br/>pedido, momento, produto, estado, pagamento"]
    Inputs --> IN003{"IN-003<br/>Canal de compra?"}
    IN003 -- "Grossista" --> CH008["CH-008 RECUSAR<br/>Encaminhar para o retalhista original"]
    IN003 -- "Franquia canadiana" --> CH007["CH-007 ENCAMINHAR<br/>Processo da franquia do Canadá com o SKU da franquia"]
    IN003 -- "Mainline ou Outlet" --> CH001["CH-001<br/>Aplicar regras da loja recetora"]
    IN003 -- "levi.com, levi.ca ou BackPocket" --> MOnline["Marcar caminho online ou BackPocket"]
    IN003 -- "Desconhecido" --> MDesc["Prosseguir; o comprovativo decide em M4"]
    CH001 --> IrM3([Ir para M3])
    MOnline --> IrM3
    MDesc --> IrM3
```

Este fluxograma corresponde ao início do processo. Primeiro verifica se o colaborador está autorizado a processar devoluções (HS-006) [3]; se não estiver, o pedido é encaminhado para quem tenha essa autorização. De seguida recolhe os factos de entrada da transação e identifica o canal de compra. Os produtos grossistas são recusados, os da franquia canadiana seguem o processo próprio, e os restantes canais avançam para a avaliação do produto, com as compras online marcadas para o caminho específico da levi.com e levi.ca [3].

---

### 4.4.2. Elegibilidade do produto

#### Figura 3: Processo de verificação de paragens obrigatórias e estado físico da peça

```mermaid
flowchart TD
    VM2([Vindo de M2]) --> HS001{"HS-001<br/>SKU reconhecido no POS?"}
    HS001 -- "Não" --> HS004{"HS-004<br/>Produto da franquia do Canadá?"}
    HS004 -- "Sim" --> CH007["CH-007 ENCAMINHAR"]
    HS004 -- "Não" --> R_SKU["RECUSAR<br/>Não usar SKU diferente ou genérico"]
    
    HS001 -- "Sim" --> HS002{"HS-002<br/>Dockers, LS Signature, Beyond Yoga<br/>ou grossista não vendido na loja?"}
    HS002 -- "Sim" --> R_Marca["RECUSAR"]
    HS002 -- "Não" --> HS003{"HS-003<br/>Personalizado, alterado ou embainhado?"}
    HS003 -- "Sim" --> R_Alt["RECUSAR<br/>mesmo que tenha defeito"]
    HS003 -- "Não" --> PC007{"PC-007<br/>É bodywear?"}
    
    PC007 -- "Sim" --> BW_Allow["PERMITIR em qualquer estado<br/>destino pelas regras BW"]
    PC007 -- "Não" --> PC006{"PC-006<br/>Defeito de fabrico confirmado?"}
    PC006 -- "Sim" --> Def_Allow["PERMITIR reembolso ou substituição<br/>baixa por dano ao devolvido"]
    PC006 -- "Não" --> IN008{"IN-008<br/>Estado do produto?"}
    
    IN008 -- "Sujo, contaminado ou inseguro" --> PC008["PC-008 Isolamento por risco biológico"]
    IN008 -- "Não usado, etiquetas colocadas" --> PC001["PC-001 PERMITIR<br/>sujeito a M4 e M5"]
    IN008 -- "Não usado, etiquetas soltas" --> PC002{"PC-002 REVER<br/>IN-010: verificável, reetiquetável e revendível?"}
    PC002 -- "Sim" --> M4_Apr1([Aprovado, seguir para M4])
    PC002 -- "Não" --> R_PC002["RECUSAR"]
    
    IN008 -- "Não usado, sem etiquetas" --> PC003{"PC-003 REVER<br/>IN-010: verificável e preparável para revenda?"}
    PC003 -- "Sim" --> EX001["EX-001 Critério da gestão"]
    EX001 --> M4_Apr1
    PC003 -- "Não" --> R_PC003["RECUSAR"]
    
    IN008 -- "Claramente usado" --> PC004{"PC-004 REVER<br/>Gestão aprova troca pelo mesmo artigo?"}
    PC004 -- "Sim" --> Apr_Swap["Só troca pelo mesmo artigo<br/>sem numerário nem crédito sem restrições"]
    PC004 -- "Não" --> R_PC004["RECUSAR reembolso"]
    
    IN008 -- "Lavado" --> PC005["PC-005 RECUSAR"]
```

Avalia se a peça pode ser aceite. Começa pelas paragens obrigatórias (SKU não reconhecido, marcas excluídas, peças personalizadas ou alteradas), que recusam o pedido de imediato. O bodywear é aceite em qualquer estado e os defeitos de fabrico confirmados dão direito a reembolso ou substituição [3]. Nos restantes casos, o estado físico da peça determina o desfecho: aceitação direta, recusa, isolamento por risco biológico ou revisão pela gestão quando a decisão depende de critério humano.

---

### 4.4.3. Comprovativo e prazo

#### Figura 4: Fluxograma de validação de comprovativos, prazos e ajustes de preço

```mermaid
flowchart TD
    VM3([Produto elegível, vindo de M3]) --> IN005{"IN-005<br/>Tipo de pedido?"}
    
    IN005 -- "Ajuste de preço" --> PT007{"PT-007<br/>Compra em loja, até 14 dias,<br/>recibo original, artigo idêntico<br/>e sem ajuste anterior?"}
    PT007 -- "Sim" --> AprAdj["PERMITIR ajuste único<br/>pela diferença calculada no POS"]
    PT007 -- "Não" --> PT008["PT-008 RECUSAR ajuste"]
    
    IN005 -- "Devolução, troca ou oferta" --> IN003{"IN-003<br/>levi.com ou levi.ca?"}
    IN003 -- "Sim" --> GoOnline([Ir para o caminho online])
    IN003 -- "Não" --> PT001{"PT-001<br/>Comprovativo válido confirma a compra?"}
    
    PT001 -- "Sim" --> IN006{"IN-006<br/>Dias desde a compra?"}
    IN006 -- "Até 30" --> PT003["PT-003 PERMITIR<br/>reembolso total no meio original<br/>ou troca elegível"]
    IN006 -- "Mais de 30" --> PT004{"PT-004 REVER<br/>Vendável, verificável e de baixo risco?"}
    PT004 -- "Sim" --> CredLoja["Crédito de loja"]
    PT004 -- "Não" --> R_PT004["RECUSAR"]
    PT004 -.-> EX001["EX-001 Critério da gestão"]
    
    PT001 -- "Não" --> PT002["PT-002 Devolução às cegas"]
    PT002 --> PT006{"PT-006<br/>Cliente recusa dados ou barreira linguística?"}
    PT006 -- "Sim" --> Skip["Selecionar Saltar"]
    PT006 -- "Não" --> PT005["PT-005 PERMITIR só troca<br/>ou crédito de loja ao preço de venda atual"]
    Skip --> PT005
    
    PT003 --> GoM6([Ir para M6])
    CredLoja --> GoM6
    PT005 --> GoM6
```

Trata primeiro os pedidos de ajuste de preço, permitidos uma única vez em compras em loja até 14 dias. Para devoluções e trocas, verifica se existe comprovativo válido. Com comprovativo, aplica o prazo de 30 dias: dentro do prazo, o reembolso é total; fora dele, a decisão passa pela gestão [3]. Sem comprovativo, a devolução é feita às cegas e só dá direito a troca ou crédito de loja ao preço atual.

---

### 4.4.4. Caminho online da levi.com e levi.ca

#### Figura 5: Tratamento de devoluções de compras online (levi.com e levi.ca) em loja física

```mermaid
flowchart TD
    InitOnline([Compra em levi.com ou levi.ca]) --> PT001{"PT-001<br/>Encomenda encontrada?"}
    
    PT001 -- "Não" --> CH003{"CH-003<br/>A política permite devolução às cegas?"}
    CH003 -- "Não" --> R_Onl["RECUSAR"]
    CH003 -- "Sim" --> CH004{"CH-004<br/>Portal online indisponível?"}
    CH004 -- "Sim" --> BlindOrig["Às cegas no meio original"]
    CH004 -- "Não" --> BlindGC["Às cegas com cartão de oferta"]
    
    PT001 -- "Sim" --> CH002["CH-002 ENCAMINHAR<br/>Processar na BackPocket"]
    CH002 --> IN009{"IN-009<br/>Pago com Afterpay?"}
    
    IN009 -- "Sim" --> TN010["TN-010<br/>Reembolso na BackPocket para o método original"]
    TN010 --> AskAft{"Cliente pede troca, cartão de oferta, numerário ou outro meio?"}
    AskAft -- "Sim" --> HS005["HS-005 RECUSAR a exceção,<br/>reembolsar através da Afterpay"]
    AskAft -- "Não" --> ReembAft["Reembolso Afterpay"]
    
    IN009 -- "Não" --> CH005{"CH-005<br/>Enviado há mais de 30 dias?"}
    CH005 -- "Sim" --> IssueGC["Cartão de oferta"]
    CH005 -- "Não" --> IN005{"IN-005<br/>Pedido de troca?"}
    IN005 -- "Sim" --> CH006["CH-006 Concluir a troca,<br/>saldo ao meio original"]
    IN005 -- "Não" --> IN001{"IN-001 == EUA e cliente pede<br/>cartão de oferta eletrónico?"}
    IN001 -- "Sim" --> eGC["Cartão de oferta eletrónico"]
    IN001 -- "Não" --> OrigTend["Reembolso no meio original, ver M7"]
```

Define o tratamento das compras online devolvidas em loja. Se a encomenda for encontrada, é processada na BackPocket, com regras próprias para a Afterpay, que não admite exceções ao meio de reembolso. O meio de reembolso depende do tempo decorrido desde o envio, de se tratar de uma troca e do mercado [3]. Se a encomenda não for encontrada, a devolução às cegas só é aceite quando a política o permite.

---

### 4.4.5. Resultado, troca e exceções

#### Figura 6: Fluxo integrado para regras de troca, resolução de contestações e aprovação de exceções

```mermaid
flowchart TD
    subgraph E1 [Entrada 1: Trocas Normais]
        M45([Resultado de M4, M5 ou caminho online]) --> IsSwap{"IN-005<br/>É uma troca?"}
        IsSwap -- "Não" --> GoM7([Ir para M7])
        IsSwap -- "Sim" --> EP001{"EP-001<br/>Com recibo e muda só o tamanho?"}
        EP001 -- "Sim" --> KeepPrice["Manter preço original ou promocional"]
        EP001 -- "Não" --> EP002["EP-002 Devolver pelo valor elegível e vender o novo ao preço atual"]
        KeepPrice --> HasBal{"Fica saldo reembolsável?"}
        HasBal -- "Sim" --> TN006["TN-006 Saldo ao cartão original"]
        HasBal -- "Não" --> GoM8_1([Ir para M8])
        EP002 --> GoM8_1
    end

    subgraph E2 [Entrada 2: Contestações e Exceções]
        Contest([Cliente contesta o resultado]) --> EX002["EX-002 Explicar a política e oferecer a melhor alternativa conforme"]
        EX002 --> IsAngry{"Cliente irritado ou cria perturbação?"}
        IsAngry -- "Não" --> KeepStd["Manter o resultado padrão"]
        IsAngry -- "Sim" --> EX003["EX-003 Escalar para o responsável sénior"]
        EX003 --> EX004{"EX-004<br/>Sem regras HS, verificável,<br/>sem fraude e concluível no sistema?"}
        EX004 -- "Não" --> R_Exc1["RECUSAR a exceção"]
        EX004 -- "Sim" --> EX006{"EX-006<br/>Exige meio proibido, SKU incorreto,<br/>produto excluído ou contornar Afterpay,<br/>PayPal, Venmo ou processo online?"}
        EX006 -- "Sim" --> R_Exc2["RECUSAR a exceção, usar o processo obrigatório"]
        EX006 -- "Não" --> EX005{"EX-005<br/>Artigo vendável?"}
        EX005 -- "Não" --> R_Exc3["RECUSAR"]
        EX005 -- "Sim" --> LeastExp["Resolução menos abrangente:<br/>1. troca pelo mesmo artigo<br/>2. crédito de loja<br/>3. reembolso no meio original"]
        LeastExp --> EX007["EX-007 Documentar motivo, aprovador,<br/>valor, resultado, preocupação e destino"]
        EX007 --> GoM7_2([Ir para M7])
    end

    subgraph E3 [Entrada 3: Revisão da Gestão]
        ReverEntry([Regra devolveu REVER<br/>PC-002, PC-003, PC-004 ou PT-004]) --> EX001["EX-001 Avaliar revenda, comprovativo, tempo, valor, risco de fraude e circunstâncias"]
        EX001 --> EX006
    end
```

Tem três entradas. Nas trocas, mantém o preço original quando só muda o tamanho e trata qualquer outra troca como devolução seguida de nova venda. Quando o cliente contesta o resultado, o fluxo começa por explicar a política e só escala para o responsável sénior em caso de perturbação [3]. Os casos marcados como REVER passam pelo critério da gestão. Qualquer exceção é recusada se violar controlos obrigatórios e, quando aprovada, segue a resolução menos abrangente e fica documentada [1].

---

### 4.4.6. Valor da devolução

#### Figura 7: Fluxograma de determinação do valor de reembolso conforme o tipo de comprovativo e promoções

```mermaid
flowchart TD
    InitVal([Transação com reembolso, troca ou crédito]) --> ProofType{"Tipo de comprovativo?"}
    
    ProofType -- "Às cegas" --> IsOutletBlind{"IN-002<br/>Loja Outlet?"}
    IsOutletBlind -- "Sim" --> CH009["CH-009 Preço atual após as promoções da Outlet"]
    IsOutletBlind -- "Não" --> PT005["PT-005 Preço de venda atual"]
    CH009 --> TierBlind{"Promoção por escalões?"}
    PT005 --> TierBlind
    TierBlind -- "Sim" --> EP003["EP-003 Escalão pelo número de artigos devolvidos nesta transação"]
    TierBlind -- "Não" --> StoreCredOut["Troca ou crédito de loja"]
    EP003 --> StoreCredOut
    
    ProofType -- "Com recibo" --> CrossOutlet{"Origem Mainline ou Online e loja recetora Outlet?"}
    CrossOutlet -- "Sim" --> CH010["CH-010 PVP original, se POS e política permitirem"]
    CrossOutlet -- "Não" --> OrigPaid["Valor original pago"]
    CH010 --> TierRcpt{"Promoção por escalões?"}
    OrigPaid --> TierRcpt
    TierRcpt -- "Sim" --> EP004["EP-004 Valor calculado pelo POS com a quantidade original"]
    TierRcpt -- "Não" --> GoTender([Ir para o meio de reembolso])
    EP004 --> GoTender
```

Calcula o valor a devolver a partir do tipo de comprovativo. Nas devoluções às cegas, usa o preço atual, considerando as promoções da Outlet. Nas devoluções com recibo, usa o valor pago, ou o PVP original quando um artigo da Mainline ou online é devolvido numa Outlet [3]. Em ambos os casos, as promoções por escalões são recalculadas segundo regras próprias.

---

### 4.4.8. Meio de reembolso

#### Figura 8: Fluxograma de determinação do meio de reembolso com base no método de pagamento original

```mermaid
flowchart TD
    InitTender([Reembolso de devolução verificada]) --> IsGift{"IN-005<br/>Devolução de oferta?"}
    
    IsGift -- "Sim" --> TN007["TN-007 Reembolso tokenizado ao cartão do comprador, ou crédito de loja"]
    IsGift -- "Não" --> OrigMethod{"IN-009<br/>Meio de pagamento original?"}
    
    OrigMethod -- "Crédito ou débito" --> TN001["TN-001 Reembolso tokenizado, sem pedir o cartão"]
    TN001 --> AccState{"Estado da conta?"}
    AccState -- "Ativa" --> RefCard["Cartão original"]
    AccState -- "Ativa, cartão perdido/roubado" --> TN002["TN-002 Conta do cartão original"]
    AccState -- "Encerrada" --> TN003{"TN-003 Tentativa ao cartão original recusada?"}
    TN003 -- "Sim" --> AltTender["Outro cartão, numerário ou cartão de oferta"]
    TN003 -- "Não (débito)" --> TN004["TN-004 Débito: sem numerário antes da recusa"]
    
    OrigMethod -- "Apple Pay ou Google Pay" --> TN005["TN-005 Cartão ou conta associada"]
    OrigMethod -- "PayPal ou Venmo" --> TN008["TN-008 Fluxo da aplicação sem substituir o meio"]
    OrigMethod -- "Afterpay, compra em loja" --> TN009["TN-009 Cliente localiza a encomenda na app; devolução total à Afterpay e recibo do POS"]
    
    OrigMethod -- "Interac, Canadá" --> TN011{"TN-011<br/>Mesmo cartão físico presente?"}
    TN011 -- "Não" --> InteracFail["Não processar sem o cartão nem inserir manualmente"]
    TN011 -- "Sim" --> IsBP{"Compra em loja BackPocket?"}
    IsBP -- "Sim" --> TN012["TN-012 Concluir na BackPocket, reembolso manual na VeriFone pelo valor exato"]
    IsBP -- "Não" --> InteracPOS["Reembolso Interac no POS"]
    
    OrigMethod -- "Numerário ou cartão de oferta" --> OrigCash["Reembolso no meio original, PT-003"]
```

Determina para onde vai o dinheiro numa devolução verificada, consoante o meio de pagamento original. Os cartões são reembolsados por tokenização, sem o cliente ter de os apresentar, e um meio alternativo só é usado quando a conta está encerrada e a tentativa ao cartão original é recusada. PayPal, Venmo e Afterpay seguem obrigatoriamente o fluxo das respetivas aplicações [3]. O Interac, no Canadá, exige a presença do cartão físico.

---

### 4.4.9. Controlos e documentação

#### Figura 9: Fluxograma de controlos, aprovações e documentação da transação

```mermaid
flowchart TD
    Resolved([Transação resolvida]) --> RetType{"Tipo de devolução?"}
    
    RetType -- "Às cegas" --> CT002{"CT-002<br/>Processador é Lead Cashier ou Elevated Stylist?"}
    CT002 -- "Sim" --> MgrAppr["Obter aprovação do XStore Manager"]
    CT002 -- "Não" --> CT005_1["CT-005 Assinaturas: cliente ou Recusado; processador; testemunha ou SSC"]
    MgrAppr --> CT005_1
    
    RetType -- "Verificada" --> CT001["CT-001 Pessoal autorizado com credenciais próprias"]
    CT001 --> CT004["CT-004 Atribuir ao Stylist da venda original"]
    CT004 --> CT005_2["CT-005 Assinaturas"]
    
    CT005_1 --> CT006{"CT-006<br/>Recibo original entregue?"}
    CT005_2 --> CT006
    
    CT006 -- "Sim" --> Staple["Agrafar ao exemplar da loja"]
    CT006 -- "Não, ou tem outros artigos" --> Annotate["Anotar no exemplar da loja"]
    
    Staple --> HadExc{"Houve exceção aprovada?"}
    Annotate --> HadExc
    
    HadExc -- "Sim" --> EX007["EX-007 Documentar a exceção"]
    HadExc -- "Não" --> CT007["CT-007 Reter suportes 90 dias; online com os suportes diários"]
    EX007 --> CT007
    CT007 --> GoDest([Ir para o destino do produto])
```

Garante que a transação fica corretamente autorizada e registada. As devoluções às cegas processadas por Lead Cashier ou Elevated Stylist exigem aprovação do XStore Manager, e as devoluções verificadas são atribuídas ao Stylist da venda original [3]. Em todos os casos são recolhidas as assinaturas, tratado o recibo, documentadas as exceções aprovadas e retidos os suportes durante 90 dias.

---

### 4.4.10. Destino do produto

#### Figura 10: Fluxograma de encaminhamento e destino do produto após devolução

```mermaid
flowchart TD
    InitDest([Produto recebido]) --> IsBio{"Sujo, contaminado ou inseguro?"}
    
    IsBio -- "Sim" --> Bio["PC-008 e BW-004 Risco biológico: saco, etiquetar e datar,<br/>sala de reservas, e-mail ao corporativo; aguardar eliminação"]
    IsBio -- "Não" --> IsBW{"Bodywear?"}
    
    IsBW -- "Sim" --> BW003{"BW-003<br/>Faltam unidades ou foi usado?"}
    BW003 -- "Sim" --> DmgOutSet["Baixa por dano do conjunto"]
    BW003 -- "Não" --> OrigPack{"Embalagem original intacta?"}
    OrigPack -- "Sim" --> BW001{"BW-001<br/>Inspeção confirma não usado e vendável?"}
    BW001 -- "Sim" --> SalesFloor([Área de vendas])
    BW001 -- "Não" --> DmgOutSet
    OrigPack -- "Não" --> BW002["BW-002 Saldos com 50% de desconto, código de barras riscado a vermelho"]
    BW002 --> SalesFloor
    
    IsBW -- "Não" --> PC006{"PC-006<br/>Defeito de fabrico?"}
    PC006 -- "Sim" --> DmgOutSingle["Baixa por dano"]
    PC006 -- "Não" --> CT008{"CT-008<br/>Inspeção de dano, etiquetas e RFID"}
    CT008 -- "Com dano" --> DmgOutSingle
    CT008 -- "Etiquetas ou RFID incorretos" --> Retag["Reetiquetar e corrigir RFID"]
    CT008 -- "Conforme" --> CrossCh{"Artigo entre canais?"}
    Retag --> CrossCh
    
    CrossCh -- "Não" --> SalesFloor
    CrossCh -- "Sim" --> EP007{"EP-007<br/>Já está em saldo?"}
    EP007 -- "Sim" --> SalePromo["Saldos com as promoções atuais"] --> SalesFloor
    EP007 -- "Não" --> EP005{"EP-005<br/>Está ou esteve no sortido da loja recetora?"}
    EP005 -- "Sim" --> Reprice["Reprecificar ao preço atual e devolver à área de vendas"] --> SalesFloor
    EP005 -- "Não" --> EP006["EP-006 Saldos com 20% de desconto sobre o preço devolvido"] --> SalesFloor
```

Decide o que acontece à peça depois de aceite. Os artigos sujos ou inseguros são isolados como risco biológico. O bodywear segue regras próprias, que vão da revenda à baixa por dano do conjunto [3]. Os restantes artigos são inspecionados antes de voltarem à venda. Os artigos de outros canais são reprecificados ou colocados em saldos, conforme estejam ou não no sortido da loja recetora.

---

### 4.5. Exemplos de formalização

```prolog
REGRA HS-003
  SE produto.personalizado = sim OU produto.alterado = sim
  ENTÃO elegibilidade ← RECUSAR ; PARAR
  justificação ← "Peça alterada não é devolvível, mesmo com defeito"

REGRA PC-002
  SE estado = não_usado E etiquetas = soltas
  ENTÃO elegibilidade ← REVER
  perguntar("A peça pode ser verificada, reetiquetada e revendida?")

REGRA PT-003
  SE comprovativo ∈ VÁLIDOS E dias ≤ 30 E produto.elegível = sim
  ENTÃO elegibilidade ← PERMITIR
  tipo ∈ {reembolso, troca} ; valor ← valor_pago ; meio ← original

REGRA PT-005
  SE comprovativo = nenhum E produto.elegível = sim
  ENTÃO elegibilidade ← PERMITIR
  tipo ∈ {troca, crédito_loja} ; valor ← preço_atual
```

### 4.6. Prioridade entre regras
A política fornecida pelo perito não define prioridades. No entanto, em caso de conflitos, prevalecerá o nível mais alto e, em casos do mesmo nível, será escolhida a regra mais específica [1]. Com isso, foi proposta a seguinte ordem:

1. **Pré-condição de autorização do colaborador** (`HS-006`).
2. **Encaminhamentos obrigatórios**, para o canal de execução da compra (`CH-002`, `CH-007`, `CH-008`).
3. **Regras de paragem obrigatória**, verificação da procedência e situação do produto a nível de sistema (`HS-001` a `HS-004`).
4. **Regras de segurança**, que disparam sempre, independente da elegibilidade (`PC-008`, `BW-004`).
5. **Regras específicas de categoria do produto** (`PC-007`, Bodywear) antes das regras gerais do estado do produto (`PC-001` a `PC-005`).
6. **Comprovativo de compra** (`PT-001` a `PT-008`, `CH-003`), e **prazo específico para método de reembolso** (`CH-005`).
7. **Regras de exceções da gestão** (`EX-001` a `EX-008`), que nunca anulam as regras de Paragens Obrigatórias, Estado do Produto e Comprovativo e Prazo (`EX-004`, `EX-006`).

> A agitação e atitude de um cliente não é modelada como facto de entrada (`EX-003`), e essa situação não altera a elegibilidade, apenas desencadeia o escalonamento.

---

## 5. Bibliografia

* **[1]** D. Hopper, *“Returns & Exchanges Knowledge Base 1,”* 2026.
* **[2]** L. S. & Co., *“Returns and Exchanges,”* setembro 2026. [Online]. Disponível em: `https://help.levi.com/hc/en-us/articles/360052069812-Levi-s-Return-Exchange-Policy`.
* **[3]** D. Hopper, Interviewee, *Entrevistas formais para aquisição e definição do conhecimento.* [Interview]. 18 e 23 Setembro 2026.
* **[4]** L. &. Co., *Documento Impresso - Texto do Recibo do Cliente.*
* **[5]** C. Martins, *“Material da unidade curricular (fichas de exercícios de Prolog e diapositivos das aulas), ISEP - MEIA, Paradigmas da Programação em Inteligência Artificial,”* 2026.
* **[6]** L. Faria, *“Material da unidade curricular e bibliografia indicada, ISEP - MEIA, Engenharia do Conhecimento,”* Porto, 2026.
* **[7]** SWI-Prolog, *“Swi-Prolog Reference manual,”* outubro 2026. [Online]. Disponível em: `https://www.swi-prolog.org/pldoc/doc_for?object=manual`.
* **[8]** Apache Kie, *“Drools Documentation, Vers. 10.2.0.,”* outubro 2026. [Online]. Disponível em: `https://kie.apache.org/docs/10.2.x/drools/drools/introduction/`.

---

## 6. Terminologia específica

#### Tabela 8: Terminologia específica aplicada no contexto das devoluções
| Termo | Definição |
| :--- | :--- |
| **Bodywear** | Roupa interior e peças de contacto direto com a pele, com regras próprias de aceitação e destino. |
| **Crédito de loja** | Valor atribuído ao cliente para compras futuras, em vez de reembolso. |
| **BackPocket** | Serviço omnicanal em loja física que permite a um colaborador encomendar diretamente um artigo para o cliente quando o stock não se encontra disponível na loja local. O pedido é processado através do sistema interno e expedido tal como uma encomenda habitual da Levi.com. |
| **AfterPay, Venmo, Interac** | Referem-se aos métodos e plataformas de pagamento digitais disponibilizados a clientes na América do Norte (EUA e Canadá), integrados nos pontos de venda físicos e no comércio eletrónico. |
| **Mainline / Outlet** | Referem-se aos dois principais formatos de lojas físicas no modelo de retalho (*retail*), diferenciados pela estratégia comercial, sortido de produto e posicionamento de preço:<br/>• **Mainline (Full-Price Retail):** Lojas de conceito principal e preço regular. Focam-se nas coleções atuais, lançamentos sazonais, linhas premium e na experiência completa da marca, servindo como a principal montra comercial e de imagem.<br/>• **Outlet (Value / Factory Store):** Lojas focadas em valor e preços reduzidos. O sortido é tipicamente composto por linhas desenhadas especificamente para este canal (*made-for-outlet*), excedentes de inventário (*clearance*) e artigos de coleções anteriores, com foco em rotação rápida e descontos permanentes. |
| **Lead Cashier** | Função operacional no piso de loja responsável por coordenar a área dos caixas (*cash wrap*) e apoiar as transações financeiras diárias, servindo de ponte entre os operadores de caixa (*cashiers*) e a equipa de gestão de loja. |
| **XStore Manager** | Refere-se ao módulo de gestão de retalho e back-office da solução de ponto de venda Oracle Retail Xstore (ou ao perfil de funções de gerência dentro da aplicação), utilizado pela equipa de gestão para controlar as operações diárias da loja. |
| **Stylist** | Função orientada para o serviço ao cliente e consultoria de produto no piso de loja, focada em proporcionar uma experiência de compra personalizada e aumentar a conversão de vendas. |
| **Elevated Stylist** | Nível avançado da função de Stylist no retalho, reservado a colaboradores com experiência consolidada e elevado domínio técnico, focados na fidelização de clientes e na condução de vendas de valor superior. |
| **SKU** | Código alfanumérico único atribuído internamente a cada produto para identificar e rastrear o inventário no sistema de retalho e na cadeia de abastecimento. |
| **PVP** | Valor final fixado para a comercialização de um produto diretamente ao consumidor final no retalho. |
