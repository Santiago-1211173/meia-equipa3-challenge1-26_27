@echo off
rem Inicia o sistema pericial (SWI-Prolog) e abre a interface no browser.
rem Duplo clique neste ficheiro. Fechar esta janela para o servidor.
cd /d "%~dp0"
title Sistema pericial Levi's (SWI-Prolog)

set "SWIPL=swipl"
where swipl >nul 2>nul
if errorlevel 1 set "SWIPL=C:\Program Files\swipl\bin\swipl.exe"
if not exist "%SWIPL%" if not "%SWIPL%"=="swipl" (
    echo Nao encontrei o SWI-Prolog. Instale-o em https://www.swi-prolog.org/download/stable
    pause
    exit /b 1
)

if "%PORT%"=="" set "PORT=8090"
"%SWIPL%" main.pl web
pause
