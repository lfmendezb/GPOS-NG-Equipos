# [Blueprint Técnico] H-11 (RN-24): desbloqueo de una base restaurada sin central (DM-01, DM-02 y DM-03)

- **Autor:** arquitecto-software, equipo A · **Fecha:** 2026-10-10
- **Árbol leído:** `GPOS-NG-h11`, rama `a/h11-desbloqueo-restauracion`, `42e13b6` (sin cambios en el árbol)
- **Encargo:** `GPOS-NG-Equipos/avisos/B-a-A/2026-10-10-encargo-h11-desbloqueo-restauracion.md` (aprobado por el propietario el 2026-10-10). **Hallazgos de origen:** `C-a-B/2026-10-10-ensayo-demo-resultado.md` (DM-01, DM-02 y DM-03).
- **Alcance firmado:** ADR-53, cláusula 9 (`docs/adr/ADR-053.md:59`); H-11 y H-12 (`docs/decisiones/2026-10-04-cierre-h0.md:229-230`, firmadas el 2026-10-04); H-13 (`:231`).
- **Estado del diseño:** listo para el arquitecto-datos y los desarrolladores, con las preguntas P-1 a P-6 (sección 12) **pendientes de la decisión del propietario**. Ninguna bloquea el inicio: cada una tiene una opción por omisión que se puede cambiar sin rehacer el diseño.

> **Nota sobre H-13.** La fila de H-13 dice «Sí» (`cierre-h0.md:231`), pero la cabecera del mismo documento la lista como pendiente de firma (`:3`). El encargo la da por aprobada. El diseño usa **solo el SUPER**, que es lo más restrictivo y cumple las dos lecturas. Conviene que el Maestro corrija el registro.

---

## 1. Contexto y alcance

### 1.1 Cómo se detecta hoy la restauración y dónde salta el 51330 (verificado)

| Pieza | Evidencia | Qué hace |
|---|---|---|
| Registro del fork | `src/GPOS.Migracion/Aprovisionamiento.cs:233-257` (`RegistrarSitioAsync`) | `crear` guarda el `recovery_fork_guid` en `sync.EstadoNodo.ForkRegistrado`. `actualizar` **no lo vuelve a registrar** si la fila existe (`:102-103`, `:127`, `:236-237`): es correcto, porque si lo hiciera borraría la marca de la restauración |
| Detección en la consola | `Aprovisionamiento.cs:33` (`EstadoBase.Restaurada`) y `:141-164` | `verificar` compara el fork registrado con el actual y lo imprime (`Program.cs:69-70`), pero **el código de salida solo mira `AlDia`** (`Program.cs:71`): esto es **DM-02** |
| Guarda del motor (51330) | `doc.TR_Documento_Emision`: `SqlMigracionesOla3EmisionLigera.cs:49-55`, vigente en el script generado `database/empresa/gpos-empresa-20261010035415_Ola4BusquedaSinTildes.sql:11945-11973` (los parches de Ola4* no tocan la guarda). `caja.TR_Movimiento_Nodo`: `SqlMigracionesOla3.cs:334-342` | En la emisión (`Estado` 0 → 1) y en todo movimiento de caja: si `EmisionBloqueada = 1`, el fork es nulo o el fork actual es distinto del registrado, **THROW 51330**. Solo se exceptúa la reaplicación con `SESSION_CONTEXT('gpos.reaplicacion')` y una reconciliación en estado `R` |
| Guarda del servicio | `DocumentosNg.cs:40-46` con `ConsultasDocumentos.cs:13-21` sobre la vista `sync.EstadoEmision` (`SqlMigracionesOla3.cs:495-500`) | **Solo lee `EmisionBloqueada`, no compara el fork.** Tras una restauración, la bandera sigue en 0 (viene del respaldo), así que el servicio toma el número de la serie y el NCF y **el rechazo llega tarde**, desde el disparador. La transacción se deshace entera y no se consume nada, pero el trabajo se hace en vano |
| Traducción a HTTP | `ErroresNumeracion.cs:341-344`, mensaje en `:137` y `DocumentosNg.cs:51-54`; código `EMISION_BLOQUEADA_RECONCILIAR` (`CodigosDocumento.cs:40`) | 503. El texto dice «…hasta reconciliarse **con la central**», que **no aplica** a la empresa de una sola base |
| Vía de desbloqueo | — | **No existe** (ni comando, ni servicio, ni pantalla). Además, la aplicación **no puede** escribir el estado: `DENY INSERT, UPDATE, DELETE ON sync.EstadoNodo` y `sync.Nodo` (`SqlMigracionesMae.cs:90-91`) y `ON sync.Reconciliacion` (`SqlMigracionesOla3.cs:657`). Esto es **DM-01** |

**Lo que ya existe y se reutiliza (verificado):**
- `sync.Reconciliacion`, `ReconciliacionSerie`, `ReconciliacionNcf` y `ReconciliacionSecuencia` (`Bandeja.cs:52-102`, `SyncConfiguracion.cs:58-116`).
- `sync.ReconciliacionChequera` (`Bandeja.cs:108-115`).
- `fiscal.NcfZonaIncierta` (`Comprobantes.cs:108-124`, `FisConfiguracion.cs:124-157`).
- Estado `X` «cerrado por restauración» (`Comprobantes.cs:24-25`), inmutable por `TR_SecuenciaNcf_Bloque`: 51325 impide reabrirlo y 51324 impide que otro bloque se solape (`SqlMigracionesOla3.cs:385-400`). La pantalla de secuencias nunca reabre un `X` (`AdministracionService.cs:337-338`).
- `conf.Parametros.MargenMinimoSerie`, que vale entre 100 y 1.000.000 (`CfgConfiguracion.cs:92,125`).

### 1.2 Alcance

1. **Desbloqueo sin central** (H-11) de la empresa de una sola base, solo con el **SUPER** (H-13) y con **motivo obligatorio**:
   - cierra cada secuencia NCF vigente en el último NCF probado y registra la porción siguiente como secuencia nueva (H-12);
   - adelanta las series con RN-12;
   - registra el fork actual;
   - deja la confirmación y el desbloqueo juntos en la bitácora;
   - **todo en una transacción**.
2. **Traslado planificado** (precisión del Maestro a H-11; RN-04): las secuencias **sin diferencias** se confirman sin cerrarse.
3. **Detección temprana en el servicio:** la guarda lee también el fork y rechaza antes de tomar números.
4. **DM-02:** `verificar` devuelve **3** si la base está RESTAURADA.
5. **DM-03:** se quita el aviso falso de intercalación vacía con AUTO_CLOSE.
6. **Superficies:** API, y una tarjeta «Restauración de la base» en la pestaña Diagnóstico (Web y MAUI). **Sin subcomando de desbloqueo en `GPOS.Migracion`** (decisión D-3).

**Fuera de alcance:**
- la reconciliación de nodos con la central (entrega 2, RN-03 y pasos 2 a 4 de POS 2.3);
- la resolución de la zona incierta: reconstruir o anular en el 608, que es la pregunta P-6;
- el diario electrónico (H-14, **no construido**: no aparece en `src`);
- la consulta automática al proveedor de e-CF;
- DM-04 (AUTO_CLOSE OFF obligatorio), que va al arquitecto-datos.

