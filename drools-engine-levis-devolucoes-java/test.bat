@echo off
rem ==============================================================================
rem MEIA 2026/2027 · ENGCIA · Desafio 1 (Equipa 3)
rem Script de Teste Automatizado do Motor Drools Levi's (Java 21) para Windows
rem ==============================================================================
cd /d "%~dp0"
echo ========================================================================
echo   MEIA 2026/2027 · ENGCIA · Desafio 1 (Equipa 3)
echo   Verificacao Completa do Motor Drools Levi's (Java 21)
echo ========================================================================
echo A executar compilacao e verificacao de testes...
call mvn clean verify -DskipITs=false %*
