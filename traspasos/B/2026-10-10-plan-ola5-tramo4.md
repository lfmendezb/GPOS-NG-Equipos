# Ola 5 · Tramo 4 de la API de reportes (ADR-109): plan de diseño

**Autor:** arquitecto de software, equipo B · **Fecha:** 2026-10-10 · **Base verificada:** `feature/modelo-ng` `ec459d5` (árbol `GPOS-B-modelo-ng`, solo lectura) · **Estado:** propuesta, pendiente de que el propietario responda las preguntas de la sección 11.
**Firmas en las que se apoya:** ADR-109 (P-1 a P-5, E1, UX-V-01 a 08, precisiones de las cláusulas 4, 5 y 8), ADR-110, ADR-111 (cláusula 7, evidencia), ADR-113 (PF-01 a PF-06: «Por despachar» en la entrega 1, anillos), ADR-125 (C-01 a C-04 y E-07), ADR-52 (RB-P1).
**Leyenda:** [V] verificado en el código o en un documento citado; [I] inferido.

---

## 1. Contexto y alcance

### 1.1 Por qué el tramo 4 es una condición de publicación
- P-2 (ADR-109, nota del 2026-10-10): los reportes 8 a 10, 13 a 16, 21 a 23 y 27 siguen en la principal hasta tener vista, y **no se publica al cliente hasta vaciar la lista**. La lista es `ReportesSemilla.EnLaPrincipal` (`src/GPOS.Core/Sistema/ReportesSemilla.cs:136-140`) [V], con 11 códigos:

| N.º | Código | Hoy lee | Problema |
|---|---|---|---|
| 8 | `CXC-ANTIGUEDAD` | `vw_GPost_DocumentosCxC`, `Clientes`, `Sucursales` (heredado) | Ver hallazgo H-T4-01 |
| 9 | `CXC-ANTIGUEDAD-RESUMEN` | ídem | ídem |
| 10 | `CXC-ESTADO-CUENTA` | ídem | ídem |
| 13 | `CXP-FACTURAS` | `compras.Compra`, `doc.Documento`, `fiscal.*` (tablas) | Corre con la credencial de escritura |
| 14 | `CXP-POR-SUPLIDOR` | ídem | ídem |
| 15 | `CXP-ANTIGUEDAD` | `cxp.Cuenta` y tablas | ídem |
| 16 | `CXP-PAGOS` | `banco.DocBanco` y tablas | ídem |
| 21 | `EF-DOCS-BANCARIOS` | ídem | ídem |
| 22 | `EF-CAJA-CHICA` | `caja.CajaChica`, `fiscal.*` | ídem; además muestra la cédula completa (`g.RncCedula`) a cualquiera con el área |
| 23 | `EF-MOV-CAJA` | `Mov_Cajas`, `Sucursales` (heredado) | Ver H-T4-01 |
| 27 | `DASH-CXC-ANTIGUEDAD` | igual que 8 | ídem |

(Consultas en `ReportesSemilla.cs:17-33`, `:63-115`, `:303-331` [V].)

### 1.2 Hallazgos que cambian el alcance
- **H-T4-01 (Alta) [V+I].** Los reportes 8, 9, 10, 27 y 23 leen el esquema heredado (`vw_GPost_DocumentosCxC`, `Clientes`, `Sucursales`, `Mov_Cajas`). En `feature/modelo-ng` esas tablas solo existen por la convivencia H-03 (`Aprovisionamiento.cs:108-112`, `EsquemaHeredado`) [V] y los documentos nuevos escriben `cxc.Cuenta` (`Partidas.cs:40`) y `caja.Movimiento` [V]. Por eso, **hoy esos cinco reportes muestran datos viejos o vacíos** [I: no ejecutado], y en una base creada sin el esquema heredado fallan con «nombre de objeto no válido» [I]. No es solo un traslado de credencial: se reescriben sobre el modelo nuevo.
- **H-T4-02 (Media) [V].** La tarjeta «Cuentas por cobrar» suma `cxc.Cuenta.SaldoPendiente` sin tasa (`ConsultasTablero.cs:45-49`), así que mezcla monedas. `cxc.Cuenta` no tiene `Tasa` (guion de empresa `gpos-empresa-20261010130522_BitacoraLogSoloInsercion.sql:3158-3171`), a diferencia de `cxp.Cuenta`, que sí la tiene (`ConsultasTablero.cs:57`).
- **H-T4-03 (Media) [V].** Las definiciones de CxC, CxP y banco totalizan `Monto` y `Balance` en la moneda de cada documento (`ReportesSemilla.cs:200-275`, `Monto(...)` con `Totalizar: true`): suman pesos con dólares. Contradice la regla de monedas del tramo 3 (solo se totaliza lo `*Base`; comentario en `ReportesSemilla.cs:35-37`).
- **H-T4-04 (Media) [V].** El tablero (`/api/reportes/dashboard/indicadores`) sigue en la principal con su conexión de escritura (`ReportesEndpoints.cs:66-68`, `DashboardService.cs:45`), aunque la cláusula 1 pone el tablero en la API de reportes. No está en la lista P-2 y no bloquea la publicación según la letra de P-2, pero sí la conformidad con la cláusula 1. Va a la pregunta Q-1.
- **H-T4-05 (Baja) [V].** La prueba F9 afirma que un reporte P-2 «sigue en la principal» (`tests/GPOS.Tests/Mvp/ReportesF9Tests.cs:267-269`) y `T3_02_...` depende de que `CXP-PAGOS` esté en la lista (`:277-283`). Al vaciar la lista hay que reescribir las dos.

