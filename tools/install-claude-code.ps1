#Requires -Version 5.1
<#
.SYNOPSIS
    Instalador de Claude Code para Windows / PowerShell (portátil MSI).

.DESCRIPTION
    Deja el comando `claude` listo para usar desde tu terminal PowerShell.

    Qué hace, en orden:
      1. Comprueba si `claude` ya está instalado.
      2. Intenta el instalador nativo oficial de Anthropic (recomendado).
      3. Si falla, instala Node.js (vía winget si está disponible) e instala
         Claude Code con npm como plan B.
      4. Añade la carpeta de binarios al PATH del usuario.
      5. Verifica la instalación y te dice el siguiente paso.

.NOTES
    No necesita permisos de administrador: instala solo para tu usuario.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\install-claude-code.ps1
#>

[CmdletBinding()]
param(
    # Fuerza el método de instalación: 'auto' (por defecto), 'native' o 'npm'.
    [ValidateSet('auto', 'native', 'npm')]
    [string]$Method = 'auto'
)

$ErrorActionPreference = 'Stop'

# ----------------------------------------------------------------------------
# Utilidades de salida (con color, legibles en PowerShell)
# ----------------------------------------------------------------------------
function Write-Step  { param([string]$m) Write-Host "==> $m" -ForegroundColor Cyan }
function Write-Ok    { param([string]$m) Write-Host "[OK]  $m" -ForegroundColor Green }
function Write-Warn2 { param([string]$m) Write-Host "[!]   $m" -ForegroundColor Yellow }
function Write-Err   { param([string]$m) Write-Host "[X]   $m" -ForegroundColor Red }

