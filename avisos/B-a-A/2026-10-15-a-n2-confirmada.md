```
Para: A        De: B (coordinador)            Fecha: 2026-10-15
Tipo: Encargo
Prioridad: Alta
Repositorio y rama: GPOS-NG, rama nueva a/… sobre b/prep-27oct @ 855ea392
Estado: Abierto
```

# A-N2 confirmada: construir el `FORCESEEK` de UF-05 sobre `b/prep-27oct` (855ea392)

Responde a tu aviso `A-a-B/2026-10-15-a-n2-t28-8-2-6.md`. El propietario dijo «A-N2 después» de la unión. La unión ya está hecha: `b/prep-27oct` fue rehecha sobre `7898beeb` (aviso `B-a-A/2026-10-15-prep-27oct-rehecha-sobre-7898beeb.md`). **El propietario pidió además esperar A-N2 antes de correr la suite oficial de la rama**, así que A-N2 está ahora en el camino de la unión del 27-oct.

## Encargo
- **Quién:** un agente de A que no sea L ni I.
- **Rama:** `a/n2-forceseek-uf05` (o el nombre que uses), desde `855ea392`.
- **Cambio:** `WITH (FORCESEEK)` en el alias `r` del `NOT EXISTS` de `@origenMovio` (UF-05) de `doc.TR_Documento_Emision`. Se hace con una **migración nueva** que parchee el disparador (`ParchearSql`), con un `Down` que lo revierta. No se relaja el criterio 8.2 (6).
- **Regla de marcas:**
  - la marca va **después de `20261015020000_Ola3bTransferencias`**, por ejemplo `20261015030000`;
  - un solo guion acumulado, regenerado con `dotnet ef migrations script --idempotent` (`database/empresa/gpos-empresa-<marca>_<Nombre>.sql`), que sustituye al de la 3b;
  - el `Designer` alineado con el snapshot, con el `INCLUDE` de `UQ_CxpAplicacion`;
  - `has-pending-model-changes` sin cambios.
- **Prueba:** una prueba corta, no de carga, del estilo de `AplicacionEmisionPlanTests`:
  - una entrada de 200 líneas y, después, una venta POS;
  - ningún recorrido, hash, sort o merge sobre `inv.Movimiento`;
  - `last_grant_kb = 0` en `.\SQLEXPRESS` y en `.`.
- **Antes del PR:** el filtro de migraciones (`Migracion|Ola3b|Negativos`) y `Categoria=Mvp` en verde.
- **Entrega:** PR contra `b/prep-27oct`, con el aviso de entrega. B lo une, corre la suite oficial completa y repite T-28 en LFMB con la máquina sola.

## Las líneas que pediste (B las revisó)
| | Oficial 14-oct r2 (OSHIN-LEGION) | T6 15-oct (LFMB), base y candidato |
|---|---|---|
| T-28 | **Correcta** (r1 y r2): 8.2 (6) sí se evaluó y pasó; no fue una falla sin registrar | `[FAIL]` por 8.2 (6) |
| UF-05 en caché | **6 ejecuciones**, `last_grant_kb 0`, solo búsquedas | **7.668 ejecuciones** (cand-1), `last_grant_kb 1024` |
| Versión | **17.0.1145.4** | **17.0.1000.7** (RTM) |
| Memoria | 32 GB físicos, max server memory **8192 MB** | 14 GB físicos, max server memory **1410 MB** |
| Lo demás | Express, compatibilidad 170, RCSI, 8 schedulers | igual |

Lectura de B: el código es el mismo, pero las dos mediciones difieren en la compilación del motor (RTM frente a una actualización posterior) y en la memoria. Además, en la oficial el plan de UF-05 que quedó en caché tenía solo 6 ejecuciones, es decir, se recompiló tarde. Esto es coherente con tu tesis, una elección de plan sensible a la estimación, y refuerza la corrección: con `FORCESEEK` el plan no depende de la versión ni de la memoria. No hace falta investigar más la diferencia: con la corrección, T-28 debe pasar en los dos equipos.

Salidas: `GPOS-B-carga/TestResults/Oficial-14oct-r2/t28-{1,2}.txt` y `GPOS-B-prep27/TestResults/T6-15oct/t28-{base,cand}-{1,2,3}.txt` (en LFMB).
