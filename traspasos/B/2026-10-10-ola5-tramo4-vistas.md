# Ola 5 · Tramo 4, bloque A: vistas de CxC, CxP, compras, banco y caja (contrato 1.3)

> **PARCIAL (pausa por orden del propietario, 2026-10-10).** Cuando llegó la pausa, los puntos 1 a 7 del encargo estaban escritos y probados. Falta una revisión final del texto antes de darlo por cerrado. La base `GPOS_TEST_T4VISTAS` ya se borró y no se lanzaron más consultas.

**Autor:** arquitecto-datos, equipo B · **Fecha:** 2026-10-10 · **Estado:** propuesta de diseño (no se editó ni se compiló ningún repositorio).
**Base verificada:** `feature/modelo-ng` `ec459d5` (árbol `GPOS-B-modelo-ng`, solo lectura); esquema del guion `database/empresa/gpos-empresa-20261010130522_BitacoraLogSoloInsercion.sql`.
**Firmas:** ADR-109 (P-2; Q-1 a Q-6 del 2026-10-10; cláusulas 3, 4 y 11), ADR-50, ADR-52 (RB-P1), RS-01 a RS-03.
**Plan:** `GPOS-NG-Equipos/traspasos/B/2026-10-10-plan-ola5-tramo4.md` (secciones 5.1, 5.2, 7.1 y 10).
**SQL:** `scratchpad/sql/ola5-tramo4/` (archivos citados como `00-…` a `90-…`).
**Leyenda:** [V] verificado (código, motor o ejecución); [I] inferido.

## Resumen (12 líneas)

1. Ocho vistas nuevas más `rptc.CajaChica` y `rptc.MovimientoCaja`: `rpt.CxcDocumento`, `rpt.CxpDocumento`, `rpt.Compra`, `rpt.DocBanco`, `rpt.CajaChica`/`rptc.CajaChica`, `rpt.MovimientoCaja`/`rptc.MovimientoCaja`, `rpt.CatTipoGasto` y `rpt.CatTermino`. Las probé en `GPOS_TEST_T4VISTAS`: dos aplicaciones seguidas, reversión y nueva aplicación sin errores [V].
2. Todas tienen columnas `*Base` redondeadas por fila. `banco.DocBanco.Tasa` existe (NOT NULL, `CK_DocBanco_Tasa`) [V].
3. Cédula abreviada en caja chica (Q-2): el largo es el tipo (9 = RNC íntegro; 11 = `*******` + 4).
4. Q-3: rol `O` o `H` en `rpt.CxcDocumento` y en la consulta de facturas, más la columna `NcfHistorico`.
5. Q-5: `Esperado` es NULL en `rpt.CierreCajaConteo`.
6. Q-4: los montos de `CIERRE` y de su reverso van en NULL en `rpt`.
7. Contrato 1.3, solo aditivo (3 líneas cambiadas y 1.666 agregadas), con huella `15E75340C3726390D565A166034B6E1B3A6DE1A9BC1FD3A742E237C08B8EB1CB`. V-D7 contra el motor: 53 vistas, 949 columnas, 0 diferencias [V].
8. `cxc.Cuenta.Tasa decimal(19,6) NOT NULL` sin DEFAULT, rellenada desde `ventas.Venta`: los cuatro orígenes de CxC la escriben [V]. Si falta, la migración se detiene (falla cerrada). Con 200.000 cuentas tarda 1,2 s [V].
9. Comparación de los 11 reportes: CxC (8, 9, 10, 27) y movimientos de caja (23) dan hoy 0 filas porque leen tablas heredadas; con las vistas dan los datos reales. Los demás coinciden fila por fila y ganan las columnas en moneda base. Diferencia en la tarjeta de CxC: 1.250 hoy (mezcla monedas) frente a 7.150 en moneda base.
10. Índices: `IX_Cuenta_ClienteVencimiento` incluye `Tasa` (+45 KB) y `IX_CajaMovimiento_Jornada` se amplía (+22 MB por 2 millones de filas): un día y una caja bajan de 430 ms a 4 ms. Todo cumple p95 < 2 s, salvo un mes sin caja con 2 millones de filas (3,6 a 4,4 s, < 30 s).
11. Migración `Ola5VistasTramo4`, después de la última migración de la rama. Choca solo en el *snapshot* y en el contrato (un solo editor). No comparte objetos con `Ola5AuditExportacion`, `Ola3bTransferencias` ni `NegativosTresNiveles`.
12. Dos preguntas para el propietario: el riesgo residual de RS-02 en `rpt.MovimientoCaja` (recomiendo aceptarlo y que lo revise el auditor) y el filtro por omisión «Hoy» del reporte 23 (recomendado).

