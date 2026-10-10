# [Informe de Seguridad] T1 de ADR-118/119 (construido) y diseño del tramo 1 de la ola 3b

Auditor de seguridad, equipo B · 2026-10-10 · **Solo lectura**: no edité nada, no compilé y no ejecuté pruebas.

- **Árbol revisado:** `GPOS-B-adr118`, rama `b/adr118-119-t1`. Revisé `63401d0..d2e28ec` (T1) y también los commits nuevos del backend S que ya estaban al revisar: `d2a1a5c` (T2), `28c3e78` (T4 del servidor) y `106fa26` (pruebas). HEAD: `106fa26`. Las rutas `src/…` son relativas a ese árbol.
- **Diseño de la 3b:** `GPOS-NG-Equipos/traspasos/B/2026-10-10-plan-ola3b.md` [PLAN], `2026-10-10-ola3b-ddl-corregido.md` [DDLm], `ola3b-ddl/ola3b-ddl-corregido.sql` [DDL] y `2026-10-10-ux-transferencias.md` [UX].
- **Firmas contrastadas:** ADR-118, ADR-119 (con las precisiones del 2026-10-10, puntos 1 a 8), ADR-105, ADR-106, ADR-053 (cláusula 9, CR-01) y CLAUDE.md (orden único de bloqueos).
- **Convención:** [V] = verificado leyendo el código o el SQL citado; [S] = sospecha que hay que confirmar con una prueba. No incluyo pasos de explotación.

---

## 1. Alcance y superficie revisada

| Superficie | Elementos |
|---|---|
| Núcleo de existencias (T1) | `ConsultasInventario.AplicarExistencia`, `AplicarExistenciaLote`, sus variantes `Estricta`, `LoteDeArticulo`; `LibroInventario` (preparación, lote de comandos, `ExistenciasEnLote.Exigir`, `ExigeLoteVigente`, reversos); migración `NegativosTresNiveles` (vista `inv.PoliticaNegativa`, `inv.RevisionLote`, `CK_Lote_Vencimiento` WITH NOCHECK, retiro de `LoteVencido = 'A'`, `Down`) |
| Caminos de salida | POS rápido (`PosService.VenderAsync`), factura de venta, factura desde conduce, conduce, ajuste, merma, devolución POS y de oficina, reversos de anulación, importación de existencias iniciales |
| Endpoints nuevos (T2 y T4) | `GET /api/inventario/lotes-disponibles`, `GET /lotes/existe`, `GET|POST /revisiones-lote…`; `POST /api/admin/parametros` (motivo de negativos) |
| Privilegios | «Revisión de lotes» (`revisionlotes`), siembra en perfiles y en usuarios; interruptor de negativos (grupo `RequiereAdmin`) |
| 3b (diseño) | Disparadores de partes, `sync.fn_GuardaParte`, T-09 en la base (51453), segregación S-02 (51451), anulación con `ANULA_TRANSITO` (51455), sesiones y escaneos, idempotencia, `DENY` a `gpos_app`, pantallas sin costos |

---

## 2. Tabla resumen de hallazgos

### T1 construido (con T2 y T4 del servidor ya en la rama)

| Id | Severidad | Título |
|---|---|---|
| SEG-T1-01 | **Media** | La fecha de vencimiento registrada llega a quien recibe (`lotes-disponibles` con «Entradas» y la orden de compra precargada), contra el punto 7 de la precisión de las pantallas del lote (D-10) |
| SEG-T1-02 | **Media** | Quien levanta una revisión de lote puede resolverla él mismo, y «Corregir el vencimiento» puede volver vendible un lote vencido |
| SEG-T1-03 | **Media** | Con un documento retrofechado (factura o conduce) se vende o despacha un lote que ya venció hoy |
| SEG-T1-04 | Baja | `AplicarExistenciaLote` no comprueba que el lote sea del artículo (sin FK compuesta) |
| SEG-T1-05 | Baja | La vista previa de la importación de existencias dice si el vencimiento coincide, sin levantar revisión ni dejar rastro |
| SEG-T1-06 | Baja | El `Down` de `NegativosTresNiveles` vuelve a permitir negativos sin escribir una línea de bitácora |
| SEG-T1-07 | Baja [S] | La factura desde un conduce de un artículo con lote no lleva `LoteId` en `VentaLinea` y el disparador 51307 la rechaza. Falla cerrada; es funcional (pasa a QA) |

