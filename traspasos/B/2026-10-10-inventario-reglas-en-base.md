# Reglas de negocio que viven en la base de datos de empresa: inventario, razón de ser y qué se puede mover a la aplicación

- **Fecha:** 2026-10-10
- **Autor:** arquitecto de datos del equipo B
- **Rama y versión revisadas:** `feature/modelo-ng`, árbol `GPOS-B-modelo-ng`, HEAD `9fe5476` (unión de la ola 5)
- **Tipo:** análisis y documentación. No modifica código, esquema ni migraciones. No se ejecutó nada contra SQL Server.
- **Estado de las recomendaciones:** Pendiente de firma del propietario (sección 8)

## Índice

1. [Resumen](#1-resumen)
2. [Alcance, método y convenciones](#2-alcance-método-y-convenciones)
3. [Inventario](#3-inventario)
   - 3.1 Cifras
   - 3.2 `doc`: ciclo de vida del documento
   - 3.3 Inmutabilidad de las extensiones (`ventas`, `cxc`, `caja`, `inv`, `compras`, `cxp`, `banco`)
   - 3.4 `fiscal`: NCF, 606, 607, 608 y período declarado
   - 3.5 `inv`: kárdex, período cerrado, conteo y unidades
   - 3.6 `cat`: códigos y significado de los maestros
   - 3.7 `num` y `org`: numeración y sucursales
   - 3.8 `sync`: rango del nodo y base restaurada (H-11)
   - 3.9 `audit`: bitácoras de solo inserción
   - 3.10 Privilegios negados (`DENY`) como regla de negocio
   - 3.11 Restricciones `CHECK`, `UNIQUE` y FK con significado de negocio
   - 3.12 Vistas con lógica (`rpt`, `rptc`, `num`, `sync`, `inv`)
   - 3.13 Guardas de migración (no son reglas de operación)
4. [Por qué vive cada regla en la base](#4-por-qué-vive-cada-regla-en-la-base)
5. [Qué se podría mover a la aplicación sin perder seguridad](#5-qué-se-podría-mover-a-la-aplicación-sin-perder-seguridad)
6. [Costos y riesgos actuales](#6-costos-y-riesgos-actuales)
7. [Recomendación final](#7-recomendación-final)
8. [Hoja de firma](#8-hoja-de-firma)
9. [Cierre](#cierre)

---

## 1. Resumen

- La base de empresa del modelo nuevo tiene **68 disparadores, 3 procedimientos, 0 funciones, 73 vistas, 284 restricciones `CHECK`, 74 índices únicos (20 filtrados), 253 claves foráneas sin cascada y 38 sentencias `DENY`**. Las reglas con número propio ocupan **51201 a 51204 y 51300 a 51407**: 98 números distintos, de los que 4 son guardas de migración (51394, 51397, 51398 y 51399). **No hay ningún error 52xxx** en la base de empresa.
- **Casi todo el costo está en la emisión:** 7 de los 9 disparadores de `doc.Documento` son `AFTER UPDATE` y corren en la sentencia que emite. Esa sentencia se ejecuta con la serie tomada.
- **El costo medido es pequeño en la venta y grande en la compra.**
  - Venta: `TR_Documento_Emision` cuesta de 0,405 a 0,434 ms bajo carga, frente a unos 5 ms de tramo con la serie tomada.
  - Compra: `TR_Documento_Ola4` cuesta de 17 a 24 ms por factura de compra de 20 líneas. El PR #21 de C lo baja a unos 12,7 ms.
- **Mi recomendación es mantener en la base todas las reglas de las clases (a) y (b).** Son las de inmutabilidad, NCF, períodos, base restaurada, rango del nodo, saldos y unicidad. Ninguna debe moverse nunca.
- **No recomiendo mover hoy ninguna regla de la clase (c).** Moverlas ahorraría como mucho 0,3 ms por venta. A cambio, un error del programa o un proceso que escriba SQL directo dejaría pasar datos fiscales incorrectos, y los nodos de la entrega 2 llegarían sin red.
- **Sí recomiendo simplificar:**
  - unir el PR #21;
  - quitar una regla duplicada dentro de la propia base (51312);
  - retirar la opción «lote vencido con autorización», que ADR-119 ya retiró;
  - eliminar las vistas de compatibilidad de `num` en el corte de la entrega 1;
  - cubrir con pruebas las reglas que solo valida la base y que hoy no tienen prueba localizada.
- **El costo real de las reglas en la base es de mantenimiento, no de rendimiento.**
  - El texto vigente de los tres disparadores grandes solo se puede leer en el guion acumulado: se arma con 39 parches de cadena repartidos en 10 archivos.
  - Unas 35 reglas (conteo aproximado, inferido de la columna «API: Sí») están en los dos lados: el servicio las valida y la base las vuelve a comprobar.

---

## 2. Alcance, método y convenciones

**Fuentes leídas (verificado):**
- `database/empresa/gpos-empresa-20261010130522_BitacoraLogSoloInsercion.sql` (13.950 líneas). Se cita como **G:línea**.
- `src/GPOS.Core/Datos/Empresa/Migraciones/SqlMigraciones*.cs`. Se cita como **M/archivo:línea**.
- El mapeo de errores `src/GPOS.Core/Infraestructura/Numeracion/ErroresNumeracion.cs`, los servicios de `src/GPOS.Core/Servicios` y las pruebas de `tests/GPOS.Tests`.
- Los ADR de `master` (`GPOS NG/docs/adr`).
- El diseño `docs/datos/2026-10-06-disparadores-emision-y-borrador.md`, el estudio `docs/datos/2026-10-09-estudio-numero-al-final.md`, la hoja `docs/decisiones/2026-10-09-hoja-firma-numero-al-final-y-mc.md` y la recalibración `docs/decisiones/2026-10-10-recalibracion-8-2-5-t28.md`.
- La hoja de rendimiento de la ola 4 (F-R1 a F-R5) en `GPOS-NG-Equipos/traspasos/A/hoja-firma-rendimiento-ola4-2026-10-08.md`.
- El PR #21 de C (`c/compra-variable-tabla`, abierto, «no unir antes del 14-oct»).

**Cómo se fijó la versión vigente de cada objeto:**
- Muchos disparadores se redefinen en varias migraciones; `TR_Documento_Emision`, por ejemplo, tiene 7 versiones en el guion.
- Para cada objeto se tomó **la última** `CREATE OR ALTER` del guion acumulado, que es la que queda en una base al día.
- Para cada línea final se identificó la migración que la contiene (sección 6.2).

**Columna «API» de las tablas:**
- **Sí:** el servicio valida antes y rechaza con su propio código. La base es la red. Evidencia: comentario «la validación previa debió detectarlo» en `ErroresNumeracion.cs:206`, o búsqueda del código en los servicios.
- **Construye:** el servicio calcula el dato correcto por diseño, sin validarlo. La base comprueba que cuadre.
- **No (solo base):** no se localizó una validación previa en `src/GPOS.Core` ni en `src/GPOS.Api`. El mapeo convierte el mensaje del motor en el código de la API (`ErroresNumeracion.cs:421-425`).
- **Diseño:** el programa nunca hace esa escritura. La regla ataja otro proceso, el SQL directo o un error.
- Las búsquedas son por texto. Un «No» quiere decir **no localizado**, no «demostrado inexistente».

**Clases de la sección 4:**
- **(a)** Invariante fiscal o de integridad que debe sobrevivir a cualquier cliente o error.
- **(b)** Coherencia que debe evaluarse en la misma transacción que la escritura.
- **(c)** Defensa en profundidad de algo que la API ya valida o construye.
- **(d)** Histórico o heredado, sin razón fuerte hoy.

**Hechos e inferencias:**
- Lo que no está marcado **(inferido)** se leyó en el código o en los documentos citados.
- Ninguna cifra de rendimiento es mía de esta sesión: todas vienen de las mediciones citadas.

---

## 3. Inventario

### 3.1 Cifras

| Objeto | Cantidad | Evidencia |
|---|---|---|
| Disparadores (versión vigente) | 68 | última `CREATE OR ALTER TRIGGER` de cada nombre en G |
| … sobre `doc.Documento` | 9 (Nace, Inmutable, Emision, Anulacion, Credito, Motivo608, Ola4, Ola4b, RangoNodo) | `src/GPOS.Core/Datos/Empresa/Configuracion/DisparadoresNg.cs:34-35` y G |
| Procedimientos | 3 (`sync.usp_AdelantarSecuencias`, `sync.usp_AbrirReconciliacionLocal`, `sync.usp_ConfirmarReconciliacionLocal`) | G:5388, G:12432, G:12477 |
| Funciones | 0 | G |
| Vistas | 73 (55 `rpt`, 13 `rptc`, 3 `num`, 1 `sync`, 1 `inv`) | G |
| `CHECK` (versión vigente) | 284 | G (16 se borran y se vuelven a crear) |
| Índices únicos | 74, de ellos 20 filtrados | G |
| Claves foráneas | 253, **ninguna** con `ON DELETE CASCADE` | G (ADR-08: eliminar solo sin referencias) |
| `DENY` | 38 sentencias | G |
| Números de error propios | 98 distintos: 51201, 51203, 51204 y de 51300 a 51407; 4 son guardas de migración (51394, 51397, 51398 y 51399) | G |
| Errores 52xxx | 0 | G |

### 3.2 `doc`: ciclo de vida del documento

Estados de `doc.Documento.Estado`: 0 = borrador, 1 = emitido, 2 = anulado.

| Regla | Qué protege (negocio) | Dónde | Origen | API | Clase |
|---|---|---|---|---|---|
| **51300** `TR_Documento_Nace` | Todo documento nace en borrador; la emisión es siempre la transición 0→1. Así ningún documento entra emitido sin pasar por las reglas de emisión. | G:4912 · M/SqlMigracionesOla3.cs:91 | CA-01, ADR-72 | Diseño | a |
| **51301** `TR_Documento_Inmutable` | Un emitido solo se anula; un anulado no cambia. No cambian el número, el tipo, la serie, la fecha, la sucursal, `EmitidoEn`, el motivo sin NCF, `Uid` ni el origen. Tampoco se borra un documento emitido. | G:4918 · M/SqlMigracionesOla3.cs:99 | CA-01, ADR-48, ADR-72 | Diseño | a |
| **51330** guarda MD-59 (dentro de `TR_Documento_Emision`) | Una base restaurada o un nodo en reconciliación **no emite**. Lee `sys.database_recovery_status` en cada emisión y falla cerrada si no puede leer el fork. | G:11967-11973 | ADR-53 cláusula 9, MD-59, H-10 | Sí (`ConsultasDocumentos.cs:17` comprueba antes) | a |
| **51303** CA-10 | Los totales de la venta cuadran con sus líneas. | G:12000 | CA-10 | Construye (`VentasNg.cs:31-33`) | c |
| **51304** CA-12 | El resumen por impuesto cuadra con las líneas. Ese resumen lo leen el Z, el 607 y el e-CF. | G:12021 | CA-12 | Construye | c |
| **51305** CA-11 | Pagos más crédito igual al total. En la nota de crédito y la devolución: reembolsos más saldo a favor más aplicaciones. | G:12029 | CA-11, CA-46 | Construye | c |
| **51306** CA-24 | La venta POS y el cobro en caja pertenecen a una jornada abierta. | G:12032-12035 | CA-24, MD-17 | Sí (`PosService.cs:25`, `Jornadas`) | b |
| **51307 / 51308** CA-21 | Lote obligatorio si el artículo lo controla. Lote vencido bloqueado o con autorización. | G:12038, G:12045 | CA-21; **ADR-119 retiró la opción «A»** | No localizada en el servicio de venta (inferido: solo base) | c / **d** (opción «A») |
| **51309** CA-09 | El kárdex del documento es de almacenes de su sucursal, salvo regla explícita o sucursal cerrada. | G:12051 | CA-09, CA-45 | Sí (`ErroresNumeracion.cs:396-400`; `ConsultasInventario.cs:65`) | c |
| **51380 / 51381 / 51382** R2 y D-K1 | El kárdex coincide con las líneas: cantidad × factor en unidad base, unidad y factor vigentes, costo por unidad base. El ajuste lleva su motivo. | G:12090, G:12117, G:12124, G:12140 | ADR-78 (R2), D-K1 | Construye | c |
| **51405** D-MVP-02 | Solo una entrada recibe una orden de compra. La orden debe estar abierta, ser del mismo suplidor, tener los mismos artículos y no recibirse de más. | G:12149-12169 | D-MVP-02, I-1 | Sí (`InventarioService.cs`) | b |
| **51311** CA-22 | El ajuste del conteo es exactamente contado menos existencia del corte, y se aplica tras el corte y el cierre de la captura. | G:12181-12184 | CA-22 | Construye | c |
| **51320 / 51321** CA-23 y CA-35 | Un tipo sin NCF no lleva comprobante. Un tipo con NCF lleva comprobante o un motivo explícito. «No generar comprobante» exige la autorización `SIN_NCF`. | G:12189, G:12194 | CA-23, CA-35, RG-04/05, ADR-68 | Sí (`EmisionNcfNg`, `DocumentosNg`) | a |
| **51312** `TR_Documento_Anulacion` | Anular un documento con NCF exige el código del 608. | G:12205 | CA-02 | Sí | **d (duplicada)**: `TR_Documento_Motivo608` hace una comprobación más estricta con el mismo número (G:6492) |
| **51313 / 51314** | La anulación revierte el kárdex y los movimientos de caja del documento. | G:12208, G:12211 | CA-02 | Construye | b |
| **51315 / 51316** | La anulación deja sin efecto las aplicaciones. No se anula un documento con aplicaciones vigentes. El saldo a favor de la nota anulada queda en 0. | G:12214-12220 | CA-03, MD-17 | Sí (`CobrosService`, `Partidas`) | b |
| **51317** | Solo se anula con la jornada abierta. | G:12225 | MD-17 | Sí | b |
| **51406** | No se anula una entrada cuya orden ya fue facturada. | G:12230 | D-MVP-02, I-3 | Sí (`InventarioService.cs`) | b |
| **51312 / 51336 / 51337** `TR_Documento_Motivo608` | Con NCF: motivo del maestro y su tipo del 608. Sin NCF: no va al 608. Un motivo inhabilitado no se usa. | G:6482-6499 · M/SqlMigracionesOla3EmisionLigera.cs:272 | ADR-71 (Q-3) | Sí (`ErroresNumeracion.cs:407-414`) | a |
| **51335 / 51339 / 51338 / 51316 / 51334** `TR_Documento_Credito` | La nota de crédito solo se usa con su forma de pago, en su moneda y emitida. No se usa vencida. Su saldo cuadra con sus consumos vigentes. No se anula con consumos. El recibo cuadra. | G:6376-6450 · M/SqlMigracionesOla3EmisionLigera.cs:162 | ADR-70 (Q-4), MD-17 | Sí para 51335 y 51339 (`ErroresNumeracion.cs:415-421`); construye para 51338 y 51334 | b |
| **51341** `TR_Documento_Ola4` | Compras, CxP y bancos solo en la central. | G:11749 | ADR-53 cláusulas 2 y 4 | Sí (`CxpEndpoints.cs`, `Program.cs`) | a (entrega 2) |
| **51342 / 51343 / 51344** | Los totales de la compra cuadran. La factura del suplidor crea su cuenta por pagar por el total. El kárdex de la compra coincide con las líneas y con lo ya recibido. | G:11760-11831 | CA-10, R4, ADR-78, D-MVP-02 | Construye | c |
| **51345 / 51346** | La compra lleva su 606 o «Sin comprobante fiscal» autorizado. El NCF recibido o emitido es del tipo correcto. | G:11839, G:11849 | R4-18, PO-04 | Sí (parcial) | a |
| **51347 / 51348 / 51352 / 51353 / 51349 / 51351** | El pago, el anticipo, la aplicación de saldo a favor, la solicitud de pago, el documento bancario y la caja chica cuadran. | G:11853-11897 | R4-42, PO-09, R4-52, CA-24 | Construye o Sí | c |
| **51355** | Los saldos de las cuentas por pagar y de los saldos a favor del suplidor cuadran con sus aplicaciones. | G:11904-11909 | R4-44, R4-45 | Construye | b |
| **51358 / 51407 / 51315 / 51316 / 51356 / 51357 / 51317 / 51354** (anulación en compras) | No se anula: lo convertido o facturado, una orden con entradas, una compra con pagos, un saldo a favor en uso, una solicitud pagada, fuera de jornada ni un saldo inicial bancario. El 606 queda marcado como anulado. | G:11917-11942 | R4-02, R4-47, R4-48, R4-52, MD-17 | Sí (mayoría) | b |
| **51367 a 51379, 51359 a 51366** `TR_Documento_Ola4b` | Fechas y fiscal de los documentos de oficina:<br>– período declarado (51371, 51372);<br>– fecha futura (51367);<br>– retrofecha con tope y autorización (51368);<br>– nota no anterior a su factura (51369);<br>– plazo fiscal de 30 días (51379);<br>– concepto de la nota (51365);<br>– ITBIS e ISC al costo del 606 (51359);<br>– comprobante no posterior al registro (51370);<br>– devolución a suplidor y su cuadre (51360 a 51364, 51366, 51377);<br>– retención recibida (51374);<br>– monto en moneda base (51375). | G:9780-9962 · M/SqlMigracionesOla4Huecos.cs:29 (parche sobre M/SqlMigracionesOla4b.cs:199) | Confirmación contable 2026-10-07, PP-02, F-1 a F-7, HC-09, HC-10, R4-39, art. 8 del Decreto 293-11 | **Mixta:**<br>– Sí: F-1, F-2 y F-6 (`FechasDocumento.cs:28-60`), 51369, 51370, 51360, 51361, 51363, 51364, 51366, 51377 (`CuentasPorPagarService.Notas.cs`, `DocumentosComercialesService.*`).<br>– **No (solo base):** 51379 (plazo fiscal), 51362 (devolución excede), 51374 (retención recibida), 51375 (monto base) y 51359 (606 al costo, que el servicio construye). | a (51371, 51372, 51379, 51359, 51370); b (51360 a 51364, 51366); c (resto) |

### 3.3 Inmutabilidad de las extensiones (`ventas`, `cxc`, `caja`, `inv`, `compras`, `cxp`, `banco`)

Todas estas reglas responden a un mismo principio: lo emitido o anulado no se modifica (CA-01).

| Disparadores | Qué protege | Dónde | Número | API | Clase |
|---|---|---|---|---|---|
| `ventas.TR_Venta_Inmutable`, `TR_VentaLinea_`, `TR_VentaLineaImpuesto_`, `TR_VentaImpuesto_`, `TR_VentaPago_`; `cxc.TR_Recibo_`, `TR_ReciboPago_`, `TR_ReciboCredito_`; `caja.TR_CierreConteo_`, `TR_CajaChica_`; `inv.TR_DocInventario_`, `TR_DocInventarioLinea_`; `banco.TR_DocBanco_`, `TR_SolicitudPagoDocumento_`; `cxp.TR_Compensacion_`, `TR_Regularizacion_`; `compras.TR_CompraLinea_`, `TR_FacturaRecepcion_` | Ninguna fila de un documento emitido o anulado se inserta, se cambia ni se borra. | G:5063-5112, G:6145, G:7702-7738, G:9136, G:11723 · plantilla M/SqlMigracionesOla3.cs:259 y M/SqlMigracionesOla4.cs:107 | 51302 (y 51358 en `CompraLinea`) | Diseño | a |
| `caja.TR_Cierre_Inmutable` | Un cierre X o Z emitido no cambia. Al anularlo solo se marca `Anulado`; un X solo recibe el Z que lo incluyó. | G:5123 · M/SqlMigracionesOla3.cs:278 | 51302 | Diseño | a |
| `cxc.TR_Aplicacion_Inmutable`, `cxp.TR_Aplicacion_Inmutable` | Una aplicación emitida solo queda sin efecto al anular su documento, sin cambiar monto, retenciones ni bases. | G:9142, G:9153 | 51302 | Diseño | a |
| `banco.TR_SolicitudPago_Inmutable` | Una solicitud emitida solo cambia al pagarse o al anularse su pago. | G:7740 | 51302 | Diseño | a |
| `compras.TR_Compra_Inmutable` | Lo emitido no cambia. Una solicitud u orden convertida o facturada es de solo lectura. Una orden con entradas no cambia de suplidor ni de moneda. | G:12232 · M/SqlMigracionesOla4OrdenRecibida.cs:236 | 51302, 51358, 51407 | Sí (51407) | a / b |

### 3.4 `fiscal`: NCF, 606, 607, 608 y período declarado

| Regla | Qué protege | Dónde | Origen | API | Clase |
|---|---|---|---|---|---|
| **51322 / 51323 / 51327** `TR_Comprobante_Inmutable` | Un comprobante no se modifica ni se borra. El original nace con el documento en borrador. El reemplazo solo sustituye un B de contingencia. Ningún NCF sale de un bloque cerrado. | G:5136 · M/SqlMigracionesOla3.cs:293 | RF-01, CA-37, RN-11, ADR-53 cláusula 9 | Diseño / Sí | a |
| **51324 / 51325 / 51326** `TR_SecuenciaNcf_Bloque` | Los bloques de NCF no se solapan (con `UPDLOCK, HOLDLOCK`) y no salen de su rango autorizado. Un bloque cerrado por restauración no se reabre. El rango no baja de lo ya emitido. | G:5213 · M/SqlMigracionesOla3.cs:385 | CA-59, RN-11, RB-06, ADR-53 cláusula 9 (3) | Sí (parcial; `ConsultasRestauracion.cs:145`) | a + b |
| **51390** `TR_NcfZonaIncierta_Inmutable` | De una zona incierta solo cambian el estado y su resolución. | G:12621 · M/SqlMigracionesH11.cs:223 | RN-16, ADR-53 cláusula 9 (5) | Diseño | a |
| `fiscal.TR_Registro606_Inmutable` | Los datos del 606 de un emitido solo se marcan anulados con su documento. | G:7753 · M/SqlMigracionesOla4.cs:151 | CA-01, R4-16 | Diseño | a |
| **51373** `TR_PeriodoDeclarado_Registro` | La bitácora del período fiscal es de solo inserción, un período a la vez y sin carrera (`UPDLOCK, HOLDLOCK` sobre `conf.Parametros`). No se declara el mes en curso. Actualiza `FiscalDeclaradoHasta`, que la aplicación no puede escribir (`DENY`, G:9279). | G:9101 · M/SqlMigracionesOla4b.cs:116 | Confirmación contable, F-6 y F-7 | Sí (`ConsultasPeriodoFiscal.cs:40`) | a + b |

### 3.5 `inv`: kárdex, período cerrado, conteo y unidades

| Regla | Qué protege | Dónde | Origen | API | Clase |
|---|---|---|---|---|---|
| **51333** `TR_Movimiento_PeriodoCerrado` | Ningún movimiento de inventario entra con fecha igual o anterior al cierre. Retiene S sobre `conf.Parametros` (`REPEATABLEREAD`) para que el cierre espere a los movimientos en vuelo. Excepciones: incorporación (K-06) y reaplicación. | G:6016 · M/SqlMigracionesOla3Firmas.cs:22 | ADR-69 (punto 3: «disparador 51333 como red»), T-27 | Sí (`FechasDocumento.cs:41`, `PeriodoInventario`) | a + b |
| `TR_CierrePeriodo_Reemplazo` | La foto de un mes reabierto no se pierde: pasa entera a `CierrePeriodoReemplazado`. | G:9118 · M/SqlMigracionesOla4b.cs:135 | HC-06, precisión de ADR-69 | Diseño | a |
| **51318 / 51386 / 51302** `TR_Conteo_Inmutable`, `TR_ConteoLinea_Corte` | El corte del conteo no se mueve. La existencia del corte no cambia. Tras el corte solo entran artículos con existencia 0. La unidad de la línea es la vigente y no cambia. | G:5148, G:10664 · M/SqlMigracionesOla3.cs:307, M/SqlMigracionesOla4FactorUnidad.cs:123 | CA-22, ADR-78 (9) | Construye | c |
| **51376** `TR_MotivoAjuste_ClaseInmutable` | Un motivo de ajuste usado no cambia de clase (merma o consumo interno). | G:9127 · M/SqlMigracionesOla4b.cs:146 | MOTIVO_EN_USO | **No (solo base)** | a |

### 3.6 `cat`: códigos y significado de los maestros

| Regla | Qué protege | Dónde | Origen | API | Clase |
|---|---|---|---|---|---|
| **51310** `TR_Articulo_Codigo`, `TR_Cliente_CodigoInmutable`, `TR_Suplidor_CodigoInmutable` | El código de un maestro con movimientos no cambia. | G:5181, G:5193, G:5204 · M/SqlMigracionesOla3.cs:347-374 | P-3, F-04, principio rector (códigos inmutables) | Sí (`ErroresNumeracion.cs:393`) | a |
| **51319** `TR_ArticuloCodigo_SinColision` y `TR_Articulo_Codigo` | Un código alterno nunca es el código interno de otro artículo. | G:2406, G:5190 · M/SqlMigracionesMae.cs:29 | CA-08 | Sí (parcial) | b |
| **51340** `TR_MotivoAnulacion_Inmutable` | Un motivo de anulación usado no cambia su código ni su tipo del 608. | G:6066 · M/SqlMigracionesOla3Firmas.cs:82 | ADR-71, P-3 | Sí | a |
| **51383 / 51384 / 51385** `TR_ArticuloUnidad_Factor`, `TR_Articulo_UnidadBase` | El factor de una unidad usada no cambia. La unidad base tiene factor 1. La unidad base de un artículo con movimientos no cambia. | G:10630, G:10648 · M/SqlMigracionesOla4FactorUnidad.cs:74, :94 | ADR-78 (R7) | Sí (parcial) | a |

### 3.7 `num` y `org`: numeración y sucursales

| Regla | Qué protege | Dónde | Origen | API | Clase |
|---|---|---|---|---|---|
| **51201** `num.TR_Serie_Prefijos` | Regla de choque de prefijos R-D3′ contra las otras series y los prefijos reservados. Toma `UPDLOCK` sobre `num.Configuracion`. | G:5229 · M/SqlMigracionesOla3.cs:404 | ADR-46 | Sí (`ErroresNumeracion.cs:381-383`) | b |
| **51204** | Falta la fila de configuración: esquema sin aplicar. | G:5237 | ADR-45 | Diseño | a |
| **51203** `org.TR_Sucursal_CodigoNumeracion` | Choque de códigos de numeración entre sucursales, con la misma regla y el mismo bloqueo. | G:5261 · M/SqlMigracionesOla3.cs:438 | ADR-46, precisión del 2026-10-03 | Sí | b |
| **51378** `org.TR_Caja_AlmacenConJornada` | Una caja con jornada abierta no cambia de almacén ni de sucursal. | G:9164 · M/SqlMigracionesOla4b.cs:172 | CAJA_CON_JORNADA_ABIERTA | Sí (`ConsultasConfiguracion.cs`) | b |

### 3.8 `sync`: rango del nodo y base restaurada (H-11)

| Regla | Qué protege | Dónde | Origen | API | Clase |
|---|---|---|---|---|---|
| **51332** `TR_*_RangoNodo` (13 tablas) | Toda llave de secuencia pertenece al rango del nodo local (`NodoId × 10¹²`). Solo la incorporación con su marca de sesión admite otra. | G:5460-5567, G:7774 · M/SqlMigracionesOla3RangoNodo.cs:36 | E1-1, K-62, ADR-53 | Diseño | a |
| **51330** `caja.TR_Movimiento_Nodo` | La misma guarda MD-59 para los movimientos de caja. | G:5171 · M/SqlMigracionesOla3.cs:334 | ADR-53 cláusula 9 | Sí | a |
| **51328 / 51329** `usp_AbrirReconciliacionLocal`, `usp_ConfirmarReconciliacionLocal` (`EXECUTE AS OWNER`) | Desbloqueo sin central: solo una base realmente restaurada y sin otros nodos activos. Confirmación con las reglas C0 a C8 (completitud de NCF, ningún NCF vigente ya usado, series adelantadas). | G:12432, G:12477 · M/SqlMigracionesH11.cs:41, :90 | ADR-53 cláusula 9, H-11 (RN-24), precisión del 2026-10-10 | Sí (el servicio comprueba antes; `ErroresNumeracion.cs:427-434`) | a + b |
| **51389** `TR_Reconciliacion{Ncf,Serie,Chequera}_Abierta` | El registro de una reconciliación solo se escribe mientras está abierta. | G:12603-12619 · M/SqlMigracionesH11.cs:248 | S-02 | Diseño | a |
| **51331** `usp_AdelantarSecuencias` | Adelanta las secuencias de llave en una reconciliación en curso. **Hoy ningún código lo llama** (búsqueda en `src`). | G:5388 · M/SqlMigracionesOla3.cs:605 | ADR-53 cláusula 9 (4), entrega 2 | — | a (entrega 2) |

### 3.9 `audit`: bitácoras de solo inserción

| Regla | Qué protege | Dónde | Clase |
|---|---|---|---|
| `DENY UPDATE, DELETE ON audit.Bitacora` | La bitácora no se reescribe. | G:1141 | a |
| `DENY UPDATE, DELETE ON dbo._LOG` | Bitácora heredada de solo inserción (última migración). | G:13936 · M/SqlMigracionesBitacoraLog.cs | a |
| `CK_Bitacora_Detalle` | El detalle es JSON válido. | G:523 | c |

### 3.10 Privilegios negados (`DENY`) como regla de negocio

Estos `DENY` hacen la mitad del trabajo de inmutabilidad sin costo de ejecución. Todos son de clase **(a)**.

- **Ni `UPDATE` ni `DELETE`** para la aplicación (`gpos_app`) sobre:
  - `doc.Autorizacion`, `doc.Impresion`;
  - `inv.Movimiento`, `caja.Movimiento`, `caja.ConteoCiego`;
  - `fiscal.Comprobante`, `cxc.ReciboCredito`, `cxp.Compensacion`, `cxp.Regularizacion`, `fiscal.PeriodoDeclarado`;
  - los registros de reconciliación.
- **Sin `DELETE`** sobre `doc.Documento`, `fiscal.SecuenciaNcf`, `fiscal.NcfZonaIncierta`, `num.PrefijoReservado` y `fiscal.Registro606`.
- **Sin `UPDATE`** sobre `inv.CierrePeriodo` y sobre la columna `conf.Parametros.FiscalDeclaradoHasta`.
- **Catálogos fiscales de solo lectura:** `fiscal.TipoAnulacion`, `fiscal.TipoRetencionIsr` y `cat.ConceptoNota`.
- **`sync.Nodo` y `sync.EstadoNodo`:** solo los cambian los procedimientos `EXECUTE AS OWNER`.
- **`DENY ALTER`** sobre los esquemas `num` y `sync`.
- **Tablas `dbo` retiradas de la ola 4:** sin escritura.

Evidencia: G:444-445, G:2458-2459, G:5429-5439, G:6027, G:6046, G:6164, G:8157-8160, G:9277-9280, G:9756, G:11728, G:12634-12636, G:13936.

### 3.11 Restricciones `CHECK`, `UNIQUE` y FK con significado de negocio

La lista completa de las 284 `CHECK` vigentes, con línea, se puede regenerar del guion; aquí van las de significado de negocio. Las enumeraciones de dominio («Estado IN …», «Tasa > 0», porcentajes entre 0 y 100) son de clase **(c)**: cuestan casi nada y atajan errores de captura o del programa.

| Restricción | Qué protege | G | Clase |
|---|---|---|---|
| `UQ_Documento_Numero`, `UQ_Documento_Uid` | Un número es único en la empresa (ADR-48). Idempotencia del envío. | 4230, 4238 | a |
| `UQ_Comprobante_Ncf`, `CK_Comprobante_Ncf`, `CK_Comprobante_Reemplazo`, `CK_Comprobante_ContingenciaB` | Un NCF no se repite. Forma B11 o E13 coherente con el tipo. El reemplazo solo es un E con código 4. | 3990, 3102-3107, 7202 | a |
| `CK_SecuenciaNcf_Rango`, `_Prefijo`, `_Cierre`, `CK_RangoAutorizado_Rango` | `Siguiente` dentro del bloque. Prefijo y dígitos B/E. Bloque cerrado con fecha. | 2945-2948, 2819 | a |
| `CK_Documento_Provisional`, `CK_Documento_Origen` | El borrador sin número (origen P) solo existe en borrador, con número «~». | 6235, 9319 | a (ADR-72) |
| `CK_Documento_Anulacion`, `CK_Documento_Emision`, `CK_Documento_Codigo608`, `CK_Documento_MotivoSinNcf` | Datos de la anulación completos. Emitido con fecha de emisión. Código del 608 válido. | 3020-3025 | a |
| `UX_Cierre_ZPorJornada`, `UX_Cierre_NumeroZ` | Un Z por jornada (precisión de ADR-17). Número de Z único por caja. | 3926, 3918 | a |
| `UX_Jornada_CajaAbierta`, `UX_Jornada_CajeroAbierta` | Una jornada abierta por caja y por cajero. | 4294, 4302 | b |
| `UX_Movimiento_Revertido`, `UX_CajaMovimiento_Revertido` | Un movimiento se revierte una sola vez. | 4422, 4374 | b |
| `UX_Movimiento_DocumentoLinea` | Un movimiento de kárdex por documento, línea, artículo, almacén y lote (ADR-78). | 11107 | b |
| `CK_Existencia_Negativa`, `CK_ExistenciaLote_Negativa` | Existencia nunca negativa salvo permiso explícito (antecedente de ADR-118). | 2716, 2913 | b |
| `CK_Cuenta_Saldo`, `CK_Credito_Saldo`, `CK_CxpCuenta_Saldo`, `CK_CxpCredito_Saldo`, `CK_CupoSinConexion_Consumo`, `CK_ClienteSaldo_Saldo` | Ningún saldo es negativo ni supera su monto. Ningún cupo sin conexión se sobrepasa. | 3167, 3146, 6734, 6712, 2674, 2635 | b |
| `CK_Venta_Totales`, `CK_VentaLinea_Importe`, `CK_Compra_Total` | Total = subtotal − descuento + impuesto (+ cargo). Importe de línea con la regla de redondeo única. | 3577, 3729, 6911 | c |
| `CK_Movimiento_Unidad`, `CK_Movimiento_Costo`, `CK_Movimiento_Ajuste`, `CK_Movimiento_Valor` | Coherencia del kárdex (ADR-78, R5). | 11115, 10518, 3292, 11594 | c |
| `UX_Registro606_Ncf` | Un NCF recibido es único por RNC entre los vigentes. | 7554 | a |
| `CK_Parametros_FiscalDeclarado`, `CK_PeriodoDeclarado_*` | El período declarado es fin de mes y avanza o retrocede con sentido. | 8598, 8530-8532 | a |
| `CK_Parametros_LoteVencido` (`'B','A'`) | Permite la opción «A» que ADR-119 retiró. | 846 | **d** |
| `CK_NumSerie_*`, `UX_NumSerie_Prefijo`, `UQ_PrefijoReservado_Prefijo`, `UX_Sucursal_CodigoNumeracion` | Forma de los prefijos y subseries (alfabeto sin I, O ni Q). Prefijo único. Reservas. | 3798-3846, 2549, 4486, 1114 | a |
| `CK_Nodo_Central`, `CK_EstadoNodo_*`, `CK_Reconciliacion*`, `CK_NcfZonaIncierta_*` | Identidad del sitio y estados de la reconciliación (ADR-53 cláusula 9). | 361-381, 2845, 3049, 3325-3330, 12371-12411 | a |
| 253 FK sin cascada | Eliminar solo sin referencias, en la misma operación y sin carreras (ADR-08, precisión del 2026-10-04). | — | a |

### 3.12 Vistas con lógica (`rpt`, `rptc`, `num`, `sync`, `inv`)

| Vista | Lógica de negocio | G | Clase |
|---|---|---|---|
| `rpt.Formato607`, `rpt.Formato608`, `rpt.Formato606` | Formatos fiscales:<br>– excluyen los e-NCF (serie E, regla del propietario del 2026-10-08, ADR-108);<br>– ITBIS en 0 fuera del plazo fiscal;<br>– formas de pago en moneda base con el ajuste de centavos a la forma mayor;<br>– zonas inciertas anuladas al 608. | 10299, 10240, 8135 | a (fiscal, aplazados por el ERP) |
| `rpt.Conciliacion*` (14), `rpt.DocumentosPeriodoReabierto`, `rpt.DocumentosFechaAnterior`, `rpt.NcfZonaIncierta`, `rpt.Autorizaciones`, `rpt.NegativoPorRegularizar`, `rpt.LoteNegativo` | Diagnósticos de solo lectura que prueban los invariantes de saldo, existencia, crédito, órdenes y período. No impiden nada. | 5310-5376, 6150-6160, 8074-8128, 9180-9242, 9361-9374, 13481-13521 | c (auditoría) |
| `rpt.*` y `rptc.*` de la ola 5 (contrato 1.2) | Superficie de lectura de la API de reportes. `rptc` lleva costos y la niega a `gpos_reportes` (G:13891). | 12725-13877 | a (aislamiento, ADR-38, ADR-109) |
| `num.SerieCodigoSucursal`, `num.PrefijoReservadoCodigoSucursal`, `num.ConfiguracionHeredada` | Compatibilidad con los nombres heredados de la numeración de `master`. | 5289-5301 | **d** (ADR-47 retirado por ADR-52) |
| `sync.EstadoEmision` | Expone si la base está restaurada (fork) y si hay otros nodos. | 12419 | a |
| `inv.ExistenciaGlobal` | Existencia total por artículo, sin regla. | 5306 | c |

### 3.13 Guardas de migración (no son reglas de operación)

51394, 51397, 51398 y 51399 detienen una migración si los datos existentes no cumplen la regla nueva: G:6194, G:6523, G:8205, G:8250-8254, G:10471, G:11080-11082, G:11468, G:11714, G:12330, G:12722. Corren una vez y no tienen costo en la operación. Se mantienen.

---

## 4. Por qué vive cada regla en la base

### 4.1 Criterio

Una regla debe vivir en la base cuando se cumple al menos una de estas condiciones:

1. **Debe sobrevivir a cualquier escritor (clase a).** La base de empresa la escriben la API, el futuro comando `GPOS.Migracion`, la incorporación de nodos (entrega 2, con la marca `gpos.incorporacion`), los procedimientos `EXECUTE AS OWNER` y, en el peor caso, una persona con SQL directo.
   - La cláusula 9 de ADR-53 exige que **«la base lo detecte por sí misma … y falle cerrada»**.
   - ADR-69 (punto 3) nombra el disparador 51333 como **la red** del período cerrado.
   - ADR-08 pide la garantía de borrado **«en la base, en la misma operación y sin carreras»**.
2. **Debe evaluarse en la misma transacción que la escritura (clase b).** Si la regla compara con filas que otra transacción puede cambiar, comprobarla en el servicio deja un hueco entre la lectura y la escritura.

Matiz importante:
- **Con RCSI** (activado por `Aprovisionamiento.cs:366-368`, MD-11), un `SELECT` dentro de un disparador lee la última versión confirmada, no la que otra transacción tiene a medias. **(Comportamiento documentado de SQL Server; inferido para estas reglas.)**
- Por eso un disparador cierra el hueco de concurrencia **solo** en tres casos:
  - cuando lee con indicación de bloqueo (`UPDLOCK`, `HOLDLOCK`, `REPEATABLEREAD`): 51201, 51203, 51324, 51333, 51373, `TR_Documento_Ola4b`, `TR_CierrePeriodo_Reemplazo`;
  - cuando es una restricción declarativa: `UNIQUE`, `CHECK` de fila o FK, que SQL Server valida con bloqueos aun con RCSI;
  - cuando lee filas que la propia transacción ya bloqueó, como el saldo de la nota que la aplicación acaba de actualizar en 51338.
- En las demás reglas de la clase (b), lo que cierra la carrera es el **orden único de bloqueos** de ADR-45 en el servicio (jornada → documentos → configuración → …). El disparador da la garantía de que el resultado final es coherente.

### 4.2 Clasificación

| Clase | Reglas | Fundamento firmado |
|---|---|---|
| **(a) Invariante fiscal o de integridad** | 51300, 51301, toda la familia 51302 y `DENY`; 51322, 51323, 51327; 51324 a 51326; 51390; 51373; 51371, 51372; 51333 y el reemplazo de la foto; 51330 (dos disparadores); 51332 (13 disparadores); 51328, 51329, 51331, 51389; 51320, 51321, 51345, 51346; 51312, 51336, 51337 (`Motivo608`); 51310, 51340, 51376, 51383 a 51385; 51341; 51204; `UQ_Documento_Numero`, `UQ_Comprobante_Ncf`, `UX_Registro606_Ncf`, `UX_Cierre_ZPorJornada`, `CK_Documento_Provisional`; las 253 FK sin cascada; las vistas fiscales y de aislamiento | ADR-48, ADR-52 (CA-01), ADR-53 cláusulas 2, 4 y 9 con H-10, H-11, H-12 y sus cuatro precisiones del 2026-10-10, ADR-69, ADR-71, ADR-72, ADR-78 (R7), ADR-08, ADR-17, ADR-108, ADR-109, RG-04/05 |
| **(b) Misma transacción** | 51201, 51203 (`UPDLOCK` sobre la configuración); 51306, 51317, 51378 (jornada); 51313 a 51316 (anulación completa); 51335, 51338, 51339, 51334 (saldo de la nota y recibo); 51355 (saldos CxP); 51358, 51405 a 51407 (estado de la orden); 51360 a 51364, 51366 (devoluciones a suplidor y regularizaciones); 51319; `UX_Jornada_*`, `UX_*Revertido`, `UX_Movimiento_DocumentoLinea`, `CK_*_Saldo`, `CK_Existencia_Negativa` | ADR-45 y sus precisiones (orden único de bloqueos; «toda operación que dependa del estado de un documento lo bloquea y lo relee»), ADR-46, ADR-70, MD-17, ADR-118 (política de negativos, decidida) |
| **(c) Defensa en profundidad** | 51303, 51304, 51305 (cuadres de venta); 51307 (lote obligatorio); 51309; 51311, 51318, 51386 (conteo); 51380 a 51382, 51344 (kárdex = líneas); 51342, 51343, 51347 a 51349, 51351 a 51354, 51356, 51357 (cuadres de compras, pagos y bancos); 51365, 51367 a 51370, 51374, 51375, 51377, 51379, 51359 (fechas y fiscal de oficina); la mayoría de las `CHECK` de dominio; las vistas de conciliación | Diseño de emisión del 2026-10-06 (§3.2, «garantías que se conservan»), `ErroresNumeracion.cs` (la base como red) |
| **(d) Heredado o sin razón fuerte** | 51312 repetida en `TR_Documento_Anulacion` (G:12205); la rama «A» de 51308 y `CK_Parametros_LoteVencido`; las 3 vistas `num.*Heredada/CodigoSucursal`; `usp_AdelantarSecuencias` sin llamador hasta la entrega 2 (no es heredado: está anticipado) | ADR-119 (precisión H-QA-02 del 2026-10-08), ADR-52 (retira ADR-47 en el corte) |

**Observación sobre la clase (c):**
- Varias reglas de (c) tienen además peso fiscal: 51379 (plazo de 30 días del Decreto 293-11), 51359 (ITBIS al costo del 606) y 51374 (retención recibida).
- Hoy **solo las valida la base**.
- Si se movieran, habría que reescribirlas en el servicio. No serían un duplicado que se borra.

---

## 5. Qué se podría mover a la aplicación sin perder seguridad

### 5.1 Lo que cuesta hoy (medido por otros, citado)

| Medición | Valor | Fuente |
|---|---|---|
| `TR_Documento_Emision`, un hilo | 0,25 a 0,28 ms | recalibración del 2026-10-10, línea 12 |
| `TR_Documento_Emision`, bajo carga (6 cajeros) | 0,405 a 0,434 ms (tope recalibrado: < 0,55 ms; antes < 0,4) | ídem |
| Suma de los 5 disparadores de `UPDATE` de la venta tras aligerarlos | 0,33 ms; el `UPDATE` sin disparadores cuesta 0,15 ms | diseño del 2026-10-06, §2.2 |
| Sentencia de emisión completa (`UPDATE doc.Documento … Numero`) | 1,43 a 1,50 ms de CPU, 123 lecturas | estudio del número al final, §1.1 |
| Tramo de una venta con la serie tomada | unos 5 ms (200 ventas/s); con compras, de 6 a 7 ms (inferido allí) | ídem |
| `TR_Documento_Ola4` en el POS (sale enseguida) | 0,022 ms | ídem, tabla de §2 |
| `TR_Documento_Ola4` con compras (promedio) | 0,91 a 1,22 ms | ídem |
| `UPDATE` de emisión de una FCP de 20 líneas | 17,4 a 24,2 ms → **12,5 a 12,9 ms** con el PR #21 (−35 %) | PR #21 de C |
| Compilación de la regla 51344 | 91 ms → 36 a 37 ms con el PR #21 | ídem |
| I-2 de F-R1 | unos 15 ms por emisión que no es del POS en `TR_Documento_Ola4` | hoja de rendimiento de la ola 4, F-R1 |
| `KEEPFIXED PLAN` (rechazado) | con planes congelados, el disparador llegó a 4,6 ms | recalibración, línea 12 |

### 5.2 Relación con el principio firmado «número al final del guardado»

- **D-1 y D-3** (firmadas el 2026-10-09, se construyen desde el 2 de noviembre): número, NCF, comprobante, bitácora y **emisión** van juntos en el lote final, con la serie tomada.
- El estudio lo dice expresamente: la sentencia de emisión «se ejecuta hoy con la serie tomada y **seguirá así** en el diseño propuesto» (§1.1, línea 49).
- La causa está en `TR_Documento_Inmutable` (51301): impide emitir primero y numerar después, alternativa A7 descartada (estudio, línea 110).
- **Consecuencia:**
  - Con el número al final, los disparadores de emisión son **una parte mayor** del tramo retenido, porque el resto del trabajo sale de ese tramo.
  - Con unos 0,4 ms de `TR_Documento_Emision` más unos 0,15 ms del resto, la emisión sigue siendo menos del 3 % de los 52 ms de la meta (recalibración, línea 12).
  - En la venta, **no es el cuello de botella**. En la compra, `TR_Documento_Ola4` sí pesa (unos 12 a 24 ms), pero menos que el recálculo de costo (de 1 a 2 s), que resuelve M-C.
- **Advertencia de la propia hoja:** un supermercado real hace de 0,2 a 0,5 ventas/s (inferido allí). La serie está ocupada menos del 0,3 % del tiempo. Cualquier ahorro de 0,3 ms en la venta será invisible para el cliente.

### 5.3 Candidatas, una por una

Solo se evalúan las reglas de la clase (c) y las de la clase (b) cuyo hueco ya cierra el servicio. Las de la clase (a) están en la sección 5.4.

| Candidata | Qué se gana | Qué se pierde (escenario que ya no se atajaría) | Condición para moverla | Recomendación |
|---|---|---|---|---|
| **Cuadres de la venta 51303, 51304, 51305** | De 0,10 a 0,15 ms de CPU por venta (inferido: en la versión anterior al aligerado, CA-12 costaba 125 µs, CA-10 54 µs y CA-11 47 µs, diseño §2.3; hoy son menores). | Un error de redondeo o de armado en `Calculadora`, un importador nuevo o la incorporación de un nodo guardarían una venta cuyo resumen por impuesto no cuadra. Ese resumen alimenta el Z, el 607 y el e-CF. El error aparecería en la DGII, no al guardar. | Pruebas de propiedad sobre `Calculadora` y conciliación diaria (`rpt.Conciliacion*`) con alerta. Aun así perdería la red ante la incorporación de nodos de la entrega 2. | **Mantener** |
| **Kárdex = líneas 51380, 51381, 51382 y 51344** | En la venta, menos de 0,1 ms (inferido). En la compra, la mayor parte de los 12,5 ms tras el PR #21 (51344 es la regla cara por su tabla derivada). | Un error del programa descuadra existencia y costo sin aviso. El costo promedio es la base del costo de venta y de M-C. | Que M-C (foto mensual) y el cierre de período detecten el descuadre a tiempo. Hoy no lo hacen en la misma transacción. | **Mantener y simplificar:** unir el PR #21 y evaluar después del 14 de octubre si 51344 puede reutilizar las sumas que ya calcula el servicio |
| **Fechas de oficina F-1, F-2 y F-6 (51367, 51368, 51371) en `TR_Documento_Ola4b`** | Una lectura de `conf.Parametros` por documento de oficina; nada en el POS, que sale en la primera consulta (G:9791). | F-6 (período declarado) es fiscal y su carrera la cierra el `REPEATABLEREAD` del disparador frente a la declaración (51373). Moverla abre el hueco: un documento en vuelo entra en un mes que se declara al mismo tiempo. | Ninguna razonable: el servicio ya la valida y el disparador es la única barrera sin carrera. | **Mantener** (F-1 y F-2 cuestan casi nada) |
| **Reglas de 4b que solo valida la base: 51379, 51362, 51374, 51375, 51359** | Nada medible: corren solo en documentos de oficina. | Si se mueven, hay que **escribirlas** en el servicio: hoy no existen allí (búsqueda en `src`). Mientras tanto, no habría ninguna barrera. | — | **Mantener en la base y agregar pruebas** (no se localizó ninguna prueba que las cite por número ni por código; sección 6.4) |
| **Conteo 51311, 51318, 51386** | Nada en el POS: solo corre en el conteo (CNT). | Un ajuste de conteo que no cuadra con «contado − corte». | — | **Mantener** |
| **Cuadres de compras, pagos y bancos 51342, 51343, 51347 a 51357** | Una parte de los 0,9 a 1,2 ms promedio de `TR_Documento_Ola4` con compras. | Saldos de CxP descuadrados o anulaciones parciales; además, sincronización con el ERP (ADR-73) a partir de datos incoherentes. | — | **Mantener** (la compra es poco frecuente; F-R1 ya fijó corregir sin cambiar reglas) |
| **51312 en `TR_Documento_Anulacion`** | Una consulta menos por anulación (µs). | Nada: `TR_Documento_Motivo608` comprueba lo mismo y más, con el mismo número (G:6488-6492). | Que una prueba confirme que 51312 sigue saliendo por `Motivo608`. | **Quitar de `Anulacion`** (dentro de la base, no a la aplicación) |
| **Rama «A» de 51308 y `CK_Parametros_LoteVencido`** | Nada medible. | Nada: ADR-119 la retiró. Hoy contradice lo firmado. | Migración de la tanda T4 del equipo A (ya asignada en ADR-119). | **Retirar** con T4 |
| **Vistas `num.*` de compatibilidad** | Ninguno de rendimiento; menos superficie. | Las usa todavía el `EmpresaDbContext` heredado (búsqueda: `ConjuntoPrefijos.cs`, `NumeracionService.Diagnostico.cs`). | Corte de la entrega 1 (ADR-52 retira `_CNumeracion`). | **Retirar en el corte** |
| **`CHECK` de dominio** (enumeraciones, `Tasa > 0`, porcentajes) | Ninguno: se evalúan por fila, en microsegundos y sin lecturas. | Datos fuera de dominio escritos por un importador o por SQL directo. | — | **Mantener** |

### 5.4 Lo que no debe moverse nunca, y por qué

| Regla | Por qué nunca |
|---|---|
| 51300, 51301, familia 51302, `DENY` de solo inserción, `TR_Cierre_Inmutable`, `TR_Registro606_Inmutable` | **Inmutabilidad de lo emitido.** Debe resistir a cualquier escritor, incluida una persona con SQL. Es la evidencia ante la DGII y ante el auditor. Los `DENY` no cuestan nada y los disparadores de extensión solo corren cuando se escribe una fila de detalle. |
| 51322, 51323, 51327, 51324 a 51326, 51390, `UQ_Comprobante_Ncf`, `CK_SecuenciaNcf_*`, `CK_Comprobante_*` | **NCF.** Un NCF repetido, fuera de bloque o de un bloque cerrado por restauración es un incumplimiento fiscal que no se corrige después. 51324 necesita `UPDLOCK, HOLDLOCK` para no tener carrera entre dos altas de bloque. |
| 51330 (dos disparadores), 51328, 51329, 51389, `EXECUTE AS OWNER`, `CK_EstadoNodo_*` | **Base restaurada.** La cláusula 9 de ADR-53 exige que la base lo detecte **por sí misma** y falle cerrada. Una API vieja, otra instancia o una restauración manual no pasan por el servicio. |
| 51332 (rango del nodo) | **Llaves de nodo (entrega 2).** La incorporación de un nodo y la reaplicación escriben fuera del camino normal. Sin esta regla, una llave ajena colisiona en la central sin aviso. |
| 51333, `TR_CierrePeriodo_Reemplazo`, `DENY UPDATE ON inv.CierrePeriodo` | **Período de inventario cerrado** (ADR-69: «disparador 51333 como red»). El `REPEATABLEREAD` hace que el cierre espere a los movimientos en vuelo, cosa que el servicio solo no puede garantizar. |
| 51371, 51372, 51373, `DENY UPDATE` de `FiscalDeclaradoHasta` | **Período fiscal declarado.** «Sin privilegio que lo salte» (G:9797). La declaración y el documento en vuelo se ordenan por el bloqueo de `conf.Parametros`. |
| 51320, 51321 | **Sin NCF, solo con motivo y con autorización** (RG-04/05; regla del propietario de no fomentar «No generar comprobante»). |
| `UQ_Documento_Numero`, `UX_*` de unicidad, `UX_Jornada_*`, `UX_Cierre_ZPorJornada`, FK sin cascada | **Unicidad y referencias.** Son las únicas garantías sin carrera posibles. ADR-48 y ADR-08 las piden en la base. |
| 51310, 51340, 51376, 51383 a 51385 | **Significado de los maestros.** Un código o un factor cambiado en un maestro con historia reescribe en silencio el significado de la historia. Además, la réplica a los nodos (entrega 2) copia maestros sin pasar por el servicio. |
| 51341 | **Dueño por sitio** (ADR-53 cláusulas 2 y 4). En la entrega 2, un nodo con una API desactualizada no debe poder emitir compras. |

---

## 6. Costos y riesgos actuales

### 6.1 Rendimiento

- **Venta.**
  - Las reglas de la base cuestan unos 0,33 a 0,43 ms de los unos 5 ms que la venta retiene la serie.
  - Con el número al final, ese costo sigue dentro del tramo retenido (sección 5.2).
  - Es aceptable y está vigilado: tope de 0,55 ms de la prueba 8.2 (5) de T-28 y prueba de planes 8.2 (6), sin recorridos ni concesión de memoria.
- **Compra.**
  - `TR_Documento_Ola4` es el disparador caro: de 12 a 24 ms con la serie `FacturaCxp` tomada, más 91 ms de compilación de la regla 51344 (36 ms con el PR #21).
  - Su causa es la tabla derivada `inserted ⋈ deleted ⋈ TipoDocumento`, repetida en cada regla (G:11744 y siguientes).
  - El PR #21 la carga una sola vez para 51344. La variante de cargarla para todas las reglas empeoraba el cheque, la caja chica y el depósito entre 0,25 y 0,4 ms.
- **Recompilaciones.**
  - Los disparadores grandes tienen planes muy sensibles a las estadísticas: con planes congelados llegaron a 4,6 ms.
  - `KEEPFIXED PLAN` está rechazado, con razón (recalibración, línea 12).
  - Es un riesgo latente: un cambio de estadísticas en producción puede producir un pico. Lo vigila la prueba de planes.

### 6.2 Mantenimiento

- **Las reglas están en dos lugares.**
  - Unas 35 reglas tienen validación previa en el servicio y repetición en la base (columna «API: Sí»).
  - El mapeo `ErroresNumeracion.cs` registra «la validación previa debió detectarlo» en 15 casos.
  - Cada cambio de regla toca el servicio, el disparador, el mapeo del error y dos pruebas.
- **El texto vigente no se lee en un solo lugar.**
  - Los disparadores grandes se arman con **39 parches de cadena** (`Parchear`, `ParchearSql`, `LoteDe`, `Replace`) en **10 archivos** de migraciones.
  - Ejemplo: el `TR_Documento_Ola4b` vigente es un parche de `SqlMigracionesOla4Huecos.cs:29`, sobre otro de `SqlMigracionesOla4Conversion.cs:51`, sobre el texto de `SqlMigracionesOla4b.cs:199`.
  - `TR_Documento_Emision` tiene 7 versiones en el guion; la vigente sale de `SqlMigracionesOla4OrdenRecibida.cs:256-290`, encima de `EmisionConAjustes()`.
  - Para revisar una regla hay que leer el guion acumulado (G) o regenerarlo.
  - **Riesgo Medio:** un parche que no encuentra su marca falla al armarse, pero un parche que encuentra una marca equivocada pasa sin error **(inferido)**.
- **Nueve disparadores sobre `doc.Documento`** (7 de `UPDATE`) cuyo orden de ejecución no está fijado. Solo es determinista en la práctica porque cada uno tiene su propio filtro.
  - Si dos fallan en el mismo `UPDATE`, el código devuelto depende del orden **(inferido)**.
  - El diseño del 2026-10-06 (§3.2) acota el caso a emisiones de varias filas, que la aplicación no hace.

### 6.3 Concurrencia y RCSI

- Con RCSI, solo las reglas con indicación de bloqueo o declarativas cierran por sí mismas el hueco entre la lectura y la escritura (sección 4.1).
- Las demás reglas de la clase (b) dependen del orden de bloqueos del servicio (ADR-45).
- No es un defecto. Pero quien mueva una regla de (b) al servicio debe saber que la garantía nunca fue solo del disparador.

### 6.4 Pruebas

- Hay 27 archivos de prueba que citan números de regla.
- **No se localizó ninguna prueba** que cite por número o por código de la API estas reglas:
  - **solo base:** 51379 (`PLAZO_FISCAL`), 51362 (`DEVOLUCION_EXCEDE`), 51374, 51375, 51359, 51376 (`MOTIVO_EN_USO`);
  - **inmutabilidad y NCF:** 51302 (toda la familia), 51322 y 51323;
  - **otras:** 51308, 51310, 51314 a 51317, 51326, 51334, 51338, 51341, 51342, 51346 a 51351, 51353 a 51358, 51360, 51361, 51363, 51369 (salvo un caso por código), 51370 y 51377.
- Pueden estar cubiertas por pruebas que comprueban el mensaje o el efecto **(no verificado)**.
- **Riesgo Medio:** las reglas que solo valida la base son, por definición, las que solo una prueba de base puede vigilar.

### 6.5 Bases contenidas (`COLLATE CATALOG_DEFAULT`)

- La precisión P-B1 de ADR-54 (firmada el 2026-10-10) exige `COLLATE CATALOG_DEFAULT` al comparar columnas del catálogo con datos, variables de tabla o `#temp`. La ola 5 ya pasa bases a `CONTAINMENT = PARTIAL` (`src/GPOS.Migracion/Lectura/CredencialesLectura.cs:159`).
- El guion de empresa tiene **0** cláusulas `CATALOG_DEFAULT`.
- **Disparadores:** solo leen el catálogo por columnas sin intercalación (`sys.database_recovery_status.recovery_fork_guid`, `database_id`). **Sin riesgo** (verificado en G:11967-11972 y G:5174-5176).
- **Procedimientos:**
  - `usp_AdelantarSecuencias` compara `sys.sequences.name` con un `VALUES` literal y con variables `sysname` (G:5401-5416).
  - `usp_ConfirmarReconciliacionLocal` no compara texto del catálogo en las reglas C0 a C8 que revisé.
  - Por las reglas de precedencia de intercalación, un literal no debería chocar con una columna del catálogo **(inferido)**. No está probado en una base contenida, y el procedimiento hoy no tiene llamador.
  - **Riesgo Bajo.** Agregar una prueba antes de la entrega 2.
- **Columnas de datos:** las comparaciones de texto entre columnas usan `Latin1_General_100_BIN2` o `Latin1_General_BIN` explícitas (19 casos en G). No dependen de la intercalación del catálogo.

### 6.6 Hallazgos

| ID | Severidad | Hallazgo | Evidencia | Remediación |
|---|---|---|---|---|
| RB-01 | Media | La rama «lote vencido con autorización» (51308 con `LoteVencido = 'A'`) y `CK_Parametros_LoteVencido IN ('B','A')` siguen vivas. ADR-119 las retiró (precisión H-QA-02). | G:12045, G:846; ADR-119:37 | Tanda T4 del equipo A, ya asignada |
| RB-02 | Media | Reglas fiscales que solo valida la base (51379, 51359, 51374, 51375, 51362, 51376) sin prueba localizada. | sección 6.4 | 0,5 a 1 día de QA: una prueba por regla (inferido) |
| RB-03 | Media | El texto vigente de 3 disparadores se arma con 39 parches en 10 archivos. | sección 6.2 | Consolidar el texto completo de cada disparador en un archivo único en la próxima migración que los toque (sección 7) |
| RB-04 | Baja | 51312 está en dos disparadores; el de `Anulacion` es redundante. | G:12205, G:6492 | Quitarlo en la próxima migración que toque `TR_Documento_Anulacion` |
| RB-05 | Baja | Procedimiento sin prueba en una base contenida. | sección 6.5 | Prueba antes de la entrega 2 |
| RB-06 | Baja | Vistas `num.*` de compatibilidad, que retira el corte. | G:5289-5301 | Retirar en el corte de la entrega 1 |
| RB-07 | Baja (ya en curso) | `TR_Documento_Ola4` repite la tabla derivada en cada regla. | G:11744 y siguientes; PR #21 | Unir el PR #21 después del 14 de octubre, regenerando la migración si H-11 se une antes |

---

## 7. Recomendación final

1. **Mantener en la base todas las reglas de las clases (a) y (b).** Es lo que piden ADR-53 cláusula 9, ADR-69, ADR-48, ADR-08 y ADR-45. Su costo en la venta está medido y acotado (menos de 0,55 ms, menos del 3 % de la meta).
2. **No mover a la aplicación ninguna regla de la clase (c) en la entrega 1.**
   - El ahorro máximo en la venta es de 0,1 a 0,3 ms (inferido) e invisible con el ritmo real de una tienda.
   - A cambio, se pierde la red contra los errores del programa, los importadores y la incorporación de nodos de la entrega 2, que escribe fuera del camino normal.
   - Reabrirlo solo si, después de la fase 1 del número al final (medición de noviembre), los disparadores de emisión superan el **10 % del tramo retenido con la serie** en T-28 o T-57.
3. **Regla de ubicación para las reglas nuevas** (propuesta para firma, P-1). Una regla nueva va a la base si es:
   - inmutabilidad, NCF o período;
   - sitio o nodo;
   - unicidad o saldo con concurrencia.

   Va solo al servicio si es de interfaz o de flujo. Y va a los dos lados solo si es (c) con peso fiscal, documentándolo en el mapeo de errores. Así se evita que la lista de reglas duplicadas crezca sin criterio. Ejemplo inmediato: ADR-118 (negativos), cuyo caso fijo ya prevé un `CHECK` (`CK_Articulo_NegativaControl`).
4. **Simplificar sin cambiar reglas:**
   - unir el PR #21 después del 14 de octubre;
   - quitar el 51312 redundante;
   - retirar la opción «A» con T4;
   - retirar las vistas `num.*` en el corte.
5. **Reducir el costo de mantenimiento:**
   - **escribir el texto completo** de cada disparador grande en la próxima migración que lo toque, en lugar de otro parche. El guion queda igual; el código fuente, legible. Esfuerzo inferido: de 0,5 a 1 día por disparador, sin cambiar reglas, con la prueba de equivalencia carácter por carácter que ya usa C;
   - fijar con `sp_settriggerorder` el primero y el último de `doc.Documento` solo si alguna prueba demuestra dependencia del orden. Hoy no hace falta.
6. **Cubrir con pruebas** las reglas de la sección 6.4 (RB-02): de 0,5 a 1 día de QA (inferido).

Costo de todo lo recomendado: **sin costo de infraestructura ni de licencias**. Esfuerzo inferido de 2 a 4 días-persona en total, repartidos entre T4 (A), el PR #21 (C, ya hecho) y una migración de consolidación (B o A), con un margen de ±50 %.

---

## 8. Hoja de firma

Ninguna de estas preguntas cambia lo que el usuario ve ni sus datos. Todas son internas.

| ID | Pregunta | Opciones | Recomendación | Firma |
|---|---|---|---|---|
| **RB-P1** | ¿Se adopta la **regla de ubicación** de la sección 7 (3) para toda regla nueva de la base de empresa? | A. Adoptar · B. Decidir caso por caso | **A.** Evita que crezcan las reglas en dos lugares sin criterio. Qué rompe: nada. A quién afecta: a los programadores y arquitectos (regla obligatoria). Cómo se migra: aplica solo a lo nuevo. | [ ] A · [ ] B |
| **RB-P2** | ¿Se mantienen en la base, sin mover a la aplicación, todas las reglas actuales de las clases (a), (b) y (c) durante la entrega 1, con revisión tras la medición de noviembre (umbral: 10 % del tramo con la serie)? | A. Mantener con revisión · B. Mover ya los cuadres de la venta (51303 a 51305) y del kárdex (51380 a 51382) | **A.** B ahorra de 0,1 a 0,3 ms por venta (inferido) y quita la red ante errores del programa y ante la incorporación de nodos. | [ ] A · [ ] B |
| **RB-P3** | ¿Se quita el 51312 redundante de `TR_Documento_Anulacion` (lo sigue comprobando `TR_Documento_Motivo608`)? | A. Quitar en la próxima migración que lo toque · B. Dejarlo | **A.** Sin efecto visible; un punto menos de mantenimiento. | [ ] A · [ ] B |
| **RB-P4** | Para las reglas fiscales que **solo valida la base** (51379, 51359, 51374, 51375, 51362, 51376): ¿se agregan pruebas de base sin duplicarlas en el servicio? | A. Solo pruebas · B. Pruebas y validación previa en el servicio | **A.** El mapeo de errores ya entrega el código de la API (`ErroresNumeracion.cs:421-425`); duplicarlas agrega mantenimiento sin seguridad nueva. B solo si el usuario necesita el aviso antes de llegar a emitir (no lo pide ninguna decisión). | [ ] A · [ ] B |
| **RB-P5** | ¿Se escribe el **texto completo** de `TR_Documento_Emision`, `TR_Documento_Ola4` y `TR_Documento_Ola4b` en la próxima migración que los toque, en lugar de otro parche? | A. Sí, con prueba de equivalencia · B. Seguir con parches | **A.** Esfuerzo inferido de 0,5 a 1 día por disparador; sin cambio de reglas; reduce el riesgo RB-03. Encaja con la construcción del número al final (noviembre), que tocará la emisión. | [ ] A · [ ] B |
| **RB-P6** | Confirmar que la tanda T4 del equipo A retira la rama «A» de 51308 y amplía `CK_Parametros_LoteVencido` solo a `'B'` (ADR-119, H-QA-02). | A. Confirmar en T4 · B. Adelantarla en una migración aparte | **A.** Ya está asignada; adelantarla mezcla migraciones con H-11 y con el PR #21. | [ ] A · [ ] B |

Si firma «Todo según recomendación»: RB-P1 A, RB-P2 A, RB-P3 A, RB-P4 A, RB-P5 A, RB-P6 A. El documentador registraría RB-P1 como precisión de ADR-52 (o de ADR-45, a criterio del Arquitecto Maestro). Ninguna de las seis exige un ADR nuevo.

---

## Cierre

- **Estado:** Completado (análisis). Las recomendaciones quedan Pendientes de firma.
- **Artefactos:** este documento (`scratchpad/inventario-reglas-en-base.md`). Destino propuesto en el proyecto: `docs/datos/2026-10-10-inventario-reglas-en-base.md`.
- **Supuestos:**
  - La versión vigente de cada objeto es la última `CREATE OR ALTER` del guion acumulado.
  - Un «No» en la columna API quiere decir no localizado por búsqueda de texto.
  - Las cifras de rendimiento son de las mediciones citadas, no de esta sesión.
  - El comportamiento de RCSI y de la intercalación en bases contenidas es el documentado de SQL Server (inferido para estas reglas; no se probó).
- **Decisiones candidatas a ADR:** RB-P1 (regla de ubicación de las reglas de negocio en la base), como precisión de ADR-52 o ADR-45.
- **Entregas a otros agentes:**
  - qa-automatizado → pruebas de RB-02 y RB-05;
  - equipo A → RB-01 en T4;
  - desarrollador-backend → RB-03 y RB-04 en la próxima migración de emisión;
  - documentador-tecnico → registrar el documento y la firma.
- **Próximo paso recomendado:** presentar la hoja RB-P1 a RB-P6 al propietario junto con la unión del PR #21 después del 14 de octubre.
