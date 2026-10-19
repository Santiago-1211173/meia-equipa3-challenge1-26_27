#!/bin/bash
set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p "$PROJECT_ROOT/logs"

echo "=========================================="
echo "🚀 Reiniciando Stack SmartCloth AI & Levi's"
echo "=========================================="

# 1. Parar serviços antigos
"$PROJECT_ROOT/stop_all.sh"

# 2. Verificar base de dados PostgreSQL (:5432)
echo "🐘 [1/5] A verificar base de dados PostgreSQL (:5432)..."
if ! pg_isready -h localhost -p 5432 -U pericial -d pericial >/dev/null 2>&1; then
  if docker inspect levis-postgres >/dev/null 2>&1; then
    echo "   -> A iniciar contentor Docker levis-postgres..."
    docker start levis-postgres >/dev/null 2>&1 || true
  elif which systemctl >/dev/null 2>&1; then
    echo "   -> A iniciar serviço PostgreSQL local..."
    systemctl start postgresql 2>/dev/null || true
  fi
fi

PG_OK=0
for i in {1..15}; do
  if pg_isready -h localhost -p 5432 -U pericial -d pericial >/dev/null 2>&1; then
    PG_OK=1
    break
  fi
  sleep 1
done

if [ "$PG_OK" -eq 1 ]; then
  echo "   -> PostgreSQL operacional (:5432)"
else
  echo "   ⚠️ Aviso: PostgreSQL não respondeu a pg_isready dentro do tempo limite."
fi

# 3. Recompilar Drools Levi's Engine (Java Maven)
echo "📦 [2/5] Compilando Drools Levi's Engine (Java Maven)..."
mvn -f "$PROJECT_ROOT/drools-engine-levis-devolucoes-java/pom.xml" package -DskipTests -q

PERICIAL_JAR=$(ls "$PROJECT_ROOT/drools-engine-levis-devolucoes-java/backend/pericial-api/target/pericial-api-"*.jar 2>/dev/null | head -n 1)
if [ -z "$PERICIAL_JAR" ]; then
  echo "❌ Erro: JAR do pericial-api não encontrado em target/."
  exit 1
fi

# 4. Compilar Dashboard (Next.js Produção)
echo "📦 [3/5] Compilando Dashboard Next.js (Build de Produção)..."
(cd "$PROJECT_ROOT/dashboard" && npm run build)

# 5. Iniciar Microserviços
echo "⚡ [4/5] A iniciar microserviços..."

# Prolog Engine
cd "$PROJECT_ROOT/prolog_engine"
nohup swipl src/main.pl > "$PROJECT_ROOT/logs/prolog.log" 2>&1 &
echo "   -> Prolog Engine iniciado (:8080)"

# Drools Levi's Engine
nohup java -jar "$PERICIAL_JAR" \
  --spring.profiles.active=dev --server.port=8082 > "$PROJECT_ROOT/logs/drools_levis.log" 2>&1 &
echo "   -> Drools Levi's Engine iniciado (:8082)"

# Backend Orchestrator (FastAPI)
cd "$PROJECT_ROOT/backend_orchestrator"
nohup ./venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000 > "$PROJECT_ROOT/logs/orchestrator.log" 2>&1 &
echo "   -> Backend Orchestrator iniciado (:8000)"

# Dashboard (Produção)
cd "$PROJECT_ROOT/dashboard"
nohup npm run start -- -p 3000 -H 0.0.0.0 > "$PROJECT_ROOT/logs/dashboard.log" 2>&1 &
echo "   -> Dashboard Produção iniciado (:3000)"

# 6. Validação de Saúde
echo "⏳ [5/5] A aguardar arranque e estabilização dos serviços..."
ALL_READY=0
for i in {1..35}; do
  if curl -sf http://127.0.0.1:3000/api/health > /dev/null 2>&1 && \
     curl -sf http://127.0.0.1:8082/actuator/health > /dev/null 2>&1 && \
     curl -sf http://127.0.0.1:8000/api/v1/levis/health > /dev/null 2>&1; then
    ALL_READY=1
    break
  fi
  sleep 1
done

echo ""
echo "🔍 Diagnóstico dos Componentes:"
if curl -sf -X POST http://127.0.0.1:8080/evaluate -H "Content-Type: application/json" -d '{"scenario":"health_check","value":42}' >/dev/null 2>&1; then
  echo "   [OK] Prolog Engine (:8080)"
else
  echo "   [FAIL] Prolog Engine (:8080)"
fi

if curl -sf http://127.0.0.1:8082/actuator/health >/dev/null 2>&1; then
  echo "   [OK] Drools Levi's Engine (:8082)"
else
  echo "   [FAIL] Drools Levi's Engine (:8082)"
fi

if curl -sf http://127.0.0.1:8000/health >/dev/null 2>&1; then
  echo "   [OK] Backend Orchestrator FastAPI (:8000)"
else
  echo "   [FAIL] Backend Orchestrator FastAPI (:8000)"
fi

if curl -sf http://127.0.0.1:3000/api/health >/dev/null 2>&1; then
  echo "   [OK] Dashboard Next.js (:3000)"
else
  echo "   [FAIL] Dashboard Next.js (:3000)"
fi

echo ""
if [ "$ALL_READY" -eq 1 ]; then
  echo "✅ Tudo operacional!"
  echo "👉 Local:    http://localhost:3000"
  echo "👉 Público:  https://challenge1.smbitsolutions.pt"
  echo "📁 Logs disponíveis na pasta: logs/"
else
  echo "⚠️ Serviços iniciados, mas alguns componentes ainda estão a inicializar. Consulta logs/ para detalhes."
fi