---

## 1. Contexto y modelo de tenencia aplicado

- Base de datos por empresa (ADR-52/53). Las vistas son locales a la base de la empresa y viven también en el nodo, con el mismo esquema. No hay columna de tenencia.
- Aislamiento de lectura: el SQL del diseñador corre con `gpos_rpt_*` (rol `gpos_reportes`), que solo lee `rpt`. Las consultas registradas corren con `gpos_lec_*` (rol `gpos_lectura`), que lee `rpt` y `rptc`. Las tablas se leen por encadenamiento de propiedad (todo es de `dbo`, V-R1). No hace falta ningún permiso nuevo: `PermisosLecturaReportes.Sql` concede por esquema (`src/GPOS.Core/Datos/Empresa/Migraciones/PermisosLecturaReportes.cs:29-60`). Lo comprobé con usuarios sin login [V]:
  - `gpos_reportes` lee las vistas nuevas de `rpt`;
  - `gpos_reportes` recibe 229 en `rptc.CajaChica`, en `rptc.MovimientoCaja` y en `cxc.Cuenta`;
  - `gpos_lectura` lee `rptc` y recibe 229 en `caja.Movimiento`.
- Confirmo H-T4-01 [V, ahora ejecutado]: en una base del modelo nuevo, los reportes 8, 9, 10, 27 y 23 devuelven 0 filas aunque haya documentos, porque leen `vw_GPost_DocumentosCxC` y `Mov_Cajas` (`ReportesSemilla.cs:17-33` y `:320-331`). Ver `evidencia/salida-actuales.txt`.

## 2. Tablas y relaciones (vistas)

Reglas comunes, iguales que las de la ola 5:
- dueño `dbo` y `CREATE OR ALTER`;
- sin nombres de tres partes, pistas ni SQL dinámico;
- texto `varchar` (ADR-50);
- `SucursalId` y `SucursalCodigo` en toda vista de documento;
- `Estado IN (1, 2)` con la columna `Estado`;
- `rptc` = `rpt` + columnas al final.

DDL completo en `01-rpt-vistas-tramo4.sql`.

| Vista | Grano | Columnas clave (además de documento, sucursal y moneda) | Notas |
|---|---|---|---|
| `rpt.CxcDocumento` | `cxc.Cuenta` (FAC a crédito, ND, CHD, factura importada) | `FechaVencimiento`, `Cliente*`, `VendedorCodigo` y `ZonaCodigo` del cliente, `Tasa`, `Monto`, `Aplicado`, `Balance` (= `SaldoPendiente` sin transformar), `MontoBase`, `BalanceBase`, `Ncf varchar(50)`, `NcfHistorico` | NCF: `Rol IN ('O','H')` o, en la importada sin H, `ventas.Venta.Referencia` (CA-46) |
| `rpt.CxpDocumento` | `cxp.Cuenta` (FCP, NDP, CxP importada) | `Suplidor*`, `FacturaSuplidor`, `Tasa`, `Monto`, `Aplicado`, `Balance`, `MontoBase`, `BalanceBase`, `Ncf` | NCF = 606 recibido o B11 emitido (rol O), igual que en compras |
| `rpt.Compra` | `compras.Compra` de FCP, NDP, NCP y DVS | `Ncf`, `NcfModificado`, `TipoGasto*`, `Almacen*`, `Termino*`, `Signo` (NCP y DVS restan), montos y sus `*Base`, `NumeroOrigen` | Los reportes 13 y 14 filtran FCP. Incluir las notas no cuesta nada (seek por tipo) y sirve a los reportes del ADMIN |
| `rpt.DocBanco` | `banco.DocBanco` | `Clase`, `Signo`, `Cuenta*`, `NumeroCheque`, `Referencia`, `Suplidor*`, `Beneficiario`, `Concepto`, `TipoGasto*`, `Tasa`, `Monto`, `MontoDirecto`, `MontoBase`, `Caja*`, `NumeroOrigen` | `Monto` positivo y `Signo` aparte, como en la tabla |
| `rpt.CajaChica` | `caja.CajaChica` | `Caja*`, `Cajero`, `Beneficiario`, `IdentificacionEnmascarada`, `Concepto`, `Ncf`, `TipoGasto*`, `Monto`, `Itbis`, `MontoBase`, `ItbisBase`, porcentajes de retención | RS-01 y Q-2 |
| `rptc.CajaChica` | ídem | + `Identificacion` | `verdatospersonales`. Sin consumidor en la entrega 1 (Q-2); se crea para que el contrato no cambie en la entrega 2 (costo: una vista) |
| `rpt.MovimientoCaja` | `caja.Movimiento` | `Fecha` (= `FechaOperacion` de la jornada), `FechaRegistroLocal`, `Hora`, `RegistradoEn`, `Caja*`, `JornadaId`, `Cajero`, `Usuario`, `Tipo`, `TipoRevertido`, `EsCierre`, `Documento*`, `Motivo`, `Tasa`, `Monto`, `MontoBase` | Q-4: `Monto` y `MontoBase` en NULL si `EsCierre = 1` |
| `rptc.MovimientoCaja` | ídem | + `MontoCompleto`, `MontoCompletoBase` | `vercuadrecaja` |
| `rpt.CatTipoGasto`, `rpt.CatTermino` | fila del maestro | `Id`, `Codigo`, `Descripcion`, `Inhabilitado`, más `TipoBienServicio606` / `Dias` | L-27 a L-37 |