### 1.3 Alcance cerrado

**Dentro (condición de publicación: bloque A):**
1. Vistas `rpt`/`rptc` de los 11 reportes P-2 y contrato de vistas 1.3.
2. Reescritura de las 11 definiciones sobre `rpt`, con totales en moneda base, y la lista `EnLaPrincipal` vacía. También se retira el camino `IntactoEnLaPrincipal` / `EnLaPrincipalAsync`.
3. Tarjeta de CxC en moneda base.
4. `GET /api/reportes` que no cae entera si la API de reportes no responde (sección 5.3).
5. Contratos C-3 a C-6 del visor.
6. Guarda del rol H de H-2 en toda vista que lee `fiscal.Comprobante`.
7. T3-10: `rpt.CierreCajaConteo` sin cifras del cuadre para quien no tiene el privilegio.
8. Registro en `audit.Exportacion` desde la principal en cuanto exista la tabla (ADR-111, cláusula 7; D-02).

**Dentro (antes del corte, no bloquean la publicación: bloque B):**
9. Pendientes de interfaz del visor:
   - Enter y Esc;
   - filas con detalle accesibles por teclado;
   - teléfono (100 filas, UX-V-02);
   - restaurar la página y el orden al volver de un detalle.
10. Reportes de la entrega 1 de RPV:
    - C-01 a C-04 y E-07 (vistas nuevas `rpt.LoteVencimiento` y `rpt.AutorizacionDetalle`);
    - E-01 y E-04 (anillo 1 de «Por despachar»);
    - **recortables:** E-02, E-03 y E-06 (anillo 2, salen el 20-nov si no caben, PF-06).
11. Registro en el contrato de las vistas de tránsito de la 3b (`rpt.TransitoArticulo`, `rptc.TransitoArticulo`, `rpt.ConciliacionTransito`, `rpt.ConciliacionTransferenciaAbierta`) y la etiqueta «Diferencia de transferencia» de la clase 8 en `rpt.Kardex`.

**Fuera:**
- Antigüedad a una fecha de corte pasada: los reportes 8, 9, 15 y 27 siguen con el saldo de hoy, como ahora.
- Estado de cuenta con movimientos (recibos y notas intercalados). El 10 conserva su semántica actual: documentos con balance de un cliente obligatorio.
- Vistas canónicas X-02 a X-06 de la 3b (después del corte, según el plan de la 3b, 4.3).
- Canal externo (cláusula 14).
- Formatos 606, 607 y 608 (RS-04, aplazados).
- Cifrado en reposo de la cédula (RS-05).
- Retiro del Razor del SUPER.

---

## 2. Módulos y dependencias

Sin módulos ni proyectos nuevos. Cambian:

| Proyecto | Cambio | Dependencias (sin cambios; sin ciclos) |
|---|---|---|
| `GPOS.Core` | Migración `Ola5VistasCxcCxpCaja` (después de `BitacoraLogSoloInsercion`), texto de las vistas en `VistasReportesOla5Tramo4.cs` (una clase nueva; `VistasReportesOla5.cs` no se edita, según su encabezado `:5`). Semilla: definiciones reescritas, `EnLaPrincipal` vacía y eliminada. Tablero: tarjeta de CxC | `GPOS.Contracts`, `GPOS.Comun` |
| `GPOS.Contracts` | `contrato-vistas.v1.json` versión 1.3; `ReporteColumnaDto.Ordenable` (C-5); campo aditivo `privilegios` del problema (C-3) | — |
| `GPOS.Reportes` | Metadatos `totalesEstado`, `profundidad` y `datosPersonales` (C-4 a C-6); variante `rpt`/`rptc` de caja chica | `GPOS.Comun`, `GPOS.Contracts` (no `GPOS.Core`, cláusula 1) |
| `GPOS.Reportes.Api` | Mensaje de `PRIVILEGIO_REQUERIDO` (C-3) | ídem |
| `GPOS.Api` | Lista de reportes en la principal (5.3); registro en `audit.Exportacion`; retiro del reenvío selectivo | `GPOS.Core` |
| `GPOS.Web`, `GPOS.UI.MAUI` | Visor (bloque B) | `GPOS.Contracts` |

La prueba de arquitectura que ya impide que `GPOS.Reportes*` referencie `GPOS.Core` sigue vigente; no se agrega ninguna referencia.