---

## 2. Módulos y dependencias

| Módulo | Cambio | Depende de |
|---|---|---|
| `GPOS.Contracts` | DTO de 5.2 y los códigos `CodigosRestauracion` | — |
| `GPOS.Core` | Servicio nuevo `RestauracionSitioService` (Servicios); consultas en `Consultas/Sitio/ConsultasRestauracion.cs` (Dapper, `varchar` con largo según ADR-50); `DocumentosNg.ExigirPuedeEmitirAsync` lee el fork por la vista; mensaje de 51330 para la empresa de una sola base | Contracts; EF (`EmpresaNgDbContext`); los procedimientos de la sección 10 |
| `GPOS.Api` | `RestauracionEndpoints.cs` (sección 5) | Core |
| `GPOS.Web` y `GPOS.UI.MAUI` | Componente `RestauracionSitio.razor` en `Components/Compartidos` (una copia en cada interfaz, como `DiagnosticoNumeracion.razor`), insertado en la pestaña Diagnóstico de `Pages/Admin/Numeracion.razor:102-103`; métodos en `INumeracionCliente`, `ApiClient.Numeracion.cs` y `NumeracionClienteSimulado.cs` | API |
| `GPOS.Migracion` | DM-02 (`Program.cs`) y DM-03 (`Aprovisionamiento.cs`) | Core |
| Base de empresa | La migración `H11DesbloqueoRestauracion`, después de `Ola4BusquedaSinTildes` (sección 10) | — |

Sin ciclos: la dirección sigue siendo Api → Core → Contracts, Web/MAUI → Contracts. **No hay proyectos nuevos.**

---

## 3. C4

No aplica en los niveles de contexto y contenedores, porque no cambian. Componente:

```
[Web/MAUI: RestauracionSitio.razor] --HTTPS/JWT--> [Api: RestauracionEndpoints] --> [Core: RestauracionSitioService]
      |                                                                                 |  una SqlTransaction (XACT_ABORT)
      |                                                                                 +--> EXEC sync.usp_AbrirReconciliacionLocal      (EXECUTE AS OWNER)
      |                                                                                 +--> num.Serie / sync.ReconciliacionSerie        (gpos_app)
      |                                                                                 +--> fiscal.SecuenciaNcf / sync.ReconciliacionNcf / fiscal.NcfZonaIncierta
      |                                                                                 +--> audit.Bitacora (+ _LOG por PuenteCfg)
      |                                                                                 +--> EXEC sync.usp_ConfirmarReconciliacionLocal  (EXECUTE AS OWNER)
[GPOS.Migracion verificar] --lee--> sync.EstadoNodo + sys.database_recovery_status --> código de salida 3
```

---

## 4. Modelo de dominio

### 4.1 Estados del sitio, tal como los ve el servicio

| Estado | Condición | Acción disponible |
|---|---|---|
| `NORMAL` | Fork actual = fork registrado y `EmisionBloqueada = 0` | Ninguna |
| `RESTAURADA` | Fork actual ≠ fork registrado (o fork nulo), **o** `EmisionBloqueada = 1` con `MotivoBloqueo = 'RESTAURACION'` | Desbloquear (SUPER) |
| `BLOQUEADA_OTRA_CAUSA` | `EmisionBloqueada = 1` con otro motivo (`MANUAL`, `HUECO_SECUENCIA`, `APROVISIONAMIENTO`) | Ninguna aquí |
| `REQUIERE_CENTRAL` | `RESTAURADA` y existe otro nodo en `sync.Nodo` con `Local = 0` e `Inhabilitado = 0` | Ninguna en la entrega 1 (cláusula 9, nodo o RN-23) |
| `SIN_IDENTIDAD` | No hay fila en `sync.EstadoNodo` | Ninguna; avisar que se ejecute `GPOS.Migracion actualizar` |

**Decisión D-1:** se permite con `RolSitio.Ambos` **y** con `RolSitio.Central` sin otros nodos activos (`Sitio.cs:6-14`). En la entrega 1 una «central» sin nodos es, de hecho, una base única: la condición se decide por los datos y no por la configuración. *Alternativa descartada:* solo `Ambos`. Rechazaría una instalación configurada como `Central` que no tiene nodos, sin ganancia de seguridad.

### 4.2 Agregado «Reconciliación local» (`sync.Reconciliacion` y sus filas hijas)

- **Causa** (`varchar(30)`): `RESTAURACION` si alguna secuencia tiene diferencias; `TRASLADO` si ninguna la tiene (RN-04). Se confirma igual en los dos casos.
- **ForkAnterior** = `ForkRegistrado`; **ForkActual** = el de la base.
- **Estado:** nace en `L` (lista para confirmar) y termina en `C` (confirmada) **en la misma transacción**. Nunca pasa por `R`, para no abrir la excepción de reaplicación de los disparadores.
- **Una fila de `ReconciliacionNcf` por cada secuencia vigente** (`Estado` `A` o `R`), aunque no cambie: es la prueba de que se revisó.
- **Una fila de `ReconciliacionSerie` por cada serie adelantada.**

### 4.3 Invariantes (las comprueban el servicio y la base)

- **I-1. Ningún NCF retrocede.** Para cada secuencia vigente, `UltimoProbado ≥ UltimoEmitidoEnBase` (si la base no emitió, `≥ Desde − 1`), y `UltimoProbado ≤ Hasta`.
- **I-2. Corte.** `Corte = UltimoProbado` (+ un margen voluntario si se firma P-1). Con `Corte > UltimoEmitidoEnBase`, el bloque se cierra en `X` con `Hasta = Corte` y la porción `Corte + 1 … Hasta` original se registra como secuencia nueva, con los mismos tipo, punto, prefijo, dígitos, autorización, vencimiento y estado (`A` o `R`). Si `Corte = Hasta`, solo se cierra.
- **I-3. Sin diferencias.** Con `Corte = UltimoEmitidoEnBase`, la secuencia no se toca. Numéricamente es igual que cerrar y continuar en `Corte + 1`; así se evita una secuencia sin necesidad.
- **I-4. H-12.** La porción `X` nunca se reasigna: 51325 y 51324 (disparador existente) la protegen. El `UPDATE` que cierra pasa por 51326 porque `Hasta = Corte ≥ Siguiente − 1`, que está **verificado** contra el texto del disparador (`SqlMigracionesOla3.cs:396-398`).
- **I-5. Zona incierta.** Si `Corte > UltimoEmitidoEnBase`, se inserta `fiscal.NcfZonaIncierta(SecuenciaId = cerrada, Desde = UltimoEmitidoEnBase + 1, Hasta = Corte, Causa = 'RESTAURACION', Estado = 'P', Evidencia, Referencia, ReconciliacionId)`. Son los NCF emitidos después del respaldo, que hay que reconstruir (RN-16).
- **I-6. Series (RN-12).** `SiguienteNuevo = Siguiente + Margen`, con `Margen = MAX(MargenMinimoSerie, ⌈1,5 × emisión diaria máxima de la serie en los 30 días previos al último momento conocido × días inciertos⌉)`.
  - **Último momento conocido** = el mayor entre `doc.Documento.CreadoEn` y `audit.Bitacora.FechaHora` de la base. *Inferido:* es una aproximación al punto del respaldo sin permisos en `msdb`, la misma razón por la que el arquitecto-datos descartó `restorehistory` (modelo de datos de H0, 6.1).
  - **Días inciertos** = `⌈(ahora − último momento) en días⌉`, con un mínimo de 1.
  - **Series:** todas las de clase `DOC` y la serie `MAE` de clientes (RN-12; la pregunta P-2 trata las demás).
  - **Emisión diaria:** en las series `DOC`, documentos por `SerieId` y `Fecha`; en la de clientes, `cat.Cliente.CreadoEn` por día.
  - Si `SiguienteNuevo` no cabe en los dígitos de la serie, el desbloqueo responde 422 `SERIE_SIN_CAPACIDAD` y no hace nada. *Inferido* como improbable (8 dígitos); el desarrollador verifica si puede reutilizar el paso a subserie del modelo nuevo antes de rechazar.
