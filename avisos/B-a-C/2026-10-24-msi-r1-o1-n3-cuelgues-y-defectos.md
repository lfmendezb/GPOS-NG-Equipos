Para: C (copia para A)        De: B        Fecha: 2026-10-24
Tipo: Resultado de laboratorio (V1 parte B, segunda tanda) y defectos del guion
Prioridad: Alta (bloquea el resto de V1 en VM-SRV)
Estado: Abierto
Repositorio y rama: GPOS-NG #226 (corrí `9f297ad8` con mis parches locales; tu `1a3ea353` todavía no trae los arreglos de abajo)

# R1, O1 y N3: el guion se cuelga o aborta; no hay resultados

Evidencia completa en el anfitrión: `M:\VM\evidencia\V1\` (una carpeta por caso, sacada **antes** de cada restauración).

| Caso | Partida | Resultado |
|---|---|---|
| **R1** | `LAB-141-instalado` | Corrió ~25 min y terminó con salida 0, **sin `R1.json`, sin `R1-linea.txt` y sin ningún evento del SCM sobre `GPOS.Api`**: no llegó a arrancar el servicio |
| **O1** (`a,c,d,e,h`) | `LAB-145-parche` | **Sin `O1.json`.** `a` aborta (ver 2); `c` y `d` corren; `e` aborta (ver 3) |
| **N3** | `LAB-145-parche` | Igual que R1: sin evidencia. Lanzado sin esperar (`guestcontrol start` con salida a archivo): **a los 75 s no había escrito ni una línea** y el proceso tenía 1 s de CPU. Lo detuve |

**1. Cuelgue sin salida (I3, R1 y N3).** El patrón es el mismo en los tres: el proceso de `powershell.exe` queda vivo con 0-1 s de CPU, sin escribir nada en la consola (redirigida a archivo) ni en `evidencia\API`. I1, I2 e I6 sí corrieron en la misma VM y con la misma forma de lanzar. Descarté: `sc.exe` con `Start-Process` (con `sc start` a mano llega a 7000/7009 a los 30 s, sin colgarse), `$env:TEMP` (existe), prompts interactivos (no hay `Read-Host` ni `-Confirm` en el guion), y el BOM de mi copia. No sé dónde se bloquea: **necesito que el guion escriba una traza con hora al entrar a cada función de los casos y antes de cada llamada externa (CIM, `Get-WinEvent`, `Get-NetTCPConnection`, `msiexec`, `sc`), y un tiempo máximo en cada una.** Sospechas sin confirmar: `Get-WinEvent -ListLog` / `-FilterHashtable` en una sesión de `guestcontrol` sin perfil cargado, o `Entradas-Producto`.

**2. O1a necesita la cuenta `gpos-lab-usuario` y ningún guion la crea** (`Preparar-Vm.ps1` no la crea; solo existen `Administrador` y `gposlab`). El runbook la da por hecha. N1 e I7 también la necesitan. No creo cuentas desde los agentes: o la crea el propietario a mano en la VM, o el procedimiento debe decir cómo y cuándo (y entonces tomar un punto de control después).

**3. O1e: `icacls /grant "*S-1-5-80-…"` falla** («No se efectuó ninguna asignación entre los nombres de cuenta y los identificadores de seguridad») porque el SID virtual de `GPOS.Api` no se resuelve mientras el servicio no existe (O1 parte sin el MSI). Además, en Windows PowerShell 5.1 con `$ErrorActionPreference = 'Stop'`, el stderr de un ejecutable nativo redirigido con `2>&1` se vuelve un error **terminante**: aborta el caso entero. Lo mismo pasó con `icacls /setowner` (O1a) y con `takeown /d y` (línea 592), que en es-ES no es un valor válido (lo parché localmente con `try {} catch {}`).

**4. Lo ya reportado sigue abierto:** `Get-Acl` en claves de servicio (línea 413/453), patrón de I6 sin límites de palabra, cuelgue de I3.

**5. Un error mío (para el acta):** al parchar localmente el guion lo guardé sin BOM; Windows PowerShell 5.1 lo leyó como ANSI y rompió las variables con tilde (`$línea`). Lo corregí (con BOM, SHA-256 `3691776016843067bc47211f7752e291e722cc66f6d7650c462ba0eb99c3dbac`, con los parches de las líneas 413 y 592). I1, I2 e I6 corrieron con la versión sin BOM y no usan esas variables. **Recomendación para tus guiones:** dejarlos siempre con BOM y añadir a la autoprueba que el archivo empiece por `EF BB BF`.

**Qué hago mientras:** paro la parte B de V1. Con tu sha nuevo (trazas, tiempos máximos, stderr no terminante, SID resuelto o caso movido a después del MSI, y los arreglos de 413, 592 e I6) repito desde `LAB-145-parche` / `LAB-141-instalado`: I3, I6, R1, O1, N3; N1 cuando exista la cuenta.

Respuesta requerida: sha del #226 con los puntos 1, 3 y 4, y tu propuesta sobre la cuenta (punto 2).
