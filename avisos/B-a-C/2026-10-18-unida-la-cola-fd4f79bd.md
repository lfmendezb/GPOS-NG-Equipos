```
Para: A y C        De: B            Fecha: 2026-10-18
Tipo: Aviso (uniones y medición)
Prioridad: Media
Repositorio y rama: GPOS-NG feature/modelo-ng @ fd4f79bd
Estado: Abierto
```

# Unida toda la cola: #61 al #84 (`feature/modelo-ng` = `fd4f79bd`)

Durante la pausa B gestionó todas las tareas (decisión del propietario). **A y C no tienen nada abierto en la cola de uniones.**

## Medición del #61 y el #71: cumplen
- N6-02 (ruta B), 5 rondas: razón de medianas **0,910** (0,996 con las 8 corridas); la primera tanda (1,066) era ruido. T-28 0,988; ruta E 0,88 a 0,94 frente a la B; ventas de 300 y 420 artículos sin penalización. Informe: `traspasos/B/2026-10-18-medicion-61-71.md`.

## Lo unido
| Lote | PR | Punta | Suite oficial (LFMB) |
|---|---|---|---|
| 1 | #61 (C) + #71 (C) | `4f4a92d5` | 3818 / 2 fallidas |
| 2 | #75, #76 (A); #77, #78, #79, #80, #81, #82, #84 (C) | `8206230e` | 3909 / 4 fallidas |
| 3 | #83 (C) | `fd4f79bd` | 3917 / 5 fallidas |
En cada lote, las fallas de carga (H11S01, ráfagas de NumeracionQaB2 y QaOla3, DL22 de tiempo, C10, R02) pasan solas. Las deterministas se corrigieron en la unión (abajo). El #84 se cerró con nota (su base, el #80, ya estaba unida).

## Correcciones de B en las uniones (por choques entre ramas)
1. **PD07** (`DesbloqueoRestauracionTests`): creaba la secuencia E31 antes de vender con tipo B; con el #61, una empresa con bloques E ya no emite serie B (SE-01). Ahora la crea después de la venta.
2. **#79:** `LongitudesColumnasConexionTests.cs` (BP2) entra en el manifiesto `Transicion/ClasificacionPruebas.md`.
3. **#83 (conflicto semántico con el #61, resuelto por un agente con Opus):** `RequiereRnc` sale de la tabla `fiscal.TipoComprobante`; la migración `20261018181156_T2cAceptaDeSuplidor` deja `RequiereRnc = 1` en 01, 14, 15, 31, 44 y 45 (los seis que el #61 tenía en código). Además, el mapeo BP2 de `NcfTipo` ignora `RequiereRnc` y `AceptaDeSuplidor`.
4. **Última marca de migración de la punta: `20261018181156`.** Toda migración nueva lleva una posterior.

## Para A y C: NuGet
La configuración de NuGet de LFMB apunta a un origen local que no existe (`C:\Users\lfmen\source\NugetLocalFeed`); con paquetes nuevos (el #75 y el #81 agregan `System.ServiceProcess.ServiceController` y `Microsoft.Extensions.Configuration.Json`), `dotnet build` falla con NU1301. B restauró con `dotnet restore --source https://api.nuget.org/v3/index.json` y compila con `--no-restore`. Si les pasa, hagan lo mismo; no hay que cambiar ninguna configuración.

## Sigue (después del miércoles 21)
El ADR de Linux con PL-10 (a) (falta el número), D1 de DB-7 desde el 2-nov (B), los hallazgos LC-03 a LC-05 del #79 y S04, S05 y S07 del #81, la excepción de `ImportacionesService.cs:428` y las casillas `RequiereRnc` y `AceptaDeSuplidor` en la pantalla de tipos. Rebasen cualquier rama abierta sobre `fd4f79bd`.
