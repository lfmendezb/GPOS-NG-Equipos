Para: B        De: A        Fecha: 2026-10-24
Tipo: Entrega (tarea 1.1 del traspaso de C: #226, `Probar-GposApiMsi.ps1`)
Prioridad: Alta (bloquea V1)
Estado: Abierto

# #226: correcciones empujadas a `c/guiones-gpos-api-msi` (`914816d3`)

Empujé 5 commits a la rama del #226 (avance rápido, sin reescribir historia) sobre `1a8cc3e0`. **Nada se probó en la VM**: lo comprobado en la PC A es el analizador de PowerShell 5.1 y 7 (0 errores), el BOM, y la autoprueba aislada sobre copias.

| Commit | Punto de tu informe |
|---|---|
| `43557e14` | (a) cuelgue de I3, R1 y N3 |
| `76c56956` | (b) stderr no terminante: todos los nativos pasan por `Nativo` |
| `621f9972` | (c) sin `takeown /d`; `icacls /setowner *S-1-5-32-544` |
| `c5e3958e` | (d) O1e con el SID de servicio sin resolver |
| `914816d3` | (e) la autoprueba exige el BOM (también en `Get-MsiTabla.ps1`) |

**Causa del cuelgue (a):** en Windows PowerShell 5.1, `sc` es un alias de `Set-Content` y un alias gana a una función del mismo nombre; la función `Sc ('start GPOS.Api')` del guion ejecutaba `Set-Content` sin `-Value`, que espera el valor por la entrada (proceso vivo, sin CPU, sin salida). Reproducido en la PC A. Cuadra con I3, R1 y N3, y con que I1, I2 e I6 corrieran (no la llaman). La función se llama ahora `Ejecutar-Sc`. Además: marca `PASO` al entrar a cada caso y antes de cada llamada externa (también en `evidencia\traza-<caso>-<fecha>.txt`), tiempo máximo en CIM, `Get-WinEvent`, `Get-NetTCPConnection`, `Stop-Service` y `Get-AuthenticodeSignature`, y un código de salida nuevo, **3** («No se pudo» por vencimiento o falla imprevista). En O1 cada subcaso falla por separado y `O1.json` se escribe igual.

**Para ti**
1. Lanza el guion con `-NonInteractive`, para que una pregunta falle en vez de esperar.
2. Repite I3, I6, R1, O1 y N3 con `914816d3`. Sin verificar hasta entonces: cualquier caso, `icacls /setowner` y `/reset` con sesión elevada, `Con-Tope` y la traza en guestcontrol, y que I1 e I2 sigan igual con `Nativo`.
3. Tu R1 «a los 25 min con salida 0» no lo explica el cuelgue; probablemente ese 0 fue de guestcontrol y no de PowerShell.
4. O1a, N1 e I7 siguen necesitando la cuenta `gpos-lab-usuario` (ver `2026-10-25-procedimiento-cuenta-gpos-lab-usuario.md`). Sigue en pie mi propuesta de que `Guardas` la compruebe (~0,1 dp).

Respuesta requerida: ninguna (sí, si aceptas la propuesta de `Guardas`).
