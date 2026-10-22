```
Para: arquitecto-software de A        De: arquitecto-software de B        Fecha: 2026-10-22
Tipo: Respuesta a la propuesta de frontera del token de servicio de T4-04 (F-1 a F-5; P-1 se lleva al propietario)
Estado: Recomendación técnica de B, para acordar entre A y B. Nada de esto está construido ni firmado
Fuentes: propuesta de A (traspasos/A/propuesta-frontera-token-servicio-t4-04-2026-10-22.md); origin/feature/modelo-ng @ cb94f19b;
         worktree GPOS-B-t4-04 (rama b/ola5-t4-04, 9c0f447d y 5af4d9c4, sin empujar). Solo lectura: nada compilado ni ejecutado.
```

# Recomendación de B sobre la frontera del token de servicio (T4-04)

## 0. Resumen

| Id | Propuesta de A | Respuesta de B |
|---|---|---|
| F-1 | Token opaco `gpos-prg.` (256 bits) con una sesión técnica en memoria de la principal; no es JWT | **Acepta**, con dos condiciones (C-1.1 y C-1.2) |
| F-2 | A toca 3 archivos de la API de reportes (`ProveedorContexto`, `VerificadorIntrospeccion`, `AutenticacionIntrospeccion`); B revisa | **Acepta** (B revisa, 0,25 dp) |
| F-3 | B entrega antes del 10-30 la lista de rutas que abre un token `prg` | **Acepta con cambio:** la lista va en este documento (una sola ruta) y se aplica con una lista blanca por metadatos del *endpoint*, no por texto de la ruta |
| F-4 | Q7 (suspender la regla y escribir en `BitacoraSeguridad`) espera a D5 | **Acepta** |
| F-5 | 429 por «una consulta a la vez por usuario»: B reintenta con `Retry-After` dentro de los 5 min | **Acepta con cambio:** reintento acotado (3 intentos, ≤ 90 s en total y con al menos 60 s de vigencia restante); no se usa todo el plazo de 5 min ni otra partición de concurrencia |
| P-1 | Sin token de servicio para el SUPER | B **apoya la opción (a)** y la lleva al propietario (es visible: necesita su firma) |

Contrato: B adopta la interfaz de A (`IEmisorTokenServicio`) y retira la suya (`IProveedorTokenServicio`). Pide a A un único cambio: un **constructor público para las pruebas** de `TokenServicio`, además de publicar antes solo el contrato (sección 3).

---

## 1. Qué hay hoy en el lado de B (verificado en el worktree)

| Hecho | Evidencia |
|---|---|
| La interfaz provisional de B es `IProveedorTokenServicio.EmitirAsync(SolicitudTokenServicio(Empresa, Usuario, ReglaId))` y devuelve `TokenServicio(Valor, Emitido, Vence)` | `GPOS-B-t4-04/src/GPOS.Api/Servicios/TokenServicioReportes.cs:9`, `:13`, `:37-40` [V] |
| `Admisible`: tiene valor, está vigente y dura como mucho 5 min | `TokenServicioReportes.cs:16`, `:25` [V] |
| La implementación registrada falla cerrada con una `ReglaNegocioException` | `TokenServicioReportes.cs:46-51`; registro `TryAddSingleton` en `src/GPOS.Api/Endpoints/ReenvioReportes.cs:346` [V] |
| **Defecto de B:** si falta el autor, usa `sesion.Usuario`, que en el alcance del trabajo es `"SISTEMA"` | `TrabajoNotificaciones.cs:135` con `:252` (`Alcance(empresa, regla.UsuarioModificacion ?? "SISTEMA")`) [V] |
| El token sale como texto `"Bearer " + Valor` y lo usa `ArchivoAsync(string autorizacion, …)` | `TrabajoNotificaciones.cs:127-139`, `:99-100`; `ReenvioReportes.cs:167-173` [V] |
| Un 429 de la API de reportes da hoy una regla de negocio sin reintento; si la API no responde, `ReportesNoDisponibleException` (503) | `ReenvioReportes.cs:174-181`, `:314-322` [V] |
| Solo `ReglaNegocioException` queda como resultado de la regla; cualquier otra excepción solo se registra en el log | `TrabajoNotificaciones.cs:34-38`, `:258-262` [V] |
| La regla avanza su `ProximaEjecucion` al tomarla: si una ejecución falla, ese período no se envía hasta la siguiente programación | `src/GPOS.Core/Servicios/Correo/NotificacionesService.cs:353-370` [V] |
| `GPOS.Api` no tiene `InternalsVisibleTo` | `git grep InternalsVisibleTo -- src/GPOS.Api`: 0 resultados [V] |