- **I-7. Completitud.** No se confirma si falta una fila de `ReconciliacionNcf` para alguna secuencia vigente o una fila de `ReconciliacionSerie` para alguna serie del alcance de I-6. Lo comprueba el procedimiento de confirmación (sección 10).
- **I-8. Solo con restauración.** El procedimiento de apertura falla si el estado no es `RESTAURADA` (sección 4.1). Es la defensa contra el uso indebido: ver la sección 8.

### 4.4 Eventos de dominio (bitácora, `audit.Bitacora`, en la transacción)

`Accion` cabe en 40 caracteres (`Bitacora.cs:25`) y `Motivo`, en 200.

| Accion | Cuándo | Detalle (JSON ≤ 4000 B) |
|---|---|---|
| `NODO_RESTAURACION_DETECTADA` | Al abrir | Forks anterior y actual, último momento conocido, días inciertos |
| `NCF_BLOQUE_CERRADO_RESTAURACION` | Una línea por bloque cerrado | Secuencia, prefijo, desde, último en la base, corte, hasta original, evidencia, referencia |
| `NCF_BLOQUE_ASIGNADO` | Una línea por bloque nuevo | Id nuevo, rango, vencimiento |
| `SERIE_ADELANTADA_RESTAURACION` | Una línea por serie | Serie, siguiente anterior, margen, siguiente nuevo |
| `NODO_RECONCILIACION_CONFIRMADA` | Al confirmar | `ReconciliacionId`, causa, conteos y **Motivo** en la columna `Motivo` |
| `NODO_EMISION_DESBLOQUEADA` | Al confirmar, inmediatamente después | `ReconciliacionId` |

Las tablas `sync.Reconciliacion*` son la fuente completa; la bitácora es el resumen legible, partido por líneas para no truncarse.

---

## 5. Contratos de la API interna

Grupo: `/api/admin/sitio/restauracion`, `.Sitio(OperacionSitio.SoloCentral)`, etiqueta «Administración». **Aislamiento:** opera solo sobre la base de la empresa de la sesión, por `IEmpresaDbFactory`; ninguna ruta recibe el código de empresa, como `NumeracionEndpoints.cs:7-8`. Sin el esquema aplicado: 503 `ESQUEMA_PENDIENTE` (patrón existente). Errores con `ProblemDetails` y la extensión `codigo`.

### 5.1 Rutas

| # | Método y ruta | Permiso | Respuesta |
|---|---|---|---|
| R1 | `GET /api/admin/sitio/restauracion` | `RequiereAdmin()` (ADMIN o SUPER; el ADMIN ve el estado para avisar) | 200 `EstadoRestauracionDto` |
| R2 | `POST /api/admin/sitio/restauracion/vista-previa` | `RequiereSuper()` | 200 `PlanDesbloqueoDto`. **Siempre 200**: los problemas van en `Errores`, como E3 de numeración. Solo lee |
| R3 | `POST /api/admin/sitio/restauracion/desbloquear` | `RequiereSuper()`; además `RequireRateLimiting(LimitesPeticiones.Reportes)` (inferido como suficiente) | 200 `ResultadoDesbloqueoDto` |

**H-13:** mientras el ADMIN sea global, R2 y R3 son **solo del SUPER**, como el modo por sucursal (`NumeracionEndpoints.cs:41-44`). **No** se agrega la opción a `Permisos.Todos`: `Permisos.cs:44-45` concede todo al ADMIN y a cualquier perfil al que se asigne. El privilegio «Reconciliar nodo restaurado» (grupo fiscal de Administración) nace con la versión 1 del acceso multiempresa, en una tarea V1-H13 que devuelve la acción al ADMIN de la empresa.

### 5.2 DTO (`GPOS.Contracts/Admin/Restauracion.cs`)

```csharp
public sealed record EstadoRestauracionDto(
    string Estado,                       // NORMAL | RESTAURADA | BLOQUEADA_OTRA_CAUSA | REQUIERE_CENTRAL | SIN_IDENTIDAD
    Guid? ForkRegistrado, Guid? ForkActual,
    DateTime? UltimoMomentoConocidoUtc, int DiasInciertos, int MargenMinimoSerie,
    IReadOnlyList<SecuenciaRestauracionDto> Secuencias,   // vacías salvo en RESTAURADA
    IReadOnlyList<SerieRestauracionDto> Series,
    string Huella);                      // token de concurrencia (SHA-256 del fork actual y de Id+Siguiente+Version de secuencias y series)

public sealed record SecuenciaRestauracionDto(
    int SecuenciaId, string TipoComprobante, string? TipoDescripcion, string PuntoEmision, string Prefijo, byte Digitos,
    long Desde, long Hasta, long Siguiente, long? UltimoEmitidoEnBase, string? UltimoNcfEnBase,
    bool Electronica, DateTime? FechaVencimiento, bool Vencida, string Estado /* A | R */);

public sealed record SerieRestauracionDto(
    int SerieId, string Clase, string TipoCodigo, string? Sucursal, string Prefijo,
    long SiguienteActual, int EmisionDiariaMaxima, int Margen, long SiguienteNuevo);

public sealed record DesbloqueoRestauracionRequest(
    string Huella, string Motivo, IReadOnlyList<UltimoProbadoDto> Secuencias);

public sealed record UltimoProbadoDto(
    int SecuenciaId,
    string? UltimoNcfProbado,   // NCF completo (B + 10 o E + 12); null = «esta secuencia no emitió nada» (válido solo si la base tampoco)
    string Fuente,              // DIARIO | PROVEEDOR | PAPEL
    string Referencia);         // 5..100: qué evidencia se consultó (p. ej., «Consulta al proveedor, 2026-10-10 15:20, lote 77»)

public sealed record PlanDesbloqueoDto(
    string Causa /* RESTAURACION | TRASLADO */, IReadOnlyList<PlanSecuenciaDto> Secuencias,
    IReadOnlyList<SerieRestauracionDto> Series, IReadOnlyList<string> Avisos, IReadOnlyList<string> Errores);

public sealed record PlanSecuenciaDto(
    int SecuenciaId, string Prefijo, string Accion /* SIN_CAMBIO | CERRAR_Y_CONTINUAR | CERRAR_AGOTADA */,
    long? HastaCerrado, long? NuevoDesde, long? NuevoHasta, long? ZonaDesde, long? ZonaHasta);

public sealed record ResultadoDesbloqueoDto(
    int ReconciliacionId, string Causa, IReadOnlyList<PlanSecuenciaDto> Secuencias,
    IReadOnlyList<SerieRestauracionDto> Series, IReadOnlyList<string> Avisos);
```

