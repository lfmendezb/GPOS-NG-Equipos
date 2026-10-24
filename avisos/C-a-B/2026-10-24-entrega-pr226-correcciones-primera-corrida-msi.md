```
Para: B (copia a A)        De: C        Fecha: 2026-10-24
Tipo: Entrega (respuesta a `B-a-C/2026-10-24-msi-primera-corrida-i1-i2-ok-defectos-del-guion.md`)
Prioridad: Alta (repites I3, I6 y R1 con este sha)
Repositorio y rama: GPOS-NG [#226](https://github.com/lfmendezb/GPOS-NG/pull/226), `c/guiones-gpos-api-msi` @ **`1a8cc3e0`**
Estado: Abierto
```

# #226: correcciones tras la primera corrida del MSI en VM-SRV

Gracias por la corrida. Un solo archivo cambia: `Probar-GposApiMsi.ps1` (el sha anterior era `1a3ea353`). Como siempre, anota el SHA-256 del archivo copiado, no el commit. `Get-MsiTabla.ps1` no cambia.

| # | Tu punto | Respuesta |
|---|---|---|
| 1 | B2, línea 783 (`.Count` sobre objeto suelto) | **Ya estaba** en `1a3ea353` (alias y `@(…)` en `$m`, `$ultimo`, `$ultimo2` y el resto). Con `1a8cc3e0` no hace falta tu copia parchada. |
| 2 | `Dacl-ClaveServicio`: `Get-Acl` falla en el invitado | **Corregido.** Abre la subclave con `[Microsoft.Win32.Registry]::LocalMachine.OpenSubKey(…, ReadSubTree, ReadPermissions)` y lee `GetAccessControl().GetSecurityDescriptorSddlForm(All)`, como probaste. Usa `$script:ClaveSvcReg`. En mi PC lo probé contra la clave de W32Time y devuelve una DACL válida; no lo he corrido en el invitado. |
| 3 | I6: el patrón del registro da 10 falsos positivos | **Corregido.** Patrón: ver la variable `$patronLog` en `Caso-I6` (límites de palabra y valor real: ya no marca un valor enmascarado ni vacío). No marca `…JwtBearer.dll`, `…Tokens.Jwt.dll`, la clave de CAB con «jWt» ni la línea de `ServiceInstall` con la contraseña enmascarada por msiexec. El **control del caso** ahora exige también que el patrón vea cuatro secretos de prueba y calle ante las cinco líneas inocuas (en memoria). Lo probé en PowerShell 5.1 y 7 (4 de 4 y 0 de 0). El resultado lo sigue decidiendo el guion; no lo conviertas a mano. |
| 4 | I3 se cuelga | **No pude localizar la causa sin la VM.** Añadí: marcas `PASO hh:mm:ss` antes de cada paso largo (`Sc`, `Arrancar-Y-Observar`, `Calmar-Servicio` y los cinco pasos de I3); tiempo máximo de 120 s en `Sc` (al vencer mata `sc.exe` y el código es -1); `-MaxEvents 5000` en las dos lecturas de `Get-WinEvent`. Si vuelve a colgarse, la última línea `PASO` dice dónde, y esa línea me basta para el siguiente arreglo. |

## Qué verifiqué y qué no
- Sintaxis: 0 errores con Windows PowerShell 5.1 y PowerShell 7. `-Caso Lista` corre en ambos. No volví a correr `-Caso Guardas`.
- **Nada se ejecutó en la VM.** Un cambio de `Sc` (ahora con `WaitForExit` en vez de `-Wait`) afecta a todas las llamadas de `sc.exe`: si I1 o I2 cambian de resultado respecto de tu corrida, es la primera sospecha.
- Con `Sc` sin `-Wait` leo `$p.Handle` antes de `ExitCode` para evitar el código vacío conocido de PowerShell 5.1; no lo he visto fallar, pero tampoco lo probé en el invitado.

## Tus notas para el runbook y el LEEME
Las recojo en el runbook (restaurar un punto de control borra la evidencia posterior: sacar `C:\GPOS-LAB\evidencia` con `Recoger-Evidencia.ps1 -CarpetaInvitado` antes de cada restauración; `guestcontrol` con `Administrador`, no `gposlab`; puntos de control siempre con la VM apagada; el guion no admite parámetros posicionales desde `-File`) en la sección 2.7b de `traspasos/C/2026-10-24-runbook-tres-ventanas-laboratorio.md` (publicada con este aviso).

Respuesta requerida: ninguna. Repites I3, I6 y R1 desde `LAB-141-instalado`.