---

## 2. Respuesta por punto

### F-1. Forma del token: referencia opaca con sesión técnica en memoria

**Propuesta de A.** El valor es `gpos-prg.` seguido de 32 bytes aleatorios en Base64Url. La principal guarda solo su SHA-256 en un registro en memoria con `{sid tec-…, autor, empresa, regla, reporte, emitido, vence, revocada}`. La introspección lo valida por la misma canalización y el mismo protocolo v1, y devuelve los claims del autor con `prg`, `prg_rpt` y `amr = prg`. El token vence a los 5 min exactos, sin tolerancia de reloj, y se revoca al desecharlo, al reiniciar la principal o cuando cambia `sst`.

**B: acepta.** Motivos:
- **Quién emite y quién valida.** Emite la principal y valida la misma principal, en el mismo proceso. Así no hay tolerancia de reloj: el JWT de la sesión tiene 1 min (`src/GPOS.Comun/Sesion/ParametrosTokenSesion.cs`, `Tolerancia = 1 min`, `ClockSkew`) [V], así que un JWT de «5 min» viviría hasta 6. El token tampoco depende de `Jwt:Clave` ni de la llave ES256 de D2. Cumple Q-T4-04 (a) y la segunda precisión de ADR-109 cl. 7 (A-4): no hay un segundo camino de autenticación (`docs/adr/ADR-109.md`, precisión A-4) [V].
- **Revocación en cada petición.** La API de reportes no analiza el token: lo pregunta por introspección (`src/GPOS.Reportes.Api/Seguridad/VerificadorIntrospeccion.cs:101-113`) [V]. Con la caché desactivada para `gpos-prg.` (F-2), la revocación por desecho surte efecto en la petición siguiente. El estado de la cuenta (inhabilitación, `sst`, revocación) sigue con la caché de 15 s de la principal (`src/GPOS.Api/Seguridad/RevocacionSesiones.cs:83`, `:143-157`) [V] y con el paquete `rptsis` de 15 s (`src/GPOS.Reportes/Contexto/ProveedorContexto.cs:42`, `:101-115`) [V]. Es lo firmado en la cl. 6 (15 s) y dentro de una vigencia de 5 min es aceptable.
- **Aislamiento entre empresas.** La empresa queda fijada en la sesión técnica, sale de la regla y no del cliente, y la API de reportes la vuelve a comprobar con `rptsis.AccesoEmpresa` (`ProveedorContexto.cs:71`) [V]. El token solo vale en su sitio, porque el registro vive en la principal de ese sitio (ADR-109 cl. 6, «solo acepta tokens de su sitio»).
- **El token no sale en los registros.** Con el tipo de A (`AplicarA`, `ToString` sin el valor), el valor nunca existe como `string` en el código de B. Hoy sí existe (`TrabajoNotificaciones.cs:138`). Es una mejora frente a la interfaz de B.
- **Sesión técnica marcada como programada.** `sid tec-…`, `prg`, `prg_rpt` y `amr = prg`. Por eso nunca reemplaza ni cierra la sesión interactiva del autor, que es el problema de reutilizar el `sid` (`RevocacionSesiones.cs:169-189`) [V].
- **Alternativas descartadas por A, de acuerdo:** (b) JWT `prg+jwt`, que guarda el estado dos veces y queda expuesto a la validación local con ES256; (c) JWT sin registro, que no se puede revocar; (d) el `sid` del autor.

**Condiciones de B:**
- **C-1.1 (D2):** un valor `gpos-prg.` nunca se valida en local, ni siquiera con ES256. La cl. 6 dice que con ES256 la API de reportes valida localmente; esto la precisa. Va a «Decisiones candidatas a ADR» como precisión de ADR-109 cl. 6 y 7, y se fija con una prueba en `GPOS.Reportes.Tests` cuando llegue D2.
- **C-1.2:** el registro en memoria supone un solo servidor de API (ADR-24, R-4 de A). Se escribe en la precisión para que, si algún día hay varios servidores, se rediseñe en lugar de fallar en silencio.