**Desvíos respecto del plan, con su motivo:**
1. **Sin `DiasVencido` en las vistas.** La regla vigente de las vistas prohíbe `SYSDATETIME()` y `SYSUTCDATETIME()`: «la fecha de hoy la pone la API» (`database/ola5/rpt-vistas-ventas-inventario.sql:39-40`). El SQL del diseñador sí la admite (`AnalizadorSql` no rechaza funciones del sistema) y la consulta actual de CxP ya la usa (`ReportesSemilla.cs:81`). Los días se calculan en la consulta de cada reporte (sección 4); el tablero (Q-1) recibe `@hoy` de `HoyEmpresa`. Ventaja: las vistas siguen siendo deterministas.
2. **Caja chica: el enmascarado lo decide el largo.** `caja.CajaChica` no guarda el tipo de identificación, pero `CK_CajaChica_Rnc` exige 9 u 11 dígitos, así que el largo equivale al tipo. Además, la columna se llama `IdentificacionEnmascarada` y no `RncCedulaEnmascarada`: la prueba de género exige que lo que empieza por `Rnc` termine en `-ado` (`ContratoVistasTests.cs:79-94`).
3. **Sin marca `Revertido` en `MovimientoCaja`.** Costaría una búsqueda por fila (la misma decisión que en el kárdex, revisión 3). El reverso es una fila propia con `TipoRevertido`.
4. **`Fecha` del movimiento = `FechaOperacion` de la jornada.** Es sargable a través de `caja.Jornada` y de `IX_CajaMovimiento_Jornada`, y coincide con el informe de caja. `RegistradoEn` no tiene índice, así que filtrar por la fecha de registro recorrería toda la tabla. La fecha y la hora de registro se exponen aparte.

## 3. Restricciones e integridad

- `cxc.Cuenta.Tasa decimal(19,6) NOT NULL` con `CK_Cuenta_Tasa (Tasa > 0)`, simétrica a `cxp.Cuenta`. **Sin DEFAULT**, a propósito: un `INSERT` que no la mande falla con el error 515 en lugar de tomar 1 en silencio. Ese era el riesgo de la alternativa descartada (derivarla en la vista). Guion: `00-cxc-cuenta-tasa.sql`.
- **Relleno [V]:** sale de `ventas.Venta.Tasa`. Los cuatro llamadores de `Partidas.RegistrarCuentaAsync` (`Partidas.cs:25`) crean `ventas.Venta` en la misma transacción:
  - ND (`CobrosService.cs:405-418`);
  - CHD (`:540-551`);
  - FAC (`DocumentosComercialesService.Ventas.cs:319`);
  - importación (`ImportacionesService.cs:452-459`).

  Con 200.000 cuentas, ninguna quedó distinta de su venta [V]. Si alguna cuenta no tiene `ventas.Venta`, `THROW 51399` y no se cambia nada (camino no ejecutado: no hay datos que lo provoquen).
- **RB-P1:** en la base va solo la invariante (`Tasa > 0`). La coherencia con `ventas.Venta` no lleva disparador: la garantiza la aplicación (un único `InsertarCuenta`, `ConsultasCxc.cs:14`) y la vigila una prueba de base (sección 7, prueba T-3).
- Grano: el `LEFT JOIN fiscal.Comprobante … Rol IN ('O','H')` devuelve como máximo una fila, porque 51420 de H-2 impide O y H en el mismo documento (`a/h2-ncf-historico`, `SqlMigracionesH2.cs`). Hoy `CK_Comprobante_Rol` solo admite O y R, así que `'H'` no devuelve filas. El texto vale antes y después de H-2 [V].

## 4. Consultas de los 11 reportes y comparación con la versión actual

