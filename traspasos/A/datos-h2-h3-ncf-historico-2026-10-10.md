# Blueprint de datos: H-2 (NCF histórico como comprobante, rol H) y H-3 (fecha de implantación), con la tanda H-4, H-6 y H-7

[Arquitecto de datos, equipo A] · 2026-10-10 · Rama `a/h2-ncf-historico` (desde `feature/modelo-ng` `e7f1f96`) · **Estado: propuesta de diseño; las preguntas P-1 a P-9 esperan la firma del propietario.**

Encargo: aviso `GPOS-NG-Equipos/avisos/B-a-A/2026-10-10-encargo-h2-h3-y-tanda.md`. Lo firmado está en ADR-11, precisiones del 2026-10-10, punto 3 (en `master`). El hallazgo de origen está en `avisos/A-a-B/2026-10-10-a3-seguridad-y-preguntas.md`.

Convenciones del documento:
- **[V]** = verificado en el código o en una base temporal.
- **[I]** = inferido.
- El guion acumulado vigente es `database/empresa/gpos-empresa-20261010130522_BitacoraLogSoloInsercion.sql`. En adelante lo cito como **[G]**.

---

## 1. Contexto y modelo de tenencia aplicado

**Modelo de tenencia.** Una base por empresa (CLAUDE.md, «Datos»). Todo lo que se diseña aquí vive dentro de la base de la empresa: no hay columna discriminadora ni datos entre empresas. `GPOS_SYSDATA` no cambia.

**Situación actual [V]**
- La importación de facturas históricas crea el documento con `Origen = 'I'` y `MotivoSinNcf = 'H'` (`DocumentosNg.cs:189-207`, `ConsultasDocumentos.cs:78-83`). El NCF del archivo se guarda solo en `ventas.Venta.Referencia` (`ImportacionesService.cs:451-454`).
- `ConsultasFiscal.NcfDocumento` lee únicamente `fiscal.Comprobante` con `Rol = 'O'` (`ConsultasFiscal.cs:87-90`). Por eso:
  - la devolución (`DocumentosComercialesService.Ventas.cs:223-225` y `PosService.cs:678`) y la nota de crédito o de débito (`CobrosService.cs:360` y `378-379`) de una factura histórica ven un origen «sin NCF»;
  - la excepción «origen sin NCF» las deja salir sin B04 ni E34 y sin el privilegio (`Ncf.cs:277-278`, `EmisionNcfNg.cs:101-108`).
- `fiscal.Comprobante.SecuenciaId` es `int NOT NULL`, y la tabla tiene estas restricciones ([G]:3082-3112, `FisConfiguracion.cs:88-98`):
  - `CK_Comprobante_Rol` = `Rol IN ('O','R')`;
  - `CK_Comprobante_Reemplazo` = `Rol = 'O' OR (E, código 4, NcfModificado)`;
  - el índice único `UQ_Comprobante_Ncf`, que garantiza un solo espacio de NCF en la empresa.
- No existe un parámetro de «fecha de implantación». Lo busqué en `conf.Parametros` ([G]:820-850 y sus `ADD`), en `conf.Empresa` ([G]:663-688), en el dominio y en los contratos.

**Lo que se decide en este diseño.** Se crea el rol **`H` (histórico)** en `fiscal.Comprobante`:
- sin secuencia, sin contingencia y sin documento modificado;
- solo en facturas importadas (`FAC` o `FPOS`, `Origen = 'I'`, `MotivoSinNcf = 'H'`);
- es el único comprobante de su documento;
- **no va al 607 ni al 608**;
- lo encuentra `NcfDocumento`.

El documento conserva `MotivoSinNcf = 'H'`, que significa «GPOS no emitió su NCF». Así la regla 51321 no cambia ([G]:12186-12194): solo cuenta el rol O.

---

## 2. Tablas y relaciones

| Objeto | Cambio | Aislamiento |
|---|---|---|
| `fiscal.Comprobante` | `SecuenciaId` pasa a `int NULL`. Filas nuevas con `Rol = 'H'`. Ninguna columna nueva. | Base por empresa; el NCF es único en la empresa (`UQ_Comprobante_Ncf`) |
| `conf.Parametros` (H-3) | Columna nueva `FechaImplantacion date NULL`. La tabla tiene versionado de sistema, así que el historial guarda cada cambio. | Fila única (`CK_Parametros_Unica`) |
| `rpt.NcfHistoricoIncidencia` (vista nueva) | Reporte calculado de las incidencias del NCF histórico. No es una tabla: siempre refleja el estado actual. | Base por empresa |

**Fila del rol H**

| Columna | Valor |
|---|---|
| `DocumentoId` | la factura importada |
| `Rol` | `'H'` |
| `SecuenciaId` | `NULL` |
| `Ncf` | el del archivo, en mayúsculas y sin espacios |
| `TipoComprobanteCodigo` | `SUBSTRING(Ncf, 2, 2)` |
| `FechaEmision` | `Documento.Fecha` (la usa el E34 como `FechaNCFModificado`) |
| `RncReceptor` y `NombreReceptor` | los de la venta (RNC solo si tiene 9 u 11 dígitos) |
| Montos | en la moneda base, con la misma regla E1-2 de `EmisionNcfNg.EnMonedaBase` |
| `PropinaLegal` | 0 |
| `TipoIngreso`, `NcfModificado`, `CodigoModificacion`, `ContingenciaId` y `FechaVencimientoSecuencia` | `NULL` |

**Tamaño [I]**
- Una fila de `fiscal.Comprobante` ocupa unos 120 bytes, y unos 300 bytes con sus cinco índices.
- DEMO: 9.604 filas, unos **3 MB**.
- Un cliente real con 5 años de historia y 100.000 facturas al año tendría 500.000 filas, unos **150 MB**. Sin efecto en el costo del hosting de una instalación local con SQL Server Express (límite de 10 GB por base), pero conviene importar solo la historia útil: las facturas con saldo, las del plazo de devolución y las que necesita el 607 del período abierto.

---

## 3. Restricciones e integridad

### 3.1 Restricciones `CHECK` de `fiscal.Comprobante`

| Restricción | Antes | Después |
|---|---|---|
| `CK_Comprobante_Rol` | `Rol IN ('O','R')` | `Rol IN ('O','R','H')` |
| `CK_Comprobante_Reemplazo` | `Rol = 'O' OR (LEFT(Ncf,1)='E' AND CodigoModificacion=4 AND NcfModificado IS NOT NULL)` | `Rol IN ('O','H') OR (…igual…)` |
| `CK_Comprobante_Historico` (nueva) | — | `(Rol='H' AND SecuenciaId IS NULL AND ContingenciaId IS NULL AND NcfModificado IS NULL AND CodigoModificacion IS NULL AND FechaVencimientoSecuencia IS NULL AND TipoIngreso IS NULL AND PropinaLegal = 0) OR (Rol <> 'H' AND SecuenciaId IS NOT NULL)` |
| `CK_Comprobante_Ncf`, `_CodMod`, `_TipoIngreso` y `_ContingenciaB` | — | Sin cambios. Todas valen para el rol H: el formato B+10 o E+12, el tipo igual al del NCF y la contingencia nula. |

`CK_Comprobante_Historico` se agrega **con validación** (`WITH CHECK`). Las filas O y R existentes cumplen la segunda rama porque `SecuenciaId` era `NOT NULL`.

### 3.2 Revisión completa de disparadores, vistas y consultas que suponen una secuencia o un rango