### 5.3 Validaciones (R2 las informa en `Errores`; R3 responde 422 `VALIDACION` con la lista)

1. `Motivo`: obligatorio, de 15 a 200 caracteres después de recortar (`Reconciliacion.Motivo` y `Bitacora.Motivo` son de 200).
2. `Secuencias` cubre **exactamente** las secuencias vigentes que ve R1: sin faltantes, sin repetidas y sin secuencias que no estén vigentes.
3. `UltimoNcfProbado`:
   - el prefijo es el de la secuencia y los dígitos coinciden;
   - el número cumple I-1;
   - null solo si `UltimoEmitidoEnBase` es null.
4. `Fuente` ∈ {`DIARIO`, `PROVEEDOR`, `PAPEL`} (valores de `CK_NcfZonaIncierta_Evidencia`, sin `CENTRAL`). En secuencias `E`, **solo `PROVEEDOR`** (opción por omisión de P-5, RN-20).
5. `Referencia`: de 5 a 100 caracteres (largo de `NcfZonaIncierta.Referencia`).
6. **Avisos** (no bloquean):
   - un tipo queda sin secuencia vigente: «registre un rango nuevo; mientras tanto, ese tipo de comprobante no se podrá emitir». No se sugiere «No generar comprobante» (regla del 2026-10-02);
   - la porción nueva hereda un vencimiento ya pasado: **no se crea**, y el aviso lo explica;
   - es una restauración (días inciertos > 0) y **todas** las secuencias están sin diferencias: «Confirme que la evidencia cubre hasta hoy».

### 5.4 Códigos de error

| HTTP | `codigo` | Causa |
|---|---|---|
| 401 / 403 | — | Sin sesión, o sin ser SUPER en R2 y R3 (o sin ser ADMIN en R1) |
| 409 | `SITIO_NO_RESTAURADO` | El estado no es `RESTAURADA` (I-8). Lo comprueba el servicio y lo **vuelve a comprobar** el procedimiento (51328) |
| 409 | `REQUIERE_RECONCILIACION_CENTRAL` | Hay otros nodos activos (entrega 2) |
| 409 | `RESTAURACION_ESTADO_CAMBIO` | La `Huella` no coincide: cambió el fork, una secuencia o una serie después de R1 |
| 422 | `VALIDACION` | Sección 5.3 |
| 422 | `SERIE_SIN_CAPACIDAD` | I-6 |
| 503 | `ESQUEMA_PENDIENTE` | Falta la migración `H11DesbloqueoRestauracion` |
| 500 | — | 51329 (confirmación incompleta, I-7): es un **defecto del programa** y se registra como error, no se traduce para el usuario |

Los errores del motor se traducen en `ErroresNumeracion` (51328 → 409 y 51329 → 500), sin nombres de objetos.

### 5.5 Cambio en la guarda de emisión

- `ExigirPuedeEmitirAsync` lee también `Restaurada` de la vista ampliada (sección 10) y lanza el 503 `EMISION_BLOQUEADA_RECONCILIAR` **antes** de tomar la serie y el NCF.
- **Mensaje nuevo** cuando no hay otros nodos (texto definitivo del especialista-pos y del diseñador UX): «La base de datos de la empresa se restauró desde un respaldo y no puede facturar hasta que el Super Usuario la desbloquee. La operación no se guardó. Avise al administrador.»
- Se conserva el texto actual («…con la central») para cuando existan nodos.

---

## 6. Interfaces entre módulos

```csharp
// GPOS.Core/Servicios/RestauracionSitioService.cs
public sealed class RestauracionSitioService(IEmpresaDbFactory factory, ISesionActual sesion, IGuardaSitio guarda)
{
    Task<EstadoRestauracionDto> EstadoAsync(CancellationToken ct);
    Task<PlanDesbloqueoDto> VistaPreviaAsync(DesbloqueoRestauracionRequest req, CancellationToken ct);   // solo lee
    Task<ResultadoDesbloqueoDto> DesbloquearAsync(DesbloqueoRestauracionRequest req, CancellationToken ct);
}
```

- El cálculo del plan es una **función pura** (`PlanDesbloqueo.Calcular(estado, request, hoy)`), compartida por R2 y R3 y probada sin base.
- `Aprovisionamiento.VerificarAsync` no cambia de firma. `EstadoBase` gana `bool EmisionBloqueada` y `string? MotivoBloqueo`, que se leen de la vista, para el informe de `verificar`.

### 6.1 Flujo de `DesbloquearAsync` y atomicidad

Una conexión y **una `SqlTransaction`** con `SET XACT_ABORT ON`, en `READ COMMITTED`. La base tiene RCSI (MD-11), así que toda lectura de algo que se va a cambiar lleva `UPDLOCK, HOLDLOCK` o `READCOMMITTEDLOCK`. Los pasos siguen el **orden firmado de bloqueos: configuración → series → NCF**:

1. `guarda.Exigir(SoloCentral)`.
2. `EXEC sync.usp_AbrirReconciliacionLocal @Usuario, @UsuarioId` (nivel **configuración**). El procedimiento:
   - bloquea `sync.EstadoNodo` con `UPDLOCK, HOLDLOCK`;
   - comprueba I-8 y que no haya otros nodos activos;
   - inserta `sync.Reconciliacion` (`Estado` `L`, `NodoId` 1, `DetectadaEn`, `Causa` provisional `RESTAURACION`, forks);
   - fija `EstadoNodo.EmisionBloqueada = 1`, `MotivoBloqueo = 'RESTAURACION'`, `BloqueadaDesde` y `ReconciliacionId`;
   - devuelve el `Id`.

   Las emisiones concurrentes leen la vista con `HOLDLOCK` en el mismo nivel, así que esperan o fallan sin interbloqueo.