### 3b, tramo 1 (diseño)

| Id | Severidad | Título |
|---|---|---|
| SEG-3B-01 | **Media** | La segregación S-02 solo se comprueba en la base al confirmar: el despachador puede abrir la sesión, unirse y contar (escanear) |
| SEG-3B-02 | **Media** | Anulación: el despachador decide si hace falta supervisor (no confirma la salida) y además puede autorizarse a sí mismo (`OfrecerPropio`) |
| SEG-3B-03 | **Media** | Las redes de la base (T-09 51453, `ANULA_TRANSITO` 51455, fecha 51452 y todas las reglas de las partes) se saltan con la marca de sesión `gpos.incorporacion` o `gpos.reaplicacion`, que cualquier sesión de `gpos_app` puede fijar |
| SEG-3B-04 | Baja | CR-01: confirmar la salida, abrir la sesión y escanear no comprueban el candado en la base (solo `FueraDeSitio`) |
| SEG-3B-05 | Baja | El despacho de un lote vencido con motivo (D3) choca con `ExigeLoteVigente` de T1: hay riesgo de que se resuelva con un rodeo (`Revaluar`) |
| SEG-3B-06 | Baja | La UX traduce `FUNCION_INCOMPATIBLE` como 51456 (en el DDL, 51456 es `SESION_NO_PURGABLE` y 51451 es la segregación) |
| SEG-3B-07 | Baja | La idempotencia del despacho no se ve en el DDL: debe usar `doc.Documento.Uid` con su huella |

No hay hallazgos Críticos ni Altos.

---

## 3. Checklist OWASP (Top 10 2021)

| # | Categoría | Resultado |
|---|---|---|
| A01 | Control de acceso | Con hallazgos: SEG-T1-01, SEG-T1-02, SEG-3B-01 y SEG-3B-02. Verificado: `revisiones-lote` exige el privilegio en el grupo y en el servicio; Parámetros es `RequiereAdmin` |
| A02 | Fallas criptográficas | No aplica (no hay criptografía nueva) |
| A03 | Inyección | Sin hallazgo: todo el SQL está parametrizado (Dapper, `Sql.Varchar` con largo, `OPENJSON` tipado). Las variantes `Estricta` se arman con `Replace` sobre constantes, sin datos del usuario |
| A04 | Diseño inseguro | Con hallazgos: SEG-T1-03, SEG-3B-02, SEG-3B-03 y SEG-3B-05 |
| A05 | Configuración | SEG-T1-06 (reversión). Lo de fábrica pasa a «prohibir» (ADR-118, cláusula 8) [V] |
| A06 | Componentes vulnerables | No aplica: no hay paquetes nuevos en los diffs |
| A07 | Autenticación | No aplica: sin cambios |
| A08 | Integridad de datos | Con hallazgos: SEG-T1-04 (defensa en profundidad) y SEG-3B-03. Verificado: partes de solo inserción, `DENY UPDATE/DELETE` a `gpos_app` |
| A09 | Registro y monitoreo | SEG-T1-05 y SEG-T1-06. Verificado: el motivo al permitir negativos y la resolución de la revisión quedan en la bitácora dentro de la transacción |
| A10 | SSRF | No aplica |
| — | Aislamiento entre empresas | No aplica a lo nuevo: base por empresa y sin columnas de empresa. Entre sucursales: guarda de sitio de la 3b (SEG-3B-04) |

