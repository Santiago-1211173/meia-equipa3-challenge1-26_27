# 🎯 Plano de Implementação — Redesign Dashboard RetailFlow

> **Objetivo:** Transformar o dashboard atual (dark mode, técnico, baseado em JSON) num produto "sellable" estilo POS de retalho, seguindo o design system **"Tactile Playful POS"** já definido. O resultado deve parecer uma aplicação real de loja de roupa, com zero atrito para o operador.

> **Executor:** Agente Gemini 3.8 Flash High
> **Stack:** Next.js 16 + React 19 + TailwindCSS 4 + TypeScript
> **Fonte do design:** `chalange1_design/` (8 sub-pastas com screenshots e HTML de referência)

---

## 📐 Referência Visual — Screenshots do Design Alvo

Cada screenshot abaixo representa um ecrã do design alvo. O agente deve reproduzir fielmente o aspeto visual, layout e comportamento interativo de cada um.

````carousel
![Página Inicial — Dashboard do operador com hero, CTA principal, últimos casos resolvidos e dicas](C:/Users/santi/.gemini/antigravity-ide/brain/0a4ebe64-7018-4ada-8316-451ad733599d/design_pagina_inicial.png)
<!-- slide -->
![Passo 1 — Seleção do motor de inferência (Drools vs Prolog), cards grandes táteis](C:/Users/santi/.gemini/antigravity-ide/brain/0a4ebe64-7018-4ada-8316-451ad733599d/design_passo1.png)
<!-- slide -->
![Passo 2 — Mercado e Tipo de Loja: jurisdição, formato comercial, canal de compra](C:/Users/santi/.gemini/antigravity-ide/brain/0a4ebe64-7018-4ada-8316-451ad733599d/design_passo2.png)
<!-- slide -->
![Passo 3 — Elegibilidade do Produto: validação inicial, estado físico, defeitos](C:/Users/santi/.gemini/antigravity-ide/brain/0a4ebe64-7018-4ada-8316-451ad733599d/design_passo3.png)
<!-- slide -->
![Passo 4 — Comprovativo e Prazo: tipo de pedido, recibo, janela temporal](C:/Users/santi/.gemini/antigravity-ide/brain/0a4ebe64-7018-4ada-8316-451ad733599d/design_passo4.png)
<!-- slide -->
![Passo 5 — Troca ou Exceção de Balcão: opções de troca, situação do cliente](C:/Users/santi/.gemini/antigravity-ide/brain/0a4ebe64-7018-4ada-8316-451ad733599d/design_passo5.png)
<!-- slide -->
![Passo 6 — Meio de Reembolso e Liquidação: tipo de devolução, pagamento, finalizar](C:/Users/santi/.gemini/antigravity-ide/brain/0a4ebe64-7018-4ada-8316-451ad733599d/design_passo6.png)
<!-- slide -->
![Caminho Online — Fluxo alternativo para compras BackPocket/levi.com](C:/Users/santi/.gemini/antigravity-ide/brain/0a4ebe64-7018-4ada-8316-451ad733599d/design_caminho_online.png)
````

---

## 🏗️ Arquitetura Atual vs. Alvo

### Estado Atual

O dashboard é uma SPA Next.js em **dark mode** com aspeto técnico/developer:
- Página única (`page.tsx`) com dois motores em tabs
- O utilizador **seleciona cenários JSON predefinidos** e vê resultados em tabelas/code blocks
- Layout 2-colunas: editor JSON à esquerda, resultado à direita
- Sem fluxo step-by-step, sem cards táteis, sem branding de produto
- CSS com variáveis dark (`--bg-page: #09090b`)
- Mostra códigos de regras internos (IN-005, PT-003, etc.)

### Estado Alvo

- **Light mode** com design system "Tactile Playful"
- **Multi-página** com routing: Home → Passo 1 → 2 → 3 → 4 (→ 5 → 6 se necessário)
- **Wizard step-by-step** com progress bar tátil e cards de seleção grandes
- **Zero jargão técnico** — sem códigos de regras, sem JSON visível ao operador
- Branding "RetailFlow" com navbar fixa, avatar do operador, badge de streak
- O operador responde a perguntas simples (seleção visual), não manipula JSON

### Ficheiros-chave existentes a preservar/adaptar