El SQL propuesto está en `21-consultas-nuevas.sql` (bloques N1 a N7) y las consultas actuales, extraídas sin tocar de `ReportesSemilla.cs`, en `20-consultas-actuales.sql`. Mismos datos de prueba (`10-datos-prueba.sql`: 22 documentos con pesos, dólares, anulados, una importada, un cierre Z y su reverso), con hoy = 2026-10-10. Salidas en `evidencia/salida-actuales.txt` y `evidencia/salida-nuevas.txt`. Todas se ejecutaron también como `gpos_reportes` [V].

| N.º | Reporte | Consulta nueva (fuente) | Actual frente a nueva | Explicación |
|---|---|---|---|---|
| 8 | `CXC-ANTIGUEDAD` | N1 `rpt.CxcDocumento` con `Estado = 1 AND Balance > 0`; tramos en moneda base | **0 filas → 4 filas** | Lee la vista heredada (vacía). Las 4 cuentas con saldo: FC1 600; FC2 US$ 100 = 6.000 en moneda base; la importada HIST-0099 250, con NCF B0100009999 (`NcfHistorico = 1`); ND1 300. Quedan fuera el CHD con saldo 0 y la factura anulada |
| 9 | `CXC-ANTIGUEDAD-RESUMEN` | N1 agrupado por cliente: solo `BalanceBase` y tramos (SUMA) | 0 → 2 clientes | Ídem. Se quita la suma de `Balance` en la moneda del documento, que sumaría pesos con dólares (H-T4-03) |
| 10 | `CXC-ESTADO-CUENTA` | N1 con el cliente obligatorio | 0 → filas del cliente | Ídem. Q-3: la columna NCF pasa a visible |
| 27 | `DASH-CXC-ANTIGUEDAD` | N1: `Rango` y SUMA de `BalanceBase` | 0 → 4 tramos | Ídem |
| 13 | `CXP-FACTURAS` | N2 `rpt.Compra` con `TipoCodigo = 'FCP' AND Estado = 1` | 3 = 3 filas, mismos valores | Agrega `TotalBase`: FP2 US$ 200 = 11.700. Hoy el total sumaba 2.080 «mezclado»; ahora 13.580 en moneda base |
| 14 | `CXP-POR-SUPLIDOR` | N2 agrupado: `SubTotalBase`, `ItbisBase` y `TotalBase` (SUMA) | Mismos documentos | Totales en moneda base |
| 15 | `CXP-ANTIGUEDAD` | N3 `rpt.CxpDocumento` con `Estado = 1 AND Balance > 0` | 3 = 3 filas | **NCF de FP2:** hoy NULL (solo lee el 606); ahora B1100000001 (B11 emitido, rol O), igual que el reporte 13. Tramos en moneda base: FP2 US$ 50 = 2.925 |
| 16 | `CXP-PAGOS` | N5 = N4 con `SuplidorId IS NOT NULL` | 2 = 2 | Agrega `MontoBase`: TRB1 US$ 150 = 9.000 |
| 21 | `EF-DOCS-BANCARIOS` | N4 `rpt.DocBanco` con `Estado = 1` | 3 = 3 | Ídem. `Monto` sin signo, como hoy |
| 22 | `EF-CAJA-CHICA` | N6 `rpt.CajaChica` con `Estado = 1` | 2 = 2 | **RNC:** la cédula 00112345678 → `*******5678` (Q-2). El RNC 130123456 queda íntegro. `MontoBase`: CC2 US$ 10 = 600. NCF con rol O explícito (antes, `TOP (1)` sin rol ni orden) |
| 23 | `EF-MOV-CAJA` | N7 `rpt.MovimientoCaja` | **0 filas → 8 filas** | Lee `Mov_Cajas` (heredado). «Origen» con las etiquetas de `CierresCaja.DescripcionOrigen` (`Negocio/Comun.cs:113-128`), «Documento» = número o motivo. Retiro por cierre Z y «Cierre Z anulado» con ingreso y egreso en NULL (Q-4) |
| Tarjeta | CxC (Q-1) | N8: `SUM(BalanceBase)` de `rpt.CxcDocumento` | **1.250 → 7.150** | Hoy suma `SaldoPendiente` sin tasa (`ConsultasTablero.cs:43-49`). Coincide exactamente con el total del reporte 9 |