### F-2. A toca los tres archivos de la API de reportes

**Propuesta de A.** Tres cambios:
- `ProveedorContexto.MotivoRechazo`: con `prg` no compara `sid` con `rptsis.SesionUsuario` (`ProveedorContexto.cs:81-87`) [V].
- `VerificadorIntrospeccion`: no guarda en caché los tokens `gpos-prg.`.
- `AutenticacionIntrospeccion`: aplica la lista blanca de F-3.

`Program.cs` y `ServiciosReportes.cs` no se tocan. Esfuerzo: unos 0,3 dp.

**B: acepta.** Motivos:
- Son cambios de seguridad pequeños y sin ellos todo token de servicio da 401 `reemplazada`.
- Ninguna rama activa de B toca esos tres archivos: el #152 (T4-01) no los cambia. Las únicas ramas de `origin` con diferencias en los archivos de seguridad de la principal son ramas viejas (`a/t6-bancos`, `b/c10-…`, `b/integracion-pendiente-14oct`, `b/prep-27oct-…`, y solo en `RevocacionSesiones.cs`) [V, `git diff` por rama].
- Respeta la regla de la sección 6.4 del plan (la línea de B sigue siendo dueña de `Program.cs` y `ServiciosReportes.cs`).

**Precisiones que B pide en la revisión:**
- (a) En `MotivoRechazo` se omite **solo** `MotivoSesion`; usuario inhabilitado y revocación por `iat` siguen (`ProveedorContexto.cs:83-84`).
- (b) El rechazo `prg` en la caché tampoco se guarda. Hoy se guardan también los resultados no válidos (`VerificadorIntrospeccion.cs:112`).
- (c) No se anota actividad: la principal ya no la anota para la rama nueva.

Revisión de B: 0,25 dp.

### F-3. Rutas que abre un token `prg` (lista de B)

**Propuesta de A.** B entrega la lista antes del 10-30: la exportación `/api/reportes/{id}/exportar/{formato}` y la ruta del PDF de T4-01. Cualquier otra ruta da 401 sin `X-GPOS-Sesion`.

**B: acepta con cambio. La lista ya va aquí: una sola ruta.**

| Abre | Condiciones (todas) |
|---|---|
| `GET /api/reportes/{id:int}/exportar/{formato}` (`src/GPOS.Reportes.Api/Endpoints/EndpointsReportes.cs:64`) [V] | Método `GET`; valor de ruta `id` igual a `prg_rpt`; `formato` en `pdf`, `xlsx` o `csv` (`ReglaNotificacion.FormatosReporte`, `src/GPOS.Contracts/Admin/Notificaciones.cs:183`) [V]; solo por la canalización (`PorCanalInterno`, ya exigido en `:67` y `:129`) [V] |

**No abre**, aunque estén por la canalización:
- `/api/reportes`, `/api/reportes/{id}` y `/api/reportes/{id}/ejecutar`;
- `/api/admin/reportes/*` (diseñador);
- el tablero;
- **todo `/interno/render/*`, incluida `/interno/render/resultado`** (`EndpointsRender.cs:43-54`) [V].

**Por qué no abre `/interno/render/resultado`:** esa ruta recibe un `ResultadoReporte` ya ejecutado. Usarla para el programado obliga a la principal a ejecutar el reporte, lo que contradice CA-O5-8 y la cl. 1. El PDF del programado debe salir de la misma exportación (`exportar/pdf`). Hoy la API de reportes solo exporta CSV y XLSX (`src/GPOS.Reportes/Exportacion/OpcionesExportacion.cs:51-58`) [V]. Agregar PDF a la exportación, con el `ServicioRender` que T4-01 ya trasladó, es trabajo de B (0,5 a 0,75 dp) [I]. Hasta entonces, un programado en PDF devuelve 400 y la regla registra el fallo. La regla por omisión es PDF (`Notificaciones.cs:166`) [V].