## 3. C4

No aplica un diagrama nuevo: los contenedores (principal, API de reportes, canalizaciones de introspección y de exportación, SQL Server) no cambian respecto del tramo 3. Cambia un flujo, el de la lista, en la sección 5.3.

## 4. Modelo de dominio

No cambia el dominio. Solo hay una regla de lectura nueva: el saldo en moneda base de una cuenta por cobrar es `ROUND(SaldoPendiente × Tasa del documento, 2)`. Es la misma regla de P-5 y la que ya usa la CxP.

---

## 5. Contratos

### 5.1 Vistas nuevas (contrato de vistas 1.3, aditivo; `VersionMinima` sigue en 1.0)

Reglas comunes, iguales que las del tramo 3:
- dueño `dbo`;
- sin nombres de tres partes;
- fechas `date` del documento;
- códigos y nombres de los maestros, para que el SQL del diseñador no necesite tablas;
- columnas `*Base` redondeadas por fila, para que el total sea la suma exacta de las filas (como P-4);
- texto `varchar` (ADR-50);
- `SucursalId` y `SucursalCodigo` en toda vista de documento (D-03);
- ningún índice nuevo sin la medición de la sección 8.

| Vista | Grano | Columnas principales | Fuente | Privilegio |
|---|---|---|---|---|
| `rpt.CxcDocumento` | Cuenta por cobrar (`cxc.Cuenta`) de un documento emitido (`Estado = 1`) | `DocumentoId`, `Numero`, `TipoCodigo`, `Fecha`, `FechaVencimiento`, `DiasVencido` (hoy de la empresa, UTC−4, igual que `SaldosCxp`), `ClienteId`, `ClienteCodigo`, `ClienteNombre`, `VendedorCodigo` y `ZonaCodigo` del cliente (los del reporte actual), `MonedaCodigo`, `Tasa`, `Monto`, `Aplicado`, `Balance`, `BalanceBase`, `Ncf`, `SucursalId`, `SucursalCodigo` | `cxc.Cuenta`, `doc.Documento`, `doc.TipoDocumento`, `cat.Cliente`, `cat.Moneda`, `org.Sucursal`, `fiscal.Comprobante` (rol según Q-3) | `rpt` (sin identificación) |
| `rpt.CxpDocumento` | Cuenta por pagar (`cxp.Cuenta`) de un documento emitido | Las mismas que `CxcDocumento`, con `Suplidor*` y `FacturaSuplidor`; `Ncf` de `fiscal.Registro606` | `cxp.Cuenta`, `compras.Compra`, `fiscal.Registro606`, maestros | `rpt` |
| `rpt.Compra` | Factura de compra `FCP` (Estado 1 o 2, con `Estado`) | `Numero`, `Fecha`, `Suplidor*`, `FacturaSuplidor`, `Ncf`, `TipoGastoCodigo`, `AlmacenCodigo`, `TerminoCodigo`, `MonedaCodigo`, `Tasa`, `SubTotal`, `Descuento`, `Impuesto`, `Total`, `TotalBase`, sucursal | `compras.Compra`, `doc.*`, `fiscal.*`, maestros | `rpt` (los totales del documento no son «costos» en el sentido de RS-03: no hay costo por artículo; el reporte 13 ya lo ve el área Compras) |
| `rpt.DocBanco` | Documento bancario (Estado 1 o 2) | `Numero`, `Fecha`, `Clase`, `TipoDescripcion`, `CuentaCodigo`, `NumeroCheque`, `Referencia`, `SuplidorCodigo`, `Beneficiario`, `Concepto`, `MonedaCodigo`, `Tasa` [I: verificar la columna en `banco.DocBanco`], `Monto`, `MontoBase`, sucursal | `banco.DocBanco`, `banco.CuentaBancaria`, maestros | `rpt` |
| `rpt.CajaChica` | Gasto de caja chica emitido | `Numero`, `Fecha`, `CajaCodigo`, `Beneficiario`, `RncCedulaEnmascarada` (RNC de 9 dígitos íntegro; otra identificación, `*******` y los últimos 4: RS-01), `Concepto`, `Ncf`, `TipoGastoCodigo`, `Monto`, `Impuesto`, sucursal | `caja.CajaChica`, `doc.*`, `fiscal.*`, `org.Caja` | `rpt` |
| `rptc.CajaChica` | ídem | Superconjunto, con `RncCedula` completa al final | ídem | `verdatospersonales` |
| `rpt.MovimientoCaja` | Movimiento de `caja.Movimiento` | `MovimientoId`, `Fecha` y `Hora` locales (desde `RegistradoEn`), `CajaCodigo` (por la jornada), `JornadaId`, `Tipo`, `DocumentoNumero`, `TipoDocumentoCodigo`, `Usuario` (cajero), `MonedaCodigo`, `Tasa`, `Ingreso`, `Egreso`, `IngresoBase`, `EgresoBase`, `Motivo`, `Revertido`, sucursal. Las filas `CIERRE` según Q-4 | `caja.Movimiento`, `caja.Jornada`, `org.Caja`, `doc.Documento` | `rpt` (más `rptc` si Q-4 = A) |
| `rpt.CatTipoGasto`, `rpt.CatTermino` | Fila del maestro | `Id`, `Codigo`, `Descripcion`, `Inhabilitado` | `cat.*` | `rpt` |

