# Dashboard — Sistema Especialista

Interface Next.js (App Router) para os três motores de inferência do projeto. Cada motor tem a sua aba e todos seguem o mesmo fluxo guiado: **escolher dados, executar, ver a decisão e a justificação, repetir ou limpar**.

| Aba | Motor | Modos / funcionalidades |
| --- | --- | --- |
| Drools · Devoluções | Drools (política de devoluções) | Cenários prontos, avaliação, decisão por artigo, "como", "porque não", dados em falta, simulação "e se" |
| Prolog | SWI-Prolog | **Inferência passo a passo** (carregar base, executar, factos, "como", "porque não", reiniciar) e **avaliação rápida** |
| Drools · Diagnóstico | Drools (diagnóstico por sintomas) | Sintomas sim/não, cenários prontos, diagnóstico e regras aplicadas |

A aba ativa fica na URL (`/?motor=returns|prolog|drools`) e o modo do Prolog também (`&modo=inference|evaluate`), por isso qualquer vista pode ser partilhada por link.

## Executar

```bash
npm install
npm run dev      # http://localhost:3000
npm run build && npm start
npm run lint
```

Requer o gateway (`backend_orchestrator`) a correr em `http://127.0.0.1:8000`. Não há variáveis de ambiente: gateway e dashboard correm na mesma máquina e a URL está numa constante em [`src/config/gateway.ts`](src/config/gateway.ts).

## Arquitetura

O browser **nunca** fala com o gateway. Fala com Route Handlers do Next (`src/app/api/**/route.ts`), que fazem proxy no servidor:

```
browser ──► /api/{prolog|drools|returns}/…  ──►  gateway :8000  ──►  motores
            (src/app/api, src/server/gateway.ts)
```

```
src/
  app/                 página (casca com abas) e Route Handlers
  components/
    shared/            esqueleto comum: abas, passos, resultado, erro, vazio
    engines/           um painel por motor (estado e fluxo)
    returns/           peças da aba de devoluções
  client/              chamadas do browser às rotas /api e saúde dos motores
  server/              acesso ao gateway (timeout, erros) e neutralização de marca
  config/              URL do gateway, rotas permitidas, rótulos e cenários
  types/               tipos dos contratos
```

- **Rotas permitidas:** cada motor só expõe os caminhos listados em `ENGINE_PROXY` ([`src/config/gateway.ts`](src/config/gateway.ts)). Qualquer outro responde 404.
- **Erros:** todas as rotas devolvem o mesmo formato, `{ error: { code, message, status } }`, com códigos como `ENGINE_UNAVAILABLE` e `TIMEOUT`. A interface mostra a mensagem tal como vem.
- **Saúde:** cada aba mostra um ponto verde ou vermelho; o botão "Atualizar estado" repete a verificação.

## Neutralidade de marca

A base de conhecimento de devoluções foi escrita a partir da política de uma marca concreta, mas o frontend não pode expô-la. Em [`src/server/brand.ts`](src/server/brand.ts):

- os valores de enum do motor que nomeiam a marca são trocados por aliases neutros à saída e repostos à entrada, para os pedidos continuarem válidos;
- o texto livre é reescrito e nunca volta ao motor como dado.

Ao acrescentar campos ou textos, use termos neutros ("política de devoluções", "loja", "cliente"). O único sítio onde o caminho do gateway aparece com o nome do motor é `src/config/gateway.ts`.

## Notas sobre os motores

- **Prolog (inferência):** a sessão do motor é única e partilhada. A interface retoma o que já estiver carregado. Carregar uma base inexistente apaga a sessão, por isso só se oferece a base `vehicles`.
- **Drools (diagnóstico):** as regras exigem `"yes"`/`"no"` explícitos, e a interface envia sempre os 13 sintomas (por omissão, "não").
- **Devoluções:** as explicações ("como", "porque não") precisam de a avaliação ter sido guardada pelo motor (`avaliacaoId`).