---

## 4. Hallazgos

### 4.1 T1 construido

#### SEG-T1-01 · Media · La fecha registrada llega a quien recibe (D-10)

- **Riesgo.** La regla firmada dice: «Quien recibe nunca ve ni recibe precargada la fecha registrada de un lote existente» (ADR-119, precisión de las pantallas, punto 7, último guion). La captura ciega existe para detectar mercancía equivocada o un vencimiento mal rotulado. Si el receptor conoce la fecha registrada, puede copiarla y la bandera de revisión no se levanta nunca.
- **Evidencia [V].**
  - `src/GPOS.Api/Endpoints/InventarioEndpoints.cs:46-48`: `lotes-disponibles` admite `Permisos.Entradas` (y `Ajustes`, que también cubre el ajuste de entrada).
  - `src/GPOS.Core/Consultas/Inventario/ConsultasLotes.cs:29-36` y `src/GPOS.Core/Servicios/LotesService.cs:22-31`: la respuesta trae el `Vencimiento` de cada lote con existencia. Además, el parámetro `fecha` con la marca `Vencido` permite deducir la fecha aunque se quitara ese campo.
  - `src/GPOS.Core/Consultas/Compras/ConsultasCompras.cs:44` y `src/GPOS.Core/Servicios/DocumentosComercialesService.Compras.cs:109`: al cargar una orden de compra para facturarla, cada línea con un lote existente trae `VencimientoLote` (la fecha registrada) precargado en la factura de compra. Una orden puede enlazar un lote existente sin fecha (`Compras.cs`, rama `crear = false`).
  - La prueba `LoteContratoApiTests.N4_28` solo comprueba el cuerpo del 422; `N4_29` comprueba que el cajero ve la fecha, pero no excluye al receptor.
- **Remediación (unas 0,05 sp).**
  1. Quitar `Entradas` de `lotes-disponibles`. Con `Ajustes`, devolver la fecha solo en las salidas (por ejemplo, otro endpoint o un parámetro de modo que el servidor no conceda a quien solo tiene `Entradas`/`FacturasCompra`). Las entradas usan `lotes/existe`, que ya cumple D-10.
  2. En `LineasCompra`, devolver `VencimientoLote` solo en la consulta de una factura ya guardada. Al cargar una orden o solicitud para facturarla, no precargarlo.
  3. Agregar una prueba: un usuario con solo `Entradas` no obtiene ninguna fecha registrada por ningún endpoint.

#### SEG-T1-02 · Media · Autorresolución de la revisión y lote vencido que vuelve a venderse

- **Riesgo.** La misma persona puede recibir un lote existente con otra fecha (lo que levanta la revisión) y después resolverla con «Corregir el vencimiento del lote». Eso cambia la fecha de **todas** las unidades del lote, en todos los almacenes. Si el lote estaba vencido, vuelve a venderse, y la cláusula 5 de ADR-119 («el núcleo rechaza venderlo») queda sin efecto. La bitácora lo registra, pero no lo impide.
- **Evidencia [V].**
  - `src/GPOS.Core/Consultas/Inventario/ConsultasLotes.cs:114-122`: `Resolver` actualiza `inv.Lote.FechaVencimiento` sin ninguna condición sobre quién levantó la revisión ni sobre si el lote está vencido.
  - `src/GPOS.Core/Servicios/LotesService.cs:86-126`: solo exige el privilegio, el motivo de 10 caracteres y la versión. No compara `r.Usuario` con `sesion.Usuario`.
  - `src/GPOS.Core/Sistema/PermisosService.cs:368`: el perfil de almacén sembrado reúne `Entradas`, `Ajustes` y `RevisionLotes`. La siembra aditiva le da el privilegio a todo el que tenga «Ajustes» (firmado, UX-118-08).