Sobre la tasa de la CxC (H-T4-02), se recomienda al arquitecto-datos agregar `cxc.Cuenta.Tasa decimal(19,6) NOT NULL`, simétrica a `cxp.Cuenta`:
- relleno desde `ventas.Venta.Tasa`, y para el cheque devuelto, desde su documento;
- `Partidas.RegistrarCuentaAsync` la recibe.

Alternativa descartada: derivarla en la vista con `COALESCE` sobre tres orígenes (`ventas.Venta`, cheque devuelto y tasa del día). Es frágil y cada origen nuevo de CxC la rompería en silencio. El costo de la recomendada es de unas 0,1 sp; si el arquitecto-datos prefiere la vista, el contrato de columnas no cambia.

### 5.2 Cambios en vistas existentes (contrato 1.3)

| Vista | Cambio | Contrato |
|---|---|---|
| `rpt.CierreCajaConteo` | T3-10: `Esperado` pasa a NULL en todas las filas (también en los Z), y la cifra queda solo en `rptc.CierreCajaConteo`. La columna se conserva, así que no hay pérdida de columnas (cláusula 11) | Huella nueva. Depende de Q-5 |
| `rpt.VentaDocumento`, `rpt.ConsultaFactura` y sus `rptc` | Ya filtran `c.Rol = 'O'` (`VistasReportesOla5.cs:72,147,622,681`) [V]: el rol H no entra. Solo se agrega la guarda (sección 7.2) y, si Q-3 lo pide, la columna aditiva `NcfHistorico` en `ConsultaFactura` | Aditivo |
| `rpt.Kardex`, `rptc.Kardex` | Etiqueta «Diferencia de transferencia» de la clase 8. La hace quien una segundo entre el tramo 4 y el tramo 2 de la 3b | Huella nueva |
| Tránsito (3b) | Las cuatro vistas las crea la migración de la 3b (H-3b-17). El tramo 4 solo las agrega a `contrato-vistas.v1.json` y a la prueba estática | Aditivo (1.4) |

**Orden de versiones:** el tramo 4 publica la 1.3 y se une antes que el tramo 1 de la 3b (28-29 oct). La 3b rebasa y publica la 1.4 con el tránsito. El tramo 2 de la 3b o el bloque B, el que se una segundo, publica la 1.5 con la etiqueta de la clase 8 y las vistas de RPV. **Una sola mano edita el contrato en cada unión**, según la regla de editor único de la 3b (R-2 de su DDL).

### 5.3 API

| Ruta | Método | Cambio | Permiso | Aislamiento |
|---|---|---|---|---|
| `/api/reportes` | GET | **Lo responde siempre la principal** desde `GPOS_SYSDATA` (`ReportesService.ListarAsync`), aunque el reenvío esté encendido. Ya no se reenvía. DTO `List<ReporteResumen>` sin cambios. Si la API de reportes no responde, la lista se ve y la ejecución da 503 `REPORTES_NO_DISPONIBLE` por reporte, no en toda la pantalla | Autenticado; el filtro por área y por solo-administrador es el de hoy | Empresa del token (la sesión lo valida en cada petición, como hoy) |
| `/api/reportes/{id}` | GET | Se reenvía siempre (sin `EnLaPrincipalAsync`) | igual | igual |
| `/api/reportes/{id}/ejecutar` | POST | Se reenvía siempre. **Errores nuevos:** ninguno. Se conservan 403 `PRIVILEGIO_REQUERIDO` (con el campo aditivo `privilegios: ["vercostos", …]` y el mensaje con los **nombres** del catálogo, C-3), 403 `SUCURSAL_NO_PERMITIDA`, 422 `PAGINA_FUERA_DE_ALCANCE`, 429 y 503 | igual | La API de reportes, con `rptsis.AccesoEmpresa` |
| `/api/reportes/{id}/exportar/{formato}` | GET | Siempre por la canalización de exportación. La principal escribe `audit.Exportacion` con la huella, los renglones, el usuario, la empresa y el formato (ADR-111), en lugar del evento 5123 (`ReenvioReportes.cs:63,85,96`) | `rptexportar` | igual |
| `/api/reportes/dashboard/indicadores` | GET | Tarjeta de CxC con `BalanceBase`. Si Q-1 = A, se traslada a la API de reportes como consulta registrada sobre `rpt`/`rptc` | Autenticado; «Ver costos» para el valor del inventario (PD-09) | Empresa |