**Cómo se aplica (el cambio sobre la propuesta de A):**
- En lugar de comparar el texto de la ruta en el manejador de autenticación, B marca el *endpoint* con un metadato `PermiteTokenProgramado`, en su archivo `EndpointsReportes.cs`.
- A, en `AutenticacionIntrospeccion` (o en una política de autorización global), **rechaza todo token `prg` cuyo *endpoint* no tenga el metadato** y compara `RouteValues["id"]` con `prg_rpt`.
- Así, una ruta nueva queda cerrada por omisión y un cambio de nombre no abre nada.
- Esto exige que el *endpoint* ya esté resuelto al autenticar, es decir, `UseRouting` antes de `UseAuthentication` [I]. A lo verifica en `Program.cs` de reportes sin editarlo; si no se cumple, el control pasa a un filtro de *endpoint* global.

### F-4. Q7 (suspender la regla y escribir en `BitacoraSeguridad`) espera a D5

**Propuesta de A.** T4-04 no suspende la regla ni escribe en `BitacoraSeguridad`; D5 agrega `Activa = 0` y `REGLA_NOTIFICACION_SUSPENDIDA` en el mismo punto de denegación.

**B: acepta.** Motivos:
- No amplía el catálogo cerrado de T1-1 ni duplica a D5.
- Mientras tanto, la denegación queda en `UltimoResultado` de la regla (`TrabajoNotificaciones.cs:34-38`; `NotificacionesService.cs:372-378`) [V] y en el evento `TokenServicioDenegado`.
- **Costo aceptado:** una regla cuyo autor perdió el acceso falla en cada programación hasta D5 (como mucho, una línea por ejecución). No hay clientes en producción.
- **Condición:** la denegación del emisor y la suspensión de D5 usan **el mismo** verificador (`IVerificadorAccesoAutor`), como propone A en la sección 9.

### F-5. 429 «una consulta a la vez por usuario»

**Propuesta de A.** Si el autor está usando reportes en ese momento, B reintenta con `Retry-After` dentro de los 5 min; si no lo logra, falla y lo registra.

**B: acepta con cambio.** El token de servicio lleva el `sub` del autor, así que comparte con él:
- su turno (`TurnosConsultas.TomarTurnoUsuario`, 429 `REPORTE_EN_CURSO`, `src/GPOS.Reportes/Ejecucion/TurnosConsultas.cs:22-32`) [V];
- su ventana de 30 peticiones por minuto (429 `LIMITE_PETICIONES`, `EndpointsReportes.cs:39`, `:111-126`) [V];
- y sus temporales de exportación (429 `EXPORTACIONES_EN_CURSO`) [V].

**Regla de B:**
- Reintenta solo los 429 con código `REPORTE_EN_CURSO`, `REPORTES_OCUPADOS`, `LIMITE_PETICIONES` o `EXPORTACIONES_EN_CURSO`.
- Respeta `Retry-After`, con un tope de 30 s por espera.
- Como mucho **3 intentos y 90 s en total**, y solo si al token le quedan **al menos 60 s** de vigencia (30 s de la cl. 12 más la transferencia). No pide un token nuevo.
- Si no lo logra, la regla registra: «El reporte no se generó porque el usuario X tenía otro reporte en curso; se enviará en la próxima programación».

**Por qué no hasta los 5 min:**
- `TrabajoNotificaciones` ejecuta las reglas una por una, para todas las empresas (`TrabajoNotificaciones.cs:229`, `:250-262`) [V]. Una espera de minutos detiene los demás envíos del sitio.
- La regla ya avanzó su próxima ejecución (`NotificacionesService.cs:353-370`) [V].

**Alternativa descartada:** una partición de concurrencia propia para el programado (por ejemplo, la clave `prg:{sid}`). Permite dos consultas a la vez del mismo usuario, en contra de la cl. 12 («una consulta a la vez por usuario»), y necesitaría una precisión firmada.

---

## 3. Cambios de interfaz

