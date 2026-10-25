# 08 — Tratamento da incerteza

> Camada de incerteza do sistema pericial: **fatores de certeza** (risco de fraude), **probabilidade bayesiana** (defeito de fabrico ou desgaste) e **lógica fuzzy** (revendibilidade e recomendação de crédito em PT-004).
>
> **Todos os valores numéricos deste documento são demonstrativos.** Servem para implementar e apresentar as funcionalidades; não foram fornecidos nem validados pela operação. Ficam num ficheiro de parâmetros versionado, marcado `demonstrativo: true`, e a interface mostra esse aviso em todos os resultados.
>
> Este documento complementa `01` a `05` e não altera as regras da base de conhecimento. Em caso de conflito, `01-base-conhecimento.md` prevalece.

## 1. Âmbito e princípios

### 1.1 Onde está a incerteza

A incerteza não está nas regras da política, que continuam nítidas e binárias. Está nos **dados de entrada que dependem de juízo humano** e nas **zonas REVER**, onde a política já admite critério da gestão.

| Problema | Regras afetadas | Técnica | Componente |
|---|---|---|---|
| Risco de fraude | EX-008, EX-004, CT-002 | Fatores de certeza (MYCIN) | §2 |
| Defeito de fabrico ou desgaste | PC-006 vs PC-004/PC-005 | Probabilidade bayesiana (razões de verosimilhança) | §3 |
| Possibilidade de revenda (IN-010) | PC-002, PC-003, EX-005 | Lógica fuzzy | §4.1 |
| Crédito de loja depois dos 30 dias | PT-004 | Lógica fuzzy | §4.2 |

Fora do âmbito desta versão: credibilidade das declarações do cliente (PT-002, TN-007) e redes bayesianas com tabelas de probabilidade condicionada. Ficam para uma fase posterior.

### 1.2 Princípios obrigatórios

1. **A incerteza nunca transforma um RECUSAR num PERMITIR.** As paragens obrigatórias (HS), os prazos explícitos e os processos obrigatórios ficam nítidos. A camada de incerteza só pode:
   - calcular dados derivados (grau de revendibilidade, risco de fraude, probabilidade de defeito);
   - recomendar dentro das zonas REVER;
   - tornar o resultado mais cauteloso: passar PERMITIR a REVER, exigir aprovação, ou suspender (EX-008).
2. **A decisão final nas zonas REVER é humana**, como a regra EX-004 já exige. O sistema apresenta a recomendação e o grau; a gestão decide.
3. **O comportamento do cliente nunca é evidência.** Os atributos `Cliente.agitado`, `Cliente.contestaResultado`, `Cliente.barreiraLinguistica` e `Cliente.forneceDados` não geram evidências em nenhum componente. O documento de casos de teste exige que o comportamento altere o escalonamento sem alterar indevidamente a elegibilidade, e PT-006 proíbe pressionar o cliente a dar dados.
4. **Rastreabilidade total.** Cada grau calculado guarda as contribuições de cada evidência ou regra fuzzy e a versão dos parâmetros usados.
5. **Parâmetros fora do código.** Fatores de certeza, priors, razões de verosimilhança, funções de pertença e limiares ficam num ficheiro versionado (§6), nunca em constantes Java nem em DRL.

## 2. Fatores de certeza — risco de fraude

### 2.1 Combinação (modelo MYCIN)

Cada evidência tem um fator de certeza (CF) entre −1 e 1. Os fatores combinam-se dois a dois, por qualquer ordem (a operação é comutativa e associativa):

| Sinais | Fórmula |
|---|---|
| Ambos ≥ 0 | CF = CF₁ + CF₂ × (1 − CF₁) |
| Ambos < 0 | CF = CF₁ + CF₂ × (1 + CF₁) |
| Sinais opostos | CF = (CF₁ + CF₂) / (1 − min(\|CF₁\|, \|CF₂\|)) |

Sem evidências, o CF é 0.

### 2.2 Evidências (valores demonstrativos)

| Código | Evidência | Fonte | Como é obtida | CF |
|---|---|---|---|---|
| EF-01 | Sem comprovativo verificável | SISTEMA | `comprovativo == null` ou `confirmaCompra == false` | +0,30 |
| EF-02 | Todos os artigos sem etiquetas | SISTEMA | todos os `ArtigoDevolvido` com `etiquetas == AUSENTES` | +0,20 |
| EF-03 | Artigos do mesmo pedido em estados muito diferentes | SISTEMA | ≥ 2 artigos e (máx. `grauUso` − mín. `grauUso`) ≥ 2 | +0,30 |
| EF-04 | O cliente não explica onde nem quando comprou | COLABORADOR | `Cliente.explicaOrigemCompra == FALSE` | +0,40 |
| EF-05 | Pede numerário numa devolução às cegas | SISTEMA | `Cliente.pedeNumerario` e devolução às cegas | +0,30 |
| EF-06 | Comprovativo verificado | SISTEMA | PT-001 verificada | −0,60 |

Uma resposta "Não sei" do colaborador (EF-04 com `null`) não gera evidência.

### 2.3 Limiares e efeitos (demonstrativos)

