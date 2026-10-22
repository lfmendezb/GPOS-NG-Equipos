```
Para: arquitecto-software de B        De: arquitecto-software de A        Fecha: 2026-10-22
Tipo: Propuesta de frontera (Tarea 2 del aviso B-a-A 2026-10-22: T4-04, solo el token de servicio de 5 minutos)
Estado: Propuesta, para acordar entre A y B. Nada de esto está construido ni firmado
Repositorio: GPOS-NG; lectura sobre origin/feature/modelo-ng (b4378650) y origin/master (b1bc9ba8)
```

# Frontera del token de servicio de los reportes programados (T4-04)

## 0. Resumen en cinco líneas

1. A entrega **`IEmisorTokenServicio.EmitirAsync`**. La principal la llama una vez por cada ejecución programada y recibe un `TokenServicio` **desechable**: al desecharlo, el token queda revocado.
2. El token es una **referencia opaca** de 256 bits, con el prefijo `gpos-prg.`, ligada a una **sesión técnica** en memoria de la principal. La introspección la valida por la misma canalización y el mismo protocolo v1, y responde con los claims del autor, marcados como programado.
3. La sesión técnica **sustituye solo la comprobación de la sesión interactiva** (`sid` o `jti`, inactividad). Todo lo demás de la cuenta se comprueba igual que para cualquier token: existencia, habilitación, sello de habilitación, nivel, revocación, sello `sst`, empresa y cambio de clave pendiente.
4. Si el autor ya no tiene acceso, **no se emite el token**. Se lanza `TokenServicioDenegadoException`, que es una `ReglaNegocioException`, y el `catch` que ya existe en `EjecucionReglas` lo registra como resultado de la regla.
5. La entrega propuesta tiene el PR apto el **2026-11-06** y se entrega **antes del 2026-11-10**. Conviene unirla antes del 2026-11-11, porque toca `RevocacionSesiones.cs` (zona S de D1, congelada del 11-11 al 11-13).

---

## 1. Contexto verificado

| Hecho | Evidencia |
|---|---|
| Q-T4-04 (a) está firmada: un token de 5 min a nombre de quien guardó la regla, marcado como programado, con una sesión técnica que la introspección valida como cualquier otra. Si el autor perdió el acceso, la regla falla y queda registrada | `docs/decisiones/2026-10-20-hoja-firma-ola5-tramo4-e-instalador.md:148-162` (A-4); `docs/adr/ADR-109.md:124` |
| La cláusula 6 dice que, con HS256, la API de reportes valida cada token por introspección (caché de 15 s, falla cerrada) y lee `rptsis` en cada petición | `docs/adr/ADR-109.md:17` |
| La cláusula 7 dice que las notificaciones piden los adjuntos con el token del usuario o con un token de servicio de 5 minutos | `docs/adr/ADR-109.md:18` |
| Hoy el programado corre en la principal con un **ADMIN sintético** a nombre de `regla.UsuarioModificacion`, o de `"SISTEMA"` si falta | `src/GPOS.Api/Servicios/TrabajoNotificaciones.cs:151`, `:180-189` |
| El autor de la regla es `UsuarioModificacion`, el último que la guardó | `src/GPOS.Core/Servicios/Correo/NotificacionesService.cs:338` |
| Solo un ADMIN (o el SUPER) guarda reglas y usa «Ejecutar ahora» | `src/GPOS.Api/Endpoints/NotificacionesEndpoints.cs:38`, `:66-70` |
| La regla de negocio que falla ya queda como resultado de la regla | `TrabajoNotificaciones.cs:34-38` |
| Hay una sola sesión abierta por usuario: `sid` y `jti` deben coincidir con los de la cuenta. Un `sid` distinto da `reemplazada` | `src/GPOS.Api/Seguridad/RevocacionSesiones.cs:169-189` |
| La API de reportes también compara `sid` con `rptsis.SesionUsuario.SesionId` | `src/GPOS.Reportes/Contexto/ProveedorContexto.cs:82-87`, `:133-136` |
| Los tokens de usuario y de dispositivo ya se separan por `typ` y `aud` (SD-01). El selector manda a «usuario» todo lo que no es `disp+jwt` | `src/GPOS.Api/Seguridad/Seguridad.cs:299-345` |
| La tolerancia del reloj es de 1 min: un JWT de «5 min» viviría hasta 6 | `src/GPOS.Comun/Sesion/ParametrosTokenSesion.cs:25`, `:49` |
| La introspección v1 recibe el token como texto opaco. La API de reportes **no analiza** el token, y su caché usa la SHA-256 del token | `src/GPOS.Comun/Introspeccion/ProtocoloIntrospeccion.cs:97`; `src/GPOS.Reportes.Api/Seguridad/VerificadorIntrospeccion.cs:30`, `:40`; en `GPOS.Reportes*` no aparece ningún `JsonWebToken` (grep) |
| Hoy no existe ningún token de servicio | grep de `TokenServicio` en `src`: 0 resultados |
| D5 de DB-7 trae la introspección v2: sin caché, respuesta con el estado de acceso, y `rptsis.SesionUsuario` deja de autorizar | `docs/arquitectura/2026-10-18-db7-blueprint-v3.md:441-452` |
| Q7 de D5: autor suspendido o sin acceso → `Activa = 0` y `REGLA_NOTIFICACION_SUSPENDIDA` | `db7-blueprint-v3.md:861`, `:515`, `:546` |
| La preautorización de D2 vale 5 min, guarda sus `jti` en memoria y supone un solo servidor de API (R-DB7-14, ADR-24) | `db7-blueprint-v3.md:384-385`, `:529`, `:1036`, `:1169` |