### En B (`IProveedorTokenServicio` → contrato de A)
1. Retirar `IProveedorTokenServicio`, `SolicitudTokenServicio(Empresa, Usuario, ReglaId)`, el *record* `TokenServicio` y `ProveedorTokenServicioPendiente` (`TokenServicioReportes.cs`), y el `TryAddSingleton` de `ReenvioReportes.cs:346`.
2. Resolver `IEmisorTokenServicio` con `GetService`. Si no está registrado (fuera de Windows, o antes de unir el PR de A), lanzar `ReportesNoDisponibleException`: falla cerrada, la regla registra el fallo y no se envía.
3. Pasar `regla.UsuarioModificacion` **tal cual**, sin `?? sesion.Usuario`, que hoy vale `"SISTEMA"` (`TrabajoNotificaciones.cs:135`). Pasar también `def.Id` como `ReporteId` y la empresa del trabajo.
4. Usar `await using` del token alrededor de `ArchivoAsync` y desecharlo **antes** de `EncolarConEvidenciaAsync`.
5. Cambiar `ArchivoAsync(string autorizacion, …)` a `ArchivoAsync(Action<HttpRequestMessage> autorizar, …)`. El programado pasa `token.AplicarA` y «Ejecutar ahora» copia el encabezado del usuario. El valor no vuelve a ser un `string` en B.
6. Conservar la defensa de `Admisible` con lo que expone A: `VenceUtc > ahora` y `VenceUtc − ahora ≤ 5 min`. No hace falta `EmitidoUtc`.
7. Capturar `TokenServicioNoDisponibleException` en `EjecucionReglas.EjecutarAsync` y registrarla como resultado («No se pudo verificar el acceso del autor; se reintentará en la próxima programación»), aparte del «Error inesperado».
8. Reintento de F-5 en `ArchivoAsync`, o en quien lo llama.
9. Agregar `token.SesionTecnica` a los parámetros de `audit.Exportacion` (`ParametrosJson`), junto con el origen `programado:regla {Id}` (AE-02).
10. Defensa en profundidad: ocultar los valores de los encabezados en el registro del cliente `ClienteCanal` (`ReenvioReportes.cs`, `AddHttpClient`) con `RedactLoggedHeaders(_ => true)`. Desde .NET 8 ya se ocultan por omisión [I: verificar con la versión del SDK].
11. Metadato `PermiteTokenProgramado` en `exportar` (F-3) y PDF en la exportación de la API de reportes (F-3).

### En A (a la propuesta de la sección 3)
1. **Publicar primero solo el contrato**, antes del 2026-10-30 y en un commit pequeño de unos 0,1 dp: `IEmisorTokenServicio`, `SolicitudTokenServicio`, `TokenServicio`, las dos excepciones y `MotivosTokenServicio`. B lo usa como base de T4-04 y puede unir sin la implementación (el camino de falla cerrada del punto B-2).
2. **Constructor público para las pruebas** de `TokenServicio` (valor, `sesionTecnica`, autor, empresa, regla, reporte, `VenceUtc` y una función de revocación). `GPOS.Api` no tiene `InternalsVisibleTo` y las pruebas de B (`NotificacionesReportesTests`, `ReportesF9Tests`) necesitan emisores falsos. No abre ningún riesgo: un valor solo vale si está en el registro.
3. Aplicar F-3 con el metadato, en lugar de comparar el texto de la ruta.
4. F-2 (b): no guardar en caché tampoco los rechazos `prg`.

---

## 4. Esfuerzo y orden de construcción

**Esfuerzo de B** (inferido, ±30 %):

| Trabajo | dp |
|---|---|
| Adaptar al contrato de A (puntos 1 a 7) | 0,3 |
| Reintento de F-5 | 0,25 |
| Evidencia con la sesión técnica y ocultar encabezados | 0,1 |
| Metadato de F-3 | 0,05 |
| Adaptar las pruebas | 0,25 |
| Revisar los tres archivos de A | 0,25 |
| **Total** | **1,2** |
| PDF en la exportación de la API de reportes (si no va en T4-02) | +0,5 a 0,75 |

El esfuerzo de A no cambia (1,5 dp) y suma unos 0,1 dp por el contrato separado y el constructor de pruebas.

**Orden:**

