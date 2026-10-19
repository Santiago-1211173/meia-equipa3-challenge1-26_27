@echo off
rem ==============================================================================
rem MEIA 2026/2027 · ENGCIA · Desafio 1 (Equipa 3)
rem Script de Arranque da API Pericial Drools Levi's (:8082) para Windows
rem ==============================================================================
cd /d "%~dp0"
echo ========================================================================
echo   MEIA 2026/2027 · ENGCIA · Desafio 1 (Equipa 3)
echo   Sistema Pericial de Devolucoes e Trocas Levi's (Drools 8/9 + Spring Boot)
echo ========================================================================
echo A compilar e empacotar a aplicacao pericial (Maven package)...
call mvn package -DskipTests -q
if %ERRORLEVEL% NEQ 0 (
    echo ERRO na compilacao Maven.
    exit /b %ERRORLEVEL%
)

for /f "delims=" %%F in ('dir /b /s backend\pericial-api\target\pericial-api-*.jar ^| findstr /v "original-"') do (
    set "JAR_FILE=%%F"
    goto found_jar
)

:found_jar
if not defined JAR_FILE (
    echo ERRO: Ficheiro JAR executavel nao encontrado.
    exit /b 1
)

echo Iniciando a API Drools na porta 8082 (perfil dev)...
echo   - Swagger UI:   http://localhost:8082/swagger-ui.html
echo   - Healthcheck:  http://localhost:8082/actuator/health
java -jar "%JAR_FILE%" --spring.profiles.active=dev --server.port=8082 %*