| CF | Classificação | Efeito |
|---|---|---|
| ≥ 0,70 | `RISCO_ALTO` | Insere `IndicadorFraude` (nível `SIGNIFICATIVO`, descrição com as contribuições). Dispara EX-008: suspende e envolve a gestão. |
| 0,40 a < 0,70 | `RISCO_MEDIO` | Exige aprovação da Gestão da Loja (IU-12). Se o resultado final for PERMITIR, passa a REVER (IU-50). Nunca altera um RECUSAR. |
| < 0,40 | `RISCO_BAIXO` | Sem efeito. |

### 2.4 Exemplos

**Cenário 6** (três pares sem recibo, estados diferentes):

| Evidência | CF | CF acumulado |
|---|---|---|
| EF-01 Sem comprovativo | 0,30 | 0,3000 |
| EF-02 Todos sem etiquetas | 0,20 | 0,4400 |
| EF-03 Estados muito diferentes | 0,30 | 0,6080 |
| EF-04 Não explica a origem | 0,40 | 0,7648 |
| EF-05 Pede numerário | 0,30 | **0,8354** |

Resultado: `RISCO_ALTO` → EX-008. O facto de o cliente estar nervoso e defensivo **não entra** no cálculo.

**Cenário 3** (oferta sem recibo, cliente calmo): só EF-01 → CF = 0,30 → `RISCO_BAIXO`. Um indício fraco isolado não escala.

**Sinais opostos** (EF-03 com EF-06): (0,30 − 0,60) / (1 − 0,30) = **−0,4286** → `RISCO_BAIXO`.

## 3. Probabilidade bayesiana — defeito de fabrico ou desgaste

### 3.1 Método

Forma odds-verosimilhança do teorema de Bayes:

> *odds* iniciais = P / (1 − P)
> *odds* finais = *odds* iniciais × LR₁ × LR₂ × …
> P final = *odds* finais / (1 + *odds* finais)

Cada evidência **observada como presente** contribui com a sua razão de verosimilhança LR = P(evidência | defeito) / P(evidência | desgaste). LR > 1 favorece o defeito de fabrico; LR < 1 favorece o desgaste.

**Simplificações desta versão** (documentadas para serem revistas):

- Evidência ausente ou desconhecida tem LR = 1 (não é aplicada). A contribuição é registada como "não aplicada" para a explicação.
- **Grupos de evidências correlacionadas:** dentro de um grupo, só se aplica a evidência com o LR mais afastado de 1 (maior |ln LR|). As restantes ficam registadas como "não aplicada (grupo)". Evita contar duas vezes a mesma informação, sem construir uma rede bayesiana.
- A metodologia PROSPECTOR (LS/LN por antecedente, evidência incerta, hipóteses intermédias) está **em análise** como alternativa (§9). Por isso, o cálculo fica atrás da interface `ModeloBayesiano`, para poder ser substituído sem alterar as regras.

### 3.2 Pré-condições

O cálculo só corre para um artigo quando, cumulativamente:

- `EstadoProduto.alegaDefeito == true`;
- a porta G2 foi ultrapassada (nenhuma regra HS disparou; em particular HS-003);
- o artigo não é bodywear (PC-007 já o aceita);
- `EstadoProduto.defeitoFabricoConfirmado == false` (se a gestão já confirmou, PC-006 aplica-se diretamente).

No **cenário 4**, as calças foram embainhadas: HS-003 recusa e o cálculo bayesiano **não corre**.

### 3.3 Evidências e parâmetros (valores demonstrativos)

Prior: **P(defeito) = 0,30** (proporção demonstrativa de alegações de dano que são defeitos de fabrico).

| Código | Evidência | Fonte | Grupo | LR |
|---|---|---|---|---|
| ED-01 | Dano numa costura ou ponto de união | COLABORADOR | — | 4,0 |
| ED-02 | Dano localizado num único ponto | COLABORADOR | — | 2,5 |
| ED-03 | Compra há 30 dias ou menos | SISTEMA | — | 2,0 |
| ED-04 | Defeito conhecido para o SKU | CATALOGO | — | 6,0 |
| ED-05 | Desgaste generalizado do tecido | COLABORADOR | USO | 0,25 |
| ED-06 | Sinais de lavagem repetida | COLABORADOR | USO | 0,40 |
| ED-07 | Dano compatível com uso indevido (corte, queimadura, rasgão por tração) | COLABORADOR | — | 0,10 |

ED-03 é derivada das datas por uma regra; ED-04 vem do `CatalogoProdutoGateway` (simulado em dev/test); as restantes vêm da inspeção do colaborador (Sim / Não / Não sei).

### 3.4 Limiares e efeitos (demonstrativos)

| P(defeito) | Classificação | Efeito |
|---|---|---|
| ≥ 0,80 | `PROPOR_PC006` | Aprovação `GESTAO_LOJA` e mensagem "propor PC-006" (IU-21); o resultado final passa a REVER (IU-50). Quando a gestão confirma, a reavaliação com `defeitoFabricoConfirmado = true` aplica PC-006. |
| 0,40 a < 0,80 | `REVER_DEFEITO` | EX-001: inspeção adicional pela gestão (IU-22); o resultado final passa a REVER (IU-50). |
| < 0,40 | `DESGASTE` | Sem efeito na elegibilidade. PC-004 ou PC-005 aplicam-se normalmente. |

