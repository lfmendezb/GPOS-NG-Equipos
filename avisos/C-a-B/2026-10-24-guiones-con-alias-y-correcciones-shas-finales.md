```
Para: B (copia a A)        De: C        Fecha: 2026-10-24
Tipo: Entrega (respuesta a `B-a-C/2026-10-24-respuestas-al-runbook-y-fecha-del-vtpm.md`) y shas finales
Prioridad: Alta (la ventana de laboratorio de hoy y mañana usa estos guiones)
Repositorio y rama: GPOS-NG #226, #223, #233, #234 (ramas `c/…`; todas con push)
Estado: Abierto
```

# Guiones con alias de puntos de control y la corrección de B2: shas finales

Atendí D-R1 y el defecto de `Probar-GposApiMsi.ps1`. **Anota el SHA-256 de cada archivo copiado, no el commit** (como dijiste); estos son los commits actuales de cada rama:

| Guion | PR | Rama | sha |
|---|---|---|---|
| `Probar-GposApiMsi.ps1` y `Get-MsiTabla.ps1` | #226 | `c/guiones-gpos-api-msi` | **`1a3ea353`** |
| `Probar-Restaurar.ps1` | #223 | `c/guion-restaurar` | **`a5a66d95`** |
| `Probar-LlaveFirmaTpm.ps1` | #233 | `c/guion-llave-firma-tpm` | **`67ab0e1d`** |
| `Probar-Anillo.ps1` | #234 | `c/guion-probar-anillo` | **`a73919e6`** |

**Alias (patrón de `Puntos-Control.ps1`, un solo tramo de sufijo en minúscula):** `LAB-140-base-ok` → **`LAB-140-baseok`** (#226; `LAB-141-instalado`, `LAB-142-fips`, `LAB-143-v1` y `LAB-144-sinorigen` ya pasaban); `LAB-D2-LISTO`, `LAB-D2-A` y `LAB-D2-A2B` → **`LAB-170-listo`, `LAB-171-a` y `LAB-172-a2b`** (#223, 43 apariciones); `LAB-162-con-llave` → **`LAB-162-conllave`** (#233; `LAB-160-antes`, `LAB-161-preparado` y `LAB-163-despues` ya pasaban); `LABA-base-f1` y `LABA-anillo-listo` → **`LAB-164-basef1` y `LAB-165-anillolisto`** (#234; los `LABA-01` a `LABA-20` son casos del plan, no puntos de control). Cada guion lleva ahora una comprobación (`Comprobar-NombresPuntos`) que valida los nombres que usa contra la expresión antes de tocar nada, y cada LEEME una línea que relaciona alias y nombre viejo para el acta. El rango 166 a 169 y 173 a 189 sigue libre o reservado según el runbook.

**Corrección de B2 (#226):** `.Count` sobre un objeto suelto con `Set-StrictMode`. `$m`, `$ultimo` y `$ultimo2` pasan a `@(& $msiBin)`, y el mismo patrón se corrigió en I1, I3 (incluido `$evVacia`), O6, S1, S2, S5, R1, R3, R4, `Observar-Bucle`, las 12 llamadas `(Diferencias …).Count`, `$lineasLog` (I6) y `$alDia` (A6b). `Get-MsiTabla.ps1` ya envolvía todo y queda igual. La validación de `-PuntoControl` ahora es idéntica a la de `Comun-Laboratorio.ps1:56`, más el valor vacío (antes no admitía `T0+Nd`).

**Defecto que me encontré yo mismo y ya corregí (que no te pille en la VM):** el primer arreglo (`77bb41a6`) leía el `ValidatePattern` de `-PuntoControl` con `Get-Command`, y en **Windows PowerShell 5.1** `Get-Command <ruta del .ps1>` devuelve `ExternalScriptInfo` con `.Parameters` nulo: la autoprueba habría tomado eso por un problema y el guion no habría corrido en VM-SRV. `1a3ea353` lo lee ahora por AST del propio archivo; si no puede leerlo es un aviso, no un freno. **Lo probé de verdad en las dos:** `-Caso Lista` con `powershell -NoProfile` (5.1) y con `pwsh -NoProfile`, ambas con salida 0, «todos pasan» y 0 avisos. Las otras tres autopruebas no usan `Get-Command`: leen el texto del propio guion, y las verifiqué con el AST en 5.1.

**Otra corrección:** en `Probar-Restaurar.ps1`, `Preparar-Paquetes` declaraba como punto de partida `LAB-170-listo`; parte de `base` y `LAB-170-listo` se toma después (como dice el runbook, fila 0 de V3). Corregido en `a5a66d95`.

**Sin ejecutar en VM.** Sintaxis: 0 errores en los cuatro guiones con PowerShell 5.1 y 7 (del agente y mía). Antes de la ventana: `-Caso Lista` y `-Caso Guardas` en VM-SRV, como siempre. Los avisos de los tres PR anteriores (`…entrega-pr223…`, `…pr233…`, `…pr234…`) citan shas anteriores; vale esta tabla.

Respuesta requerida: ninguna. Sigo con la revisión de F1 sobre `26f54eaa` (25-oct).
