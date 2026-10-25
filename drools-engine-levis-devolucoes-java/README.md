# Sistema pericial de devoluções e trocas Levi's

Sistema pericial usado pelos colaboradores das lojas Levi's (Mainline e Outlet, EUA e Canadá) para decidir
devoluções, trocas e ajustes de preço, e para explicar cada decisão (Como, Porquê, Porque não, E se, O que falta).

## Documentação

- `docs/01` a `docs/06`: base de conhecimento, regras IF/THEN, fluxograma, modelo, estrutura e cenários de teste.
- `docs/08-incerteza.md`: camada de tratamento da incerteza (fatores de certeza, Bayes, fuzzy), com valores
  demonstrativos.
- `docs/07-plano.md`: plano de implementação por fases, estado e fecho (Definição de concluído).
- `docs/adr/`: decisões de arquitetura e ambiguidades por validar (`0003-ambiguidades.md`).

## Convenções

### Fonte de verdade e decisões
- `docs/01` a `docs/06` são a fonte de verdade; em caso de conflito, `01` prevalece sobre `02`, que prevalece sobre
  `03` e `04`. Só se alteram por decisão explícita.
- Não se inventam regras de negócio. Onde a base de conhecimento é omissa ou ambígua, implementa-se o comportamento
  documentado, marcado "a validar" e registado em `docs/adr/0003-ambiguidades.md`.
- As decisões de arquitetura ficam em `docs/adr/`.

### Incerteza (docs/08)
- Os parâmetros de incerteza são demonstrativos; nunca se escrevem em código Java ou DRL, só no ficheiro de
  parâmetros (`parametros-incerteza.yml` e ficheiros FCL).
- A camada de incerteza nunca transforma RECUSAR em PERMITIR: só calcula dados derivados, recomenda nas zonas REVER
  ou torna o resultado mais cauteloso.

### Código
- Código, mensagens e documentação em português de Portugal, sem acentos nos identificadores Java/TS. Os termos
  operacionais ficam em inglês: Mainline, Outlet, BackPocket, Afterpay, PayPal, Venmo, Interac, bodywear, POS, SKU.
- Valores monetários em `BigDecimal`, datas em `LocalDate`/`LocalDateTime`, DTO como `record` com Bean Validation.
- `pericial-model` sem dependências de Spring/JPA; entidades JPA separadas dos factos Drools.
- Os controllers só usam DTO e nunca acedem ao modelo nem ao Drools (garantido por ArchUnit).
- As integrações externas (POS, BackPocket, Afterpay, PayPal/Venmo, Interac/VeriFone) ficam atrás de interfaces
  (portas), com adaptadores simulados para desenvolvimento e testes.
- Cada avaliação guarda a versão do kjar e o rasto das regras disparadas (auditoria).

### Regras DRL
- Cada regra usa o ID da base de conhecimento no nome (ex.: `rule "PT-003 Devolução verificada até 30 dias"`).
- Cada regra declara os metadados:
  - `@id`, `@modulo`, `@descricao` e `@condicoes`;
  - `@conclusoes`: as conclusões OUT que pode produzir (ex.: `"OUT-001=PERMITIR,OUT-002=REEMBOLSO"`), vazio se só
    regista uma ação (ADR 0006).
- Há um `agenda-group` por módulo (M0–M9, ONLINE) e as precedências fazem-se com `salience`.
- Todas as regras incluem `Decisao( terminal == false )`; as exceções estão no ADR 0004. EX-008 e PC-008 têm
  `auto-focus true`.

### Definição de concluído
- Cada regra tem pelo menos um teste unitário que referencia o ID da regra.
- Os 10 cenários de `docs/06-casos-teste.md` existem como testes de aceitação (JSON em
  `backend/pericial-rules/src/test/resources/cenarios/`), com os resultados esperados derivados de `02` e marcados
  "a validar" até confirmação da operação.
- Build e testes verdes, sem violações de ArchUnit, Checkstyle ou Spotless.

## Requisitos

- JDK 25 LTS ou superior (o código é compilado com `release 25`).
- Maven 3.9 ou superior.
- Node 24 LTS (frontend; o Angular 22 exige pelo menos 22.22.3) e Docker (ambiente local e testes de integração
  com Testcontainers).

## Comandos

```bash
mvn clean verify                       # build, testes, Spotless, Checkstyle, JaCoCo, ArchUnit
mvn spotless:apply                     # formatar o código Java
docker compose up --build              # PostgreSQL + API (perfil dev, :8080) + frontend (:8081)
```

Para correr a API fora do Docker: `docker compose up -d postgres`, `mvn install -DskipTests` e
`mvn -pl backend/pericial-api spring-boot:run -Dspring-boot.run.profiles=dev`.

## Frontend

```bash
cd frontend && npm ci
npm start                 # http://localhost:4200, com proxy de /api para localhost:8080
npm run start:en          # a versão inglesa
npm test                  # testes unitários (Vitest)
npx playwright test       # E2E: os 10 cenários e as explicações (arranca a API com docker compose se preciso)
npm run api:atualizar     # copia o OpenAPI exportado pelos testes da API e regenera src/app/api
npm run i18n:extrair      # extrai as mensagens (pt-PT); traduzir em src/locale/messages.en.xlf
npm run verificar         # formatação (Prettier) e traduções completas
```

## Integração contínua

`.github/workflows/ci.yml` corre em cada push e pull request:
- **backend:** `mvn verify` (testes, IT com Testcontainers, ArchUnit, Checkstyle, Spotless, JaCoCo) e a verificação de
  que `frontend/openapi/openapi.json` corresponde à API;
- **frontend:** formatação, cliente gerado sem diferenças, traduções completas, testes e build;
- **e2e:** `docker compose up --build --wait` e os testes Playwright contra a imagem nginx.

## API

- Swagger UI (dev): http://localhost:8080/swagger-ui.html; documento OpenAPI em `/v3/api-docs`, exportado
  pelos testes para `backend/pericial-api/target/openapi.json`.
- Autenticação por token JWT (`Authorization: Bearer ...`). Em dev, `GET /api/v1/dev/colaboradores` lista
  colaboradores de exemplo e `POST /api/v1/dev/tokens` emite um token para um deles. Em produção, os tokens vêm
  do fornecedor OIDC (ver `docs/adr/0008-api-e-seguranca.md`).
- O idioma das explicações segue o cabeçalho `Accept-Language` (pt-PT por omissão, ou en).

## Módulos

| Módulo | Papel |
|---|---|
| `backend/pericial-model` | Factos do domínio (POJO, sem Spring/JPA) |
| `backend/pericial-rules` | Regras DRL (kjar versionado) e cenários de aceitação |
| `backend/pericial-explanation` | Explicações das decisões |
| `backend/pericial-dto` | Contratos da API |
| `backend/pericial-persistence` | Histórico e auditoria (JPA + Flyway) |
| `backend/pericial-service` | Orquestração, motor de regras, integrações |
| `backend/pericial-api` | Aplicação Spring Boot (REST) |
| `frontend` | Angular |