3. Recalcula la `Huella` con las lecturas ya bloqueadas. Si difiere: `THROW` → 409 `RESTAURACION_ESTADO_CAMBIO`, y se deshace todo.
4. **Series:** `num.Serie` con `UPDLOCK` en orden ordinal de `Id`; `UPDATE Siguiente`; `INSERT sync.ReconciliacionSerie`; una línea de bitácora por serie.
5. **NCF:** `fiscal.SecuenciaNcf` vigentes con `UPDLOCK` en orden de `Id`. Para cada una:
   - `SIN_CAMBIO`: solo `INSERT sync.ReconciliacionNcf` (zona nula);
   - `CERRAR_*`: `UPDATE Estado = 'X', CerradoEn, Hasta = Corte, ModificadoPor`; después el `INSERT` del bloque nuevo, si corresponde; luego `INSERT ReconciliacionNcf` (con `BloqueNuevoId`, `UltimoConocido = Corte`, zona, evidencia y referencia) y `INSERT fiscal.NcfZonaIncierta` (I-5); bitácora.

   El `UPDATE` va **antes** del `INSERT` para que 51324 no vea un solape.
6. `EXEC sync.usp_ConfirmarReconciliacionLocal @Id, @Usuario, @UsuarioId, @Motivo, @Causa`. El procedimiento:
   - comprueba que el fork actual sigue siendo `ForkActual` de la reconciliación (otra restauración en medio → 51328);
   - comprueba I-7;
   - pone `Reconciliacion` en `Estado = 'C'` con `ConfirmadaPor`, `ConfirmadaPorId`, `ConfirmadaEn`, `Motivo` y `Causa`;
   - en `EstadoNodo`: `ForkRegistrado` = fork actual, `EmisionBloqueada = 0`, `MotivoBloqueo` y `BloqueadaDesde` nulos, y `ReconciliacionId` = `Id`.
7. Bitácora `NODO_RECONCILIACION_CONFIRMADA` y `NODO_EMISION_DESBLOQUEADA`. **Commit.**

Cualquier error deshace todo: no queda la reconciliación a medias, ni un bloque `X` sin su sucesor, ni el fork registrado sin cierres. Un segundo `POST` concurrente espera en el paso 2 y, al seguir, encuentra el fork igual: 409 `SITIO_NO_RESTAURADO`. **Es idempotente por construcción.**

**Volumen y tiempo (inferido):** decenas de secuencias y de 30 a 80 series; unas 200 sentencias; menos de 1 s en Express. Las cajas no pueden emitir durante ese tiempo de todos modos.

---

## 7. Estructura de proyectos y carpetas

```
src/GPOS.Contracts/Admin/Restauracion.cs                       (DTO + CodigosRestauracion)
src/GPOS.Core/Servicios/RestauracionSitioService.cs
src/GPOS.Core/Servicios/Modulos/Sitio/PlanDesbloqueo.cs        (función pura)
src/GPOS.Core/Consultas/Sitio/ConsultasRestauracion.cs         ([ConsultaRegistrada], varchar con largo)
src/GPOS.Core/Datos/Empresa/Migraciones/2026101xxxxxxx_H11DesbloqueoRestauracion.cs  + SqlMigracionesH11.cs
database/empresa/gpos-empresa-2026101xxxxxxx_H11DesbloqueoRestauracion.sql   (generado, como los anteriores)
src/GPOS.Api/Endpoints/RestauracionEndpoints.cs                (+ MapRestauracion en Program.cs)
src/GPOS.Web/Components/Compartidos/RestauracionSitio.razor     (+ ApiClient/INumeracionCliente/Simulado)
GPOS.UI.MAUI/Components/Compartidos/RestauracionSitio.razor     (copia; mismo patrón que DiagnosticoNumeracion)
tests/GPOS.Tests/ModeloNg/DesbloqueoRestauracionTests.cs
tests/GPOS.Web.Tests/… y tests/GPOS.UI.MAUI.Tests/… (bUnit de los estados)
```

Se cumple la convención `GPOS.{Área}` y ningún proyecto es nuevo.

### 7.1 Pantalla mínima: tarjeta «Restauración de la base» en Diagnóstico

Va arriba de `DiagnosticoNumeracion` y se carga al abrir la pestaña: R1 solo lee y es barato.

| Estado | Qué ve | Acciones |
|---|---|---|
| Cargando | Indicador | — |
| `NORMAL` | Una línea en verde: «La base no se ha restaurado; la emisión está habilitada.» | — |
| `RESTAURADA`, usuario ADMIN | Alerta roja: «La base se restauró desde un respaldo y no puede facturar. Solo el Super Usuario puede desbloquearla.» | — |
| `RESTAURADA`, usuario SUPER | Alerta roja, más tres bloques: (1) **secuencias vigentes**, con el último NCF de la base y tres campos por fila: «Último NCF probado», «Fuente» (lista) y «Referencia de la evidencia»; un botón «Igual al de la base» solo copia el valor y no salta la fuente; (2) **series** (solo lectura): siguiente actual → nuevo y margen; (3) **resumen del último momento conocido y de los días inciertos** | «Vista previa» (R2) |
| Vista previa | Tabla del plan: «Sin cambio», o «Se cierra B0200000001–B0200000150; nueva secuencia 151–1000; por revisar (zona incierta) 121–150», más los avisos y errores | «Corregir», o «Desbloquear…» (deshabilitado si hay errores) |
| Diálogo de confirmación | Resumen del plan; campo **Motivo** obligatorio (15 a 200); casilla «Verifiqué la evidencia de cada secuencia y entiendo que los bloques cerrados no se vuelven a usar» | «Confirmar desbloqueo» (R3) y «Cancelar» |
| Resultado | Alerta verde con el número de la reconciliación y la lista de lo cerrado y lo creado; recarga R1, que pasa a `NORMAL` | — |
| 409 `RESTAURACION_ESTADO_CAMBIO` | «Los datos cambiaron mientras revisaba. Se recargaron; revise de nuevo.» | Recarga |
| 409 `REQUIERE_RECONCILIACION_CENTRAL` / `BLOQUEADA_OTRA_CAUSA` / `SIN_IDENTIDAD` | Texto informativo, sin formulario | — |

Accesibilidad: `role="alert"` y `aria-live`, como el diagnóstico existente. **El texto definitivo es del diseñador UX.**

---

## 8. Requisitos de seguridad de arquitectura

- **Autenticación:** JWT de usuario actual (HS256; ES256 cuando se implemente ADR-41). No se aceptan tokens de dispositivo, porque las rutas no declaran `RequiereDispositivo`.
- **Autorización:**
  - R1 con `RequiereAdmin`; R2 y R3 con `RequiereSuper` (H-13);
  - el servicio **vuelve a comprobar** que la sesión es SUPER (defensa en profundidad, como `SincronizarEspejoAsync`);
  - sin privilegio asignable hasta la V1.
