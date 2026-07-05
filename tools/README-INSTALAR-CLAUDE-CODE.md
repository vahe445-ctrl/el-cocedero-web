# Instalar Claude Code en tu portátil MSI (Windows + PowerShell)

Este instalador deja el comando **`claude`** listo para arrancar desde tu
terminal PowerShell. No necesita permisos de administrador (instala solo para
tu usuario).

## Archivos

| Archivo | Para qué sirve |
|---|---|
| `install-claude-code.ps1` | El instalador (script de PowerShell). |
| `Instalar-Claude-Code.cmd` | Lanzador de **doble clic** (llama al `.ps1` automáticamente). |

---

## Opción A — La más fácil (doble clic)

1. Descarga los dos archivos (`install-claude-code.ps1` y `Instalar-Claude-Code.cmd`)
   en la **misma carpeta** (por ejemplo, tu Escritorio).
2. Haz **doble clic** en `Instalar-Claude-Code.cmd`.
3. Espera a que termine y sigue las instrucciones que aparecen en pantalla.

---

## Opción B — Desde PowerShell (a mano)

Abre PowerShell, ve a la carpeta donde descargaste el script y ejecuta:

```powershell
powershell -ExecutionPolicy Bypass -File .\install-claude-code.ps1
```

### Instalación directa sin descargar nada (una sola línea)

Si prefieres el instalador oficial de Anthropic sin descargar este repo:

```powershell
irm https://claude.ai/install.ps1 | iex
```

---

## Cómo arrancar Claude Code después de instalar

1. **Cierra y vuelve a abrir** PowerShell (para que se recargue el `PATH`).
2. Escribe:

   ```powershell
   claude
   ```

3. La primera vez te pedirá **iniciar sesión** con tu cuenta.

---

## ¿Qué hace el instalador por dentro?

1. Comprueba si `claude` ya está instalado (y no hace nada si ya lo está).
2. Prueba el **instalador nativo oficial** de Anthropic (recomendado).
3. Si eso falla, instala **Node.js** (con `winget` o Chocolatey si están
   disponibles) y luego Claude Code con `npm install -g @anthropic-ai/claude-code`.
4. Añade la carpeta del binario a tu `PATH` de usuario.
5. Verifica que `claude` responde y te indica el siguiente paso.

### Forzar un método concreto

```powershell
# Solo el instalador nativo:
powershell -ExecutionPolicy Bypass -File .\install-claude-code.ps1 -Method native

# Solo vía npm (Node.js):
powershell -ExecutionPolicy Bypass -File .\install-claude-code.ps1 -Method npm
```

---

## Requisito de Windows: `bash` (Git for Windows)

En Windows, Claude Code necesita **bash**, que viene con **Git for Windows**.
Si al instalar ves este error:

```
Claude Code on Windows requires either Git for Windows (for bash) or PowerShell.
```

instala Git for Windows y vuelve a intentarlo:

```powershell
winget install --id Git.Git -e --source winget --accept-package-agreements --accept-source-agreements
```

> El instalador `install-claude-code.ps1` de este repo **ya lo instala solo**
> automáticamente antes de instalar Claude Code, así que con la Opción A o B no
> tienes que hacer nada más.

---

## Problemas frecuentes

- **"No se puede ejecutar scripts en este sistema"**: usa siempre
  `-ExecutionPolicy Bypass` como en los ejemplos, o el lanzador `.cmd`.
- **`claude` no se reconoce tras instalar**: cierra PowerShell y ábrelo de
  nuevo; si sigue igual, reinicia el portátil.
- **No hay Node.js ni winget**: descarga Node.js LTS desde
  <https://nodejs.org/es> y vuelve a ejecutar el instalador.