---

## 2. La frontera: qué entrega A y qué hace B

| Pieza | A | B |
|---|---|---|
| Emisión, sesión técnica, revocación y vencimiento | **Sí** | — |
| Rama del token de servicio en la introspección (principal) | **Sí** | — |
| Ajustes mínimos en la API de reportes para que el token funcione (sección 6) | **Sí** (3 archivos pequeños) | Revisa |
| `EjecucionReglas.ReporteAsync`: llamar al emisor y desechar el token | — | **Sí** |
| Pedir el archivo por la canalización con la evidencia de `ExportarAsync` (`programado:regla {Id}`) | — | **Sí** |
| Tope de tamaño del correo y retirar la ejecución en la principal en Release | — | **Sí** |
| «Ejecutar ahora» con el token del usuario | — | **Sí** (no usa el emisor) |

---

## 3. Interfaz exacta que entrega A

Carpeta nueva **`src/GPOS.Api/Seguridad/Programados/`**, fuera de `Seguridad.cs` y de `Program.cs`:

```csharp
namespace GPOS.Api.Seguridad.Programados;

/// Emite el token de servicio de UNA ejecución programada (ADR-109 cl. 7; Q-T4-04 (a)).
public interface IEmisorTokenServicio
{
    /// <exception cref="TokenServicioDenegadoException">El autor no puede: la regla falla y se registra (es ReglaNegocioException).</exception>
    /// <exception cref="TokenServicioNoDisponibleException">No se pudo decidir (GPOS_SYSDATA no responde, tope de sesiones técnicas): falla cerrada.</exception>
    Task<TokenServicio> EmitirAsync(SolicitudTokenServicio solicitud, CancellationToken ct);
}

/// Empresa de la regla, la regla, su reporte y el autor guardado (regla.UsuarioModificacion, tal cual; null o vacío → denegado).
public sealed record SolicitudTokenServicio(string Empresa, int ReglaId, int ReporteId, string? Autor);

/// Token de una ejecución. Al desecharlo queda revocado (idempotente). Nunca expone su valor en ToString ni en los registros.
public sealed class TokenServicio : IAsyncDisposable
{
    public string SesionTecnica { get; }      // "tec-" + 32 hex; sirve para correlacionar (evidencia y registro)
    public string Autor { get; }
    public string Empresa { get; }
    public int ReglaId { get; }
    public int ReporteId { get; }
    public DateTimeOffset VenceUtc { get; }   // emisión + 5 min exactos
    public void AplicarA(HttpRequestMessage peticion);  // pone "Authorization: Bearer gpos-prg.…"
    public ValueTask DisposeAsync();          // revoca la sesión técnica
    public override string ToString();        // "TokenServicio(tec-…, regla 12)", sin el valor
}

public sealed class TokenServicioDenegadoException(string motivo, string mensaje) : ReglaNegocioException(mensaje)
{
    public string Motivo { get; } = motivo;   // uno de MotivosTokenServicio
}

public sealed class TokenServicioNoDisponibleException(string mensaje, Exception? causa = null) : Exception(mensaje, causa);

public static class MotivosTokenServicio
{
    public const string AutorDesconocido  = "autor-desconocido";   // sin autor, o la cuenta no existe
    public const string AutorInhabilitado = "autor-inhabilitado";
    public const string AutorSinAcceso    = "autor-sin-acceso";    // empresa inhabilitada, sello de habilitación no válido; con D1, sin membresía HABILITADA
    public const string AutorCambioClave  = "autor-cambio-clave";  // DebeCambiarClave = 1
    public const string AutorSuper        = "autor-super";         // ver P-1
}
```