- **Remediación (unas 0,05 sp).**
  - En `Resolver`, rechazar con 403 `FUNCION_INCOMPATIBLE` si `inv.RevisionLote.Usuario` = usuario de la sesión. Es la misma lógica de segregación que ADR-106.
  - Con la resolución V, si el lote está vencido hoy y la fecha nueva lo deja vigente, exigir la autorización de un supervisor (ADR-68) o el nivel ADMIN.
  - En la bitácora, agregar «antes vencido: sí/no».
  - Como lo firmado no fija la segregación aquí, va como **decisión candidata** (precisión de UX-118-06/08).

#### SEG-T1-03 · Media · Lote vencido vendido con un documento retrofechado

- **Riesgo.** La regla del lote vencido se mide contra la fecha del documento, no contra hoy. Una factura de venta o un conduce con fecha anterior (dentro del tope de días) deja salir hoy, físicamente, producto que ya venció. En farmacia es un riesgo para la salud del cliente.
- **Evidencia [V].**
  - Servicio: `src/GPOS.Core/Servicios/DocumentosComercialesService.Ventas.cs:391` y `src/GPOS.Core/Servicios/InventarioService.cs:347` pasan `doc.Fecha`.
  - Núcleo: `src/GPOS.Core/Servicios/Modulos/Inventario/LibroInventario.cs:355` usa `fecha.Date` del kárdex.
  - Disparador 51308: `src/GPOS.Core/Datos/Empresa/Migraciones/SqlMigracionesOla3EmisionLigera.cs:369-374` compara con `e.Fecha`.
  - La prueba `tests/GPOS.Tests/ModeloNg/NegativosNucleoTests.cs:268` fija este comportamiento como esperado.
  - Mitigaciones existentes: la retrofecha exige el privilegio `FechaAnterior`, el tope `TopeDiasAnteriores`, un motivo y la bitácora (`src/GPOS.Core/Servicios/Nucleo/FechasDocumento.cs:33-60`). El POS usa `HoraEmpresa.Hoy` (`PosService.cs:244`).
- **Remediación (unas 0,02 sp).** Medir el vencimiento en la salida contra `max(fecha del documento, hoy de la empresa)`, en las tres capas (servicio, `GruposLote` y 51308). Así la regla deja de depender de quién tiene el privilegio de retrofecha. Va como **decisión candidata** (precisión de PQ-2: «el que vence hoy todavía sale» se conserva).

#### SEG-T1-04 · Baja · El lote no se ata al artículo en el comando

- **Riesgo.** Si alguna vez llega una llave de lote de otro artículo (por un defecto de quien llama), el comando usa el vencimiento y la política de ese otro artículo y crea filas incoherentes. Hoy no es explotable: todos los caminos resuelven el lote por (artículo, código).
- **Evidencia [V].** `src/GPOS.Core/Consultas/Inventario/ConsultasInventario.cs:52-59` (`WHERE l.Id = @lote`, sin `l.ArticuloId = @articulo`). FK simples: `src/GPOS.Core/Datos/Empresa/Configuracion/InvConfiguracion.cs:130`, `:187`.
- **Remediación.** Agregar `AND l.ArticuloId = @articulo` y, si no hay fila, no aplicar (faltante). Como red adicional, un `CHECK` o un disparador de coherencia en el kárdex. Unas 0,01 sp.

#### SEG-T1-05 · Baja · La vista previa de la importación revela la coincidencia de la fecha

- **Riesgo.** Al validar sin guardar, la fila con otro vencimiento da el error «ya está registrado con otra fecha», pero no se levanta revisión (`c.Guardar`). Repitiendo la validación se deduce la fecha registrada sin dejar rastro. Requiere el privilegio de importación.
- **Evidencia [V].** `src/GPOS.Core/Servicios/Importacion/ImportacionExistencias.cs:128` (mensaje) y `:207` (solo con `Guardar`).
- **Remediación.** Registrar en la bitácora cada validación con lotes existentes, o devolver en la vista previa un aviso neutro («lote existente: el vencimiento se compara al importar»).