**Columnas propuestas para la semilla** (las escribe desarrollador-backend; se conservan los nombres de campo que usan los enlaces, `ReportesSemilla.cs:515-523`):
- **8, 10 y 15:** `MontoDocumento("Balance", "Balance")` y `Monto("BalanceBase", "Balance (moneda base)")`. Los tramos son `Monto(..., "Corriente (moneda base)")`, etc., totalizados. En el 10, además, `Monto`, `Aplicado` y `Balance` como `MontoDocumento`, y NCF visible. En el 8, `NCF` opcional.
- **9 y 27:** solo `BalanceBase` y los tramos, con SUMA.
- **13:** `SubTotal`, `Itbis` y `Total` como `MontoDocumento`; `TotalBase` totalizado. Opcionales: `SubTotalBase`, `ItbisBase`, `Descuento`, `Tasa`, `Almacen` y `Termino`.
- **14:** SUMA de las tres columnas `*Base`.
- **16 y 21:** `Monto` como `MontoDocumento` y `MontoBase` totalizado.
- **22:** etiqueta «RNC o cédula»; `Monto` e `Itbis` como `MontoDocumento`; `MontoBase` e `ItbisBase` totalizados; `Moneda` opcional.
- **23:** `Moneda` visible; `Ingreso` y `Egreso` como `MontoDocumento`; `IngresoBase` y `EgresoBase` totalizados; `Usuario` opcional; filtro por omisión «Hoy» (pregunta Q-T4D-02).

## 5. Índices y consultas que los justifican

Volumen del cliente grande (`30-volumen.sql`):
- 200.000 cuentas por cobrar (5.000 con saldo; 10 % en US$);
- 200.000 cuentas por pagar (5.000 con saldo);
- 20 cajas × 30 días = 600 jornadas;
- 2.000.000 de movimientos de caja.

Forma del diseñador: `WITH gpos_base AS (…)` con página de 500 o totales, y parámetros tipados (`31-medicion.sql`). SQL Server 2025 Express en el equipo del propietario, en caliente. El tiempo es el mínimo y el máximo de 3 pasadas. Las cifras son de esta máquina [V], y en el servidor del cliente pueden variar ±50 % [I].

| Caso | Sin cambio de índices | Con los índices propuestos |
|---|---|---|
| M1 antigüedad CxC, página 500 | 137 a 336 ms | 134 a 218 ms |
| M2 totales CxC = tarjeta | 107 a 194 ms; `cxc.Cuenta` 1.765 lecturas | 105 a 184 ms; **30 lecturas** |
| M3 estado de cuenta de un cliente | 0 a 42 ms | 6 a 7 ms |
| M4 totales CxP | 135 a 233 ms | 127 a 232 ms |
| M5 compras de un mes, totales | 62 a 221 ms | 63 a 124 ms |
| M6 movimientos de un mes y una caja, página | 582 a 1.037 ms | 583 a 1.040 ms (recorre el agrupado: la página pide `Usuario`, `Motivo` y `DocumentoId`) |
| M7 movimientos de un mes y una caja, totales | 554 a 1.029 ms | **154 a 293 ms** |
| M8 movimientos de un mes sin caja (2 millones de filas), totales | 4.011 a 5.205 ms | 3.648 a 4.430 ms |
| M9 movimientos de un día y una caja, totales | 430 a 450 ms (recorrido de 26.793 páginas) | **4 a 7 ms** |

**Índices:**
1. **`IX_Cuenta_ClienteVencimiento` (filtrado `SaldoPendiente > 0`) agrega `Tasa` a su INCLUDE.**
   - Consultas que atiende: tarjeta de CxC y totales de los reportes 8, 9, 10 y 27.
   - Efecto: las lecturas de `cxc.Cuenta` bajan de 1.765 a 30. El tiempo baja solo de 227 a 209 ms, porque domina `doc.Documento` (2.459 lecturas).
   - Costo: 9 B × 5.000 filas ≈ 45 KB. Cero en escritura: `Tasa` no cambia después del `INSERT`.
   - Se reconstruye con `DROP_EXISTING`, en < 0,2 s [V].
2. **`IX_CajaMovimiento_Jornada (JornadaId)` amplía su INCLUDE a `(Tipo, MonedaId, Monto, Tasa, SucursalId, MovimientoRevertidoId, RegistradoEn)`** (`03-indice-movimiento-caja.sql`).
   - Consultas que atiende: totales del reporte 23 por día o mes y caja (M7, M9), y el cuadre de la jornada, que ya lo usa.
   - Costo: de 109 a 131 MB con 2 millones de filas (≈11 B por fila). `caja.Movimiento` es de solo inserción. Creación: 2,5 s con 2 millones de filas, OFFLINE en Express y Standard (bloquea las inserciones de caja mientras dura) → ventana de la migración. Un cliente típico (≈100.000 movimientos al año) lo crea en < 0,2 s [I].
   - Opción para la revisión de A (sin medir): fundirlo con `IX_Movimiento_JornadaId_SucursalId` (73 MB, el índice de convención de EF para la FK compuesta) con claves `(JornadaId, SucursalId)`. El neto sería −51 MB respecto de hoy, pero exige cambiar `HasIndex` en `CajConfiguracion`.