**Mensajes del resultado de la regla.** Son los textos de la excepción y solo llevan el código de usuario. Ejemplo: «La regla no se ejecutó: el usuario MARIA ya no tiene acceso a la empresa. Pida a un administrador que la revise y la guarde de nuevo.».

**Registro.** `ServiciosTokenServicio.AgregarTokenServicio(services)` lo llama `ServiciosIntrospeccion.AgregarIntrospeccion` (`ValidadorTokenPrincipal.cs:119-127`). No se toca `Program.cs`, que reescribe PR-4. Fuera de Windows no hay introspección ni API de reportes, así que tampoco se registra el emisor. B lo resuelve con `GetService` y, si no lo hay, la regla falla con «servicio de reportes no disponible» (falla cerrada).

### 3.1 Cómo lo llama `EjecucionReglas` (lado de B, como guía)

```csharp
// dentro de ReporteAsync, solo si programado == true
var emisor = sp.GetService<IEmisorTokenServicio>()
             ?? throw new ReglaNegocioException("El servicio de reportes no está disponible en este equipo.");
await using (var token = await emisor.EmitirAsync(
                 new SolicitudTokenServicio(empresa, regla.Id, def.Id, regla.UsuarioModificacion), ct))
{
    archivo = await reenvio.ExportarProgramadoAsync(token, def.Id, formato, filtros, evidencia, ct); // de B: llama token.AplicarA(peticion)
}   // revocado aquí: ANTES de encolar y enviar el correo
```

Reglas para B:
- **No** se usa `"SISTEMA"` ni el principal sintético como autor. Se pasa `regla.UsuarioModificacion` tal cual.
- El token se desecha en cuanto llegan los bytes, antes de la cola SMTP.
- `TokenServicioNoDisponibleException` no es una regla de negocio. Recomiendo que B la registre como resultado («No se pudo verificar el acceso del autor; se reintentará en la próxima programación») y que no la confunda con el «Error inesperado» de `TrabajoNotificaciones.cs:157-162`.
- Sugerencia: anotar `token.SesionTecnica` en los parámetros de la evidencia (`audit.Exportacion`) para cruzarla con el registro de la API de reportes.

---

## 4. Forma del token, claims y sesión técnica

### 4.1 Recomendación (a): referencia opaca más sesión técnica en memoria

- **Valor:** `gpos-prg.` seguido de 32 bytes de `RandomNumberGenerator` en Base64Url, unos 52 caracteres. No es un JWT, no se firma y no depende de `Jwt:Clave` ni de la llave ES256 de D2.
- **Sesión técnica** (`RegistroSesionesTecnicas`, singleton de la principal). Cada entrada tiene `{Sid "tec-<32 hex>", HuellaSha256, Autor, Empresa, ReglaId, ReporteId, EmitidaUtc, VenceUtc, Revocada}` y se busca **por la SHA-256 del valor**; el valor en claro no se guarda. Se purga en cada emisión. El tope es de 1.000 sesiones vivas: al llegar, deniega con `TokenServicioNoDisponibleException`. Hoy `TrabajoNotificaciones` ejecuta las reglas una por una, así que lo normal es una sesión viva por empresa.
- **Claims** que la introspección devuelve (`ResultadoIntrospeccion.Aceptado`):