#### SEG-T1-06 · Baja · `Down` sin bitácora

- **Evidencia [V].** `src/GPOS.Core/Datos/Empresa/Migraciones/SqlMigracionesNegativos.cs:331-339`: restituye `PermiteExistenciaNegativa = 1` sin insertar una línea en `audit.Bitacora`. El `Up` sí la escribe (`:303-309`).
- **Remediación.** Insertar una línea `MIGRACION`/`Revertir` con el antes y el después en el mismo `Down`.

#### SEG-T1-07 · Baja [S] · Factura desde conduce con artículos con lote

- **Evidencia.**
  - `src/GPOS.Core/Servicios/DocumentosComercialesService.Ventas.cs:387-391`: devuelve `null` si hay `ConduceId`, y la línea de venta queda sin `LoteId`.
  - El disparador lanza 51307 para `FAC` con `ControlLote = 1` y `LoteId IS NULL` (`SqlMigracionesOla3EmisionLigera.cs:67`, `:119-120`).
  - Falla cerrada: no abre ningún camino. Es un defecto funcional.
- **Remediación.** Copiar el lote de la salida del conduce a la línea de la factura. Entrega a QA para confirmarlo con una prueba.

### 4.2 Diseño de la 3b, tramo 1

#### SEG-3B-01 · Media · La segregación solo se comprueba en la base al confirmar

- **Riesgo.** S-02 busca que quien despachó no cuente lo que llega. En la base solo se compara `doc.Documento.CreadoPor` con `TransferenciaRecepcion.RegistradoPor` al confirmar. El despachador puede abrir la sesión, unirse o escanear (conteo ciego hecho por quien sabe lo que mandó), y que otro solo confirme. La [UX] dice que el servicio responde 403 también al abrir y al unirse (`[UX]:462`), pero esa capa no tiene red en la base y nada cubre el escaneo.
- **Evidencia [V].**
  - `[DDL]:806-808` (única comprobación de 51451).
  - `[DDL]:751-771` (sesión: sin S-02).
  - `[DDL]:773-784` (escaneo: sin S-02).
  - `RegistradoPor` es una columna que escribe la aplicación. No sale de `SESSION_CONTEXT`, así que la red se apoya en un valor que manda quien inserta.
- **Remediación (unas 0,05 sp).**
  - Agregar 51451 en `TR_SesionRecepcion_Reglas` (`AbiertaPor`) y en `TR_SesionRecepcionEscaneo_Reglas` (`Usuario`), en modo E.
  - Tomar el usuario de la marca de sesión de la API, no de la columna.
  - Agregar a PB-3b-09: «el despachador no abre, no se une y no escanea».

#### SEG-3B-02 · Media · Anulación sin supervisor efectivo

- **Riesgo.** El supervisor solo se exige si `SalidaConfirmadaEn` no es nulo (`[DDL]:977-980`), y la salida la confirma el propio despachador. Escenario de fraude: la mercancía sale con el conduce impreso, la salida no se confirma en el sistema y después se anula. El origen recupera existencia que ya no está y el faltante solo aparece en el conteo físico.
- Además, con salida confirmada, la [UX] prevé que quien tenga `transfdespacho` Autorizar se autorice a sí mismo (`[UX]:548`, `OfrecerPropio`). El trigger solo comprueba que exista una fila `ANULA_TRANSITO`, sin mirar quién autorizó.
- El control compensatorio de autoautorizaciones de ADR-106 llega con la ola 5: en el tramo 1 no hay control detectivo.
- **Remediación (unas 0,05 sp).**
  - Exigir `ANULA_TRANSITO` si existe `CONDUCE_IMPRESO` en la bitácora o si la TI tiene más de N horas, aunque la salida no se haya confirmado.
  - En 51455, exigir `z.AutorizadoPor <> x.CreadoPor` y que sea distinto de quien anula.
  - Hasta la ola 5, listar las anulaciones de TI con conduce impreso en el historial y en los indicadores.
  - Va como **decisión candidata** (precisión de ADR-106 o de [TRF] 2.5).