| Objeto (última definición) | ¿Supone secuencia, rango o rol O? | Efecto del rol H | Acción |
|---|---|---|---|
| `fiscal.TR_Comprobante_Inmutable` ([G]:5136-5147) | 51323 exige el documento en borrador para O, y para R un B de contingencia. 51327 une con la secuencia. | H no entra en 51323. 51327 no une con `SecuenciaId` nulo. **Hoy un H entraría sin ninguna regla.** | **Se cambia**: 51420, en 3.3 |
| `fiscal.TR_SecuenciaNcf_Bloque` ([G]:5213-5228) | 51324 compara bloques entre sí. | No ve los H: se podría registrar un bloque encima de NCF del sistema anterior. | **Se cambia**: 51421, en 3.3 |
| `doc.TR_Documento_Emision`, regla 51320 y 51321 ([G]:12186-12194) | 51320 rechaza cualquier comprobante en un tipo sin NCF; 51321 cuenta solo el rol O. | `FAC` y `FPOS` llevan NCF (`LlevaNcf = 1`), así que 51320 no salta. En 51321 se cumple `@conComprobanteO = 0` con el motivo H. | Ninguna |
| `doc.TR_Documento_Anulacion`, regla 51312 ([G]:12204-12205) | Pide el código del 608 si el documento tiene un comprobante de cualquier rol. | Anular una histórica con H exigiría el 608. | Se prohíbe anular una factura histórica con H (51422; **P-1**) |
| `doc.TR_Documento_Motivo608` ([G]:6482-6495) | 51312 y 51336, igual que la anterior. | Igual. | Cubierto por 51422 |
| `doc.TR_Documento_Ola4` y `Ola4b` (51345, 51359…) | Compras y 606 (`FCP`, `NCP`, `NDP`, `DVS`). | Ninguno: H solo existe en `FAC` y `FPOS`. | Ninguna |
| `rpt.Formato607` ([G]:10299-10346) | `WHERE c.Rol = 'O'` ([G]:10346). | **Excluido** desde ya. | Ninguna |
| `rpt.Formato608` ([G]:10240-10250) | No filtra el rol: cualquier comprobante de un documento anulado. | Una histórica anulada (si P-1 lo permite) o anulada antes de esta migración **entraría al 608**. | **Se cambia**: `AND c.Rol <> 'H'` |
| `rpt.Formato606` ([G]:8135-8146) | `LEFT JOIN … Rol = 'O'`. | Ninguno. | Ninguna |
| `rpt.NcfZonaIncierta` y `fiscal.NcfZonaIncierta` | Por secuencia. | Ninguno. | Ninguna |
| `sync.usp_ConfirmarReconciliacionLocal`, regla C5 ([G]:12549-12556) | Ningún NCF ya guardado (de cualquier rol) puede estar en la parte por emitir de un bloque vigente. | Un bloque que se solape con un H **bloquea el desbloqueo** con C5. Es correcto: se resuelve con el remedio de **P-3**. | Ninguna (comportamiento esperado, documentado) |
| `ConsultasRestauracion.SecuenciasColumnas.UltimoComprobante` (`ConsultasRestauracion.cs:34-42`) | El mayor NCF dentro del rango, de cualquier bloque. | Cuenta el H. R1 propone avanzar más allá de él, lo que es coherente con P-3. | Ninguna |
| `ConsultasFiscal.UltimoEmitido` (`:81-84`) | Busca por `SecuenciaId`. | Excluye H (`NULL`). | Ninguna |
| `ConsultasFiscal.NcfDocumento` (`:87-90`) | Solo el rol O. | No ve H. | **Se cambia** (sección 7.4) |
| `ConsultasVentas.VentaPorId` (`:13-36`) y la búsqueda (`:108-122`) | `Rol = 'O'`. | La pantalla de la factura histórica no muestra su NCF. | `Rol IN ('O','H')` (sección 7.4) |
| `ConsultaFacturasService` (`:65` y `:83`) | O, con `Referencia` como respaldo. | Funciona. | `Rol IN ('O','H')`; se conserva el respaldo para las incidencias |
| `ConsultasCxc` (`:118`, `:131`, `:144` y `:214`) | `Rol = 'O'`. | Los estados de cuenta no muestran el NCF histórico. | `Rol IN ('O','H')` |
| `ConsultasCaja` (`:169-172`) | NCF de la jornada (rol O). | Ninguno: la histórica no tiene jornada. | Ninguna |
| `ConsultasDocumentos.TieneNcf` (`:117-119`) | Cualquier rol (motivo del 608). | H cuenta. | Ninguna. El servicio rechaza antes con P-1. |
| `ConsultasImpresion.Documento.Fiscal` (`:19`) | Cualquier rol. | La reimpresión de una histórica con NCF se trata como una copia fiscal (control de VF-13). | Ninguna. Es lo prudente. |
| `ConsultasFacturasHistoricas.NcfsExistentes` (`ConsultasVentas.cs:272-277`) | `Comprobante` más `Referencia`. | Sigue sirviendo. | Ninguna |
| Esquema `rpt` y `rptc` de la ola 5 (equipo B) | Todavía **no existen** en esta rama [V]. `rpt.ConsultaFactura` está planeada con `Rol = 'O'` (`revision-vistas-ola5-2026-10-08.md:62`). | Si toma el 607 o el 608 sin filtrar el rol, se colaría H. | Entrega al equipo B (sección 11) |

### 3.3 Reglas nuevas en el motor

Los números van del **51420 al 51425** (**P-7**). El equipo B ya cita del 51400 al 51412 en sus avisos. Del 51420 en adelante no aparece en ningún lado [V, búsqueda en `GPOS-NG-Equipos`].

| Número | Dónde | Regla |
|---|---|---|
| 51420 | `fiscal.TR_Comprobante_Inmutable` | El rol H solo se registra si se cumple todo esto: el documento está en borrador, tiene `Origen = 'I'` y `MotivoSinNcf = 'H'`, es de tipo `FAC` o `FPOS`, su comprobante es de categoría `FACTURA` y de la serie de su letra, y el documento no tiene otro comprobante. Además, un documento importado no recibe un comprobante O ni R. |
| 51421 | `fiscal.TR_SecuenciaNcf_Bloque` y `fiscal.TR_Comprobante_Inmutable` | La parte por emitir (`Siguiente` a `Hasta`) de un bloque habilitado (A o R) no contiene un NCF histórico. Se revisa al crear o cambiar el bloque, y al registrar un H nuevo. |
| 51422 | `doc.TR_Documento_Historico` (nuevo) | Una factura histórica con comprobante H no se anula: se corrige con una nota de crédito (**P-1**). |
| 51423 | `conf.TR_Parametros_Implantacion` (H-3) | La fecha de implantación no se borra. Debe ser posterior a toda factura histórica y no posterior a la primera factura propia emitida. |
| 51424 | `doc.TR_Documento_SinNcf` (H-3) | Una factura importada se emite solo con una fecha anterior a la de implantación, y la fecha de implantación debe estar fijada. |
| 51425 | `doc.TR_Documento_SinNcf` (H-4) | Los motivos O y H, en 9.3. |

---

## 4. Índices y consultas que los justifican

**No se crea ningún índice.**

| Consulta | Índice que usa | Costo |
|---|---|---|
| 51421 en el bloque: ¿hay algún H entre `Prefijo+Siguiente` y `Prefijo+Hasta`? | `UQ_Comprobante_Ncf`, búsqueda por rango. Como los NCF de un mismo prefijo tienen el mismo largo, el orden del texto es el del número; es la misma técnica de C5 y de `UltimoComprobante`. | Una búsqueda por bloque cambiado. La emisión no la paga: el disparador sale temprano si solo cambia `Siguiente`. |
| 51420 y 51421 al registrar un comprobante | `PK_Documento`, `PK_TipoDocumento` y `PK_TipoComprobante`; `PK_Comprobante (DocumentoId, Rol)`; `UQ_Comprobante_Ncf` para la búsqueda del bloque | Rol O: el predicado `i.Rol = 'H'` corta. Rol H: tres búsquedas por llave. Menos de 0,1 ms [I]. |
| `NcfDocumento` nueva | `PK_Documento`, `PK_Venta`, y `PK_Comprobante` con `Rol IN ('O','H')` (dos búsquedas) | Igual que hoy |
| `rpt.NcfHistoricoIncidencia` | `IX_Documento_TipoFecha` (tipos 1 y 2) con búsqueda por llave en `doc.Documento`; para las colisiones, una búsqueda por rango en `UQ_Comprobante_Ncf` por bloque | Bajo demanda (Diagnóstico). Recorre todas las facturas históricas: con 500.000 filas, alrededor de 1 a 3 s [I]. |
| `NcfsEnBloques` de la importación (7.4) | `fiscal.SecuenciaNcf` es pequeña (decenas de filas): unión por hash con el JSON | Unos milisegundos con 10.000 NCF [I] |
| 51423 (cambio de la fecha de implantación) | `IX_Documento_TipoFecha` (tipos 1 y 2 y la fecha) | Cambio raro: irrelevante |

---

## 5. Auditoría y trazabilidad

- **Relleno.** La migración deja una línea en `audit.Bitacora`:
  - `Usuario = 'MIGRACION'`, `Accion = 'RELLENO_NCF_HISTORICO'`, `Entidad = 'fiscal.Comprobante'`;
  - `Detalle` en JSON con los registrados, las incidencias por causa y las colisiones con bloques.

  También emite `PRINT` con el mismo resumen. Que el `PRINT` llegue a `migracion.log` del DEMO depende de cómo el migrador recoja los mensajes informativos [I]; la línea de la bitácora es la que hace fe.
- **Importación (H-3).** Ya existe una línea por lote en `audit.Bitacora` y `_LOG` (`ImportacionesService.cs:159`, con `DelModeloNuevo = true` en las facturas). H-3 la vuelve estructurada; la sección 8.3 dice qué lleva.
- **Comprobante H.** Es inmutable como los demás (51322; `DENY UPDATE, DELETE` a `gpos_app`, [G]:5436).
- **Fecha de implantación.** Cada cambio queda en `conf.ParametrosHistorial`, por el versionado de sistema, con `ModificadoPor`. El servicio deja además una línea en la bitácora con el motivo.

---

## 6. Persistencia de sincronización

No aplica a la entrega 1: hoy cada empresa tiene una sola base.

Para la entrega 2 (ADR-53):
- las filas H nacen en la central, porque la importación es de la implantación;
- deben replicarse a los nodos para que una devolución en la sucursal encuentre el NCF (`NcfDocumento`);
- 51421 debe valer también en el nodo, al recibir un bloque de la central.

Va como entrega al diseño de sincronización.

---

## 7. Script de migración y reversión

### 7.1 Migraciones y orden

Todas van **después de `20261010130522_BitacoraLogSoloInsercion`**. Las marcas de tiempo las pone `dotnet ef migrations add` al crearlas.

| Migración | Contenido | PR |
|---|---|---|
| `<ts>_H2ComprobanteHistorico` | Secciones 7.2 y 7.3 | H-2 |
| `<ts>_H3FechaImplantacion` | Sección 8 | H-3 (en el mismo PR o en uno aparte) |
| `<ts>_H4MotivosSinNcf` | Sección 9 | Tanda posterior |

**Modelo de EF (lo cambia el backend)**
- `Comprobante.SecuenciaId` pasa a `int?`.
- En `ComprobanteConfiguracion`, las tres restricciones de 3.1.
- `Parametros.FechaImplantacion` (`DateTime?`, `date`).
- En `DisparadoresNg.PorTabla`:
  - `doc.Documento` suma `TR_Documento_Historico` y `TR_Documento_SinNcf`;
  - `conf.Parametros` suma `TR_Parametros_Implantacion`.
- Actualizar la instantánea.

**Guion acumulado.** Se regenera con:

```
dotnet ef migrations script --idempotent -p src/GPOS.Core -s src/GPOS.Core -c EmpresaNgDbContext -o database/empresa/gpos-empresa-<ts>_H2ComprobanteHistorico.sql
```

Después se borra el anterior. La prueba `AprovisionamientoTests.El_script_embebido_es_el_que_genera_EF` lo vigila (`AprovisionamientoTests.cs:156-168`).

**Importante para el guion idempotente.** EF envuelve cada `migrationBuilder.Sql(...)` en su propio `EXEC(N'…')`, y una tabla `#temporal` muere al terminar su `EXEC`. Por eso **el relleno (7.3) va en una sola llamada `migrationBuilder.Sql`**.

### 7.2 DDL de `H2ComprobanteHistorico` (Up)

