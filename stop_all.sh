#!/bin/bash
set -e

echo "🛑 A parar serviços existentes..."
pkill -f "swipl src/main.pl" 2>/dev/null || true
pkill -f "drools-engine-.*\.jar" 2>/dev/null || true
pkill -f "uvicorn app.main:app" 2>/dev/null || true
pkill -f "next-server" 2>/dev/null || true
pkill -f "next dev" 2>/dev/null || true
pkill -f "next start" 2>/dev/null || true

sleep 2
echo "✅ Todos os microserviços e dashboard foram terminados."