Sobre la lista, alternativa descartada: «agregar a la API de reportes los P-2» o un respaldo que reintente en la principal si la API cae. Duplica la lógica de visibilidad en dos procesos y además depende de un fallo para cambiar de camino. Responderla en la principal es coherente con la cláusula 2 (las definiciones son persistencia de la principal) y deja un solo dueño del filtro. Riesgo: que la lista de la principal y la definición que devuelve la API de reportes discrepen en la visibilidad. Se mitiga con la prueba de contrato de la sección 7.1, punto 6.

**Metadatos aditivos del resultado** (cláusula 8: no rompen a los clientes):
- `Metadatos["totalesEstado"] = "no-disponibles"` (C-4). `Metadatos["totales"]` queda solo para la leyenda (`ReportesVentasRegistrados.cs:317`). `EjecutorDisenador.cs:412` deja de escribir el texto «no disponibles» en `totales` y escribe el estado en `totalesEstado`.
- `Metadatos["profundidad"] = "50000"`, de `OpcionesEjecutor.ProfundidadMaxima` (`OpcionesEjecutor.cs:56`) (C-5).
- `ReporteColumnaDto.Ordenable` (`bool?`; `null` = sí) (C-5).
- `Metadatos["datosPersonales"] = "abreviados"` cuando el reporte usa una vista con variante `rptc` de datos personales y el usuario no tiene «Ver datos personales» (C-6). El primer consumidor es el reporte 22.

### 5.4 Definiciones reescritas (semilla)
- Las 11 definiciones leen solo `rpt.*`, con los mismos códigos, títulos y columnas visibles. Lo que el usuario ve cambia en dos cosas:
  - los montos en la moneda del documento se muestran **sin totalizar**, y se agrega la columna «(moneda base)» totalizada (H-T4-03, la regla del tramo 3);
  - el reporte 23 pasa del vocabulario de `Mov_Cajas` (Origen, Turno) al de `caja.Movimiento`. «Origen» muestra el tipo de movimiento con las etiquetas de la pantalla de caja, y «Cajero» muestra el usuario.

  Qué rompe: nada que esté en producción (BP2 nunca salió a producción; ADR-52 permite cambiar los reportes por rendimiento). A quién afecta: a quien ya usó estos reportes en el DEMO. Cómo se migra: la semilla actualiza las definiciones del sistema que siguen intactas, con la huella de T3-02, y las que modificó un ADMIN se dejan como están.
- El 22, con «Ver datos personales», usa `rptc.CajaChica` mediante la variante por privilegio de RS-03. Esto exige que el 22 sea un **reporte registrado** (consulta del código con `gpos_lec`), porque el SQL del diseñador no ve `rptc`. Alternativa: dejarlo en el diseñador con la identificación siempre enmascarada. Se recomienda la segunda opción para el tramo 4 (0,05 sp frente a 0,2), con C-6 informando «abreviados». Ver Q-2.
- `EnLaPrincipal`, `IntactoEnLaPrincipal`, `EnLaPrincipalAsync` y el camino de exportación «que todavía arma la principal» (`ReportesService.cs:267`) se eliminan. El modo «sin dirección» (todo en la principal) queda según Q-6.

## 6. Interfaces entre módulos
- `ReenvioReportes` deja de consultar `ReportesService.EnLaPrincipalAsync`; el reenvío es por ruta, no por reporte.
- Interfaz nueva en `GPOS.Core`: `IRegistroExportacion.RegistrarAsync(EvidenciaExportacion, ct)`. La implementa la principal sobre `audit.Exportacion` y la llama `ReenvioReportes.ExportarAsync` después de recibir los encabezados `X-GPOS-Renglones` y `X-GPOS-Huella-Datos`. Mientras la tabla no exista se conserva el evento 5123 tras un interruptor, para no esperar a `b/ola5-auditoria`.
- El visor consume `totalesEstado`, `profundidad`, `Ordenable`, `datosPersonales` y `privilegios`, y sigue con su camino reactivo si faltan (diseño UX, 3.3 a 3.5).

## 7. Pruebas y criterio de salida

### 7.1 Pruebas nuevas o cambiadas
1. **Vistas:** en `GPOS.Tests`, con rasgo NG, una prueba por vista nueva sobre una base `GPOS_TEST_*`. Comprueba:
   - el grano (sin duplicados por `DocumentoId`);
   - que `BalanceBase` sea igual a `ROUND(Balance × Tasa, 2)`;
   - que la suma de `BalanceBase` sea igual a la tarjeta de CxC, y el mismo cuadre con CxP;
   - que en la caja chica el RNC salga íntegro, la cédula enmascarada en `rpt` y completa en `rptc`.
