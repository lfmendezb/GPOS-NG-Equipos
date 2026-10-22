```
Para: B        De: C        Fecha: 2026-10-22
Tipo: Entrega (tarea 2 del aviso 2026-10-22: inventario de reportes y vistas `rpt` que muestran la identificación del tercero; M-5 de ADR-161 y TT)
Prioridad: Media
Repositorio y rama: GPOS-NG `feature/modelo-ng` (leído en el ref local `origin/feature/modelo-ng` @ `b4378650`, 2026-10-22 14:46)
Estado: Abierto
```

# Inventario de salidas que muestran la identificación del tercero

**Solo lectura; nada compilado ni ejecutado.** Lo hizo un agente de lectura (búsquedas con `git grep`) y yo verifiqué personalmente la fila #10 (`ReportesSemilla.cs:304`). Las demás filas son del agente: [V] = leído en el texto, [I] = inferido. Abreviatura: BASE = raíz del repositorio. «Enmasc.» = `'*******'` + últimos 4.

## Tabla

| # | Salida | Tipo | Dónde sale completa | Archivo:línea | Quién la ve | Qué cambiaría al enmascarar | Depende de R/C/P/N | V/I |
|---|---|---|---|---|---|---|---|---|
| 1 | `rpt.VentaDocumento` | vista rpt | Solo R (9 dígitos); C y P enmasc. | BASE `database/ola5/rpt-vistas-ventas-inventario.sql:137-208` (enmasc. 168-170; `RncReceptor` por tipo 202-203) | Sin privilegio (null en contrato) | Hoy ya enmascara C y P; enmascarar R = quitar la rama `'R'` en 168-170 | Sí: `TipoIdentificacionCliente` de la venta; `RncReceptor` usa `ti.Receptor` | V |
| 2 | `rptc.VentaDocumento` | vista rptc | R y C completas; P últimos 4 | mismo archivo `:209-287` (completa 265-267) | `verdatospersonales` (SUPERVISOR y CONTADOR por omisión; CAJERO no) | Ninguno: ya es la restringida | Sí (IN R,C) | V |
| 3 | `rpt.Cotizacion` | vista rpt | Solo R | mismo archivo `:463-506` (enmasc. 486-488) | Sin privilegio | Como #1 | Sí | V |
| 4 | `rptc.Cotizacion` | vista rptc | R y C | mismo archivo `:507-559` (completa 539-541) | `verdatospersonales` | Ninguno | Sí | V |
| 5 | `rpt.ConsultaFactura` (y rptc) | vista rpt/rptc | rpt: solo R; rptc: R y C | `rpt-vistas-ventas-inventario.sql` enmasc. 812-814 y 870-872, rptc 886-888; versión previa en `database/ola5/rpt-vistas-tramo4.sql:431-549` | rpt sin privilegio; rptc `verdatospersonales` | Como #1 | Sí | V (hay **dos** definiciones; vigente por confirmar) |
| 6 | `rpt.CatCliente` / `rptc.CatCliente` | vista rpt/rptc | rpt: solo R; rptc: R y C | `rpt-vistas-ventas-inventario.sql:1548-1569` | rpt sin privilegio; rptc `verdatospersonales` | Como #1; afecta el maestro de clientes en reportes | Sí | V |
| 7 | `rpt.CatSuplidor` / `rptc.CatSuplidor` | vista rpt/rptc | Igual que #6 | mismo archivo `:1570-1590` | Igual | Como #6 | Sí | V |
| 8 | `rpt.CajaChica` (reporte 22) | vista rpt | RNC de 9 dígitos íntegro; cédula (11) enmasc. | `database/ola5/rpt-vistas-tramo4.sql:230-267` (regla por LEN, 242-244) | Sin privilegio | Enmascarar el RNC de 9 dígitos; bajo riesgo fiscal si no alimenta el 606 (confirmar con el contador) | No: decide por largo (`CK_CajaChica_Rnc`: 9 u 11 dígitos) | V |
| 9 | `rptc.CajaChica` | vista rptc | RNC y cédula completos (296) | mismo archivo `:268-314` | `verdatospersonales` | Ninguno | No | V |
| 10 | Reporte del sistema «Gastos de caja chica» (`EF-CAJA-CHICA`) | reporte con SQL directo (no pasa por `rpt`) | RNC completo, sin enmascarar | `src/GPOS.Core/Sistema/ReportesSemilla.cs:303-304` (`g.RncCedula AS RNC` sobre `caja.CajaChica`) | La semilla no declara privilegio; visible a quien ejecute el reporte (I) | Cambiar la SQL de la semilla: hoy elude el enmascarado de #8 | No | **V** (verificado por mí) |
| 11 | `rpt.Formato606` (606) | vista rpt, obligatoria | RNC/cédula completos (`r.RncCedula`) | `database/empresa/gpos-empresa-20261021001638_Ola5VistasTramo4.sql:8135-8160` | Sin privilegio (RS-04 aplazada según LEEME) | **NO enmascarar**: rompe el 606 | No directo: usa código `'1'/'2'` (`FisConfiguracion.cs:275-287`) | V |
| 12 | `rpt.Formato607` (607) | vista rpt, obligatoria | `RncReceptor` completo | mismo guion `:14453` (versiones previas 5345, 9249, 10168) | Sin privilegio (RS-04 aplazada) | **NO enmascarar**: rompe el 607 | No | V |
| 13 | `rpt.Formato608` | vista rpt | No muestra identificación | mismo guion `:14416` | n/a | n/a | n/a | V |
| 14 | Impresión: «RNC/Cédula» del tercero en factura, ticket y plantillas | formato | RNC completo (`FormatoRnc.Mostrar`) | `src/GPOS.Api/Impresion/FormatoDocumento.cs:76`; `FormatoTicket.cs:70`; `src/GPOS.Contracts/Impresion/PlantillasRazor.cs:113`; `PlantillasRazor.Rollo.cs:70`; `GeneradorRazor.cs:187` y `245` | Quien pueda imprimir (privilegio no verificado) | **NO enmascarar** comprobantes con `RequiereRnc`/e-CF: es dato del comprobante | No | V |
| 15 | Impresión: origen del tercero (venta, recibo, nota, retención, caja chica, cliente) | modelo de formato | Cliente `v.ClienteRnc` completo; retención `SuplidorRnc` y `AgenteRnc` completos; caja chica `g.Rnc` completo | `src/GPOS.Api/Impresion/FabricaModelo.cs:48-73, 102, 117, 142-143, 169, 195, 207, 221, 235-236 (retención), 250 (caja chica), 269`; `ImpresionDatosService.cs:51-54` | Igual que #14 | Retención: **NO enmascarar** (comprobante del agente retenedor). Caja chica: bajo riesgo | No | V (líneas); I (mapeo por tipo) |
| 16 | Consulta de compras | pantalla/consulta | `IdentificacionSuplidor` completa | `src/GPOS.Core/Consultas/Compras/ConsultasCompras.cs:19` y `368` | No verificado | Rompe la búsqueda por RNC si la hay | No | V (SQL); I (pantalla) |
| 17 | Búsqueda de facturas por RNC | pantalla | RNC completo en el listado | `src/GPOS.Core/Servicios/ConsultaFacturasService.cs:81, 111-120`; `ConsultaFacturas.razor:40` | No verificado | Rompe una función de negocio (buscar por RNC) | No | V (campo); I (columna) |
| 18 | Autocompletar maestros (clientes y suplidores) | consulta | `Detalle` = identificación completa, TOP 200 | `src/GPOS.Core/Consultas/Maestros/ConsultasMaestros.cs:16-29` | No verificado | Afecta la selección de terceros | No | V (SQL); I (UI) |
| 19 | Consultas CxP | consulta | `Identificacion` del suplidor | `src/GPOS.Core/Consultas/CuentasPorPagar/ConsultasCxp.cs:312, 320, 441` | No verificado | Revisar uso en pantalla | No | V (SQL); I (uso) |
| 20 | Consulta fiscal | consulta | `RncReceptor` completo | `src/GPOS.Core/Consultas/Fiscal/ConsultasFiscal.cs:37` | No verificado | **NO enmascarar** si alimenta el 607 o el e-CF | No | V (SQL); I (uso) |
| 21 | Verificar exportación (admin) | pantalla admin | Columna RNC por fila | `src/GPOS.Web/Components/Pages/Admin/VerificarExportacion.razor:44-57` | Admin (no verificado) | Verificación de integridad: no enmascarar | No | V |
| 22 | Exportaciones CSV y XLSX | exportación | Lo que traiga la vista de origen | `src/GPOS.Reportes/Exportacion/EscritorCsv.cs`, `EscritorXlsx.cs` (no leídos en detalle) | Igual que la fuente | Hereda el enmascarado de la fuente | Hereda | I |