Cada bloque es una llamada `migrationBuilder.Sql`, en este orden. Los textos completos de los disparadores se arman a partir de la clase que los creó: el de Ola3 para `TR_Comprobante_Inmutable` y `TR_SecuenciaNcf_Bloque`, y el de `Ola4SinEcf607` para `rpt.Formato608`. Se usa `Parchear`, como `SqlMigracionesOla4AjusteCerrada.cs:12-19`, y no se copia el texto. El Down repone el original desde la misma clase.

```sql
-- 1) SecuenciaId admite NULL (solo el rol H la deja vacía).
--    [V] En SQL Server 15.0.2190 (2019 Express), ALTER COLUMN de NOT NULL a NULL funciona con el índice IX_Comprobante_SecuenciaId y la FK
--    FK_Comprobante_Secuencia en su lugar (probado en una base temporal GPOS_TEST_ARQDATOS_H2, ya borrada). Si EF genera el AlterColumn con
--    DROP/CREATE del índice, también vale.
ALTER TABLE fiscal.Comprobante ALTER COLUMN SecuenciaId int NULL;

-- 2) Restricciones
ALTER TABLE fiscal.Comprobante DROP CONSTRAINT CK_Comprobante_Rol;
ALTER TABLE fiscal.Comprobante ADD CONSTRAINT CK_Comprobante_Rol CHECK (Rol IN ('O', 'R', 'H'));
ALTER TABLE fiscal.Comprobante DROP CONSTRAINT CK_Comprobante_Reemplazo;
ALTER TABLE fiscal.Comprobante ADD CONSTRAINT CK_Comprobante_Reemplazo
    CHECK (Rol IN ('O', 'H') OR (LEFT(Ncf, 1) = 'E' AND CodigoModificacion = 4 AND NcfModificado IS NOT NULL));
ALTER TABLE fiscal.Comprobante WITH CHECK ADD CONSTRAINT CK_Comprobante_Historico CHECK (
       (Rol = 'H' AND SecuenciaId IS NULL AND ContingenciaId IS NULL AND NcfModificado IS NULL AND CodigoModificacion IS NULL
                  AND FechaVencimientoSecuencia IS NULL AND TipoIngreso IS NULL AND PropinaLegal = 0)
    OR (Rol <> 'H' AND SecuenciaId IS NOT NULL));
```

```sql
-- 3) fiscal.TR_Comprobante_Inmutable: las reglas de Ola3 sin cambios, más 51420 y 51421 (H-2)
CREATE OR ALTER TRIGGER fiscal.TR_Comprobante_Inmutable ON fiscal.Comprobante AFTER INSERT, UPDATE, DELETE AS
BEGIN SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM deleted)
        THROW 51322, N'Un comprobante fiscal no se modifica ni se borra (RF-01).', 1;
    IF EXISTS (SELECT 1 FROM inserted i JOIN doc.Documento d ON d.Id = i.DocumentoId
               WHERE (i.Rol = 'O' AND d.Estado <> 0) OR (i.Rol = 'R' AND (d.Estado <> 1 OR NOT EXISTS (
                        SELECT 1 FROM fiscal.Comprobante o WHERE o.DocumentoId = i.DocumentoId AND o.Rol = 'O' AND o.ContingenciaId IS NOT NULL AND o.Ncf = i.NcfModificado))))
        THROW 51323, N'El comprobante original nace con el documento; el reemplazo solo sustituye un B de contingencia (CA-37).', 1;
    IF EXISTS (SELECT 1 FROM inserted i JOIN doc.Documento d ON d.Id = i.DocumentoId JOIN fiscal.SecuenciaNcf s ON s.Id = i.SecuenciaId
               WHERE s.Estado IN ('C', 'X') AND d.Origen <> 'R')
        THROW 51327, N'El NCF sale de un bloque cerrado (RN-11).', 1;
    -- H-2: el comprobante histórico nace con la factura importada (en borrador) y es su único comprobante; un importado no recibe O ni R
    IF EXISTS (SELECT 1 FROM inserted i
                 JOIN doc.Documento d ON d.Id = i.DocumentoId
                 JOIN doc.TipoDocumento t ON t.Id = d.TipoDocumentoId
                 JOIN fiscal.TipoComprobante tc ON tc.Codigo = i.TipoComprobanteCodigo
                WHERE (i.Rol = 'H' AND (d.Estado <> 0 OR d.Origen <> 'I' OR ISNULL(d.MotivoSinNcf, '') <> 'H' OR t.Codigo NOT IN ('FAC', 'FPOS')
                                        OR tc.Categoria <> 'FACTURA' OR tc.Serie <> LEFT(i.Ncf, 1)
                                        OR EXISTS (SELECT 1 FROM fiscal.Comprobante o WHERE o.DocumentoId = i.DocumentoId AND o.Rol <> 'H')))
                   OR (i.Rol <> 'H' AND d.Origen = 'I'))
        THROW 51420, N'El comprobante histórico solo se registra en una factura importada (origen I, motivo H), en borrador, con un NCF de factura y sin otro comprobante; un documento importado no recibe un comprobante emitido (H-2).', 1;
    IF EXISTS (SELECT 1 FROM inserted i JOIN fiscal.SecuenciaNcf s ON s.Prefijo = LEFT(i.Ncf, 3)
                WHERE i.Rol = 'H' AND s.Estado IN ('A', 'R') AND s.Siguiente <= s.Hasta
                  AND TRY_CONVERT(bigint, SUBSTRING(i.Ncf, 4, 10)) BETWEEN s.Siguiente AND s.Hasta)
        THROW 51421, N'El NCF histórico cae en la parte por emitir de un bloque NCF habilitado de GPOS (H-2).', 1;
END
```

```sql
-- 4) fiscal.TR_SecuenciaNcf_Bloque: el texto de Ola3 más, al final, la regla 51421
    -- H-2: la parte por emitir de un bloque habilitado no incluye NCF que ya usó el sistema anterior (rol H)
    IF EXISTS (SELECT 1 FROM inserted i
                WHERE i.Estado IN ('A', 'R') AND i.Siguiente <= i.Hasta
                  AND EXISTS (SELECT 1 FROM fiscal.Comprobante c
                               WHERE c.Ncf BETWEEN i.Prefijo + RIGHT(REPLICATE('0', i.Digitos) + CONVERT(varchar(20), i.Siguiente), i.Digitos)
                                               AND i.Prefijo + RIGHT(REPLICATE('0', i.Digitos) + CONVERT(varchar(20), i.Hasta), i.Digitos)
                                 AND c.Rol = 'H'))
        THROW 51421, N'El bloque de NCF incluye números que ya usó el sistema anterior: regístrelo a partir del siguiente al último NCF histórico (H-2).', 1;
```

La regla mira solo el rol H. El solapamiento con un O de otro bloque ya lo cubren 51324 y C5. Así no interfiere con los flujos de H-11.

Qué puede hacer el administrador con un bloque que ya se solapa:
- cerrarlo (`Estado` C) o bajar su `Hasta`: pasa;
- reactivarlo o ampliarlo: lo rechaza.

```sql
-- 5) rpt.Formato608: el texto de Ola4SinEcf607 con el rol H fuera (primera rama)
CREATE OR ALTER VIEW rpt.Formato608 AS
SELECT c.Ncf, c.FechaEmision, CONVERT(date, d.AnuladoEn) AS FechaAnulacion, d.CodigoAnulacion608
  FROM fiscal.Comprobante c JOIN doc.Documento d ON d.Id = c.DocumentoId
  -- Regla del propietario del 2026-10-08: ningún e-NCF (serie E) va al 608
  JOIN fiscal.TipoComprobante tc ON tc.Codigo = c.TipoComprobanteCodigo AND tc.Serie <> 'E'
 WHERE d.Estado = 2
   -- H-2: el NCF histórico lo emitió y lo informó el sistema anterior
   AND c.Rol <> 'H'
UNION ALL
SELECT s.Prefijo + RIGHT(REPLICATE('0', s.Digitos) + CONVERT(varchar(12), n.Desde), s.Digitos), NULL, CONVERT(date, n.ResueltoEn), n.Codigo608
  FROM fiscal.NcfZonaIncierta n JOIN fiscal.SecuenciaNcf s ON s.Id = n.SecuenciaId
  JOIN fiscal.TipoComprobante tz ON tz.Codigo = s.TipoComprobanteCodigo AND tz.Serie <> 'E'
 WHERE n.Estado = 'A';
```

```sql
-- 6) Una factura histórica con NCF no se anula (P-1; si el propietario elige permitirla, este disparador no se crea y queda el filtro del 608)
CREATE OR ALTER TRIGGER doc.TR_Documento_Historico ON doc.Documento AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF NOT UPDATE(Estado) RETURN;
    IF EXISTS (SELECT 1 FROM inserted i JOIN deleted d ON d.Id = i.Id
                WHERE i.Estado = 2 AND d.Estado <> 2
                  AND EXISTS (SELECT 1 FROM fiscal.Comprobante c WHERE c.DocumentoId = i.Id AND c.Rol = 'H'))
        THROW 51422, N'Una factura histórica con NCF del sistema anterior no se anula: corríjala con una nota de crédito (H-2).', 1;
END
```

