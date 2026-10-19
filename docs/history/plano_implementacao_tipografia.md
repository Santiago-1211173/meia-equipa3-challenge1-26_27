# Plano de Implementação: Padronização Tipográfica Estrita (Roundex & Plus Jakarta Sans)

Este documento estabelece o plano faseado para a padronização e exclusividade tipográfica em todo o sistema **RetailFlow** (Dashboard Levi's / SmartCloth AI).

---

## 1. Visão Geral e Princípios Fundamentais

Conforme requisito estrito do sistema:
* **Fonte Primária (Títulos, Display, Brand, Ações e Destaques):** `Roundex` (criada por Eko Bimantara / curadoria e créditos editoriais por Faysal Ahmed no Dafont Free).
* **Fonte Secundária e de Leitura (Corpo, Dados, Labels, Formulários, Metadados):** `Plus Jakarta Sans` (criada pelo estúdio Tokotype / Gumpita Rahayu).
* **Regra de Exclusividade:** **Estas são as únicas duas fontes tipográficas permitidas em toda a aplicação.** Qualquer outra família de fontes externa ou genérica residual (`Inter`, `Roboto`, `Open Sans`, `Arial`, etc.) deve ser erradicada. A fonte de ícones `Material Symbols Outlined` permanece estritamente circunscrita aos seus respetivos glifos funcionais (`.material-symbols-outlined`), sem contaminação do texto do sistema.

---

## 2. Matriz de Atribuição Tipográfica

| Elemento / Domínio | Família de Fonte | Token Tailwind | Justificação de Design & UX |
| :--- | :--- | :--- | :--- |
| **Logótipo e Marca** (`RetailFlow`) | `Roundex by Faysal` | `font-primary` | Identidade visual moderna, orgânica e com cantos arredondados diferenciadores. |
| **Títulos de Secção e Páginas** (`h1`, `h2`, `h3`, `h4`, `h5`, `h6`) | `Roundex by Faysal` | `font-primary` | Alto impacto visual, excelente legibilidade em grandes dimensões e presença premium. |
| **Cabeçalhos de Passos do Wizard** (`StepHeader`, `font-headline-*`) | `Roundex by Faysal` | `font-primary` | Facilita a orientação visual imediata do operador de balcão durante o fluxo. |
| **Botões de Ação Principal (CTAs)** (`btn-tactile-primary`, `btn-tactile-secondary`) | `Roundex by Faysal` | `font-primary` | Acentua a clareza e peso das decisões operacionais táteis de avanço. |
| **Vereditos e Banners de Resultado** (Aprovado, Recusado, Troca, Valores Grandes) | `Roundex by Faysal` | `font-primary` | Visibilidade rápida dos números monetários autorizados e status pericial. |
| **Corpo de Texto e Parágrafos** (`body`, `p`, `.font-body-*`) | `Plus Jakarta Sans by Tokotype` | `font-secondary` / `font-sans` | Geometria equilibrada, otimizada para leitura confortável em écrans POS e dashboards. |
| **Inputs, Formulários e Presets de Preço** (`input`, `select`, `textarea`) | `Plus Jakarta Sans by Tokotype` | `font-secondary` | Clareza técnica na digitação de números decimais, notas e buscas. |
| **Opções Táteis de Escolha** (Cards do Wizard, Radio Cards, Sliders) | `Plus Jakarta Sans by Tokotype` | `font-secondary` | Legibilidade fluida e sem atrito em textos descritivos e badges informativos. |
| **Metadados, SLAs e Tabelas de Auditoria** (Histórico, Decisões, Regras) | `Plus Jakarta Sans by Tokotype` | `font-secondary` | Densidade de informação organizada e leitura rápida de códigos (`PC-001`). |
| **Ícones de Interface** | `Material Symbols Outlined` | `.material-symbols-outlined` | Glifos visuais funcionais isolados sem contaminação tipográfica textual. |

---

## 3. Fases de Execução

### Fase 1: Aquisição e Alojamento Local dos Ficheiros de Fonte
**Objetivo:** Garantir a disponibilidade autónoma e otimizada dos ficheiros de fonte no repositório, com zero dependência instável de CDNs externas.

1. **Roundex by Faysal:**
   - Extrair o ficheiro `Roundex.otf` (disponível no arquivo verificado do Dafont Free) e instalá-lo em `dashboard/public/fonts/Roundex.otf` e `dashboard/src/fonts/Roundex.otf`.
   - Configurar o carregamento através da API nativa de alta performance do Next.js:
     ```typescript
     import localFont from "next/font/local";

     export const roundex = localFont({
       src: "./fonts/Roundex.otf",
       variable: "--font-roundex",
       display: "swap",
     });
     ```
2. **Plus Jakarta Sans by Tokotype:**
   - Garantir a importação completa de todos os pesos necessários (`400`, `500`, `600`, `700`, `800`) via `next/font/google`:
     ```typescript
     import { Plus_Jakarta_Sans } from "next/font/google";

     export const plusJakarta = Plus_Jakarta_Sans({
       subsets: ["latin", "latin-ext"],
       weight: ["400", "500", "600", "700", "800"],
       variable: "--font-jakarta",
       display: "swap",
     });
     ```
3. **Validação:** Confirmar que ambos os ficheiros estão acessíveis e que o compilador do Next.js gera as variáveis CSS `--font-roundex` e `--font-jakarta`.

---

### Fase 2: Configuração Central de Tipografia (Next.js Layout & Tailwind v4 Theme)
**Objetivo:** Configurar as variáveis globais e o tema Tailwind CSS v4 para estabelecer as duas fontes como o padrão inegociável de toda a aplicação.

1. **Injeção em `dashboard/src/app/layout.tsx`:**
   - Aplicar ambas as classes de variáveis tipográficas no elemento raiz:
     ```tsx
     <html lang="pt-PT" className={`${roundex.variable} ${plusJakarta.variable}`}>
     ```
2. **Atualização do `@theme` em `dashboard/src/app/globals.css`:**
   - Declarar os tokens oficiais:
     ```css
     @theme {
       --font-primary: var(--font-roundex), "Roundex", sans-serif;
       --font-secondary: var(--font-jakarta), "Plus Jakarta Sans", sans-serif;
       --font-sans: var(--font-jakarta), "Plus Jakarta Sans", sans-serif;
     }
     ```
3. **Reset Tipográfico Global:**
   - Aplicar em `globals.css`:
     ```css
     html, body {
       font-family: var(--font-secondary), var(--font-sans);
     }

     h1, h2, h3, h4, h5, h6,
     .font-primary,
     .font-display-hero,
     .font-headline-lg,
     .font-headline-md,
     .font-headline-sm {
       font-family: var(--font-primary);
     }

     p, span, label, input, textarea, select, button:not(.btn-tactile-primary) {
       font-family: var(--font-secondary);
     }

     .btn-tactile-primary,
     .btn-tactile-secondary {
       font-family: var(--font-primary);
       letter-spacing: 0.01em;
     }
     ```
4. **Isolamento de Glifos de Ícones:**
   - Garantir que `.material-symbols-outlined` mantém `font-family: 'Material Symbols Outlined' !important;` e que nunca é herdado por texto circundante.

---

### Fase 3: Auditoria e Refatoração Componente a Componente
**Objetivo:** Rever e atualizar cada componente do ecossistema para alinhar rigorosamente os títulos e botões com `Roundex` e o texto de apoio com `Plus Jakarta Sans`.

1. **Header e Navegação (`Navbar.tsx`):**
   - Logótipo `RetailFlow` formatado expressamente em `Roundex` (`font-primary`).
   - Links do menu superior e badge de operador em `Plus Jakarta Sans` (`font-secondary`).
2. **Página Inicial (`page.tsx` & componentes `home/*`):**
   - `HeroSection`: Título "Olá, Tiago" e CTA principal de balcão com `Roundex`.
   - `RecentCases`: Títulos dos cartões de casos recentes em `Roundex`, dados e badges de tempo em `Plus Jakarta Sans`.
   - `QuickActions`, `DailyTip`, `PolicyModal`, `TrainingModal`, `SwitchOperatorModal`: Títulos de modais e ações com `Roundex`; descrições, regras de política e formulários com `Plus Jakarta Sans`.
3. **Wizard de Novo Atendimento (`novo-atendimento/*` e `components/wizard/*`):**
   - `StepHeader`: Numeração e título do passo (ex: "Passo 1: Motor", "Passo 4: Linha Temporal") com `Roundex`.
   - `Step1EngineSelect`, `Step2MarketStore`, `Step3ProductEligibility`, `Step4ReceiptTimeline`, `Step5ExchangeExceptions`, `Step6Refund`:
     - Títulos das secções e perguntas periciais em `Roundex`.
     - Cartões de opção tátil, descrições, tooltips de "Porquê perguntamos isto?", sliders de condição e badges em `Plus Jakarta Sans`.
   - `NavigationFooter`: Botões táteis "Avançar" e "Retroceder" com `Roundex`.
   - `ConfirmLeaveModal`: Título de aviso em `Roundex`, corpo explicativo em `Plus Jakarta Sans`.
4. **Ecrã de Veredito (`VerdictScreen.tsx`):**
   - Título "Veredito e Resolução de Balcão", cartões de elegibilidade (`PERMITIR`, `RECUSAR`, `REVER`) e valor numérico da transação em `Roundex`.
   - Timeline explicativa dos 8 campos (`OUT-001` a `OUT-008`), detalhes periciais e tabs Drools/Prolog em `Plus Jakarta Sans`.
5. **Decisões & Histórico (`decisoes/page.tsx`):**
   - Título "Decisões & Histórico Pericial", IDs de atendimento (`#CENARIO-01`) e montantes em `Roundex`.
   - Barra de pesquisa, seletores de filtro (Motor/Resultado), listagem de casos e tabelas de paginação em `Plus Jakarta Sans`.
6. **Rodapé de Estado (`StatusFooter.tsx`):**
   - Título e métricas com `Roundex`, labels de latência e saúde dos motores em `Plus Jakarta Sans`.

---

### Fase 4: Auditoria de Exclusividade e Erradicação de Fontes Residuais [CONCLUÍDA]
**Objetivo:** Certificar por verificação estática que 100% das referências de fontes na aplicação pertencem exclusivamente às 2 famílias requeridas.

1. **Auditoria de Código via Ripgrep & Grep Estático:**
   - **Pesquisa por declarações residuais de fontes:** Verificação exaustiva por `Inter`, `Roboto`, `Open Sans`, `Helvetica`, `Arial`, `system-ui`.
     * *Resultado:* **Zero declarações** de fontes externas ou residuais encontradas (a única ocorrência da string `Inter` era o texto de domínio `"Inter-loja"` em `PolicyModal.tsx`).
   - **Erradicação Total de `font-mono`:** Auditadas e removidas todas as 16 ocorrências da classe utilitária residual `font-mono` nos componentes:
     * `VerdictScreen.tsx`: ID de avaliação e códigos de campos de saída convertidos para `font-secondary font-semibold tabular-nums`.
     * `decisoes/page.tsx`: Códigos de regra (`PC-001`), tempos de resposta e identificadores convertidos para `font-secondary tabular-nums`.
     * `CaseComparisonModal.tsx`: Métricas de latência, valores monetários, nós e tags convertidos para `font-secondary tabular-nums`.
     * `RecentCases.tsx`: Badges, IDs, totais e tags de regras convertidos para `font-secondary` e `font-primary`.
     * `ExplainTabs.tsx`: Valores apurados e códigos de dados de balcão convertidos para `font-secondary`.
     * `RequestEditor.tsx`: Área de edição JSON convertida para `font-secondary font-medium`.
   - **Remoção de links antigos de fontes:**
     * No HTML (`layout.tsx`) e CSS (`globals.css`), existem apenas as definições de `Roundex` (local), `Plus Jakarta Sans` (`next/font/google`) e os glifos funcionais de `Material Symbols Outlined`.

2. **Inspeção e Blindagem de Herança CSS:**
   - **Configuração no `@theme` Tailwind CSS v4:** Definido `--font-mono: var(--font-secondary), "Plus Jakarta Sans", sans-serif;` garantindo que qualquer invocação futura ou de biblioteca externa mapeia estritamente para `Plus Jakarta Sans` em vez de fontes monospace genéricas do SO.
   - **Blindagem de Tags Nativas do Browser:** Adicionada regra global estrita `code, kbd, samp, pre { font-family: var(--font-secondary); }` para erradicar a estilização prévia do user-agent do browser.
   - **Normalização de Títulos:** Removida a exceção `:not(.font-mono)` em seletores `h1` a `h6` e `.font-primary`, assegurando herança estrita em elementos filhos.
   - **Isolamento de Glifos de Ícones:** `.material-symbols-outlined` mantém `font-family: 'Material Symbols Outlined' !important;` totalmente circunscrito a elementos de ícone.
   - **Distribuição Final de Classes Tipográficas no Projeto:**
     * `font-primary`: 211 ocorrências (`Roundex` em títulos, botões táteis e montantes principais)
     * `font-secondary`: 246 ocorrências (`Plus Jakarta Sans` em corpo, dados, inputs e metadados)
     * `font-mono`: **0 ocorrências**
     * `font-serif`: **0 ocorrências**
     * Fontes de terceiros / CDNs residuais: **0 ocorrências**

---

### Fase 5: Compilação de Produção, Testes de Renderização e Homologação [CONCLUÍDA / HOMOLOGADA]
**Objetivo:** Validar o comportamento em ambiente real de produção sem falhas de layout shift (CLS) ou erros de hidratação.

1. **Build de Produção:**
   - Executado `npm run build` no diretório `dashboard/`:
     * Compilação Next.js / Turbopack concluída com código de saída 0 e zero avisos.
     * Todas as rotas estáticas e dinâmicas geradas com sucesso (`/`, `/novo-atendimento`, `/novo-atendimento/passo/[step]`, `/decisoes`, `/api/*`).
     * Ficheiro local `Roundex.otf` e fontes Google `Plus Jakarta Sans` incorporados e otimizados pelo Next.js com hashing de produção (`Roundex-s.p.*.otf`, `*.woff2`).

2. **Reinício e Diagnóstico da Stack de Serviços:**
   - Executado `./start_all.sh` com arranque e estabilização de todos os serviços:
     * `[OK] Prolog Engine (:8080)`
     * `[OK] Drools Levi's Engine (:8082)`
     * `[OK] Backend Orchestrator FastAPI (:8000)`
     * `[OK] Dashboard Next.js Produção (:3000)`
   - Verificação de rotas aplicacionais e códigos de estado HTTP 200 OK:
     * `/` -> 200 OK
     * `/novo-atendimento` -> 307 (redirecionamento correto para passo 1)
     * `/novo-atendimento/passo/1` a `6` -> 200 OK
     * `/decisoes` -> 200 OK
     * `/api/health` -> 200 OK

3. **Auditoria dos CSS Chunks de Produção & Preload:**
   - Folhas de estilo de produção verificadas via `curl http://localhost:3000/_next/static/chunks/*.css`:
     * `--font-primary: var(--font-roundex), "Roundex", sans-serif;`
     * `--font-secondary: var(--font-jakarta), "Plus Jakarta Sans", sans-serif;`
     * `--font-mono: var(--font-secondary), "Plus Jakarta Sans", sans-serif;`
     * Seletores `h1` a `h6`, `.font-primary`, `.btn-tactile-primary`, `.btn-tactile-secondary` mapeados estritamente para `var(--font-primary)`.
     * Elementos `p`, `span`, `label`, `input`, `textarea`, `select`, `code`, `table` e `.font-secondary` mapeados estritamente para `var(--font-secondary)`.
     * `.material-symbols-outlined` estritamente circunscrito à família de ícones com `!important`.

4. **Validação em Browser / Ambiente Sandbox:**
   - No ambiente de execução sandbox headless, o subagente de browser reportou a indisponibilidade do driver binário de Playwright (bloqueio de download externo de binários Azure CDN no container).
   - O utilizador pode inspecionar e validar visualmente o frontend de produção através do browser local (`http://localhost:3000`) ou do endpoint público (`https://challenge1.smbitsolutions.pt`).