3. **Ningún índice por `SaldoPendiente > 0` adicional** (lo pedía la sección 10 del plan): los filtrados de CxC y CxP ya existen. **Ninguno por `RegistradoEn`:** el filtro va por la jornada.
4. **M8 (mes sin caja, 2 millones de filas) no cumple p95 < 2 s.** Queda en 3,6 a 4,4 s, dentro del límite de 30 s. Mitigación sin índice: filtro por omisión «Hoy» en el reporte 23 (Q-T4D-02). Para el uso típico, un día y una caja, la consulta tarda 4 ms.

## 6. Auditoría y trazabilidad

Las vistas no escriben. `audit.Exportacion` es de `b/ola5-auditoria` (no se toca). `rpt.Empresa` sigue igual para el encabezado de evidencia. Sin cambios en `_LOG`.

## 7. Persistencia de sincronización

No aplica en la entrega 1. En el nodo (entrega 2), `cxc.Cuenta.Tasa` viaja con la cuenta: la columna es NOT NULL, así que el paquete de sincronización que la cree debe traerla [I: el diseño del nodo aún no existe].

**Pruebas que se proponen** (las escribe QA o desarrollador-backend):
- **T-1, V-D7 con la 1.3:** reproducida en `evidencia/vd7.ps1`, con 0 diferencias.
- **T-2, prueba estática:** superconjunto `rptc`, privilegios y género. Reproducida: 0 errores y 13 pares.
- **T-3:** `cxc.Cuenta.Tasa = ventas.Venta.Tasa` en toda cuenta.
- **T-4:** `SUM(rpt.CxcDocumento.BalanceBase)` = tarjeta = total del reporte 9.
- **T-5:** en caja chica, el RNC de 9 dígitos íntegro y la cédula enmascarada en `rpt`; completa en `rptc`.
- **T-6:** `EsCierre = 1` deja `Monto` en NULL en `rpt` y lo trae en `rptc.MovimientoCaja.MontoCompleto`, también en el reverso.
- **T-7:** `Esperado` es NULL en todo `rpt.CierreCajaConteo`.
- **T-8:** grano de `rpt.CxcDocumento` y de `rpt.ConsultaFactura` con un comprobante H (después de H-2).

## 8. Script de migración y reversión (`Ola5VistasTramo4`)

**Orden de `Up`** (una migración de EF, generada después de la última migración de la rama al construir):
1. `AddColumn<decimal>("Tasa", "cxc", "Cuenta", "decimal(19,6)", nullable: true)`.
2. `Sql(SqlMigraciones.Ola5Tramo4RellenoTasa())`: va en `EXEC(N'…')`, porque la columna nace en el mismo lote. Incluye la falla cerrada 51399 y el `UPDATE` desde `ventas.Venta`.
3. `AlterColumn` a `nullable: false` (sin `defaultValue`).
4. `AddCheckConstraint("CK_Cuenta_Tasa", "Tasa > 0")`.
5. Los dos índices con `Sql(... WITH (DROP_EXISTING = ON))`, en lugar del par `DropIndex`/`CreateIndex` que genera EF, para no quedar sin índice. El modelo declara `IncludeProperties` para que el *snapshot* coincida.
6. `Sql(SqlMigraciones.Ola5VistasTramo4())`:
   - comprobación V-R1 con `THROW 51399`;
   - las vistas en `EXEC`, con el texto generado sin comentarios. Ojo: los comentarios previos al `CREATE` quedan guardados en `sys.sql_modules`, lo vi en la prueba;
   - `rpt.VersionContrato` con la huella de la 1.3;
   - `PermisosLecturaReportes.Sql`.

**`Down`** (`90-reversion.sql`, probado [V]):
1. Borra las 10 vistas nuevas.
2. Repone `rpt.CierreCajaConteo`, `rpt.ConsultaFactura`, `rptc.ConsultaFactura` y `rpt.VersionContrato` con su texto de `VistasReportesOla5.Vistas`, buscado por nombre. El contrato vuelve a la 1.2: tras revertir, la huella leída es la de la 1.2.
3. Devuelve los índices a su forma anterior.
4. Quita el CHECK y la columna.

No hay pérdida de datos: la tasa sigue en `ventas.Venta`.

**Idempotencia [V]:** aplicar → aplicar → revertir → aplicar → aplicar, sin errores. Con 200.000 cuentas, la segunda aplicación de la tabla tarda 0,23 s (no hace nada).