```sql
-- 7) Reporte de incidencias (calculado; sin datos personales: número, fecha y NCF)
CREATE OR ALTER VIEW rpt.NcfHistoricoIncidencia AS
WITH h AS (
    SELECT d.Id AS DocumentoId, d.Numero, d.Fecha, d.Estado, UPPER(LTRIM(RTRIM(v.Referencia))) AS Ncf
      FROM doc.Documento d
      JOIN doc.TipoDocumento t ON t.Id = d.TipoDocumentoId AND t.Codigo IN ('FAC', 'FPOS')
      JOIN ventas.Venta v ON v.DocumentoId = d.Id
     WHERE d.Origen = 'I' AND d.Estado IN (1, 2) AND NULLIF(LTRIM(RTRIM(v.Referencia)), '') IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM fiscal.Comprobante c WHERE c.DocumentoId = d.Id AND c.Rol = 'H'))
-- a) Facturas históricas cuyo NCF no quedó registrado como comprobante H
SELECT h.DocumentoId, h.Numero, h.Fecha, CONVERT(varchar(50), h.Ncf) AS Ncf,
       CASE WHEN NOT (SUBSTRING(h.Ncf, 2, 12) NOT LIKE '%[^0-9]%'
                      AND ((LEFT(h.Ncf, 1) = 'B' AND LEN(h.Ncf) = 11) OR (LEFT(h.Ncf, 1) = 'E' AND LEN(h.Ncf) = 13))) THEN 'FORMATO'
            WHEN NOT EXISTS (SELECT 1 FROM fiscal.TipoComprobante tc WHERE tc.Codigo = SUBSTRING(h.Ncf, 2, 2)
                               AND tc.Categoria = 'FACTURA' AND tc.Serie = LEFT(h.Ncf, 1)) THEN 'TIPO'
            WHEN EXISTS (SELECT 1 FROM fiscal.Comprobante c WHERE c.Ncf = h.Ncf) THEN 'YA_REGISTRADO'
            WHEN EXISTS (SELECT 1 FROM h o WHERE o.Ncf = h.Ncf AND o.DocumentoId <> h.DocumentoId) THEN 'DUPLICADO'
            ELSE 'PENDIENTE' END AS Causa,
       CONVERT(int, NULL) AS SecuenciaId,
       (SELECT TOP (1) c.DocumentoId FROM fiscal.Comprobante c WHERE c.Ncf = h.Ncf) AS DocumentoConflictoId
  FROM h
UNION ALL
-- b) NCF históricos registrados dentro del rango de un bloque de GPOS
SELECT c.DocumentoId, d.Numero, d.Fecha, c.Ncf,
       CASE WHEN s.Estado IN ('A', 'R') AND TRY_CONVERT(bigint, SUBSTRING(c.Ncf, 4, 10)) >= s.Siguiente THEN 'COLISION_FUTURA'
            ELSE 'DENTRO_DE_BLOQUE' END,
       s.Id, NULL
  FROM fiscal.SecuenciaNcf s
  JOIN fiscal.Comprobante c
    ON c.Ncf BETWEEN s.Prefijo + RIGHT(REPLICATE('0', s.Digitos) + CONVERT(varchar(20), s.Desde), s.Digitos)
                 AND s.Prefijo + RIGHT(REPLICATE('0', s.Digitos) + CONVERT(varchar(20), s.Hasta), s.Digitos)
   AND c.Rol = 'H'
  JOIN doc.Documento d ON d.Id = c.DocumentoId;
GO
GRANT SELECT ON rpt.NcfHistoricoIncidencia TO gpos_app;   -- Diagnóstico; gpos_reportes ya la ve por el GRANT del esquema ([G]:446)
```

| Causa | Severidad | Qué significa |
|---|---|---|
| `YA_REGISTRADO` | **Crítica** si el conflicto es un O | GPOS emitió un NCF que el sistema anterior ya había usado: es un NCF duplicado ante la DGII |
| `COLISION_FUTURA` | **Alta** | La emisión de ese tipo se cae al llegar al número (2601 en `UQ_Comprobante_Ncf`); falla cerrada |
| `FORMATO`, `TIPO` y `DUPLICADO` | Media | La factura queda sin un NCF utilizable: sus devoluciones y notas se rechazan (7.4) |
| `DENTRO_DE_BLOQUE` | Baja | Informativa |
| `PENDIENTE` | Baja | No debería existir tras el relleno; aparece si algún camino guardó `Referencia` sin el H |

### 7.3 Relleno idempotente (una sola llamada `migrationBuilder.Sql`, después del paso 7)

```sql
SET XACT_ABORT ON;
CREATE TABLE #h (DocumentoId bigint NOT NULL PRIMARY KEY, Fecha date NOT NULL, Ncf varchar(50) NOT NULL, Tipo char(2) NULL,
                 Rnc varchar(11) NULL, Nombre varchar(150) NOT NULL, Tasa decimal(19, 6) NOT NULL,
                 Gravado decimal(19, 2) NOT NULL, Exento decimal(19, 2) NOT NULL, Itbis decimal(19, 2) NOT NULL, Total decimal(19, 2) NOT NULL,
                 Causa varchar(20) NULL);

-- 1. Candidatas: facturas importadas (emitidas o anuladas) con NCF en Referencia y sin ningún comprobante (idempotencia)
INSERT INTO #h (DocumentoId, Fecha, Ncf, Rnc, Nombre, Tasa, Gravado, Exento, Itbis, Total)
SELECT d.Id, d.Fecha, UPPER(LTRIM(RTRIM(v.Referencia))),
       CASE WHEN LEN(x.Digitos) IN (9, 11) AND x.Digitos NOT LIKE '%[^0-9]%' THEN x.Digitos END,
       v.NombreCliente, v.Tasa, ISNULL(l.Gravado, 0), ISNULL(l.Exento, 0), v.Impuesto, v.Total
  FROM doc.Documento d
  JOIN doc.TipoDocumento t ON t.Id = d.TipoDocumentoId AND t.Codigo IN ('FAC', 'FPOS')
  JOIN ventas.Venta v ON v.DocumentoId = d.Id
 CROSS APPLY (SELECT REPLACE(REPLACE(ISNULL(v.IdentificacionCliente, ''), '-', ''), ' ', '') AS Digitos) x
 OUTER APPLY (SELECT SUM(CASE WHEN vl.PorcentajeImpuesto > 0 AND i.Exento = 0 THEN vl.Importe END) AS Gravado,
                     SUM(CASE WHEN vl.PorcentajeImpuesto = 0 OR i.Exento = 1 THEN vl.Importe END) AS Exento
                FROM ventas.VentaLinea vl JOIN fiscal.Impuesto i ON i.Id = vl.ImpuestoId WHERE vl.DocumentoId = d.Id) l
 WHERE d.Origen = 'I' AND d.MotivoSinNcf = 'H' AND d.Estado IN (1, 2)
   AND NULLIF(LTRIM(RTRIM(v.Referencia)), '') IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM fiscal.Comprobante c WHERE c.DocumentoId = d.Id);

-- 2. Moneda base (E1-2): a la tasa de la venta; los centavos de la conversión, al componente mayor si cuadraba en su moneda
UPDATE h SET Gravado = b.G + CASE WHEN a.Ajusta = 1 AND a.Mayor = 1 THEN a.Dif ELSE 0 END,
             Exento  = b.E + CASE WHEN a.Ajusta = 1 AND a.Mayor = 2 THEN a.Dif ELSE 0 END,
             Itbis   = b.I + CASE WHEN a.Ajusta = 1 AND a.Mayor = 3 THEN a.Dif ELSE 0 END,
             Total   = b.T
  FROM #h h
 CROSS APPLY (SELECT ROUND(h.Gravado * h.Tasa, 2) AS G, ROUND(h.Exento * h.Tasa, 2) AS E, ROUND(h.Itbis * h.Tasa, 2) AS I, ROUND(h.Total * h.Tasa, 2) AS T) b
 CROSS APPLY (SELECT CASE WHEN h.Gravado + h.Exento + h.Itbis = h.Total THEN 1 ELSE 0 END AS Ajusta, b.T - (b.G + b.E + b.I) AS Dif,
                     CASE WHEN ABS(b.G) >= ABS(b.E) AND ABS(b.G) >= ABS(b.I) THEN 1 WHEN ABS(b.E) >= ABS(b.I) THEN 2 ELSE 3 END AS Mayor) a
 WHERE h.Tasa <> 1;

-- 3. Clasificación (mismo orden que la vista)
UPDATE #h SET Causa = 'FORMATO'
 WHERE NOT (SUBSTRING(Ncf, 2, 12) NOT LIKE '%[^0-9]%' AND ((LEFT(Ncf, 1) = 'B' AND LEN(Ncf) = 11) OR (LEFT(Ncf, 1) = 'E' AND LEN(Ncf) = 13)));
UPDATE #h SET Tipo = SUBSTRING(Ncf, 2, 2) WHERE Causa IS NULL;
UPDATE h SET Causa = 'TIPO' FROM #h h
 WHERE h.Causa IS NULL AND NOT EXISTS (SELECT 1 FROM fiscal.TipoComprobante tc
                                        WHERE tc.Codigo = h.Tipo AND tc.Categoria = 'FACTURA' AND tc.Serie = LEFT(h.Ncf, 1));
UPDATE h SET Causa = 'YA_REGISTRADO' FROM #h h
 WHERE h.Causa IS NULL AND EXISTS (SELECT 1 FROM fiscal.Comprobante c WHERE c.Ncf = h.Ncf);
WITH d AS (SELECT Causa, COUNT(*) OVER (PARTITION BY Ncf) AS Veces FROM #h WHERE Causa IS NULL)
UPDATE d SET Causa = 'DUPLICADO' WHERE Veces > 1;          -- ninguna de las repetidas se registra: no hay criterio para elegir

-- 4. Registro (51420 exige el borrador: el disparador se apaga solo dentro de esta transacción, como en Ola4MonedaBase607, [G]:10276-10297;
--    las condiciones de 51420 ya están en el filtro del paso 1 y en la clasificación)
DISABLE TRIGGER fiscal.TR_Comprobante_Inmutable ON fiscal.Comprobante;
BEGIN TRY
    INSERT INTO fiscal.Comprobante (DocumentoId, Rol, SecuenciaId, Ncf, TipoComprobanteCodigo, FechaEmision, FechaVencimientoSecuencia, TipoIngreso,
                                    RncReceptor, NombreReceptor, NcfModificado, CodigoModificacion, ContingenciaId,
                                    MontoGravado, MontoExento, Itbis, PropinaLegal, MontoTotal)
    SELECT DocumentoId, 'H', NULL, CONVERT(varchar(13), Ncf), Tipo, Fecha, NULL, NULL, Rnc, Nombre, NULL, NULL, NULL, Gravado, Exento, Itbis, 0, Total
      FROM #h WHERE Causa IS NULL;
END TRY
BEGIN CATCH
    ENABLE TRIGGER fiscal.TR_Comprobante_Inmutable ON fiscal.Comprobante;
    THROW;
END CATCH;
ENABLE TRIGGER fiscal.TR_Comprobante_Inmutable ON fiscal.Comprobante;

-- 5. Reporte: nunca detiene la migración
DECLARE @detalle varchar(4000) = (
    SELECT (SELECT COUNT(*) FROM #h WHERE Causa IS NULL) AS registrados,
           (SELECT Causa AS causa, COUNT(*) AS cantidad FROM #h WHERE Causa IS NOT NULL GROUP BY Causa FOR JSON PATH) AS incidencias,
           (SELECT COUNT(*) FROM rpt.NcfHistoricoIncidencia WHERE Causa = 'COLISION_FUTURA') AS colisionesFuturas,
           (SELECT COUNT(DISTINCT SecuenciaId) FROM rpt.NcfHistoricoIncidencia WHERE Causa = 'COLISION_FUTURA') AS bloquesConColision
       FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);
IF EXISTS (SELECT 1 FROM #h) OR EXISTS (SELECT 1 FROM rpt.NcfHistoricoIncidencia)
    INSERT INTO audit.Bitacora (Usuario, Accion, Pantalla, Entidad, Detalle)
    VALUES ('MIGRACION', 'RELLENO_NCF_HISTORICO', 'Migración H2ComprobanteHistorico', 'fiscal.Comprobante', @detalle);
PRINT CONCAT(N'H-2: relleno de NCF históricos: ', @detalle);
DROP TABLE #h;
```

