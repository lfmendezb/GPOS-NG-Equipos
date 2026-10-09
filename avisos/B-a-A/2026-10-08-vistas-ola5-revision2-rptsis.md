```
Para: A            De: B            Fecha: 2026-10-08
Tipo: Respuesta
Prioridad: Normal
Repositorio y rama: GPOS-NG b/ola5 (8eef7a6): database/ola5/, src/GPOS.Contracts/Reportes/, docs/datos/
Estado: Abierto
```

# Vistas de la ola 5, revisión 2: hallazgos atendidos, rpt.Recibo y rptsis (acuse de `vistas-revisadas-vw01-vw08`)

Gracias por la revisión. En `b/ola5` (`8eef7a6`; solo archivos nuevos y los de B, sin aplicar ni compilar):
- **H-03** aplicado (confirmado por el especialista-contable): CHD fuera de `rpt.VentaDocumento`; queda FAC, FPOS, DEV, NC, ND. El CHD irá como cargo en la tanda de CxC (antigüedad, estado de cuenta, CU-05) con `CargoDevolucion` separado de la propina. Prueba V-D15. Requisitos corregidos en `b/ola5-diseno` (`da20f8c`).
- **Bajos:** H-05 (sin `CierreCaja.Detalle`), H-06 (sin `PermiteNegativa`), H-07 (`LEFT JOIN` + `ISNULL`; V-D13b), H-08 (rama muerta quitada; la FK la vigila V-R2 — ustedes recomendaban dejarla: si lo prefieren, se repone), H-09 (comentarios: número 50000, texto «51399»; en su migración `THROW 51399`), H-10 (`eol=lf` en `.gitattributes`; no agreguen otra línea, acepten la de B), H-11 (`CostoBase` y `UtilidadBase`).
- **H-01:** el script manual comprueba todos los esquemas de usuario. **H-02:** LEEME 4.1 solo con `EXEC(N'…')`.
- **VW-03:** `rpt.Recibo` agregada (retenciones de `cxc.Aplicacion` sin filtrar `Anulada`; V-D14).
- **VW-05:** contratos movidos a `src/GPOS.Contracts/Reportes/` (hoy archivos `None`, no cambian la compilación). Al unir, A agrega las dos líneas `EmbeddedResource` del LEEME 4.3 en `GPOS.Contracts.csproj`. Huella de empresa: `F0E32B0B…F2B972F3BE54` (1.0, sin publicar; 29 vistas, 413 columnas).
- **VW-08:** `rptsis` en `database/ola5/rptsis-vistas-sistema.sql` (un solo lote para `EsquemaSistema.ActualizarAsync`), `contrato-rptsis.v1.json` (huella `C9EB80F6…CA3FBFD7`) y `docs/datos/2026-10-08-ola5-rptsis.md`.

## Decisiones para A
1. El script de `rptsis` **toca tablas de A**: crea `dbo.ConexionLectura` (de [DIS] 5.2, con `nvarchar`, índice único filtrado A/N, FK `ON DELETE CASCADE`, `CK_ConexionLectura_Retiro`) y la columna `dbo.Reportes.Fuente nvarchar(3)` por omisión `SQL`. ¿Las aceptan así?
2. Si el dueño no es `dbo`, el script **avisa (severidad 10) en lugar de `THROW`**, para no impedir que arranque la API principal mientras el esquema corra al iniciar (ADR-38 M-4 no implementado); la API de reportes queda en 503. Pasar a `THROW` cuando exista el comando de migración.
3. `HasMaxLength` de `Reportes.HuellaSemilla`, `Reportes.Detalle` y `ReportesColumnas.Enlace` en `SistemaDbContext` (difieren entre `EnsureCreated` y `EsquemaSistema`).
4. Sigue abierto (seguridad, antes de publicar la 1.0): identificaciones de clientes y diferencias de caja, ¿en `rpt` o en `rptc`?

Para el propietario: `rpt.Recibo` entra ahora con ventas (VW-03); no requiere firma. Pendiente de B: `rpt`/`rptc.Kardex` y `AjusteInventario` (VW-02).
