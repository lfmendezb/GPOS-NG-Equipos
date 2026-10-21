# Plan de pruebas de N-1: `GPOS.Api` en modo servicio (Windows y systemd)

```
Para: B (coordinador, desarrollador y devops de B); copia a A (PR-4 de ADR-90)     De: C (QA)     Fecha: 2026-10-20
Tipo: Plan de pruebas (solo diseño: no se programó, compiló ni ejecutó nada)
Encargo: avisos/B-a-C/2026-10-20-nuevas-tareas-para-c.md, tarea 3
Rama de B: b/n1-api-modo-servicio (ventana 2026-10-28 a 2026-11-06; terminar antes del 2026-11-02)  → no existe todavía en origin
Estado: Completado (pendiente de las preguntas de la sección 7)
```

## 0. Resumen

- **Orden del middleware:** se fija con una **prueba de arquitectura sobre el texto de `Program.cs`**, dirigida por una tabla de pares «A antes que B». No se puede inspeccionar la tubería real sin levantar el host, y el host levanta SQL (sección 2.2). La tabla hace que A (PR-4) y DB-7 (T1) agreguen una fila, no una prueba nueva.
- **Hoy no existen en la API HTTPS redirigido, HSTS ni CORS** [V]. No se fijan como obligatorios; se fijan como reglas condicionales («si aparecen, van aquí»).
- **Hallazgo de orden con consecuencia de seguridad:** `UseLicencia` decide con `ctx.GetEndpoint()` y, si es nulo, deja pasar (`ModoLicencia.cs:29-33`). Un `UseRouting` explícito colocado después de él abriría la barrera de la licencia en silencio. La regla A-05 lo impide.
- **Lo que casi todo el plan necesita de B:** que el registro del modo servicio, las opciones del anfitrión, el registro de eventos y la comprobación `ARRANQUE_PRIVILEGIOS` vivan en una clase propia (como `ModoEstacion`), no dentro de `Program.cs`. Sin esa costura, cada prueba del modo servicio exige levantar la API con SQL (pregunta P-1).
- **Tres riesgos que el plan no puede cerrar con pruebas automáticas** y que conviene decidir antes de unir (sección 6): trabajo largo **antes** de `app.Run()` frente al límite de 30 s del administrador de servicios, dirección de escucha del servicio mientras PR-4 no esté unido, y que `GPOS.Api` **sí lanza un proceso** (Chrome o Edge, para el PDF), lo que contradice la premisa de la lista de privilegios de A.
- **Ninguna prueba de la suite instala, arranca ni consulta servicios.** Lo que exige un servicio real va a una lista de pasos de laboratorio (sección 4) para la VM-SRV del diseño del laboratorio de ADR-90, nunca la PC del propietario. Una prueba de arquitectura (B-08) lo vigila.

## 1. Alcance, fuentes y hechos verificados

**Alcance.** El código de N-1: `AddWindowsService` y `AddSystemd` en `GPOS.Api`, el directorio de contenido, el registro en el Visor de eventos, los tiempos de arranque y de parada, y `ARRANQUE_PRIVILEGIOS`. Quedan fuera: el MSI (A/devops de B, O-1, O-3), la lista de privilegios (A la propone; B la mide), el verbo `tls`, las unidades de systemd (tanda LN de ADR-129) y N-10.