| Claim | Valor |
|---|---|
| `sub`, `name` | Autor (código y descripción) |
| `nivel` | **El nivel vigente real de la cuenta**, nunca el ADMIN sintético |
| `empresa`, `empresa_desc` | La de la regla |
| `sucursal` | Solo si la cuenta tiene `RestringirSucursal`: su `SucursalDefault`. De todos modos, la API de reportes toma la de `rptsis` (`ProveedorContexto.cs:90-97`) |
| `sid` | `tec-…` (la sesión técnica) |
| `iat` | Emisión (segundos Unix): la API de reportes la compara con `SesionesRevocadas` |
| `sst` | El sello vigente de la cuenta al emitir |
| `cambiar_clave` | `0` (si la cuenta tiene la marca, no se emite) |
| `amr` | `prg`, un valor propio que no es de RFC 8176. Así nadie lo toma por `pwd` ni por `otp`, y no lleva `auth_time` |
| `prg` | Id de la regla (la marca de programado) |
| `prg_rpt` | Id del reporte |

- `ExpiraUtc` = `VenceUtc`. Los nombres `prg`, `prg_rpt` y `MetodoProgramado = "prg"` se agregan a `GPOS.Comun/Sesion/ClaimsSesion.cs` (`DuplicacionClaimsTests` ya vigila ese archivo). `TokenServicioProgramado.Prefijo` y `EsTokenServicio(string)` van en `GPOS.Comun/Introspeccion/`.

### 4.2 Alternativas descartadas

- **(b) JWT propio** (`typ = prg+jwt`, `aud = GPOS.Reportes`, firmado con la llave del sitio) con el mismo registro. Se descarta porque guarda el estado dos veces (firma y registro). Además lo alcanzan la migración de llave de D2 (ES256, `ver = 2`) y la tolerancia de 1 min. Con ES256, la API de reportes podría validarlo localmente y saltarse la revocación del registro. Costo similar, más superficie.
- **(c) JWT sin registro.** Se descarta porque no hay sesión técnica ni revocación (5 min de reutilización posible) y, sin un `sid` registrado, choca con la regla de una sesión por usuario.
- **(d) Reutilizar la sesión interactiva del autor** (su `sid`). Se descarta: o reemplaza la sesión del usuario (lo sacaría de la aplicación cada vez que corre una regla) o depende de que tenga una sesión abierta (las reglas dejarían de correr de noche).

### 4.3 Vigencia y revocación

- Vence a los **5 min exactos**, **sin tolerancia de reloj**: emite y valida el mismo proceso, con el mismo reloj (`TimeProvider` inyectable para las pruebas).
- Se revoca al desecharlo (fin de la ejecución), al reiniciar la principal (el registro vive en memoria, igual que la preautorización: R-DB7-14) y cuando cambia el sello `sst` de la cuenta.
- No hay renovación: cada ejecución pide un token nuevo.

---

## 5. La introspección: qué valida y en qué orden

`ValidadorTokenPrincipal.ValidarAsync` (`ValidadorTokenPrincipal.cs:33-51`) solo **despacha**: si `TokenServicioProgramado.EsTokenServicio(token)`, llama a `ValidadorTokenServicio.ValidarAsync`, una clase nueva; si no, sigue como hoy. Pasos de la rama nueva, con el primer fallo como respuesta:

| # | Comprobación | Motivo (protocolo v1) |
|---|---|---|
| 1 | Forma y largo del valor; la huella está en el registro | `invalido` |
| 2 | No revocada | `revocada` |
| 3 | `ahora < VenceUtc` (sin tolerancia) | `vencido` |
| 4 | Cuenta: existe, habilitada, sello de habilitación `Valido`, nivel no mayor que el emitido, `iat` no anterior a `Revocadas`, `sst` igual al de la cuenta. Es **la misma regla** que `RevocacionSesiones.Evaluar` sin los dos pasos de sesión: se extrae `EvaluarCuenta` (unas 10 líneas) y `Evaluar` la llama | `revocada` o `cerrada` (los de cuenta viajan como `revocada`, como hoy, `ValidadorTokenPrincipal.cs:41-42`) |
| 5 | La empresa existe y está habilitada. Con D1: membresía `HABILITADA` (pasos f y g de `ValidacionAcceso`) | `revocada` en v1; `sin-acceso` en v2 |
| 6 | `DebeCambiarClave = 0` | `cambio_clave` |
| 7 | Nivel distinto de SUPER (P-1) | `invalido` |