2. **Contrato:** prueba estática con la huella de la 1.3, `privilegio` en `rptc.CajaChica`, ninguna vista de `rpt` que nombre otro esquema que no sea de vistas, y los permisos generados desde el catálogo (cláusula 3).
3. **Guarda H-2:** toda vista de `rpt`, `rptc` o `imp` cuyo texto nombre `fiscal.Comprobante` debe filtrar `Rol` de forma explícita (análisis con ScriptDom del texto de la vista en el catálogo). La propuso A en `a/h2-ncf-historico`; si A la une primero, el tramo 4 solo agrega las vistas nuevas a su lista.
4. **P-2 vacía:**
   - la prueba F9 se reescribe: los reportes 8 a 10, 13 a 16, 21 a 23 y 27 se ejecutan **en la API de reportes**, con el mismo dato de la prueba (factura a crédito, recibo, compra, cheque, gasto y movimiento de caja);
   - `T3_02` se sustituye por: «ningún reporte del sistema se ejecuta en la principal» (con el reenvío encendido, la principal no abre una conexión de empresa para `/ejecutar`);
   - una prueba de arquitectura comprueba que no queda ningún SQL de la semilla que lea fuera de `rpt`.
5. **Tarjeta de CxC:** dos facturas a crédito, en DOP y en USD con tasa 60, dan la suma en moneda base; la tarjeta coincide con el total del reporte 9.
6. **Lista:** con la API de reportes detenida (o la canalización sin dueño), `GET /api/reportes` responde 200 y `/ejecutar` responde 503. Prueba de contrato: la lista de la principal y `GET /{id}` de la API de reportes coinciden en la visibilidad para USER, ADMIN y SUPER, y con y sin privilegios.
7. **C-3 a C-6:** pruebas de `GPOS.Reportes.Tests` sobre los metadatos y el problema.
8. **T3-10:** `gpos_rpt` lee `rpt.CierreCajaConteo` y `Esperado` es NULL en los X y los Z.
9. **Evidencia:** una exportación CSV deja una fila en `audit.Exportacion` con la huella igual a `X-GPOS-Huella-Datos`. Sin la tabla, deja el evento 5123.
10. **Visor (bloque B):** pruebas bUnit en `GPOS.Web.Tests`: Enter ejecuta, Esc cancela, `tabindex` y `role="button"` en las filas con detalle, tamaño 100 en el teléfono, y página y orden restaurados.
11. **Rendimiento:** plan de ejecución con *seek* y tiempo con el volumen del cliente grande, mayor que el de [D3B] [I]:
    - vistas de CxC y CxP con 200.000 cuentas y 5.000 con saldo;
    - `rpt.MovimientoCaja` con 2 millones de filas por un mes y una caja;
    - objetivo: p95 menor que 2 s y nunca más de 30 s (cláusula 12).

### 7.2 Criterio de salida (punto de control G-O5-T4)
- **A (publicación):**
  - `EnLaPrincipal` no existe y ningún reporte del sistema se ejecuta con la conexión de escritura;
  - suite oficial (`--filter "Transicion!=Ola5&Transicion!=Defecto"`), `GPOS.Reportes.Tests`, Web y MAUI en verde, ejecutadas solas;
  - prueba F9 en verde;
  - revisión del auditor-seguridad sobre las vistas nuevas (RS-01 en la caja chica y T3-10) con estado «Aprobado» o «Aprobado con observaciones» y sin hallazgos Altos abiertos;
  - revisión de A del núcleo (migración y `cxc.Cuenta.Tasa`).
- **B (corte):** visor sin pendientes de 3.G, C-01 a C-04, E-07, E-01 y E-04 con sus pruebas. E-02, E-03 y E-06 solo si el anillo 2 sigue vivo el 20-nov.
- El veredicto es una recomendación; la publicación la firma el propietario (C2).

---

## 8. Requisitos de seguridad de arquitectura
- **Autenticación:** la del tramo 3, sin cambios: introspección por la canalización y E1 (`ExigeOtpSuper`).
- **Autorización:**
  - área del reporte y solo-administrador, como hoy;
  - `rptc.CajaChica` exige «Ver datos personales»;
  - el cuadre de caja, solo en `rptc` (T3-10);
  - `PRIVILEGIO_REQUERIDO` nombra los privilegios sin exponer más (C-3).
- **Aislamiento:**
  - una base por empresa;
  - la API de reportes valida `rptsis.AccesoEmpresa` en cada petición;
  - la restricción de sucursal (D-03) se aplica a todas las vistas nuevas porque todas traen `SucursalCodigo` con el catálogo «Sucursales».
- **Secretos:** ninguno nuevo. Las credenciales de lectura siguen en sobres (cláusula 5). La migración nueva corre con el login de migración, no con el de la API (RG-14 sigue abierto en A).
- **Lo que se cierra:** la escritura que todavía ve el SQL de los 11 reportes, que hoy corren con `gpos_app`.

## 9. Sincronización
No aplica: las vistas son locales a cada base, y en un nodo los saldos se marcan «parcial» (cláusula 9, ya construida).

