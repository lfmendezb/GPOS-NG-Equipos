# RB-P5, RB-P3 y RB-P4: texto completo de los disparadores de emisión, prueba de equivalencia y pruebas de base

**Autor:** arquitecto de datos del equipo B · **Fecha:** 2026-10-10 · **Estado:** Completado (diseño; pendiente de construcción)
**Origen:** ADR-52, precisión RB-P1 a RB-P6 firmada el 2026-10-10 (`docs/adr/ADR-052.md`); informe `docs/datos/2026-10-10-inventario-reglas-en-base.md` (rama `feature/modelo-ng`, commit `ec459d5`).
**Base del trabajo:** guion `database/empresa/gpos-empresa-20261010130522_BitacoraLogSoloInsercion.sql` (rama `feature/modelo-ng`, árbol `GPOS-B-modelo-ng`, solo lectura) y PR #21 (`origin/c/compra-variable-tabla`, commit `dfde08e`, sin unir).
**Artefactos SQL:** `scratchpad/sql/rb-p5/` (rutas absolutas en el cierre).

---

## [Blueprint de Datos]

### 1. Contexto y modelo de tenencia aplicado

- Tenencia: una base por empresa (ADR-52/53). Los disparadores viven en cada base de empresa (`doc.Documento`). Este trabajo no cambia el aislamiento: no agrega tablas, columnas, índices ni permisos.
- En `feature/modelo-ng`, el esquema de empresa se arma con migraciones de EF cuyo SQL escriben a mano las clases `SqlMigraciones*.cs`. El guion idempotente embebido en `GPOS.Migracion` es el que se instala (`src/GPOS.Migracion/ScriptEmpresa.cs:22`), y una prueba exige que sea idéntico al que genera EF (`tests/GPOS.Tests/ModeloNg/AprovisionamientoTests.cs:155-163`).
- Problema (RB-03): el texto vigente de los tres disparadores grandes no está escrito en ningún archivo. Sale de encadenar parches de cadena (`Parchear`, `ParchearSql`, `LoteDe`; `SqlMigracionesOla4b.cs:394-427`, `SqlMigracionesOla4FactorUnidad.cs:128`) sobre los lotes de migraciones anteriores.

**Cómo verifiqué el texto vigente (evidencia, no inferencia):**
1. Creé `GPOS_TEST_RBP5_ARQDATOS` en `.\SQLEXPRESS` (intercalación `Latin1_General_100_CI_AS_SC_UTF8`, la de `Aprovisionamiento.cs:68`) y le apliqué el guion completo: 34 migraciones, 0 errores. Hace falta `sqlcmd -I`: sin QUOTED_IDENTIFIER, el guion falla en los índices filtrados (Msg 1934).
2. Extraje del guion la última `EXEC(N'CREATE OR ALTER TRIGGER …')` de cada objeto con `herramientas/extraer.pl`. El literal se lee como `(?:[^']|'')*`; un primer intento con `.*?` cortaba el literal del PR #21 en un `'');`.
3. Comparé byte por byte esa extracción con `OBJECT_DEFINITION` de la base (`herramientas/volcar.ps1`): **idénticas en los 5 objetos**. La única diferencia es la cabecera: SQL Server guarda `CREATE OR ALTER TRIGGER` como `CREATE   TRIGGER`.
4. Quité la sangría que agrega EF (`herramientas/desangrar.pl`, ver 7.2) y volví a ejecutar cada texto con esa sangría (`herramientas/ronda.ps1`). En una base recién creada con el guion, la definición normalizada coincide con el archivo antes y después: **True/True en los 4 objetos**. Las dos variantes compilan.

| Disparador | Versiones en el guion | Última (línea del guion) | Migración de la última | Líneas | Bytes (LF) | SHA-256 del archivo |
|---|---|---|---|---|---|---|
| `doc.TR_Documento_Emision` | 7 | G:11945 | `20261010030111_Ola4OrdenRecibida` | 252 | 23 037 | `22840a4e…a4b7` |
| `doc.TR_Documento_Ola4` | 5 | G:11737 | `20261010030111_Ola4OrdenRecibida` | 208 | 37 557 | `d090a031…cf34` |
| `doc.TR_Documento_Ola4b` | 3 | G:9780 | `20261007183910_Ola4Huecos` | 184 | 29 170 | `a5baaf58…9d33` |
| `doc.TR_Documento_Anulacion` | 3 | G:12197 | `20261010030111_Ola4OrdenRecibida` | 35 | 3 401 | `4be9ff2d…cfda5` |