| Fecha | Hito |
|---|---|
| Hasta el 2026-10-28 | Acuerdo de F-1 a F-5 (este documento). B lleva P-1 al propietario |
| Hasta el 2026-10-30 | A publica solo el contrato. La lista de F-3 ya está aquí |
| 10-28 a 11-02 | B adapta T4-04 (calendario de la sección 7 del plan). PR de B con el emisor ausente, falla cerrada |
| 11-03 a 11-05 | A construye el emisor, el registro, la rama de la introspección y los tres archivos |
| 11-06 | PR de A apto. Revisan el auditor-seguridad y B (F-2) |
| 11-06 a 11-09 | B prueba de extremo a extremo con el emisor real: sin conexión de empresa en la principal, evidencia con el origen y la SHA-256, sin API de reportes no se envía, F-5 y F-3 |
| **Antes del 2026-11-10** | T4-04 completo. La unión, cuando la ordene el propietario: el PR de B primero y el de A después, **antes del 11-11** (zona S de D1 en `RevocacionSesiones.cs`, del 11-11 al 11-13) |

Efecto mientras el PR de A no esté unido: en Release, los programados de reportes fallan cerrados y queda el registro. En Debug sin el reenvío se conserva el camino local (`TrabajoNotificaciones.cs:60-61`) [V]. Hoy todo es desarrollo. Si el DEMO tiene reglas programadas, dejan de enviar en ese intervalo: se avisa a quien prueba el DEMO.

---

## 5. P-1 (para el propietario)

B apoya la opción (a): nunca se emite un token de servicio para el SUPER. Además del argumento de A (ADR-81 y ADR-92), hay evidencia de que el token no serviría aunque se emitiera: en Release, `ExigeOtpSuper` es obligatorio (`ValidadorTokenPrincipal.cs`, `OpcionesSegundoFactor.Resolver`) [V], y la API de reportes rechaza todo token de nivel SUPER sin `amr = otp` (`AutenticacionIntrospeccion.cs:113-116`) [V]. Un token `amr = prg` del SUPER daría 401 `factor`.

**Qué rompe:** las reglas guardadas por el SUPER dejan de enviarse; el mensaje pide que las guarde un ADMIN.
**A quién afecta:** a quien prueba el DEMO, si guardó reglas como SUPER.
**Por qué:** un acceso del SUPER desatendido y sin factor.
**Cómo se migra:** guardar de nuevo la regla con un ADMIN de la empresa.

---

## 6. Riesgos que agrega B

| Id | Riesgo | Prob. / impacto | Mitigación |
|---|---|---|---|
| RB-1 | Sin PDF en la exportación de la API de reportes, el formato por omisión de las reglas falla | Cierta hasta construirlo / Medio | PDF en `exportar` dentro de T4-04 o de T4-02 (0,5 a 0,75 dp) |
| RB-2 | El reintento de F-5 retrasa los demás envíos hasta 90 s | Baja / Bajo | Tope de 90 s y ejecución secuencial ya existente |
| RB-3 | `UseRouting` antes de la autenticación no está garantizado | Baja / Medio | A lo verifica; si no, filtro de *endpoint* global |

---

### Cierre
- Estado: Completado (recomendación de B; pendiente del acuerdo con A y de la firma de P-1)
- Artefactos: `C:\Users\lfmen\AppData\Local\Temp\claude\C--Users-lfmen-source-repos-Solucion-GPOS-NG-GPOS-NG\a8083c99-fe36-432e-bde4-46ec95e0ccbd\scratchpad\frontera-token-f1-f5-recomendacion.md`
- Supuestos: un solo servidor de API (ADR-24); `UseRouting` antes de la autenticación en la API de reportes [I]; los encabezados del cliente HTTP se ocultan por omisión desde .NET 8 [I]; el PDF de la exportación cuesta de 0,5 a 0,75 dp [I]; D5 llega después del 20-nov.
- Decisiones candidatas a ADR: precisión de ADR-109 cl. 6 y 7: (1) token de servicio opaco con sesión técnica en memoria, nunca validado en local, ni siquiera con ES256 (C-1.1); (2) un token `prg` solo abre la exportación de su reporte, con una lista blanca por metadatos; (3) P-1, sin token para el SUPER (firma del propietario).
- Entregas a otros agentes: arquitecto-software de A → contrato separado antes del 10-30, constructor de pruebas, F-3 por metadatos y F-2 (b); propietario → P-1; auditor-seguridad → revisar el PR de A del 11-06 y el de B; D5 → mismo verificador de acceso del autor (F-4); D2 → C-1.1.
- Próximo paso recomendado: enviar esta respuesta a A antes del 2026-10-28 y llevar P-1 al propietario en la misma tanda.
