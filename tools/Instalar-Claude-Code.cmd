@echo off
REM ===================================================================
REM  Instalar Claude Code - lanzador de doble clic
REM  Ejecuta el script de PowerShell saltando la politica de ejecucion
REM  solo para este proceso (no cambia nada permanente del sistema).
REM ===================================================================
setlocal
echo.
echo   Instalando Claude Code para PowerShell...
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install-claude-code.ps1" %*
echo.
echo   Pulsa una tecla para cerrar esta ventana.
pause >nul
endlocal
