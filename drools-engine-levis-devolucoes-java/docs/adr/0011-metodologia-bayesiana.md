# ADR 0011 — Metodologia bayesiana para defeito de fabrico ou desgaste

- **Estado:** Em análise
- **Data:** 2026-10-15
- **Referência:** `docs/08-incerteza.md`, §3 e §9

## Contexto

Quando o cliente alega um defeito, o colaborador tem de distinguir um **defeito de fabrico** (PC-006) do **desgaste**
pelo uso (PC-004 ou PC-005). A política não dá critérios numéricos: a decisão depende da inspeção e de indícios
(dano numa costura, desgaste generalizado, compra recente, defeito conhecido para o SKU…), que tornam uma hipótese
mais ou menos provável.

O `docs/08` pede um cálculo bayesiano da probabilidade de defeito, com estes requisitos:

- **Valores demonstrativos.** O prior, as razões de verosimilhança e os limiares ficam no ficheiro de parâmetros.
- **Cálculo explicável.** O "Como?" mostra cada passo e as evidências não aplicadas.
- **Princípio 1.** O resultado só pode tornar a decisão mais cautelosa (REVER, propor PC-006 à gestão).
- **Cálculo substituível.** Tem de ser possível trocar de método sem alterar as regras IU-20 a IU-23.

A equipa forneceu uma implementação de referência do modelo PROSPECTOR (`FactBayes.java` e `Rules.drl`).

## Opções

### Opção A — Razões de verosimilhança simples (adotada nesta versão)

Forma *odds*–verosimilhança do teorema de Bayes:
*odds* finais = *odds* iniciais × LR₁ × LR₂ × …, e P = *odds* / (1 + *odds*).

- **Evidência binária.** Cada evidência do colaborador é Sim, Não ou Não sei. Só as evidências observadas como
  presentes contribuem; "Não" e "Não sei" têm LR = 1 e ficam registadas como "não aplicada".
- **Grupos de correlação.** Dentro de um grupo (ex.: USO, que junta o desgaste generalizado e os sinais de lavagem
  repetida) só se aplica a evidência mais forte, a de maior |ln LR|. Evita contar duas vezes a mesma informação sem
  construir uma rede bayesiana.
- **Exemplos verificados:** caso A 0,8955, caso B 0,3000 (0,1463 sem a regra de grupo) e caso C 0,7742.

| Vantagens | Desvantagens |
|---|---|
| Simples de calibrar: um prior e um LR por evidência | Pressupõe independência condicional fora dos grupos |
| Cada passo é explicável ("0,30 → 0,63 com a costura, LR 4,0") | Não aproveita a evidência ausente, que tem LR = 1 |
| Sem estado partilhado: cálculo puro em Java, testável sem Drools | Não trata a incerteza da própria observação ("talvez") |

### Opção B — PROSPECTOR (LS/LN por antecedente)

- **Dois pesos por regra:** cada regra tem uma razão de suficiência (LS), usada quando a evidência está presente, e
  uma razão de necessidade (LN), usada quando está ausente.
- **Evidência incerta:** é interpolada linearmente entre os dois pesos, conforme a certeza da observação.
- **Estrutura:** admite hipóteses intermédias (ex.: "dano de costura" como sub-hipótese) e regras determinísticas.

| Vantagens | Desvantagens |
|---|---|
| Usa a evidência ausente (LN) e a evidência incerta | Duplica os parâmetros a calibrar (LS e LN por regra) |
| Hipóteses intermédias tornam o raciocínio mais fiel à inspeção | Mais difícil de explicar a quem decide |

Pontos a avaliar na implementação de referência antes de a adotar:

1. **Pivô da interpolação.** Usa 0,5 em vez do prior da hipótese, o que distorce o resultado quando o prior não é 0,5
   (aqui é 0,30).
2. **Regras com vários antecedentes.** Só disparam se todos os factos existirem; um antecedente desconhecido bloqueia
   a regra, em vez de contribuir com peso neutro.
3. **Estado estático no listener.** Os valores ficam em campos estáticos, o que é incompatível com pedidos simultâneos
   numa API web e com a auditoria por avaliação.

## Decisão

Esta versão adota a **opção A**. O cálculo fica atrás da interface `ModeloBayesiano` (`pericial-uncertainty`), com
uma única implementação, `ModeloRazoesVerosimilhanca`. As regras IU-20 a IU-23 chamam apenas o `ServicoIncerteza`:
mudar para a opção B exige uma nova implementação da interface e novos parâmetros, mas nenhuma alteração às regras.

A opção B fica **em análise** até haver:

- dados de inspeção reais para calibrar LS e LN;
- uma correção dos três pontos acima na implementação de referência;
- a confirmação da operação de que a evidência incerta ("talvez") é útil na loja.

## Consequências

- Os resultados bayesianos são demonstrativos e marcados como tal na interface e nas explicações.
- Cada `GrauCrenca` guarda a versão dos parâmetros e as contribuições, incluindo as não aplicadas e o motivo, para
  que uma decisão possa ser reconstruída depois de uma mudança de método.
- Se se adotar a opção B, este ADR passa a "Substituído" e um novo ADR regista a calibração.
