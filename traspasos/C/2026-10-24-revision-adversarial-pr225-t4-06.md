Para: B (copia a A, dueño de T4-06)        De: C        Fecha: 2026-10-24
Tipo: Revisión adversarial (encargo B-a-C/2026-10-23-tareas-nuevas-para-c-tanda-8, punto 1)
Prioridad: Alta
Repositorio y rama: GPOS-NG #225 `a/t4-06-lista-p2` @ 7394790a (solo lectura), base `feature/modelo-ng` (merge-base `b9efa9fb`; punta actual `1b310591`, con el #217 unido)
Estado: Abierto

Convención: [V] = lo comprobé con un comando y su resultado en mi equipo; [I] = inferido del código o de la documentación. El árbol es el worktree de C en 7394790a, en HEAD separado. No cambié el PR, no lo comenté y no empujé nada.

Las pruebas hostiles fueron un archivo temporal sin commit (`tests/GPOS.Tests/Mvp/RevisionCPr225Tests.cs`, 9 casos), que ya borré del worktree. Hay copia en `traspasos/C/2026-10-24-revision-adversarial-pr225-t4-06-pruebas.cs.txt`; el último bloque de esa copia es la variante de T6-46b con el emisor real, que va dentro de `NotificacionesReportesTests` después de unir el #217. SQL local: `.\SQLEXPRESS`. Compilé una sola vez a la vez.

# Veredicto

**Aprobado con observaciones** (recomendación técnica; la decisión es del propietario, C2). **T4-06 se puede unir con dos condiciones previas, las dos baratas:**