**Guarda adicional em PC-004 e PC-005:** estas regras não disparam para um artigo com `GrauCrenca(hipotese == DEFEITO_FABRICO, classificacao in (PROPOR_PC006, REVER_DEFEITO))`. O artigo fica em REVER até à decisão da gestão. Isto não viola o princípio 1: o resultado passa a REVER, não a PERMITIR, e só a confirmação humana leva a PC-006. Sem alegação de defeito, PC-004 e PC-005 comportam-se exatamente como antes.

### 3.5 Exemplos

*Odds* iniciais = 0,30 / 0,70 = 0,4286.

| Caso | Evidências aplicadas | *Odds* finais | P(defeito) | Classificação |
|---|---|---|---|---|
| A — variante do cenário 4 sem bainha | ED-01 (4) × ED-02 (2,5) × ED-03 (2) | 8,5714 | **0,8955** | `PROPOR_PC006` |
| B — costura com sinais de uso | ED-01 (4) × ED-05 (0,25); ED-06 não aplicada (grupo USO) | 0,4286 | **0,3000** | `DESGASTE` |
| C — costura em compra recente | ED-01 (4) × ED-03 (2) | 3,4286 | **0,7742** | `REVER_DEFEITO` |

No caso B, sem a regra de grupo, ED-06 seria aplicada também e P desceria para 0,1463: é a dupla contagem que o grupo evita.

## 4. Lógica fuzzy

### 4.1 Revendibilidade (IN-010)

**Entradas**

- `grauUso` ∈ [0, 4]: escala do colaborador — 0 Nenhum, 1 Ligeiro, 2 Moderado, 3 Evidente, 4 Intenso.
- `etiquetas` ∈ [0, 1]: derivada de `EstadoEtiquetas` — COLOCADAS = 1,0; SOLTAS = 0,6; AUSENTES = 0,0.

**Funções de pertença** (pontos de funções lineares por troços; valores demonstrativos)

| Variável | Termo | Pontos |
|---|---|---|
| grauUso | nenhum | (0,1) (0,5;1) (1,5;0) |
| | ligeiro | (0,5;0) (1,5;1) (2,5;0) |
| | moderado | (1,5;0) (2,5;1) (3,5;0) |
| | intenso | (2,5;0) (3,5;1) (4;1) |
| etiquetas | ausentes | (0;1) (0,2;1) (0,5;0) |
| | parciais | (0,3;0) (0,6;1) (0,9;0) |
| | completas | (0,7;0) (0,9;1) (1;1) |
| revendibilidade (saída, [0,1]) | baixa | (0;1) (0,2;1) (0,4;0) |
| | media | (0,3;0) (0,5;1) (0,7;0) |
| | alta | (0,6;0) (0,8;1) (1;1) |

**Regras** (Mamdani: E = mínimo, implicação = mínimo, agregação = máximo, desfuzzificação = centroide)

| ID | Regra |
|---|---|
| RV1 | SE grauUso é nenhum E etiquetas é completas ENTÃO revendibilidade é alta |
| RV2 | SE grauUso é nenhum E etiquetas é parciais ENTÃO revendibilidade é alta |
| RV3 | SE grauUso é nenhum E etiquetas é ausentes ENTÃO revendibilidade é media |
| RV4a | SE grauUso é ligeiro E etiquetas é completas ENTÃO revendibilidade é media |
| RV4b | SE grauUso é ligeiro E etiquetas é parciais ENTÃO revendibilidade é media |
| RV5 | SE grauUso é ligeiro E etiquetas é ausentes ENTÃO revendibilidade é baixa |
| RV6 | SE grauUso é moderado ENTÃO revendibilidade é baixa |
| RV7 | SE grauUso é intenso ENTÃO revendibilidade é baixa |

**Limiares e efeitos** (só se `ArtigoDevolvido.revendivel == null`, para nunca sobrepor uma decisão explícita da gestão; não se aplica a bodywear)

| Grau | Classificação | Efeito |
|---|---|---|
| ≥ 0,60 | `REVENDIVEL` | `revendivel = TRUE` |
| 0,40 a < 0,60 | `REVENDIBILIDADE_INDETERMINADA` | `revendivel` fica `null`; a gestão decide em EX-001 |
| < 0,40 | `NAO_REVENDIVEL` | `revendivel = FALSE` |

**Exemplos** (centroide calculado numericamente; tolerância de teste ±0,02)

| Caso | grauUso | etiquetas | Regras ativas (força) | Grau | Classificação |
|---|---|---|---|---|---|
| Cenário 1 — não usado, etiquetas soltas | 0 | 0,6 | RV2 (1,0) | 0,844 | `REVENDIVEL` |
| Não usado, sem etiquetas | 0 | 0,0 | RV3 (1,0) | 0,500 | `REVENDIBILIDADE_INDETERMINADA` |
| Cenário 6 — par ligeiramente usado sem etiquetas | 1 | 0,0 | RV3 (0,5), RV5 (0,5) | 0,325 | `NAO_REVENDIVEL` |
| Ligeiro com etiquetas colocadas | 1 | 1,0 | RV1 (0,5), RV4a (0,5) | 0,675 | `REVENDIVEL` |