#### SEG-3B-03 · Media · Las marcas de sesión saltan las redes de la base

- **Riesgo.**
  - `@inc = 1` (cuando existe `SESSION_CONTEXT('gpos.incorporacion')`) omite la fecha (51452), T-09 (51453) y el supervisor de la anulación (51455): `[DDL]:905-906`, `:919`, `:952`, `:977`.
  - `Reaplicando` omite todas las reglas de la cabecera y de la recepción: `[DDL]:705`, `:792`, con la definición en `:541-558`.
  - `sp_set_session_context` lo puede ejecutar cualquier sesión del login de la aplicación. En la entrega 1 nadie incorpora mensajes de otro sitio. Basta un defecto o una inyección para convertir la marca en una llave maestra.
  - Es un patrón heredado (`SqlMigracionesOla3EmisionLigera.cs:166`, `:288`), pero aquí protege reglas de dinero e inventario.
- **Remediación (unas 0,05 sp).**
  - En los disparadores de la 3b de la entrega 1, no aceptar `gpos.incorporacion`.
  - En la entrega 2, exigir además un principal dedicado (por ejemplo, `IS_ROLEMEMBER('gpos_sync') = 1` o un procedimiento firmado) y fijar la marca con `@read_only = 1`.
  - No dejar nunca que la marca salte 51455.
  - Entrega a arquitecto-datos.

#### SEG-3B-04 · Baja · CR-01 incompleto en la base

- **Evidencia [V].** `TR_Transferencia_Reglas` (UPDATE de la confirmación de salida), `TR_SesionRecepcion_Reglas` y el escaneo solo comprueban `FueraDeSitio`, no `Bloqueada`: `[DDL]:700-724`, `:751-784`. La recepción sí comprueba `Bloqueada` (`:793-794`), y la TI la cubre 51403 sobre `doc.Documento` (`[DDLm]` §6).
- La cláusula 9 de ADR-53 dice «ninguna operación de escritura de negocio». La API bloquea las rutas sin `PermitidaConCandado`, así que la red de la base es parcial.
- **Remediación.** Agregar `g.Bloqueada = 1 → 51330` en la cabecera (UPDATE), en la sesión y en el escaneo.

#### SEG-3B-05 · Baja · Lote vencido en el despacho frente a T1

- **Evidencia [V].**
  - `LibroInventario.cs:364-366`: `ExigeLoteVigente` exige un lote vigente en toda salida que no sea ajuste, conteo, reverso ni `Revaluar`, y la clase 6 «Traslado» entra.
  - `[PLAN]:23` y `:118`, y `[UX]:186`, `:296-306`: el despacho admite un lote vencido con motivo (D3).
  - Tal como está, el núcleo rechazaría ese despacho. El rodeo fácil (marcarlo `Revaluar`) también cambia el costo y debilita el control.
- **Remediación.** Una marca explícita en `MovimientoNuevo` (por ejemplo, `AdmiteVencido`), que solo ponga el despacho cuando la línea traiga `MotivoLoteVencido`. Con una prueba que confirme que la venta y el conduce siguen rechazando.

#### SEG-3B-06 · Baja · Código del motor mal citado

- **Evidencia.** `[UX]:462` («403 (51456)») frente a `[DDL]:22-23` (51451 `FUNCION_INCOMPATIBLE`; 51456 `SESION_NO_PURGABLE`). Un mapeo erróneo en `ErroresNumeracion` mostraría un 500 en lugar del 403.
- **Remediación.** Corregir la [UX] y probar el mapeo de 51440 a 51457.

#### SEG-3B-07 · Baja · Idempotencia del despacho