---

### 2. Tablas y relaciones

No aplica: no hay cambios de tablas.

Sí cambian los artefactos de código. La propuesta (sección 7.3) agrega una carpeta de SQL con el texto completo de cada disparador.

---

### 3. Restricciones e integridad (entregables 1 y 3)

#### 3.1 Entregable 1: texto vigente completo

Archivos en `scratchpad/sql/rb-p5/`, con LF, UTF-8 sin BOM y sin la sangría de EF. Son el texto tal como se escribiría en el código; con la sangría de EF, cada uno reproduce exactamente la definición de la base.

| Archivo | Qué es |
|---|---|
| `doc.TR_Documento_Emision.sql` | Texto vigente. THROW: 51303 a 51309, 51311 (×2), 51320, 51321, 51330, 51380 a 51382 y 51405 (×5). |
| `doc.TR_Documento_Ola4.sql` | Texto vigente **sin el PR #21**. THROW: 51315 a 51317 (de CxP), 51341 a 51358 y 51407. |
| `doc.TR_Documento_Ola4.pr21.sql` | **Variante con el PR #21** (C-10): extraída del guion de la rama `origin/c/compra-variable-tabla` (`gpos-empresa-20261010155005_Ola4CompraVariableTabla.sql`). |
| `doc.TR_Documento_Ola4.pr21.diff` | Diferencia entre las dos versiones de Ola4. Agrega el bloque `BEGIN … DECLARE @e TABLE … INSERT @e … END` dentro de la guarda de 51344 y cambia 9 tablas derivadas por `@e e`. Fuera de 51344 no cambia nada (mismo resultado que `CompraVariableTablaTests.SinVariable`). |
| `doc.TR_Documento_Ola4b.sql` | Texto vigente. Reglas 51359 a 51372, 51374, 51375, 51377 y 51379. |
| `doc.TR_Documento_Anulacion.sql` | Texto vigente, con el 51312 repetido (líneas 7 a 9). |
| `doc.TR_Documento_Anulacion.sin51312.sql` | **RB-P3:** el mismo texto sin las líneas 7 a 9; nada más cambia (`.sin51312.diff`). |

**Observaciones del texto:**
- `Ola4b` tiene dos bloques con la sangría corrida, restos de los parches: 51365 (líneas 61 a 67) y el comentario de HC-10 (línea 68).
- **Recomendación:** no reformatear en la misma migración. Si se arregla la sangría, la equivalencia exacta del nivel 1 deja de servir y hay que usar el nivel 3 (sección 4.2). Conviene reformatear en una migración aparte o no hacerlo.

**RB-P3 (51312): por qué quitarlo no cambia la conducta**
- `TR_Documento_Motivo608` lanza el mismo número con una condición que **contiene** la de `Anulacion`. Con NCF exige `MotivoAnulacionId`, `CodigoAnulacion608` y que el tipo coincida con el del maestro (verificado en la base).
- **Lo único que cambia es el mensaje.** Hoy, cuando falta `CodigoAnulacion608`, el mensaje depende del disparador que corra primero, porque el orden no está fijado: puede salir «(CA-02)» o «(Q-3)». Después siempre sale «…un motivo de anulación y el tipo del 608 de ese motivo (Q-3)».
- La API clasifica por número, no por mensaje: `ErroresNumeracion.cs:409-411` y `MotivosAnulacionTests.cs:140`. Ninguna prueba compara el mensaje de CA-02 (búsqueda en `src` y `tests`). El caso «23 anular con NCF sin motivo» (`DisparadoresEmisionTests.cs:201`) espera 51312 y sigue pasando.

#### 3.2 Entregable 3: lista de pruebas de RB-P4 (lista para QA)

**Hallazgo que corrige el inventario (sección 6.4 del informe):**
- **51376 sí tiene prueba:** `MigracionOla4bTests.cs:192-208`, con el caso 547 (las dos clases a la vez), el caso de cambio sin uso y el 51376 con un movimiento.
- **51359** tiene pruebas del camino feliz (`ComprasOla4Tests.cs:62`, `ConversionOla4Tests.cs:80`), pero ninguna en la que falle.
- Las otras cuatro (51379, 51362, 51374 y 51375) no tienen prueba localizada (búsqueda por número y por código en `tests/`). Severidad del hallazgo: Baja (el informe sobrestimaba el hueco en 51376).

