# Plano de Implementação: Persistência Unificada e Comparação Multi-Motor (Drools vs Prolog)

> **Alvo:** Agente Autónomo Integrado (Gemini 3.8 Flash High)  
> **Objetivo:** Eliminar 100% dos dados mockados/fabricados, persistir as inferências de ambos os motores (Drools e Prolog) em PostgreSQL e viabilizar a comparação direta de casos resolvidos por motores distintos no Dashboard.  
> **Revisão:** V2.0 — Incorpora todas as correções técnicas, mitigações de build e hardening da review do Claude Opus 4.6.

---

## 1. Contexto e Diagnóstico do Sistema

### 1.1 Estado Atual Identificado na Análise
1. **Frontend Mockado:**
   - [RecentCases.tsx](file:///c:/Users/santi/Desktop/meia-equipa3-challenge1-26_27/dashboard/src/components/home/RecentCases.tsx): A lista de "Últimos Casos Resolvidos" utiliza uma constante estática `mockCases` com 3 casos estáticos e uma tag com texto fixo `"Todos (24)"`.
   - [decisoes/page.tsx](file:///c:/Users/santi/Desktop/meia-equipa3-challenge1-26_27/dashboard/src/app/decisoes/page.tsx): O histórico geral de decisões utiliza a constante estática `initialDecisions`.
   - Nenhuma destas páginas consome APIs reais para listar o histórico.
2. **Motor Prolog ([prolog_engine](file:///c:/Users/santi/Desktop/meia-equipa3-challenge1-26_27/prolog_engine/README_ENTREGA.md)):**
   - 100% declarativo e autónomo em SWI-Prolog, sem ligação a base de dados relacional.
   - O [retail_prolog_service.py](file:///c:/Users/santi/Desktop/meia-equipa3-challenge1-26_27/backend_orchestrator/app/services/retail_prolog_service.py#L327) guarda as avaliações apenas num dicionário volátil em memória (`_evaluations_cache`) que se perde a cada reinício de contentor.
3. **Motor Drools ([drools-engine](file:///c:/Users/santi/Desktop/meia-equipa3-challenge1-26_27/drools-engine-levis-devolucoes-java)):**
   - Possui persistência própria em PostgreSQL (`levis-postgres`, base de dados `pericial`, tabelas `avaliacao`, `registo_regra`, `excecao_aprovada`), acedida exclusivamente pelo Spring Boot.
4. **Base de Dados PostgreSQL (`levis-postgres`):**
   - Está em execução no Docker (porta `5432:5432`), mas apenas o contentor `drools-engine` se encontra ligado a ela. O `orchestrator` não tem conexão configurada.

### 1.2 Decisão Estratégica de Arquitetura
* **Onde persistir?** No **`backend_orchestrator` (FastAPI)**.
  - O `prolog_engine` **não deve ser alterado com drivers SQL** (preserva a pureza declarativa exigida academicamente no PPROGIA).
  - O `backend_orchestrator` é a camada unificadora que já expõe as rotas `/api/v1/levis` e `/api/v1/retail`.
  - O orquestrador liga-se ao PostgreSQL existente (`levis-postgres`) e cria uma tabela unificada de histórico de inferências (`historico_inferencias`), registando cada avaliação com a etiqueta explícita do motor (`DROOLS` ou `PROLOG`) e o identificador do caso (`pedido_id`).
  - Desta forma, o mesmo caso (ex.: `"RF-8924"` ou `"CENARIO-01"`) pode ser executado por ambos os motores e persistido, permitindo compará-los lado a lado.

---

## 2. Visão Geral das Fases

```mermaid
graph TD
    Fase1[Fase 1: Infraestrutura Docker, Dependências & Conetividade DB] --> Fase2[Fase 2: Modelo de Dados, Engine Async & Lifespan]
    Fase2 --> Fase3[Fase 3: Repositório, Interceção das Avaliações & Endpoints]
    Fase3 --> Fase4[Fase 4: Semeadura Idempotente dos 10 Cenários Oficiais]
    Fase4 --> Fase5[Fase 5: Gateway Next.js BFF & Tipagem TypeScript]
    Fase5 --> Fase6[Fase 6: Eliminação dos Mocks no Frontend & UI de Comparação]
```

---

## 3. Especificação Detalhada das Fases

### Fase 1: Infraestrutura Docker, Dependências & Conetividade DB

**Objetivo:** Garantir que o ambiente Docker e Python possui todas as ferramentas necessárias para compilar e conectar o `backend_orchestrator` ao PostgreSQL de forma assíncrona e resiliente.

**Ficheiros a alterar:**
- [backend_orchestrator/Dockerfile](file:///c:/Users/santi/Desktop/meia-equipa3-challenge1-26_27/backend_orchestrator/Dockerfile)
- [backend_orchestrator/requirements.txt](file:///c:/Users/santi/Desktop/meia-equipa3-challenge1-26_27/backend_orchestrator/requirements.txt)
- [docker-compose.yml](file:///c:/Users/santi/Desktop/meia-equipa3-challenge1-26_27/docker-compose.yml)
- [backend_orchestrator/app/core/config.py](file:///c:/Users/santi/Desktop/meia-equipa3-challenge1-26_27/backend_orchestrator/app/core/config.py)
- [backend_orchestrator/.env](file:///c:/Users/santi/Desktop/meia-equipa3-challenge1-26_27/backend_orchestrator/.env)

**Ações Passo a Passo:**

1. **Atualizar `backend_orchestrator/Dockerfile`:**
   Adicionar os pacotes de sistema necessários (`gcc`, `libpq-dev`) antes de correr o `pip install`, evitando que a compilação de extensões C do `asyncpg` falhe na imagem `python:3.11-slim`:
   ```dockerfile
   # Instalar dependências de compilação do sistema operacional
   RUN apt-get update && apt-get install -y --no-install-recommends \
       gcc \
       libpq-dev \
       && rm -rf /var/lib/apt/lists/*
   ```

2. **Atualizar `backend_orchestrator/requirements.txt`:**
   Adicionar exclusivamente o stack assíncrono (sem o driver redundante `psycopg2-binary`):
   ```text
   sqlalchemy>=2.0.28,<2.1.0
   asyncpg>=0.29.0,<0.30.0
   ```

3. **Atualizar `docker-compose.yml`:**
   - Adicionar healthcheck explícito ao serviço `levis-postgres`:
     ```yaml
     levis-postgres:
       image: postgres:16-alpine
       container_name: levis-postgres
       restart: unless-stopped
       ports:
         - "5432:5432"
       environment:
         POSTGRES_DB: pericial
         POSTGRES_USER: pericial
         POSTGRES_PASSWORD: pericial
       healthcheck:
         test: ["CMD-SHELL", "pg_isready -U pericial -d pericial"]
         interval: 5s
         timeout: 5s
         retries: 5
       volumes:
         - levis_postgres_data:/var/lib/postgresql/data
       networks:
         - retail-network
     ```
   - No serviço `orchestrator`, configurar a variável `DATABASE_URL` e dependência com condição `service_healthy`:
     ```yaml
     orchestrator:
       # ...
       environment:
         - PORT=8000
         - PROLOG_ENGINE_URL=http://prolog-engine:8080
         - PROLOG_TIMEOUT_SECONDS=5.0
         - DROOLS_ENGINE_URL=http://drools-engine:8080
         - LEVIS_DROOLS_URL=http://drools-engine:8080
         - DATABASE_URL=postgresql+asyncpg://pericial:pericial@levis-postgres:5432/pericial
         - DEBUG=true
         - CORS_ORIGINS=["http://localhost:3000","http://localhost:5173","http://localhost:8000"]
         - INFERENCE_ENGINE_ENABLED=true
       depends_on:
         prolog-engine:
           condition: service_started
         drools-engine:
           condition: service_started
         levis-postgres:
           condition: service_healthy
     ```

4. **Atualizar `backend_orchestrator/app/core/config.py` e `.env`:**
   Adicionar o campo `DATABASE_URL` à classe `Settings`:
   ```python
   DATABASE_URL: str = "postgresql+asyncpg://pericial:pericial@localhost:5432/pericial"
   ```

**Comando de Validação da Fase 1:**
```bash
docker compose build orchestrator
```
*(Deve compilar sem qualquer erro de gcc/asyncpg).*

---

### Fase 2: Modelo de Dados, Engine Async & Lifespan

**Objetivo:** Criar o schema declarativo SQLAlchemy para a tabela `historico_inferencias`, implementar retry com backoff exponencial na inicialização e registar o ciclo de vida da base de dados no `main.py`.

**Ficheiros a criar:**
- `backend_orchestrator/app/db/__init__.py`
- `backend_orchestrator/app/db/session.py` (Engine, factory e dependency `get_db`)
- `backend_orchestrator/app/db/models.py` (Entidade `HistoricoInferencia`)
- `backend_orchestrator/app/db/init_db.py` (Criação resiliente de tabelas com backoff)

**Ficheiros a alterar:**
- [backend_orchestrator/app/main.py](file:///c:/Users/santi/Desktop/meia-equipa3-challenge1-26_27/backend_orchestrator/app/main.py)
- [backend_orchestrator/app/api/deps.py](file:///c:/Users/santi/Desktop/meia-equipa3-challenge1-26_27/backend_orchestrator/app/api/deps.py)

**Ações Passo a Passo:**

1. **Criar `backend_orchestrator/app/db/session.py`:**
   ```python
   from typing import AsyncGenerator
   from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
   from sqlalchemy.orm import declarative_base
   from app.core.config import settings

   Base = declarative_base()

   async_engine = create_async_engine(
       settings.DATABASE_URL,
       echo=settings.DEBUG,
       pool_size=10,
       max_overflow=20,
       pool_pre_ping=True,
   )

   async_session_factory = async_sessionmaker(
       bind=async_engine,
       class_=AsyncSession,
       expire_on_commit=False,
       autoflush=False,
   )

   async def get_db() -> AsyncGenerator[AsyncSession, None]:
       """FastAPI dependency injecting an asynchronous database session."""
       async with async_session_factory() as session:
           try:
               yield session
           finally:
               await session.close()
   ```

2. **Criar `backend_orchestrator/app/db/models.py`:**
   ```python
   import uuid
   from datetime import datetime, timezone
   from sqlalchemy import Column, String, Numeric, Integer, DateTime, Index
   from sqlalchemy.dialects.postgresql import UUID, JSONB
   from app.db.session import Base

   class HistoricoInferencia(Base):
       __tablename__ = "historico_inferencias"

       id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
       pedido_id = Column(String(64), nullable=False, index=True)
       motor = Column(String(20), nullable=False, index=True)  # 'DROOLS' ou 'PROLOG'
       motor_versao = Column(String(100), nullable=True)
       produto_nome = Column(String(200), nullable=False, default="Artigo")
       produto_ref = Column(String(64), nullable=True)
       valor_devolucao = Column(Numeric(12, 2), nullable=True, default=0.0)
       elegibilidade = Column(String(30), nullable=False)  # PERMITIR, RECUSAR, TROCA, REVER
       tipo_transacao = Column(String(30), nullable=True)
       meio_reembolso = Column(String(50), nullable=True)
       nivel_aprovacao = Column(String(50), nullable=True)
       regras_disparadas = Column(JSONB, nullable=False, default=list)
       input_pedido_json = Column(JSONB, nullable=False, default=dict)
       decisao_json = Column(JSONB, nullable=False, default=dict)
       duracao_ms = Column(Integer, nullable=False, default=0)
       executado_em = Column(
           DateTime(timezone=True),
           nullable=False,
           default=lambda: datetime.now(timezone.utc),
           index=True
       )

       __table_args__ = (
           Index("ix_historico_pedido_motor", "pedido_id", "motor"),
           Index("ix_historico_executado_em_desc", executado_em.desc()),
       )
   ```

3. **Criar `backend_orchestrator/app/db/init_db.py` (com Retry e Backoff):**
   ```python
   import asyncio
   import logging
   from sqlalchemy.exc import OperationalError
   from app.db.session import async_engine, Base
   # Importar modelos para registo nos metadados
   import app.db.models  # noqa: F401

   logger = logging.getLogger(__name__)

   async def init_db(max_retries: int = 5, delay: float = 2.0) -> None:
       """Initialize database tables with exponential backoff retry."""
       for attempt in range(1, max_retries + 1):
           try:
               logger.info(f"[DB] Initializing database schema (attempt {attempt}/{max_retries})...")
               async with async_engine.begin() as conn:
                   await conn.run_sync(Base.metadata.create_all)
               logger.info("[DB] Database tables successfully verified/created.")
               return
           except (OperationalError, ConnectionRefusedError, OSError) as exc:
               if attempt == max_retries:
                   logger.error(f"[DB] Failed to connect to database after {max_retries} attempts: {exc}")
                   raise
               sleep_time = delay * (2 ** (attempt - 1))
               logger.warning(f"[DB] Connection failed. Retrying in {sleep_time:.1f}s... ({exc})")
               await asyncio.sleep(sleep_time)
   ```

4. **Conectar ao Ciclo de Vida em `backend_orchestrator/app/main.py`:**
   - No `lifespan(app: FastAPI)`:
     ```python
     # Startup (após clientes HTTP):
     from app.db.init_db import init_db
     from app.db.session import async_engine
     await init_db()

     # Shutdown:
     await async_engine.dispose()
     ```
5. **Atualizar `backend_orchestrator/app/api/deps.py`:**
   Adicionar re-exportação da dependency `get_db`:
   ```python
   from app.db.session import get_db  # noqa: F401
   ```

**Comando de Validação da Fase 2:**
```bash
docker compose up -d levis-postgres orchestrator
docker compose logs orchestrator --tail=50
```
*(Deve exibir `[DB] Database tables successfully verified/created` nos logs do orchestrator).*

---

### Fase 3: Repositório, Interceção das Avaliações & Endpoints

**Objetivo:** Implementar o serviço de persistência unificada, intercetar todas as chamadas normais de avaliação para gravar em PostgreSQL, disponibilizar o endpoint de avaliação simultânea em paralelo (`/avaliar-ambos`) e endpoints de consulta e comparação de deliberações.

**Ficheiros a criar:**
- `backend_orchestrator/app/services/inferences_service.py`
- `backend_orchestrator/app/api/v1/endpoints/inferences.py`
- `backend_orchestrator/app/schemas/inference_record.py` (Pydantic schemas para listagem e comparação)

**Ficheiros a alterar:**
- [levis_service.py](file:///c:/Users/santi/Desktop/meia-equipa3-challenge1-26_27/backend_orchestrator/app/services/levis_service.py) e [retail_prolog_service.py](file:///c:/Users/santi/Desktop/meia-equipa3-challenge1-26_27/backend_orchestrator/app/services/retail_prolog_service.py) (Adicionar persistência pós-avaliação)
- [router.py](file:///c:/Users/santi/Desktop/meia-equipa3-challenge1-26_27/backend_orchestrator/app/api/v1/router.py) (Registar `/avaliacoes`)

**Especificação dos Endpoints REST:**

1. **`GET /api/v1/avaliacoes` (Listagem Paginada Dinâmica):**
   - Query params: `motor: Optional[str]`, `pedido_id: Optional[str]`, `elegibilidade: Optional[str]`, `pagina: int = 0`, `tamanho: int = 20`.
   - Retorna: `PaginaResponse[InferenciaListItem]`.
   - Adiciona o campo booleano `temOutroMotor: bool` se houver outra inferência do mesmo `pedido_id` com motor diferente.

2. **`GET /api/v1/avaliacoes/{id}` (Detalhe Individual da Inferência):**
   - Retorna o payload completo, incluindo regras disparadas e decisão canónica.

3. **`GET /api/v1/avaliacoes/comparacao/{pedido_id}` (Matriz Comparativa de Motores):**
   - Recupera os registos mais recentes de Drools e Prolog para o `pedido_id`.
   - Retorna:
     ```json
     {
       "pedidoId": "CENARIO-01",
       "consenso": true,
       "resumoConsenso": "Ambos os motores deliberaram APROVADO.",
       "razaoVelocidade": "Prolog foi 1.8x mais rápido que Drools",
       "instanciaDrools": { ... },
       "instanciaProlog": { ... },
       "divergencias": []
     }
     ```

4. **`POST /api/v1/avaliar-ambos` (Execução Paralela Resiliente):**
   - Recebe o pedido de avaliação.
   - Executa em simultâneo através de `asyncio.gather(*tasks, return_exceptions=True)`.
   - Se um dos motores falhar (timeout ou erro), persiste o motor que teve sucesso e devolve o erro parcial do outro sem provocar HTTP 500.

**Comando de Validação da Fase 3:**
```bash
curl -X GET "http://localhost:8000/api/v1/avaliacoes"
```
*(Deve retornar status 200 com lista vazia `{"conteudo": [], "totalElementos": 0, ...}`).*

---

### Fase 4: Semeadura Idempotente dos 10 Cenários Oficiais

**Objetivo:** Garantir que o sistema nunca arranca vazio após a remoção dos mocks, semeando de forma idempotente as avaliações reais dos 10 cenários oficiais da Levi's em ambos os motores.

**Ficheiros a criar:**
- `backend_orchestrator/app/db/seed.py`

**Ficheiros a alterar:**
- `backend_orchestrator/app/api/v1/endpoints/inferences.py` (Adicionar rota `POST /api/v1/avaliacoes/seed`)

**Ações Passo a Passo:**

1. **Implementar `seed_scenarios(force: bool = False)`:**
   - Obter os 10 cenários usando `levis_service.get_example_scenarios()` (que já carrega os ficheiros `cenario-*.json` em `drools-engine/.../cenarios/`).
   - Para cada cenário `sc` (com `sc.id` de 1 a 10 e `pedido_id = f"CENARIO-{sc.id:02d}"`):
     - **Verificação de Idempotência:** Verificar se já existem registos para `(pedido_id, "DROOLS")` e `(pedido_id, "PROLOG")`. Se já existirem e `not force`, salta.
     - **Execução Drools:** Submete `sc.pedido` a `levis_service.evaluate()` e persiste com `motor="DROOLS"`.
     - **Execução Prolog:** Submete `sc` a `retail_prolog_service.evaluate_return()` e persiste com `motor="PROLOG"`.
   - Total: 20 inferências reais persistidas no PostgreSQL (10 casos x 2 motores).

2. **Integrar no Startup do Orquestrador:**
   - Em `main.py`, chamar `await seed_scenarios(force=False)` durante a inicialização (executado apenas se a tabela estiver vazia).

**Comando de Validação da Fase 4:**
```bash
curl -X POST "http://localhost:8000/api/v1/avaliacoes/seed"
curl -X GET "http://localhost:8000/api/v1/avaliacoes?tamanho=5"
```
*(Deve devolver registos reais persistidos com `motor: "DROOLS"` e `motor: "PROLOG"`).*

---

### Fase 5: Gateway Next.js BFF & Tipagem TypeScript

**Objetivo:** Criar o proxy Next.js BFF para as novas rotas de avaliações e definir os contratos de dados em TypeScript, assegurando compatibilidade tipada com o frontend.

**Ficheiros a alterar/criar:**
- [dashboard/src/config/gateway.ts](file:///c:/Users/santi/Desktop/meia-equipa3-challenge1-26_27/dashboard/src/config/gateway.ts)
- `dashboard/src/app/api/avaliacoes/[...path]/route.ts` (Proxy seguro usando `gatewayFetch`)
- `dashboard/src/types/inferences.ts` (Contratos canónicos TypeScript)

**Especificação da Tipagem TypeScript (`dashboard/src/types/inferences.ts`):**
```typescript
export type MotorTipo = "DROOLS" | "PROLOG";
export type ElegibilidadeTipo = "PERMITIR" | "RECUSAR" | "TROCA" | "REVER";

export interface RegraItemDto {
  codigo: string;
  nome?: string;
  modulo?: string;
  mensagem?: string;
  resultado?: string;
}

export interface InferenciaItem {
  id: string;
  pedidoId: string;
  motor: MotorTipo;
  motorVersao: string;
  produtoNome: string;
  produtoRef: string;
  valorDevolucao: number;
  elegibilidade: ElegibilidadeTipo;
  tipoTransacao: string;
  meioReembolso?: string;
  nivelAprovacao?: string;
  executadoEm: string;
  duracaoMs: number;
  regrasDisparadas: RegraItemDto[];
  temOutroMotor?: boolean;
}

export interface ComparacaoMotoresResponse {
  pedidoId: string;
  consenso: boolean;
  resumoConsenso: string;
  razaoVelocidade?: string;
  instanciaDrools?: InferenciaItem;
  instanciaProlog?: InferenciaItem;
  divergencias: string[];
}
```

**Proxy em `dashboard/src/app/api/avaliacoes/[...path]/route.ts`:**
Implementar o handler `GET` e `POST` encaminhando para `${GATEWAY_URL}/api/v1/avaliacoes/${path}` através da função `gatewayFetch` existente em `dashboard/src/server/gateway.ts`.

---

### Fase 6: Eliminação dos Mocks no Frontend & UI de Comparação

**Objetivo:** Limpar definitivamente todos os dados falsos/estáticos da Home e da página de Decisões, ligar aos endpoints reais e disponibilizar a interface de comparação lado a lado.

**Ficheiros a alterar/criar:**
- [RecentCases.tsx](file:///c:/Users/santi/Desktop/meia-equipa3-challenge1-26_27/dashboard/src/components/home/RecentCases.tsx)
- [decisoes/page.tsx](file:///c:/Users/santi/Desktop/meia-equipa3-challenge1-26_27/dashboard/src/app/decisoes/page.tsx)
- `dashboard/src/components/home/CaseComparisonModal.tsx` (Componente Modal de Comparação)

**Ações Passo a Passo:**

1. **Refatorar [RecentCases.tsx](file:///c:/Users/santi/Desktop/meia-equipa3-challenge1-26_27/dashboard/src/components/home/RecentCases.tsx):**
   - **Remover** integralmente a constante `mockCases` (L23-L77).
   - **Remover** o texto fixo `"Todos (24)"` (L125), substituindo por contagem dinâmica baseada nos dados reais retornados.
   - Adicionar estado de fetching (`useEffect` para `/api/avaliacoes`):
     - *Loading State:* Shimmer skeleton.
     - *Empty State:* Mensagem amigável com botão de semeadura/novo atendimento.
     - *Error State:* ErrorBanner com retry.
   - Adicionar Badge do Motor em cada linha:
     - `Drools`: Badge com fundo índigo/azul (`bg-indigo-50 text-indigo-700 border-indigo-200`).
     - `Prolog`: Badge com fundo esmeralda (`bg-emerald-50 text-emerald-700 border-emerald-200`).
   - Se `item.temOutroMotor === true`, exibir botão: `"Comparar Motores"`.

2. **Criar `dashboard/src/components/home/CaseComparisonModal.tsx`:**
   - Modal com visual minimalista de alta legibilidade, com duas colunas lado a lado:
     - **Coluna Esquerda:** Instância Drools (resultado, regras DRL, latência ms).
     - **Coluna Direita:** Instância Prolog (resultado, deduções lógicas, latência ms).
     - **Cabeçalho:** Banner de Consenso (Verde se concordarem, Âmbar com aviso de divergência se discordarem).

3. **Refatorar [decisoes/page.tsx](file:///c:/Users/santi/Desktop/meia-equipa3-challenge1-26_27/dashboard/src/app/decisoes/page.tsx):**
   - **Remover** a constante `initialDecisions` (L24-L95).
   - Consumir os dados reais da API `/api/avaliacoes`, suportando pesquisa e filtros reais por motor (`TODOS`, `DROOLS`, `PROLOG`) e por resultado (`PERMITIR`, `RECUSAR`, etc.).

---

## 4. Instruções de Execução para o Agente Gemini 3.8 Flash High

> [!IMPORTANT]
> **Checklist Operacional de Segurança:**
> 1. Executar **uma fase de cada vez**. Nunca avançar para a fase seguinte sem executar o comando de validação respetivo.
> 2. **Não tocar em `prolog_engine`:** O SWI-Prolog mantém-se 100% puro e sem dependências relacionais.
> 3. Na Fase 5/6, antes de eliminar os arrays mock, assegurar que a base de dados tem dados semeados da Fase 4 para não quebrar os testes visuais.
> 4. Validar o arranque dos contentores via `docker compose ps` e inspecionar a interface no browser (`http://localhost:3000`).

---

## 5. Estado de Execução das Fases

- [x] **Fase 1: Infraestrutura Docker, Dependências & Conetividade DB** — Concluída.
- [x] **Fase 2: Modelo de Dados, Engine Async & Lifespan** — Concluída.
- [x] **Fase 3: Repositório, Interceção das Avaliações & Endpoints** — Concluída.
- [x] **Fase 4: Semeadura Idempotente dos 10 Cenários Oficiais** — Concluída.
- [x] **Fase 5: Gateway Next.js BFF & Tipagem TypeScript** — Concluída.
- [x] **Fase 6: Eliminação dos Mocks no Frontend & UI de Comparação** — Concluída com sucesso e validada end-to-end via Browser Subagent e Next.js production build (`npm run build`).