**Fuentes leídas** (con `git show`/`git grep`, sin checkout): `origin/feature/modelo-ng` `b8f166db` (código de referencia, que es donde vive el trabajo reciente), `origin/master` `d064656c` (ADR), `origin/a/adr90-rt01-modo-red` `8c99f9cf` (PR-1a, #122); en el área común, `traspasos/A/blueprint-instalador-o1-o3-n10-2026-10-20.md`, `traspasos/A/blueprint-adr90-rt01-rt05-rt06-2026-10-20.md`, `traspasos/B/2026-10-20-respuestas-b-a-los-planos-de-a.md` y `traspasos/C/2026-10-20-diseno-laboratorio-adr090.md`.

**Hechos que condicionan el plan** (todos [V] salvo marca):

| # | Hecho | Evidencia |
|---|---|---|
| H1 | La tubería de la API, en orden: `UseForwardedHeaders`, `UseSinCache`, `UseLimiteCuerpo`, `UseExceptionHandler`, `UseAuthentication`, `UseRateLimiter` (condicional a `limites.Habilitado`), `UseAuthorization`, `UseFiltroFactor`, `UseAutenticacionReciente`, `UseCambioClaveObligatorio`, `UseModoEsquemaPendiente`, `UseVersionEsquemaEmpresa`, `UseModoCandadoRestauracion`, `UseGuardaSitio`, `UseLicencia` | `src/GPOS.Api/Program.cs:349,351,353,360,371,373,374,376,378,381,383,385,387,389,392` |
| H2 | No hay `UseHsts`, `UseHttpsRedirection`, `UseCors`/`AddCors`, `UseRouting` ni `UseEndpoints` en la API. HSTS y la redirección están solo en la Web | `git grep` en `src/GPOS.Api`, `src/GPOS.Core`, `src/GPOS.Comun`; `src/GPOS.Web/Program.cs:106,109` |
| H3 | Entre `builder.Build()` (línea 338) y `app.Run()` (línea 455) hay trabajo con SQL, anillo y licencia: `ComprobacionAnillo.EjecutarAlArrancarAsync` (430), `Inicializacion.EjecutarAsync` (431), `EstadoLicenciaService.ArrancarAsync` (434), `TrabajoVigilanciaRestauracion.ComprobarAlArrancarAsync` (445) | `Program.cs:338-455` |
| H4 | `GPOS.Api` no tiene `AddWindowsService` ni `AddSystemd`, ni referencia al paquete de servicios de Windows. Existen en `GPOS.Reportes.Api/Program.cs:24` y en `ModoEstacion.cs:17` | `git grep`; `src/GPOS.Api/GPOS.Api.csproj`; paquete `Microsoft.Extensions.Hosting.WindowsServices` 10.0.12 ya usado por Reportes, el agente y citado en `GPOS.Migracion.csproj:18`. **`Microsoft.Extensions.Hosting.Systemd` no está en el repositorio** |
| H5 | Ninguna prueba del repositorio nombra `WindowsService`, `ServiceName`, `IHostLifetime`, `StopApplication` ni `ShutdownTimeout` | `git grep` en `tests/` |
| H6 | `ServiciosWindows.Api = "GPOS.Api"` ya existe y lo usa el verbo del anillo para decidir si la API está «detenida». Si el servicio se registra con otro nombre, el verbo lo toma por «no instalado» | `src/GPOS.Comun/Servicios/ServiciosWindows.cs:11-15`; `MantenimientoAnilloSellosTests.cs:512-523` |
| H7 | `UseLicencia` usa `ctx.GetEndpoint()` y `ctx.User`; con endpoint nulo, deja pasar | `src/GPOS.Api/Seguridad/ModoLicencia.cs:27-33` |
| H8 | `UseLimiteCuerpo` también depende de `GetEndpoint()` («va después del enrutamiento implícito») | `src/GPOS.Api/Seguridad/LimitesPeticiones.cs:195-199` |
| H9 | `GPOS.Api` lanza un navegador Chromium con PuppeteerSharp para el PDF de los formatos personalizados, con perfil en `Path.GetTempPath()` | `src/GPOS.Api/Impresion/ConvertidorPdf.cs:66-82` |
| H10 | `Path.GetTempPath()` se usa en tres sitios de la API | `ConvertidorPdf.cs:66`, `Endpoints/RncDgiiEndpoints.cs:40`, `Servicios/TrabajoRncDgii.cs:156` |
| H11 | Sin `Kestrel:Endpoints` ni `urls` en `appsettings.json` de la API. El 5071 sale solo de `launchSettings.json` (no se publica) y del `ASPNETCORE_URLS` del DEMO | `src/GPOS.Api/appsettings.json`; `src/GPOS.Api/Properties/launchSettings.json:8`; `instalador/Demo/scripts/herramientas/Comun-Demo.ps1:344` |
| H12 | Los servicios de fondo de la API esperan con el token (`PeriodicTimer.WaitForNextTickAsync(ct)`, `Task.Delay(…, ct)`) | `TrabajoVigilanciaRestauracion.cs:36-39`, `TrabajoRespaldosPosteriores.cs:19-24`, `TrabajoRncDgii.cs:76-79,192`, `TrabajoNotificaciones.cs:108-111`, `TrabajoReloj.cs:17-35`, `TrabajoPurgaBitacoraSeguridad.cs:18-24` |
| H13 | Levantar `Program` con `WebApplicationFactory<Program>` ejecuta también el tramo entre `Build` y `Run`, porque las pruebas actuales necesitan SQL y la base del sistema se crea al levantar la API [I: la mecánica interna de .NET no se leyó; la evidencia es el comportamiento de `ApiMvpFactory`] | `tests/GPOS.Tests/Mvp/ApiMvpFactory.cs:17-21` |
| H14 | Bloque `#if DEBUG`: `MapOpenApi` y `Inicializacion.CreaCuentasAlArrancar`. La suite corre en Debug; el servicio, en Release | `Program.cs:368-370`; `Inicializacion.cs:17-21` |

## 2. La prueba de arquitectura del orden del middleware

### 2.1 Qué debe fijar

Una **tabla de reglas** `(Antes, Después, Obligatoria, Motivo)`, evaluada sobre las posiciones de texto de las llamadas `app.Use…(` de `Program.cs` (sin comentarios). Cada regla se justifica con un comentario del código o un ADR; las que no tienen justificación escrita no entran (van en 2.4).

| Regla | Antes → Después | ¿Obligatoria hoy? | Motivo y evidencia |
|---|---|---|---|
| R1 | `UseFiltroOrigenNodo` → `UseForwardedHeaders` | Condicional; A la vuelve obligatoria en PR-4 | El filtro mira la IP de la **conexión**, nunca `X-Forwarded-For` (ADR-90 RT-06, PT-05; blueprint de A, 5.3 «Posición») |
| R2 | `UseForwardedHeaders` → todo otro `app.Use…`, salvo `UseFiltroOrigenNodo` | Sí | «Primer middleware de la API» (blueprint de A, líneas 40 y 280; `Program.cs:349`). `LimitesPeticiones.Ip` y los frenos por IP leen la IP ya corregida |
| R3 | `UseExceptionHandler` → `UseAuthentication` | Sí | `ManejarErrorAsync` traduce `AccesoDenegado`, `ReglaNegocio`, etc. Los eventos de `AddJwtBearer` (`OnTokenValidated` consulta `RevocacionSesiones`, con SQL) y todo lo posterior deben quedar bajo el manejador |
| R4 | `UseAuthentication` → `UseRateLimiter` | Sí (cuando exista) | Comentario `Program.cs:372`: «el límite general es por usuario cuando hay sesión válida» |
| R5 | `UseAuthentication` → `UseAuthorization` | Sí | Autorización sin identidad no tiene sentido |
| R6 | `UseAuthentication` → `UseFiltroFactor`, `UseAutenticacionReciente`, `UseCambioClaveObligatorio`, `UseModoEsquemaPendiente`, `UseVersionEsquemaEmpresa`, `UseModoCandadoRestauracion`, `UseLicencia` | Sí | Leen la sesión (`ctx.User`). `UseLicencia` lo exige en `ModoLicencia.cs:33`. **[I]** que los otros seis leen `ctx.User`: por sus comentarios en `Program.cs:376-388`; B lo confirma (pregunta menor en 7) |
| R7 | `UseCambioClaveObligatorio` → `UseModoEsquemaPendiente` | Sí | Comentario `Program.cs:379-380`: «va antes del modo limitado» |
| R8 | `UseModoEsquemaPendiente`, `UseVersionEsquemaEmpresa`, `UseModoCandadoRestauracion`, `UseGuardaSitio` → `UseLicencia` | Sí | Comentario `Program.cs:390-391`: la licencia «va aquí, al final, después de las respuestas de infraestructura» |
| R9 | `UseRouting` explícito (si aparece) → `UseLimiteCuerpo`, `UseRateLimiter`, `UseAuthorization`, `UseLicencia`, `UseGuardaSitio` | Condicional (hoy no hay `UseRouting`: H2) | H7 y H8: sin endpoint, la licencia deja pasar y el tope de cuerpo no se aplica. Alternativa admitida: que no haya `UseRouting` ni `UseEndpoints` explícitos |
| R10 | `UseHttpsRedirection` / `UseHsts` (si aparecen) → `UseAuthentication`, y después de `UseForwardedHeaders` | Condicional | Si algún día se agregan (hoy ADR-90 RT-05 no abre el puerto 80), el esquema reenviado debe ser el correcto antes de redirigir. Requeriría ajustar `ForwardedHeaders`, que hoy solo reenvía `XForwardedFor` (`Program.cs:51`) |
| R11 | `UseCors` (si aparece) → `UseAuthentication`, y después del enrutamiento | Condicional | Un rechazo de CORS no debe pasar por la autenticación; hoy no hay CORS en la API |

**Orden de arranque** (misma clase, mismo texto). Es el contrato de «falla cerrada» de N-1 y de ADR-90 RT-01:

| Regla | Contenido | Motivo |
|---|---|---|
| S1 | `AddWindowsService`/`UseWindowsService` y `AddSystemd`/`UseSystemd` están presentes y antes de `builder.Build()` | ADR-129, bloque B.1 («registra a la vez»); F-5 |
| S2 | La comprobación `ARRANQUE_PRIVILEGIOS` aparece antes de `ComprobacionAnillo.EjecutarAlArrancarAsync`, antes de `Inicializacion.EjecutarAsync` y antes de `app.Run()` | Vector v2 de ADR-77: orden «identidad, privilegios, carpetas, Data Protection» (`EstacionInstaladorTests.cs`, aserción de `ordenAlArrancar`); nada que toque datos corre antes |
| S3 | `ExigirArranque(app, red)` (PR-4 de A) va después de `builder.Build()` y antes de `Inicializacion.EjecutarAsync` | Blueprint de A, sección 7, punto 2, y regla 3 de PR-4. Condicional hasta PR-4 |
| S4 | Hay un solo `app.Run()` (o `RunAsync`) y no queda ninguna instrucción de arranque después | Con el servicio, `Run` es donde el anfitrión se conecta al administrador de servicios |

### 2.2 Cómo detectarlo sin levantar el host

| Opción | Veredicto | Costo [I] |
|---|---|---|
| **(a) Análisis del texto de `Program.cs`** con tabla de pares y un evaluador probado con programas sintéticos | **Recomendada.** Neutral (sin SQL), instantánea, ya es el patrón del repositorio: `LicenciaSinInterruptoresTests` (QA-L06) y `SellosEnLaApiTests` leen `Program.cs` con `Select(Trim)` y comparan posiciones | 0,5 dp |
| (b) Inspeccionar la tubería real con `WebApplicationFactory<Program>` | **No viable.** Los middleware son delegados anónimos y `WebApplication` construye la tubería en un constructor propio [I]: solo se llegaría a ella con reflexión sobre campos privados. Además, levantar `Program` exige SQL (H13) | — |
| (c) Pares de comportamiento con el host real (p. ej. IP de la conexión suplantada desde un `IStartupFilter`) | **Solo para dos pares con efecto observable** (ver D-01 y E-03). Cada uno exige SQL y base temporal | 0,3 dp cada uno |
| (d) Extraer la cadena a `UseCanalizacionGpos(this WebApplication)` y probarla con un `IApplicationBuilder` que registra | Descartada por ahora: cambia producción en la zona S de DB-7 sin riesgo concreto que la justifique. Se reabre si (a) resulta frágil | 1 dp |

**Robustez del evaluador (para no depender de la forma):**
- Posiciones de texto de `\bapp\.(Use\w+)\(` tras quitar comentarios `//` y `/* */`; el `if (limites.Habilitado) app.UseRateLimiter();` cuenta como presente-condicional por configuración; `MapOpenApi` queda fuera (está bajo `#if DEBUG`).
- Un patrón con `\bbuilder\.Build\(\)` y `\bapp\.Run(Async)?\(` para S1 a S4, como `AnilloFueraDeWindowsArquitecturaTests` (`Cada_programa_llama_al_Configurar_con_guarda_antes_de_construir`).
- El evaluador se prueba a sí mismo con programas sintéticos, igual que `La_guarda_de_Program_reconoce_UseLicencia_condicionado`: desorden detectado, línea comentada ignorada, filtro antes de encabezados aceptado, sin `UseRouting` aceptado, `UseRouting` tardío rechazado.

### 2.3 Nombres exactos

Archivos en `tests/GPOS.Tests/Arquitectura/` (carpeta que `PruebasNeutralesTests` ya excluye del detector de SQL), con `[Trait("Esquema","Neutral")]` y `[Trait("Categoria","ServicioApi")]`:

- `ProgramaApiTexto.cs`: ayudante estático (no es una clase de pruebas). Une los tres `LineasPrograma()` que hoy se repiten; las otras dos clases pueden seguir con el suyo hasta que alguien las toque.
- **`OrdenProgramaApiTests`**:
  - `Cada_regla_de_orden_de_la_tuberia_se_cumple` — `[Theory]` con `[MemberData(nameof(Reglas))]`; falla con «R3: UseExceptionHandler debe ir antes de UseAuthentication (motivo)».
  - `Los_middleware_obligatorios_estan_una_sola_vez_y_sin_condicion` — `UseForwardedHeaders`, `UseExceptionHandler`, `UseAuthentication`, `UseAuthorization`. (`UseLicencia` ya lo vigila QA-L06; no se duplica.)
  - `Los_encabezados_reenviados_son_el_primer_middleware_salvo_el_filtro_de_origen_de_nodo` (R2).
  - `El_filtro_de_origen_de_nodo_si_existe_va_antes_de_los_encabezados_reenviados` (R1; A lo cambia a obligatorio en PR-4 poniendo `Obligatoria = true` en su fila).
  - `No_hay_UseRouting_explicito_o_va_antes_de_los_middleware_que_leen_el_endpoint` (R9).
  - `Si_aparecen_HSTS_redireccion_a_HTTPS_o_CORS_respetan_su_posicion` (R10 y R11).
  - `El_modo_servicio_se_registra_antes_de_construir_el_anfitrion` (S1).
  - `Las_comprobaciones_de_arranque_van_antes_que_cualquier_acceso_a_datos` (S2 y S3).
  - `App_Run_es_la_ultima_instruccion_de_arranque` (S4).
  - `El_evaluador_de_orden_detecta_los_desordenes_y_ignora_los_comentarios` — `[Theory]` con programas sintéticos.

### 2.4 Qué no debe fijar (para que no se rompa con cambios legítimos)

- **Números de línea**, sangría, nombres de variables (`app`, `builder`) ni comentarios.
- **El orden relativo entre `UseFiltroFactor`, `UseAutenticacionReciente`, `UseVersionEsquemaEmpresa`, `UseModoCandadoRestauracion` y `UseGuardaSitio`** más allá de R6 a R8. Ningún comentario ni ADR lo exige, y ADR-81 y DB-7 siguen agregando piezas.
- **La posición de `UseSinCache` y `UseLimiteCuerpo` frente a `UseExceptionHandler`.** `UseSinCache` fija sus encabezados en `OnStarting` (`AutenticacionReciente.cs:52-62`), así que ambos órdenes son válidos.
- **`UseRateLimiter` frente a `UseAuthorization`** (hoy va antes; el comentario solo exige que vaya después de la autenticación).
- **La sección `builder.Services…`**: DB-7 quita `Jwt:Clave` y su guarda de arranque (`Program.cs:60`), y mueve `OnTokenValidated` a `ValidacionAcceso` (blueprint v3, líneas 465 y 693). Ninguna regla se ancla ahí.
- **La posición de los `app.Map…`** frente a los `app.Use…` (el middleware de punto final se agrega al final de todos modos [I]).
- **Que HSTS, redirección o CORS existan** (H2).
- **El orden entre `ARRANQUE_PRIVILEGIOS` y `ExigirArranque`**, hasta que B y A lo fijen (pregunta P-3). Solo se fija que ambos preceden a los datos.
- **La forma de registrar el servicio** (`builder.Services.AddWindowsService` o `builder.Host.UseWindowsService`): el regex admite ambas; lo que se fija es el efecto (grupo C).

### 2.5 Coordinación con PR-4 de A y con DB-7

- El blueprint de A (sección 8) promete en PR-4 «una prueba de arquitectura sobre el texto de `Program.cs`». **Propuesta:** que sea la **fila R1 y S3 de esta tabla**, no una clase aparte. Se evita una segunda copia del evaluador y un choque de nombres.
- Las pruebas de texto **no están** en la zona S de DB-7 (están en `tests/`). Solo se leen. Si T1 de DB-7 agrega un `app.Use…`, la tabla no cambia salvo que la pieza tenga una regla documentada.

## 3. Lo que sí se puede probar sin instalar el servicio

Convención: **Hoy** = comportamiento con el código de `feature/modelo-ng` `b8f166db`: «Rojo» falla porque N-1 no existe; «Verde» es una guardia que ya pasa y protege la regresión. Las pruebas viven en `tests/GPOS.Tests`. Salvo indicación, el filtro es `--filter "Categoria=ServicioApi"`; las que no necesitan SQL se corren con `--filter "Categoria=ServicioApi&Esquema=Neutral"`. El filtro oficial de la suite (`Transicion!=Ola5&Transicion!=Defecto`) no cambia.

### 3.1 Grupo A · Orden (clase `OrdenProgramaApiTests`, Neutral, texto)
Ver 2.3. Hoy: **Verde** salvo `Las_comprobaciones_de_arranque_van_antes_que_cualquier_acceso_a_datos`, `El_modo_servicio_se_registra_antes_de_construir_el_anfitrion` (no existe el registro) y las filas condicionales sin pieza, que pasan en vacío.

### 3.2 Grupo B · Arquitectura del modo servicio (clase `ModoServicioArquitecturaTests`, Neutral, texto y reflexión)

| ID | Prueba | Afirma | Hoy |
|---|---|---|---|
| B-01 | `El_nombre_del_servicio_sale_de_ServiciosWindows_Api_y_no_de_un_literal` | La llamada de registro usa `ServiciosWindows.Api`; no hay un literal `"GPOS.Api"` en ella. Cierra el riesgo de H6 | Rojo |
| B-02 | `ServiciosWindows_Api_vale_GPOS_Api_y_su_cuenta_virtual_es_NT_SERVICE_GPOS_Api` | La constante y la cuenta `NT SERVICE\GPOS.Api` (la usarán el MSI y `sc qc`) | Verde |
| B-03 | `Program_de_GPOS_Api_no_exige_Windows` | Sin `throw new PlatformNotSupportedException` ni `if (!OperatingSystem.IsWindows())` de primer nivel (a diferencia de `GPOS.Reportes.Api/Program.cs:14`). ADR-129 pide un binario en dos modos | Verde |
| B-04 | `Los_paquetes_de_alojamiento_de_servicio_usan_la_misma_version` | `GPOS.Api.csproj` referencia `Hosting.WindowsServices` (y `Hosting.Systemd`) con la versión de Reportes y del agente (hoy 10.0.12) | Rojo |
| B-05 | `Ningun_servicio_de_fondo_de_la_API_espera_sin_el_token_de_cancelacion` | En `BackgroundService` de `src/GPOS.Api` y `src/GPOS.Core`: ningún `Task.Delay(` sin token, `Thread.Sleep`, `.Wait(`, `.GetAwaiter().GetResult()` ni `.Result` en `ExecuteAsync` | Verde (H12) |
| B-06 | `La_comprobacion_ARRANQUE_PRIVILEGIOS_no_tiene_interruptor` | Los archivos de la comprobación no leen `IConfiguration`, variables de entorno, `IsDevelopment()` ni usan `#if DEBUG` (patrón de QA-L06). Su único condicionante es «corre como servicio» | Rojo |
| B-07 | `Las_llamadas_a_la_plataforma_del_modo_servicio_estan_en_archivos_Windows_o_Linux` | La lectura del token (`OpenProcessToken`, `GetTokenInformation`) solo en `*.Windows.cs`, con `[SupportedOSPlatform("windows")]`. **Reutilizar la prueba de ADR-129, B.5, de A** (`RedPlataformaArquitecturaTests` solo cubre `GPOS.Comun/Red`) ampliando su carpeta | Rojo |
| B-08 | `Ninguna_prueba_de_la_suite_instala_o_arranca_servicios` | Ningún `.cs` de `tests/` (salvo `Laboratorio/Servicio/` y este archivo) contiene `sc(.exe) create/delete/config/start/stop`, `New-Service`, `Start-Service`, `Stop-Service`, `msiexec`, `InstallUtil`, `ManagedInstallerClass` ni `new ServiceController(`. Es la garantía de «no instalar servicios en la PC del propietario» | Verde |
| B-09 | `Los_eventos_del_modo_servicio_estan_en_su_franja_y_los_de_arranque_son_criticos` | Con `EventIdUnicosTests.Declarados()`: los números de N-1 caen en la franja que fije B (P-2), no chocan, y `ARRANQUE_*` se registra en `LogCritical` | Rojo |

### 3.3 Grupo C · Modo servicio sin instalar (clase `ModoServicioApiTests`; Neutral si B aporta la costura de P-1; si no, `Esquema=NG` con `ApiMvpFactory`)

| ID | Prueba | Afirma | Hoy |
|---|---|---|---|
| C-01 | `Registrar_fija_el_nombre_del_servicio_y_el_origen_del_Visor_de_eventos` | `IOptions<WindowsServiceLifetimeOptions>.Value.ServiceName == ServiciosWindows.Api`; `IOptions<EventLogSettings>.Value.SourceName == ServiciosWindows.Api` y `LogName == "Application"` [I: que `AddWindowsService` complete `SourceName` si está vacío; la prueba lo comprueba] | Rojo |
| C-02 | `Fuera_del_servicio_el_IHostLifetime_no_es_el_de_Windows_ni_el_de_systemd` | En consola (proceso de pruebas) `WindowsServiceHelpers.IsWindowsService()` y `SystemdHelpers.IsSystemdService()` son falsos y el `IHostLifetime` no es `WindowsServiceLifetime` ni `SystemdLifetime`. Protege la regla «consola para desarrollo, DEMO y pruebas» (N-1, 2026-10-19). **Guarda:** si el ejecutor corre como servicio, la prueba se omite con un mensaje, no falla | Rojo (no hay registro) |
| C-03 | `En_modo_servicio_la_raiz_de_contenido_es_la_carpeta_del_binario` | Con la costura `Opciones(args, esServicio: true)`, `ContentRootPath == AppContext.BaseDirectory`; con `false`, el valor por omisión. En servicio el directorio de trabajo es `System32` [I: documentación de Microsoft, no verificada hoy] | Rojo |
| C-04 | `Con_la_raiz_del_binario_appsettings_y_el_archivo_de_instalacion_se_leen_en_su_orden` | Con una carpeta temporal como raíz: `appsettings.json` < archivo de instalación (`AgregarArchivoInstalacion("GPOS.Api", ruta)`) < variables de entorno < argumentos. No usa `GPOS__ArchivoInstalacion__Carpeta` (es global al proceso y rompe el paralelismo) | Rojo |
| C-05 | `El_Visor_de_eventos_recibe_las_categorias_GPOS_desde_Information` | Regla de filtro para el proveedor de Visor de eventos con prefijo `GPOS` ≤ `Information`, como en la estación (`ModoEstacion.cs:19`); conserva las tres categorías de `appsettings.json` (`Logging:EventLog`). Solo inspecciona las opciones: **no escribe** en el Visor | Rojo |
| C-06 | `El_tiempo_de_cierre_del_anfitrion_es_el_declarado` | `IOptions<HostOptions>.Value.ShutdownTimeout` es el valor que B fije (propuesta: explícito y menor que el tiempo que se mida en el laboratorio L-09; no se deja al valor por omisión sin decirlo) | Rojo |
| C-07 | `Los_privilegios_sobrantes_se_calculan_contra_la_lista_declarada` | Tabla como `Un_privilegio_fuera_de_la_lista_declarada_impide_arrancar`: `[]`, `[SeChangeNotifyPrivilege]` → ok; `[SeImpersonatePrivilege, SeChangeNotifyPrivilege, SeCreateGlobalPrivilege]` → `[SeCreateGlobalPrivilege, SeImpersonatePrivilege]` en orden ordinal | Rojo |
| C-08 | `La_lista_declarada_de_privilegios_es_solo_SeChangeNotifyPrivilege` | `PrivilegiosDeclarados == ["SeChangeNotifyPrivilege"]` (propuesta de A, sección 3.1). Cuando A y el laboratorio cambien la lista, se cambia aquí y en el MSI (F-01) | Rojo |
| C-09 | `El_mensaje_de_ARRANQUE_PRIVILEGIOS_lista_solo_nombres_de_privilegios` | Sin cadenas de conexión, rutas ni valores de configuración (C10; patrón de `Las_advertencias_no_llevan_valores_ni_saltos_de_linea`) | Rojo |
| C-10 | `ARRANQUE_PRIVILEGIOS_solo_se_comprueba_cuando_el_proceso_corre_como_servicio` | `DebeComprobar(esServicio: false)` es falso; con `true`, verdadero. En consola el token de un desarrollador tiene privilegios de sobra y la API debe arrancar igual | Rojo |
| C-11 | `Lee_los_privilegios_del_token_del_proceso` | `[SupportedOSPlatform("windows")]`: contiene `SeChangeNotifyPrivilege` y, en el ejecutor de desarrollo, privilegios sobrantes (como `EstacionImpresionTests.cs:56-63`) | Rojo |

### 3.4 Grupo D · Arranque y parada con el host real (clase `CicloDeVidaApiTests : ApiMvpFactory`, `Esquema=NG`, SQL)
Corren solas, como el resto de suites con SQL (regla del proyecto: una suite a la vez).

| ID | Prueba | Afirma | Hoy |
|---|---|---|---|
| D-01 | `Arranca_en_consola_y_atiende_salud_con_el_modo_servicio_registrado` | `GET /api/salud` → 200; `IHostLifetime` no es el del servicio; la API arranca con el registro presente. Es la humo de regresión de A («arranca igual que hoy») | Verde mientras no haya registro; Rojo con C-02 |
| D-02 | `StopApplication_detiene_el_anfitrion_dentro_del_tiempo_de_cierre` | `IHostApplicationLifetime.StopApplication()` dispara `ApplicationStopping` y `ApplicationStopped` en menos del `ShutdownTimeout` (techo de la prueba: 10 s; es un presupuesto sobre una base vacía, no una medición de producción); `RegistroErrores` sin entradas de nivel `Error` o `Critical` | Verde (guardia) |
| D-03 | `Todos_los_servicios_de_fondo_registrados_se_detienen_al_cancelar` | Resuelve `IEnumerable<IHostedService>`, comprueba que están los siete conocidos (`TrabajoPurgaBitacoraSeguridad`, `TrabajoVigilanciaRestauracion`, `TrabajoRespaldosPosteriores`, `TrabajoRncDgii`, `TrabajoNotificaciones`, `TrabajoReloj`, `TrabajoLicencia`) y que `StopAsync` termina en menos de 5 s | Verde (guardia) |

### 3.5 Grupo E · Falla cerrada de ADR-90 RT-01 (clase `FallaCerradaArranqueApiTests`; **se agregan al unir PR-4 de A**)

| ID | Prueba | Afirma |
|---|---|---|
| E-01 | `En_Estricto_sin_modo_de_red_la_API_no_arranca_y_no_toca_la_base` | `GPOS:Seguridad:ModoIdentidad=Estricto` con una fuente de registro falsa «sin modo»: levantar el host lanza `ArranqueRedException` con `EventosRed.ConfiguracionInvalida` (4743); y **la base de pruebas no se creó** (`DB_ID(...) IS NULL`): la falla ocurre antes de `Inicializacion` (S3) |
| E-02 | `Sin_modo_y_sin_Estricto_la_API_arranca_solo_en_loopback_con_el_evento_4745` | Arranca y deja el aviso 4745 |
| E-03 | `El_filtro_de_origen_de_nodo_rechaza_con_la_IP_de_la_conexion_aunque_X_Forwarded_For_diga_otra` | Par de comportamiento con el host real: un `IStartupFilter` de la prueba fija `RemoteIpAddress`; vale la pena porque verifica R1 con la tubería real. Las pruebas del filtro de A (PR-3) usan `TestServer` propio y no cubren esto |
| E-04 | `Con_ARRANQUE_PRIVILEGIOS_rechazado_la_API_no_toca_la_base` | Con una costura que devuelva privilegios sobrantes: igual que E-01, con el evento de N-1 |

### 3.6 Grupo F · MSI de la API (cuando exista `instalador/Api/Package.wxs`; análisis de XML, no instala)
Mismo patrón que `EstacionInstaladorTests`. Las escribe quien construya el MSI (devops de B); se listan para que la rama de N-1 deje los nombres reservados.

| ID | Prueba | Afirma |
|---|---|---|
| F-01 | `El_servicio_GPOS_Api_se_instala_con_la_cuenta_virtual_y_solo_SeChangeNotifyPrivilege` | `ServiceInstall/@Name == ServiciosWindows.Api`, `@Account == NT SERVICE\GPOS.Api`, sin `Password`, sin `ServiceSid`, `RequiredPrivilege` igual a C-08 en `OnInstall` y `OnReinstall` |
| F-02 | `La_recuperacion_es_60_segundos_tres_veces_con_contador_diario` | Según A (sección 3.2): 60 s, 3 veces, reinicio del contador a 1 día, `FailureActionsWhen="failedToStopOrReturnedError"` |
| F-03 | `El_origen_del_Visor_de_eventos_se_llama_como_el_servicio` | `EventSource/@Name == ServiciosWindows.Api` (iguala C-01) |
| F-04 | `El_arranque_automatico_espera_a_SQL_Server_o_es_diferido` | Depende de lo que decida B para el riesgo R-1 |
| F-05 | `El_MSI_no_pasa_direcciones_de_escucha` | Sin `--urls`, `ASPNETCORE_URLS` ni `Kestrel:Endpoints`: ADR-90 los rechaza cuando hay modo (`ArranqueRed.ClavesDeEscucha`, rama `a/adr90-rt01-modo-red`) |
| F-06 | `El_SID_de_la_cuenta_virtual_es_el_que_calcula_Windows` | Constante medida con `sc.exe showsid GPOS.Api` en la VM (como `EstacionImpresionTests.cs:36-44`). Requiere la medición del laboratorio L-02 |

## 4. Lo que no se puede probar sin instalar el servicio, y quién lo cubre

| Qué | Por qué no hay prueba automática | Quién lo cubre |
|---|---|---|
| Configuración del servicio en el administrador: cuenta, tipo de inicio, privilegios requeridos, acciones de recuperación, SID | Existe solo después de `ServiceInstall` | **Estática:** F-01 a F-03 y F-06 (XML del MSI). **Medida:** devops de B con `sc.exe qc/qprivs/qfailure/qsidtype/showsid` en VM-SRV (L-02) |
| Token real del proceso con `RequiredPrivilege` | Solo un servicio de la cuenta `NT SERVICE\GPOS.Api` lo tiene | C-07 y C-11 prueban la lógica; **L-04 y L-05** la medida y el negativo, en VM |
| Arranque, parada y reinicio por el SCM; límite de 30 s; error 1053 | El SCM no se puede simular | **L-03, L-07, L-08** (devops de B) |
| Recuperación ante fallos (60 s × 3, contador diario) | Exige matar el proceso real | **L-06** |
| Apagado del equipo con peticiones en curso | Depende del SCM y de `WaitToKillServiceTimeout` [I] | **L-09** |
| Corte brusco durante la emisión de documentos y de números (atomicidad) | Exige proceso real y carga | **L-10**, con las consultas de verificación de huecos y duplicados de numeración |
| Eventos en el Visor (origen registrado por el MSI, niveles, visibilidad) | Escribir en el Visor exige el origen registrado y privilegios de administrador | C-01/C-05 prueban la configuración; **L-03 y L-14** la visibilidad real, incluido el caso «origen no registrado» |
| Lectura de `%ProgramData%\GPOS NG\config\GPOS.Api.json` bajo la cuenta virtual, y las ACL de ADR-77 | Las ACL las pone el MSI de A (O-1 y O-3) | C-04 prueba las capas; **L-11** la lectura real y el rechazo de claves no permitidas |
| Directorio de contenido real (`System32`) | No se cambia el directorio de trabajo del proceso de pruebas sin romper el paralelismo | C-03 prueba la costura; **L-12** lo comprueba en el servicio |
| Conexión a SQL Server con la identidad del servicio | Depende de cómo se asigne el login de la API (RG-14) | **L-13** (devops de B con arquitecto-datos) |
| PDF (Chrome o Edge), temporales y descarga del padrón RNC bajo la cuenta virtual | H9 y H10 | **L-15** |
| Acceso a la llave del certificado del anillo (H-17 v2) y a la carpeta de licencia como servicio | Lo dan el verbo `tls` y las ACL de A | **L-16** con A |
| Equivalente Linux (`Type=notify`, `Restart=on-failure`, `journalctl`) | Sin unidad de systemd hasta la tanda LN (ADR-129, C11) | **Declarado, no probado.** Se cubre con `VM-LNX` (Ubuntu 24.04) cuando exista la unidad; el registro de `AddSystemd` se prueba solo como no-op (C-02) |
| Actualización y desinstalación del MSI | Es de A (N-10) | Fuera de N-1 |

### 4.1 Lista de pasos del laboratorio (para devops de B en `VM-SRV`)

**Reglas.** Solo en la VM del diseño del laboratorio de ADR-90 (sección 3 de `traspasos/C/2026-10-20-diseno-laboratorio-adr090.md`) y con sus guardas LS-11 (marcador en `HKLM\SOFTWARE\GPOS NG\LaboratorioTls\Id` o su equivalente para este laboratorio, variable `GPOS_LAB_*`, nombre del equipo en la lista, comprobación de virtualización). **Nunca** en la PC del propietario ni en OSHIN-LEGION. Antes de cada caso: punto de control. Sin MSI, el servicio se crea con un guion del laboratorio (`sc.exe create` con `obj= "NT SERVICE\GPOS.Api"` y `sc.exe privs`); con MSI, se instala el paquete. Ninguna evidencia lleva cadenas de conexión ni tokens.

| ID | Caso | Pasos | Resultado esperado |
|---|---|---|---|
| L-01 | Preparación | Publicar `GPOS.Api` en Release; crear el servicio; `sc.exe sidtype GPOS.Api unrestricted` (ADR-76, punto 5) | Servicio detenido, cuenta `NT SERVICE\GPOS.Api` |
| L-02 | Configuración medida | `sc.exe qc`, `qprivs`, `qfailure`, `qsidtype`, `showsid GPOS.Api` | Coinciden con F-01, F-02 y F-06; el SID se copia como constante |
| L-03 | Ciclo normal | `sc.exe start GPOS.Api`; esperar `RUNNING`; `GET /api/salud`; `sc.exe stop`; medir tiempos; leer el Visor | Arranca sin 1053; para en menos de `ShutdownTimeout`; origen y niveles correctos; sin errores |
| L-04 | Privilegios positivos | Con `RequiredPrivilege = SeChangeNotifyPrivilege`, leer el evento de comprobación (o `whoami /priv` desde el proceso) | Token con la lista exacta; arranque correcto |
| L-05 | Privilegios negativos | `sc.exe privs GPOS.Api SeChangeNotifyPrivilege/SeImpersonatePrivilege`; arrancar; restaurar | `ARRANQUE_PRIVILEGIOS` en el Visor (Crítico), proceso sale con código ≠ 0, sin puerto abierto |
| L-06 | Recuperación | Con el servicio activo: `taskkill /f` del proceso, cuatro veces espaciadas | Reinicio a los 60 s las tres primeras; al día siguiente (o con el contador) se reinicia el conteo |
| L-07 | Arranque con el equipo y SQL | Reiniciar la VM con SQL Server en inicio automático (normal), luego en diferido, luego detenido | Registrar si la API arranca, falla o reintenta; fija R-1 y F-04 |
| L-08 | Arranque lento | Detener SQL Server, arrancar la API; medir hasta `RUNNING` o error | Registrar si aparece 1053 y cuánto tarda; decide P-4 |
| L-09 | Apagado del equipo | Con un bucle de peticiones de consulta activo, `shutdown /r /t 0` | Parada limpia en el tiempo previsto; evento de parada; fija C-06 |
| L-10 | Corte durante la emisión | Con 20 ventas en paralelo (guion de la API), `taskkill /f`; luego consultar numeración | Sin documentos huérfanos, sin huecos ni duplicados de número (principio «número al final del guardado») |
| L-11 | Configuración de instalación | Crear `GPOS.Api.json` con `GPOS:RncDgii:Url` y con una clave no permitida | Se aplica la primera; la segunda se ignora con aviso; los usuarios sin privilegios no pueden escribir el archivo |
| L-12 | Directorio de contenido | Colocar un `appsettings.json` marcado junto al binario; arrancar | Lo lee; no se crea nada en `C:\Windows\System32` |
| L-13 | SQL como servicio | Arrancar con la cadena de conexión definitiva | Conecta; sin errores de inicio de sesión |
| L-14 | Visor sin origen | Quitar el origen del registro (solo en la VM) y arrancar | Registrar el comportamiento (R-6); el código de salida debe bastar para el SCM |
| L-15 | PDF y temporales | Generar un PDF de un formato personalizado y cargar el padrón RNC; después `sc.exe stop` | Funciona o falla con mensaje claro; no queda `msedge.exe`/`chrome.exe` huérfano; ubicación de `TEMP` registrada |
| L-16 | Anillo y licencia | Arranque en Estricto con el anillo protegido por certificado | `ComprobacionAnillo` y la carpeta de licencia pasan como servicio (con A) |
| L-17 | Linux (declarado) | `VM-LNX`: `systemctl status`, `journalctl -u gpos-api` | No se ejecuta hasta la tanda LN |

## 5. Relación con lo existente

**`GPOS.AgenteImpresion` (estación), que ya corre como servicio:**
- *Cómo está hecho:* `Program.cs` despacha `--estacion` a `ModoEstacion.EjecutarAsync` (`Host.CreateApplicationBuilder`, `AddWindowsService(o => o.ServiceName = …)`, proveedor de Visor con origen igual al nombre del servicio y filtro `GPOS` ≥ `Information`: `ModoEstacion.cs:13-24`). `ServicioEstacion.ComprobarArranque()` compara **identidad → privilegios → carpetas** y, si falla, hace `LogCritical` y `Environment.Exit(1)` (`ServicioEstacion.cs:263-286`). `IdentidadServicio` calcula el SID de la cuenta virtual y lee los privilegios del token por P/Invoke.
- *Cómo está probado:* `EstacionImpresionTests` (SID medido con `sc.exe showsid`, `PrivilegiosSobrantes`, lectura real del token, rechazo de identidad fuera del servicio, DACL y credencial) y `EstacionInstaladorTests` (análisis del XML de `Package.wxs`: cuenta, argumento, `RequiredPrivilege` exacto, sin `ServiceSid`, origen del Visor, DACL del vector v2). Todos son `Esquema=Neutral` y `[SupportedOSPlatform("windows")]`.
- *Lo que **no** se prueba hoy:* el resultado de `AddWindowsService`, el nombre del servicio registrado, la configuración del Visor, ni los tiempos de parada. Reportes (`Program.cs:24`) tampoco. **N-1 no debe repetir ese hueco**: por eso los grupos B, C y D y la costura de P-1.
- *Qué se reutiliza:* los nombres de pruebas y el esquema (`PrivilegiosSobrantes`, `Lee_los_privilegios_del_token_del_proceso`), el análisis de XML del MSI (grupo F) y el SID medido en VM.
- *Diferencia que importa:* la estación sale con `Environment.Exit(1)` desde un servicio hospedado, **después** de que el anfitrión ya se conectó al SCM. En la API la comprobación debe ir **antes** de los datos (S2), es decir, antes de `app.Run()`, y entonces el administrador de servicios aún no fue notificado (R-1, R-6, P-3).

**ADR-77.** La raíz `%ProgramData%\GPOS NG\config` es carpeta de componente. Hoy el proceso **no** comprueba su DACL (`ArchivoInstalacion` lo dice) y VS-2 (N-11 a N-15) no se construye antes de la prueba D4. N-1 solo exige leerla bajo la cuenta virtual (L-11); el vector v2 de la comprobación de arranque sigue siendo identidad → privilegios → carpetas → Data Protection (S2).

**ADR-90.**
- PR-1a (#122) ya está en `origin/a/adr90-rt01-modo-red`: `EvaluacionArranqueRed` es `ArranqueRed.Evaluar`, y `ArranqueRedException`/`EventosRed` (4743 a 4746) son los tipos que usan E-01 y E-02. `RedPlataformaArquitecturaTests` es la prueba de B.5 que B-07 amplía.
- PR-4 es posterior a N-1 en la ventana (F-5). Las filas R1 y S3 y el grupo E se activan entonces.
- Con modo presente, ADR-90 rechaza `urls`, `http_ports`, `https_ports` y `Kestrel:Endpoints` (`ArranqueRed.ClavesDeEscucha`). El servicio instalado no debe traerlos (F-05), y el DEMO debe quitar su `ASPNETCORE_URLS` al adoptar el paquete (blueprint de A de ADR-90, «Entregas a otros agentes»).

**ADR-129.** Bloque B.1: `AddWindowsService` y `AddSystemd` a la vez, cada uno sin efecto fuera de su plataforma [I, inferido en el ADR]; B.5: CA1416 como error y prueba de arquitectura (B-07). Falla cerrada B.2: la comprobación de privilegios no tiene implementación aprobada en Linux, y un componente sin implementación no debe arrancar (no fallar abierto). C-10 fija que en consola no se comprueba; qué pasa bajo systemd lo decide B (P-3).

**DB-7.** `Program.cs` es zona S; T1-1 a T1-4 caen el 11-09 y la zona está congelada del 11-11 al 11-13; la condición firmada de F-5 es terminar antes del 11-02. Las pruebas de este plan están en `tests/` y no tocan la zona S; el riesgo es de rebase de B, no de las pruebas.

## 6. Riesgos

| ID | Riesgo | Evidencia | Sev. [I] | Qué lo cubre |
|---|---|---|---|---|
| R-1 | **Trabajo largo antes de `app.Run()`.** Con el servicio, el anfitrión se conecta al SCM en `Run`; todo lo anterior (SQL, anillo, licencia, esquema: `Program.cs:430-445`) cuenta contra el límite de arranque del SCM (30 s por omisión [I: documentación de Microsoft, no verificada hoy]; error 1053). Además, con inicio automático, SQL Server puede no estar listo al encender el equipo, y la API no tiene dependencia ni reintento | H3; `Inicializacion.cs` | Alta | L-07 y L-08; decisión de B: dependencia de servicio, inicio diferido o reintento; F-04. **No hay prueba automática** |
| R-2 | **Dirección de escucha del servicio hasta que PR-4 entre.** Sin `urls` ni `Kestrel:Endpoints`, un servicio escucharía en el valor por omisión de Kestrel (`http://localhost:5000` [I]), no en 5071, que es lo que espera la Web (`GPOS.Web/appsettings.json:14`) | H11 | Alta | P-4; L-03 (`GET /api/salud` en el puerto esperado) |
| R-3 | **La API lanza un proceso (Chrome o Edge) para el PDF.** El blueprint de A justifica no pedir `SeAssignPrimaryTokenPrivilege` y similares porque «no hay `Process.Start`/`ProcessStartInfo`» (sección 3.1), pero PuppeteerSharp sí lanza el navegador. Bajo una cuenta virtual, en sesión 0, con perfil en `TEMP`, puede fallar o dejar procesos huérfanos | H9 | Media (Alta si el PDF es del flujo de la entrega 1) | L-15; entrega a A (revisar la justificación de la sección 3.1) y a B (decidir si el PDF funciona en modo servicio) |
| R-4 | `Path.GetTempPath()` bajo la cuenta virtual cae en un directorio distinto del de un usuario (descarga del padrón RNC, perfil del navegador). ADR-77 aplica a `Reportes\temp`, no a estos | H10 | Media | L-15 |
| R-5 | **Parada.** Si una tarea de fondo o una petición larga tarda más que el tiempo que el SCM concede al apagar el equipo (`WaitToKillServiceTimeout`, 5 s por omisión [I]), el proceso se mata con transacciones abiertas | H12 | Media | D-02, D-03, B-05, C-06; L-09 y L-10 |
| R-6 | **Falla cerrada que nadie ve.** Si el origen del Visor no está registrado, el evento crítico puede perderse en silencio [I] y solo queda el código de salida. Y una falla antes de `app.Run()` puede no figurar como parada con error para la recuperación del SCM [I] | `ServicioEstacion.cs:263-271` | Media | F-02, F-03, L-05 y L-14; P-3 |
| R-7 | La suite corre en **Debug**; el servicio corre en **Release**. `#if DEBUG` cambia el arranque (cuentas iniciales, sellado, OpenAPI) | H14 | Media | Pruebas de texto (cubren ambos); L-03 a L-16 con la publicación Release |
| R-8 | **Choque en `Program.cs`** entre N-1, PR-4 (A) y T1 de DB-7 | `Program.cs` zona S; F-5 | Media | Tabla de reglas (2.1); orden de uniones de F-5 |
| R-9 | `WindowsServiceHelpers.IsWindowsService()` es verdadero si el ejecutor de pruebas corre como servicio (agente de CI) y C-02 fallaría | — | Baja | Guarda de C-02 (se omite con mensaje) |
| R-10 | Paquete nuevo `Microsoft.Extensions.Hosting.Systemd` en el repositorio. ADR-129 pide `AddSystemd` pero la política de paquetes del propietario (actualizar solo por vulnerabilidad o versión estable) no está citada en ADR-129 | H4 | Baja | B-04; P-6 |
| R-11 | La comprobación de privilegios solo cubre Windows; en Linux sigue sin equivalente aprobado (ADR-129, C-tabla) | ADR-129 B.2 | Baja (entrega posterior) | Declarado |

**Cobertura.** La política por omisión (70 % de líneas del código modificado en módulos críticos; N-1 es seguridad) se mide sobre las piezas nuevas. Quedan **sin cobertura automática**: la rama «es servicio» del arranque real, la conexión con el SCM y la rama Linux. Se cubren con el laboratorio y se declaran en el informe de QA del PR.

## 7. Preguntas para B

1. **P-1 · Costura.** ¿Pondrá el registro del servicio, las opciones del anfitrión (`ContentRootPath`), la configuración del registro de eventos, el `ShutdownTimeout` y `ARRANQUE_PRIVILEGIOS` en una clase aparte (por ejemplo `src/GPOS.Api/Servicio/ModoServicioApi.cs`, con `Opciones(args, esServicio)`, `Registrar(IServiceCollection, ILoggingBuilder)` y `ComprobarArranque()`), como `ModoEstacion`? Es la **recomendación de QA**: los grupos B y C quedan Neutral y sin SQL, y se reduce el roce con la zona S. Si no, el grupo C se hace con `ApiMvpFactory` (más lento y con SQL).
2. **P-2 · EventId.** ¿Qué franja usará N-1? Las libres son 4767 a 4779 (de `GPOS.Instalacion`, de B) y 4790 a 4799 (reserva de DB-7). Propuesta de QA: tres números: `ARRANQUE_PRIVILEGIOS` (Crítico), servicio iniciado y servicio detenido (Información), y, si quiere, uno de Información con la lista de privilegios presentes (útil para L-04).
3. **P-3 · Forma de fallar.** ¿`Environment.Exit(1)` como la estación, o una excepción antes de `app.Run()`? Y, en systemd/Linux, ¿«falla cerrada sin implementación» (ADR-129, B.2) o se omite? Define el código de salida que ve el SCM y la prueba E-04. Y el orden respecto de `ExigirArranque` de A (se propone: identidad y privilegios primero, luego el modo de red, luego el anillo, luego los datos).
4. **P-4 · Escucha del servicio** mientras PR-4/PR-2 de A no entren (R-2): ¿cómo se fija el puerto en la ventana 10-28 a 11-06?
5. **P-5 · Tiempo de arranque (R-1):** ¿se acepta medirlo en L-07/L-08 y decidir allí entre dependencia de SQL, inicio diferido o reintento? ¿Umbral propuesto? QA sugiere ≤ 20 s en frío con SQL listo.
6. **P-6 · Paquete de systemd (R-10):** ¿lo cubre ADR-129 B.1 sin otra firma? Misma versión 10.0.12.
7. **P-7 · Quién escribe las pruebas.** Propuesta: **C escribe los grupos A y B** (solo texto y reflexión) en un PR apilado sobre `b/n1-api-modo-servicio`, para que lleguen antes del 11-02; **el desarrollador de B** escribe C y D junto con el código (necesitan la costura); **devops de B** escribe F y ejecuta el laboratorio. Si prefiere otro reparto, la tabla de la sección 3 es el contrato.
8. **P-8 (menor)** · ¿Confirma que `UseFiltroFactor`, `UseAutenticacionReciente`, `UseCambioClaveObligatorio`, `UseModoEsquemaPendiente`, `UseVersionEsquemaEmpresa` y `UseModoCandadoRestauracion` leen la sesión (R6)? Si alguno no, se saca de la regla.

## 8. Esfuerzo y calendario (días-persona, ±50 %, [I])

| Pieza | Quién | dp |
|---|---|---|
| Ayudante y grupos A y B | C (PR apilado) | 0,75 |
| Grupos C y D | Desarrollador de B | 0,75 |
| Grupo E (tras PR-4) | A o B | 0,25 |
| Grupo F | Devops de B | 0,25 |
| Guiones y ejecución del laboratorio (L-01 a L-16) | Devops de B | 1,5 |
| Revisión de privilegios (L-04, L-05, R-3) | Auditor-seguridad | 0,25 |
| **Total** | | **≈ 3,75** |

**Calendario sugerido:** respuestas a P-1 a P-3 antes del 10-24; grupos A y B listos el 10-27 (verdes en `feature/modelo-ng` salvo los rojos esperados); grupos C y D con el PR de N-1 (10-28 a 11-01); laboratorio L-01 a L-10 el 11-02 a 11-04, antes de que A abra PR-4; grupo E con PR-4. La suite completa, sola, antes de unir (regla del proyecto).

## 9. Supuestos y alternativas descartadas

**Supuestos:**
- El código de referencia es `feature/modelo-ng` `b8f166db`; la rama `b/n1-api-modo-servicio` no existe aún, así que no se pudo ver el diseño real de B.
- La ventana de F-5 está firmada según la nota de ADR-90 (`origin/master:docs/adr/ADR-090.md:265`).
- [I] marcan afirmaciones de plataforma (comportamiento del SCM, `WindowsServiceHelpers`, valores por omisión de Kestrel) no verificadas en esta sesión: no se compiló ni ejecutó nada.

**Alternativas descartadas** (además de las de 2.2): una prueba de proceso hijo (`Process.Start` de `GPOS.Api.exe` con otro directorio de trabajo) para el directorio de contenido, porque exige SQL, es lenta y su resultado se obtiene mejor en L-12; y una prueba automática que cree un servicio de verdad, por la regla de no instalar servicios.

### Cierre
- Estado: Completado
- Artefactos: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\C\2026-10-20-plan-pruebas-n1-api-servicio.md`
- Supuestos: código de referencia `feature/modelo-ng` `b8f166db` porque `b/n1-api-modo-servicio` no existe; afirmaciones de plataforma marcadas [I]; nada se compiló ni ejecutó
- Decisiones candidatas a ADR: Ninguna
- Entregas a otros agentes: B (desarrollador) → P-1 a P-3, grupos C y D, `EventIdUnicosTests` ampliado; B (devops) → grupo F y laboratorio L-01 a L-16 en VM; A (arquitecto) → revisar la justificación de privilegios por el hallazgo R-3 (PuppeteerSharp lanza un proceso) y absorber R1/S3 en la tabla en lugar de una prueba aparte en PR-4; auditor-seguridad → L-04, L-05 y R-3
- Próximo paso recomendado: B responde P-1 a P-3 antes del 10-24 para que C deje listos los grupos A y B el 10-27