- **Evidencia.** El DDL no agrega una clave de idempotencia a `inv.Transferencia` (`[DDL]:141-165`). La [UX] reenvía la `ClaveIdempotencia` (`[UX]:372`). El mecanismo duradero existe (`doc.Documento.Uid` y su huella, `src/GPOS.Core/Dominio/Numeracion/Documentos.cs:65`, `:86`, en `feature/modelo-ng`).
- **Remediación.** Que T2 de la 3b mapee la clave a `Uid` en `BorradorSinNumeroAsync`, y una prueba de reintento con resultado desconocido (0 TI duplicadas y 0 doble descuento).

---

## 5. Controles bien implementados (verificados, sin hallazgo)

**T1 y servidor de T2/T4**
- La política se resuelve dentro de los dos comandos de existencia. Sin fila de política se prohíbe (`@permite = 0`). Lote o serie, siempre 0; lote con vencimiento, siempre 0 (`ConsultasInventario.cs:21`; `SqlMigracionesNegativos.cs:264-277`).
- El lote rechaza: `UPDATE` condicional con `UPDLOCK, SERIALIZABLE` y sin `INSERT` negativo para los artículos con lote.
- Orden «saldos»: primero la existencia del almacén y después la del lote, cada una en orden de llave, también al repartir en varios lotes (`LibroInventario.cs`, `ExistenciasEnLote.Comandos`). No hay bloqueos nuevos y la política se lee con versiones (RCSI inferido de C-4).
- La red del lote vencido está en el núcleo: relee `inv.Lote` dentro de la transacción, así que una resolución V concurrente no se salta.
- Ningún camino de salida queda sin cubrir:
  - POS rápido: `PosService.cs:244`, con `HoraEmpresa.Hoy`.
  - Factura sin conduce, conduce, ajuste, merma y devolución a suplidor.
  - Reversos: con la política, sin la regla del vencimiento.
  - Importación: fila sin lote = error.
  - Disparadores 51307 y 51308 en la emisión.
  - Devolución: usa siempre el lote de origen (`PosService.cs:877`).
- `SalidaEstricta`: la sustitución por `Replace` está cubierta por una prueba (`NegativosNucleoTests.cs:283-284`).
- P-12: la prueba de arquitectura impide escribir las existencias fuera de los dos comandos (`tests/GPOS.Tests/Arquitectura/EscrituraExistenciaTests.cs`).
- Interruptor de negativos: solo ADMIN o SUPER (`AdminEndpoints.cs:15`, `RequiereAdmin`). Pasar a permitir exige motivo, con una línea de bitácora propia en la misma transacción (`AdministracionService.cs`). Ningún texto sugiere cambiar la política ni «No generar comprobante» (`LibroInventario.MensajeSalida`).
- Bandera de revisión:
  - el 422 `LOTE_VENCIMIENTO_DISTINTO` y `lotes/existe` no revelan la fecha (prueba `N4_28`);
  - se levanta en una transacción aparte, única por (lote, fecha indicada), sin entrar en el orden único;
  - la carrera entre la validación y la transacción se cubre en `LotesDocumento.EntradaAsync`.
- Retiro de `LoteVencido = 'A'` con bitácora y `CHECK = 'B'`. `CK_Lote_Vencimiento` WITH NOCHECK no inventa fechas (punto 8).
- SQL parametrizado con `varchar` y largo (ADR-50).

