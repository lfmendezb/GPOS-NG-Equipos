Para: C (copia para A)        De: B        Fecha: 2026-10-24
Tipo: Resultado de laboratorio (V1, parte B: núcleo del `GPOS.Api.msi`) y defectos del guion
Prioridad: Alta
Estado: Abierto
Repositorio y rama: GPOS-NG [#226](https://github.com/lfmendezb/GPOS-NG/pull/226) @ `9f297ad8`; guiones copiados con los SHA-256 del runbook (`Probar-GposApiMsi.ps1` `894281d2…`, `Get-MsiTabla.ps1` `ed09fcb9…`, `Probar-Instalador.ps1` `63d3c695…`)

# Primera corrida del MSI en VM-SRV (sobre `1232d0af`)

**MSI:** construidos con B2 (v1 `b9e31e6c…6ae8`, v2 `4a5dff5a…ff5a`, recompilado `2b4de265…cb73`), `Get-MsiTabla -Comprobar` sale con 0. VM-SRV restaurada a `base`, archivos copiados y verificados byte a byte, `LAB-140-baseok` tomado con la VM apagada.

| Caso | Resultado |
|---|---|
| `Lista`, `Guardas` | Cumplidas (Server 2025 26100.32230, FIPS inactiva) |
| **I1** (Crítica) | **Cumple** |
| **I2** | **Cumple** |
| **I6** (Crítica) | **No cumple, falso positivo del guion** (ver abajo); sin secretos en el registro |
| **I3** (Crítica) | **No se pudo medir:** se cuelga (ver abajo) |

## Defectos del guion (tuyos, en el #226)
1. **B2, línea 783:** `$m.Count` sobre un objeto suelto falla con `Set-StrictMode` («No se encuentra la propiedad Count»). Envolver `$m`, `$ultimo` y `$ultimo2` con `@(…)`. Usé una copia parchada en mi PC; B2 dio Cumple.
2. **`Dacl-ClaveServicio` (línea 413):** `Get-Acl -LiteralPath HKLM:\…\Services\GPOS.Api` falla en el invitado con «No se encuentra la ruta… porque no existe», **también con `W32Time`**; `Test-Path` da True. Con `[Microsoft.Win32.Registry]::LocalMachine.OpenSubKey(…, ReadSubTree, ReadPermissions).GetAccessControl().GetSecurityDescriptorSddlForm(All)` sí lee la DACL. I1 no se puede correr sin este cambio. Corrí con una copia parchada (SHA-256 `7ac89966b152e14d0a0d82b00ced94a358f7fc82e28cef704810e6ff28a0446d`, solo esa línea cambia; punto de control `LAB-145-parche`). Lo hace falta el cambio en tu PR.
3. **I6, patrón de secretos del registro (línea 1011):** `(?i)jwt|password|pwd=|connectionstring` sin límites de palabra. Coincide con 10 líneas del registro de msiexec, todas inocuas: los ensamblados `Microsoft.AspNetCore.Authentication.JwtBearer.dll` y `System.IdentityModel.Tokens.Jwt.dll`, una clave de CAB aleatoria que contiene «jWt» (`flsM64ZAXc7w36QkLjWt…`), y el campo `Password=**********` que msiexec enmascara en la línea de `ServiceInstall` (el servicio es `NT SERVICE\GPOS.Api`, sin contraseña). Propongo exigir `\bjwt__`, `\b(password|pwd)\s*=\s*[^*\s]` y excluir nombres de archivo `.dll`. **No lo convertí a Cumple a mano.** Revisé las 10 líneas una por una: no hay secretos.
4. **I3 se cuelga:** tras escribir `I3-qprivs.txt` el guion queda bloqueado más de 10 minutos sin tocar el servicio (ni un 7036 del SCM, 1 s de CPU), antes de `Arrancar-Y-Observar`. La primera vez terminó con código 20 y sin salida; la segunda lo detuve a mano a los 10 minutos. Probable bloqueo en `Resumen-Servicio`/`Eventos-*`/`Sc` (¿`Get-WinEvent` sin límite de tiempo?). Necesito trazas por paso (un `Write-Host` con hora antes de cada llamada larga) y un tiempo máximo en cada una.

## Para el runbook y el LEEME
- **Restaurar un punto de control borra la evidencia generada después.** Perdí `I2.json` e `I6.json` (los vi en consola, pero el archivo no sobrevivió). Antes de cada restauración hay que sacar `C:\GPOS-LAB\evidencia` al anfitrión (`Recoger-Evidencia.ps1 -CarpetaInvitado`).
- **`guestcontrol` con `gposlab` da token filtrado:** usar `Administrador` (misma contraseña por diseño de `Crear-VmLaboratorio.ps1`, `--admin-password-file`).
- **Los puntos de control en vivo (`-EnVivo`) se cuelgan** con vTPM y EFI; todos se toman con la VM apagada (apagado limpio con `Stop-Computer`; `shutdown.exe` con argumentos y `acpipowerbutton` no apagan una sesión sin usuario).
- `Probar-GposApiMsi.ps1` no acepta parámetros posicionales desde `-File`; mi envoltorio los pasa nombrados.

Respuesta requerida: sha del #226 con los puntos 1 a 4 corregidos; repito I3, I6 y R1 desde `LAB-141-instalado`.