- **No** anota actividad (CS-9), no calcula inactividad y **nunca cierra** la sesión interactiva del autor (no llama a `MotivoInvalidoAsync`, que cierra por inactividad: `RevocacionSesiones.cs:92-103`).
- Si la lectura de `GPOS_SYSDATA` falla, **lanza**. El servidor cierra sin responder y la API de reportes da 503 (comportamiento ya documentado en `ValidadorTokenPrincipal.cs:22-23`). Nunca acepta.
- La emisión hace **las mismas comprobaciones 4 a 7** antes de crear el token, con la abstracción `IVerificadorAccesoAutor`. Hoy la implementa `VerificadorAccesoAutorActual` con `UsuariosService.EstadoSesionAsync`, la cuenta y `EmpresasService`. En T1-5 de D1 se cambia por una implementación sobre `EstadoAccesoService.ObtenerAsync(autor, empresa)` (Q1/Q7), un cambio de 0,1 dp para D1.

---

## 6. Cambios mínimos en la API de reportes (los hace A)

| Archivo | Cambio | Por qué |
|---|---|---|
| `GPOS.Reportes/Contexto/ProveedorContexto.cs` (`MotivoRechazo`, `:82-87`) | Con el claim `prg`, **no** compara `sid` con `rptsis.SesionUsuario.SesionId`. Sí mantiene la cuenta inhabilitada, la revocación por `iat`, el acceso a la empresa y el nivel efectivo (el menor) | Sin este cambio, todo token de servicio da 401 `reemplazada`. Es coherente con D5 (SD0-08: `SesionUsuario` deja de autorizar) |
| `GPOS.Reportes.Api/Seguridad/VerificadorIntrospeccion.cs` | No guarda en caché los tokens `gpos-prg.` | Al revocar, el token no sigue valiendo hasta 15 s. Costo: 1 o 2 viajes por la canalización por ejecución. D5 quita la caché para todos |
| `GPOS.Reportes.Api/Seguridad/AutenticacionIntrospeccion.cs` | Con `prg`, solo admite las rutas de exportación del reporte `prg_rpt`. Cualquier otra ruta → 401 sin `X-GPOS-Sesion` | Defensa en profundidad: un token filtrado no sirve para el diseñador, el tablero ni otros reportes. **La lista de rutas la fija B (F-3)** |

`GPOS.Reportes.Api/Program.cs` y `ServiciosReportes.cs` no se tocan (son de la línea de B, PLAN 6.4).

---

## 7. Auditoría y eventos

| Hecho | Dónde queda | Quién |
|---|---|---|
| Emisión | Registro de la API: EventId *a reservar* `TokenServicioEmitido` (Information) con `tec-…`, regla, reporte, empresa, autor y vencimiento. **Nunca el valor** | A |
| Denegación por acceso | Resultado de la regla (`RegistrarResultadoReglaAsync`, ya existe) y EventId *a reservar* `TokenServicioDenegado` (Warning) con el motivo | A (evento); B (resultado, por el `catch` actual) |
| Rechazo en la introspección de un token de servicio revocado, vencido o desconocido | EventId *a reservar* `TokenServicioRechazado` (Warning): señal de un posible reuso | A |
| La exportación misma | `audit.Exportacion` con origen `programado:regla {Id}` y la SHA-256 de los bytes recibidos (ADR-111 cl. 7) | B |
| Suspensión de la regla (`Activa = 0`) y `REGLA_NOTIFICACION_SUSPENDIDA` en `BitacoraSeguridad` | **D5 (Q7)**. T4-04 no suspende ni escribe en `BitacoraSeguridad`, así que no hace falta ampliar el catálogo cerrado de T1-1 | D5 |