Notas del relleno:
- **Idempotencia.** El paso 1 excluye los documentos que ya tienen un comprobante. Volver a ejecutar el relleno no inserta nada nuevo.
- **NCF mal formados o de un tipo que no es de factura.** No se registran y aparecen en la vista. La factura conserva `Referencia`, y su devolución o nota se **rechaza** con 422 (7.4) hasta que se resuelva (**P-4**).
- **Duplicados entre históricas, o con un NCF ya registrado en GPOS.** No se registra ninguno de los dos y se informan. Si el conflicto es con un O, es un NCF duplicado de verdad (Crítica en una empresa real).
- **Solapes con bloques.** El H se registra igual, porque el hecho es cierto: el sistema anterior usó ese número. La colisión se informa. La migración no toca `Siguiente`; el remedio es **P-3**.
- **Descuento global.** La importación pasa `PorcDescuento = 0` (`ImportacionesService.cs:453`), así que gravado + exento = `SubTotal`.

  [I] Si algún día se importara con descuento global, el reparto debería seguir a `BaseImponible`.
- **Bloqueos.** `DISABLE TRIGGER` toma un bloqueo Sch-M sobre `fiscal.Comprobante` mientras dura la transacción. La migración corre con la aplicación detenida (`Actualizar-Demo.ps1` la detiene). Con 9.604 filas, unos pocos segundos [I].

### 7.4 Cambios de consultas (los escribe el backend; texto propuesto)

**`ConsultasFiscal.NcfDocumento`.** Reemplaza el actual (`:87-90`) y suma `HistoricoPendiente` a `NcfFila`:

```sql
SELECT MAX(c.Ncf) AS Ncf,
       CONVERT(bit, CASE WHEN MAX(c.Ncf) IS NULL
                          AND MAX(CASE WHEN d.Origen = 'I' AND d.MotivoSinNcf = 'H' AND NULLIF(LTRIM(RTRIM(v.Referencia)), '') IS NOT NULL
                                       THEN 1 ELSE 0 END) = 1 THEN 1 ELSE 0 END) AS HistoricoPendiente
  FROM doc.Documento d
  LEFT JOIN ventas.Venta v ON v.DocumentoId = d.Id
  LEFT JOIN fiscal.Comprobante c ON c.DocumentoId = d.Id AND c.Rol IN ('O', 'H')
 WHERE d.Id = @documento
```

**Regla «origen sin NCF» (`Ncf.SinNcfPorOrigen` y sus llamadores)**
- Con `Ncf` no nulo, la histórica «tiene NCF». La devolución y la nota de crédito llevan B04 (o E34 si el NCF es E) con `NcfModificado` igual al NCF histórico, y no admiten «No generar comprobante». La nota de débito lleva B03 o E33. Todo esto ya lo hace `ComprobanteOrigen.Tipo` a partir del prefijo.
- Con `HistoricoPendiente = 1`, los cuatro llamadores rechazan con **422 `NCF_HISTORICO_PENDIENTE`**:
  - «La factura {n} trae del sistema anterior el NCF {Referencia}, que no está registrado como comprobante. Avise al administrador.»;
  - el texto no sugiere guardar sin comprobante (regla del 2026-10-02).

  Los llamadores son:
  - `DocumentosComercialesService.Ventas.cs:223`;
  - `PosService.cs:678`, que deja el respaldo `?? original.Ncf` sin efecto para estos casos;
  - `CobrosService.cs:360` y `:378`.
- La excepción «origen sin NCF» solo se aplica a una histórica **sin** NCF en el archivo (`Referencia` vacía). Esto sustituye la regla provisional «no se aplica a las históricas» mientras H-2 no estaba hecho.

**Lecturas de pantalla.** `Rol = 'O'` pasa a `Rol IN ('O','H')` en:
- `ConsultasVentas.VentaPorId` y la búsqueda (`:35` y `:117`);
- `ConsultasCxc` (`:118`, `:131`, `:144` y `:214`);
- `ConsultaFacturasService` (`:65`).

Devuelven como máximo una fila, porque 51420 impide que un documento tenga O y H a la vez.

**Importación (`ImportacionesService.FacturasAsync`)**
- Después de `VentasNg.Agregar` y su `SaveChanges`, y antes de `EmitirAsync` (`:451-460`), se inserta el H con el comando nuevo `ConsultasFiscal.InsertarComprobanteHistorico`. Conviene ir en el mismo lote del siguiente comando para no sumar un viaje por factura: 9.604 viajes de 1 a 3 ms serían de 10 a 30 s [I].

  ```sql
  INSERT INTO fiscal.Comprobante (DocumentoId, Rol, SecuenciaId, Ncf, TipoComprobanteCodigo, FechaEmision, RncReceptor, NombreReceptor,
                                  MontoGravado, MontoExento, Itbis, PropinaLegal, MontoTotal)
  VALUES (@documento, 'H', NULL, @ncf, SUBSTRING(@ncf, 2, 2), @fecha, @rnc, @nombre, @gravado, @exento, @itbis, 0, @total)
  -- @ncf varchar(13), @rnc varchar(11), @nombre varchar(150) (ADR-50); montos con EmisionNcfNg.EnMonedaBase
  ```

- Validaciones de fila nuevas:
  - el tipo del NCF es de categoría `FACTURA` y de la serie de su letra (catálogo `fiscal.TipoComprobante`), lo que rechaza B04, B11 o «B31»;
  - el NCF no cae en el rango de ningún bloque registrado, con la consulta nueva `NcfsEnBloques`:

    ```sql
    SELECT j.[value] AS Ncf, s.Id AS SecuenciaId, s.Prefijo, s.Desde, s.Hasta, s.Estado
      FROM OPENJSON(@ncfs) WITH ([value] varchar(13) '$') j
      JOIN fiscal.SecuenciaNcf s ON s.Prefijo = LEFT(j.[value], 3)
                                AND TRY_CONVERT(bigint, SUBSTRING(j.[value], 4, 10)) BETWEEN s.Desde AND s.Hasta
    ```

  - la fecha es anterior a la de implantación (H-3).
- Una factura B01 o E31 cuyo cliente no tiene RNC da **advertencia** (**P-6**).

**Mensajes de la gestión de secuencias.** Al registrar un bloque, el servicio calcula antes el mayor H del rango y, si lo hay, rechaza con 422 `SECUENCIA_SOLAPA_HISTORICO`: «El bloque {prefijo} del {desde} al {hasta} incluye NCF del sistema anterior hasta el {mayor}; regístrelo a partir del {mayor+1}.» El 51421 del motor queda como última defensa y se traduce en `ErroresNumeracion` con el mismo código. También se traduce el 2601 de `UQ_Comprobante_Ncf` en la emisión, que hoy es un 500: el código propuesto es `NCF_YA_USADO`.

**Anulación (P-1).** `DocumentosNg.AnularAsync` (`:296-322`) rechaza antes con 422 `HISTORICA_NO_SE_ANULA` si el documento tiene un H.

### 7.5 Reversión (`Down` de `H2ComprobanteHistorico`)

Solo vale en desarrollo (hoy todo es desarrollo). Es el mismo criterio de los Down de Ola4.

```sql
IF EXISTS (SELECT 1 FROM fiscal.Comprobante c JOIN fiscal.Comprobante h ON h.Ncf = c.NcfModificado AND h.Rol = 'H')
    THROW 51399, N'Hay notas o devoluciones que modifican un NCF histórico: la reversión de H2ComprobanteHistorico solo vale antes de emitirlas.', 1;
DROP VIEW IF EXISTS rpt.NcfHistoricoIncidencia;
DROP TRIGGER IF EXISTS doc.TR_Documento_Historico;
DISABLE TRIGGER fiscal.TR_Comprobante_Inmutable ON fiscal.Comprobante;
DELETE FROM fiscal.Comprobante WHERE Rol = 'H';
ENABLE TRIGGER fiscal.TR_Comprobante_Inmutable ON fiscal.Comprobante;
-- rpt.Formato608 con el texto de Ola4SinEcf607; TR_SecuenciaNcf_Bloque y TR_Comprobante_Inmutable con el texto de Ola3 (desde sus clases)
ALTER TABLE fiscal.Comprobante DROP CONSTRAINT CK_Comprobante_Historico;
ALTER TABLE fiscal.Comprobante DROP CONSTRAINT CK_Comprobante_Reemplazo;
ALTER TABLE fiscal.Comprobante ADD CONSTRAINT CK_Comprobante_Reemplazo
    CHECK (Rol = 'O' OR (LEFT(Ncf, 1) = 'E' AND CodigoModificacion = 4 AND NcfModificado IS NOT NULL));
ALTER TABLE fiscal.Comprobante DROP CONSTRAINT CK_Comprobante_Rol;
ALTER TABLE fiscal.Comprobante ADD CONSTRAINT CK_Comprobante_Rol CHECK (Rol IN ('O', 'R'));
ALTER TABLE fiscal.Comprobante ALTER COLUMN SecuenciaId int NOT NULL;
```

