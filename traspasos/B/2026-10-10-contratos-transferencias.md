# Contratos HTTP congelados: transferencias de la ola 3b, tramo 1 (F10)

[Blueprint Técnico · contratos de la API interna] · Arquitecto de software, equipo B · 2026-10-10 · **Solo lectura**: no edité repositorios, no compilé.

- **Estado del contrato:** `Congelado v1` para el tramo 1. Los cambios posteriores son **aditivos** (campo nuevo opcional o código nuevo); quitar o renombrar exige versión 2 y aviso a frontend y backend.
- **Árboles leídos:** `GPOS-B-modelo-ng` (`feature/modelo-ng` `ec459d5`); `GPOS-B-ola3b` (`b/ola3b` `ec459d5`, árbol limpio, **sin commits propios**); `GPOS-B-adr118` (`b/adr118-119-t1` `d2e28ec`, para `FaltanteExistenciaDto` y `CodigosInventario`). En `master`: ADR-100 a 107 (precisiones del 2026-10-10, UX-TI-01 a 07 y P-D1). Área común: diseño UX `traspasos/B/2026-10-10-ux-transferencias.md` [UXT], plan `traspasos/B/2026-10-10-plan-ola3b.md` [PLAN], DDL v3 `traspasos/B/2026-10-10-ola3b-ddl-corregido.md` y `ola3b-ddl/ola3b-ddl-corregido.sql` [DDL], blueprint del candado de A `traspasos/A/blueprint-h11-p7-candado-2026-10-10.md` [CR01]. Blueprint de la 3b del 2026-10-07 [SW3B] (`docs/arquitectura/2026-10-07-ola3b-blueprint.md` en la rama).
- **Convención:** [V] = verificado hoy en el código o el documento citado; [I] = inferido o decidido aquí.

---

## 1. Reglas comunes

| Regla | Contrato | Evidencia |
|---|---|---|
| Grupo | `/api/transferencias`, `RequireAuthorization()`, `.Sitio(OperacionSitio.Libre)`, `WithTags("Transferencias")`, en `TransferenciasEndpoints.MapTransferencias()` | [SW3B] 5.1; patrón de `DocumentosEndpoints.cs:11` (catálogos `Libre`) [V] |
| Archivos de contrato | `src/GPOS.Contracts/Inventario/Transferencias.cs` (DTO) y `src/GPOS.Contracts/Inventario/CodigosTransferencia.cs` (códigos y estados), `namespace GPOS.Contracts` | Patrón de `Inventario/Inventario.cs` y `Documentos/CodigosConflicto.cs` [V] |
| JSON | `System.Text.Json` con `JsonSerializerDefaults.Web`: propiedades en **camelCase** (`AlmacenOrigen` → `almacenOrigen`). Los enumerados viajan como **texto** (`string`, constantes en `CodigosTransferencia`), nunca `char` ni `enum` numérico | `GPOS.Web/Servicios/ApiClient.cs:74` [V] |
| Errores | `ProblemDetails` (`application/problem+json`) con `extensions.codigo`. Extensiones de detalle ya vigentes: `renglones` (base 1, lista del cliente), `articulos`/`articulo` y las de `Datos` (`faltantes`). **La pantalla decide por `codigo`, nunca por el número del motor ni por el texto** | `Program.cs` (`ManejarErrorAsync`) en `feature/modelo-ng` y su extensión de T1 en `b/adr118-119-t1` (`renglones`, `Datos`) [V] |
| Defensa doble | Permiso en la ruta (`RequierePermiso` / `RequiereAlgunPermiso`, solo la opción) y nivel y acción en el servicio (`sesion.Exigir…`) | `Seguridad.cs:213-217` [V]; [SW3B] 5.1 |
| Guarda de sitio | `IDuenoSucursal.ExigirDuenoLocalAsync` al inicio de cada comando, dentro de la transacción, tras el bloqueo de documento. En la entrega 1 nunca rechaza | ADR-103 [V] |
| Texto hacia la base | `varchar` con el largo de la columna (ADR-50), consultas con `[ConsultaRegistrada]` (CP-169) | CLAUDE.md [V] |
| Fechas | El cliente nunca manda fecha de una parte: el servidor usa el «hoy de la empresa» (51452 es la red). Las fechas de respuesta son **hora local de la empresa** sin zona (`DateTime`, como el resto de `Contracts`) | [DDL] 51452 [V] |
| Versión | `Version` = base64 del `rowversion` de `inv.Transferencia`, opaca; si no coincide, 409 `REGISTRO_MODIFICADO` | `CodigosConflicto.RegistroModificado` [V] |
| Costos | Los campos de valor llevan `[DatoCosto]` (el filtro los anula sin `VerCostos`). El despacho, la recepción, la lista y el historial **no** llevan costos; solo el detalle (T-03) | `FiltroCostos` [V]; DT-01 de [UXT] |
| Número | `{n}` = número visible de la TI (`TI` + código de la sucursal de origen + dígitos, por ejemplo `TIA0000123`), sin espacios, mayúsculas | [PLAN] 3, serie `TI` por sucursal de origen |

---

## 2. Rutas, métodos, permisos y candado

Permisos (nuevos en `Permisos.cs`, [SW3B] 8.1): `transfdespacho` (D: nivel Agregar; acciones Anular y Autorizar), `transfrecepcion` (R: Agregar; Autorizar), `transfreconciliacion` (RC: Agregar; Autorizar). ADMIN y SUPER los tienen por nivel, **sujetos a la segregación** (ADR-106).

**Candado de restauración (CR-01):** ninguna ruta de transferencias lleva `PermitidaConCandado` ni `SoloConsulta` ([DDL] 6, entrega al arquitecto-software [V]). Con el candado de empresa activo, toda escritura responde **503 `BASE_RESTAURADA`** (middleware de A) y, mientras ese middleware no esté unido, **503 `EMISION_BLOQUEADA_RECONCILIAR`** (51330 de los disparadores y de `sync.fn_GuardaParte`). La pantalla trata los dos igual. El `GET` del conduce es un **«GET con efecto»** (registra `CONDUCE_IMPRESO`) y debe entrar en la tabla aparte de PF-36 ([CR01] 5.4, PC-4: imprimir se permite con candado).