## Resumen de riesgos
1. **No enmascarar** (obligaciones DGII/e-CF): `rpt.Formato606` (#11), `rpt.Formato607` (#12), comprobantes impresos con el RNC/cédula del comprador cuando lo exigen (#14) y el comprobante de retención con RNC del suplidor y del agente (#15). Aquí la protección debe ser de **acceso** (RS-04, aplazada), no de enmascarado.
2. **Fuga conocida de mayor prioridad (#10):** el reporte `EF-CAJA-CHICA` consulta la tabla base y muestra el RNC completo; el enmascarado de `rpt.CajaChica` (#8) no lo cubre. Verificado por mí en `ReportesSemilla.cs:303-304`.
3. **M-5 se confirma:** en `rpt`, R sale completo y C se enmascara; una persona física con RNC de 9 dígitos (letra R) sale completa en #1, #3, #5, #6 y #7. M-5 necesita enmascarar por `EsPersonaFisica`, no solo por la letra.
4. **Dependencia de la letra:** #1, #3, #5, #6 y #7 dependen de `TipoIdentificacion(Cliente)` = R/C/P. El 606 usa `'1'/'2'`. CajaChica depende solo del largo. Cambiar `TipoDe` (A-1 de la revisión de la DDL) cambia el enmascarado de #1, #3, #5, #6 y #7.
5. **Pantallas operativas (#16, #17, #18):** enmascarar rompe la búsqueda por RNC o la selección de terceros; no es un cambio solo de reportes.

## Salidas que pueden enmascararse sin riesgo fiscal
- `rpt.CatCliente` y `rpt.CatSuplidor` (#6, #7): enmascarar R de personas físicas por `EsPersonaFisica`.
- `rpt.VentaDocumento`, `rpt.Cotizacion`, `rpt.ConsultaFactura` (#1, #3, #5), solo la parte `rpt`: igual.
- `rpt.CajaChica` (#8), confirmando con el contador que el reporte 22 no es soporte del 606.
- `EF-CAJA-CHICA` (#10): cambiar la SQL de la semilla (cambio de SQL, no de vista).
- Caja chica en la impresión (#15, línea 250): bajo riesgo; confirmar con el contador.
- `rptc.*` (#2, #4, #9): ya restringidas por `verdatospersonales`; sin cambio.

## Qué no encontré / no verifiqué
- El agente usó el ref local `origin/feature/modelo-ng` (`b4378650`) sin `git fetch`; puede ir atrasado.
- Búsqueda por texto, no lectura completa: en `ReportesSemilla.cs` solo se buscó `Rnc`, `Cedula`, `Identificacion`, `Pasaporte`, `TipoIdent` (no `NumeroDocumento` ni `Documento`); no se leyeron las demás semillas.
- **No leídos:** `ReportesVentasRegistrados.cs`, `ReportesInventarioRegistrados.cs`, `Definiciones/`, el diseñador de reportes (puede elegir cualquier columna: riesgo aparte), `Dashboard.razor`, `Tablero.razor`, `TablaReporte.razor`, `Reportes.razor`, `ConsultasTablero`, `ConsultasCaja`, `ConsultasCxc`, `ConsultasDocInventario`.
- No se leyeron en detalle los `ALTER VIEW` de `rpt.Recibo`, `ReciboPago`, `Compra`, `CxcDocumento`, `CxpDocumento`, `DocBanco` ni `Kardex` (solo `grep`: sin columnas de identificación).
- Hay dos definiciones de `rpt.ConsultaFactura` y tres de `Formato607`; no confirmé cuál está vigente tras las migraciones.
- No verifiqué privilegios de impresión, la asignación real de roles `gpos_reportes`/`gpos_lectura` ni quién ejecuta cada reporte de la semilla.
- No leí `ImpresionEndpoints`, `ReimpresionService`, `ExportadorReporte` ni `PlantillasRazor` completo; el mapeo de cada línea de `FabricaModelo` a cada tipo de documento es inferido.
- No leí `LEEME.md` completo ni las pruebas (`ContratoVistasTests`, `ModeloNg/*`), que podrían fijar reglas de enmascarado.

## Patrones de búsqueda usados (para auditar la ausencia)
- `git grep -n -i -E 'rnc|cedula|pasaporte|identificacion|TipoId|NumeroDocumento|TipoIdentificacion' origin/feature/modelo-ng -- database/*`
- `git grep -n -i -E 'Identificacion|\bRnc\b|Cedula|Pasaporte|TipoIdentificacion|TipoDe\b|IdentificacionCliente|IdentificacionProveedor|NumeroDocumento' -- database/ola5/ src/GPOS.Core/Datos/Empresa/Migraciones/VistasReportesOla5*.cs src/GPOS.Core/Data/Empresa/Vistas.cs`
- `git grep -n -o -i -E '(CREATE|ALTER) VIEW \[?rpt[a-z]*\]?\.\[?[A-Za-z0-9_]+' -- database/ src/GPOS.Core/Datos`
- `git grep -n -i -E 'Identificacion|\bRnc\b|Cedula|Pasaporte|RncReceptor|TipoIdent' -- src/GPOS.Contracts/Impresion src/GPOS.Api/Impresion src/GPOS.Core/Servicios/ImpresionDatosService.cs src/GPOS.Core/Consultas/Numeracion/ConsultasImpresion.cs src/GPOS.Core/Consultas/Ventas/ConsultasVentas.cs`
- `git grep -n -i -E 'Rnc|RNC|Identificacion|Cedula|Pasaporte|TipoIdent' -- src/GPOS.Core/Consultas src/GPOS.Web/Components/Pages/Ventas/ConsultaFacturas.razor src/GPOS.Web/Components/Pages/Admin/VerificarExportacion.razor src/GPOS.Core/Servicios/ConsultaFacturasService.cs src/GPOS.Core/Servicios/ReportesService.cs src/GPOS.Reportes/Consultas/Reportes src/GPOS.Reportes/Exportacion`
- `git grep -n -i -E 'enmascar|Identificacion|RncCedula|Cedula|Rnc' -- src/GPOS.Core/Sistema/ReportesSemilla.cs`
- `git grep -n -i 'verdatospersonales' -- src database/ola5/LEEME.md`
- `git grep -n -E 'TipoIdentificacion|TipoDe\(|RncCedula' -- src/GPOS.Core/Dominio/Fiscal/Registro606.cs src/GPOS.Core/Datos/Empresa/Configuracion/FisConfiguracion.cs src/GPOS.Core/Dominio/Maestros/Terceros.cs src/GPOS.Contracts/Fiscal src/GPOS.Reportes`
- Lectura de `contrato-vistas.v1.json` y de `database/ola5/LEEME.md` (líneas 145-170).

Contexto leído: `avisos/B-a-C/2026-10-22-respuesta-dorados-y-tareas-nuevas-2.md`, `traspasos/B/2026-10-22-revision-ddl-adr161.md` (M-5, A-1, TI-05, TI-08) y `traspasos/B/2026-10-22-respuesta-especialista-pos-tt.md` (1.3-1.4, `PuenteMae`, `GENERICO`).