El NCF sigue en `ventas.Venta.Referencia`: el Down no pierde ningún dato que exista antes de la migración. Pierde la línea de bitácora del relleno, que **no** se borra (`audit.Bitacora` es solo de inserción).

---

## 8. H-3: fecha de implantación

### 8.1 De dónde sale

**No existe** un parámetro [V]. Propongo crear `conf.Parametros.FechaImplantacion date NULL` (**P-2**).

Fuentes que descarté:

| Fuente | Por qué no |
|---|---|
| La fecha de la primera factura propia | Cambia con cualquier documento retrofechado y no existe antes de vender |
| El corte de las existencias iniciales | Es de otra importación y opcional; en el DEMO coincide, en general no |
| `conf.Empresa.ValidoDesde` | Es la fecha técnica de creación de la fila, no la fecha de negocio |

### 8.2 DDL (`H3FechaImplantacion`)

```sql
ALTER TABLE conf.Parametros ADD FechaImplantacion date NULL;   -- tabla con versionado de sistema: el ADD se propaga al historial
```

```sql
-- Bases existentes (desarrollo y DEMO), P-2: el día siguiente a la última factura histórica, si no queda después de la primera factura propia
DECLARE @ultimaH date = (SELECT MAX(d.Fecha) FROM doc.Documento d JOIN doc.TipoDocumento t ON t.Id = d.TipoDocumentoId
                          WHERE d.Origen = 'I' AND t.Codigo IN ('FAC', 'FPOS') AND d.Estado IN (1, 2));
DECLARE @primeraN date = (SELECT MIN(d.Fecha) FROM doc.Documento d JOIN doc.TipoDocumento t ON t.Id = d.TipoDocumentoId
                           WHERE d.Origen IN ('N', 'R') AND t.Codigo IN ('FAC', 'FPOS') AND d.Estado IN (1, 2));
IF @ultimaH IS NOT NULL AND (@primeraN IS NULL OR DATEADD(DAY, 1, @ultimaH) <= @primeraN)
    UPDATE conf.Parametros SET FechaImplantacion = DATEADD(DAY, 1, @ultimaH), ModificadoPor = 'MIGRACION' WHERE Id = 1 AND FechaImplantacion IS NULL;
ELSE IF @ultimaH IS NOT NULL
    PRINT N'H-3: hay facturas históricas posteriores a la primera factura propia; la fecha de implantación queda sin fijar (importación histórica bloqueada).';
```

```sql
CREATE OR ALTER TRIGGER conf.TR_Parametros_Implantacion ON conf.Parametros AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF NOT UPDATE(FechaImplantacion) RETURN;
    DECLARE @f date, @antes date;
    SELECT @f = i.FechaImplantacion, @antes = d.FechaImplantacion FROM inserted i JOIN deleted d ON d.Id = i.Id;
    IF @antes IS NOT NULL AND @f IS NULL
        THROW 51423, N'La fecha de implantación no se borra (H-3).', 1;
    IF @f IS NULL OR @f = @antes RETURN;
    IF EXISTS (SELECT 1 FROM doc.Documento d JOIN doc.TipoDocumento t ON t.Id = d.TipoDocumentoId
                WHERE t.Codigo IN ('FAC', 'FPOS') AND d.Origen = 'I' AND d.Estado IN (1, 2) AND d.Fecha >= @f)
        THROW 51423, N'Hay facturas históricas en la fecha de implantación o después: la fecha debe ser posterior a todas ellas (H-3).', 1;
    IF EXISTS (SELECT 1 FROM doc.Documento d JOIN doc.TipoDocumento t ON t.Id = d.TipoDocumentoId
                WHERE t.Codigo IN ('FAC', 'FPOS') AND d.Origen IN ('N', 'R') AND d.Estado IN (1, 2) AND d.Fecha < @f)
        THROW 51423, N'La fecha de implantación no puede ser posterior a la primera factura emitida en GPOS (H-3).', 1;
END
```

```sql
-- La factura importada se emite solo antes de la fecha de implantación (y con la fecha fijada). Disparador propio, como Motivo608 y Credito:
-- no se parchea TR_Documento_Emision. H-4 lo amplía con CREATE OR ALTER (sección 9).
CREATE OR ALTER TRIGGER doc.TR_Documento_SinNcf ON doc.Documento AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF NOT UPDATE(Estado) RETURN;
    IF NOT EXISTS (SELECT 1 FROM inserted i JOIN deleted d ON d.Id = i.Id
                    WHERE d.Estado = 0 AND i.Estado = 1 AND (i.MotivoSinNcf IS NOT NULL OR i.Origen = 'I')) RETURN;
    IF EXISTS (SELECT 1 FROM inserted i JOIN deleted d ON d.Id = i.Id JOIN doc.TipoDocumento t ON t.Id = i.TipoDocumentoId
                WHERE d.Estado = 0 AND i.Estado = 1 AND i.Origen = 'I' AND t.Codigo IN ('FAC', 'FPOS')
                  AND NOT EXISTS (SELECT 1 FROM conf.Parametros p WHERE p.Id = 1 AND p.FechaImplantacion IS NOT NULL AND i.Fecha < p.FechaImplantacion))
        THROW 51424, N'La factura histórica debe tener una fecha anterior a la fecha de implantación, y la fecha de implantación debe estar fijada (H-3).', 1;
END
```

**Cómo se explica la regla.** La fecha histórica queda por debajo de la fecha de implantación, y esta no puede moverse más allá de la primera factura propia. Así un ADMIN no puede cargar como «históricas» ventas del período en que ya opera, que es justamente el hallazgo H-3. Las ventas normales retrofechadas siguen con sus reglas (F-1, F-2 y `TopeDiasAnteriores`).

**Costo.** La venta normal con NCF sale en la segunda instrucción: hay una lectura de `inserted` y `deleted` de una fila. La importación de 9.604 facturas suma una búsqueda de `conf.Parametros` por factura, menos de 0,1 ms cada una [I].

**Down.** `DROP TRIGGER doc.TR_Documento_SinNcf` y `conf.TR_Parametros_Implantacion`; `ALTER TABLE conf.Parametros DROP COLUMN FechaImplantacion`. En una tabla temporal se puede quitar una columna directamente desde SQL Server 2016.

### 8.3 Aplicación (lo construye el backend)

**Parámetro**
- Se ve en Parámetros generales.
- **La primera vez** lo fija el ADMIN o el SUPER.
- Después, cambiarlo es solo del SUPER, con motivo y línea en la bitácora (**P-2**).

**Importación**
- Sin la fecha fijada, se rechaza el archivo entero con 422 `FECHA_IMPLANTACION_REQUERIDA`.
- Una fila con una fecha igual o posterior a la de implantación es un error de fila.

**Línea de bitácora por lote.** La que ya se escribe (`:159`), con:
- `Accion = 'IMPORTACION_HISTORICA'`;
- `despues` = cantidad de facturas, la fecha menor y la mayor, la fecha de implantación vigente, cuántas traen NCF y cuántas no, los NCF menor y mayor por prefijo, cuántas son B01 o E31 sin RNC, y la huella SHA-256 del archivo.

La validación no persiste nada porque se revierte.

---

## 9. Tanda posterior (H-4, H-6 y H-7): qué cambia y qué deja preparado H-2

### 9.1 H-4: la base valida los motivos O y H (`H4MotivosSinNcf`)

```sql
-- Precomprobación: si hay datos que violan la regla, la migración se detiene con 51399 y la lista (solo en desarrollo; el único camino que pone H
-- es DocumentosNg.ImportarAsync, con origen I [V])
ALTER TABLE doc.Documento WITH CHECK ADD CONSTRAINT CK_Documento_MotivoHistorico
    CHECK (MotivoSinNcf IS NULL OR MotivoSinNcf <> 'H' OR Origen = 'I');
```

`doc.TR_Documento_SinNcf` (`CREATE OR ALTER`) suma dos reglas a la 51424 de H-3:

```sql
    -- H-4: una factura importada lleva el motivo H y, si trae NCF, su comprobante H (H-2)
    IF EXISTS (SELECT 1 FROM inserted i JOIN deleted d ON d.Id = i.Id JOIN doc.TipoDocumento t ON t.Id = i.TipoDocumentoId
                 LEFT JOIN ventas.Venta v ON v.DocumentoId = i.Id
                WHERE d.Estado = 0 AND i.Estado = 1 AND i.Origen = 'I' AND t.Codigo IN ('FAC', 'FPOS')
                  AND (ISNULL(i.MotivoSinNcf, '') <> 'H'
                       OR (NULLIF(LTRIM(RTRIM(v.Referencia)), '') IS NOT NULL
                           AND NOT EXISTS (SELECT 1 FROM fiscal.Comprobante c WHERE c.DocumentoId = i.Id AND c.Rol = 'H'))))
        THROW 51425, N'La factura importada lleva el motivo H y, si trae NCF, su comprobante histórico (H-4).', 1;
    -- H-4: el motivo O (origen sin NCF) solo vale en la devolución o la nota de crédito de una factura sin comprobante fiscal
    IF EXISTS (SELECT 1 FROM inserted i JOIN deleted d ON d.Id = i.Id JOIN doc.TipoDocumento t ON t.Id = i.TipoDocumentoId
                 LEFT JOIN ventas.Venta v ON v.DocumentoId = i.Id
                 LEFT JOIN doc.Documento o ON o.Id = v.DocumentoOrigenId
                 LEFT JOIN ventas.Venta vo ON vo.DocumentoId = o.Id
                WHERE d.Estado = 0 AND i.Estado = 1 AND i.MotivoSinNcf = 'O'
                  AND (t.Codigo NOT IN ('DEV', 'NC') OR o.Id IS NULL
                       OR EXISTS (SELECT 1 FROM fiscal.Comprobante c WHERE c.DocumentoId = o.Id)
                       OR (o.Origen = 'I' AND NULLIF(LTRIM(RTRIM(vo.Referencia)), '') IS NOT NULL)))
        THROW 51425, N'El motivo «origen sin NCF» solo vale en la devolución o la nota de crédito de una factura sin comprobante fiscal (H-4).', 1;
```

