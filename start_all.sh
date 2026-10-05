#!/bin/bash
set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p "$PROJECT_ROOT/logs"

echo "=========================================="
echo "🚀 Reiniciando Stack SmartCloth AI"
echo "=========================================="

# 1. Parar serviços antigos
"$PROJECT_ROOT/stop_all.sh"

# 2. Recompilar Drools Engine (Java)
echo "📦 [1/4] Compilando Drools Engine (Java Maven)..."
mvn -f "$PROJECT_ROOT/drools_engine/pom.xml" package -DskipTests -q

# 3. Compilar Dashboard (Next.js Produção)
echo "📦 [2/4] Compilando Dashboard Next.js (Build de Produção)..."
(cd "$PROJECT_ROOT/dashboard" && npm run build)

# 4. Iniciar Microserviços
echo "⚡ [3/4] A iniciar microserviços..."

# Prolog
cd "$PROJECT_ROOT/prolog_engine"
nohup swipl src/main.pl > "$PROJECT_ROOT/logs/prolog.log" 2>&1 &
echo "   -> Prolog Engine iniciado (:8080)"

# Drools
cd "$PROJECT_ROOT/drools_engine"
nohup java -jar target/drools-engine-1.0.0-SNAPSHOT.jar --server.port=8082 > "$PROJECT_ROOT/logs/drools.log" 2>&1 &
echo "   -> Drools Engine iniciado (:8082)"

# Backend Orchestrator
cd "$PROJECT_ROOT/backend_orchestrator"
nohup ./venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000 > "$PROJECT_ROOT/logs/orchestrator.log" 2>&1 &
echo "   -> Backend Orchestrator iniciado (:8000)"

# Dashboard (Produção)
cd "$PROJECT_ROOT/dashboard"
nohup npm run start -- -p 3000 -H 0.0.0.0 > "$PROJECT_ROOT/logs/dashboard.log" 2>&1 &
echo "   -> Dashboard Produção iniciado (:3000)"

# 5. Validação de Saúde
echo "⏳ [4/4] A aguardar arranque dos serviços (8s)..."
sleep 8

echo "🔍 Verificando Health Check..."
if curl -sf http://127.0.0.1:3000/api/backend/health > /dev/null; then
  echo "✅ Tudo operacional!"
  echo "👉 Local:    http://localhost:3000"
  echo "👉 Público:  https://challenge1.smbitsolutions.pt"
  echo "📁 Logs disponíveis na pasta: logs/"
else
  echo "⚠️ Serviços iniciados, mas a API ainda está a inicializar. Consulta logs/ para detalhes."
fi