| # | Método y ruta | Entrada → salida (éxito) | Permiso (ruta → servicio) | Dueño del sitio (ADR-103) | Candado |
|---|---|---|---|---|---|
| T-00 | `GET /api/transferencias/almacenes` | → `AlmacenesTransferenciaDto` (C-1) | D → Agregar | — (lectura) | GET: pasa |
| T-01 | `GET /api/transferencias?rol=&estado=&desde=&hasta=&texto=&pagina=&tamano=` | → `PaginaTransferenciasDto` | D, R o RC → Consultar | — | GET: pasa |
| T-02 | `GET /api/transferencias/por-recibir?soloContador=` | → `PorRecibirDto` | R → Consultar | — | GET: pasa |
| T-03 | `GET /api/transferencias/{n}` | → `TransferenciaDto` | D, R o RC → Consultar | — | GET: pasa |
| T-04 | `GET /api/transferencias/{n}/historial` | → `HistorialTransferenciaDto` | D, R o RC → Consultar | — | GET: pasa |
| T-05 | `POST /api/transferencias` | `DespachoRequest` → **201** `TransferenciaDto` + `Location: /api/transferencias/{n}`; repetida: **200** con `repetida = true` | D → Agregar | Sucursal de origen | Sin marca → 503 |
| T-06 | `POST /api/transferencias/{n}/salida` | `ConfirmarSalidaRequest` → 200 `TransferenciaDto` | D → Agregar | Sucursal de origen | Sin marca → 503 |
| T-07 | `POST /api/transferencias/{n}/anular` | `AnularTransferenciaRequest` → **204** | D → Anular (+ supervisor con D Autorizar si la salida está confirmada) | Sucursal de origen (dueño actual) | Sin marca → 503 |
| T-08 | `POST /api/transferencias/{n}/sesiones` | (sin cuerpo) → **201** `SesionRecepcionDto` (sesión nueva) o **200** (se unió a la abierta) | R → Agregar | Destino vigente | Sin marca → 503 |
| T-09 | `GET /api/transferencias/sesiones/{sid}?lecturas=` | → `SesionRecepcionDto` | R → Consultar | — | GET: pasa |
| T-10 | `POST /api/transferencias/sesiones/{sid}/escaneos` | `EscaneosRequest` → 200 `EscaneosRespuestaDto` (C-7) | R → Agregar | Destino vigente | Sin marca → 503 |
| T-11 | `DELETE /api/transferencias/sesiones/{sid}/escaneos/{eid}` | → **204** (también si ya no existe) | R → Agregar (propia) / Autorizar (ajena) | Destino vigente | Sin marca → 503 |
| T-12 | `POST /api/transferencias/sesiones/{sid}/terminar` | (sin cuerpo) → 200 `ComparacionRecepcionDto` (C-9) | R → Agregar | Destino vigente | Sin marca → 503 (escribe `TerminadaEn`; **no** es `SoloConsulta`) |
| T-13 | `POST /api/transferencias/sesiones/{sid}/confirmar` | `ConfirmarRecepcionRequest` → **201** `RecepcionDto`; repetida: **200** con `repetida = true` | R → Agregar | Destino vigente | Sin marca → 503 |
| T-14 | `POST /api/transferencias/sesiones/{sid}/descartar` | (sin cuerpo) → **204** (también si ya estaba descartada) | R → Agregar | Destino vigente | Sin marca → 503 |
| T-21 | `GET /api/transferencias/{n}/conduce?reintento=` | → `application/pdf` (carta) | D o RC → Consultar | — | **GET con efecto** (tabla de PF-36) |

Límites: T-10 con una política nueva `LimitesPeticiones.Escaneos` **por usuario, 240 peticiones por minuto** (tandas de ≥ 400 ms = 150 por minuto como máximo, más reintentos) y `LimiteCuerpo(64 KB)` (200 escaneos × ≈ 200 B = 40 KB). El 120 por minuto de [SW3B] T-10 se queda corto con tandas cada 400 ms [I]. T-05 sin límite propio (2.000 líneas ≈ 0,5 a 1 MB, dentro del tope de Kestrel) [I].

**Visibilidad (404 que no distingue):** una TI es visible si la sucursal de la sesión es la de origen o la del destino vigente, o si el usuario tiene RC y la sesión está en `SucursalCentralId`. Si no es visible: 404 `TRANSFERENCIA_NO_ENCONTRADA` ([SW3B] T-03).

---

## 3. DTO (C# exacto y JSON)

Los nombres de propiedad C# son los definitivos. En JSON van en camelCase (primera letra minúscula). Los `record` posicionales siguen el estilo de `ExistenciaDto`; las peticiones son `class` con `{ get; set; }` como `DocumentoInventario` (la interfaz las arma campo a campo).

### 3.1 Catálogo de almacenes para el despacho (C-1)

```csharp
/// <summary>T-00: almacenes elegibles para despachar. Origen = almacenes habilitados de la sucursal de la sesión (S-3b-02 A);
/// destino = todos los almacenes habilitados de sucursales abiertas de la empresa (la interfaz quita el origen elegido).</summary>
public record AlmacenesTransferenciaDto(string SucursalSesion, IReadOnlyList<AlmacenTransferenciaDto> Origenes, IReadOnlyList<AlmacenTransferenciaDto> Destinos);

/// <param name="Sucursal">Código de la sucursal del almacén; si es igual al de la sucursal del origen elegido, el modo es S («Trasladar»); si no, E («Despachar»).</param>
/// <param name="SucursalCerrada">Tramo 2 (P-4): solo en Origenes, con la sesión en la central; en el tramo 1 siempre false.</param>
public record AlmacenTransferenciaDto(string Codigo, string Descripcion, string Sucursal, string SucursalNombre, bool SucursalCerrada = false);
```

JSON: `{"sucursalSesion":"01","origenes":[{"codigo":"ALM01","descripcion":"Principal","sucursal":"01","sucursalNombre":"Principal","sucursalCerrada":false}],"destinos":[…]}`

**Filtros (C-1):**
- `Origenes`: `org.Almacen` habilitado y no cerrado, de la sucursal del token; sucursal abierta. Tramo 2 (P-4 firmada): con la sesión en `SucursalCentralId`, también los almacenes habilitados de sucursales **cerradas** (`SucursalCerrada = true`).
- `Destinos`: todos los almacenes habilitados de **sucursales abiertas** de la empresa, incluidos los de la sucursal de la sesión (modo S). Orden: sucursal, código. Un almacén de sucursal cerrada nunca es destino.
- Sin almacenes de origen: lista vacía (la pantalla muestra «Su sucursal no tiene almacenes habilitados para despachar.»).

**Decisión: ruta propia en lugar de los alcances de `/api/catalogos` que pide C-1.** Motivo: `ItemCatalogo` solo tiene `Detalle` libre (`Catalogo.cs:11` [V]); el modo E/S y la agrupación por sucursal dependerían de analizar ese texto, y la ruta de catálogos no exige `transfdespacho`. *Alternativa descartada:* alcances `transferencia-origen` y `transferencia-destino` en `AlcancesCatalogo` (más barata en el servidor, ≈ 0,02 sp menos, pero frágil en el cliente). La interfaz alimenta `SelectorCatalogo` convirtiendo cada `AlmacenTransferenciaDto` en `ItemCatalogo(Codigo, Descripcion, $"{Sucursal} {SucursalNombre}")`.

### 3.2 Despacho (T-05)

```csharp
public class DespachoRequest
{
    /// <summary>Clave del intento (la genera el cliente al pulsar «Despachar»; se conserva en los reintentos). Obligatoria en la 3b.</summary>
    public Guid? ClaveIdempotencia { get; set; }
    public string AlmacenOrigen { get; set; } = "";
    public string AlmacenDestino { get; set; } = "";
    public string? Transportista { get; set; }      // ≤ 80
    public string? Vehiculo { get; set; }           // ≤ 30
    public string? Notas { get; set; }              // ≤ 200 (doc.Documento.Notas admite 500)
    /// <summary>Un solo motivo para todos los renglones con lote vencido (D3 de [TRF]); de 10 a 200 caracteres.</summary>
    public string? MotivoLoteVencido { get; set; }
    public List<LineaDespachoDto> Lineas { get; set; } = [];
}

public class LineaDespachoDto
{
    public string Articulo { get; set; } = "";      // código del artículo
    public string Unidad { get; set; } = "";        // obligatoria: una de las del artículo (ADR-78)
    public decimal Cantidad { get; set; }           // en Unidad; > 0; hasta 6 decimales
    public string? Lote { get; set; }               // código del lote existente; obligatorio si el artículo requiere lote
    public List<string>? Series { get; set; }       // obligatoria con número de serie: una por unidad base
}
```