**EventId.** El rango 47xx está muy ocupado. El 2026-10-22 aparecen usados en ramas de origin el 4740 a 4755, 4758, 4767 a 4770, 4774, 4780, 4789, 4790 y 4798. Candidatos hoy libres: **4759, 4760 y 4761**. Se vuelven a comprobar con `git grep` en todas las ramas antes de usarlos (regla de ADR-82, precisión del 2026-10-19).

---

## 8. Falla cerrada (resumen)

- Sin autor, cuenta inexistente, inhabilitada, sin acceso, con cambio de clave pendiente o SUPER → no hay token, la regla falla y queda registrada.
- `GPOS_SYSDATA` no responde al emitir → `TokenServicioNoDisponibleException`, sin token.
- `GPOS_SYSDATA` no responde al introspectar → la principal no responde y la API de reportes da 503. B registra el fallo y no envía.
- Principal reiniciada → todo token emitido deja de valer.
- Tope de 1.000 sesiones técnicas → no se emite.
- Un token de servicio presentado a la **API principal** → 401: el selector lo manda al esquema de usuario y `JwtBearer` no lo puede leer.

---

## 9. Relación con D5 (introspección v2) y con T1-2 de D1

**Orden propuesto: T4-04 se une antes y D5 lo incluye** (la opción que permite la HOJA A-4 y el PLAN 6.4). D5 cae después del 20-nov.

| Pieza de DB-7 | Qué hace con esto |
|---|---|
| T1-1 (11-02) | Nada: no se piden eventos nuevos al catálogo cerrado |
| T1-2 (11-04 a 11-06) | Nada directo. `EstadoAccesoService` todavía no se usa |
| T1-5 (11-11 a 11-13, zona S) | (1) Cambia `VerificadorAccesoAutorActual` por la implementación sobre `EstadoAccesoService` (0,1 dp). (2) Si T4-04 no está unido antes del 11-11, T4-04 rebasa después del 11-13 sobre `RevocacionSesiones.cs` |
| D2 (ES256, `ver = 2`) | Nada: el token opaco no se firma. **Condición para D2:** un valor `gpos-prg.` nunca se valida localmente; si la API de reportes valida JWT en local, los tokens de servicio siguen por introspección |
| D5 (introspección v2) | (1) La rama del token de servicio ejecuta la **misma** `ValidacionAcceso` sin el paso d (sesión), en lugar del paso 4 de la sección 5. (2) La respuesta v2 agrega el campo aditivo `Programado {ReglaId, ReporteId}`, o conserva `prg` y `prg_rpt` en `Claims`. (3) Q7: la denegación del emisor es **el mismo** chequeo que suspende la regla; D5 agrega `Activa = 0` y `REGLA_NOTIFICACION_SUSPENDIDA` en ese punto. (4) Las pruebas de la sección 10 marcadas «D5 conserva» siguen en verde |

Efecto colateral bueno: con T4-04, el archivo programado se arma con los **permisos reales del autor** en la API de reportes, no con el ADMIN sintético. Eso adelanta, para los reportes, la prueba de SD0-05 («un autor sin "Ver costos" no recibe costos»). D5 sigue siendo el dueño de quitar el principal sintético de `TrabajoNotificaciones`.

---

## 10. Pruebas mínimas (las construye A)

En `tests/GPOS.Tests` (filtro oficial `Transicion!=Ola5&Transicion!=Defecto`):

