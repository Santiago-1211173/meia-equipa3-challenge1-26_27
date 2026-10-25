# ADR 0012 — Camada de tratamento da incerteza

- **Estado:** aceite (Fase 11); os valores numéricos são demonstrativos
- **Data:** 2026-10-15
- **Referência:** `docs/08-incerteza.md`; plano em `docs/07-plano.md`, secção E

## Contexto

O `docs/08` acrescenta três técnicas de incerteza:

- **fatores de certeza** para o risco de fraude;
- **razões de verosimilhança** para distinguir defeito de fabrico de desgaste;
- **lógica fuzzy** para a revendibilidade e para a recomendação de crédito na PT-004.

Algumas indicações do `docs/08` chocam com os documentos 01–05, com os seus próprios princípios ou com a
implementação existente. Este ADR regista como cada ponto foi resolvido.

## Decisões do utilizador (2026-10-15)

1. **Revendibilidade só recomenda.**
   - O §4.1 manda fixar `revendivel = TRUE` quando o grau é REVENDIVEL. Mas a PC-002 e a PC-003 com IN-010 = sim dão
     PERMITIR, e a camada passaria sozinha um REVER a PERMITIR (cenário 1). Isso contraria os princípios 1.2.1
     (só torna mais cauteloso) e 1.2.2 (a decisão nas zonas REVER é humana).
   - Por isso, REVENDIVEL e REVENDIBILIDADE_INDETERMINADA ficam só como `GrauCrenca` e `revendivel` continua `null`.
   - NAO_REVENDIVEL fixa `revendivel = FALSE`, por ser mais cauteloso.
2. **Aprovação RESPONSAVEL_SENIOR.**
   - O §5.1 acrescenta `GESTAO_LOJA` a `NivelAprovacao`, mas o OUT-005 de `01`, que prevalece, não tem esse nível.
   - IU-12 e IU-21 exigem RESPONSAVEL_SENIOR, como a A-19. Fica "a validar" (ADR 0003, A-34).
3. **Motor fuzzy jFuzzyLogic.**
   - O jFuzzyLogic não está no Maven Central. A alternativa que lá existe, o jfuzzylite 6, tem uma licença proprietária.
   - Usa-se o jar publicado pelo autor no SourceForge (licença LGPL-3.0, segundo o repositório
     github.com/pcingola/jFuzzyLogic), instalado num repositório Maven dentro do projeto (`backend/repo-local/`), para
     que o CI e qualquer máquina compilem sem passo manual.
   - O `jFuzzyLogic_core.jar` (versão 3.3, de 2015) traz embutidas outras bibliotecas, entre elas o ANTLR 3.1
     (`org.antlr.runtime`), que colide com o `antlr-runtime` 3.5.2 do Drools. O artefacto do repositório local tem só as
     classes do jFuzzyLogic, sem alterações, e declara o `antlr-runtime` 3.5.2 como dependência. Foi verificado que o
     parser FCL funciona com essa versão e que os exemplos do `docs/08` dão os mesmos valores. O script
     `backend/repo-local/preparar-jfuzzylogic.sh` gera o artefacto a partir do jar original e confirma o SHA-256.
   - O jFuzzyLogic corre em Java 25 e devolve o grau de cada regra (`Rule.getDegreeOfSupport()`) e as pertenças das
     entradas, como pede o §4.3.
   - O motor fica atrás da interface `MotorFuzzy`.
4. **O cálculo de um grau explica-se no "Como?".**
   - O §7.1 propõe `GET .../explicacoes/porque?campo=INCERTEZA.*`. Pela ADR 0006, "Porquê?" é porque é que o sistema
     faz uma pergunta, e "Como?" é como se chegou a uma conclusão.
   - O grau explica-se em `GET .../explicacoes/como?conclusao=INCERTEZA.<HIPOTESE>[&artigo=]`.
   - "Porque não?" (`conclusao=INCERTEZA.<HIPOTESE>:<CLASSE>`) e "E se?" seguem o `docs/08`.

## Decisões técnicas

1. **Bayes no agenda-group M3.**
   - O §5.3 põe o grupo INCERTEZA antes do M3, mas o §3.2 exige a porta G2 (nenhuma HS disparou), e as
     HS-001..004 estão no M3.
   - IU-20 a IU-23 correm no M3, com salience abaixo das HS e acima da PC-004/PC-005, guardadas por
     `DecisaoArtigo(terminal == false)`.
   - O cálculo de fraude (IU-10..12) e a revendibilidade (IU-30..33) ficam no grupo INCERTEZA, antes do M3.
2. **EF-05 e EF-06 derivam dos factos.** A PT-001 e a PT-002 estão no M4, que corre depois do grupo EVIDENCIA. As
   regras IU-05 e IU-06 usam o mesmo critério que elas: comprovativo ausente ou que não confirma a compra
   (às cegas), ou comprovativo válido (verificada).