**Forma común de las pruebas** (la de `DisparadoresEmisionTests` y `CompraVariableTablaTests`; esqueleto en `esqueleto/ReglasSoloBaseTests.cs`):
- Orígenes emitidos una vez por base con los servicios.
- Cada caso, dentro de una transacción que se deshace:
  1. copia el origen en borrador con `FactorUnidadKardexTests.Copia` y `CopiarFilas`, más el kárdex con `Kardex(...)` si el tipo mueve inventario;
  2. rompe **una** condición;
  3. ejecuta `SET @fase = 'acto';` y `Emitir("@a")`;
  4. comprueba el número y el código de la API que va entre paréntesis en el mensaje.
- Base propia, porque varios casos cambian `conf.Parametros` dentro de la transacción.

**Condiciones comunes de `TR_Documento_Ola4b`** (leídas del texto, líneas 4 a 12 y 25 a 30), que la preparación debe respetar:
- el documento emitido tiene `ControlFecha >= 2` (todos los de oficina son 3: FAC, DEV, NC, REC, FCP, DVS, NCP, CHK, APS…) y `Origen <> 'I'`;
- sin `SESSION_CONTEXT` `gpos.incorporacion` ni `gpos.reaplicacion`;
- `FiscalDeclaradoHasta` en NULL (la base de prueba nace así);
- fecha del acto igual a hoy (F-1 y F-2). «Hoy» del motor es `@hoyMin = CONVERT(date, DATEADD(MINUTE, -245, SYSUTCDATETIME()))`, con 5 minutos de holgura;
- los casos con límite de días se saltan si corren a menos de 10 minutos de la medianoche de RD.