JSON: `{"claveIdempotencia":"5d2c…","almacenOrigen":"ALM01","almacenDestino":"ALM02","transportista":null,"vehiculo":null,"notas":null,"motivoLoteVencido":null,"lineas":[{"articulo":"AMX-500","unidad":"CAJA","cantidad":3,"lote":"L-2406","series":null}]}`

**Validaciones (en este orden; todas las de renglón se acumulan y van juntas en `renglones`):**

| # | Regla | Código | HTTP |
|---|---|---|---|
| 1 | `ClaveIdempotencia` presente | `CLAVE_IDEMPOTENCIA_REQUERIDA` | 422 |
| 2 | Origen: existe, habilitado, de la sucursal de la sesión | `ORIGEN_INVALIDO` | 422 |
| 3 | Destino: existe, habilitado, de sucursal abierta, ≠ origen | `DESTINO_INVALIDO` | 422 |
| 4 | De 1 a 2.000 renglones; largos de texto | 400 (`BadHttpRequest`) o 422 `DESPACHO_INVALIDO` | 422 |
| 5 | Un solo renglón por (artículo, lote) (ver nota) | `RENGLON_DUPLICADO` + `renglones` | 422 |
| 6 | Unidad del artículo; cantidad > 0 | `UNIDAD_REQUERIDA`, `UNIDAD_AJENA` (existentes) + `renglones` | 422 |
| 7 | Lote obligatorio y existente para el artículo (ADR-119) | `LOTE_REQUERIDO`, `LOTE_INEXISTENTE` (de `CodigosInventario`) + `renglones` | 422 |
| 8 | Series completas y «en existencia» en el origen | `SERIES_INCOMPLETAS`; `SERIE_NO_DISPONIBLE` (+ `series`: `[{renglon, serie, transferencia?}]`) | 422 |
| 9 | Lote vencido sin `MotivoLoteVencido` válido | `LOTE_VENCIDO_SIN_MOTIVO` + `renglones` + `lotesVencidos`: `[{renglon, articulo, lote, vencimiento}]` | 422 |
| 10 | Existencia del origen y del lote, **estricta** (T-09, P-2 firmada) | `EXISTENCIA_INSUFICIENTE` + `faltantes` (`FaltanteExistenciaDto`, motivo `T` si la política permitía negativos, C-3) | 422 |
| 11 | Período de inventario abierto | `PERIODO_CERRADO` (51333) | 422 |
| 12 | Idempotencia: misma clave, otro contenido | `IDEMPOTENCIA_CONFLICTO` | 409 |

**Nota de `RENGLON_DUPLICADO` (decisión de contrato [I]):** la recepción cuenta por artículo y lote (`inv.SesionRecepcionEscaneo` no guarda la línea, [DDL] 1.9 [V]); con dos renglones del mismo artículo y lote una lectura sería ambigua. La pantalla ya suma la lectura repetida al último renglón del mismo artículo y lote ([UXT] 3.2); con unidades distintas del mismo artículo y lote, la pantalla los une en la unidad base antes de enviar. *Alternativa descartada:* guardar la línea en el escaneo (cambio de DDL y la lectura del lector no sabe la línea).

Respuesta: `TransferenciaDto` (3.4). Con `SalidaEnUnPaso = 1` nace con `estado = "EN_TRANSITO"` y `salidaConfirmadaEn` llena. En modo S nace `"RECONCILIADO"` con `trasladoInterno = true` y una recepción R1.

### 3.3 Salida y anulación (T-06, T-07)

```csharp
public class ConfirmarSalidaRequest
{
    public string Transportista { get; set; } = "";   // obligatorio (UX-TI-04), 1 a 80
    public string? Vehiculo { get; set; }             // opcional, ≤ 30
    public string Version { get; set; } = "";         // la de TransferenciaDto.Version leída
}

public class AnularTransferenciaRequest
{
    public string Motivo { get; set; } = "";              // texto, 10 a 200
    public string? MotivoAnulacion { get; set; }          // código del maestro de ADR-71; opcional (sin NCF)
    /// <summary>Con la salida confirmada: las dos declaraciones de [TRF] 2.5, obligatorias.</summary>
    public bool MercanciaDeVuelta { get; set; }
    public bool ConduceRecuperado { get; set; }
    /// <summary>Con la salida confirmada: supervisor de la sucursal de origen con transfdespacho Autorizar (ADR-68; tipo ANULA_TRANSITO).</summary>
    public AutorizacionSupervisor? Autorizacion { get; set; }
}
```

JSON T-06: `{"transportista":"J. Pérez","vehiculo":"L123456","version":"AAAAAAAAB9E="}` · T-07: `{"motivo":"Se despachó al almacén equivocado","motivoAnulacion":null,"mercanciaDeVuelta":true,"conduceRecuperado":true,"autorizacion":{"usuario":"SUP1","clave":"<secreto>","motivo":"Error de destino"}}`

| Ruta | Rechazos |
|---|---|
| T-06 | 422 `TRANSPORTISTA_REQUERIDO`; 422 `CONDUCE_NO_IMPRESO`; 409 `SALIDA_YA_CONFIRMADA` (extensiones `salidaConfirmadaPor`, `salidaConfirmadaEn`); 409 `REGISTRO_MODIFICADO`; 409 `TRANSFERENCIA_NO_VIGENTE` (anulada); 409 `TRASLADO_INTERNO` (modo S, no tiene salida) |
| T-07 | 422 `MOTIVO_REQUERIDO`; 422 `MOTIVO_ANULACION_INVALIDO` (existente); 422 `DECLARACION_REQUERIDA`; 422 `SUPERVISOR_REQUERIDO` (salida confirmada sin `Autorizacion`; la pantalla lo pide de entrada, esto es la defensa); 422 `AUTORIZACION_INVALIDA` (existente; también 51455); 409 `TRANSFERENCIA_CON_PARTES` (51442: recepciones o sesión abierta); 409 `TRANSFERENCIA_NO_VIGENTE` (ya anulada: el reintento recarga y ve «Anulada»); 409 `TRASLADO_INTERNO` (el modo S no se anula, [DDL] 2 A4); 422 `PERIODO_CERRADO` |

### 3.4 Transferencia: resumen, detalle y acciones (C-2, C-5)