## 10. Necesidades para Datos e Integraciones
- **arquitecto-datos (B):**
  - DDL de las ocho vistas de 5.1 y de los dos catálogos;
  - `cxc.Cuenta.Tasa`, con relleno y su regla en `Partidas`;
  - T3-10;
  - contrato 1.3;
  - medición de 7.1, punto 11.

  Decide si hace falta un índice por `SaldoPendiente > 0`; hoy no se propone ninguno.
- **Integraciones:** no aplica.

---

## 11. Preguntas para el propietario

| # | Pregunta | Opciones | Recomendación | Qué rompe / costo |
|---|---|---|---|---|
| **Q-1** | ¿Se traslada el tablero (las tarjetas) a la API de reportes en este tramo? | **A.** Sí, como consultas registradas sobre `rpt`/`rptc`; los avisos operativos (cierre de sucursal) siguen en la principal. **B.** No: solo se corrige la tarjeta de CxC y el traslado pasa a la entrega 2 | **A.** La cláusula 1 lo pide y deja la principal sin SQL de reportes. Cuesta +0,3 sp, dentro del margen | Nada visible. Con B, la principal sigue leyendo tablas para el tablero después de publicar |
| **Q-2** | El reporte 22 (caja chica) muestra RNC o cédula del beneficiario. ¿Cómo la ve quien tiene «Ver datos personales»? | **A.** Siempre enmascarada en el tramo 4 (salvo el RNC de 9 dígitos), con el aviso «Identificaciones abreviadas». **B.** Se convierte en registrado para mostrarla completa con el privilegio | **A** ahora y **B** en la entrega 2 si alguien la pide: 0,05 sp frente a 0,2 | Con A, quien tiene el privilegio ve la cédula abreviada en ese reporte (hoy la ve completa cualquiera con el área, y eso se corrige) |
| **Q-3** | Facturas históricas importadas (rol H de H-2): ¿su NCF aparece en la consulta de facturas y en los estados de cuenta? | **A.** Sí, en `rpt.ConsultaFactura` y `rpt.CxcDocumento` con `Rol IN ('O','H')` y la columna `NcfHistorico`, igual que la pantalla (A cambia `ConsultasCxc` a O y H); los reportes de ventas y los formatos fiscales siguen solo con O. **B.** Solo O en todas las vistas | **A.** Coincide con la pantalla y con el estado de cuenta de A. La guarda exige que el rol sea explícito en cada vista | Con B, el reporte y la pantalla muestran NCF distintos para la misma factura |
| **Q-4** | Movimientos de caja (23): la fila de cierre revela lo declarado. ¿Quién la ve? | **A.** En `rpt` va sin el monto de las filas `CIERRE` (NULL), y `rptc.MovimientoCaja` lo muestra con «Ver cuadre de caja». **B.** Todo en `rpt`, como hoy | **A.** Aplica RS-02 sin quitar el reporte a nadie. +0,05 sp | Con A, quien no tiene el privilegio deja de ver un monto que hoy ve |
| **Q-5** | T3-10: `rpt.CierreCajaConteo` conserva hoy `Esperado` en los Z no anulados (lo permitió la precisión de la cláusula 4, punto 3) | **A.** NULL también en los Z: el cuadre solo en `rptc`. **B.** Se deja como está | **A.** Hoy el diseñador lo lee sin el privilegio, y el registrado ya lo oculta desde T3-10. Sin pérdida de columnas | Es precisión del punto 3 de la cláusula 4 de ADR-109 (firma del propietario) |
| **Q-6** | Modo «sin dirección» (la principal ejecuta los reportes) después del tramo 4 | **A.** Solo en Debug y en pruebas. En Release la principal no arranca si el reenvío está apagado, y el instalador instala los dos servicios. **B.** Se conserva como respaldo de operación | **A.** Con B, la principal vuelve a ejecutar el SQL del diseñador con la escritura (lo que ADR-109 elimina) | Una instalación sin el servicio de reportes no ve reportes. Precisión de la cláusula 8 |

---

## 12. Esfuerzo (sp, inferido, ±35 %)

| Bloque | Trabajo | sp |
|---|---|---|
| A | Vistas P-2, catálogos, `cxc.Cuenta.Tasa`, migración, contrato 1.3 | 0,60 |
| A | Reescritura de 11 definiciones, retiro de P-2 y reenvío por ruta, pruebas F9 y T3_02 | 0,40 |
| A | Tarjeta de CxC (+0,30 si Q-1 = A) | 0,10 |
| A | Lista en la principal y su prueba de contrato | 0,15 |
| A | C-3 a C-6 | 0,20 |
| A | Guarda H-2 (o adopción de la de A), T3-10, Q-4 | 0,10 |
| A | `audit.Exportacion` (interfaz e interruptor) | 0,15 |
| A | Medición de rendimiento, revisión de seguridad e integración | 0,35 |
| **A total** | | **2,05** (1,35 a 2,80; 2,35 con Q-1 = A) |
| B | Visor: pendientes de 3.G | 0,40 |
| B | C-01 a C-04 y E-07 (ADR-125) | 0,25 |
| B | E-01 y E-04 (anillo 1); E-02, E-03 y E-06 recortables | 0,20 (0,12 sin el anillo 2) |
| B | Contrato del tránsito y clase 8 | 0,10 |
| **B total** | | **0,95** (0,60 a 1,30) |
| **Total** | | **3,0 sp** (2,0 a 4,1). Costo de infraestructura y licencias: USD 0 |