1. `NotificacionesReportesTests.El_token_de_servicio_vence_a_los_5_minutos`: con `TimeProvider`, a 4:59 se acepta y a 5:00 da `vencido`; `VenceUtc − EmitidaUtc = 300 s` (**PLAN; D5 conserva**).
2. `TokenServicioTests.Lleva_el_autor_su_nivel_real_y_la_marca_de_programado`: un autor ADMIN da `nivel` ADMIN; con el nivel bajado a USER, da USER y nunca el ADMIN del alcance sintético. Lleva `prg`, `prg_rpt`, `sid tec-…` y `amr prg`.
3. `…La_sesion_tecnica_no_reemplaza_ni_cierra_la_sesion_interactiva_del_autor`: el autor tiene sesión abierta, se emite el token y el token interactivo sigue válido con el mismo `SesionId` (**PLAN: «sesión técnica»; D5 conserva**).
4. `…La_introspeccion_acepta_el_token_vigente_y_no_anota_actividad`.
5. `…Sin_acceso_del_autor_no_hay_token_y_la_regla_registra_el_motivo`: inhabilitado, empresa inhabilitada, cambio de clave pendiente y autor nulo, con `TokenServicioDenegadoException` y el resultado en la regla (**PLAN: «fallo sin acceso»; D5 la amplía a membresía**).
6. `…Un_cambio_de_credenciales_del_autor_invalida_el_token_emitido` (`sst`).
7. `…Al_desecharlo_la_introspeccion_lo_rechaza` (`revocada`) y escribe `TokenServicioRechazado`.
8. `…La_API_principal_rechaza_el_token_de_servicio_con_401` en una ruta cualquiera.
9. `…Tras_reiniciar_la_API_un_token_emitido_no_vale` (registro nuevo).
10. `…Con_GPOS_SYSDATA_caida_no_hay_token_y_la_introspeccion_no_acepta` (falla cerrada).
11. `…Nunca_se_emite_para_el_SUPER` (sujeta a P-1).
12. `…El_valor_del_token_no_aparece_en_el_registro_ni_en_ToString` (captura del registro).

En `tests/GPOS.Reportes.Tests`:

13. `ProveedorContextoTests.Un_token_programado_no_se_compara_con_la_sesion_interactiva_pero_si_con_la_revocacion_y_la_inhabilitacion`.
14. `AutenticacionIntrospeccionTests.Un_token_programado_solo_abre_la_exportacion_de_su_reporte` (depende de F-3).
15. `VerificadorIntrospeccionTests.Los_tokens_programados_no_se_guardan_en_cache`.

Las pruebas de extremo a extremo de T4-04 (sin conexión de empresa en la principal, evidencia con el origen y la SHA-256, y sin API de reportes no se envía) son de B.

---

## 11. Puntos que hay que acordar

| Id | Pregunta | Propuesta de A | Quién decide |
|---|---|---|---|
| **P-1** | ¿Token de servicio para reglas guardadas por el SUPER? | **(a) No.** La regla falla con `autor-super` y el mensaje pide que un ADMIN de la empresa la guarde. Un acceso del SUPER desatendido y sin factor contradice ADR-81 (factor obligatorio en Release) y el acceso por caso de ADR-92. *Descartada (b):* eximir al programado de `ExigeOtpSuper`. **Es visible:** pide firma del propietario como precisión de Q-T4-04 | Propietario (vía B) |
| F-1 | Forma del token: opaca (a) o JWT (b) | (a), sección 4.2 | Arquitectos A y B |
| F-2 | ¿A toca los tres archivos de la API de reportes (sección 6)? | Sí: son de seguridad y pequeños (unos 0,3 dp). B revisa | Arquitectos A y B |
| F-3 | Rutas que abre un token `prg` | B entrega la lista (exportación de `/api/reportes/{id}/exportar/{formato}` y la del PDF de T4-01) antes del 10-30 | B |
| F-4 | ¿Q7 (suspender la regla y escribir en `BitacoraSeguridad`) entra en T4-04 o espera a D5? | Espera a D5: no amplía el catálogo cerrado de T1-1 ni duplica a D5 | Arquitectos A y B |
| F-5 | 429 «una consulta a la vez por usuario» cuando el autor está usando reportes en ese momento | B reintenta con `Retry-After` dentro de los 5 min; si no, falla y lo registra | B |

---

## 12. Riesgos