```csharp
public record TransferenciaResumenDto(string Numero, DateTime Fecha, string Estado, bool TrasladoInterno,
    string SucursalOrigen, string SucursalOrigenNombre, string AlmacenOrigen,
    string SucursalDestino, string SucursalDestinoNombre, string AlmacenDestino,
    int Renglones, decimal Unidades, int? DiasEnTransito, byte PlazoDias,
    bool SalidaConfirmada, bool SalidaSinConfirmar, bool TransitoVencido, int Recepciones, bool RecepcionEnCurso);

public record PaginaTransferenciasDto(int Pagina, int Tamano, int TotalFilas, IReadOnlyList<TransferenciaResumenDto> Filas);

public record PorRecibirDto(int Contador, IReadOnlyList<TransferenciaResumenDto> Filas);   // soloContador=true → Filas vacía

public record TransferenciaDto(string Numero, string Modo, string Estado, bool TrasladoInterno, DateTime Fecha,
    string SucursalOrigen, string SucursalOrigenNombre, string AlmacenOrigen, string AlmacenOrigenNombre,
    string SucursalDestino, string SucursalDestinoNombre, string AlmacenDestino, string AlmacenDestinoNombre,
    string? AlmacenDestinoVigente, string Despachador, string? Transportista, string? Vehiculo, string? Notas,
    int? DiasEnTransito, byte PlazoDias, bool SalidaSinConfirmar, bool TransitoVencido,
    DateTime? SalidaConfirmadaEn, string? SalidaConfirmadaPor,
    int ConduceImpresiones, DateTime? ConduceUltimaImpresion, string Huella10, string Version,
    IReadOnlyList<LineaTransferenciaDto> Lineas, IReadOnlyList<RecepcionDto> Recepciones,
    RecepcionAbiertaDto? RecepcionAbierta, AnulacionTransferenciaDto? Anulacion,
    AccionesTransferenciaDto Acciones, bool Repetida = false);

public record LineaTransferenciaDto(short Linea, string Articulo, string Descripcion,
    string Unidad, decimal CantidadUnidad, decimal FactorUnidad, string UnidadBase,
    string? Lote, DateTime? VencimientoLote, IReadOnlyList<string> Series,
    decimal Despachada, decimal Recibida, decimal Pendiente,              // en unidad base
    [property: DatoCosto] decimal? CostoDespacho, [property: DatoCosto] decimal? Valor);

public record RecepcionAbiertaDto(Guid SesionId, DateTime AbiertaEn, IReadOnlyList<string> Usuarios);

public record AnulacionTransferenciaDto(DateTime Fecha, string Usuario, string Motivo, string? MotivoAnulacion, string? Autorizante);

/// <summary>Lo que la sesión puede hacer ahora; los motivo* son códigos (la pantalla pone el texto). Tramo 2 agrega campos, no quita.</summary>
public record AccionesTransferenciaDto(bool ImprimirConduce, bool ConfirmarSalida, bool Anular, bool AnularRequiereSupervisor, bool Recibir,
    string? MotivoNoConfirmarSalida, string? MotivoNoAnular, string? MotivoNoRecibir);
```

- `Estado` ∈ `CodigosTransferencia.Estados` (4.1). `Modo` ∈ `"E"`, `"S"`.
- `Despachada`, `Recibida`, `Pendiente` en **unidad base**; `CantidadUnidad` y `Unidad` son las del despacho. Pendiente = origen − consumida − faltante de `doc.LineaSaldo` R.
- `Huella10`: los 10 primeros caracteres hexadecimales de `inv.Transferencia.Huella`, en grupos (`A3F9-12C0-7B`).
- `ConduceImpresiones`: cuenta de líneas `CONDUCE_IMPRESO` (sin los reintentos por falla); `ConduceUltimaImpresion`: la más reciente.
- **Indicadores (UX-TI-07, los calcula el servidor con su hora):** `SalidaSinConfirmar` = estado `DESPACHADO` y más de 24 h desde el despacho; `TransitoVencido` = estado `DESPACHADO` o `EN_TRANSITO` y `DiasEnTransito > PlazoDias`; `DiasEnTransito` es null fuera de esos dos estados. `Recepciones` > 0 con estado `EN_TRANSITO` = «Recibida en parte (R{n})».
- **Motivos de acción** (códigos): `MotivoNoRecibir` ∈ `FUNCION_INCOMPATIBLE` (la despachó), `TRANSFERENCIA_SIN_SALDO`, `OTRA_SUCURSAL`, `SIN_PERMISO`, `TRANSFERENCIA_NO_VIGENTE`; `MotivoNoAnular` ∈ `TRANSFERENCIA_CON_PARTES`, `TRASLADO_INTERNO`, `OTRA_SUCURSAL`, `SIN_PERMISO`, `TRANSFERENCIA_NO_VIGENTE`; `MotivoNoConfirmarSalida` ∈ `CONDUCE_NO_IMPRESO`, `SALIDA_YA_CONFIRMADA`, `TRASLADO_INTERNO`, `OTRA_SUCURSAL`, `SIN_PERMISO`, `TRANSFERENCIA_NO_VIGENTE`.

**Filtros de T-01:** `rol` ∈ `origen` (por omisión) | `destino` | `todas` (solo RC con la sesión en la central; si no, 403); `estado` ∈ los códigos de 4.1 (vacío = todos); `desde`, `hasta` (`yyyy-MM-dd`, por omisión los últimos 30 días; rango > 366 días → 400 `RANGO_FECHAS_INVALIDO`); `texto` (C-6): **número de TI** (prefijo), **código de almacén** (origen o destino) o **código exacto de artículo** de alguna línea; `pagina` (base 1), `tamano` (1 a 200, por omisión 50). Orden: fecha descendente, número descendente.

**T-02:** transferencias con fila en `inv.TransferenciaAbierta` cuyo destino vigente es la sucursal de la sesión, en orden de antigüedad. Sin permiso R: 403. El menú llama con `soloContador=true` cada 60 s.

### 3.5 Historial (C-10)

```csharp
public record HistorialTransferenciaDto(string Numero, IReadOnlyList<EventoTransferenciaDto> Eventos);
/// <param name="Evento">Uno de CodigosTransferencia.Eventos.</param>
/// <param name="Numero">n de la impresión, de la reimpresión o de la recepción (R n); null en los demás.</param>
public record EventoTransferenciaDto(DateTime Fecha, string Evento, string Usuario, int? Numero, string? Detalle);
```
Eventos del tramo 1: `TRANSFERENCIA_DESPACHADA`, `CONDUCE_IMPRESO`, `CONDUCE_REINTENTO`, `SALIDA_CONFIRMADA`, `RECEPCION_ABIERTA`, `RECEPCION_DESCARTADA`, `RECEPCION_CONFIRMADA`, `RECEPCION_SOBRANTE` (UX-TI-03), `TRANSFERENCIA_ANULADA`. `Detalle` sin costos (por ejemplo «46 de 48 renglones», «Transportista J. Pérez»).

### 3.6 Recepción por sesión (T-08 a T-14; C-7)