- **Aislamiento entre empresas:** solo la base de la empresa de la sesión. El SUPER es global, así que el motivo y la bitácora de esa base registran en qué empresa actuó.
- **Privilegio mínimo en SQL:** la aplicación (`gpos_app`) sigue **sin** escribir `sync.EstadoNodo` ni `sync.Reconciliacion` (se mantienen los DENY). Solo puede ejecutar los dos procedimientos `EXECUTE AS OWNER`, que validan I-7 e I-8 por su cuenta. Es el patrón de `sync.usp_AdelantarSecuencias` (`SqlMigracionesOla3.cs:605-645`).
- **Uso indebido:**
  - **Sin restauración no hay desbloqueo:** lo impiden el servicio (409) y el procedimiento (51328). No sirve para «limpiar» un bloqueo `MANUAL` ni `HUECO_SECUENCIA`.
  - **Nada de reasignar NCF:** I-1 impide bajar del último emitido en la base. Los bloques `X` son inmutables (51325) y no se solapan (51324). La pantalla de secuencias nunca reabre un `X`.
  - **Sin repetición ni carreras:** la huella, el bloqueo de configuración y la comprobación del fork en la confirmación.
  - **Riesgo residual aceptado al firmar H-11:** un SUPER que declara un último NCF menor que el real duplicaría NCF. Lo mitigan la evidencia obligatoria con su referencia, el motivo, la bitácora de solo inserción y la revisión del contador sobre la zona incierta. **Medio** sin diario electrónico (H-14 no construido) y **Bajo** con él.
- **Auditoría:** la bitácora de la sección 4.4 en la misma transacción (`RegistroBitacora.Registrar`, que escribe además `_LOG` por `PuenteCfg`), y las tablas `sync.Reconciliacion*` con quién, cuándo y por qué.
- **Secretos:** no hay secretos nuevos. Los forks no son secretos, y en la interfaz se muestran abreviados.
- **Superficie que ya existe:** `Aprovisionamiento.RegistrarSitioAsync(registrarSiExiste: true)` (`Aprovisionamiento.cs:233`) reescribiría el fork sin controles. Es pública «para las pruebas» y ningún comando de la consola la usa (verificado: los llamadores pasan `false`). **Recomendación:** dejarla `internal`, con `InternalsVisibleTo` para las pruebas, para que nadie la convierta en un atajo.

---

## 9. Sincronización

No aplica: no hay central (H-11). Cuando exista la entrega 2, el estado `REQUIERE_CENTRAL` impide usar este camino en una empresa con nodos.

---

## 10. Necesidades para Datos e Integraciones

**Arquitecto-datos** (migración `H11DesbloqueoRestauracion`, después de `Ola4BusquedaSinTildes`; SQL idempotente; parámetros `varchar` con el largo de la columna según ADR-50):

1. **Vista `sync.EstadoEmision`:** agregar `Restaurada bit` (fork actual nulo o distinto, para fallar cerrada), `ForkRegistrado`, `ForkActual`, `ReconciliacionId` y `HayOtrosNodos bit`. Las columnas existentes no cambian (`ConsultasDocumentos.EstadoEmision` las lee por nombre).
2. **`sync.ReconciliacionNcf`:** columnas `Evidencia varchar(10) NULL`, con el `CHECK` de `CK_NcfZonaIncierta_Evidencia`, y `Referencia varchar(100) NULL`.
3. **`sync.usp_AbrirReconciliacionLocal`** y **`sync.usp_ConfirmarReconciliacionLocal`**, con `EXECUTE AS OWNER`, `XACT_ABORT` y la semántica del paso 2 y del paso 6 de la sección 6.1; `GRANT EXECUTE` a `gpos_app`. Errores propuestos (libres, verificado): **51328** (sitio no restaurado, otros nodos o cambio de fork) y **51329** (confirmación incompleta). El número final lo asigna el arquitecto-datos.
4. Opcional: `CHECK` de `sync.Reconciliacion.Causa` (`RESTAURACION`, `TRASLADO`, más los de la entrega 2).
5. Confirmar que `gpos_app` puede `INSERT` en `sync.ReconciliacionNcf` y `sync.ReconciliacionSerie` (hoy por `GRANT … ON SCHEMA::sync`, `SqlMigraciones.cs:45`, sin DENY específico; *verificado en el texto*, por probar).
6. Si se firma P-3: usar `sync.ReconciliacionChequera`, que ya existe; no requiere esquema nuevo.
7. Precisar en su documento el caso de la base única: el cierre **recorta `Hasta` al corte** (H-11), a diferencia del nodo, que conserva el `Hasta` (modelo de datos de H0, 6.3). Los disparadores existentes ya lo admiten (I-4).

**Arquitecto-integraciones:** nada para construir. Una nota: con un proveedor de e-CF dueño de la secuencia (RN-22), la «última e-NCF probada» se consulta al proveedor a mano. La consulta automática (RN-08 y RN-20) queda para un conector, sin tocar el núcleo (ADR-73.7).

---

## 11. Riesgos

| Id | Riesgo | Prob. / impacto | Mitigación |
|---|---|---|---|
| R-1 | Último NCF declarado menor que el real: NCF duplicado | Media sin H-14 / alto | Evidencia, referencia y motivo obligatorios; bitácora; diario electrónico H-14 antes del primer cliente (`cierre-h0.md:101`); P-1 |
| R-2 | Revertir a un paquete **anterior a H-11** con su respaldo deja la base bloqueada sin vía de desbloqueo (el programa viejo no la tiene) | Alta solo al cruzar esa frontera / alto | Regla de operación: desde H-11, no revertir a versiones previas. En el DEMO, lo que recomienda C (reinstalar el paquete del 2026-10-07). Hacia adelante, cada versión trae su desbloqueo |
| R-3 | Secuencias registradas **después** del respaldo desaparecen al restaurar y, si se vuelven a registrar desde su primer número, se repiten los NCF | Baja / alto | La tarjeta lo indica: «Si registró rangos NCF después del respaldo, regístrelos antes de desbloquear; aparecerán aquí para indicar su último NCF probado». La pantalla de secuencias permite registrarlos con la emisión bloqueada (`GuardarSecuenciaAsync` no pasa por la guarda) |
| R-4 | Las secuencias de llave vuelven atrás (modelo de datos de H0, 6.3). En la base única no chocan dentro de la base, pero los `Id` perdidos pudieron quedar en referencias externas (JSON del e-CF en IQ, adjuntos futuros, ERP) | Baja hoy / medio | Fuera de H-11. Candidato: llamar a `sync.usp_AdelantarSecuencias` con un margen en el mismo desbloqueo (+0,05 sp); lo decide el arquitecto-datos con la entrega 2 |
| R-5 | Cheques ya impresos se vuelven a proponer (`banco.Chequera.Siguiente` retrocede) | Baja / alto | P-3 |
| R-6 | El grupo de conexiones de la API conserva conexiones a la base anterior a la restauración | Media / bajo | Guía de devops: detener la API, restaurar e iniciarla. Ya figura en el ensayo |
| R-7 | El «último momento conocido» es una aproximación: subestima los días inciertos si la base quedó inactiva antes del respaldo | Baja / bajo | El margen mínimo es 100; el SUPER ve la fecha y los días antes de confirmar |
| R-8 | `Iniciar-Demo.ps1` (fuera del repositorio, DM-05) interpreta «al día» por el texto y no por el código de salida | Media / bajo | Entrega a devops |

### 11.1 Decisiones del arquitecto (candidatas a ADR o a precisión de ADR-53, cláusula 9)