3. **Efeitos sobre cada `DecisaoArtigo`.** A elegibilidade do pedido é recalculada a partir dos artigos no M9
   (OUT-001, ADR 0002). Se a IU-50 alterasse a `Decisao`, a agregação sobrescrevia-a.
   - A IU-21 e a IU-22 (defeito provável ou possível) aplicam logo REVER ao artigo no M3: o §3.4 diz que "o artigo fica
     em REVER até à decisão da gestão", e só assim a PT-003 continua a ver um artigo elegível (como no §8). Como o
     `aplicar` nunca baixa a severidade, uma variante da IU-50 para o defeito nunca dispararia; a IU-50 fica só para o
     risco de fraude médio, passando os artigos PERMITIR (ou ainda sem resultado) a REVER.
   - Nunca altera RECUSAR nem ENCAMINHAR.
4. **Respostas de inspeção no modelo.**
   - O §5.4 manda o `AvaliacaoService` inserir as evidências do colaborador. A simulação ("E se?") e o "Porque não?"
     reavaliam o pedido gravado, por isso as respostas têm de estar no pedido:
     - `EstadoProduto.inspecaoDefeito: Map<String, Boolean>` (ED-xx → presente, ausente ou desconhecido);
     - `Cliente.explicaOrigemCompra`;
     - `Cliente.pedeNumerario`.
   - A `FabricaEvidencias` (`pericial-uncertainty`) cria as `Evidencia` com o peso dos parâmetros e é chamada pelo
     `ExecutorSessao`, o mesmo caminho para a avaliação, a simulação e o "Porque não?".
5. **Cenário 6.**
   - O indício registado à mão (A-27) é substituído pelas entradas do `docs/08`: `explicaOrigemCompra = NAO`,
     `pedeNumerario = true` e `grauUso` 0, 1 e 2 (a mancha conta como uso moderado).
   - O CF dá 0,8354 e a IU-11 insere o `IndicadorFraude`. O resultado final mantém-se: EX-008, REVER, DISTRICT_AREA.
6. **`grauUso` e `condicaoUso` são independentes.** Não há validação cruzada; a EF-03 usa só o `grauUso`.
7. **A-17 mantém-se.** O "baixo risco" da PT-004 continua a depender de `IndicadorFraude`; o RISCO_MEDIO atua pela
   IU-12 e pela IU-50.
8. **IDs e metadados.**
   - As regras IU-xx têm os mesmos metadados que as restantes.
   - O `MetadadosRegrasTest` passa a aceitar os IDs IU-xx definidos no `docs/08` (§5.4).
   - O `CoberturaRegrasTest` exige um teste `@Regra` por regra IU.

9. **Foco da EX-008 depois da IU-11.** O `auto-focus` da EX-008 não interrompe o grupo em curso (o Drools avalia os
   grupos de forma preguiçosa); antes, o indício era inserido no arranque e a EX-008 corria antes de tudo. A IU-11 dá
   explicitamente o foco ao grupo TRANSVERSAL depois de inserir o indício, para a suspensão ser imediata. Consequência
   no cenário 6: o M0 e o M2 (CT-003, IN-003) correm antes da suspensão, porque o risco só se conhece depois deles.
10. **Integridade das etiquetas como parâmetro.** O §5.1 põe `getIntegridadeEtiquetas()` no modelo, com os valores
   1,0, 0,6 e 0,0, mas o §6 tem os mesmos valores no ficheiro de parâmetros (`integridadeEtiquetas`). Para não haver
   parâmetros no código, o mapeamento fica no `ServicoIncerteza`, lido do ficheiro.
11. **Respostas na API.** As perguntas do colaborador (`cliente.explicaOrigemCompra`, `estado.inspecaoDefeito`)
   chegam como `Resposta` (SIM, NAO, NAO_SEI) e são convertidas em `Boolean` (NAO_SEI → `null`, evidência
   desconhecida). `ProdutoRequest.defeitoConhecido` (ED-04) é preenchido pelo catálogo quando o pedido não o traz; o
   catálogo simulado marca o SKU `TRUCKER-AZUL-M` com um defeito conhecido, só para demonstração.

## Consequências

- **Regressão:** os cenários 2, 5, 7, 8, 9 e 10 ficam idênticos (CF em RISCO_BAIXO, sem `grauUso` nem
  `alegaDefeito`).
- **Cenários que mudam:** os JSON dos cenários 1, 3, 4 e 6 ganham as novas entradas e os graus esperados, marcados
  "a validar". O cenário 1 continua em REVER (decisão 1).
- **Dependência LGPL:** o jFuzzyLogic é usado sem modificações, ligado como biblioteca; a licença fica registada aqui
  e no POM.
- **Testes de literais:** um teste falha se aparecerem valores demonstrativos (CF, LR, limiares) em código Java ou
  DRL.