```csharp
public record SesionRecepcionDto(Guid Id, string Numero, string Estado, bool ConteoCiego, bool Terminada, DateTime? TerminadaEn,
    string AlmacenOrigen, string SucursalOrigen, string AlmacenDestino, string AbiertaPor, DateTime AbiertaEn,
    IReadOnlyList<string> Usuarios, IReadOnlyList<LineaSesionDto> Lineas, IReadOnlyList<NoEsperadoDto> NoEsperados,
    int TotalLecturas, IReadOnlyList<LecturaDto> Lecturas);

/// <param name="Esperado">Pendiente de la línea en <see cref="Unidad"/>; null con conteo ciego hasta terminar (después, en todas).</param>
/// <param name="Recontable">Tras terminar: la línea tenía diferencia al terminar y admite lecturas nuevas (UX-TI-05).</param>
public record LineaSesionDto(short Linea, string Articulo, string Descripcion, string Unidad, decimal FactorUnidad,
    string? Lote, DateTime? VencimientoLote, bool RequiereSerie, decimal Contado, decimal? Esperado, bool Recontable);

public record NoEsperadoDto(string Articulo, string Descripcion, string? Lote, decimal Contado);

public record LecturaDto(Guid EscaneoId, DateTime En, string Usuario, string Articulo, string? Lote, string? Serie, decimal Cantidad,
    string Origen, bool NoEsperado, bool DespuesDeTerminar);

public class EscaneosRequest
{
    public List<EscaneoDto> Escaneos { get; set; } = [];   // 1 a 200
}

public class EscaneoDto
{
    public Guid EscaneoId { get; set; }             // lo genera el cliente por lectura y lo conserva hasta tener respuesta
    public string Codigo { get; set; } = "";        // lo leído: código o código de barras del artículo, o número de serie
    public string? Lote { get; set; }               // obligatorio si el artículo viene en más de un lote en la TI
    public decimal Cantidad { get; set; } = 1;      // > 0, en la unidad de la línea; con serie, 1
    public string Origen { get; set; } = "E";       // "E" escaneo (lector o cámara), "D" digitado (3+código, botón +1)
}

public record EscaneosRespuestaDto(IReadOnlyList<ResultadoEscaneoDto> Resultados, SesionRecepcionDto Sesion);

/// <param name="Estado">ACEPTADO, NO_ESPERADO o RECHAZADO (CodigosTransferencia.EstadosEscaneo).</param>
/// <param name="Codigo">Con RECHAZADO, el código del motivo; null en los demás.</param>
/// <param name="Repetido">El EscaneoId ya estaba guardado: no sumó otra vez.</param>
public record ResultadoEscaneoDto(Guid EscaneoId, string Estado, string? Codigo, string? Mensaje, short? Linea, string? Articulo, string? Lote,
    decimal? ContadoLinea, bool Repetido);

public record ComparacionRecepcionDto(Guid SesionId, string Numero, short ConsecutivoPropuesto, DateTime TerminadaEn,
    IReadOnlyList<LineaComparacionDto> Lineas, IReadOnlyList<NoEsperadoDto> NoEsperados, bool HayDiferencias);

/// <param name="Esperado">Pendiente en la unidad de la línea.</param>
/// <param name="ARecibir">min(Contado, Esperado): lo que entrará al confirmar (UX-TI-03).</param>
/// <param name="Diferencia">Contado − Esperado (negativa = falta, positiva = sobra).</param>
/// <param name="Resultado">COMPLETO, FALTA o SOBRA.</param>
public record LineaComparacionDto(short Linea, string Articulo, string Descripcion, string Unidad, decimal FactorUnidad, string UnidadBase,
    string? Lote, DateTime? VencimientoLote, decimal Esperado, decimal Contado, decimal ARecibir, decimal Diferencia, string Resultado);

public class ConfirmarRecepcionRequest
{
    public bool CierraSaldo { get; set; }                         // tramo 1: false
    public List<DiferenciaRequest>? Diferencias { get; set; }     // tramo 1: null o vacía
    public AutorizacionSupervisor? Autorizacion { get; set; }     // tramo 1: null
}

public record RecepcionDto(long Id, short Consecutivo, DateTime Fecha, string RegistradoPor, int Renglones, decimal Unidades,
    IReadOnlyList<LineaRecepcionDto> Lineas, IReadOnlyList<SobranteRecepcionDto> Sobrantes, IReadOnlyList<NoEsperadoDto> NoEsperados,
    string Numero, string EstadoTransferencia, bool Repetida = false);

public record LineaRecepcionDto(short Linea, string Articulo, string? Lote, decimal Cantidad, string UnidadBase);   // unidad base

/// <summary>UX-TI-03: lo contado de más en una línea que no entra al inventario; queda en la bitácora RECEPCION_SOBRANTE.</summary>
public record SobranteRecepcionDto(short Linea, string Articulo, string? Lote, decimal Cantidad, string Unidad);
```

`DiferenciaRequest` se declara ya con la forma de [SW3B] 5.3 más `VencimientoRecibido` (ADR-119), pero en el tramo 1 su uso responde 422 `DIFERENCIAS_NO_DISPONIBLES`:
```csharp
public class DiferenciaRequest
{
    public short? Linea { get; set; }
    public string Clase { get; set; } = "";          // F, S, C, N (tramo 2)
    public string Motivo { get; set; } = "";
    public decimal Cantidad { get; set; }
    public string? ArticuloRecibido { get; set; }
    public string? LoteRecibido { get; set; }
    public DateTime? VencimientoRecibido { get; set; }
    public string? AlmacenAverias { get; set; }
    public string? Referencia { get; set; }
    public string? Observacion { get; set; }
}
```

**Reglas de la sesión:**

| Paso | Regla |
|---|---|
| T-08 abrir o unirse | Exige: TI visible, estado `DESPACHADO` o `EN_TRANSITO`, destino vigente = sucursal de la sesión, pendiente > 0, el usuario **no** es quien despachó (S-02, también ADMIN y SUPER; modo S no llega aquí). Si ya hay una sesión `A`, se une (200); si no, la crea (201). La carrera la resuelve `UX_SesionRecepcion_Abierta` (2601 → relee y se une) |
| T-09 | `lecturas` = cuántas lecturas recientes (0 a 200, por omisión 50), más nuevas primero. S-02 también aquí (403): el despachador no ve el conteo |
| T-10 lectura | Resuelve `Codigo` en este orden: serie de la TI (`inv.TransferenciaSerie`), código del artículo, código de barras. Resultado por lectura: **ACEPTADO** (artículo y lote de una línea; suma), **NO_ESPERADO** (artículo existente que no está en la TI, o lote que no está en la TI; se guarda con `NoEsperado = 1` y no suma a ninguna línea) o **RECHAZADO** (no se guarda) con `Codigo` ∈ `ESCANEO_CODIGO_DESCONOCIDO`, `ESCANEO_NO_PERTENECE` (serie de otra TI o de otro artículo), `ESCANEO_LOTE_REQUERIDO` (artículo con varios lotes en la TI, sin `Lote`), `ESCANEO_SERIE_REPETIDA`, `ESCANEO_RENGLON_SIN_DIFERENCIA` (tras terminar, línea no recontable), `ESCANEO_INVALIDO` (cantidad ≤ 0, serie con cantidad ≠ 1). **Un rechazo no hace fallar la tanda**: la respuesta es 200 con un resultado por lectura, en el mismo orden. Solo fallan la tanda entera: 404, 403 `FUNCION_INCOMPATIBLE`, 409 `SESION_CERRADA`, 409 `DESTINO_NO_VIGENTE`/`TRANSFERENCIA_NO_VIGENTE`, 400 (más de 200 o `EscaneoId` vacío) y 503 |
| Idempotencia de lectura | PK `(SesionId, EscaneoId)`. Un `EscaneoId` ya guardado devuelve su resultado original con `Repetido = true` y no suma. Un rechazado no se guarda: el reenvío se vuelve a evaluar y da el mismo rechazo (determinista). Un mismo `EscaneoId` repetido dentro de la tanda se toma una vez |
| T-11 borrar | Propia: R Agregar. Ajena: R **Autorizar** (si no, 403). Tras terminar, solo se borran lecturas `DespuesDeTerminar` (si no, 409 `LECTURA_ANTERIOR_A_TERMINAR`). Inexistente: 204 (el reintento no falla). Sesión cerrada: 409 `SESION_CERRADA` |
| T-12 terminar | La primera llamada fija `TerminadaEn`; las siguientes devuelven la comparación actual **sin mover** `TerminadaEn`. `Recontable` = la línea tenía `Contado ≠ Esperado` con las lecturas anteriores a `TerminadaEn` (se deriva de `inv.SesionRecepcionEscaneo.En`, sin columna nueva). `DespuesDeTerminar` = `En > TerminadaEn` (marca de UX-TI-05) |
| T-13 confirmar (tramo 1) | `CierraSaldo = false`, `Diferencias` vacía y `Autorizacion` nula; si no, 422 `DIFERENCIAS_NO_DISPONIBLES`. Exige haber terminado (409 `CONTEO_SIN_TERMINAR`). Entra por línea `min(Contado, Pendiente)` × factor; si todas dan 0, 422 `RECEPCION_SIN_CANTIDADES`. Lo que sobra queda en `Sobrantes` y en la bitácora `RECEPCION_SOBRANTE` de la misma transacción; los no esperados, en `NoEsperados` y en la misma línea de bitácora (UX-TI-03, nota de ADR-105). Lo que falta **queda pendiente** (otra sesión lo recibe: R2). Sesión `A → C`. S-02 se vuelve a exigir (403) |
| T-14 descartar | Sesión `A → X`; sus lecturas quedan hasta la purga (30 días). Repetido sobre `X`: 204. Sobre `C`: 409 `SESION_CERRADA` |