**Integración en la rama** (desarrollador-backend):
- Script de diseño nuevo `database/ola5/rpt-vistas-tramo4.sql`, a partir de `01-…`. El de la ola 5 no se edita: `MigracionOla5VistasTests` exige que `VistasReportesOla5` sea igual a su script.
- Clase generada `VistasReportesOla5Tramo4.cs`.
- `ContratoVistasTests`:
  - leer la unión de los dos scripts, de modo que la redefinición del tramo 4 sustituya a la de la ola 5;
  - tomar la huella del script del tramo 4.
- Un `MigracionOla5Tramo4VistasTests` análogo.
- Mismo cambio, sin falta: `ConsultasCxc.InsertarCuenta` y `Partidas.RegistrarCuentaAsync(…, decimal tasa, …)` en los 4 llamadores, y `CuentaCxc.Tasa` con `HasPrecision(19, 6)` y el CHECK en `CxcConfiguracion`.
- El contrato 1.3 está listo en `scratchpad/sql/ola5-tramo4/contrato-vistas.v1.json`, con LF y sin BOM.

**Choques:**

| Rama / migración | Qué toca | Choque con el tramo 4 |
|---|---|---|
| `b/ola5-auditoria` · `20261010171353_Ola5AuditExportacion` | `audit.Exportacion`, `audit.ExportacionCierre`, `audit.ExportacionEstado`, procedimientos y DENY a `gpos_app` | Solo el *snapshot* y el orden de las marcas de tiempo. Ningún objeto en común. `audit` ya existe, así que el DENY generado de los roles de lectura la cubre |
| `b/ola3b` · `20261010172413_Ola3bTransferencias` | `inv.*` de tránsito, `CK_Movimiento_Clase`, `conf.Parametros` y 4 vistas `rpt`/`rptc` de tránsito fuera del contrato | *Snapshot* y contrato: la 3b rebasa sobre la 1.3 y publica la 1.4 con la huella recalculada (un solo editor, R-2). Las vistas de la 3b quedan legibles por permiso de esquema. Ningún objeto en común |
| `b/adr118-119-t1` · `20261010153018_NegativosTresNiveles` | `inv.PoliticaNegativa*`, `inv.RevisionLote`, `cat.Articulo.PermiteNegativa`, `conf.Parametros` | Solo el *snapshot*. `rpt-vistas-negativos-tras-t1.sql` cambia `rpt.NegativoPorRegularizar` sin cambiar columnas (no toca el contrato) |
| `a/h2-ncf-historico` (A) · `H2ComprobanteHistorico`, H3, H4 | Rol H en `CK_Comprobante_Rol`, `rpt.Formato608` sin H, `rpt.NcfHistoricoIncidencia` | Compatible: las vistas ya usan `IN ('O','H')`. **Observación para A:** `rpt.NcfHistoricoIncidencia` queda en `rpt` y la lee `gpos_reportes` por el permiso de esquema, pero no está en el contrato. Conviene registrarla en una versión 1.x o moverla fuera de `rpt`. La guarda de H-2 debe incluir las 10 vistas nuevas |

Regla de unión: quien una segundo regenera su migración (marca de tiempo nueva) y el *snapshot*. El tramo 4 no depende del esquema de ninguna de las cuatro ramas.

## 9. Respaldo, restauración y retención

Sin cambios: las vistas no guardan datos. La migración no exige respaldo previo propio (se puede revertir sin pérdida), pero corre con la API detenida, como toda migración de `GPOS.Migracion`.

## 10. Privilegios de base de datos

Sin roles ni concesiones nuevas.
- `gpos_reportes`: `SELECT` sobre `rpt`.
- `gpos_lectura`: `SELECT` sobre `rpt` y `rptc`.
- DENY generado sobre todo esquema de tablas.
- La migración corre con el login de migración, nunca con `gpos_app`, `sa` ni `gsf` (RG-14 sigue abierto en A).

## 11. Riesgos

| # | Riesgo | Prob. / impacto | Mitigación |
|---|---|---|---|
| R-D1 | `ALTER COLUMN` y la creación de índices toman Sch-M y bloquean la venta a crédito y la caja mientras duran | Cierta / bajo: 1,2 s + 2,5 s con el volumen del cliente grande | Migración con la API detenida |
| R-D2 | Un origen nuevo de CxC sin tasa | Baja / medio | NOT NULL sin DEFAULT (error 515 inmediato), prueba T-3 |
| R-D3 | **RS-02 residual:** en una jornada **abierta**, sumar `rpt.MovimientoCaja` da el esperado del efectivo antes del conteo ciego | Media / medio | Pregunta Q-T4D-01; revisión del auditor-seguridad |
| R-D4 | Huella: la API de reportes trae el contrato 1.3 y una base aún en 1.2 → «pendiente» en los registrados (`LectorRegistradas.cs:137`) | Baja / bajo | Migrar antes de arrancar la API (orden actual del agente de actualización) |
| R-D5 | Crecimiento de `IX_CajaMovimiento_Jornada` en Express (límite de 10 GB) | Baja / bajo: ≈1 MB al año en un cliente típico; 264 MB al año en el cliente extremo, que estaría en Standard | Fusionar con el índice de la FK (sección 5) |
| R-D6 | Observación aparte (Baja, fuera del tramo): el balance del cliente en `MaestrosService.cs:66-79` también suma `SaldoPendiente` sin tasa | — | Con `Tasa` ya en la tabla, cuesta una línea. Va a backend |

