```
Para: B            De: C            Fecha: 2026-10-10
Tipo: Aviso | Entrega
Prioridad: Normal
Repositorio y rama: GPOS-NG feature/modelo-ng 42e13b6
Estado: Abierto
```

# Equipo C tras el retiro de Visual Studio y del DEMO: recursos para el límite de agentes

Completa `B-a-C/2026-10-10-demo-se-retira-de-c.md`. El propietario desinstaló Visual Studio 2026, dejó el .NET 10 SDK y eliminó el DEMO.

## Comprobado
- **SDK:** 10.0.401. Los workloads `maui`, `maui-windows`, `android`, `ios` y `maccatalyst` se conservan.
- **Compilación y pruebas sin Visual Studio, sobre `feature/modelo-ng` `42e13b6`:**
  - build de `GPOS.Tests`: 0 errores, en 60 s;
  - `GPOS.Tests` filtrado contra `.\SQLEXPRESS` (Aprovisionamiento y TextoBusqueda): 44/44, en 55 s;
  - **`GPOS.Web.Tests` completa: 517/517** (38 s);
  - **`GPOS.UI.MAUI.Tests` completa: 448/448** (8 s);
  - build de MAUI para Windows (`-p:WindowsPackageType=None`): 0 errores, en 35 s.
- **DEMO retirado:** la carpeta `C:\GSF\PROYECTO ARGON\GPOS-Demo-Socio-2026-10-07` ya no está. Tampoco están `GPOS_DEMO`, `GPOS_SYSDATA` ni `GPOS_TEST_1a6aad73`. Quedan solo bases ajenas a GPOS NG (`POS_*`, `SYSDATA`, `BASEBRIRESTCSHARP`).
- **Cambio de herramientas:** al quitar Visual Studio se fue el ODBC Driver 17, así que **`sqlcmd` ya no funciona**. Las pruebas no lo necesitan, porque usan `Microsoft.Data.SqlClient`. Para consultas sueltas, C usa `System.Data.SqlClient` desde PowerShell. Si hiciera falta `sqlcmd`, lo instala el propietario (ODBC 18 o go-sqlcmd).

## Recursos libres
| Recurso | Antes | Ahora |
|---|---|---|
| Núcleos lógicos | 8 | 8 |
| RAM total | 7,8 GB | 7,8 GB |
| RAM libre en reposo (con la sesión de Claude abierta) | 1,2 GB | **1,9 GB** |
| Disco C: libre | 6,5 GB (98 %) | **37,8 GB de 237 GB** |
| `.\SQLEXPRESS` en uso | — | 274 MB (mín. 1.024 / máx. 3.072 MB configurados) |
| `.\BARTENDER` | sin tope | sigue en marcha (ajeno a GPOS; C no tiene permiso para ver su memoria) |

## Propuesta para el límite de agentes (decide el propietario)
- **Mantener el límite actual:** hasta 4 agentes si solo uno compila o prueba; si compilan o prueban más de uno, 2; lo pesado de SQL Server corre solo. La RAM no cambió y el build de `GPOS.Tests` sigue siendo el pico. Lo que mejora es el disco, que ya no es un riesgo.
- **Propuesta de memoria de SQL Server (no aplicada; es configuración del equipo):** `SQLEXPRESS` con mínimo 512 y máximo 2.048 MB. El mínimo actual de 1.024 MB retiene 1 GB que necesitan los builds.
- Si el propietario detiene `.\BARTENDER` (y su telemetría), cuando no se use, se libera algo más de memoria.
