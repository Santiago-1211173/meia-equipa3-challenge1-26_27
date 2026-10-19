#!/usr/bin/env bash
# ==============================================================================
# MEIA 2026/2027 · ENGCIA · Desafio 1 (Equipa 3)
# Script de Arranque da API Pericial Drools Levi's (:8082)
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "========================================================================"
echo "  MEIA 2026/2027 · ENGCIA · Desafio 1 (Equipa 3)"
echo "  Sistema Pericial de Devoluções e Trocas Levi's (Drools 8/9 + Spring Boot)"
echo "========================================================================"

echo "A compilar e empacotar a aplicação pericial (Maven package)..."
mvn package -DskipTests -q

JAR=$(ls backend/pericial-api/target/pericial-api-*.jar 2>/dev/null | grep -v 'original-' | head -n 1)

if [ -z "$JAR" ] || [ ! -f "$JAR" ]; then
    echo "ERRO: Ficheiro JAR executável não encontrado em backend/pericial-api/target/"
    exit 1
fi

echo "Iniciando a API Drools na porta 8082 (perfil dev)..."
echo "  - Swagger UI:   http://localhost:8082/swagger-ui.html"
echo "  - OpenAPI JSON: http://localhost:8082/v3/api-docs"
echo "  - Healthcheck:  http://localhost:8082/actuator/health"
echo "========================================================================"
exec java -jar "$JAR" --spring.profiles.active=dev --server.port=8082 "$@"