## 13. Dependencias

| Dependencia | Dueño | Fecha prevista | Si se retrasa |
|---|---|---|---|
| `audit.Exportacion` | otro agente de B en `b/ola5-auditoria` | sin fecha [V: la rama está en `ec459d5`, sin la tabla] | El bloque A sale con el evento 5123 tras el interruptor. La publicación exige la tabla según ADR-111: se anota como condición propia |
| H-2 (rol H, guarda) | A, `a/h2-ncf-historico` | en construcción | Las vistas ya filtran O. Si H-2 se une después, quien una segundo agrega las vistas nuevas a la guarda |
| 3b tramo 1 (tránsito) | B, `b/ola3b` | unión 28-29 oct | El registro en el contrato se mueve con la 3b; no bloquea A |
| 3b tramo 2 (clase 8) | B | 2 a 20 nov | Etiqueta de la clase 8 al unir |
| T1 de ADR-118/119 (lotes) | B, `b/adr118-119-t1` | 27 oct | C-01 y E-07 esperan a T1 |
| «Por despachar», anillo 1 | A y B | control el 20-nov y el 1-dic (PF-06) | E-01 y E-04 la siguen; el anillo 2 sale el 20-nov |
| C-1 (motivo unificado del 401) | C, fase A de ADR-81 | — | No bloquea: UX-V-01 cae al inicio de sesión |
| RG-14 y T3-12 | A | en cola | No bloquea el tramo; sí la publicación (lista de §7 del consolidado) |

## 14. Paralelización (límite del equipo de B: hasta 8 agentes, máximo 3 compilando o probando)

| Fechas | Línea 1 (datos y servidor) | Línea 2 (servidor de reportes) | Línea 3 (interfaz) |
|---|---|---|---|
| 13-14 oct | arquitecto-datos: DDL de 5.1 y `cxc.Cuenta.Tasa` (sin compilar) | — | — |
| 15-22 oct | backend: migración `Ola5VistasCxcCxpCaja`, semilla reescrita y P-2 vacía, tarjeta de CxC | backend: C-3 a C-6, lista en la principal, `IRegistroExportacion` | frontend: visor 3.G (Enter, Esc, filas, teléfono, restaurar) |
| 23-24 oct | QA: suite oficial sola, F9, rendimiento; auditor-seguridad sobre las vistas | — | — |
| **24-25 oct** | **Unión del bloque A a `feature/modelo-ng`** (antes del rebase de la 3b el 27-28) | | |
| 28 oct-14 nov | C-01, C-02 y E-07 (tras T1); C-03 y C-04 | `audit.Exportacion` real cuando llegue | consumo de C-4 a C-6 en el visor |
| 17 nov-5 dic | E-01 y E-04 (anillo 1); E-02, E-03 y E-06 solo si siguen vivos el 20-nov; contrato del tránsito y clase 8 | — | — |
| **5 dic** | **G-O5-T4 completo**; margen hasta el corte | | |

Son 3 agentes como máximo compilando a la vez. La migración y el *snapshot* tienen un editor único (línea 1).

## 15. Riesgos

| # | Riesgo | Prob. / impacto | Mitigación |
|---|---|---|---|
| R-1 | El rebase de la 3b y del bloque A choca en la migración y en el contrato | Alta / medio | Unir A el 24-25 oct; la 3b regenera; un solo editor del contrato |
| R-2 | `rpt.MovimientoCaja` lenta por período sin caja | Media / medio | Medición 7.1, punto 11; filtro de caja o de sucursal por omisión en el 23; índice solo con medición |
| R-3 | La reescritura del 23 cambia lo que el usuario ve | Cierta / bajo | Se documenta en las notas de la versión; BP2 nunca salió a producción |
| R-4 | `audit.Exportacion` no llega antes de publicar | Media / alto para la publicación | Interruptor; condición de publicación explícita |
| R-5 | Divergencia de visibilidad entre la lista (principal) y la definición (API de reportes) | Baja / medio | Prueba de contrato 7.1, punto 6 |

## 16. Decisiones candidatas a ADR
- Precisión de la cláusula 8 de ADR-109: la lista la responde la principal, el reenvío es por ruta y no por reporte, y el modo «sin dirección» queda solo en Debug (Q-6).
- Precisión del punto 3 de la cláusula 4 de ADR-109: `Esperado` fuera de `rpt.CierreCajaConteo` y monto de `CIERRE` fuera de `rpt.MovimientoCaja` (Q-4, Q-5).
- `cxc.Cuenta.Tasa` (precisión de datos de P-5; no requiere ADR si la acepta el arquitecto-datos).