| Ficheiro | Decisão |
|---|---|
| `src/app/globals.css` | ❌ Reescrever totalmente (dark → light, variáveis novas) |
| `src/app/layout.tsx` | ✏️ Atualizar (adicionar fonte Plus Jakarta Sans, navbar global) |
| `src/app/page.tsx` | ✏️ Transformar na landing page (hero + últimos casos) |
| `src/components/engines/ReturnsPanel.tsx` | ❌ Substituir pelo wizard multi-step |
| `src/components/shared/EngineWorkspace.tsx` | ❌ Substituir por layout do wizard |
| `src/components/shared/StepIndicator.tsx` | ✏️ Refazer com progress bar tátil (pill capsules) |
| `src/components/shared/EngineNav.tsx` | ❌ Substituir pela navbar global do design |
| `src/config/returnsLabels.ts` | ✅ Preservar (tradução de enums) |
| `src/config/engines.ts` | ✏️ Adaptar steps para o novo fluxo |
| `src/config/gateway.ts` | ✅ Preservar (proxy config) |
| `src/server/brand.ts` | ✅ Preservar (neutralização de marca) |
| `src/client/api.ts` | ✅ Preservar (API client) |
| `src/types/returns.ts` | ✅ Preservar (tipos do motor) |
| `src/components/returns/ExplainTabs.tsx` | ✏️ Adaptar estilo visual (preservar lógica) |
| `src/components/returns/DecisionSummary.tsx` | ✏️ Redesign visual para resultado final |

---

## 🎨 Design System — Tokens Obrigatórios

O agente **DEVE** seguir estes tokens rigorosamente. São a única fonte de verdade para cores, tipografia e espaçamento.

### Cores (Light Mode)

```css
:root {
  /* Canvas e Surfaces */
  --surface:               #FAF8FF;   /* Background principal */
  --surface-container-low: #F2F3FF;
  --surface-container:     #EAEDFF;
  --surface-container-high:#E2E7FF;
  --surface-container-lowest: #FFFFFF; /* Cards/Modals */
  --on-surface:            #131B2E;   /* Texto principal */
  --on-surface-variant:    #3C4A42;   /* Texto secundário */

  /* Primary (Emerald) — ações de progresso, aprovação */
  --primary:               #006C49;
  --primary-container:     #10B981;
  --on-primary:            #FFFFFF;
  --on-primary-container:  #00422B;
  --primary-pressed:       #059669;   /* Bottom-border 3D */

  /* Secondary (Royal Blue) — seleção, toggle, navegação */
  --secondary:             #0058BE;
  --secondary-container:   #2170E4;

  /* Tertiary (Amber) — avisos, créditos loja */
  --tertiary:              #855300;
  --tertiary-container:    #E29100;
  --tertiary-fixed:        #FFDDB8;

  /* Error */
  --error:                 #BA1A1A;
  --error-container:       #FFDAD6;

  /* Outlines */
  --outline:               #6C7A71;
  --outline-variant:       #BBCABF;
  --border-card:           #E2E8F0;
  --border-card-bottom:    #CBD5E1;
}
```

### Tipografia

**Fonte única:** `Plus Jakarta Sans` (pesos 500, 700, 800)

| Token | Size | Weight | Line-height | Uso |
|---|---|---|---|---|
| display-hero | 40px | 800 | 48px | Título da landing page |
| headline-lg | 30px | 700 | 38px | Títulos de passo |
| headline-md | 22px | 700 | 28px | Subtítulos de secção |
| headline-sm | 18px | 700 | 24px | Títulos de card |
| body-xl | 18px | 500 | 28px | Opções de seleção |
| body-lg | 16px | 500 | 24px | Texto geral |
| body-md | 14px | 500 | 20px | Descrições |
| label-lg | 14px | 700 | 18px | Labels, badges |
| label-md | 12px | 700 | 16px | Tags, chips |
| caption | 12px | 500 | 16px | Notas, ajuda |

### Elevação (Estilo Tátil 3D)

```
Card normal:      border: 2px solid #E2E8F0; border-bottom: 3px solid #CBD5E1;
Card selecionado: border: 2px solid #3B82F6; border-bottom: 4px solid #1D4ED8; background: #EFF6FF;
Botão primário:   background: #10B981; box-shadow: 0 4px 0 0 #059669;
Botão primário:hover  → translate-y: 2px; box-shadow: 0 2px 0 0 #059669;
Botão primário:active → translate-y: 4px; box-shadow: none;
```