### 4.2 Recomendação de crédito de loja (PT-004)

Corre depois de PT-004 ter devolvido REVER (devolução verificada com mais de 30 dias). É **apenas uma recomendação** apresentada ao gestor; não altera a `Decisao`.

**Entradas**

- `diasAposPrazo` ∈ [0, 180]: `diasDesdeCompra − 30` (limitado a 180).
- `revendibilidade` ∈ [0, 1]: grau de §4.1 (0,5 se não tiver sido calculado).
- `risco` ∈ [0, 1]: CF de fraude de §2, com valores negativos limitados a 0 (0 se não existir).
- `valor` ∈ [0, 500]: soma de `precoPago` dos artigos, em moeda local (limitado a 500).

**Funções de pertença** (valores demonstrativos)

| Variável | Termo | Pontos |
|---|---|---|
| diasAposPrazo | pouco | (0;1) (7;1) (21;0) |
| | moderado | (14;0) (35;1) (60;0) |
| | muito | (45;0) (90;1) (180;1) |
| revendibilidade | baixa | (0;1) (0,3;1) (0,5;0) |
| | media | (0,3;0) (0,55;1) (0,8;0) |
| | alta | (0,6;0) (0,8;1) (1;1) |
| risco | baixo | (0;1) (0,2;1) (0,4;0) |
| | medio | (0,3;0) (0,5;1) (0,7;0) |
| | alto | (0,6;0) (0,75;1) (1;1) |
| valor | baixo | (0;1) (50;1) (150;0) |
| | alto | (100;0) (250;1) (500;1) |
| recomendacao (saída, [0,100]) | fraca | (0;1) (20;1) (40;0) |
| | moderada | (30;0) (50;1) (70;0) |
| | forte | (60;0) (80;1) (100;1) |

**Regras**

| ID | Regra |
|---|---|
| CR1 | SE dias é pouco E revendibilidade é alta E risco é baixo ENTÃO recomendacao é forte |
| CR2 | SE dias é moderado E revendibilidade é alta E risco é baixo ENTÃO recomendacao é moderada |
| CR3 | SE dias é pouco E revendibilidade é media E risco é baixo ENTÃO recomendacao é moderada |
| CR4 | SE risco é medio E revendibilidade é alta ENTÃO recomendacao é moderada |
| CR5 | SE dias é muito ENTÃO recomendacao é fraca |
| CR6 | SE risco é alto ENTÃO recomendacao é fraca |
| CR7 | SE revendibilidade é baixa ENTÃO recomendacao é fraca |
| CR8 | SE valor é alto E dias é moderado ENTÃO recomendacao é fraca |

**Classificação:** ≥ 70 `CREDITO_RECOMENDADO`; 40 a < 70 `CREDITO_A_CRITERIO`; < 40 `CREDITO_NAO_RECOMENDADO`.

**Exemplos** (tolerância de teste ±2 pontos)

| Caso | dias após prazo | revend. | risco | valor | Regras ativas (força) | Recomendação |
|---|---|---|---|---|---|---|
| A — 35 dias | 5 | 0,83 | 0,10 | 80 | CR1 (1,0) | 84,4 → `CREDITO_RECOMENDADO` |
| B — 55 dias | 25 | 0,83 | 0,10 | 80 | CR2 (0,524) | 50,0 → `CREDITO_A_CRITERIO` |
| C — 55 dias, valor alto | 25 | 0,83 | 0,10 | 220 | CR2 (0,524), CR8 (0,524) | 32,3 → `CREDITO_NAO_RECOMENDADO` |
| D — 130 dias | 100 | 0,83 | 0,10 | 80 | CR5 (1,0) | 15,6 → `CREDITO_NAO_RECOMENDADO` |
| E — risco médio | 5 | 0,83 | 0,55 | 80 | CR4 (0,75) | 50,0 → `CREDITO_A_CRITERIO` |

### 4.3 Motor fuzzy

`MotorFuzzy` é uma interface. A implementação de referência usa a biblioteca **jFuzzyLogic** com ficheiros FCL (norma IEC 61131-7), versionados em `pericial-uncertainty/src/main/resources/fcl/`. No início da fase, confirmar a disponibilidade e a licença da dependência no Maven Central. Se não for adequada, implementar um motor Mamdani mínimo (mínimo/máximo, centroide discreto com ≥ 1000 pontos) que leia os mesmos parâmetros. Em ambos os casos, o motor tem de devolver, além do valor, os graus de pertença das entradas e a força de cada regra ativada, para as explicações.

Exemplo `revendibilidade.fcl`:

```
FUNCTION_BLOCK revendibilidade

VAR_INPUT
    grauUso : REAL;
    etiquetas : REAL;
END_VAR

VAR_OUTPUT
    revendibilidade : REAL;
END_VAR

FUZZIFY grauUso
    TERM nenhum   := (0, 1) (0.5, 1) (1.5, 0);
    TERM ligeiro  := (0.5, 0) (1.5, 1) (2.5, 0);
    TERM moderado := (1.5, 0) (2.5, 1) (3.5, 0);
    TERM intenso  := (2.5, 0) (3.5, 1) (4, 1);
END_FUZZIFY

FUZZIFY etiquetas
    TERM ausentes  := (0, 1) (0.2, 1) (0.5, 0);
    TERM parciais  := (0.3, 0) (0.6, 1) (0.9, 0);
    TERM completas := (0.7, 0) (0.9, 1) (1, 1);
END_FUZZIFY

DEFUZZIFY revendibilidade
    TERM baixa := (0, 1) (0.2, 1) (0.4, 0);
    TERM media := (0.3, 0) (0.5, 1) (0.7, 0);
    TERM alta  := (0.6, 0) (0.8, 1) (1, 1);
    METHOD : COG;
    DEFAULT := 0.5;
END_DEFUZZIFY

RULEBLOCK regras
    AND : MIN;
    ACT : MIN;
    ACCU : MAX;
    RULE RV1  : IF grauUso IS nenhum AND etiquetas IS completas THEN revendibilidade IS alta;
    RULE RV2  : IF grauUso IS nenhum AND etiquetas IS parciais THEN revendibilidade IS alta;
    RULE RV3  : IF grauUso IS nenhum AND etiquetas IS ausentes THEN revendibilidade IS media;
    RULE RV4a : IF grauUso IS ligeiro AND etiquetas IS completas THEN revendibilidade IS media;
    RULE RV4b : IF grauUso IS ligeiro AND etiquetas IS parciais THEN revendibilidade IS media;
    RULE RV5  : IF grauUso IS ligeiro AND etiquetas IS ausentes THEN revendibilidade IS baixa;
    RULE RV6  : IF grauUso IS moderado THEN revendibilidade IS baixa;
    RULE RV7  : IF grauUso IS intenso THEN revendibilidade IS baixa;
END_RULEBLOCK

END_FUNCTION_BLOCK
```

`credito-pt004.fcl` segue o mesmo formato, com as variáveis, termos e regras CR1 a CR8 de §4.2. Os nomes das regras no FCL são os IDs RV/CR, para que as explicações os possam citar.

## 5. Integração no modelo e nas regras

### 5.1 Alterações ao modelo (`pericial-model`)

**Novas classes**

| Classe | Atributo | Tipo | Descrição |
|---|---|---|---|
| `Evidencia` | `codigo` | `String` | EF-xx ou ED-xx |
| | `hipotese` | `Hipotese` | Hipótese a que se refere |
| | `pedidoId` | `String` | Pedido |
| | `artigoId` | `String` | Artigo (nulo para evidências do pedido) |
| | `presente` | `Boolean` | TRUE observado; FALSE observado ausente; null desconhecido |
| | `fonte` | `FonteEvidencia` | Origem da evidência |
| | `peso` | `double` | CF ou LR, preenchido a partir dos parâmetros na inserção |
| | `grupo` | `String` | Grupo de correlação (ex.: USO); nulo se não tiver |
| | `descricao` | `String` | Texto para as explicações |
| `GrauCrenca` | `pedidoId` | `String` | Pedido |
| | `artigoId` | `String` | Artigo (nulo para FRAUDE) |
| | `hipotese` | `Hipotese` | Hipótese avaliada |
| | `metodo` | `MetodoIncerteza` | Técnica usada |
| | `valor` | `double` | CF em [−1,1], probabilidade em [0,1], grau fuzzy em [0,1] ou recomendação em [0,100] |
| | `classificacao` | `ClassificacaoIncerteza` | Classe resultante dos limiares |
| | `contribuicoes` | `List<Contribuicao>` | Passos do cálculo |
| | `versaoParametros` | `String` | Versão do ficheiro de parâmetros |
| | `demonstrativo` | `boolean` | Parâmetros demonstrativos |
| `Contribuicao` | `codigo` | `String` | EF/ED/RV/CR |
| | `descricao` | `String` | Texto legível |
| | `peso` | `double` | CF, LR ou força da regra fuzzy |
| | `valorAntes` | `double` | Valor antes deste passo (CF acumulado, P) |
| | `valorDepois` | `double` | Valor depois deste passo |
| | `aplicada` | `boolean` | Falso para "não aplicada" (desconhecida, ausente ou grupo) |
| | `motivoNaoAplicada` | `String` | Ex.: "grupo USO" |

**Alterações a classes existentes**

| Classe | Alteração |
|---|---|
| `EstadoProduto` | `+ Integer grauUso` (0–4, null desconhecido); `+ boolean alegaDefeito`; `+ double getIntegridadeEtiquetas()` (COLOCADAS 1,0; SOLTAS 0,6; AUSENTES 0,0) |
| `Cliente` | `+ Boolean explicaOrigemCompra` (null = "Não sei"); `+ boolean pedeNumerario` |
| `Decisao` | `+ List<GrauCrenca> grausCrenca`; `+ String versaoParametrosIncerteza` |

**Novas enumerações e valores**