**3b (diseño)**
- Partes de solo inserción, con `DENY UPDATE/DELETE` a `gpos_app` y una prueba con 229 (`[DDL]:1081-1096`).
- T-09 en dos capas: `SalidaEstricta` más 51453, con la salvedad de SEG-3B-03.
- Guarda de sitio que falla cerrada sin `sync.EstadoNodo`.
- Idempotencia de la recepción: `UQ_Recepcion_Sesion` sobrevive a la purga (sin FK), escaneos con PK `(SesionId, EscaneoId)`, sesión con `UPDLOCK` al confirmar y cola local en el cliente.
- El despacho no muestra costos (DT-01; `ArticuloLinea.Linea.Costo` es `[DatoCosto]`). El detalle los muestra solo con `VerCostos`. `rptc.TransitoArticulo` solo para la API.
- Orden de bloqueos sin ciclos aparentes (`[DDLm]` §2), con la existencia del origen y la del destino en una sola pasada en el modo S.

---

## 6. Remediaciones priorizadas

1. **Antes de unir T1/T2/T4 (27-oct):** SEG-T1-01 (quitar `Entradas` de `lotes-disponibles` y no precargar la fecha de la orden) y SEG-T1-02 (no resolver la revisión propia). En total, unas 0,1 sp.
2. **Decisión del propietario:** SEG-T1-03 (vencimiento contra `max(fecha, hoy)`) y SEG-3B-02 (supervisor por conduce impreso y sin autoautorización).
3. **DDL v3 antes del 15-oct:** SEG-3B-01, SEG-3B-03, SEG-3B-04 y SEG-3B-06.
4. **En construcción:** SEG-3B-05 y SEG-3B-07 (3b); SEG-T1-04, 05 y 06 (T1).
5. **QA:** SEG-T1-07.

---

## 7. Recomendación

- **T1 (con T2 y T4 del servidor, HEAD `106fa26`): Aprobado con observaciones.** No hay hallazgos Críticos ni Altos. Recomiendo corregir SEG-T1-01 y SEG-T1-02 antes de la unión del 27-oct, porque la primera contradice una regla firmada (D-10).
- **3b, tramo 1:** es diseño, sin dictamen de publicación. Hay que incorporar SEG-3B-01 a 04 al DDL v3 y llevar SEG-3B-02 al propietario.
- Es una recomendación técnica: la decisión es del propietario.

### Cierre
- Estado: Aprobado con observaciones (T1); 3b, diseño revisado.
- Artefactos: `C:\Users\lfmen\AppData\Local\Temp\claude\C--Users-lfmen-source-repos-Solucion-GPOS-NG-GPOS-NG\2ab4d64a-60e5-4721-9bba-4b93894990d8\scratchpad\auditoria-t1-y-diseno-3b.md`
- Supuestos:
  - las bases tienen RCSI activo (C-4), por eso la política se lee sin bloqueo;
  - `RequierePermiso` en un grupo exige el privilegio sin distinguir acción;
  - no ejecuté pruebas: SEG-T1-07 es sospecha.
- Decisiones candidatas a ADR:
  - vencimiento en la salida contra `max(fecha del documento, hoy)` (precisión de PQ-2 de ADR-119);
  - segregación en la resolución de revisiones de lote (precisión de UX-118-06/08);
  - supervisor obligatorio en la anulación de una TI con conduce impreso y sin autoautorización (precisión de ADR-106 o de [TRF] 2.5);
  - marcas de sesión solo para un principal dedicado (precisión de ADR-53, cláusula 2).
- Entregas a otros agentes:
  - backend S (B) → SEG-T1-01, 02, 04, 05 y 06;
  - arquitecto-datos (3b) → SEG-3B-01, 03, 04 y 05;
  - disenador-ux-ui → SEG-3B-06 y retirar `OfrecerPropio` de la anulación en tránsito;
  - arquitecto-software (B) → SEG-3B-07 y la marca `AdmiteVencido`;
  - qa-automatizado → SEG-T1-07, la prueba «solo Entradas no ve fechas» y PB-3b-09 ampliada;
  - Arquitecto Maestro → las cuatro decisiones candidatas.
- Próximo paso recomendado: corregir SEG-T1-01 y 02 en `b/adr118-119-t1` antes del 27-oct y llevar SEG-T1-03 y SEG-3B-02 a la hoja de firma.