### Shapes

- Botões e chips: `border-radius: 9999px` (pill)
- Cards interativos: `border-radius: 1.5rem` (24px)
- Progress bar: segmentos pill com `height: 10px; border-radius: 9999px`

---

## 🧩 Componentes Partilhados (Design System)

> [!IMPORTANT]
> Estes componentes são **reutilizados em várias páginas**. Devem ser criados PRIMEIRO e importados consistentemente. Nunca duplicar estilos inline.

### 1. Navbar

- **Usado em:** Todas as páginas
- **Design:** Barra fixa topo, branding "RetailFlow" com ícone bolt, navegação pill-shaped, badge do operador
- **Referência visual:** Topo de todos os screenshots
- **Props:** `activeRoute: string`, `operatorName: string`
- **Notas:** O link ativo tem `bg-primary text-on-primary rounded-full shadow-[0_3px_0_0_#005236]`

### 2. ProgressBar

- **Usado em:** Todos os passos do wizard
- **Design:** Barra segmentada com capsules pill. Segmentos completos = emerald (#10B981). Atual = animação de progresso. Futuros = cinza (#E2E8F0)
- **Referência visual:** Parte inferior dos passos 1 a 6
- **Props:** `totalSteps: number`, `currentStep: number`, `nextLabel?: string`

### 3. TactileCard (Card de Seleção)

- **Usado em:** Passos 1, 2, 3, 4, 5, 6
- **Design:** Card grande com ícone (48x48 rounded), título bold, descrição, borda 3D tátil
- **Estados:** Normal (white + outline cinza), Selected (azul + background EFF6FF + checkmark), Disabled (opacidade 0.5)
- **Props:** `icon: ReactNode`, `title: string`, `description?: string`, `selected: boolean`, `onClick: () => void`, `badge?: string`
- **Comportamento:** Ao clicar, transição suave. O card "desce" 2px ao selecionar (press effect)

### 4. StepHeader

- **Usado em:** Todos os passos do wizard
- **Design:** Badge "PASSO X DE Y" em pill emerald, título headline-lg centrado, descrição body-lg
- **Props:** `step: number`, `totalSteps: number`, `title: string`, `subtitle?: string`

### 5. NavigationFooter

- **Usado em:** Todos os passos
- **Design:** Botão "Voltar" (pill outline cinza) à esquerda, texto "A seguir: ..." ao centro, botão "Continuar" (pill emerald 3D) à direita
- **Props:** `onBack?: () => void`, `onNext: () => void`, `nextLabel: string`, `nextHint?: string`, `disabled?: boolean`

### 6. SectionCard

- **Usado em:** Passos 2, 3, 4 (agrupa sub-secções numeradas)
- **Design:** Card branco com rounded-xl, padding generoso, título numerado (1., 2., 3.)
- **Props:** `number: number`, `title: string`, `children: ReactNode`

### 7. StatusFooter

- **Usado em:** Todas as páginas
- **Design:** Barra inferior com status dos motores (dot verde/amarelo + label), versão do sistema
- **Props:** `droolsStatus: 'online' | 'offline'`, `prologStatus: 'online' | 'offline'`

### 8. ToggleButton (Sim/Não ou opções binárias)

- **Usado em:** Passo 3 (validação de peça)
- **Design:** Dois botões pill lado a lado, o selecionado em emerald com checkmark
- **Props:** `options: {label: string, value: string}[]`, `selected: string | null`, `onChange: (value: string) => void`

### 9. ResultCard

- **Usado em:** Resultado final (após submissão)
- **Design:** Card com fundo emerald/vermelho/amber conforme elegibilidade, ícone grande, valor monetário, explicação em linguagem simples
- **Props:** `eligibility: Elegibilidade`, `refundValue?: number`, `explanation: string`

---

## 📋 Fases de Implementação

---

### FASE 0 — Preparação e Design System Foundation

**Duração estimada:** 1 sessão
**Prioridade:** Crítica (bloqueia tudo)

#### Tarefas:

**0.1** Instalar a fonte Plus Jakarta Sans no `layout.tsx`:

```tsx
import { Plus_Jakarta_Sans } from 'next/font/google';
const plusJakarta = Plus_Jakarta_Sans({
  subsets: ['latin'],
  weight: ['500', '700', '800'],
  variable: '--font-jakarta'
});
```

**0.2** Reescrever `globals.css` completamente:

- Remover TODAS as variáveis dark mode
- Implementar os tokens de cor, tipografia, espaçamento e elevação documentados acima
- Criar classes utilitárias para os componentes táteis
- A fonte `Plus Jakarta Sans` deve ser a default em `body`

**0.3** Atualizar `layout.tsx`:

- Aplicar a classe da fonte ao `<body>`
- Background `#FAF8FF`
- Meta tags SEO atualizadas (título "RetailFlow - Assistência Inteligente de Balcão")

**0.4** Criar a estrutura de pastas para as novas rotas:

```
src/app/
  page.tsx                     <- Landing page (Home)
  novo-atendimento/
    page.tsx                   <- Wizard container (redirect para passo 1)
    passo/[step]/page.tsx      <- Páginas dinâmicas do wizard (1-6)
  decisoes/page.tsx            <- Histórico (placeholder)
  layout.tsx                   <- Root layout com Navbar
src/components/
  ui/                          <- Componentes do design system
    Navbar.tsx
    ProgressBar.tsx
    TactileCard.tsx
    StepHeader.tsx
    NavigationFooter.tsx
    SectionCard.tsx
    StatusFooter.tsx
    ToggleButton.tsx
    ResultCard.tsx
  wizard/                      <- Componentes específicos de cada passo
    WizardContext.tsx
    Step1EngineSelect.tsx
    Step2MarketStore.tsx
    Step3ProductEligibility.tsx
    Step4ReceiptTimeline.tsx
    Step5ExchangeExceptions.tsx
    Step6Refund.tsx
    OnlinePath.tsx
    VerdictScreen.tsx
  home/                        <- Componentes da landing page
    HeroSection.tsx
    RecentCases.tsx
    QuickActions.tsx
```

> [!TIP]
> Cria todos os ficheiros de componente UI primeiro (FASE 1) antes de construir as páginas. Isto garante que cada página importa componentes testados e consistentes.

---

### FASE 1 — Componentes UI do Design System

**Duração estimada:** 1 sessão
**Prioridade:** Crítica

Implementar os 9 componentes partilhados documentados acima, em `src/components/ui/`. Cada componente deve:

- Ser **client component** (`"use client"`)
- Receber props tipadas com TypeScript
- Usar **exclusivamente** variáveis CSS e classes Tailwind definidas no design system
- Ter animações de transição suaves (150ms ease)
- Ser acessível (aria-labels, aria-current, focus states)

#### Detalhes de implementação por componente:

**Navbar:**

- Logo "RetailFlow" com ícone bolt num círculo emerald com sombra 3D inferior
- Badge "Loja Central - Caixa Aberto" com dot verde pulsante
- Links de navegação em formato pill
- Badge de streak "18 SEGUIDAS" em amber (tertiary-fixed)
- Avatar do operador com nome e nível (N2)
- `position: fixed; top: 0` com backdrop-blur

**ProgressBar:**

- Container com flex e gap entre segmentos
- Cada segmento: `height: 10px`, `border-radius: 9999px`, `flex: 1`
- Cores: completo = `#10B981`, atual = `#10B981` com animation pulse, futuro = `#E2E8F0`
- Abaixo dos segmentos: texto "Próximo: [nome do passo seguinte]"

**TactileCard:**

- Container: `background: white`, `border: 2px solid #E2E8F0`, `border-bottom: 3px solid #CBD5E1`, `border-radius: 1.5rem`, `padding: 1.5rem`
- Ícone numa caixa 48x48 com `rounded-xl bg-surface-container-low`
- Quando `selected`: `background: #EFF6FF`, `border-color: #3B82F6`, `border-bottom: 4px solid #1D4ED8`, checkmark verde no canto
- Transição: `transform`, `border`, `background` em 150ms
- **Press effect:** `active:translate-y-[2px]`, sombra inferior reduz

---

### FASE 2 — Landing Page (Home)

**Duração estimada:** 1 sessão
**Prioridade:** Alta

Transformar `src/app/page.tsx` na página inicial do design.

#### Referência visual:

![Página Inicial](C:/Users/santi/.gemini/antigravity-ide/brain/0a4ebe64-7018-4ada-8316-451ad733599d/design_pagina_inicial.png)

#### Secções a implementar:

**2.1 Hero Section** (`src/components/home/HeroSection.tsx`)

- Fundo gradiente suave (surface-container para primary-fixed com 20% opacidade)
- Saudação personalizada: "Olá, [Nome]!" com emoji 👋 em `display-hero`
- Frase motivacional: "Pronto para o turno de hoje? Cada devolução clara cria um cliente fiel."
- Badges de estado: "Consenso Drools e Prolog Ativo", "SLA Médio: 7.4s"
- **CTA box à direita:** Card branco com "Balcão Rápido", botão "Iniciar Nova Troca ou Devolução" (emerald 3D grande) + botão secundário "Consultar Políticas Rápidas"
- Glows decorativos (circles com blur no background)

**2.2 Últimos Casos Resolvidos** (`src/components/home/RecentCases.tsx`)

- Card branco com título "Últimos Casos Resolvidos no Teu Balcão"
- Filtros pill: "Todos (24)", "Devoluções", "Trocas"
- Lista de cards táteis com: ícone de status, referência (#RF-XXXX), nome do produto, badge de resultado (verde=aprovado, amber=troca, vermelho=recusado), descrição em linguagem simples da regra aplicada, botões "Ver Veredito" e imprimir

> [!CAUTION]
> A descrição da regra aplicada NUNCA mostra códigos (PT-003, IN-005). Deve ser sempre texto descritivo como "Etiqueta original intacta, prazo cumprido (14 dias) e comprovativo digital verificado."

**2.3 Dica do Dia** (inline na landing)

- Card com fundo azul claro, ícone de lâmpada, título da dica, botão "Compreendido! 👍"
- Conteúdo fixo ou rotativo (pode ser hardcoded para demo)

**2.4 Quick Actions Footer**

- 3 cards horizontais: "Trocar de Operador", "Simular Cenário de Treino", "Políticas Março 2025"
- Cada um com ícone, título, subtítulo e seta para a direita

---

### FASE 3 — Wizard Multi-Step (Fluxo de Atendimento)

**Duração estimada:** 2 sessões
**Prioridade:** Crítica

Este é o core da aplicação. Quando o operador clica "Iniciar Nova Troca ou Devolução", entra num wizard de 4 a 6 passos onde vai respondendo a perguntas visuais (cards táteis).

#### Arquitetura do Wizard

Criar um **WizardContext** (`src/components/wizard/WizardContext.tsx`) que:

- Mantém o estado global do wizard como um `Record<string, unknown>`
- Expõe `setField(key, value)`, `getField(key)`, `goToStep(n)`, `currentStep`, `totalSteps`
- Acumula as respostas do operador e no final constrói o `ReturnRequest` para enviar à API
- O mapeamento de campos visuais para campos do `ReturnRequest` JSON fica **exclusivamente** neste context (o operador NUNCA vê JSON)

#### Container da rota (`src/app/novo-atendimento/passo/[step]/page.tsx`)

- Lê o param `step` (1 a 6)
- Renderiza: `<StepHeader>` + componente do passo + `<ProgressBar>` + `<NavigationFooter>`
- Valida que o step anterior está preenchido antes de permitir avançar

---

#### Passo 1 — Seleção do Motor

**Referência:** design_passo1.png

![Passo 1](C:/Users/santi/.gemini/antigravity-ide/brain/0a4ebe64-7018-4ada-8316-451ad733599d/design_passo1.png)

- Título: "Selecione o Motor de Avaliação"
- Dois TactileCard lado a lado:
  - **Motor Drools:** Ícone bolt, título "Motor Drools 8.44", subtítulo "Motor de Regras Ágil e Rete-OO"
  - **Motor Prolog:** Ícone circle, título "Motor Prolog 9.2", subtítulo "Dedução Lógica Formal e Cláusulas de Horn"
- Radio-button visual (circle outline no card, filled quando selecionado)
- Footer: Seleção atual em texto, botões "Guardar" e "Continuar para Passo 2"

> [!NOTE]
> Apesar do design original mostrar nomes técnicos (Rete-OO, Cláusulas de Horn), MANTER porque esta seleção é para fins de demo/apresentação e mostra os dois motores do sistema. O operador real provavelmente não escolheria, mas para o contexto académico faz sentido mostrar.

---

#### Passo 2 — Mercado e Tipo de Loja

**Referência:** design_passo2.png

![Passo 2](C:/Users/santi/.gemini/antigravity-ide/brain/0a4ebe64-7018-4ada-8316-451ad733599d/design_passo2.png)

- Título: "Mercado e Tipo de Loja"
- 3 secções numeradas em SectionCard:
  1. **Jurisdição Territorial e Fiscal:** 2 cards — "Estados Unidos (EUA)" [badge Ativo], "Canadá (CA)"
  2. **Formato Comercial da Loja Recetora:** 2 cards — "Loja Mainline" (com tags: Coleções Atuais, LVC, Made and Crafted), "Loja Outlet" [badge Factory Store] (com tags: SMFO, Clearance, Descontos Escalonados)
  3. **Canal de Compra Original:** 5 cards em grid — "Loja Física", "Online/BackPocket", "Franquia Canadiana", "Grossista/Externo", "Desconhecido"
- Cada opção com ícone, título, descrição curta
- **Mapeamento ao JSON do motor:** Canal mapeia para `compraOriginal.canal`, Tipo mapeia para `loja.tipoLoja`

---

#### Passo 3 — Elegibilidade do Produto

**Referência:** design_passo3.png

![Passo 3](C:/Users/santi/.gemini/antigravity-ide/brain/0a4ebe64-7018-4ada-8316-451ad733599d/design_passo3.png)

- Título: "Elegibilidade do Produto"
- Subtítulo: "Confirme os detalhes da peça e a sua condição física para validar a devolução"
- 2 secções:
  1. **Validação Inicial da Peça:**
     - Pergunta "Código de barras reconhecido?" com ToggleButton Sim/Não
     - Pergunta "Marca permitida na loja?" com ToggleButton Sim/Não
     - Pergunta "Peça com alterações ou bainhas feitas?" com ToggleButton Não (corte original) / Sim (alterada)
     - Pergunta "Roupa Interior ou Peça Íntima?" com ToggleButton Não (Normal) / Sim (Peça íntima)
     - Pergunta "Tem defeito de fabrico visível?" com ToggleButton Sem defeito aparente / Defeito confirmado
  2. **Estado Físico da Peça:**
     - Grid 3x2 de TactileCard com ícones:
       - "Não usado, com etiquetas" | "Não usado, etiquetas soltas" | "Não usado, sem etiquetas"
       - "Claramente usado" | "Lavado" | "Sujo ou manchado"
     - Pergunta "Pronta para voltar a ser vendida?" com ToggleButton Sim/Não

- **Mapeamento:** Condição mapeia para `artigos[0].estado.condicaoUso`, Etiquetas mapeia para `artigos[0].estado.etiquetas`

---

#### Passo 4 — Comprovativo e Prazo

**Referência:** design_passo4.png

![Passo 4](C:/Users/santi/.gemini/antigravity-ide/brain/0a4ebe64-7018-4ada-8316-451ad733599d/design_passo4.png)

- Título: "Comprovativo e Prazo"
- 3 secções:
  1. **Tipo de Pedido:** 4 cards — "Devolução Standard", "Troca por Artigo", "Devolução de Oferta", "Ajuste de Preço"
  2. **Comprovativo de Compra:** 5 opções em lista — "Recibo Original de Compra" [badge Recomendado], "Confirmação Online", "Recibo de Oferta", "Consulta no Terminal POS", "Sem Comprovativo"
  3. **Dias desde a Compra:** 2 cards — "Até 30 Dias" [badge verde], "Mais de 30 Dias" [badge cinza]
- **Mapeamento:** Tipo mapeia para `tipoPedido`, Comprovativo mapeia para `comprovativo.tipo`, Dias usado para calcular `compraOriginal.dataCompra`

---

#### Passo 5 — Troca ou Exceção de Balcão (condicional)

**Referência:** design_passo5.png

![Passo 5](C:/Users/santi/.gemini/antigravity-ide/brain/0a4ebe64-7018-4ada-8316-451ad733599d/design_passo5.png)

- Só aparece se o tipo de pedido envolve troca ou exceção
- 2 secções:
  1. **O cliente pretende fazer uma troca?** 3 cards: "Não, Manter Devolução Normal", "Troca pelo Mesmo Modelo/Tamanho", "Troca por Outro Artigo Diferente"
  2. **Situação do Cliente no Balcão:** 3 cards com emojis: "Conforme/Aceite" (smile), "Contesta Política" (speech bubble), "Chamar Gerência" (warning)
  - Card adicional: "Exceção de Gerência Necessária?" com opções Sim/Não

> [!WARNING]
> Neste passo o design original mostra códigos de regras (EP-001, EX-002, etc.). O agente **DEVE REMOVER todos os códigos** e substituí-los por texto descritivo. Exemplo: em vez de "Regras EX-002 e EX-003 - Mediação e Escalonamento", usar apenas "Mediação e Escalonamento".

---

#### Passo 6 — Meio de Reembolso e Liquidação

**Referência:** design_passo6.png

![Passo 6](C:/Users/santi/.gemini/antigravity-ide/brain/0a4ebe64-7018-4ada-8316-451ad733599d/design_passo6.png)

- 3 secções:
  1. **Tipo de Devolução:** 2 cards — "Devolução Normal" [badge Padrão], "Recibo de Oferta (Gift)" [badge Opcional]
  2. **Meio de Pagamento Original Detetado:** Card com informação do cartão (auto-preenchido ou seleção manual)
  3. **Estado da Conta / Validação:** 2 cards — "Conta Ativa / Normal", "Cartão / Conta Encerrada"
- **Resumo final:** Card com fundo emerald: "Reembolso Tokenizado Pronto a Emitir" + valor monetário grande
- Botão final: "Finalizar e Gerar Recibo" com ícone sparkles (emerald 3D, tamanho extra)

---

### FASE 4 — Integração com API e Resultado

**Duração estimada:** 1 sessão
**Prioridade:** Crítica

#### 4.1 Construção do pedido

- No `WizardContext`, quando o operador chega ao último passo e clica "Calcular Veredito Final" ou "Finalizar":
  - Construir o objeto `ReturnRequest` a partir das respostas acumuladas
  - Chamar `api('/api/returns/avaliar', { method: 'POST', body: request })` ou equivalente Prolog conforme motor selecionado no Passo 1
  - Mostrar loading state com animação emerald

#### 4.2 Ecrã de resultado (VerdictScreen)

- Criar componente VerdictScreen que mostra:
  - Badge grande com elegibilidade (PERMITIR = verde, RECUSAR = vermelho, REVER = amber)
  - Valor a devolver em destaque
  - Explicação em linguagem natural (usar o campo `resumo` da resposta, NUNCA códigos de regra)
  - Timeline "Como decidimos" (usar dados de `ExplicacaoComoResponse` mas renderizar como cards táteis com checkmark/cross, SEM mostrar `codigoRegra`)
  - Botões: "Novo Atendimento", "Imprimir Recibo", "Ver Detalhes"

#### 4.3 Adaptação do ExplainTabs

- Manter a lógica existente em `ExplainTabs.tsx` mas:
  - Mudar o estilo visual para o design system tátil
  - Na tab "Como chegou aqui?", renderizar `nomeRegra` (nunca `codigoRegra`)
  - Na tab "Porque não...?", esconder `codigoRegra`, mostrar apenas `resumo` e `condicoes` com linguagem simples
  - Na tab "O que falta?", esconder `item.caminho` (path do JSON), mostrar apenas `item.descricao`
  - Tab "E se...?" mantém os presets mas com visual tátil

---

### FASE 5 — Caminho Online (Fluxo Alternativo)

**Duração estimada:** 0.5 sessão
**Prioridade:** Média

**Referência:** design_caminho_online.png

![Caminho Online](C:/Users/santi/.gemini/antigravity-ide/brain/0a4ebe64-7018-4ada-8316-451ad733599d/design_caminho_online.png)

Se no Passo 2 o operador seleciona "Online / BackPocket" como canal de compra, o fluxo bifurca para este caminho simplificado:

- 3 secções:
  1. **Localização da Encomenda Web:** "Sim, Encomenda Localizada" / "Não Encontrada"
  2. **Método de Pagamento Original:** 4 cards — "Cartão de Crédito/Débito", "Afterpay (BNPL)", "PayPal/Venmo", "Apple Pay/Google Pay"
  3. **Janela de Expedição e Tipo de Resolução:** "Menor ou igual a 30 dias desde o envio" / "Mais de 30 dias", + pergunta "Cliente pretende trocar diretamente no balcão?"
- Botão final: "Processar na BackPocket" com ícone rocket

---

### FASE 6 — Polish e Micro-interações

**Duração estimada:** 0.5 sessão
**Prioridade:** Média

#### 6.1 Animações

- Cards táteis: press-down effect com `transition: transform 150ms ease, box-shadow 150ms ease`
- Progress bar: segmentos preenchem com animation `ease-out 300ms`
- Transição entre passos: fade-in suave
- Botão CTA: hover eleva ligeiramente, active desce

#### 6.2 Estados vazios e de loading

- Loading: spinner emerald com texto "A processar..."
- Erro: card com border vermelha e ícone warning, botão "Tentar novamente"
- Sucesso: confetti discreto (opcional) ou checkmark animado

#### 6.3 Responsividade

- Mobile (menor que 640px): cards empilham em coluna, navbar colapsa para hamburger
- Tablet (640px a 1024px): layout centrado, max-width 680px no wizard
- Desktop (maior que 1024px): layout com max-width 1200px, 2 colunas onde aplicável

#### 6.4 Acessibilidade

- Todos os cards interativos: `role="radio"` ou `role="option"`, `aria-checked`
- Focus visible com outline emerald
- Skip-to-content link
- Navegação por teclado no wizard

---

## Regras de Ouro para o Agente Executor

> [!CAUTION]
> Estas regras são **invioláveis**. Se alguma for quebrada, o resultado não é aceitável.

1. **NUNCA mostrar códigos de regras na UI** (PT-003, IN-005, EX-002, HS-001, OUT-001, etc.). Todo o texto virado para o operador deve ser em linguagem natural portuguesa.

2. **NUNCA mostrar JSON ao operador.** O editor JSON raw (`RequestEditor.tsx`) desaparece. Os campos são preenchidos visualmente.

3. **Preservar TODA a lógica de negócio existente.** Os ficheiros `src/client/`, `src/server/`, `src/config/gateway.ts`, `src/types/` e `src/app/api/` não devem ser alterados funcionalmente — apenas adaptados visualmente quando necessário.

4. **Font única: Plus Jakarta Sans.** Não usar system fonts, Roboto, Inter, ou qualquer outra.

5. **Light mode APENAS.** Zero referências a dark mode.

6. **Cor primária: emerald (#10B981 / #006C49).** Não usar vermelho/laranja para CTAs.

7. **Botões 3D táteis.** Todos os botões primários devem ter a sombra inferior sólida e press effect.

8. **Componentes UI partilhados.** Nunca reescrever inline o estilo de um Navbar, ProgressBar ou TactileCard. Importar sempre de `@/components/ui/`.

9. **Texto sempre em Português Europeu** (pt-PT). Não pt-BR.

10. **Os ficheiros de design em `chalange1_design/` são referência visual, não código para copiar.** O HTML deles usa Tailwind CDN e é slop — o código novo deve ser limpo, componentizado e seguir as convenções do projeto Next.js existente.

---

## Resumo das Fases

| Fase | Conteúdo | Estimativa | Depende de | Estado |
|------|----------|------------|------------|--------|
| **0** | Preparação: CSS, fonte, routing, estrutura de pastas | 1 sessão | nada | ✅ Concluída |
| **1** | 9 Componentes UI do design system | 1 sessão | Fase 0 | ✅ Concluída |
| **2** | Landing Page (Home) | 1 sessão | Fase 1 | ✅ Concluída |
| **3** | Wizard 6 passos + WizardContext | 2 sessões | Fase 1 | ✅ Concluída |
| **4** | Integração API + resultado final | 1 sessão | Fase 3 | ✅ Concluída |
| **5** | Caminho Online (alternativo) | 0.5 sessão | Fase 3 | ✅ Concluída |
| **6** | Polish, animações, responsivo, a11y | 0.5 sessão | Todas | ✅ Concluída |

**Total estimado: aproximadamente 7 sessões (Todas as Fases Concluídas com Sucesso 🎉)**