| # | Regla (código API) | Preparación (en la transacción) | Resultado esperado |
|---|---|---|---|
| **P1** | 51379 `PLAZO_FISCAL` | Origen: FAC con fecha de hace 31 días y NC de ventas sobre ella, emitida hoy por el servicio, que la marca `FueraPlazoFiscal = 1` (`DocumentosComercialesService.Ventas.cs:71,277`). Para la FAC retrofechada: `TopeDiasAnteriores = 40`, privilegio «Fechar documentos en días anteriores» y `MotivoFechaAnterior` (patrón de `FechaAnteriorServicioTests`). Acto: copia de la NC con `UPDATE ventas.Venta SET FueraPlazoFiscal = 0`. | 51379 |
| P2 | 51379 (control) | Copia de la misma NC, sin cambios (marca en 1). | 0 |
| P3 | 51379 (límite) | Igual que P1, con la FAC a **30** días y la marca en 0. | 0 (la regla exige más de 30) |
| P4 | 51379 (DEV) | Igual que P1, con una devolución de mercancía (`DEV`, con kárdex) en lugar de la NC. | 51379 |
| P5 | 51379 (incorporación) | Igual que P1, con `EXEC sp_set_session_context N'gpos.incorporacion', 1` antes del acto. | 0 (sale en la línea 6) |
| **P6** | 51359 `COMPRA_606_COSTO` | Origen: FCP en pesos con una línea `ItbisAlCosto = 36` e `IscAlCosto = 10` (como `ComprasOla4Tests.cs:62`). Tablas: `compras.Compra`, `CompraLinea`, `cxp.Cuenta`, `fiscal.Registro606` y `fiscal.Comprobante` (`TablasCompra` de `CompraVariableTablaTests`), más el kárdex. Acto: `UPDATE fiscal.Registro606 SET ItbisAlCosto = ItbisAlCosto + 1`. | 51359 |
| P7 | 51359 (ISC) | Igual, con `UPDATE fiscal.Registro606 SET Isc = Isc - 0.01`. | 51359 |
| P8 | 51359 (ISC de más) | Igual, con `Isc = Isc + 5`: la regla solo prohíbe que sea menor. | 0 |
| P9 | 51359 (moneda) | Origen: FCP en US$ a 58,5 (como `ConversionOla4Tests.cs:80`): 2.106 / 585. Acto: `UPDATE fiscal.Registro606 SET ItbisAlCosto = 36` (sin convertir). | 51359 |
| P10 | 51359 (control) | Copia de la FCP, sin cambios. | 0 |
| **P11** | 51362 `DEVOLUCION_EXCEDE` | Origen: FCP de 2 artículos (línea 1: 5 unidades del artículo A; línea 2: artículo B), con existencia inicial suficiente para no depender de ADR-118. DVS de 2 unidades de la línea 1, emitida por el servicio. Tablas de la copia: `compras.Compra`, `CompraLinea`, `cxp.Credito` (51361 exige el saldo a favor por el total) y el kárdex. Acto: copia @a de la DVS, `SET @fase = 'acto'`, `Emitir(@a)`, copia @b y `Emitir(@b)`: en total 6 > 5. | 51362 (en @b) |
| P12 | 51362 (control) | Una sola copia: en total 4 ≤ 5. | 0 |
| P13 | 51362 (artículo) | Copia con `UPDATE compras.CompraLinea SET OrigenLinea = 2`: cita la línea del artículo B y no cambia totales ni kárdex. | 51362 |
| P14 | 51362 (otra factura) | Copia con la línea citando otra FCP emitida (`OrigenDocumentoId` distinto de `Compra.DocumentoOrigenId`). | 51362 |
| **P15** | 51374 `RETENCION_RECIBIDA_INVALIDA` | Origen: FAC a crédito de 1.000 + ITBIS 180 a un cliente con RNC, y REC emitido por el servicio que aplica 500 con `RetencionItbis = 54`, `RetencionIsr = 0` y `FechaRetencion` = hoy. Tablas de la copia: `cxc.Recibo`, `ReciboPago`, `Aplicacion` y `ReciboCredito` si las hay. El cuadre 51334 solo suma `Monto` (`TR_Documento_Credito`, verificado), así que cambiar retenciones o fechas no lo rompe. Acto: `UPDATE cxc.Aplicacion SET FechaRetencion = DATEADD(DAY, 1, <fecha del REC>)`. | 51374 |
| P16 | 51374 (antes de la factura) | `FechaRetencion = DATEADD(DAY, -1, <fecha de la FAC>)`. | 51374 |
| P17 | 51374 (acumulado de ITBIS) | Tres copias del REC emitidas en el mismo lote: 54 × 4 = 216 > 180. | 51374 (en la tercera) |
| P18 | 51374 (acumulado de ISR) | Copia con `RetencionIsr = 1001` (base 1.000). Si salta 51375 antes, ajustar también `MontoBaseFactura`: 51374 se evalúa primero en el mismo disparador (línea 159 frente a 172). | 51374 |
| P19 | 51374 (no es recibo) | Copia de una NC de ventas que aplica a la FAC, con `UPDATE cxc.Aplicacion SET RetencionItbis = 1`. | 51374 |
| P20 | 51374 (control) | Una copia del REC, sin cambios: 108 ≤ 180. | 0 |
| **P21** | 51375 `MONTO_BASE_INVALIDO` | Copia del REC de P15 con `UPDATE cxc.Aplicacion SET MontoBaseFactura = MontoBaseFactura + 0.01`. | 51375 |
| P22 | 51375 (tasa de la factura, CXC) | Origen: FAC en US$ a 58,5 y REC en US$ a 60. Acto: `MontoBaseFactura = ROUND((Monto + RetencionItbis + RetencionIsr) * 60, 2)`, es decir, a la tasa del pago. | 51375 |
| P23 | 51375 (CXP) | Origen: FCP en US$ y su pago (APS o CHK) emitido por el servicio en la central. Acto: `UPDATE cxp.Aplicacion SET MontoBaseFactura = MontoBaseFactura + 0.01`. | 51375 (si salta antes una de 51347 a 51349, revisar si alguna lee `MontoBaseFactura`; inferido que no) |
| P24 | 51375 (control) | Copias de P22 y P23 sin cambios. | 0 |
| **P25** | 51376 `MOTIVO_EN_USO` (complemento de `MigracionOla4bTests.cs:192`) | Motivo usado (mismo truco de la prueba existente: `NOCHECK` y `DISABLE TRIGGER` en `inv.Movimiento`, dentro de la transacción). Acto: `UPDATE inv.MotivoAjuste SET EsMerma = 0`. | 51376 |
| P26 | 51376 | Motivo usado: `UPDATE … SET Descripcion = 'x', Inhabilitado = 1`. | 0 (no entra: `UPDATE()` de la línea 4) |
| P27 | 51376 | Motivo usado: `UPDATE … SET EsMerma = EsMerma`. | 0 (`UPDATE()` es verdadero, pero no hay cambio) |
| P28 | 51376 | Dos motivos, uno usado y otro no, en un solo `UPDATE`. | 51376 (toda la sentencia) |
| **P29** | RB-P3: 51312 | Venta con NCF (origen `ConNcf` de `DisparadoresEmisionTests`). Acto: anular sin `CodigoAnulacion608` ni motivo. | 51312 y el mensaje contiene «(Q-3)». Determinista solo después de RB-P3. |
| P30 | RB-P3 | Anular con `CodigoAnulacion608` y sin `MotivoAnulacionId`. | 51312 |
| P31 | RB-P3 | Catálogo: `OBJECT_DEFINITION(OBJECT_ID('doc.TR_Documento_Anulacion'))` no contiene `THROW 51312`. | Verdadero |