**Unidades:** `Contado`, `Esperado` y `Cantidad` de la lectura van en la unidad de la línea de la TI; la recepción (kárdex y `RecepcionDto.Lineas`) va en unidad base. Con número de serie, la línea se despacha en unidad base (factor 1) y cada serie leída es 1.

### 3.7 Conduce (T-21)

`GET /api/transferencias/{n}/conduce?reintento=false` → `application/pdf`, carta, «Página n de m», huella en texto, sin costos (sin QR en el tramo 1). Cada llamada registra `CONDUCE_IMPRESO` con su número (la segunda en adelante sale «REIMPRESIÓN n»). `reintento=true` = reintento tras una falla de la impresora (`CONDUCE_REINTENTO`, no cuenta como reimpresión), igual que `ImpresionEndpoints` [V]. Modo S: título «TRASLADO ENTRE ALMACENES» (UX-TI-06). Anulada: sale con «ANULADA». 404 si no es visible.

---

## 4. Estados y códigos

### 4.1 Estados (`CodigosTransferencia.Estados`)

| Código | Texto de la pantalla | Cuándo (vista `inv.TransferenciaEstado`) | Tramo |
|---|---|---|---|
| `DESPACHADO` | «Despachada» | Emitida, sin salida confirmada | 1 |
| `EN_TRANSITO` | «En tránsito» | Salida confirmada (o `SalidaEnUnPaso`), con pendiente > 0; con recepciones = «Recibida en parte (R n)» | 1 |
| `RECONCILIADO` | «Recibida» | Pendiente 0 en todas las líneas (modo S: nace así) | 1 |
| `ANULADO` | «Anulada» | Anulada | 1 |
| `RECIBIDO_PROVISIONAL` | «Recibida provisional» | Entrega 2 | — |
| `CON_DIFERENCIAS` | «Con diferencias» | Tramo 2 | 2 |

Recepción en una TI `DESPACHADO`: permitida (la salida es opcional para recibir, [TRF] 2.3). Estados de la sesión: `A` abierta, `C` confirmada, `X` descartada. Estados de lectura: `ACEPTADO`, `NO_ESPERADO`, `RECHAZADO`. Resultado de comparación: `COMPLETO`, `FALTA`, `SOBRA`.

### 4.2 Tabla código ↔ número del motor ↔ HTTP (C-8)

**Del motor (franja 51440-51459, ADR-100 precisión 5 y P-D1) [V en el DDL]:** las agrega el backend a `ErroresNumeracion.Clasificar` con un `case >= 51440 and <= 51459` propio. **Hoy esa franja cae en `default` → 500 genérico sin código** (`ErroresNumeracion.cs:450-463`, solo cubre 51300-51399) [V].

| Número | Código | HTTP | Tramo | Nota |
|---|---|---|---|---|
| 51440 | `PARTE_DE_OTRO_SITIO` | 409 | 1 | El servicio responde antes (ADR-103); si llega del motor, aviso en el registro |
| 51441 | `PARTE_INMUTABLE` | 500 | 1 | Defecto. **Excepción:** escaneo en sesión cerrada → el servicio lo traduce a 409 `SESION_CERRADA` |
| 51442 | `TRANSFERENCIA_CON_PARTES` | 409 | 1 | |
| 51443 | `DESTINO_NO_VIGENTE` | 409 | 1 | |
| 51444 | `IMPUTACION_SOLO_CENTRAL` | 403 | 2 | |
| 51445 | `MOTIVO_CON_MOVIMIENTOS` | 409 | 2 | |
| 51446 | `REDIRECCION_NO_PERMITIDA` | 409 | 2 | |
| 51447 | `SUCURSAL_RESPONSABLE_INVALIDA` | 422 | 2 | |
| 51448 | `IMPUTACION_NO_PERDIDA` | 422 | 2 | |
| 51449 | `CONFIRMACION_NO_ADMITIDA` | 409 | 2 | |
| 51450 | `RECONSTRUCCION_SIN_SUCESION` | 409 | E2 | |
| 51451 | `FUNCION_INCOMPATIBLE` | 403 | 1 | S-02 por código (ADR-106) |
| 51452 | `FECHA_PARTE` | 500 | 1 | Defecto |
| 51453 | `EXISTENCIA_INSUFICIENTE` | **422** | 1 | **El DDL dice 409**; uso 422 para que el código tenga un solo estado (el servicio lo da con 422 y `faltantes`; desde el motor va sin `faltantes`) |
| 51454 | `TRANSFERENCIA_INCONSISTENTE` | 500 | 1 | Defecto |
| 51455 | `AUTORIZACION_INVALIDA` | 422 | 1 | Código existente (`CodigosDocumento`) |
| 51456 | `SESION_NO_PURGABLE` | 500 | 1 | Solo la purga |
| 51457 | `TRANSFERENCIA_NO_VIGENTE` | 409 | 1 | |
| 51458-51459 | — | — | — | Reserva de la 3b-2 |
| 51330 | `EMISION_BLOQUEADA_RECONCILIAR` (existente) | 503 | 1 | **No** `EMISION_BLOQUEADA` como dicen [PLAN], [UXT] y [DDL]: el código real es `CodigosDocumento.EmisionBloqueada = "EMISION_BLOQUEADA_RECONCILIAR"` (`CodigosDocumento.cs:40`) [V] |
| 51333 | `PERIODO_CERRADO` (existente) | 422 | 1 | `CodigosCierreInventario.PeriodoCerrado` [V] |
| 547 (`CK_LineaSaldo_Consumo`, `CK_TransitoArticulo_Cantidad`) | `SALDO_INSUFICIENTE` | 409 | 1 | Red; con T-13 = `min(contado, pendiente)` bajo el bloqueo, no debería ocurrir |
| 2601 `UX_SesionRecepcion_Abierta` | — | 200 | 1 | Se une a la sesión |
| 2627 `UQ_Recepcion_Sesion` | — | 200 | 1 | Relee y devuelve con `repetida = true` |