- El vínculo con el origen es `ventas.Venta.DocumentoOrigenId`. La nota lo llena (`CobrosService.cs:410`) y la devolución del POS también (`PosService.cs:684-688`) [V].

  **[I] El backend debe confirmar que la devolución de `DocumentosComercialesService` también lo llena.**
- La nota de débito queda fuera de O, como en N-1, porque usa N con la autorización.
- **H-2 no se rehace.** H-4 se apoya en el rol H, en `Referencia` y en el disparador nuevo que crea H-3, y reutiliza el 51425 reservado aquí.
- Down: el `CREATE OR ALTER` con el texto de H-3 y el `DROP CONSTRAINT`.

### 9.2 H-6: motivo obligatorio del usuario en «No generar comprobante»

- Datos: `SIN_NCF` se agrega a la lista de `CK_Autorizacion_Motivo` (precedente: [G]:11409). Así: `Tipo NOT IN ('FECHA_ANTERIOR','BAJA_DEVOLUCION','REIMPRESION','SIN_NCF') OR LEN(LTRIM(RTRIM(ISNULL(Motivo,'')))) > 0`.
- Las filas existentes llevan el texto fijo «No generar comprobante» (`EmisionNcfNg.cs:106`), así que la restricción se valida sin errores.
- `ConsultasDocumentos.MotivoSinNcfAutorizado` recibe `@motivo varchar(200)` del usuario.
- El largo mínimo (por ejemplo, 10 caracteres) es regla de la aplicación (**P-9**).
- Va en la misma migración que H-4.

### 9.3 H-7: un evento de seguridad por cada 422 `NO_GENERAR_SIN_PRIVILEGIO`

- **Sin cambio de esquema.**
- El rechazo deshace la transacción del documento. Por eso el evento va **fuera** de ella:
  - `EventId` 4902 `NoGenerarSinPrivilegio`, en la categoría `GPOS.Ncf.Rastro` (`Ncf.cs:88-90`), que producción conserva en el Visor de eventos;
  - lleva la empresa, el usuario, el tipo de documento, el tipo de comprobante y el punto de entrada;
  - no lleva datos del cliente (Ley 172-13).
- La alternativa de escribirlo también en `audit.Bitacora` necesita una conexión y una transacción aparte (**P-8**).

---

## 10. Respaldo, restauración y retención

- **Antes de la migración.**
  - El DEMO: `Actualizar-Demo.ps1` ya respalda las dos bases (COPY_ONLY, CHECKSUM, VERIFYONLY).
  - Las bases de desarrollo: respaldo `COPY_ONLY` manual antes de aplicar la migración por primera vez.
- **Restauración de un respaldo anterior a H-2.** El guion vuelve a aplicar el relleno, que es idempotente. Si el respaldo es posterior, las filas H ya vienen en él.
- **C5 y R1 (H-11).** Un bloque que se solapa con un H bloquea el desbloqueo (C5), y R1 ve el H como el último emitido. Es coherente con el remedio de P-3.
- **Retención.** Las filas H se conservan igual que los demás comprobantes. Solo se insertan, no tienen papelera ni se borran.

---

## 11. Privilegios de base de datos

- `gpos_app` **no recibe nada nuevo** sobre tablas. Ya tiene `INSERT` en el esquema `fiscal` ([G]:441) y conserva el `DENY UPDATE, DELETE` sobre `fiscal.Comprobante` ([G]:5436).
- Lo único nuevo es `GRANT SELECT ON rpt.NcfHistoricoIncidencia TO gpos_app`, para Diagnóstico.
- `gpos_reportes` la ve por el permiso del esquema `rpt`. La vista no tiene datos personales: número, fecha y NCF.
- `gpos_app` no puede deshabilitar disparadores, porque no tiene `ALTER` sobre `fiscal`. El `DISABLE TRIGGER` del relleno solo lo puede hacer el login de la migración.

  Queda abierto RG-14 (privilegio mínimo del login de la API): conviene que la migración corra con un login distinto del de la API, como dice ADR-44.
- `conf.Parametros.FechaImplantacion`: en la base, el `GRANT UPDATE` del esquema `conf` ya existe. Quién puede cambiarla lo controla el servicio con el privilegio (8.3). La regla de fondo (51423) está en el motor.

---

## 12. Riesgos

| # | Riesgo | Severidad | Mitigación |
|---|---|---|---|
| RF-1 | **NCF duplicado** (`YA_REGISTRADO` contra un O): GPOS ya emitió un número que el sistema anterior usó. Es posible en un DEMO de un socio que registró B02 desde 1 y vendió. | Crítica en una empresa real; hoy solo en desarrollo y DEMO | Se informa (vista y bitácora). La importación nueva y el 51421 lo impiden en adelante. En los DEMO: reinstalar o aceptarlo. |
| RF-2 | **Colisión futura**: un bloque vigente llega a un número histórico y la venta de ese tipo se rechaza (2601) hasta resolverlo | Alta (operativa; falla cerrada) | Reporte, traducción del 2601, aviso en la banda NCF del POS (entrega a UX y backend) y el remedio de **P-3** |
| RF-3 | Una vista futura (`rpt`/`rptc` de la ola 5, o el 607 o el 608 rehechos) lee `fiscal.Comprobante` sin filtrar el rol y **declara un NCF histórico** | Alta | Prueba de guarda: toda vista de `sys.sql_modules` que lee `fiscal.Comprobante` filtra el rol. Entrega al equipo B. |
| RF-4 | Si P-1 permite anular, el 608 lo excluye; pero anular el NCF de otro período sin una nota es incorrecto ante la DGII [I] | Media | Recomendado: prohibirlo (51422) |
| RF-5 | Empresa ya con e-CF y devolución de una histórica B: hoy sale B04 (por el prefijo del origen). La DGII podría exigir E34 que modifique un B [I] | Media | Al especialista POS y fiscal (no lo introduce H-2, pero H-2 lo hace alcanzable) |
| RF-6 | Las incidencias dejan facturas históricas sin devolución ni nota posible (422) | Media | P-4. En una implantación desde cero, la importación nueva no las produce. |
| RF-7 | El ADMIN fija una fecha de implantación tardía antes de vender e importa ventas recientes como históricas | Baja | 51423 la ata a la primera factura propia. P-2: el SUPER controla los cambios. |
| RO-1 | Bloqueo Sch-M y duración de la migración | Baja | Con la aplicación detenida; segundos para miles de filas [I] |
| RO-2 | Las pruebas que importan históricas o insertan `FAC` importadas (`ImportacionesTests`, `NumeracionImportacionFacturasTests`, `ImplantacionDemoTests`, `ExtraccionBp2Tests` y `GPOS.EnsayoImplantacion`) fallarán con 51424 si no fijan antes la fecha de implantación | Media (esfuerzo de QA) | Un ayudante de prueba que la fija |
| RO-3 | Rendimiento de la importación del DEMO | Baja | El H va en lote. QA mide antes y después (meta: menos del 10 % más). |

---

## 13. DEMO

**Plantilla `datos-demo/08-facturas-historicas.xlsx`** [V, leída con un script sobre el XML del archivo]:

| Dato | Valor |
|---|---|
| Facturas | 9.604 (839 «Factura» y 8.765 «Punto de venta») |
| NCF | Todas traen uno; los 9.604 tienen formato válido |
| Duplicados | 0 |
| B01 | 1 al 1.914 |
| B02 | 1 al 7.690 |
| Fechas | Del 2025-10-01 al 2026-09-30 |

En una base nueva, la importación deja **9.604 comprobantes H y 0 incidencias**.

Cambios:
- `instalador/Demo/LEEME.md` y `datos-demo/LEEME.md`, antes de importar 08:
  - fijar la fecha de implantación en **01/10/2026**, que coincide con el corte de 07;
  - registrar los bloques **B01 desde el 1.915** y **B02 desde el 7.691**. Si no, 51421 los rechaza (es lo que se busca).
- `Instalar-Demo.ps1` puede fijar la fecha por sí mismo (entrega a DevOps).
- `ImplantacionDemoTests`: sumar las aserciones 9.604 H, 0 filas en `rpt.NcfHistoricoIncidencia`, y el rechazo de un bloque B02 desde 1.
- DEMO ya instalados: `Actualizar-Demo.ps1` aplica la migración.
  - Si el socio registró B02 desde 1 y ya vendió, aparecerán `YA_REGISTRADO` y `COLISION_FUTURA`.
  - La recomendación es reinstalar el DEMO o resolverlo con P-3.
  - La fecha se infiere como 2026-10-01 si no hay ventas propias anteriores.

---

## 14. Pruebas de datos (para QA)