| Enumeração | Valores |
|---|---|
| `Hipotese` | `FRAUDE`, `DEFEITO_FABRICO`, `REVENDIBILIDADE`, `RECOMENDACAO_CREDITO` |
| `MetodoIncerteza` | `FATOR_CERTEZA`, `BAYES`, `FUZZY` |
| `FonteEvidencia` | `SISTEMA`, `COLABORADOR`, `POS`, `CATALOGO` |
| `ClassificacaoIncerteza` | `RISCO_ALTO`, `RISCO_MEDIO`, `RISCO_BAIXO`, `PROPOR_PC006`, `REVER_DEFEITO`, `DESGASTE`, `REVENDIVEL`, `REVENDIBILIDADE_INDETERMINADA`, `NAO_REVENDIVEL`, `CREDITO_RECOMENDADO`, `CREDITO_A_CRITERIO`, `CREDITO_NAO_RECOMENDADO` |
| `NivelAprovacao` | `+ GESTAO_LOJA` |
| `Modulo` | `+ EVIDENCIA`, `+ INCERTEZA` |

### 5.2 Novo módulo `pericial-uncertainty`

Depende só de `pericial-model`. É usado por `pericial-rules` (através de globals) e por `pericial-service`.

```
pericial-uncertainty/
├── src/main/java/com/levis/devolucoes/incerteza/
│   ├── certeza/      CombinadorFatoresCerteza
│   ├── bayes/        ModeloBayesiano (interface), ModeloRazoesVerosimilhanca (implementação desta versão)
│   ├── fuzzy/        MotorFuzzy (interface), MotorFuzzyFcl (jFuzzyLogic) ou MotorMamdani (próprio)
│   ├── parametros/   ParametrosIncerteza, CarregadorParametros (valida no arranque)
│   └── ServicoIncerteza.java   # fachada usada pelas regras e pelo service
└── src/main/resources/
    ├── parametros/parametros-incerteza.yml
    └── fcl/revendibilidade.fcl, credito-pt004.fcl
```

