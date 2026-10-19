#!/usr/bin/env bash
# ==============================================================================
# MEIA 2026/2027 · ENGCIA · Desafio 1 (Equipa 3)
# Script de Teste Automatizado do Motor Drools Levi's (Java 21)
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "========================================================================"
echo "  MEIA 2026/2027 · ENGCIA · Desafio 1 (Equipa 3)"
echo "  Verificação Completa do Motor Drools Levi's (Java 21)"
echo "========================================================================"

echo "A executar compilação e verificação de testes (Unitários + Integração)..."
mvn clean verify -DskipITs=false "$@"

echo "------------------------------------------------------------------------"
echo "Testes e verificações concluídos com sucesso!"