| # | Prueba |
|---|---|
| D-01 | **Relleno.** Facturas `FAC` y `FPOS` importadas, emitidas y anuladas, con NCF válido: queda el H con el tipo, la fecha, el RNC y los montos en la moneda base (incluida una venta en USD con tasa, cuadrada al centavo). `MotivoSinNcf` sigue en H. Volver a aplicar el guion acumulado no cambia nada (patrón de `OrdenRecibidaMigracionTests`). |
| D-02 | **Incidencias.** Formato (`B0212`, `X02…` y 14 caracteres), tipo (B04, B11 y «B31»), duplicado entre dos históricas, y ya registrado contra un O. `Referencia` vacía no es incidencia. La vista coincide con el relleno, causa por causa. |
| D-03 | **Colisión.** Un bloque A con `Siguiente` por debajo de un H: la vista da `COLISION_FUTURA`, la migración termina y la bitácora lo cuenta. Emitir hasta ese número da el código traducido, no un 500. |
| D-04 | **51421 en el bloque.** Un bloque nuevo encima de un H se rechaza. Desde el siguiente al mayor H, pasa. Cerrar un bloque que se solapa, pasa. Un H por debajo de `Siguiente` no bloquea. |
| D-05 | **51420 y 51421 en el comprobante.** Se rechaza un H en: un documento N; un emitido; un `REC` importado; un tipo `NCR` o `COMPRA`; un E con letra B; un documento que ya tiene O; un NCF en la parte por emitir de un bloque. Se rechaza un O en un documento importado. 51322 al hacer `UPDATE` o `DELETE` de un H. |
| D-06 | **Origen.** La devolución (Web y POS) y la nota de crédito de una histórica con NCF llevan B04 (o E34 si es E) con `NcfModificado` igual al H, y «No generar comprobante» se rechaza. La nota de débito lleva B03. Una histórica sin NCF admite el motivo O. Una histórica con incidencia da 422 `NCF_HISTORICO_PENDIENTE`. |
| D-07 | **607 y 608.** El H no aparece en el 607. El B04 sí, con su `NcfModificado`. Una histórica anulada antes de la migración no aparece en el 608. |
| D-08 | **51422.** No se anula una histórica con H. Una histórica sin NCF se anula como hoy. |
| D-09 | **Importación.** Inserta el H por factura. Rechaza el NCF dentro de un bloque, el tipo que no es de factura, una fecha igual o posterior a la de implantación, y la importación sin la fecha fijada. La línea de bitácora tiene el JSON de 8.3. Al validar no se persiste nada. |
| D-10 | **51423 y 51424.** Borrar la fecha, ponerla en o antes de la última histórica, o después de la primera factura propia: rechazado. Emitir una histórica con fecha igual a la de implantación: 51424. Una venta normal no se ve afectada. |
| D-11 | **Down.** Con un B04 que modifica un H: 51399. Sin él: revierte limpio y el Up vuelve a dar el mismo resultado. |
| D-12 | **Guion.** `El_script_embebido_es_el_que_genera_EF`, y un único recurso embebido. |
| D-13 | **H-4.** Matriz al estilo de `DisparadoresEmisionTests`: motivo O en ND, en una DEV con origen con NCF y en una DEV con origen histórico con NCF, todo con 51425. `CK_Documento_MotivoHistorico`. |
| D-14 | **H-6.** Una autorización `SIN_NCF` con motivo vacío da 547 (`CK_Autorizacion_Motivo`). |
| D-15 | **Rendimiento.** La importación de las 9.604 del DEMO antes y después. El p95 de la venta del POS, sin cambio medible. |
| D-16 | **Guarda.** Ninguna vista de `rpt` que lea `fiscal.Comprobante` incluye H en el 607 o el 608 (prueba sobre `sys.sql_modules`). |

---

## 15. Esfuerzo (sp = semana-persona de 40 h; **todo inferido**)

| Partida | sp (centro, rango) |
|---|---|
| H-2, datos: migración, relleno, vista, disparadores, Down, modelo de EF y guion | 0,40 (0,30–0,55) |
| H-2, aplicación: importación, `NcfDocumento` y sus 4 llamadores, lecturas, traducciones 51420 a 51422 y 2601, y anulación | 0,35 (0,25–0,50) |
| H-2, pruebas D-01 a D-09, D-11, D-12, D-15 y D-16 | 0,30 (0,20–0,40) |
| H-2, DEMO (LEEME, `ImplantacionDemoTests` y el instalador) | 0,10 (0,05–0,15) |
| **H-2, total** | **1,15 (0,80–1,60)**. Coincide con el «≈ 1 semana-persona» de ADR-11 |
| H-3: columna, disparadores, parámetro en la API y la Web, importación, bitácora y D-10 | 0,40 (0,30–0,60) |
| H-4: restricción, reglas y D-13 | 0,30 (0,20–0,40) |
| H-6: restricción, motivo en la Web y MAUI, y D-14 | 0,15 (0,10–0,25) |
| H-7: evento | 0,10 (0,05–0,15) |
| P-3 (si se elige la acción «Saltar NCF históricos») | 0,20 (0,15–0,30) |

Costo de infraestructura: ninguno. No hay servicios ni licencias nuevos, y el crecimiento de la base es la sección 2.

---

## 16. Preguntas para el propietario (numeradas)

**P-1. Anular una factura histórica con NCF.**
- (a) **Recomendado:** prohibido (51422). Se corrige con una nota de crédito B04, como la regla «un e-NCF no se anula». Anular un NCF que el sistema anterior emitió y probablemente declaró no corresponde al 608 de GPOS.
- (b) Permitido, sin el 608 (el filtro ya lo excluye).

**P-2. Fecha de implantación.**
- Se crea el parámetro nuevo `conf.Parametros.FechaImplantacion` (**recomendado**).
- La primera vez la fija el ADMIN o el SUPER, y luego solo el SUPER con motivo. ¿De acuerdo?
- En las bases existentes, ¿se infiere como el día siguiente a la última factura histórica? **Recomendado: sí.** Hoy todo es desarrollo.

**P-3. Remedio de un bloque vigente que se solapa con NCF históricos.**
- (a) **Recomendado:** una acción del ADMIN o el SUPER, «Saltar los NCF del sistema anterior», que adelante `Siguiente` hasta el mayor H más uno, con motivo y bitácora.

  [I] Para la DGII esos números los usó el otro sistema, y los que queden sin uso dentro del salto serían huecos. Conviene que el contador confirme si los huecos van al 608.
- (b) Que la migración adelante sola.
- (c) Solo el reporte y que soporte lo resuelva a mano. Hoy no se puede: 51326 impide subir `Desde` y 51324 impide registrar un bloque nuevo encima del cerrado.

**P-4. Facturas históricas con incidencia** (NCF mal formado, duplicado o ya usado).
- (a) **Recomendado para la entrega 1:** quedan sin devolución ni nota (422) y se corrigen reimportando en una base nueva. Hoy no hay clientes con historia.
- (b) Una herramienta del SUPER para registrar a mano el NCF corregido, con motivo (unos 0,2 sp [I]).

**P-5. ¿La fecha de implantación vale también para las otras importaciones de la implantación?** Son tres: cuentas por pagar pendientes, saldos iniciales bancarios y el corte de las existencias iniciales. Recomendado: sí para las dos primeras, en la tanda de H-4; el corte de las existencias, igual o posterior.

**P-6. Factura histórica B01 o E31 cuyo cliente no tiene RNC.** Recomendado: advertencia, no error. El dato lo emitió el sistema anterior.

**P-7. Números de error.** Reservar del 51420 al 51425 para el equipo A en el área común. El equipo B ya cita del 51400 al 51412.

**P-8. H-7.**
- (a) **Recomendado:** el evento solo en el registro del servidor (Visor de eventos).
- (b) Además, una línea en `audit.Bitacora` con una conexión aparte. Es más auditable, pero suma una escritura por rechazo y una segunda conexión.

**P-9. H-6.** ¿Cuál es el largo mínimo del motivo del usuario? Recomendado: 10 caracteres. ¿Se conserva también en `_LOG` junto con el texto actual?

---

### Decisiones candidatas a ADR (las redacta el Arquitecto Maestro)

- **D-1. Rol H en `fiscal.Comprobante`.** Precisa ADR-11, punto 3.
  - Contexto: el NCF histórico era invisible para la emisión.
  - Elegida: un rol propio sin secuencia, con `UQ_Comprobante_Ncf` compartido.
  - Descartada: la opción (b) del hallazgo, que `NcfDocumento` cayera en `Referencia`. No detecta solapes con bloques, deja el NCF fuera del espacio único y no lo valida en el motor.
- **D-2. `conf.Parametros.FechaImplantacion`, atada a la primera factura propia.**
  - Descartadas: inferirla de los documentos o del corte de las existencias (8.1).
- **D-3. Una factura histórica con NCF no se anula (P-1).**
- **D-4. Reglas en disparadores propios** (`TR_Documento_Historico` y `TR_Documento_SinNcf`) en lugar de parchear `TR_Documento_Emision`.
  - Descartado el parche: cada versión del disparador de emisión (7 hasta hoy) arrastra el riesgo de regresión.

### Entregas a otros agentes

- **Desarrollador backend (A):**
  - las migraciones de las secciones 7 a 9, el modelo de EF, `DisparadoresNg` y el guion;
  - las consultas de 7.4;
  - la importación;
  - las traducciones 51420 a 51425 y 2601 con sus códigos 422 y 409;
  - el parámetro de la fecha con su privilegio;
  - confirmar que la devolución de `DocumentosComercialesService` llena `DocumentoOrigenId`.
- **QA (A):** las pruebas D-01 a D-16 y el ayudante que fija la fecha de implantación en las pruebas existentes (RO-2).
- **Seguridad (A):** revisión fiscal de H-2 y H-3, que el encargo exige; en especial RF-1 a RF-3, RF-7 y el `DISABLE TRIGGER`.
- **Especialista POS:** el remedio de P-3 y el aviso en la banda NCF del POS por `COLISION_FUTURA`; RF-5 (B04 o E34 con origen B en una empresa con e-CF); el LEEME del DEMO.
- **UX:** el campo de la fecha de implantación, los textos 422 nuevos (sin sugerir «No generar comprobante»), y el motivo de H-6 en la Web y MAUI.
- **Equipo B:**
  - toda vista de la ola 5 (`rpt` o `rptc`) que lea `fiscal.Comprobante` filtra el rol: `IN ('O','H')` para mostrar, y `'O'` para el 607 y el 608;
  - en la entrega 2, replicar las filas H a los nodos y aplicar 51421 en el nodo.
- **DevOps:** que `Instalar-Demo.ps1` fije la fecha de implantación; que el paquete del DEMO salga con el guion regenerado.
- **Documentador técnico:** el registro de 51420 a 51425 y de los códigos 422 nuevos.