- **D-1.** El desbloqueo se permite con `Ambos` y con `Central` sin otros nodos (sección 4.1).
- **D-2.** Para la base única, el cierre recorta `Hasta` al corte y continúa en una secuencia nueva (texto literal de H-11). Las secuencias sin diferencias no se tocan (I-3).
  - *Alternativa descartada:* cerrar el bloque completo. En la base única el bloque suele ser todo el rango de la DGII, y la empresa quedaría sin NCF hasta una autorización nueva.
- **D-3.** **No hay subcomando de desbloqueo en `GPOS.Migracion`.**
  - Duplicaría lógica fiscal fuera de la API.
  - Correría con la identidad de esquema, sin la autorización del SUPER y con un usuario de Windows en la bitácora.
  - No resuelve R-2, porque el esquema viejo no tiene los procedimientos.
  - `verificar` solo detecta y orienta.
  - *Alternativa descartada:* el subcomando `reconciliar` (+0,15 sp, inferido).
- **D-4.** La transacción es única y el estado intermedio `L` nunca se confirma; las escrituras privilegiadas solo pasan por los procedimientos `EXECUTE AS OWNER`.
  - *Alternativa descartada:* un procedimiento único con toda la lógica en T-SQL. Saca las reglas fiscales del servicio y complica las pruebas.
- **D-5.** La guarda del servicio compara también el fork (vista ampliada): falla cerrada antes de tomar números.

### 11.2 DM-02 y DM-03

**DM-02** (`Program.cs:63-71`):
- Códigos de salida de `verificar`: **0** al día y sin restaurar; **2** con migraciones pendientes; **3** RESTAURADA, con o sin pendientes; **1** error. Con varias bases (`--todas` o sin opciones) gana el más grave: 1 > 3 > 2 > 0. Hoy cada base sobrescribe el código anterior, así que el de la última base tapa los demás (`Program.cs:71,80`).
- El texto agrega «emisión bloqueada: sí o no (motivo)» y, si está RESTAURADA, la orientación: «desbloquéela desde Numeración > Diagnóstico con el Super Usuario».
- Se actualizan la ayuda (`Program.cs:163-170`) y la cabecera de comentarios (`:7-9`).

**DM-03** (`Aprovisionamiento.cs:113-117` en esta rama; C citó 108-112 desde otra):
- Con AUTO_CLOSE activo y la base cerrada, `DATABASEPROPERTYEX(@n, 'Collation')` leído **desde `master`** devuelve NULL, y el aviso sale con la intercalación vacía.
- **Corrección:** leer la intercalación con la conexión a la propia base, como ya hace `VerificarAsync` (`:142`), lo que además abre la base; o, si es NULL, no avisar y decir «no se pudo leer».
- La misma lectura en `CrearAsync` (`:69-70`) haría un `ALTER … COLLATE` innecesario sobre una base vacía cerrada: se corrige igual.
- DM-04 (AUTO_CLOSE OFF) queda para el arquitecto-datos.

---

## 12. Preguntas para el propietario (no se inventan; cada una trae la opción por omisión del diseño)

- **P-1. Margen voluntario después del último NCF probado.** H-11 dice cerrar «en el último NCF probado» y H-12 descartó un margen dentro del bloque para el nodo. ¿Se permite que el SUPER agregue un hueco voluntario (de 0 a N) entre el último probado y la secuencia nueva, que iría a la zona incierta como «no usado»?
  - *Por omisión:* margen 0, el texto literal.
  - *Recomendación:* permitirlo opcional cuando la fuente sea `PAPEL`.
- **P-2. Series de maestros.** RN-12 adelanta «documentos y clientes». ¿Se adelantan también los códigos de suplidores y de artículos?
  - *Por omisión:* no; los huecos se verían en los códigos de artículo sin beneficio fiscal.
- **P-3. Chequeras.** Al restaurar, `banco.Chequera.Siguiente` retrocede (modelo de datos de la ola 4, 3.5 y 8). ¿Se incluye en este desbloqueo la confirmación del primer cheque en blanco de cada cuenta (la tabla ya existe; +0,1 sp, inferido), o se deja como paso manual de la guía hasta la entrega 2?
  - *Recomendación:* incluirla.
- **P-4. Traslado planificado.** Cuando ninguna secuencia tiene diferencias, ¿se adelantan igual las series (texto literal de H-11), o el traslado confirma sin adelantarlas?
  - *Por omisión:* se adelantan, con un mínimo de 100 y sin efecto fiscal.
- **P-5. Evidencia del e-CF.** ¿Se exige que en las secuencias `E` la fuente sea solo el proveedor (RN-20), o también se acepta el papel (la representación impresa)?
  - *Por omisión:* solo el proveedor.
- **P-6. Zona incierta en la entrega 1.** Los reportes 606, 607 y 608 están aplazados (los lleva el ERP) y no hay pantalla para reconstruir o anular. ¿Basta en la entrega 1 con registrar la zona en `fiscal.NcfZonaIncierta` (estado P), mostrarla en solo lectura en la tarjeta y entregar una guía al contador?
  - *Por omisión:* sí.

---

## 13. Pruebas de aceptación

Infraestructura: `tests/GPOS.Tests`, con bases `GPOS_TEST_H11_*` en `GPOST_TEST_SERVER`, creadas y borradas por `BasesNgPrueba`. Nunca dos suites completas a la vez.

**Restauración real** (como en el ensayo de C y en el guion de H0, `docs/datos/scripts/2026-10-04-h0-pruebas-entrega1.sql:588-600`):
- `BACKUP DATABASE … TO DISK = <SERVERPROPERTY('InstanceDefaultBackupPath')>\GPOS_TEST_H11_<guid>.bak WITH COPY_ONLY, INIT, CHECKSUM`;
- emitir;
- `SINGLE_USER WITH ROLLBACK IMMEDIATE`, `RESTORE … WITH REPLACE` y `MULTI_USER`;
- `SqlConnection.ClearPool`;
- al final se borran la base y el `.bak`.