**Del servicio (en `CodigosTransferencia`, salvo los existentes):**

| Código | HTTP | Rutas |
|---|---|---|
| `TRANSFERENCIA_NO_ENCONTRADA` | 404 | T-03, T-04, T-06, T-07, T-08, T-21 |
| `SESION_NO_ENCONTRADA` | 404 | T-09 a T-14 |
| `CLAVE_IDEMPOTENCIA_REQUERIDA`, `ORIGEN_INVALIDO`, `DESTINO_INVALIDO`, `DESPACHO_INVALIDO`, `RENGLON_DUPLICADO`, `SERIES_INCOMPLETAS`, `SERIE_NO_DISPONIBLE`, `LOTE_VENCIDO_SIN_MOTIVO` | 422 | T-05 |
| `LOTE_REQUERIDO`, `LOTE_INEXISTENTE`, `EXISTENCIA_INSUFICIENTE` (`CodigosInventario`, T1) · `UNIDAD_REQUERIDA`, `UNIDAD_AJENA` (`CodigosDocumento`) | 422 | T-05 |
| `TRANSPORTISTA_REQUERIDO`, `CONDUCE_NO_IMPRESO` | 422 | T-06 |
| `SALIDA_YA_CONFIRMADA`, `TRASLADO_INTERNO` | 409 | T-06, T-07 |
| `MOTIVO_REQUERIDO`, `DECLARACION_REQUERIDA`, `SUPERVISOR_REQUERIDO` · `MOTIVO_ANULACION_INVALIDO` (existente) | 422 | T-07 |
| `TRANSFERENCIA_SIN_SALDO` | 409 | T-08 |
| `SESION_CERRADA`, `CONTEO_SIN_TERMINAR`, `LECTURA_ANTERIOR_A_TERMINAR` | 409 | T-10 a T-14 |
| `DIFERENCIAS_NO_DISPONIBLES`, `RECEPCION_SIN_CANTIDADES` | 422 | T-13 (tramo 1) |
| `ESCANEO_CODIGO_DESCONOCIDO`, `ESCANEO_NO_PERTENECE`, `ESCANEO_LOTE_REQUERIDO`, `ESCANEO_SERIE_REPETIDA`, `ESCANEO_RENGLON_SIN_DIFERENCIA`, `ESCANEO_INVALIDO` | — (dentro de `ResultadoEscaneoDto.Codigo`, respuesta 200) | T-10 |
| `RANGO_FECHAS_INVALIDO` | 400 | T-01 |
| `IDEMPOTENCIA_CONFLICTO`, `REGISTRO_MODIFICADO` (`CodigosConflicto`) | 409 | T-05, T-06, T-13 |
| `BASE_RESTAURADA` (middleware de A, cuando se una) | 503 | Toda escritura |

Correcciones a [UXT] 7: allí se supuso «+80» y salió `FUNCION_INCOMPATIBLE` = 51456 y `FECHA_PARTE` = 51457; los números reales son **51451** y **51452**. `MOTIVO_REQUERIDO` no existía en el código: se crea en `CodigosTransferencia`.

---

## 5. Idempotencia y reintento con resultado desconocido

| Operación | Llave | Mismo pedido repetido | Pedido distinto con la misma llave | Qué hace la pantalla si no llega respuesta |
|---|---|---|---|---|
| T-05 despacho | `ClaveIdempotencia` → `doc.Documento.Uid` (idempotencia duradera del documento) + huella del contenido | 200 con la misma TI y `repetida = true` | 409 `IDEMPOTENCIA_CONFLICTO` | Renglones en solo lectura; reenvía con **la misma** clave hasta tener 201/200 o un 4xx claro. Renueva la clave solo tras un 4xx y una edición ([UXT] 4.2) |
| T-06 salida | `Version` | 409 `SALIDA_YA_CONFIRMADA` (con quién y cuándo) | 409 `REGISTRO_MODIFICADO` | Reintenta con la misma `Version`; ante `SALIDA_YA_CONFIRMADA` recarga y muestra «La salida ya estaba confirmada.» |
| T-07 anular | Estado del documento | 409 `TRANSFERENCIA_NO_VIGENTE` | — | Reintenta; ante ese 409 recarga y ve «Anulada» |
| T-08 sesión | `UX_SesionRecepcion_Abierta` | 200 con la misma sesión | — | Reintenta sin riesgo |
| T-10 lecturas | `(SesionId, EscaneoId)` | Resultado original con `repetido = true` | (no aplica: el `EscaneoId` identifica la lectura) | Cola local (`localStorage`, clave `SesionId`) y reenvío cada 5 s hasta tener resultado |
| T-11 borrar | `(SesionId, EscaneoId)` | 204 | — | Reintenta |
| T-12 terminar | `TerminadaEn` fijo | 200 con la comparación actual | — | Reintenta |
| T-13 confirmar | `SesionId` (`UQ_Recepcion_Sesion`) + `HuellaSolicitud` (cierraSaldo + diferencias + autorizante, sin la clave del supervisor) | 200 con la misma `RecepcionDto` y `repetida = true` | 409 `IDEMPOTENCIA_CONFLICTO` | Reintenta con el mismo `sid`; ante el 409, recarga el detalle |
| T-14 descartar | Estado de la sesión | 204 | 409 `SESION_CERRADA` si se confirmó | Reintenta |
| T-21 conduce | — | Cuenta otra impresión salvo `reintento=true` | — | Reintenta con `reintento=true` |

Si una confirmación (T-13) falla por cualquier rechazo, se deshace entera y la sesión sigue `A` con sus lecturas (ADR-105).

---

## 6. Interfaces entre módulos (lo que el backend implementa detrás del contrato)

- `IDuenoSucursal` en el módulo Sitio (nivel 1), no en Configuración ([PLAN] T1).
- `LibroInventario.PrepararAsync(..., salidaEstricta: true)` para el despacho (T-09). Hoy `SalidaEstricta` solo existe en `b/adr118-119-t1` (`LibroInventario.cs:51`) [V]; hasta que T1 se una, `PermiteNegativa = false` y la red 51453.
- `FaltanteExistenciaDto` y `CodigosInventario` vienen de T1 (`b/adr118-119-t1`, `Contracts/Inventario/Lotes.cs:13`, `CodigosInventario.cs`) [V]. El motivo `T` (C-3) requiere `OrigenesPolitica.Transferencia = 'T'` en T1 o en la 3b al rebasar.
- `AutorizacionesSupervisor` con la opción `transfdespacho` y el tipo `ANULA_TRANSITO` (nombre del DDL; el plan decía `ANULAR_TRANSFERENCIA`).
- `ArticuloLinea.RequiereLote` ya está en T1 (`Catalogo.cs:19` de `b/adr118-119-t1`) [V]; **`RequiereSerie` no** (C-11 a medias).

---

## 7. Seguridad de arquitectura