**Notas para QA:**
- Las preparaciones de P1 a P24 están inferidas de la lectura del texto de los disparadores. La de 51376 está verificada contra una prueba existente.
- Si la preparación hace saltar otra regla antes, la prueba falla con el otro número. Hay que ajustar la preparación, nunca el número esperado.
- **Esfuerzo:** de 1 a 1,5 días de QA para 31 casos; el costo está en los orígenes. Sin costo de infraestructura.

---

### 4. Índices y consultas que los justifican

No aplica: no hay índices nuevos. (El PR #21 incluye columnas en `UQ_CxpAplicacion`; es de C y ya está justificado en su migración.)

#### 4.1 Entregable 2: método de prueba de equivalencia

| Nivel | Qué prueba | Cómo | Cuándo |
|---|---|---|---|
| **N1: textual exacta, sin base** | El texto consolidado es, carácter por carácter, el que armaban los parches. | `GenerateScript(null, migración, Idempotent)` → último literal `EXEC(N'CREATE OR ALTER TRIGGER {objeto} ON …')` (regex `(?:[^']|'')*`) → `''`→`'` → quitar 4 espacios de las líneas 2..n (las vacías no llevan) → CRLF→LF → igual al archivo. | En cada copia congelada; la primera de cada objeto es la prueba de la consolidación. |
| **N2: catálogo** | Lo instalado es el archivo vigente. | Base del fixture (guion embebido) → `sys.sql_modules.definition`, con `uses_ansi_nulls = 1` y `uses_quoted_identifier = 1` → `CREATE   TRIGGER`→`CREATE OR ALTER TRIGGER` → misma normalización → igual al vigente. | Siempre. |
| N3: léxica (opcional) | Equivalencia después de reformatear. | Comparar la secuencia de tokens sin comentarios ni espacios (analizador propio por regex, o `Microsoft.SqlServer.TransactSql.ScriptDom` si se acepta la dependencia en `GPOS.Tests`). | Solo si se reformatea. **Recomendación: no reformatear y no hace falta N3.** |
| **Huella de reglas** | Ningún THROW se pierde ni cambia sin declararlo. | Multiconjunto de pares (número, mensaje) entre copias congeladas consecutivas, con una tabla de cambios declarados (p. ej., RB-P3 quita «51312 … (CA-02)»). | En cada migración que cambie el disparador. |
| **N4: conducta** | La regla responde con su número. | Batería por regla: las pruebas existentes (27 casos de `DisparadoresEmisionTests`, 6 de `CompraVariableTablaTests`, etc.) más las de 3.2. | Siempre. |

**Precisiones del método:**
- **Con N1 exacta, la equivalencia ya está probada:** el motor recibe el mismo texto. N4 no prueba la equivalencia de la consolidación; vigila el **cambio** que trae la migración (número al final, RB-P3, PR #21).
- La normalización (CRLF, sangría de EF y cabecera) está **verificada** hoy en SQL Server 2025 Express. EF normaliza los fines de línea del guion (13 950 CR en 13 950 líneas). Que lo hace `IndentedStringBuilder` es inferido.
- **Esqueleto:** `esqueleto/DisparadoresTextoCompletoTests.cs`, con las pruebas N1, V (el vigente es la última copia congelada), N2, M (toda migración posterior que redefine el objeto tiene su copia congelada) y la de la huella. Las pruebas no necesitan `InternalsVisibleTo`: leen los recursos incrustados de `GPOS.Core` y el guion que genera EF, como hace C en `CompraVariableTablaTests.cs:52-102`.

---

### 5. Auditoría y trazabilidad

- No cambia la auditoría de datos.
- Mejora la trazabilidad del código:
  - `git log --follow` sobre el archivo vigente muestra la historia de cada disparador;
  - la revisión de una migración es un `git diff` entre dos copias congeladas, en lugar de leer el guion.

---

### 6. Persistencia de sincronización

No aplica.

---

### 7. Script de migración y reversión (entregable 4)

#### 7.1 Dónde vive el texto completo

```
database/empresa/disparadores/
  doc.TR_Documento_Emision.sql            ← VIGENTE: el único que se lee y se edita
  doc.TR_Documento_Ola4.sql
  doc.TR_Documento_Ola4b.sql
  doc.TR_Documento_Anulacion.sql
  congelados/
    doc.TR_Documento_Emision.20261010030111_Ola4OrdenRecibida.sql   ← base (el texto de hoy)
    doc.TR_Documento_Emision.<migración nueva>.sql                  ← lo que escribe esa migración
    …
```

**Por qué en `database/empresa/` y no en `src/`:**
- Es SQL, como el guion.
- Embebido en `GPOS.Core` con `<EmbeddedResource Include="..\..\database\empresa\disparadores\**\*.sql" LinkBase="Disparadores" />`, junto a la línea de `GPOS.Core.csproj:26`.
- No se cruza con el comodín de `GPOS.Migracion.csproj:26` (`gpos-empresa-*.sql`), ni con la prueba que exige un solo recurso con ese prefijo.

**Nombres:**
- La migración va en el **nombre del archivo** y no en una carpeta: una carpeta que empieza con un dígito cambia de nombre en el recurso (le antepone `_`; inferido de la conducta de MSBuild).
- La búsqueda es por sufijo, como hace `ScriptEmpresa.Texto()`.

**Formato:** UTF-8 sin BOM; `CREATE OR ALTER TRIGGER …` en la primera línea; comillas sin doblar; sin la sangría de EF. Los fines de línea no importan, porque EF los normaliza y las pruebas también.

#### 7.2 Cómo convive con las migraciones viejas

- **Las migraciones viejas y sus funciones C# no se tocan.** Siguen armando con parches su versión histórica, y así el guion sigue siendo el que genera EF (`AprovisionamientoTests.cs:155`).
- **Nunca se borra** `EmisionConAjustes()`, `DocumentoOla4OrdenRecibida()` ni las demás: las usan los `Down` y los `Up` históricos.
- **Una migración nunca lee el vigente; lee su copia congelada.** Si leyera el vigente, la edición siguiente cambiaría su `Up` histórico, y fallarían la prueba del guion y la N1.
- La prueba V ata el vigente a la última copia congelada; la prueba M impide volver al parche.
- **Paso 0, ya y sin migración (riesgo nulo):**
  1. subir los 4 vigentes y sus 4 copias base (las de 3.1, sin la variante del PR #21), con las pruebas N1, V y N2;
  2. el guion no cambia;
  3. desde ese momento, el texto se lee en un solo archivo.
  - Esfuerzo: 0,5 día-persona.
- **Paso 1, en la próxima migración que toque cada disparador:**
  1. editar el vigente;
  2. copiarlo como `congelados/{objeto}.{migración}.sql`;
  3. escribir la migración:

```csharp
// SqlMigraciones<Nombre>.cs (propuesto). Disparador(): lee el recurso congelado y lo pasa por Exec (SqlMigracionesOla3.cs:9).
internal static string Disparador(string objeto, string migracion) =>
    Exec(RecursoSql($".disparadores.congelados.{objeto}.{migracion}.sql"));

public static string NumeroAlFinalDisparadores() =>
    Disparador("doc.TR_Documento_Emision", "2026MMDDhhmmss_NumeroAlFinal");            // y los demás que toque
public static string NumeroAlFinalDisparadoresDown() =>
    Disparador("doc.TR_Documento_Emision", "20261010030111_Ola4OrdenRecibida");        // la copia anterior
```

  - **Reversión:** el `Down` ejecuta la copia congelada anterior. La de la base es el texto de hoy, idéntico al que dejan los parches (N1). No hay pérdida de datos: un disparador no guarda datos.
- **Orden respecto del PR #21** (recomendado):
  - unir primero el PR #21, después del 14 de octubre, como ya prevé RB-07;
  - la base de Ola4 pasa a ser `congelados/doc.TR_Documento_Ola4.20261010155005_Ola4CompraVariableTabla.sql` (= `doc.TR_Documento_Ola4.pr21.sql`), y el `Down` del PR sigue con su función.
  - Si la consolidación de Ola4 se une **antes** que el PR #21, C tiene que rehacer `DocumentoOla4ConVariableTabla()` (`SqlMigracionesOla4CompraVariableTabla.cs`) para que edite el vigente en lugar de parchear `DocumentoOla4OrdenRecibida()`, y regenerar el guion.
- **RB-P3:** se aplica en la primera migración que toque `TR_Documento_Anulacion`. Si ninguna lo toca antes del corte, entra en la del número al final, que ya toca la emisión. El vigente pasa a ser `doc.TR_Documento_Anulacion.sin51312.sql`, con el cambio declarado en la tabla de la huella.
- **Idempotencia:** `CREATE OR ALTER` es idempotente, y EF lo envuelve en la guarda de `__EFMigrationsHistory`, como el resto del guion.

---

### 8. Respaldo, restauración y retención

No aplica: no cambian datos. La guía general sigue igual: actualizar con la API detenida y con respaldo previo.

---

### 9. Privilegios de base de datos

No aplica: no cambian los permisos. `CREATE OR ALTER TRIGGER` lo ejecuta la cuenta de migración, no la de la aplicación.

---

### 10. Riesgos

| Riesgo | Severidad | Mitigación |
|---|---|---|
| Alguien edita una copia congelada ya publicada | Media | Fallan la N1 y la prueba del guion (`AprovisionamientoTests.cs:155`). |
| Una migración nueva vuelve al parche o lee el vigente | Media | Fallan las pruebas M y V. |
| El PR #21 y la consolidación de Ola4 chocan | Media | Unir primero el PR #21 (sección 7.2). |
| El mensaje de 51312 cambia (CA-02 → Q-3) | Baja | La API clasifica por número; P29 fija el mensaje nuevo. |
| Bloqueo durante la migración: `CREATE OR ALTER TRIGGER` toma Sch-M sobre `doc.Documento` | Baja | Dura milisegundos, pero espera a las emisiones en curso. Migrar con la API detenida (práctica vigente). |
| Recompilación de planes después de redefinir | Baja | El texto es idéntico; ya ocurre en cada migración que toca el disparador; la vigila la prueba de planes. |
| Guion aplicado a mano con `sqlcmd` sin `-I` | Baja | Falla visible (Msg 1934); N2 comprueba `uses_quoted_identifier`. |
| Reformatear el texto en la misma migración | Baja | No hacerlo, o usar N3. |

**Costo total:** paso 0, 0,5 día-persona; RB-P4, de 1 a 1,5 días de QA; RB-P3, 1 hora dentro de otra migración. Sin infraestructura ni licencias.

**Alternativas descartadas:**
- **Raw strings de C# por versión:** igual de legibles, pero el SQL queda fuera del resaltado y del `diff` de archivos `.sql`.
- **Solo copias por versión, sin vigente:** la ruta de lectura cambia en cada versión y se pierde `git log --follow`.
- **Seguir con parches:** es el riesgo RB-03 (un parche que encuentra una marca equivocada pasa sin error).
- **Migración de consolidación sin otro cambio:** agrega un bloque idéntico al guion sin beneficio; el paso 0 da lo mismo sin migración.

---

### Supuestos
- El nombre de la migración del número al final todavía no existe; en el ejemplo es `2026MMDDhhmmss_NumeroAlFinal`.
- Que MSBuild antepone `_` a las carpetas que empiezan con un dígito en el nombre del recurso es inferido; por eso la propuesta pone la migración en el nombre del archivo.
- El PR #21 se une sin cambios en su texto de Ola4: la variante sale de su commit `dfde08e`.

### Entregas a otros agentes
- **desarrollador-backend (A o B, quien construya):**
  - paso 0: archivos, `EmbeddedResource`, ayudante `Disparador()` y `DisparadoresTextoCompletoTests` a partir del esqueleto;
  - paso 1 en la migración del número al final, con RB-P3.
- **QA:** las 31 pruebas de 3.2 (`ReglasSoloBaseTests`).
- **Equipo C:** si su PR #21 se une después de la consolidación de Ola4, rehacer el parche como edición del vigente (sección 7.2).
- **Documentador técnico:** corregir en el informe del inventario (6.4 y RB-02) que 51376 ya tiene prueba y que 51359 solo tiene el camino feliz.