| Id | Caso | Esperado |
|---|---|---|
| CA-H11-01 | Restaurar con la emisión hecha después del respaldo | `verificar` sale con 3 y dice RESTAURADA; R1 da `RESTAURADA`; una venta POS da 503 `EMISION_BLOQUEADA_RECONCILIAR` **sin** haber tomado serie ni NCF (los contadores no cambian); un `UPDATE` directo de emisión sigue dando 51330 |
| CA-H11-02 | R3 sin restauración | 409 `SITIO_NO_RESTAURADO`; el procedimiento llamado directo da 51328; sin cambios ni bitácora |
| CA-H11-03 | Permisos | USER: 403 en R1, R2 y R3. ADMIN: R1 200 y R2/R3 403. SUPER: 200. Ruta sin sesión: 401 |
| CA-H11-04 | Restauración con diferencias (la base tiene B02 hasta 10; después del respaldo se emitieron 11 a 15; el último probado es 15, de `PAPEL`) | Bloque original en `X` con `Hasta = 15`; nuevo de 16 al `Hasta` original con `Siguiente = 16` y el mismo vencimiento; zona `P` 11–15 con evidencia y referencia; FPOS adelantada al menos 100; fork registrado; `EmisionBloqueada = 0`; `Reconciliacion` en `C` con motivo; las líneas de la sección 4.4. **La primera venta después toma B0200000016** y un número de serie al menos 100 por encima |
| CA-H11-05 | Traslado: respaldo y restauración sin emitir en medio; último probado = el de la base | `Causa = TRASLADO`; ninguna secuencia cambia; filas de `ReconciliacionNcf` con zona nula; series según P-4; se emite enseguida |
| CA-H11-06 | Validaciones | Último probado menor que el de la base, mayor que `Hasta`, prefijo ajeno, secuencia vigente omitida, secuencia `C` incluida, `E` con `DIARIO` (P-5), motivo de 10 caracteres: 422 con la lista; R2 da 200 con los mismos errores |
| CA-H11-07 | Último probado = `Hasta` | Solo se cierra; aviso de tipo sin secuencia vigente; vender con ese tipo se rechaza con el texto de falta de NCF, **sin** sugerir «No generar comprobante» |
| CA-H11-08 | Atomicidad: falla forzada en el paso 6 (por ejemplo, una serie insertada después de abrir, que dispara 51329) | Todo se deshace: sin `X`, sin secuencias nuevas, fork sin registrar, sin bitácora, `EstadoNodo` igual que antes |
| CA-H11-09 | Dos R3 simultáneos | Uno da 200 y el otro 409 (`SITIO_NO_RESTAURADO` o `RESTAURACION_ESTADO_CAMBIO`); ninguna secuencia duplicada |
| CA-H11-10 | H-12 después del desbloqueo | Cambiar `Hasta` o `Estado` del bloque `X`: 51325. Crear una secuencia que se solape con la porción cerrada: 422 (validación) o 51324. Habilitar el `X` desde la pantalla: sigue en `X` |
| CA-H11-11 | Huella vieja (cambiar una serie entre R1 y R3) | 409 `RESTAURACION_ESTADO_CAMBIO` |
| CA-H11-12 | Segunda restauración del **mismo** respaldo después de desbloquear y emitir | Bloqueada otra vez; un último probado menor que lo emitido después del primer desbloqueo da 422 si la base lo conoce. Si no lo conoce, la prueba documenta que la evidencia manda (R-1) |
| CA-H11-13 | Movimiento de caja (apertura o retiro) | Rechazado antes del desbloqueo y aceptado después |
| CA-H11-14 | Otro nodo activo en `sync.Nodo` | R1 `REQUIERE_CENTRAL`; R3 409 `REQUIERE_RECONCILIACION_CENTRAL` |
| CA-H11-15 | DM-02 | Salida 0 al día; 2 con pendientes; 3 restaurada; 1 con una cadena inválida; con dos bases (una restaurada y otra pendiente), 3 |
| CA-H11-16 | DM-03 | Base con `AUTO_CLOSE ON` y cerrada: `actualizar` no muestra el aviso de intercalación vacía |
| CA-H11-17 | Interfaz (bUnit, Web y MAUI) | Los estados de la sección 7.1, el botón «Desbloquear…» deshabilitado con errores, el motivo obligatorio y el ADMIN sin formulario |
| CA-H11-18 | Arquitectura | Las rutas nuevas declaran `Sitio` (prueba de K-65) y las consultas nuevas están registradas con parámetros `varchar` del largo de su columna (CP-169 y ADR-50) |

---

## 14. Esfuerzo (inferido, ±40 %)

| Parte | sp |
|---|---|
| Datos: vista, 2 columnas, 2 procedimientos y la migración con su script | 0,15 |
| Backend: servicio, plan puro, consultas, endpoints, guarda y mensaje | 0,30 |
| Frontend: tarjeta en Web y MAUI, más los clientes | 0,20 |
| `GPOS.Migracion`: DM-02 y DM-03 | 0,05 |
| Pruebas, con la restauración real y bUnit | 0,15 |
| Correcciones de QA y de seguridad | 0,05 |
| **Total** | **0,9 (de 0,7 a 1,2)** |
| Si se firma P-3 (chequeras) | +0,1 |

**Por qué pasa de la estimación de H0 (0,6 sp, `cierre-h0.md:86`):** esa cifra no contaba tres cosas que hoy el código obliga a hacer:
- los procedimientos privilegiados, porque la aplicación tiene DENY sobre `sync.EstadoNodo` y `sync.Reconciliacion`;
- la ampliación de la guarda del servicio, que hoy no compara el fork;
- la tarjeta duplicada en Web y MAUI.

---

### Cierre
- Estado: Completado
- Artefactos: `C:\Users\lfmen\source\repos\Solucion GPOS NG\blueprint-h11-desbloqueo-restauracion-2026-10-10.md`
- Supuestos:
  - (1) H-13 se aplica como «solo SUPER», aunque su registro es contradictorio;
  - (2) el último momento conocido se aproxima con `doc.Documento.CreadoEn` y `audit.Bitacora.FechaHora` (inferido);
  - (3) `gpos_app` puede insertar en `sync.ReconciliacionNcf` y `ReconciliacionSerie`, por el permiso del esquema, sin probar;
  - (4) el diario electrónico (H-14) no existe y la evidencia se declara a mano;
  - (5) los números 51328 y 51329 están libres en las migraciones (verificado) y los confirma el arquitecto-datos.
- Decisiones candidatas a ADR:
  - D-1 (Ambos o Central sin nodos);
  - D-2 (en la base única, el corte recorta `Hasta` y continúa en una secuencia nueva; sin diferencias no se toca nada), como precisión de la cláusula 9 de ADR-53;
  - D-3 (sin subcomando de desbloqueo en `GPOS.Migracion`);
  - D-4 (transacción única con procedimientos `EXECUTE AS OWNER`);
  - D-5 (la guarda del servicio compara el fork);
  - códigos de salida de `verificar` (0, 1, 2 y 3).
- Entregas a otros agentes:
  - arquitecto-datos → la sección 10, puntos 1 a 7, y DM-04;
  - desarrollador-backend → las secciones 5, 6 y 11.2;
  - desarrollador-frontend → la sección 7.1;
  - especialista-pos → los textos del bloqueo y del desbloqueo para la empresa de una sola base, y P-1, P-4 y P-5 con el contador;
  - disenador-ux-ui → la tarjeta de la sección 7.1;
  - qa → la sección 13;
  - revisor de seguridad → la sección 8, y dejar `internal` `RegistrarSitioAsync(registrarSiExiste: true)`;
  - devops → la regla de R-2, el paso de detener e iniciar la API de R-6 e `Iniciar-Demo.ps1` según el código 3 (R-8);
  - arquitecto-maestro → aclarar el registro de H-13 y llevar P-1 a P-6 al propietario.
- Próximo paso recomendado: que el propietario responda P-1 a P-6 (o acepte las opciones por omisión) y que el arquitecto-datos diseñe la migración `H11DesbloqueoRestauracion` de la sección 10.