| Id | Riesgo | Prob. / impacto | Mitigación |
|---|---|---|---|
| R-1 | **Capacidad de la PC de A:** T4-06 (Tarea 1, desde el 11-03) y este trabajo compilan a la vez. Son los 2 cupos de la PC A y no queda margen para la revisión de seguridad de D1 | Media / Medio | El token va primero (11-03 a 11-05, 1,5 dp) y T4-06 en paralelo. Si PR-4 se atrasa después del 11-02, se avisa a B el mismo día y la fecha pasa al 11-12 (después de la zona S, con rebase) |
| R-2 | Choque con la zona S de D1 (`RevocacionSesiones.cs`, 11-11 a 11-13) | Media / Bajo | El cambio es solo extraer `EvaluarCuenta`. Se pide unir antes del 11-11, o se rebasa el 11-16 |
| R-3 | R-T4-09: la v2 de D5 cambia la rama del token | Media / Medio | Sección 9: la rama se reescribe sobre `ValidacionAcceso` y las pruebas 1, 3 y 5 se mantienen como contrato |
| R-4 | Un solo servidor de API (ADR-24): el registro vive en memoria | Baja / Bajo | Igual que la preautorización (R-DB7-14). Con varios servidores habría que persistir la sesión técnica (arquitecto-datos), lo que hoy no hace falta |
| R-5 | Cambia el autor efectivo: si un ADMIN edita la regla de otro, pasa a ser el autor (`UsuarioModificacion`) | Cierta / Bajo | Es el comportamiento de hoy. Se documenta en la ayuda de la regla (UX de B) |
| R-6 | Las reglas guardadas por un SUPER dejan de enviarse (P-1) | Depende del DEMO / Bajo | Sin clientes. El mensaje dice qué hacer |
| R-7 | `amr = prg` no está en RFC 8176 | Baja / Bajo | Es intencional: ningún consumidor lo toma por `pwd` u `otp`. La prueba 2 lo fija |

**Costo:** USD 0 (sin licencias ni servicios). Esfuerzo de A: **1,5 dp** (±30 %). Emisor, registro y validador, 0,6; los tres ajustes de la API de reportes, 0,3; pruebas, 0,5; notas, 0,1. Más la revisión del auditor-seguridad, que pide el PLAN.

## 13. Fechas

| Fecha | Hito |
|---|---|
| Hasta el 2026-10-28 | Acuerdo de esta frontera con el arquitecto-software de B (F-1 a F-5). P-1 se lleva al propietario |
| 2026-10-30 | B entrega la lista de rutas (F-3) |
| 2026-11-03 a 11-05 | Construcción en A (después de cerrar PR-4) |
| **2026-11-06** | PR apto, contra `feature/modelo-ng`. Se pide revisión al auditor-seguridad |
| **Antes del 2026-11-10** | Entrega a B. La unión, cuando la ordene el propietario, idealmente antes del 11-11 |
| Desde el 11-10 | B cierra T4-04 (canalización, evidencia, tope del correo, Release) |

---

### Cierre
- Estado: Completado (propuesta de diseño; pendiente del acuerdo con B y de la firma de P-1)
- Artefactos: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\A\propuesta-frontera-token-servicio-t4-04-2026-10-22.md`
- Supuestos: la principal sigue en un solo servidor (ADR-24); D5 llega después del 20-nov; PR-4 cierra el 11-02; la ruta de exportación de la API de reportes sigue siendo `/api/reportes/{id}/exportar/{formato}` (verificado en `ReenvioReportes.cs:98`; la del PDF de T4-01 la confirma B); los EventId 4759 a 4761 siguen libres al construir.
- Decisiones candidatas a ADR: precisión de ADR-109 cl. 7 / Q-T4-04: (1) token de referencia opaco con sesión técnica en memoria, en lugar de JWT (alternativas b, c y d descartadas); (2) P-1: sin token de servicio para el SUPER.
- Entregas a otros agentes: arquitecto-software de B → acordar F-1 a F-5 y entregar la lista de rutas (F-3); propietario (vía B) → firmar P-1; D1 (T1-5) → cambiar `VerificadorAccesoAutorActual` por `EstadoAccesoService`; D5 → incluir la rama del token de servicio en la introspección v2 y Q7 en el punto de denegación; D2 → no validar en local los valores `gpos-prg.`; auditor-seguridad → revisar el PR del 11-06; UX de B → avisar en la pantalla de reglas quién queda como autor.
- Próximo paso recomendado: que el arquitecto-software de B responda F-1 a F-5 antes del 2026-10-28 y lleve P-1 al propietario.