1. **Rebasar sobre `feature/modelo-ng` actual** (con el #217). Hoy GitHub marca el PR como `CONFLICTING`: el conflicto está en `NotificacionesReportesTests.cs`, no en `TrabajoNotificaciones.cs` como prevé el PR (H225-02). Ensayé la unión resolviendo el conflicto con los dos lados y todo lo pertinente pasa (abajo).
2. **Arreglar la guarda textual `P2_la_lista_ya_no_existe…`.** Su expresión regular contiene caracteres de control (retroceso, 0x08) donde debía decir `\b`, así que no detecta nada (H225-01). Es un arreglo de 5 minutos.

No hay hallazgos Críticos ni Altos. Hay tres de severidad Media (H225-01 a H225-03), cuatro Bajas y una observación anterior al PR, fuera de su alcance.

**M-2 del #217 se cierra con este PR.** `Caracterizacion_pendiente_hoy_…` está invertida (T6-46b, sección 2), la mutación que la devuelve a la principal la pone en rojo [V], y la variante con el **emisor real** del #217 también pasa sobre la unión de ensayo [V]. Con la unión, el riesgo queda cerrado en código.

| Tema del encargo | Resultado |
|---|---|
| ¿Están los ~70 casos T6-xx? | De los 68 casos del plan: **21 cubiertos, 16 parciales, 22 ausentes, 8 no aplican y 1 sin verificar** (sección 3). Los imprescindibles (`*`) que faltan o quedaron huecos son T6-01 (hueco), T6-02, T6-47 (hueco), T6-51 y T6-62 |
| ¿Se invierte `Caracterizacion_pendiente_hoy_…` (T6-46b)? | **Sí** [V]. Renombrada a `Un_programado_de_un_reporte_antes_P2_del_SUPER_o_de_un_autor_inhabilitado_ya_no_se_envia_y_pasa_por_el_emisor`, sin `EnLaPrincipal`. Exige `Enviado = false`, la denegación con su motivo, sin correo ni evidencia y cero peticiones |
| P-1: 403 `DISENO_NO_PERMITIDO` | Se sostiene [V]: el 403 sale como 403 y nunca como 503 (mutación M5 en rojo). Guardar con la API de reportes **real** también funciona: SQL sobre `rpt` da 200 y SQL sobre tablas da 4xx (mis C-26 y C-28). Fallan los bordes: un 500 de la API llega como 500 con el detalle de la API, y un 200 con JSON mal formado da 500 (H225-04) |
| P-2: falla cerrada de programados y «Ejecutar ahora» | Se sostiene [V]. `Modo` perdió `enLaPrincipal`; el camino local está bajo `#if DEBUG`; Release compila (BLD-2) y Release con DEBUG no compila (BLD-3). Las mutaciones M2 y M3 se detectan |
| P-3: la principal Release no arranca en Linux | Se sostiene **por el código** [V lectura]: sin dirección no arranca por `ValidarModo` y con dirección no arranca por el control de Windows anterior. **No hay prueba que lo fije**: la mutación M8 sobrevive (H225-06) |
| Q-A4: 403 `SUCURSAL_NO_PERMITIDA` en Debug | Implementado en `ReportesService.Ejecucion.cs:62-67` y `:73`, leído de la cuenta del servidor [V]. La prueba de A solo cubre a un ADMIN con un alcance falso: si el control se limita al ADMIN (M4b), su suite no lo nota y mi C-51 sí (H225-05) |
| P-4: `CompilacionDepuracion` | Se sostiene [V]. El marcador está en `ReenvioReportes.cs` y `PublicarPaqueteDemoTests` pasa; con él, el guion del DEMO exige `-ConApiReportes` (`Publicar-PaqueteDemo.ps1:84-87`) |
| Reutiliza `ReenvioReportes.NoDisponible()` | **Sí** en las 5 rutas de `ReportesEndpoints.cs` (`#else return ReenvioReportes.NoDisponible();`) [V]. Guardar usa su propio 503 (`ReglaNegocioException` con `REPORTES_NO_DISPONIBLE` y el texto «el reporte no se guardó»), porque el servicio vive en Core y no puede llamar a la API. Es aceptable, aunque el código queda escrito dos veces (`ReportesService.CodigoNoDisponible`) |

# 1. Alcance y superficie revisada

- Diff completo `b9efa9fb..7394790a`: 16 archivos, +1023/−535.
  - Código: `ReenvioReportes.cs`, `ReportesEndpoints.cs`, `DetectorColumnasReenvio.cs` (nuevo), `TrabajoNotificaciones.cs`, `GPOS.Core.csproj`, `IDetectorColumnas.cs` (nuevo), `ReportesService.cs`, `ReportesService.Ejecucion.cs` (nuevo) y `ReportesSemilla.cs`.
  - Pruebas: `AuditoriaAdr109Tests`, `SqlSoloEnLugaresPermitidosTests`, `SemillaReportesOla5Tests`, `NotificacionesReportesTests`, `ReenvioReportesModoTests` (nuevo), `ReenvioReportesT406Tests` (nuevo) y `ReportesF9Tests`.
- Contraparte que lee el código nuevo: `GPOS.Reportes.Api/Endpoints/EndpointsReportes.cs:96-103` (`/detectar`, que devuelve `List<ReporteColumnaDto>`, el mismo contrato que deserializa la principal) y `GPOS.Reportes/Ejecucion/ErroresLectura.cs:89-90`.
- Superficie expuesta:
  - `GET /api/reportes` (lista, ahora siempre local);
  - `GET|POST /api/reportes/{id}…` (reenviadas);
  - `POST /api/admin/reportes` (Guardar, local en `GPOS_SYSDATA`, que ahora llama a la API de reportes con el token del ADMIN);
  - el trabajo de notificaciones (programados) y «Ejecutar ahora».
- Contraste: mi plan v3 (`traspasos/C/2026-10-23-plan-pruebas-t4-06.md`, casos T6-xx), la descripción del PR y el diff del #217 (`b9efa9fb..1b310591`).

# 2. Corridas [V]

| # | Árbol | Comando o filtro | Resultado |
|---|---|---|---|
| R-1 | PR | `dotnet build tests/GPOS.Tests -c Debug` (BLD-1) | 0 errores |
| R-2 | PR | `GPOS.Reportes.Tests`, `AuditoriaAdr109Tests` | 19/19 (coincide con el PR) |
| R-3 | PR | `GPOS.Tests`: `ReenvioReportesModoTests`, `ReenvioReportesT406Tests`, `NotificacionesReportesTests`, `ReportesF9Tests`, `SemillaReportesOla5Tests` | **62/62** en 44 s |
| R-4 | PR | `dotnet build src/GPOS.Api -c Release` (BLD-2) | 0 errores y 3 advertencias; la única nueva es CS9113 (`factory` sin leer en `ReportesService.cs:25`, declarada en el PR). El criterio «0 advertencias nuevas» del plan no se cumple, pero la advertencia es inocua |
| R-5 | PR | BLD-3: `GPOS.Core` y `GPOS.Api` en Release con `DefineConstants=DEBUG;TRACE` (cada uno con `BuildProjectReferences=false`) | Los dos fallan con su guarda: `GPOS.Core.csproj(61)` (Q-6, nueva) y `GPOS.Api.csproj(50)` (DL-02). En la compilación de la solución corta antes `GPOS.Criptografia.csproj(34)` (CR-04) |
| R-6 | PR + mis 9 casos | `RevisionCPr225*` | 7 pasan; **2 fallan, y cada falla demuestra un hallazgo**: C-22 y C-23 (H225-04) |
| R-7 | PR + mis casos | Conjunto amplio: `(…Reportes\|…Alcance\|…Arquitectura\|…Instalador\|…Notificaciones\|…Exportacion)&Transicion!=Ola5&Transicion!=Defecto` | 988 en total y 985 superadas. Las 3 fallas son mías: C-22 y dos de `PruebasNeutralesTests`, que protestan contra mi archivo temporal porque mezcla `Neutral` y `NG`. **Ninguna falla es del PR** |
| R-8 | **Unión de ensayo** PR + `origin/feature/modelo-ng` `1b310591` (conflicto resuelto con los dos lados) + mi variante de T6-46b con el emisor real | `NotificacionesReportesTests`, `ReenvioReportes*`, `TokenServicio*`, `ReportesF9Tests`, `SemillaReportesOla5Tests` y los míos | **141/143**. Fallan solo C-22 y C-23 (esperado). Pasa la variante `C225_T6_46b_con_el_emisor_real…` |
| R-9 | Unión de ensayo | `GPOS.Reportes.Tests` completa | **823/823** en 6 min 28 s |

Después de R-8 y R-9 hice `git merge --abort` y `git status` quedó limpio. Logs en el scratchpad de la sesión (`pr225/corrida-*.log`).

No corrí la suite oficial completa de `GPOS.Tests`. El PR tampoco la declara.

# 3. Plan T6-xx contra el PR

C = cubierto, P = parcial, A = ausente, NA = no aplica (duda abierta o verificación humana), NV = no verificado. `*` = imprescindible en el plan.

| Bloque | Casos | Detalle |
|---|---|---|
| 2.A Semilla y lista | C 2 · P 3 · A 4 | **T6-01\* P (hueca, H225-01).** T6-02\* A: no hay guarda por reflexión de `EnLaPrincipal` ni de `EnLaPrincipalAsync`. T6-03\* C (`Ningun_SQL_del_sistema_lee_tablas` y la teoría `DeVistas`, que ahora corre las 11 con `gpos_reportes`). T6-04 P (la regla de `*Base` existe, pero no hay fixture con dos monedas). T6-05 C (implícito en `AnalizarDisenador`). T6-06, T6-07 y T6-08 A (sin paridad con el oráculo, sin enlaces y sin prueba nueva de `HuellasVersion1`). T6-09 P (`lista.Count >= 26`) |
| 2.B Lista local y 503 | C 2 · P 1 · A 6 | T6-10\* y T6-11\* C (`La_lista_la_responde_la_principal…`). T6-14\* P: la lista sin `reenvio` se fija; que no haya un 503 propio en un literal, no. T6-12, T6-13, T6-15, T6-16, T6-17\* y T6-18 A |
| 2.C P-1 | C 4 · P 3 · A 2 · NA 3 | T6-20\* C. T6-21\* P (solo el 403; mi C-429 pasa). **T6-22\* A, y mi prueba falla (H225-04).** **T6-23 A, y mi prueba falla.** T6-24 P (comprueba el token; «sin token no llama» no tiene prueba). T6-25 C (`DisenoReportesRestringidoTests`, anterior). T6-26\* C. T6-27 C. T6-28 P (`Assert.NotEqual(OK)` en F9 es débil; mi C-28 fija un 4xx y pasa). T6-29 a T6-31 NA (D-1) |
| 2.D P-2 | C 4 · P 4 · A 1 | T6-40\* C. T6-41\* C. T6-42\* P. T6-43 A. T6-44\* P (el mecanismo está en `ProveedorContextoTests`, pero no hay prueba de punta a punta con un autor sin «Ver costos»). T6-45\* P (`Q6_…solo_existe_en_Debug`). T6-46\* C. **T6-46b\* C.** **T6-47 P (hueca, H225-03)** |
| 2.E Q-6 y P-3 | C 2 · P 2 · A 4 | T6-60\* C. T6-61 P. **T6-62\* A (M8 sobrevive, H225-06).** T6-63 A. T6-64\* P (comprobación textual de `ComprobarDebugCoherente`; BLD-3 lo corrí yo). T6-65\* C. T6-66 y T6-67 A |
| 2.F Q-A4 | P 2 · A 5 · NA 3 | T6-50\* P: es de unidad, con un ADMIN y un alcance falso; no pasa por HTTP ni cuenta conexiones. **T6-51\* A (M4b sobrevive; lo cubre mi C-51).** T6-52 A (lo cubre mi C-51 con `ExportarAsync`). T6-54 A. T6-55\* A (lo cubre mi C-55). T6-56 P (lo cubre mi C-56 contra `SucursalNoPermitidaException`). T6-57\* A en el PR, aunque el diseño lee la cuenta (`AlcanceAlmacenes.cs:100-101`). T6-53, T6-58 y T6-59 NA (D-5, D-7 y D-8) |
| 2.G P-4 | C 3 · NA 1 | T6-70\* C (`PublicarPaqueteDemoTests` en R-7). T6-71 y T6-72 C (sin cambios). T6-73 NA (verificación humana; el PR lo pide) |
| 2.H Reescrituras | C 4 · P 1 · NV 1 · NA 1 | T6-80 P: prueba **10 de 11** códigos y omite `CXC-ESTADO-CUENTA` sin decir por qué [I: filtro de cliente obligatorio]. T6-81, T6-82, T6-83 y T6-85 C. T6-84 NV. T6-86 NA |
| 2.I Compilación | BLD-1, BLD-2 y BLD-3 [V]; BLD-4 no corrida (el PR no toca `GPOS.Reportes.Api`); RUN-1 parcial (R-7) | |

**Total: 68 casos. C 21 · P 16 · A 22 · NA 8 · NV 1.** Las ausencias de 2.B y 2.F son las que más conviene cerrar después de la unión. Mis C-51, C-55 y C-56 ya están escritas y pasan.

# 4. Mutaciones [V]

Una a la vez, compilando y restaurando con `git checkout -- <archivo>`. Después de cada una, `git status` mostraba solo mi archivo de pruebas.

| # | Mutación | Suite del PR | Mis pruebas |
|---|---|---|---|
| **M1** | Volver a declarar `public static readonly HashSet<string> EnLaPrincipal = …{"CXP-FACTURAS"}` en `ReportesSemilla` | **No la detecta**: `AuditoriaAdr109Tests` sigue 19/19 (H225-01) | Con `\b` en lugar del 0x08, la guarda la detecta: «ReportesSemilla.cs todavía usa la lista P-2» |
| M2 | `Modo`: `reenvioHabilitado ? Principal` | La detecta (17 en rojo, T6-46b incluida) | — |
| M3 | P-2 por código en los programados (`Modo(reenvio.Habilitado && !(def.DelSistema && def.Codigo is "CXP-FACTURAS" or "CXP-PAGOS"), …)`) | La detecta: `Los_reportes_antes_de_la_lista_P2_programados_van_a_la_API…`, **T6-46b** y `Un_programado_de_un_reporte_P2_modificado…` | — |
| M4 | Quitar `await ExigirSinRestriccionDeSucursalAsync(ct)` (`Ejecucion.cs:73`) | La detecta: `En_Debug_sin_la_API_de_reportes_un_restringido_recibe_403…` | C-51 también |
| **M4b** | Exigir la restricción solo al ADMIN: `if (sesion.EsAdmin && !await alcance.SinRestriccionAsync(ct))` | **No la detecta** (H225-05) | C-51 la detecta |
| M5 | `DetectarAsync`: todo rechazo pasa a 503 `REPORTES_NO_DISPONIBLE` (`ReenvioReportes.cs:172`) | La detecta: `Un_403_de_la_API_de_reportes_nunca_se_vuelve_503` | C-429 y C-28 también |
| M6 | Guardar ignora el detector (`if (false && detector is …)`) | La detectan 6 (`ReenvioReportesModoTests` y `ReenvioReportesT406Tests`) | — (F9 no la ve: el camino local también rechaza `banco.DocBanco`) |
| M7 | `ValidarModo` solo actúa en Linux | La detecta: `En_Release_la_principal_no_arranca_sin_el_reenvio` | — |
| **M8** | Quitar el control `!OperatingSystem.IsWindows()` de `AgregarReenvioReportes` (`:426`) | **No la detecta** ninguna prueba (26/26 en `ReenvioReportes*` y `PublicarPaqueteDemoTests`) (H225-06) | — (desde Windows no se puede sin una costura) |
| **M11** | La evidencia del programado por la API de reportes sin el autor (`TrabajoNotificaciones.cs:162`, `regla.UsuarioModificacion` → `null`) | **No la detecta** (18/18, `AE_02` incluida) (H225-03) | — |

# 5. Hallazgos

| ID | Severidad | Título |
|---|---|---|
| H225-01 | **Media** | La guarda `P2_la_lista_ya_no_existe…` no detecta nada: su regex lleva caracteres de retroceso (0x08) en lugar de `\b` |
| H225-02 | **Media** | El PR no se puede unir tal como está: entra en conflicto con el #217 en `NotificacionesReportesTests.cs` |
| H225-03 | **Media** | `AE_02` quedó hueca: el criterio «programado con la regla y quien la guardó» no se verifica en el único camino de Release |
| H225-04 | Baja | En Guardar, un 500 de la API de reportes llega como 500 con el detalle de la API, y un 200 con JSON mal formado da 500 |
| H225-05 | Baja (pruebas) | Q-A4 solo se prueba con un ADMIN y un alcance falso: el USER restringido no está fijado (M4b) |
| H225-06 | Baja (pruebas) | P-3 (Linux) no tiene costura ni prueba (M8) |
| H225-07 | Baja (pruebas) | Faltan T6-02, T6-12, T6-13, T6-15 y T6-17; T6-80 omite `CXC-ESTADO-CUENTA` |
| OBS-01 | Baja, **anterior al PR** | La misma corrupción (0x08) vacía la excepción de `DireccionIp.cs` en `La_API_de_reportes_no_abre_conexiones_salientes…` |

## H225-01 (Media): la guarda de la lista P-2 está hueca

- **Riesgo.** El cierre de P-2 lo vigila `AuditoriaAdr109Tests.P2_la_lista_ya_no_existe_y_ningun_reporte_del_sistema_lee_fuera_de_rpt`. Su primera mitad (que `EnLaPrincipal`, `IntactoEnLaPrincipal` y `EnLaPrincipalAsync` no vuelvan) no puede fallar nunca.
  - En el archivo, la regex es `0x08(Intacto)?EnLaPrincipal(Async)?0x08`: dos caracteres de control de retroceso donde debía ir `\b`. El visor del diff no los muestra.
  - Lo confirmé con `od -c` sobre `AuditoriaAdr109Tests.cs:40`, y con una prueba de depuración que ejecuta el mismo bucle: con la regex limpia, el bucle encuentra `TrabajoNotificaciones.cs` (por `ReporteEnLaPrincipalAsync`, sin `\b`); con la del archivo, nada.
  - Una lista P-2 reintroducida, o un `EnLaPrincipalAsync` nuevo, pasaría la suite (M1). Ninguna otra prueba lo detecta: T6-02 no existe.
- **Evidencia.**
  - `tests/GPOS.Reportes.Tests/AuditoriaAdr109Tests.cs:40`.
  - M1 sobrevive. Con `\b` restaurado, la prueba pasa sobre el PR y M1 la pone en rojo [V].
  - El PR afirma que esta prueba se puso en rojo con su mutación. Con el archivo empujado no puede haber sido así [I: el carácter se corrompió al escribir el archivo].
- **Remediación (5 min).** Escribir `@"\b(Intacto)?EnLaPrincipal(Async)?\b"` y agregar, en la misma prueba o en una nueva, una aserción de que el archivo de pruebas no contiene caracteres de control: un `Assert.DoesNotMatch(@"[\x00-\x08\x0B\x0C\x0E-\x1F]", …)` sobre `tests/**/*.cs`. Así el problema no vuelve (ver OBS-01).

## H225-02 (Media): conflicto con el #217

- **Riesgo.** `gh pr view 225` devuelve `mergeable: CONFLICTING`. `git merge-tree` muestra el conflicto en `tests/GPOS.Tests/Mvp/NotificacionesReportesTests.cs`: el #217 insertó `UsarEmisorReal()` y dos pruebas B-2 justo antes del comentario de la caracterización que este PR reescribe. El PR dice «al unirse el emisor (#217) no hay conflicto esperado; si hubiera, `TrabajoNotificaciones.cs`», y no es así.
- **Evidencia.** R-8: lo resolví conservando los dos lados (las B-2 del #217, y después la prueba invertida con su comentario de T4-06). Compila, pasan 141 casos de `GPOS.Tests` y los 823 de `GPOS.Reportes.Tests`. `TrabajoNotificaciones.cs` se une sin conflicto.
- **Remediación (unos 20 min).**
  - A rebasa sobre `1b310591`, resuelve como arriba y vuelve a correr R-8.
  - **Recomendado:** agregar a T6-46b la variante con el emisor real (`UsarEmisorReal()`, como las B-2), que está en el anexo. Con el emisor real pasa [V], y el cierre de M-2 deja de depender del emisor de prueba.

## H225-03 (Media): `AE_02` ya no prueba el programado

- **Riesgo.** Para que `AE_02_el_envio_programado_queda_como_programado_con_la_regla_y_quien_la_guardo` siga pasando, el PR dejó de ejecutar la regla y registra la evidencia directamente con `EvidenciaExportacionesService` (`ReportesF9Tests.cs:~466-480`). La prueba verifica «Verificar» y la copia, pero ya no que **el envío programado** deje su origen y su autor. En Release, el único camino es el de la API de reportes (`TrabajoNotificaciones.cs:162`), y nadie fija ahí el autor: quitar `regla.UsuarioModificacion` de los parámetros de la evidencia no pone nada en rojo (M11). La evidencia de ADR-111, cláusula 7, perdería «quién la guardó» sin aviso.
- **Evidencia.** M11 sobrevive: 18/18 entre `NotificacionesReportesTests` y `AE_02` [V]. `Los_reportes_antes_de_la_lista_P2_programados_van_a_la_API…` comprueba `origen` y `"regla":{id}`, pero no el autor.
- **Remediación (unos 30 min).** En `Los_reportes_antes_de_la_lista_P2…` o en la prueba de evidencia del programado de `NotificacionesReportesTests`, afirmar que los parámetros contienen el autor (`regla.UsuarioModificacion`). Alternativa: reescribir `AE_02` sobre `ApiNotificacionesReportesFactory` con la API simulada. La descarto como única red porque F9 es la prueba de punta a punta del criterio AE.

## H225-04 (Baja): bordes del detector

- **Riesgo.** `ReenvioReportes.DetectarAsync` (`:169-176`) pasa **cualquier** estado no exitoso tal cual (`EstadoRegla = (int)respuesta.StatusCode`), y deserializa sin capturar `JsonException`.
  - Un 500, 502 o 504 de la API de reportes llega al navegador del ADMIN como 500 «Regla de negocio», con el `detail` de la API (limpio y cortado a 300 caracteres por `DetalleParaRegla`), en vez de 503 `REPORTES_NO_DISPONIBLE`.
  - Un 200 con cuerpo que no es JSON da 500 «Error interno».
  - No se guarda nada en ninguno de los dos casos: no hay daño a los datos. El efecto es un diagnóstico engañoso y, en el primer caso, que el texto de un error interno de la API de reportes llegue al ADMIN.
  - Es Baja porque el canal tiene el dueño verificado (nadie ajeno controla la respuesta) y la API de reportes ya oculta sus 500 [I].
- **Evidencia.**
  - C-22: un 500 con `detail` «…Server=SRV-INTERNO;Database=GPOS_E01» llega como `500 {"title":"Regla de negocio","status":500,"detail":"…Server=SRV-INTERNO…"}` [V].
  - C-23: un 200 con `<html>` llega como `500 "Error interno"` [V].
  - Es la diferencia con T6-22 y T6-23 del plan y con BP §5.
- **Remediación (cerca de 1 h).** En `DetectarAsync`:
  - 5xx → la misma `ReglaNegocioException` 503 con `REPORTES_NO_DISPONIBLE` y el detalle solo en el registro (5121);
  - `JsonException` → 400 «La API de reportes devolvió una respuesta que no se pudo leer»;
  - conservar el estado de los 4xx (403, 400, 422, 429).
  - Agregar C-22 y C-23 (anexo).

## H225-05 (Baja, pruebas): Q-A4 solo con ADMIN

- La única prueba de Q-A4 (`ReenvioReportesModoTests.En_Debug_sin_la_API_de_reportes_un_restringido_recibe_403…`) usa `SesionAdmin` y un `IAlcanceAlmacenes` falso. Si el control queda limitado al ADMIN (M4b), la suite no lo nota. Tampoco fija que el SUPER con la bandera pase (Q-A5) ni que exportar dé el mismo 403.
- Mis C-51 (USER restringido, ejecutar y exportar, con `AlcanceAlmacenes` real y la cuenta leída de `IEstadoCuentaSesion`), C-55 (SUPER con bandera y ADMIN sin bandera pasan la puerta) y C-56 (el código coincide con `GPOS.Reportes.Ejecucion.SucursalNoPermitidaException`) pasan y matan M4b.
- **Remediación:** aceptarlas (unos 15 min). Siguen sin cubrirse T6-50 por HTTP con «0 conexiones» y T6-54. Con D-5 y D-7 abiertas, eso no bloquea.

## H225-06 (Baja, pruebas): P-3 sin costura

- La firma P-3 se cumple por la combinación de `ValidarModo` (sin dirección) y el control anterior de Windows (`ReenvioReportes.cs:426-428`). Este último no tiene prueba: M8 sobrevive.
- El mensaje de `ValidarModo` menciona Linux, pero `ValidarModo` no mira el sistema operativo.
- Es la duda D-2 de mi plan; A eligió no agregar la costura.
- **Remediación (unos 30 min):** `ValidarModo(op, depuracion, esWindows)`, con `esWindows: false` y dirección → lanza; o, como mínimo, una prueba textual de que `AgregarReenvioReportes` contiene el control y el literal «solo existe en Windows» antes de `AgregarCanal`.

## H225-07 (Baja, pruebas): casos ausentes

- **T6-02:** guarda por reflexión de `ReportesSemilla.EnLaPrincipal`. Con H225-01 era la segunda red, y no existe.
- **T6-12 y T6-13:** `GET /{id}` y `exportar` con la API caída dan 503, sin fila en `audit.Exportacion`.
- **T6-15:** el 503 no filtra datos internos.
- **T6-17:** la visibilidad coincide entre la lista y la definición para USER, ADMIN y SUPER. Ahora la lista es local y la definición, remota: es la alarma R-3 del blueprint.
- **T6-80:** omite `CXC-ESTADO-CUENTA` sin explicación.
- Estimado: 2 a 3 horas en total. Ninguno bloquea la unión.

## OBS-01 (Baja, anterior al PR y fuera de su alcance)

- `AuditoriaAdr109Tests.cs:253` (en la base, `:215`; commit `b3d655f7` del 2026-10-22) tiene la misma corrupción: `!Regex.IsMatch(codigo, @"0x08(Socket|…)0x08")` siempre vale `true`.
- Por eso `DireccionIp.cs` queda siempre exceptuado de `System.Net.Sockets`, aunque llegue a abrir un `Socket`. La guarda de red saliente de la API de reportes tiene ese hueco. `TcpClient` y `UdpClient` siguen prohibidos por nombre.
- **Remediación:** la misma de H225-01, en un PR aparte de B (o en el de A, si B lo acepta).

# 6. Controles bien implementados [V salvo indicación]

- **El camino local de ejecución solo existe en Debug.**
  - `ReportesService.Ejecucion.cs` es una sola guarda de punta a punta (`#if DEBUG` … `#endif`, un único `#if`).
  - `ReportesService.cs` ya no contiene los métodos de ejecución.
  - Las cinco rutas tienen `#else return ReenvioReportes.NoDisponible();`.
  - `ReporteEnLaPrincipalAsync` queda bajo `#if DEBUG`, con `throw new ReportesNoDisponibleException()` en Release.
  - Hay doble red: la prueba textual Q6 y BLD-2.
- **La guarda del símbolo en Core** (`ComprobarDebugCoherente`) impide Release con DEBUG y Debug sin DEBUG (R-5).
- **La lista es local y no depende de la API de reportes.** Con la API caída responde 200 con los 11 códigos y no hace ninguna petición; ejecutar da 503 `REPORTES_NO_DISPONIBLE`.
- **Guardar con la API de reportes real** (fixture F9, `gpos_rpt` sobre `rpt`): una copia sobre `rpt` se guarda (200) y una sobre `banco.DocBanco` no (4xx) (C-26 y C-28). El contrato `List<ReporteColumnaDto>` coincide con `EndpointsReportes.cs:97-102`.
- **Orden de comprobaciones en Guardar.** `SoloDisenadorAsync` va antes de validar y de llamar al detector: el ADMIN restringido no llega a la API (`El_ADMIN_restringido_no_guarda_y_no_consulta_el_detector`).
- **Token.** El detector manda solo el `Authorization` de la petición en curso (`DetectorColumnasReenvio.cs:16`; la prueba compara con el del ADMIN). Sin token no llama (`ReenvioReportes.cs:161-162`).
- **Semilla.** Las 11 definiciones leen solo `rpt` (`Ningun_SQL_del_sistema_lee_tablas`, con IgnoreCase y corchetes). La teoría `DeVistas` las ejecuta con `gpos_reportes`, así que una unión por coma o un `CROSS APPLY` a tablas también fallaría en ejecución [I]. Los tramos de antigüedad son `*Base`. `HuellasVersion1` se conserva (`ReportesSemilla.cs:379`, `:408`).
- **`DISENO_NO_PERMITIDO` se propaga como 403** con su código (M5 detectada).

# 7. Remediaciones priorizadas

1. **Antes de unir:**
   - H225-02: rebasar sobre `1b310591` y resolver con los dos lados; incluir la variante de T6-46b con el emisor real. Unos 20 min.
   - H225-01: `\b` en la regex más la guarda contra caracteres de control. 5 a 15 min.
2. **Antes de unir, o como primer commit después:** H225-03, afirmar el autor en la evidencia del programado. Unos 30 min.
3. **Después de unir:**
   - H225-04: mapear 5xx y JSON inválido en `DetectarAsync`, más C-22 y C-23. Cerca de 1 h.
   - H225-05: aceptar C-51, C-55 y C-56. Unos 15 min.
   - H225-06: costura o prueba textual de P-3. Unos 30 min.
   - H225-07: casos ausentes, de 2 a 3 h.
4. OBS-01: PR aparte, unos 10 min.

# 8. Qué no verifiqué

- La suite oficial completa de `GPOS.Tests` (solo R-3, R-7 y R-8), BLD-4 y `GPOS.Web.Tests`.
- El arranque real de la principal Release en Linux (P-3): solo lectura de código y la mutación M8.
- T6-44 de punta a punta (autor sin «Ver costos» con el token de servicio); el mecanismo está en `ProveedorContextoTests` [I].
- Paridad de montos y de documentos de los 11 reportes contra el SQL anterior (T6-04 y T6-06), y el «hoy» de UTC-4 fijo en el SQL (`ReportesSemilla.cs`, `CROSS APPLY … DATEADD(HOUR, -4, …)`) [I: correcto para la República Dominicana, que no tiene horario de verano].
- Los avisos del instalador o el laboratorio sobre la publicación del DEMO (T6-73): es verificación humana.

### Cierre
- Estado: Aprobado con observaciones
- Artefactos:
  - `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\C\2026-10-24-revision-adversarial-pr225-t4-06.md` (este informe);
  - `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\C\2026-10-24-revision-adversarial-pr225-t4-06-pruebas.cs.txt` (9 casos y la variante de T6-46b con el emisor real);
  - logs `corrida-*.log` en el scratchpad de la sesión (`pr225/`).
- Supuestos: que el 0x08 vino de un fallo de escritura del archivo y no fue intencional; que la API de reportes no pone datos internos en el `detail` de sus 500.
- Decisiones candidatas a ADR: Ninguna
- Entregas a otros agentes:
  - A → rebasar sobre el #217 (H225-02), corregir la regex (H225-01), afirmar el autor en la evidencia del programado (H225-03) y considerar H225-04 a H225-06 y las pruebas del anexo;
  - B → decidir si acepta C-22, C-23, C-51, C-55 y C-56; corregir OBS-01; dar por cerrado M-2 del #217 al unir el #225 rebasado.
- Próximo paso recomendado: A rebasa el #225 sobre `1b310591`, corrige H225-01 y H225-03, y el propietario decide la unión. M-2 se cierra con esa unión.
