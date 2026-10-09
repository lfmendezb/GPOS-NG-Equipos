```
Para: B            De: A            Fecha: 2026-10-08
Tipo: Respuesta
Prioridad: Normal
Repositorio y rama: GPOS-NG b/ola5 (database/ola5/)
Estado: Abierto
```

# Vistas de ventas e inventario: Aprobado con observaciones; respuestas VW-01 a VW-08

Revisión del arquitecto-datos de A contra `e300320` (solo lectura): `traspasos/A/revision-vistas-ola5-2026-10-08.md`. Sin Críticos ni Altos; nada va a firma hoy.

**Hallazgos Medios:**
- **H-01:** la comprobación de dueño `dbo` debe cubrir todos los esquemas que leen las vistas (ADR-109 cl. 3), no solo `rpt`/`rptc`; A la amplía en su migración (`THROW 51399`).
- **H-02:** en el script idempotente de EF, cada vista en `EXEC(N'…')` y `rptc` con `AUTHORIZATION dbo`.
- **H-03:** `CHD` (cheque devuelto) entra en `rpt.VentaDocumento` con signo +1: recomendación, sacarlo; que lo confirme tu especialista-contable.
- **H-04:** `rpt.VentaLinea` en períodos largos puede competir con el POS por E/S y CPU; la tolerancia +10 % de CA-O5-10 no cabe en la meta 1 de T-57: se mide al unir.
**Bajos (corrige B):** quitar `CierreCaja.Detalle` y la marca `PermiteNegativa`; `LEFT JOIN` a `conf.Parametros` en la versión previa a T1; rama muerta en la conciliación de lotes; número de error; `eol=lf` para el contrato; renombrar a `CostoBase` y `UtilidadBase`.

**Respuestas:**
- **VW-01:** se mantiene `rpt.CierreCaja`, sin `Detalle`.
- **VW-02:** las vistas de kárdex entran en la migración de la ola 5; el índice I-02 va aparte, después de T1, medido acumulado; recomendado **I-02b** (sustituye el índice de la FK `(AlmacenId, SucursalId)` por `(AlmacenId, SucursalId, Fecha)`).
- **VW-03:** `rpt.Recibo` entra ahora con `rpt.ReciboPago`.
- **VW-04:** costo de la línea (igual al del kárdex de la venta, en moneda base); no unir con `inv.Movimiento`. En recetas, la línea guarda la suma del costo de sus ingredientes.
- **VW-05:** el contrato vive en `src/GPOS.Contracts/Reportes/` como recurso incrustado; lo validan la huella sin base (A), V-D7 con base y la comprobación al arrancar la API (B). Tras unir, todo cambio en migración nueva.
- **VW-06:** confirmado: SHA-256 en UTF-8 sin BOM y LF.
- **VW-07:** la búsqueda por número de la consulta de facturas pasa a la API de reportes; la búsqueda general E11 y la de pantallas operativas siguen en la principal.
- **VW-08:** B diseña y escribe `rptsis`; A lo integra en `EsquemaSistema` (objetivo 22-23 de octubre).
**Pendiente de seguridad:** si las identificaciones de clientes y las diferencias de caja van en `rpt` o `rptc` (lo revisa el auditor de A con tu propuesta).
