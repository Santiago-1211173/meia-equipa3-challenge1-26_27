# Sistema Pericial de Diagnóstico para Devoluções e Trocas no Retalho (Levi's)
### *Entrega Curricular de Engenharia do Conhecimento em Inteligência Artificial (ENGCIA)*
#### *Mestrado em Engenharia de Inteligência Artificial (MEIA 2026/2027) — Desafio 1 · Equipa 3*

---

## 1. Identificação e Enquadramento

* **Unidade Curricular:** Engenharia do Conhecimento em Inteligência Artificial (ENGCIA)
* **Curso:** Mestrado em Engenharia de Inteligência Artificial (MEIA), Instituto Superior de Engenharia do Porto (ISEP)
* **Desafio:** Desafio 1 — Sistema Pericial de Devoluções e Trocas no Retalho (Caso de Uso: *Levi Strauss & Co.*)
* **Equipa 3:** SmartCloth AI
* **Perito de Domínio Humano:** Dustin Hopper (Especialista em Políticas Globais de Retalho Levi's)
* **Paradigma Tecnológico:** Regras de Produção Empresariais (*Production Rules*) com Apache KIE Drools 8/9, Spring Boot 3 e Java 21 LTS

Este pacote de entrega é **100% autónomo**, focado exclusivamente na modelação formal de conhecimento, engenharia de regras de produção e explicabilidade pericial em **Java / Drools**, sem necessidade de instalação de SWI-Prolog, Python ou Node.js.

---

## 2. Requisitos de Execução

* **Java Development Kit (JDK):** Versão 21 LTS (testado e validado em OpenJDK 21 Temurin).
  ```bash
  java -version
  ```
* **Apache Maven:** Versão 3.6.3 ou superior (recomendado Maven 3.9+).
  ```bash
  mvn -version
  ```
* **Docker & Docker Compose:** Opcional, para arranque da base de dados PostgreSQL isolada com 1 comando.

---

## 3. Arranque Rápido em 2 Passos (1-Click Run)

A forma mais rápida e reproduzível para o docente avaliar o sistema pericial consiste nos seguintes passos:

### Passo 1: Iniciar a Base de Dados PostgreSQL Isolada
```bash
docker compose -f docker-compose-minimal.yml up -d
```
> O contentor `drools-levis-postgres` arranca na porta `5432` com a base de dados `pericial` pronta a receber conexões (credenciais: `pericial`/`pericial`).

### Passo 2: Compilar e Iniciar a Aplicação Pericial
Em Linux / macOS:
```bash
./run.sh
```
Em Windows:
```cmd
run.bat
```

O script compila o projeto Maven (`mvn package -DskipTests -q`) e arranca o servidor Spring Boot com a API Drools na porta `8082` (perfil `dev`).

### Acesso aos Serviços e Documentação Interativa:
* **Swagger UI / Documentação OpenAPI:** [http://localhost:8082/swagger-ui.html](http://localhost:8082/swagger-ui.html)
* **Especificação OpenAPI JSON:** [http://localhost:8082/v3/api-docs](http://localhost:8082/v3/api-docs)
* **Endpoint de Diagnóstico / Avaliação:** `POST http://localhost:8082/api/v1/avaliacoes`
* **Healthcheck Actuator:** [http://localhost:8082/actuator/health](http://localhost:8082/actuator/health)

---

## 4. Execução de Testes Automatizados

Para executar toda a suite de testes de regras DRL, rastreio de agenda, explicabilidade e integração:

Em Linux / macOS:
```bash
./test.sh
```
Em Windows:
```cmd
test.bat
```
Ou diretamente via Maven:
```bash
mvn clean test
```

> **Garantia de Qualidade:** O projeto conta com **40+ testes automatizados** distribuídos entre regras periciais isoladas (`pericial-rules`), motores de explicabilidade (`pericial-explanation`), validação de arquitetura via ArchUnit e cenários ponta a ponta (`pericial-api`), com 100% de sucesso.

---

## 5. Mapeamento Exaustivo: Base de Conhecimento vs. Ficheiros DRL

O conhecimento normativo de trocas e devoluções da Levi's (formalizado em `docs/01-base-conhecimento.md` e decomposto em regras IF/THEN em `docs/02-regras-if-then.md`) foi estruturado em **12 ficheiros de regras DRL** localizados em:
`backend/pericial-rules/src/main/resources/com/levis/devolucoes/regras/`

### 5.1 Portas de Controlo e Dependências Globais (Control Gates)
Para assegurar modularidade, segurança e evitar redundâncias, a inferência Drools governa-se por 5 Portas de Controlo:

| Porta | Designação | Condição de Passagem | Guardas Drools |
|:---:|:---|:---|:---|
| **G0** | Colaborador Autorizado | Nenhuma violação de `HS-006` | Validação de credencial de caixa própria |
| **G1** | Canal Tratável em Loja | Compra não grossista (`CH-008`) nem franquia não suportada (`CH-007`) | Triagem de canal de origem |
| **G2** | Produto Elegível | Não é parada obrigatória (`HS-001`, `HS-002`, `HS-003`, `HS-004`) | SKU válido, marca própria, sem alterações |
| **G3** | Estado Aceite | Cumpre `PC-001`, aprovação em `PC-002`/`PC-003`, defeito `PC-006` ou `PC-007` | Verificação de uso e etiquetas |
| **G4** | Comprovativo Classificado | Triagem entre Verificada (`PT-001`) ou Às Cegas (`PT-002`) | Classificação temporal e documental |

---

### 5.2 Matriz de Mapeamento dos Ficheiros DRL

| Ficheiro DRL | Etapa / Módulo | Regras Implementadas | Agenda-Group | Salience | Descrição e Papel Pericial |
|:---|:---|:---|:---|:---:|:---|
| [`m0-autorizacao.drl`](backend/pericial-rules/src/main/resources/com/levis/devolucoes/regras/m0-autorizacao.drl) | **Etapa 0** (Autorização) | `HS-006`, `CT-003` | `M0` | 90–100 | Valida a legitimidade do colaborador do POS e impede a partilha de credenciais de caixa. |
| [`m2-canal.drl`](backend/pericial-rules/src/main/resources/com/levis/devolucoes/regras/m2-canal.drl) | **Etapas 1 e 2** (Canal e Mercado) | `CH-001`, `CH-007`, `CH-008`, `IN-003` | `M2` | 50–100 | Triagem de canais físicos (Mainline, Outlet), recusa de produtos de grossistas e reencaminhamento de franquias canadianas. |
| [`m3-elegibilidade.drl`](backend/pericial-rules/src/main/resources/com/levis/devolucoes/regras/m3-elegibilidade.drl) | **Etapa 3** (Elegibilidade do Artigo) | `HS-001` a `HS-004`, `PC-001` a `PC-008`, `IN-010` | `M3` | 20–100 | Núcleo de paragens obrigatórias (marcas não aceites como Dockers/Beyond Yoga, artigos alterados ou bainhas) e avaliação do estado físico (etiquetas soltas, uso, defeito, bodywear). |
| [`m4-m5-comprovativo-prazo.drl`](backend/pericial-rules/src/main/resources/com/levis/devolucoes/regras/m4-m5-comprovativo-prazo.drl) | **Etapas 4 e 5** (Comprovativo e Prazos) | `PT-001` a `PT-008` | `M4` | 50–100 | Classificação de compras físicas como verificadas vs. devoluções às cegas; aplicação do prazo geral de 30 dias e janela de 14 dias para ajuste de preço. |
| [`online.drl`](backend/pericial-rules/src/main/resources/com/levis/devolucoes/regras/online.drl) | **Canal Digital** (BackPocket / levi.com) | `CH-002` a `CH-006`, `HS-005`, `TN-010` | `ONLINE` | 50–100 | Regras específicas para compras online devolvidas em loja física, tratamento da aplicação BackPocket e proibição estrita de exceções em Afterpay (`HS-005`). |
| [`m6-resultado-excecoes.drl`](backend/pericial-rules/src/main/resources/com/levis/devolucoes/regras/m6-resultado-excecoes.drl) | **Etapa 6** (Resultados e Exceções) | `EP-001` a `EP-003`, `EX-001` a `EX-007` | `M6` | 30–100 | Lógica de trocas (mesmo tamanho vs. modelo/cor diferente) e governação de exceções operacionais (contestações com aprovação da gestão de loja). |
| [`m7-valor.drl`](backend/pericial-rules/src/main/resources/com/levis/devolucoes/regras/m7-valor.drl) | **Etapa 7** (Cálculo do Valor) | `EP-004` a `EP-006`, `CH-009`, `CH-010` | `M7` | 50–100 | Determinação da base de valor a reembolsar: valor original pago no recibo, preço de venda atual (para devoluções às cegas) ou preço promocional da Outlet. |
| [`m7-meio-reembolso.drl`](backend/pericial-rules/src/main/resources/com/levis/devolucoes/regras/m7-meio-reembolso.drl) | **Etapa 7** (Meio de Pagamento) | `TN-001` a `TN-009`, `TN-011` a `TN-014` | `M7` | 20–100 | Resolução do meio de reembolso: tokenização de cartão, numerário, cheque corporativo para valores elevados, Afterpay, PayPal, Apple Pay e cartões de oferta. |
| [`m8-controlos.drl`](backend/pericial-rules/src/main/resources/com/levis/devolucoes/regras/m8-controlos.drl) | **Etapa 8** (Controlos e Fraude) | `CT-001`, `CT-002`, `CT-004` a `CT-007` | `M8` | 50–90 | Exigência de assinaturas do cliente, retenção documental de faturas e sinalização de indicadores de risco/fraude. |
| [`m9-destino.drl`](backend/pericial-rules/src/main/resources/com/levis/devolucoes/regras/m9-destino.drl) | **Destino do Produto** | `BW-001` a `BW-004`, `OUT-007` a `OUT-010` | `M9` | 50–100 | Encaminhamento logístico do artigo devolvido: retorno ao expositor de loja, reetiquetagem, envio para centro de destruição, baixa por defeito ou isolamento biológico. |
| [`transversais.drl`](backend/pericial-rules/src/main/resources/com/levis/devolucoes/regras/transversais.drl) | **Regras Transversais** (Auto-Focus) | `EX-008`, `PC-008` | `TRANSVERSAIS` | 1000 | Regras de paragem imediata com `auto-focus true`: perigo biológico (`PC-008`) e recusa definitiva por fraude reincidente (`EX-008`). |
| [`consultas.drl`](backend/pericial-rules/src/main/resources/com/levis/devolucoes/regras/consultas.drl) | **Queries Declarativas** | Consultas KIE | *N/A* | *N/A* | Interrogação programática da Working Memory para inspeção de factos deduzidos, artigos elegíveis e rastreio de auditoria. |

---

## 6. Arquitetura da Solução (Maven Multi-Módulo)

O projeto adota uma arquitetura desacoplada e modular dividida em **7 submódulos Maven**:

```
drools-engine-levis-devolucoes-java/
├── pom.xml                                   # POM agregador (Maven Multi-Módulo)
├── docker-compose-minimal.yml                # PostgreSQL isolado (porta 5432)
├── run.sh / run.bat                          # Scripts de arranque 1-click (:8082)
├── test.sh / test.bat                        # Scripts de execução de testes unitários
├── README_ENTREGA.md                         # Manual de entrega e avaliação ENGCIA
├── docs/                                     # Especificações formais e matrizes de decisão
│   ├── 01-base-conhecimento.md               # Base de conhecimento canónica (Dustin Hopper)
│   ├── 02-regras-if-then.md                  # Especificação das regras IF/THEN
│   ├── 03-fluxograma.md                      # Diagrama de fluxo operacional
│   ├── 04-diagrama-classes.md                # Modelo de domínio UML
│   ├── 05-estrutura-projeto.md               # Detalhes da arquitetura de software
│   ├── 06-casos-teste.md                     # 10 cenários normativos da Levi's
│   ├── 07-plano.md                           # Planeamento executivo
│   └── relatorio_final_engcia.pdf            # [Anexo] Relatório Formal de Aquisição
│
└── backend/
    ├── pericial-model/                       # MODEL: Entidades de domínio puras (POJOs Java 21)
    ├── pericial-rules/                       # KJAR: Base de regras Drools 8 compilada com kie-maven-plugin
    ├── pericial-explanation/                 # EXPLICABILIDADE: 5 vias (Como, Porquê, Porque Não, E Se, Em Falta)
    ├── pericial-dto/                         # DTO: Contratos REST imutáveis (Records)
    ├── pericial-persistence/                 # PERSISTÊNCIA: Entidades JPA, auditoria e migrações Flyway
    ├── pericial-service/                     # SERVICE: Orquestração do KIE Container e serviços de aplicação
    └── pericial-api/                         # API: Aplicação Spring Boot 3 executável com OpenAPI/Swagger
```

---

## 7. Mecanismos Formais de Explicabilidade (Módulo `pericial-explanation`)

Em cumprimento rigoroso dos princípios de Engenharia do Conhecimento, o motor não se comporta como uma caixa negra, disponibilizando **5 vias formais de explicabilidade pericial**:

1. **Explicação "Como" (*How*):** Apresenta a cadeia causal retrospetiva de todas as regras que dispararam para produzir o veredito final, com premissas satisfeitas e marcas temporais.
2. **Explicação "Porquê" (*Why*):** Justifica a exigência de dados e atributos específicos da loja, apresentando a regra candidata que se encontra pendente de prova.
3. **Explicação "Porque Não" (*Why Not*):** Analisa contrafactualmente por que razão uma dada conclusão (ex.: `PERMITIR`) falhou, enumerando as premissas não satisfeitas.
4. **Simulação "E Se" (*What-If*):** Permite simular hipóteses contrafactuais na working memory sem alterar o histórico da base de dados (ex.: *"E se o cliente tivesse apresentado recibo dentro do prazo?"*).
5. **Deteção de "O Que Falta" (*Missing Data*):** Identifica os factos e permissões mínimas necessárias para converter uma recusa ou revisão num desfecho favorável.

---

## 8. Os 10 Cenários Oficiais de Teste e Validação

O sistema foi rigorosamente validado contra os **10 cenários normativos da Levi's** formulados em articulação com o perito Dustin Hopper:

| Cenário | Descrição do Caso de Retalho | Regras Chave Acionadas | Veredito Pericial |
|:---:|:---|:---|:---:|
| **1** | Etiquetas soltas apresentadas, devolução ao 29.º dia | `PC-002`, `EX-001`, `PT-003` | `REVER` (Aprovação de Gestão) |
| **2** | Compra online Afterpay em loja com contestação | `CH-002`, `HS-005`, `EX-006` | `RECUSAR` (Proibição Afterpay) |
| **3** | Recibo de oferta na Outlet sem comprovativo | `PT-002`, `PT-005`, `CH-009` | `PERMITIR` (Crédito de Loja) |
| **4** | Calças com bainha alterada e defeito de fabrico | `HS-003`, `PC-006` | `RECUSAR` (Hard Stop - Alterado) |
| **5** | Disputa sobre devolução de produto grossista (*Wholesale*) | `CH-008`, `EX-002` | `RECUSAR` (Canal de Compra Inválido) |
| **6** | Casaco de couro após 45 dias em bom estado | `PT-004`, `EX-004` | `REVER` (Crédito de Loja Tardia) |
| **7** | Pedido de devolução de bodywear experimentado | `PC-007`, `BW-001` | `PERMITIR` (Destino Baixa/Dano) |
| **8** | Artigo com sangue ou substância perigosa | `PC-008`, `OUT-007` | `RECUSAR` (Risco Biológico) |
| **9** | Devolução em numerário superior a $100 com gaveta sem troco | `TN-004`, `TN-005` | `PERMITIR` (Cheque Corporativo) |
| **10** | Suspeita de fraude e devoluções em série | `CT-006`, `EX-008` | `RECUSAR` (Bloqueio Fraude) |

---

## 9. Exemplos de Interação com a API REST

### 9.1 Avaliação de Pedido de Devolução (`POST /api/v1/avaliacoes`)
```bash
curl -X POST http://localhost:8082/api/v1/avaliacoes \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <TOKEN_DEV>" \
  -d '{
    "loja": { "tipoLoja": "MAINLINE", "mercado": "ESTADOS_UNIDOS" },
    "tipoPedido": "DEVOLUCAO",
    "compraOnline": false,
    "compraOriginal": {
      "canal": "MAINLINE",
      "diasDesdeCompra": 15,
      "meioPagamento": "CARTAO_CREDITO"
    },
    "comprovativo": {
      "tipo": "RECIBO_IMPRESSO",
      "valido": true,
      "confirmaCompra": true
    },
    "artigos": [
      {
        "produto": {
          "sku": "LEVI-501-ORIGINAL",
          "marca": "LEVIS",
          "skuReconhecidoPOS": true,
          "personalizadoOuAlterado": false,
          "categoria": "VESTUARIO"
        },
        "condicaoUso": "NAO_USADO",
        "estadoEtiquetas": "COLOCADAS",
        "defeitoFabrico": false,
        "valorPago": 89.50
      }
    ]
  }'
```

### 9.2 Obter Explicação Causal "Como" (`GET /api/v1/avaliacoes/{id}/explicacoes/como`)
```bash
curl -X GET http://localhost:8082/api/v1/avaliacoes/{avaliacaoId}/explicacoes/como \
  -H "Accept-Language: pt-PT"
```

### 9.3 Simulação Contrafactual "E Se" (`POST /api/v1/simulacoes`)
Permite submeter variações de atributos sobre uma avaliação existente para calcular o impacto nas regras e na decisão final.

---

## 10. Documentação Formal e Relatório de Aquisição

* **Relatório Formal de Aquisição de Conhecimento:** [docs/relatorio_final_engcia.pdf](docs/relatorio_final_engcia.pdf)
* **Base de Conhecimento Original (Dustin Hopper):** [docs/01-base-conhecimento.md](docs/01-base-conhecimento.md)
* **Especificação Formal das Regras IF/THEN:** [docs/02-regras-if-then.md](docs/02-regras-if-then.md)
* **Diagrama de Fluxo Operacional:** [docs/03-fluxograma.md](docs/03-fluxograma.md)
* **Diagrama de Classes de Domínio:** [docs/04-diagrama-classes.md](docs/04-diagrama-classes.md)
* **Decisões de Arquitetura (ADRs):** [docs/adr/](docs/adr/)