- **Autenticación:** JWT HS256 de hoy; sin cambios.
- **Autorización:** permisos de la sección 2; ADMIN y SUPER por nivel, sin saltarse S-02.
- **Segregación:** S-02 por código de usuario en mayúsculas en T-08, T-09, T-10, T-13 (servicio, 403 `FUNCION_INCOMPATIBLE`) y 51451 en la base. Modo S exento (S-3b-04).
- **Aislamiento:** empresa = base del token; sucursal = claim del token (origen para D, destino vigente para R); no visible = 404. H-01 y H-02 de la auditoría siguen abiertos (no son de esta ola).
- **Secretos:** ninguno nuevo. La clave del supervisor viaja solo en el `POST` y se separa antes de la huella (`AutorizacionesSupervisor.SepararClave`).
- **Candado:** sección 2.

---

## 8. Comparación con `b/ola3b` y diferencias entre las fuentes

**Backend:** `b/ola3b` está en `ec459d5`, igual a `feature/modelo-ng`, con el árbol limpio y sin stash: **todavía no hay código de transferencias que comparar** [V]. Lo que el backend debe respetar al empezar:

| # | Diferencia encontrada | Fuente | Qué rige |
|---|---|---|---|
| D-1 | `EMISION_BLOQUEADA` frente al código real `EMISION_BLOQUEADA_RECONCILIAR` | [PLAN], [UXT] 7, [DDL] 3 frente a `CodigosDocumento.cs:40` | El código real |
| D-2 | 51453 con 409 | [DDL] 3 | 422 (un estado por código) |
| D-3 | Números supuestos con «+80» | [UXT] 7 | Tabla 4.2 |
| D-4 | T-10 con 422 `ESCANEO_NO_PERTENECE` para la tanda entera | [SW3B] 5.2 | Resultado por lectura, 200 (C-7) |
| D-5 | Alcances `transferencia-origen` / `-destino` en `/api/catalogos` | [UXT] C-1 | Ruta propia T-00 (3.1) |
| D-6 | `MOTIVO_REQUERIDO` como código existente | [UXT] 7 | Nuevo en `CodigosTransferencia` |
| D-7 | `ANULAR_TRANSFERENCIA` | [PLAN] T0 | `ANULA_TRANSITO` ([DDL]) |
| D-8 | `DespachoRequest` como `record` posicional con `Unidad` opcional | [SW3B] 5.3 | `class` con `Unidad` obligatoria |
| D-9 | `TransferenciaDto` de [SW3B] sin despachador, conduce, recepción abierta ni anulación; `Diferencias` en la línea | [SW3B] 5.3 | 3.4 (C-2). `Diferencias` y `Faltante` se agregan en el tramo 2 (aditivo) |
| D-10 | Menú firmado (UX-TI-01): «Despacho de Transferencia» y «Recepción de Transferencia»; el diseño decía «Despacho de Transferencias» y «Transferencias por Recibir» | ADR-100 frente a [UXT] 3.0 | Lo firmado (no afecta las rutas; entrega al frontend) |
| D-11 | `51440-51459` sin clasificar: hoy darían 500 sin código | `ErroresNumeracion.cs:450-463` | El backend agrega el `case` (sección 4.2) |
| D-12 | `Notas` de 200 en el DTO; la columna es `doc.Documento.Notas` de 500 | [UXT], `Documentos.cs:106` | 200 en la validación |

---

## 9. Lo que queda para el tramo 2

- T-15 diferencias posteriores, T-16 confirmación del origen, T-17 imputación, T-18 redirección, T-19 motivos, T-20 parámetros y T-22 reportes, con sus DTO de [SW3B] 5.3.
- En T-13: `CierraSaldo = true`, `Diferencias` y `Autorizacion` (se retira `DIFERENCIAS_NO_DISPONIBLES`); el sobrante anotado del tramo 1 se registra como diferencia S; `VencimientoRecibido` y `LOTE_VENCIMIENTO_DISTINTO` (ADR-119).
- Campos aditivos: `TransferenciaDto.Diferencias`, `LineaTransferenciaDto.Faltante`, `AccionesTransferenciaDto.ConfirmarOrigen`, `Imputar` y `Redirigir`; estados `CON_DIFERENCIAS` (y `RECIBIDO_PROVISIONAL` en la entrega 2); evento de historial por diferencia, imputación y redirección.
- `AlmacenTransferenciaDto.SucursalCerrada` real (P-4); `CostosSoloEnCentral` (3b-1) sobre `[DatoCosto]`; QR del conduce; MAUI de T-02 y T-08 a T-14 con el mismo contrato.
- Códigos del motor 51444 a 51450 activos.

---

## 10. Riesgos

| # | Riesgo | Prob. / impacto | Mitigación |
|---|---|---|---|
| R-1 | `FaltanteExistenciaDto`, `CodigosInventario` y `SalidaEstricta` viven en `b/adr118-119-t1` (unión el 27-oct); si la 3b los copia, choque textual | Alta / bajo | La 3b los usa **con el mismo nombre y JSON**; si T1 no ha unido, los toma por *cherry-pick* del commit de contratos de T1, nunca redefinidos |
| R-2 | `RENGLON_DUPLICADO` obliga a la pantalla a unir renglones del mismo artículo y lote | Media / bajo | Ya suma la lectura repetida; ≈ 0,01 sp más en el frontend |
| R-3 | El 503 del candado cambia de código al unirse el middleware de A | Cierta / bajo | La pantalla trata `BASE_RESTAURADA` y `EMISION_BLOQUEADA_RECONCILIAR` igual |
| R-4 | Política de 240 por minuto insuficiente con varios lectores por usuario | Baja / bajo | Es por usuario; medir en la carga (PB-3b-16) |

---

### Cierre
- Estado: Completado
- Artefactos: `C:\Users\lfmen\AppData\Local\Temp\claude\C--Users-lfmen-source-repos-Solucion-GPOS-NG-GPOS-NG\2ab4d64a-60e5-4721-9bba-4b93894990d8\scratchpad\contratos-transferencias.md`
- Supuestos: `b/ola3b` sin commits propios a la hora de leer (`ec459d5`); T1 de ADR-118/119 se une el 27-oct con `FaltanteExistenciaDto` sin cambios; el middleware del candado de A llega con `BASE_RESTAURADA`; las cifras de límites son inferidas.
- Decisiones candidatas a ADR: ninguna nueva. Son decisiones de contrato dentro de lo firmado: ruta T-00 en lugar de alcances; resultado por lectura en T-10; `RENGLON_DUPLICADO`; recontar con `Recontable` derivado de `TerminadaEn` (UX-TI-05); 51453 → 422.
- Entregas a otros agentes: desarrollador-backend (3b) → sección 4.2 en `ErroresNumeracion` (franja 51440-51459), política `Escaneos`, contratos en `Transferencias.cs` y `CodigosTransferencia.cs` como primer commit de `b/ola3b`; desarrollador-frontend → D-5, D-10, C-7 por lectura y 503 doble; A (candado) → T-21 en la tabla «GET con efecto» de PF-36 y ninguna ruta de transferencias con marca; constructor de T1 → `OrigenesPolitica.Transferencia = 'T'` y `ArticuloLinea.RequiereSerie` (C-11); arquitecto-datos → D-2 (409 → 422 de 51453, solo traducción).
- Próximo paso recomendado: que el backend haga el primer commit de `b/ola3b` solo con estos dos archivos de contratos, para que `b/ola3b-web` nazca de él.