## 12. Preguntas para el propietario

| # | Pregunta | Opciones | Recomendación | Qué rompe / costo |
|---|---|---|---|---|
| **Q-T4D-01** | El reporte 23 (movimientos de caja, en `rpt`) deja calcular, sumando, el efectivo esperado de una jornada **abierta**, antes del conteo ciego (RS-02). Q-4 oculta lo declarado, pero no evita esa suma. | **A.** Se acepta: la caja abierta se ve, el área «efectivo» de reportes no se asigna a los cajeros y lo revisa el auditor-seguridad. **B.** `rpt.MovimientoCaja` solo muestra jornadas cerradas; las abiertas, solo en `rptc` | **A.** Con B, el supervisor deja de ver en el 23 los movimientos del día, porque el 23 es del diseñador y solo lee `rpt`. B cuesta 0,02 sp | A: nada cambia. B: el 23 no muestra la caja abierta |
| **Q-T4D-02** | Filtro de fecha por omisión del reporte 23 | **A.** «Hoy». **B.** «Mes actual», como hoy | **A.** Un mes sin caja con 2 millones de movimientos tarda 3,6 a 4,4 s (más que el p95 de 2 s); un día y una caja, 4 ms | A: el reporte abre con el día y el usuario amplía el rango. Sin costo |

---

### Cierre
- **Estado:** Completado. Es diseño: la construcción y la firma de las preguntas quedan pendientes.
- **Artefactos** (en `scratchpad\`):
  - este documento, `ola5-tramo4-vistas.md`;
  - en `sql\ola5-tramo4\`: `00-cxc-cuenta-tasa.sql`, `01-rpt-vistas-tramo4.sql`, `02-permisos-lectura.sql`, `03-indice-movimiento-caja.sql`, `10-datos-prueba.sql`, `20-consultas-actuales.sql`, `21-consultas-nuevas.sql`, `30-volumen.sql`, `31-medicion.sql`, `90-reversion.sql` y `contrato-vistas.v1.json` (1.3);
  - en `sql\ola5-tramo4\evidencia\`: `salida-actuales.txt`, `salida-nuevas.txt`, `vd7.ps1`, `build-contrato.ps1` y `rehacer-base.sh`.

  La base `GPOS_TEST_T4VISTAS` se creó y se borró.
- **Supuestos:**
  - tiempos en caliente en el equipo de desarrollo, ±50 % en el servidor del cliente;
  - `RegistradoEn` en UTC (`ConsultasCaja.cs:110`);
  - la falla cerrada del relleno no se ejecutó, porque no hay datos que la provoquen;
  - `origenEsquema` del contrato no se actualizó (cambiarlo solo cambia la huella).
- **Decisiones candidatas a ADR:** ninguna nueva. `cxc.Cuenta.Tasa` es una precisión de datos de P-5 que el plan deja en manos del arquitecto-datos; Q-4 y Q-5 ya están firmadas.
- **Entregas a otros agentes:**
  - **desarrollador-backend:** migración `Ola5VistasTramo4`, script y clase generada, ajuste de `ContratoVistasTests`, `InsertarCuenta` y los 4 llamadores con tasa, mapeo de EF, semilla (sección 4), tarjeta CxC/CxP sobre `rpt` y R-D6;
  - **auditor-seguridad:** RS-01 por largo en caja chica, Q-4 con el reverso, R-D3 y `rpt.NcfHistoricoIncidencia`;
  - **A (revisión del núcleo):** `cxc.Cuenta.Tasa`, índices, la opción de fusionar el índice de la FK, la guarda de H-2 y la vista de incidencias;
  - **QA:** F9 sobre las vistas, pruebas T-1 a T-8 y medición en el hardware del piloto;
  - **diseñador UX:** «RNC o cédula» y el filtro «Hoy» del 23.
- **Próximo paso recomendado:** que el propietario responda Q-T4D-01 y Q-T4D-02, y que desarrollador-backend arranque la migración el 15-oct con este SQL.