function Test-Command {
    param([string]$Name)
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function Add-ToUserPath {
    param([string]$Dir)
    if (-not (Test-Path $Dir)) { return }
    $current = [Environment]::GetEnvironmentVariable('Path', 'User')
    $parts = @()
    if ($current) { $parts = $current -split ';' | Where-Object { $_ -ne '' } }
    if ($parts -notcontains $Dir) {
        $newPath = (@($parts + $Dir) -join ';')
        [Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
        Write-Ok "Añadido al PATH del usuario: $Dir"
    }
    # También lo dejamos disponible en la sesión actual
    if (($env:Path -split ';') -notcontains $Dir) {
        $env:Path = "$env:Path;$Dir"
    }
}

# ----------------------------------------------------------------------------
# Banner
# ----------------------------------------------------------------------------
Write-Host ""
Write-Host " Claude Code - Instalador para Windows / PowerShell" -ForegroundColor Magenta
Write-Host " (portátil MSI - El Cocedero de la Playa)" -ForegroundColor DarkGray
Write-Host " ---------------------------------------------------" -ForegroundColor DarkGray
Write-Host ""

# ----------------------------------------------------------------------------
# 0) ¿Ya está instalado?
# ----------------------------------------------------------------------------
if (Test-Command 'claude') {
    Write-Ok "Claude Code ya está instalado."
    try { & claude --version } catch { }
    Write-Host ""
    Write-Host "Para arrancarlo, escribe:  " -NoNewline
    Write-Host "claude" -ForegroundColor Green
    return
}

# ----------------------------------------------------------------------------
# 1) Método nativo (instalador oficial de Anthropic)
# ----------------------------------------------------------------------------
function Install-Native {
    Write-Step "Instalando Claude Code con el instalador oficial de Anthropic..."
    try {
        # El instalador oficial se descarga y ejecuta desde claude.ai
        $installer = Invoke-RestMethod -Uri 'https://claude.ai/install.ps1' -UseBasicParsing
        Invoke-Expression $installer
    }
    catch {
        Write-Warn2 "El instalador nativo no se pudo completar: $($_.Exception.Message)"
        return $false
    }

    # El instalador nativo suele dejar el binario aquí:
    $candidateDirs = @(
        (Join-Path $env:USERPROFILE '.local\bin'),
        (Join-Path $env:LOCALAPPDATA 'Programs\claude'),
        (Join-Path $env:USERPROFILE '.claude\bin')
    )
    foreach ($d in $candidateDirs) { Add-ToUserPath $d }

    return (Test-Command 'claude') -or ($candidateDirs | Where-Object { Test-Path (Join-Path $_ 'claude.exe') })
}

# ----------------------------------------------------------------------------
# 2) Método npm (plan B): asegura Node.js y luego npm i -g
# ----------------------------------------------------------------------------
function Ensure-Node {
    if (Test-Command 'node') {
        $v = (& node --version).TrimStart('v')
        Write-Ok "Node.js detectado: v$v"
        $major = [int]($v.Split('.')[0])
        if ($major -lt 18) {
            Write-Warn2 "Tu Node.js es antiguo (v$v). Claude Code recomienda v18 o superior."
        }
        return $true
    }

    Write-Step "Node.js no está instalado. Intentando instalarlo..."

    if (Test-Command 'winget') {
        Write-Step "Instalando Node.js LTS con winget..."
        try {
            winget install --id OpenJS.NodeJS.LTS -e --source winget `
                --accept-package-agreements --accept-source-agreements
        } catch {
            Write-Warn2 "winget falló: $($_.Exception.Message)"
        }
        # Refrescar PATH de la sesión para ver node/npm recién instalados
        $machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
        $userPath    = [Environment]::GetEnvironmentVariable('Path', 'User')
        $env:Path    = @($machinePath, $userPath) -join ';'
    }
    elseif (Test-Command 'choco') {
        Write-Step "Instalando Node.js LTS con Chocolatey..."
        try { choco install nodejs-lts -y } catch { Write-Warn2 "choco falló: $($_.Exception.Message)" }
    }

    if (Test-Command 'node') {
        Write-Ok "Node.js instalado: $(& node --version)"
        return $true
    }

    Write-Err "No se pudo instalar Node.js automáticamente."
    Write-Host "   Descárgalo manualmente (versión LTS) desde: https://nodejs.org/es" -ForegroundColor Yellow
    Write-Host "   Luego vuelve a ejecutar este script." -ForegroundColor Yellow
    return $false
}

function Install-Npm {
    if (-not (Ensure-Node)) { return $false }

    Write-Step "Instalando Claude Code con npm (npm i -g @anthropic-ai/claude-code)..."
    try {
        & npm install -g '@anthropic-ai/claude-code'
    } catch {
        Write-Err "npm install falló: $($_.Exception.Message)"
        return $false
    }

    # Añadir la carpeta global de npm al PATH por si acaso
    try {
        $npmPrefix = (& npm config get prefix).Trim()
        if ($npmPrefix) { Add-ToUserPath $npmPrefix }
    } catch { }

    return (Test-Command 'claude')
}

# ----------------------------------------------------------------------------
# Ejecutar según el método elegido
# ----------------------------------------------------------------------------
$success = $false

switch ($Method) {
    'native' { $success = [bool](Install-Native) }
    'npm'    { $success = [bool](Install-Npm) }
    default  {
        # auto: nativo primero, npm como respaldo
        $success = [bool](Install-Native)
        if (-not $success) {
            Write-Warn2 "Probando el método alternativo (npm)..."
            $success = [bool](Install-Npm)
        }
    }
}

# ----------------------------------------------------------------------------
# Verificación final
# ----------------------------------------------------------------------------
Write-Host ""
if ($success -or (Test-Command 'claude')) {
    Write-Ok "Claude Code se instaló correctamente."
    try { & claude --version } catch { }
    Write-Host ""
    Write-Host " SIGUIENTE PASO" -ForegroundColor Magenta
    Write-Host " --------------" -ForegroundColor DarkGray
    Write-Host " 1) Cierra y vuelve a abrir PowerShell (para recargar el PATH)." -ForegroundColor White
    Write-Host " 2) Escribe:  " -NoNewline -ForegroundColor White
    Write-Host "claude" -ForegroundColor Green
    Write-Host " 3) La primera vez te pedirá iniciar sesión en tu cuenta." -ForegroundColor White
    Write-Host ""
}
else {
    Write-Err "No se pudo completar la instalación automáticamente."
    Write-Host ""
    Write-Host " Instalación manual (copia y pega en PowerShell):" -ForegroundColor Yellow
    Write-Host "   irm https://claude.ai/install.ps1 | iex" -ForegroundColor White
    Write-Host " o, con Node.js instalado:" -ForegroundColor Yellow
    Write-Host "   npm install -g @anthropic-ai/claude-code" -ForegroundColor White
    Write-Host ""
    exit 1
}