`CarregadorParametros` falha o arranque se: algum CF estiver fora de [−1, 1]; algum LR for ≤ 0; o prior não estiver em ]0, 1[; os limiares não forem crescentes; faltar o FCL referido.

### 5.3 Ordem de avaliação

```
M0 → M1/M2 → EVIDENCIA → INCERTEZA → M3 → M4/M5 (inclui IU-40) → ONLINE → M6 → M7 → M8 (inclui IU-50) → M9
```

`OrdemModulos` passa a incluir `EVIDENCIA` e `INCERTEZA`. EX-008 e PC-008 mantêm `auto-focus`.

Os efeitos que tornam o resultado mais cauteloso (passar PERMITIR a REVER) são aplicados no fim, em M8, pela regra IU-50. Se fossem aplicados em INCERTEZA, regras posteriores como PT-003 voltariam a escrever PERMITIR. As aprovações nunca descem de nível: `NENHUMA < XSTORE_MANAGER < GESTAO_LOJA < RESPONSAVEL_SENIOR < DISTRICT_AREA`.

### 5.4 Novas regras DRL

As evidências do colaborador e do catálogo (EF-04, ED-01, ED-02, ED-04 a ED-07) são inseridas pelo `AvaliacaoService` a partir do pedido, com o peso lido dos parâmetros. As evidências derivadas são inseridas por regras.

| ID | Agenda-group | Função |
|---|---|---|
| IU-01 a IU-03, IU-05, IU-06 | EVIDENCIA | Derivam EF-01, EF-02, EF-03, EF-05, EF-06 a partir dos factos |
| IU-07 | EVIDENCIA | Deriva ED-03 (compra há ≤ 30 dias) para artigos com `alegaDefeito` |
| IU-10 | INCERTEZA | Calcula o `GrauCrenca` FRAUDE (CF) |
| IU-11 | INCERTEZA | CF ≥ 0,70 → insere `IndicadorFraude` |
| IU-12 | INCERTEZA | 0,40 ≤ CF < 0,70 → aprovação `GESTAO_LOJA` |
| IU-20 | INCERTEZA | Calcula o `GrauCrenca` DEFEITO_FABRICO (Bayes) por artigo, se §3.2 se cumprir |
| IU-21 a IU-23 | INCERTEZA | Aplicam os efeitos de §3.4 |
| IU-30 | INCERTEZA | Calcula o `GrauCrenca` REVENDIBILIDADE (fuzzy) por artigo com `grauUso` conhecido |
| IU-31 a IU-33 | INCERTEZA | Aplicam os efeitos de §4.1 |
| IU-40 | M5 | Depois de PT-004 em REVER, calcula a `RECOMENDACAO_CREDITO` (fuzzy) |
| IU-50 | M8 | Se a elegibilidade for PERMITIR e existir `GrauCrenca` `RISCO_MEDIO`, `PROPOR_PC006` ou `REVER_DEFEITO`, passa a REVER. Nunca altera RECUSAR nem ENCAMINHAR. |

Os IDs IU-04, IU-13 a IU-19, IU-24 a IU-29 e IU-41 a IU-49 ficam reservados. Cada regra declara `@id`, `@modulo`, `@descricao` e `@condicoes`, como as restantes.

Exemplo:

```drl
global com.levis.devolucoes.incerteza.ServicoIncerteza incerteza;

rule "IU-10 Calcular risco de fraude"
    @id("IU-10") @modulo("INCERTEZA")
    @descricao("Combina as evidências de fraude com fatores de certeza (MYCIN)")
    agenda-group "INCERTEZA"
    salience 100
when
    $d : Decisao( terminal == false )
    not GrauCrenca( pedidoId == $d.pedidoId, hipotese == Hipotese.FRAUDE )
    $evs : List() from collect( Evidencia( pedidoId == $d.pedidoId,
                                           hipotese == Hipotese.FRAUDE,
                                           presente == Boolean.TRUE ) )
then
    GrauCrenca g = incerteza.combinarFatoresCerteza( $d.getPedidoId(), $evs );
    insert( g );
    modify( $d ) { getGrausCrenca().add( g ) }
end

rule "IU-11 Risco de fraude alto"
    @id("IU-11") @modulo("INCERTEZA")
    agenda-group "INCERTEZA"
    salience 90
when
    $d : Decisao( terminal == false )
    $g : GrauCrenca( pedidoId == $d.pedidoId, hipotese == Hipotese.FRAUDE,
                     classificacao == ClassificacaoIncerteza.RISCO_ALTO )
    not IndicadorFraude( pedidoId == $d.pedidoId )
then
    insert( incerteza.indicadorFraude( $g ) );   // nível SIGNIFICATIVO; EX-008 dispara por auto-focus
end
```

O cálculo e a classificação ficam em Java (`ServicoIncerteza`), testáveis sem Drools; as regras decidem quando calcular e que efeito aplicar.

## 6. Ficheiro de parâmetros

`pericial-uncertainty/src/main/resources/parametros/parametros-incerteza.yml`:

```yaml
versao: "0.1.0-demo"
demonstrativo: true            # a interface mostra o aviso enquanto for true

fatoresCerteza:
  fraude:
    evidencias:
      EF-01: { cf: 0.30, descricao: "Sem comprovativo verificável" }
      EF-02: { cf: 0.20, descricao: "Todos os artigos sem etiquetas" }
      EF-03: { cf: 0.30, descricao: "Artigos em estados muito diferentes" }
      EF-04: { cf: 0.40, descricao: "Não explica onde nem quando comprou" }
      EF-05: { cf: 0.30, descricao: "Pede numerário numa devolução às cegas" }
      EF-06: { cf: -0.60, descricao: "Comprovativo verificado" }
    diferencaEstadosMinima: 2    # EF-03
    limiares: { medio: 0.40, alto: 0.70 }

bayes:
  defeitoFabrico:
    prior: 0.30
    evidencias:
      ED-01: { lr: 4.0,  descricao: "Dano numa costura ou ponto de união" }
      ED-02: { lr: 2.5,  descricao: "Dano localizado num único ponto" }
      ED-03: { lr: 2.0,  descricao: "Compra há 30 dias ou menos" }
      ED-04: { lr: 6.0,  descricao: "Defeito conhecido para o SKU" }
      ED-05: { lr: 0.25, descricao: "Desgaste generalizado do tecido", grupo: USO }
      ED-06: { lr: 0.40, descricao: "Sinais de lavagem repetida", grupo: USO }
      ED-07: { lr: 0.10, descricao: "Dano compatível com uso indevido" }
    limiares: { rever: 0.40, proporPc006: 0.80 }

fuzzy:
  revendibilidade:
    fcl: "fcl/revendibilidade.fcl"
    integridadeEtiquetas: { COLOCADAS: 1.0, SOLTAS: 0.6, AUSENTES: 0.0 }
    limiares: { indeterminada: 0.40, revendivel: 0.60 }
  creditoPt004:
    fcl: "fcl/credito-pt004.fcl"
    limites: { diasAposPrazo: 180, valor: 500 }
    limiares: { aCriterio: 40, recomendado: 70 }
```

Os testes usam uma cópia fixa, `src/test/resources/parametros-incerteza-teste.yml`, para que a alteração dos valores demonstrativos não parta os testes.

## 7. API, explicações e frontend

### 7.1 API e DTO

- `PedidoAvaliacaoRequest`:
  - `artigos[].grauUso` (0–4, opcional);
  - `artigos[].alegaDefeito` (boolean);
  - `artigos[].inspecaoDefeito`: mapa ED-xx → `SIM` | `NAO` | `NAO_SEI` (apenas as evidências do colaborador);
  - `cliente.explicaOrigemCompra`: `SIM` | `NAO` | `NAO_SEI`;
  - `cliente.pedeNumerario` (boolean).
- `DecisaoResponse`: `+ incerteza: List<GrauCrencaDto>` (hipótese, método, artigo, valor, classificação, contribuições, `demonstrativo`, `versaoParametros`).
- Novo `GET /api/v1/incerteza/parametros`: versão, flag `demonstrativo` e valores em vigor (só leitura).
- `GET /api/v1/avaliacoes/{id}/explicacoes/porque?campo=INCERTEZA.FRAUDE` (e `INCERTEZA.DEFEITO_FABRICO`, `INCERTEZA.REVENDIBILIDADE`, `INCERTEZA.RECOMENDACAO_CREDITO`, com `artigoId` quando aplicável).
- `POST /api/v1/avaliacoes/{id}/simulacoes` aceita alterações às evidências e ao `grauUso`.

### 7.2 Explicações

| Pergunta | Fatores de certeza | Bayes | Fuzzy |
|---|---|---|---|
| Porquê? | Lista das evidências com CF e CF acumulado: "Risco 0,84: sem comprovativo +0,30 → 0,30; sem etiquetas +0,20 → 0,44; estados diferentes +0,30 → 0,61; …" | Prior e cada passo: "P(defeito) 0,30 → 0,63 (costura, LR 4,0) → 0,81 (localizado, LR 2,5)…"; evidências não aplicadas e motivo | Graus de pertença das entradas, regras ativadas com a força, valor desfuzzificado |
| Porque não? | "Não suspendeu porque CF = 0,61 < 0,70" e que evidências o levariam acima | "Não propôs PC-006 porque P = 0,77 < 0,80" e que evidências mudariam a classe | "Não revendível porque grau = 0,33 < 0,40; regras ativas: RV3 0,5, RV5 0,5" |
| E se? | Recalcula com evidências alteradas | Idem | Idem com `grauUso`/etiquetas alterados |

O texto mostra sempre o aviso "valores demonstrativos" enquanto `demonstrativo == true`. Nunca apresentar um CF como probabilidade.

### 7.3 Frontend

- Passo de inspeção do produto: escala do grau de uso (Nenhum, Ligeiro, Moderado, Evidente, Intenso); "o cliente alega defeito?"; perguntas ED com Sim / Não / Não sei.
- Passo do cliente: "o cliente explica onde e quando comprou?" (Sim / Não / Não sei) e "pede numerário?".
- Cartão "Avaliação da incerteza" no resultado: uma linha por hipótese com valor, classificação e a lista de contribuições expansível.
- Faixa de aviso fixa "Valores demonstrativos — não usar para decisões reais" enquanto `demonstrativo == true`.

## 8. Testes

**Unitários (`pericial-uncertainty`)**

- `CombinadorFatoresCerteza`: as três fórmulas; comutatividade (ordem das evidências não altera o resultado); cadeia do cenário 6 = 0,8354; sinais opostos = −0,4286; lista vazia = 0.
- `ModeloRazoesVerosimilhanca`: casos A (0,8955), B (0,3000) e C (0,7742) de §3.5; desconhecida e ausente não aplicadas; regra de grupo.
- `MotorFuzzy`: exemplos de §4.1 (±0,02) e §4.2 (±2); classificações; regras ativadas devolvidas.
- `CarregadorParametros`: rejeita parâmetros inválidos.

**Integração com as regras (`pericial-rules`)**

| Teste | Esperado |
|---|---|
| Cenário 6 | `GrauCrenca` FRAUDE 0,8354 `RISCO_ALTO`; `IndicadorFraude` inserido; EX-008 dispara |
| Cenário 6 com `agitado` e `contestaResultado` a true e a false | **Mesmo** CF (teste de não enviesamento) |
| Cenário 3 | FRAUDE 0,30 `RISCO_BAIXO`; sem efeito |
| Cenário 4 (embainhadas) | HS-003 recusa; **nenhum** `GrauCrenca` DEFEITO_FABRICO |
| Variante do cenário 4 sem bainha (caso A), dentro de 30 dias e com recibo | P = 0,8955 `PROPOR_PC006`; PC-004 não dispara; PT-003 dá PERMITIR mas IU-50 deixa o resultado final em REVER |
| Mesma variante com `defeitoFabricoConfirmado = true` | PC-006 aplica-se; Bayes não corre |
| Caso B | `DESGASTE`; PC-004 aplica-se como antes |
| Cenário 1 | REVENDIBILIDADE 0,844 `REVENDIVEL`; `revendivel = TRUE` |
| PT-004, casos A a E de §4.2 | Classificação correta; `Decisao` inalterada (REVER) |
| Qualquer cenário em que uma regra HS recusa | Elegibilidade final continua RECUSAR (princípio 1) |
| Cenários 2, 5, 7, 8, 9, 10 | Resultados idênticos aos obtidos sem a camada de incerteza (regressão) |

## 9. Governação e pontos em aberto

- **Valores demonstrativos.** Todos os CF, priors, LR, funções de pertença e limiares são demonstrativos. A calibração com a operação (gestores e controlo de qualidade) é condição para uso real: até lá, `demonstrativo: true` e o aviso na interface.
- **Auditoria.** Cada avaliação persiste os `GrauCrenca` com as contribuições e a `versaoParametros`, para que uma decisão possa ser reconstruída.
- **Metodologia bayesiana em análise (ADR).** Registar em `docs/adr/` um ADR com estado "Em análise", comparando:
  - **Opção A, adotada nesta versão:** razões de verosimilhança simples, evidência binária, grupos de correlação.
  - **Opção B:** modelo PROSPECTOR com LS/LN por antecedente, evidência incerta com interpolação, hipóteses intermédias e regras determinísticas (referência: `FactBayes.java` e `Rules.drl` fornecidos pela equipa). Pontos a avaliar nesta opção: pivô da interpolação em 0,5 em vez do prior; regras com vários antecedentes só disparam se todos os factos existirem; estado estático no listener, incompatível com pedidos simultâneos.
  - A interface `ModeloBayesiano` isola esta escolha: mudar de opção não exige alterar as regras IU-20 a IU-23.
- **Fora de âmbito nesta versão:** credibilidade das declarações do cliente; redes bayesianas; aprendizagem dos parâmetros a partir da auditoria.
