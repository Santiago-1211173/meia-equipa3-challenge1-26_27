#!/bin/bash
set -e

echo "🛑 A parar serviços existentes..."

# Terminar instâncias do motor Drools (Levi's e legadas)
pkill -f "pericial-api" 2>/dev/null || true
pkill -f "drools-engine-.*\.jar" 2>/dev/null || true

# Terminar motor Prolog
pkill -f "swipl src/main.pl" 2>/dev/null || true

# Terminar Backend Orchestrator (FastAPI / Uvicorn)
pkill -f "uvicorn app.main:app" 2>/dev/null || true

# Terminar Dashboard Next.js
pkill -f "next-server" 2>/dev/null || true
pkill -f "next dev" 2>/dev/null || true
pkill -f "next start" 2>/dev/null || true

# Garantir desocupação das portas aplicacionais
fuser -k 8080/tcp 2>/dev/null || true
fuser -k 8082/tcp 2>/dev/null || true
fuser -k 8000/tcp 2>/dev/null || true
fuser -k 3000/tcp 2>/dev/null || true

sleep 2
echo "✅ Todos os microserviços e dashboard foram terminados."
echo "ℹ️  Base de dados PostgreSQL mantida em execução na porta 5432."
