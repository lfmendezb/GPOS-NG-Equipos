Para: B        De: C        Fecha: 2026-10-23
Tipo: Entrega (tarea 3 de B-a-C/2026-10-23-tareas-nuevas-para-c-4: plan de pruebas de T4-02b)
Prioridad: Media
Repositorio y rama: GPOS-NG, lectura (`fc68c7f6` del blueprint; `feature/modelo-ng` en `9a439234` según el encargo)
Estado: Abierto

# Plan de pruebas de T4-02b (la principal sin motores de render)

Plan, no construcción: no compilé, no corrí pruebas, no toqué ningún árbol. Fuente única: el blueprint `docs/arquitectura/2026-10-22-t4-02-blueprint-principal-sin-motores.md` (leído con `git show fc68c7f6:`, porque no está en la rama checkout; en adelante **BP**), secciones 1.3, 5, 6, 7, 8.1, 10 y 11. Marcas: **[V]** = leído en el BP; **[I]** = inferido o por calibrar en la primera corrida; **N** = prueba nueva; **E** = existente que se adapta; **P** = parcial.

Alcance de T4-02b según P-T402-02 (a, firmada el 2026-10-23): los llamadores, el borrado, `Program.cs` y la adaptación de las pruebas. `ClienteRender`, `ContratoRender` y sus pruebas propias son T4-02a (#210), revisado aparte; aquí solo se cita lo que T4-02b exige de ellos.

Niveles: **U** = unitaria o estática, sin base; **D** = con el doble de `IClienteRender` y base `GPOS_TEST_*`; **A** = con el anfitrión de la API de reportes en el proceso (`AnfitrionReportesEnProceso`, BP 10.2) y Chromium/QuestPDF reales; **M** = medición.

## 0. Resumen y lo que bloquea

1. **Cinco condiciones de unión** (C-2, C-3, C-4, C-6, C-7) = cinco comprobaciones de **hecho verificable**, no pruebas de comportamiento. Las escribo como lista de verificación con evidencia exigida (sección 1) y, donde se puede, como prueba que falla si la condición se rompe (guardas de la sección 1.6).
2. **Dos pruebas nombradas por el BP** (sección 2). Hallazgo sobre la segunda: se cumple **sin cambiar el orden** en la impresión fiscal (H-T402-02), así que la prueba **no puede ser roja antes y verde después** por un cambio de orden; hay que demostrar que no es vacua con una mutación (M-T01 a M-T04).
3. **Adaptación de los 10 archivos** (sección 3): tabla por archivo con qué tipos borrados usa, a qué pasa, nivel y riesgo.
4. **Prueba transitiva** (sección 4): tres métodos posibles; recomiendo el `deps.json` más el grafo de proyectos, con una mutación que la mata.
5. **Medición «después»** (sección 5): protocolo y qué no se puede concluir.
6. **Mutaciones** (sección 6): 24, cada una con el caso que la mata o «no la mata nada hoy».
7. **Orden de trabajo y esfuerzo** (sección 7): unos **3,5 dp** de pruebas [I], de los cuales ~1,5 ya están en las estimaciones de B (BP 13) y el resto es nuevo.
8. **Bloquean o necesitan decisión** (sección 8): C-3 no es verificable sin definir qué se archiva y dónde; quién captura la línea base tras el #156; la regla del conduce (P-T402-01 firmada en (a), así que la prueba del conduce **es obligatoria**, no condicional como dice el BP 10.1).

## 1. Condiciones de unión C-2, C-3, C-4, C-6 y C-7

El BP 8.1 las llama «condiciones para unir». Una condición no se prueba con xUnit; se **comprueba con evidencia** antes de pulsar «unir». Para cada una: qué se verifica, la evidencia exacta que pido en el cuerpo del PR, la guarda automática (si la hay) y la mutación que la hace fallar.

### 1.1 C-2 · Guarda de los dorados (#156) unida, o adoptada por B

| Caso | Qué se comprueba | Cómo | Resultado esperado | Mutación que lo rompe |
|---|---|---|---|---|
| C2-01 | #156 está unido en `feature/modelo-ng` antes de unir T4-02b | `gh pr view 156 --json state,mergedAt` y `git merge-base --is-ancestor <merge del #156> <punta de T4-02b>` | `MERGED` y salida 0. Si B la adopta: el commit de la guarda está en la rama de T4-02b y se cita | M-T05 |
| C2-02 | La guarda **funciona sobre la salida de la API de reportes**, no de la principal | Con `GPOS_TEST_DORADOS=regenerar` sin motivo → la prueba falla (el #156 exige motivo y registra la versión de Razor 10.0.13 [V del encargo]); con motivo → regenera y deja la línea en el registro | Sin motivo: rojo con el mensaje de la guarda; con motivo: verde y el diff de dorados vacío (nada cambió) | M-T05, M-T06 |
| C2-03 | Los dorados **no se regeneran** en el PR de T4-02b | `git diff --stat origin/feature/modelo-ng...HEAD -- tests/GPOS.Tests/Impresion/Dorados/` | 0 archivos de dorados cambiados. T4-02b mueve el origen del render, no el contenido; un dorado que cambia es un hallazgo, no una actualización | M-T06 |
| C2-04 | Quien regenera ya no puede hacerlo desde la principal | `RenderTrasladoTests` llama al `ServicioRender` de `GPOS.Reportes.Api` (BP 10.2) y no hay ya ningún tipo de `GPOS.Api.Impresion` que genere PDF | Compila sin `using` a los tipos borrados; la regeneración existe una sola vez | M-T07 |
| C2-05 | La guarda sigue siendo la del #156 tras el rebase (H-T402-06: «nadie impide regenerar para que pase») | Prueba de la guarda del #156 corre en la suite de T4-02b | Verde. Si el rebase la rompe o la elimina, rojo | M-T05 |

Duda abierta D-1: el #156 pasa a ser mío (encargo, tarea 1) y su revisión humana de dorados la hace el propietario o A. **C-2 depende de que yo termine el #156**; el plan lo da por unido.

### 1.2 C-3 · Línea base de `MedicionRender` de la principal capturada y archivada (B9, suite sola)

Es una condición de **proceso**: la línea base se captura **antes** de borrar los motores y se archiva. La captura la hace B (encargo: «la hago yo cuando actualices el #156»). Lo que yo puedo hacer es fijar qué es «archivada» para que sea verificable.

| Caso | Qué se comprueba | Evidencia exigida | Resultado esperado |
|---|---|---|---|
| C3-01 | Existe el archivo de la línea base | `docs/calidad/` o `traspasos/B/` (propuesta, ver D-2): `AAAA-MM-DD-linea-base-medicion-render.md` con commit, fecha, máquina, `GPOST_B9`, versiones (.NET, Chromium, QuestPDF, Razor 10.0.13), **n y percentiles** | Archivo en la rama de T4-02b o en `master` |
| C3-02 | Se capturó **con los motores de la principal**, no con la API de reportes | El commit de la captura es ancestro de T4-02b y **anterior** al primer commit de borrado de los motores; el archivo cita ese commit | `git merge-base --is-ancestor` verdadero y el commit contiene `src/GPOS.Api/Impresion/ConvertidorPdf.cs` (`git cat-file -e <commit>:src/GPOS.Api/Impresion/ConvertidorPdf.cs`) |
| C3-03 | Suite sola y base de condiciones limpias | El archivo declara «sin otra suite al mismo tiempo» (CLAUDE.md) y los resultados de **al menos 3 corridas** con su dispersión | n ≥ 3 corridas y el coeficiente de variación declarado. Sin eso, el «+50 ms en el p95» (BP R-T402-08, A-7) no es comparable [I] |
| C3-04 | Mismos escenarios que el «después» | El archivo lista los escenarios (tipo de documento, papel, filas, motor: Razor/Chromium y QuestPDF) y la sección 5 de este plan los usa sin cambios | Lista idéntica en el «antes» y el «después» |
| C3-05 | La línea base no se descarta por omisión | `MedicionRender` hoy está **omitida** detrás de `GPOST_B9` (BP H-T402-05) | La captura se hizo con `GPOST_B9` activo; en el archivo consta |

Guarda automática posible [I]: una prueba estática `Existe_la_linea_base_de_MedicionRender` que lee el archivo y comprueba que declara commit y n. Sirve para que el archivo no desaparezca al borrar; no sustituye a C3-02. Mutación: M-T08.

### 1.3 C-4 · T4-03a unido (#170), con el perfil en `%ProgramData%\GPOS NG\Reportes\render`

| Caso | Qué se comprueba | Cómo | Resultado esperado | Mutación |
|---|---|---|---|---|
| C4-01 | #170 está unido y T4-02b se apoya en él | `gh pr view 170 --json state` y ancestro | `MERGED`, ancestro verdadero | M-T09 |
| C4-02 | Se conserva el mensaje 503 con la carpeta ausente (Release): los formatos **personalizados** dan 503 y los **estándar** imprimen (BP 8.4 [V rama t4-03a `ConvertidorPdf.cs:28,39,82`]) | Caso `A` del anfitrión con un perfil que no existe y un formato `RAZOR`; luego un formato estándar | Personalizado: 503 `REPORTES_NO_DISPONIBLE` o `NAVEGADOR_NO_DISPONIBLE` (**decidir cuál**, D-3); estándar: 200 PDF | M-T10 |
| C4-03 | Ningún camino de T4-02b vuelve a poner Chromium en `GPOS.Api` | Prueba transitiva de la sección 4 | Verde | M-T09, M-T11 |
| C4-04 | La suite A de T4-02b usa el perfil del #170 (no el temporal viejo) | El accesorio fija `GPOS:Reportes:Render:Perfil` (nombre exacto por confirmar con B, D-3) en una carpeta `GPOS_TEST_*` con la ACL que el #170 exige | El accesorio arranca en Windows sin abrir `%ProgramData%` real | — (revisión) |

C4-02 y C4-04 son los únicos que tocan comportamiento. Los pongo aquí porque son la razón por la que D-T403-1 hizo de #170 una condición.

### 1.4 C-6 · T4-06 unido (A, antes del 11-11)

| Caso | Qué se comprueba | Cómo | Resultado esperado | Mutación |
|---|---|---|---|---|
| C6-01 | T4-06 está unido | `gh pr list --search "T4-06" --state merged` y ancestro | Unido, o **T4-02b no se une** | M-T12 |
| C6-02 | Tras T4-06 el camino local P-2 de `ReportesEndpoints.cs:67` queda solo en Debug [V BP 8.1] | Prueba de la compilación Release: `/api/reportes/{id}/exportar/pdf` con `ReenvioReportes` apagado no genera PDF local | En Release 503; en Debug, PDF por `ResultadoAsync` | M-T12, M-T13 |
| C6-03 | T4-02b cambia **solo** la línea del PDF de `ReportesEndpoints.cs:67` y un método de `AuditoriaAdr109Tests` (BP 8.3) | `git diff --stat` contra `origin/feature/modelo-ng` | `ReportesEndpoints.cs`: un hunk. `AuditoriaAdr109Tests.cs`: solo el método de motores | M-T14 |
| C6-04 | `CompilacionDepuracion` de `ReenvioReportes.cs` no se tocó (P-4 del DEMO) | `git diff -- src/GPOS.Api/Endpoints/ReenvioReportes.cs` | Vacío | — |
| C6-05 | `Mvp/ReportesF9Tests.cs` (que toca T4-06 y T4-02b) sigue verde tras el rebase | Suite completa | Verde | — |

### 1.5 C-7 · T1-5 de D1 unido (~11-13, o el 11-16)

| Caso | Qué se comprueba | Cómo | Resultado esperado | Mutación |
|---|---|---|---|---|
| C7-01 | T1-5 está unido; **T4-02b no se une antes** | ancestro; fecha de unión ≥ la de T1-5 | Verdadero | M-T15 |
| C7-02 | Las pruebas de T4-02b adoptan `AccesoPruebas` (el ayudante de D1) y no el patrón viejo de `BaseDatosFixture` | `git grep` en los archivos de pruebas tocados: ninguna construcción manual de token/sesión que T1-5 retira | 0 usos del patrón viejo en lo que T4-02b escribe o adapta | M-T15 |
| C7-03 | Lo que T4-02b hace en `Program.cs` no choca con T1-5 ni con T4-07 | Rebase limpio; la zona S (`Seguridad.cs`, `PermisosServidor.cs`, `RevocacionSesiones.cs`) sin cambios | `git diff --stat` sin esos tres archivos | M-T16 |
| C7-04 | `Program.cs` tras el rebase: quita `:26-27` (licencia de QuestPDF) y `:336-340`, conserva `:341-344`, **agrega** `IClienteRender` y la línea de `Retry-After` | Pruebas de arranque (`FlujosMvpTests`) y la sección 2 | Verde | M-T17 |
| C7-05 | Fecha: el 11-16 y el 11-17 sin suites (banco Q1) | Calendario; no es una prueba | La suite oficial de T4-02b corre el 11-18 o después | — |

### 1.6 Guardas automáticas que dejo recomendadas (todas **U**, sin Chromium)

| Prueba | Qué protege | Matar con |
|---|---|---|
| `ArquitecturaReportesTests.GPOS_Api_no_referencia_motores_de_render` (sección 4) | C-4, C-6, C-7 indirectamente: si algo vuelve a meter un motor | M-T11 |
| `Los_archivos_borrados_no_existen` (lista de la sección 7 del BP, 11 rutas) | Que nadie reponga `ConvertidorPdf.cs`, `MotorRazor.cs`, `Formato*.cs`, `LetraNumero.cs` y la fuente en `GPOS.Api` | M-T18 |
| `GPOS_Api_conserva_ClosedXML` | BP 7: ClosedXML se queda (lo usan `PlantillasImportacion` y `ExportadorReporte`) | M-T19 |

## 2. Las dos pruebas nombradas

Ambas en `tests/GPOS.Tests/ClienteRenderTests.cs` [V BP 10.1]. Reciben `AccesoPruebas` (C-7).

### 2.1 `Sin_la_API_de_reportes_imprimir_responde_503_y_el_documento_queda_guardado`

BP: «Guarda una venta, apaga el anfitrión, imprime: 503 `REPORTES_NO_DISPONIBLE` y la venta existe.»

**Diseño propuesto.** Nivel **A** pero **sin Chromium**: el anfitrión se levanta para que la canalización exista y se **apaga** (Dispose) antes de imprimir; así el camino probado es el real (`ClienteRender` → `ClienteCanal` → conexión rechazada), no un doble. Es la prueba de A-7 (el POS no imprime si cae el servicio; la venta se guarda).

| Caso | Escenario | Esperado | Por qué importa |
|---|---|---|---|
| S503-01 | Venta fiscal con NCF (con tipo de comprobante) guardada; anfitrión apagado; `POST /api/impresion/documento/FC/{numero}` | HTTP 503; cuerpo `codigo = REPORTES_NO_DISPONIBLE`; texto de impresión del BP 5.3 («el documento quedó guardado») | Contrato de error |
| S503-02 | Mismo escenario | La venta existe: `ventas.Venta` (o el nombre real de la tabla; **confirmar**) con el número y estado «emitida»; el **NCF consumido** no se libera ni se repite | «Queda guardado» significa documento **y** NCF: si el rechazo del render revirtiera el NCF, se rompe la regla del NCF |
| S503-03 | Mismo escenario | **0 filas** en `doc.Impresion` para ese documento (el registro de la copia va después del PDF, H-T402-02) | Enlaza con 2.2 |
| S503-04 | Mismo escenario | Evento 5121 emitido una vez (logger de pruebas), con la causa; **no** 5122 | Distingue «caído» de «suplantado» |
| S503-05 | Mismo escenario, `Retry-After` | No hay `Retry-After` (solo 429/503 de `NAVEGADOR_NO_DISPONIBLE` lo traen) | Evita que un 503 de «caído» sugiera reintentar en N s [I] |
| S503-06 | Anfitrión apagado; tipos de cada ruta de la tabla 5.2 (ticket, documento, recibo, `formato/{tipo}/{numero}`, nota, cierre, conduce, vista previa, correo, `reportes/{id}/exportar/pdf`, `consulta-facturas/exportar/pdf`) | Todas 503 `REPORTES_NO_DISPONIBLE` (teoría con 11 filas) | El BP lista 11 rutas con códigos nuevos; una sola prueba cubre solo una |
| S503-07 | Correo con PDF (`/api/notificaciones/documento`) con anfitrión apagado | 503 y **no se encola** el correo (BP 5.2/6.3) | Evita correos sin adjunto |
| S503-08 | Vista previa de comprobante real con anfitrión apagado | 503; **queda** la línea H-2 de la bitácora (H-T402-08, aceptado) | Fija el comportamiento aceptado, para que un cambio sea deliberado |
| S503-09 | Reenvío apagado (`GPOS:Reportes:Reenvio:Direccion` vacía) | 503 **sin abrir la canalización**: servidor de canalización falso con contador de conexiones = 0 | Es `Sin_direccion_responde_503_sin_abrir_la_canalizacion` (BP 10.2); la dejo aquí por coherencia |
| S503-10 | El anfitrión estaba arriba y cae a mitad (se corta la conexión tras el primer byte) | 503, sin reintento automático (BP 6.2: «sin reintentos»): el servidor falso cuenta **1** conexión | Reintento escondido duplica espera |
| S503-11 | Después de apagarlo, se enciende y se reintenta | 200 PDF; ahora sí 1 fila en `doc.Impresion` con «original» | Cierra el ciclo: el usuario reintenta y funciona |

Notas: S503-02 debe consultar la base con una conexión **nueva** (no la del `DbContext` de la petición). S503-06 es la que más vale: sin ella se prueba una ruta y las otras quedan con un `try/catch` de más.

### 2.2 `Si_el_render_falla_el_reintento_no_cuenta_otra_copia`

BP: «Comprobante fiscal: render que falla (429 forzado) → 0 filas en `doc.Impresion`; el intento siguiente es el original. Con P-T402-01 (a), la misma prueba para el conduce.»

**Observación (H-T402-02):** el orden actual ya cumple esto, así que la prueba **pasará el primer día**. Una prueba que nace verde es sospechosa; por eso la construyo con control negativo y mutaciones (M-T01 a M-T04). **P-T402-01 está firmada en (a) el 2026-10-23 [V: nota del BP 12], así que la variante del conduce no es condicional.**

Doble: `IClienteRender` falso que lanza `RenderRechazadoException` 429 con `ReintentarEn` (nivel **D**, no necesita Chromium). Una segunda variante con el anfitrión real y un 429 forzado por saturación del cupo (4 simultáneos, 10 s de espera, BP) es nivel **A** y frágil: la dejo como opcional [I].

| Caso | Escenario | Esperado | Por qué |
|---|---|---|---|
| R429-01 | Fiscal: primera impresión (original) con render 429 | HTTP 429, `codigo = RENDER_OCUPADO`, `Retry-After` presente; **0 filas** en `doc.Impresion` | Núcleo de la prueba |
| R429-02 | Luego render OK, mismo documento, **sin** `reintento` | 200; **1 fila**, número de copia = original (no «Reimpresión 2»); la marca que recibe el doble en `ModeloImpresion.Copia` es 0 o nula | «El intento siguiente es el original» |
| R429-03 | Luego otra impresión OK | Ahora 2 filas; `Copia = 1` en el modelo («COPIA 1») | Control: la cuenta sigue funcionando |
| R429-04 | Render que falla **tres veces** seguidas (429, 503, 422) y luego OK | 0 filas tras los fallos; 1 fila tras el éxito | No cuenta por intento |
| R429-05 | Reimpresión de un documento ya impreso (1 fila) con render 429 | Sigue 1 fila; el siguiente éxito es «COPIA 1» (copia 2 del conjunto), no «COPIA 2» | La falla en una **reimpresión** tampoco cuenta |
| R429-06 | `reintento` explícito (libre) con render 429 y luego OK | 0 filas tras la falla; el éxito no cuenta cuenta de más según la regla de reintento libre (**confirmar** la regla exacta en `ReimpresionService.cs:54-113` antes de fijar el esperado) | La mitigación 3 de A-7 es «reimpresión libre que no cuenta otra copia» |
| R429-07 | Choque de doble clic: dos peticiones simultáneas, ambas deciden «original»; el render de ambas OK | Una gana el registro; la otra **vuelve a decidir y vuelve a pedir el PDF** (`ImpresionEndpoints.cs:200-208`): 1 fila de original y 1 de copia; el doble recibió **3** peticiones de PDF (2 + 1 re-decisión), no 2 | Fija el comportamiento descrito en D-T402-3 |
| R429-08 | Render que falla **después** de entregar la cabecera (se corta el cuerpo) | 503; 0 filas | El fallo parcial no cuenta |
| R429-09 | Conduce de transferencia (P-T402-01 a): render 429 | 0 filas / sin `CONDUCE_IMPRESO` en la bitácora y sin avanzar la cuenta; el siguiente éxito registra `CONDUCE_IMPRESO` (no `CONDUCE_REINTENTO`) | H-T402-01, R-T402-03 |
| R429-10 | Conduce: doble clic simultáneo, con relectura | Una sola cuenta de «original»; la otra relee y cuenta la reimpresión; ninguna pierde el PDF | Bloqueo y relectura de P-T402-01 (a) |
| R429-11 | Conduce: **caracterización del orden anterior**, prueba con `[Trait("Transicion","Defecto")]` [I] o ya sin ella | No se escribe: el orden viejo desaparece con P-T402-01 (a) | Evita fijar lo que se quita |
| R429-12 | Orden de bloqueo (CLAUDE.md: «Toda operación que dependa del estado de un documento lo bloquea y lo relee antes de guardar») en el conduce partido en preparar/registrar | El registro toma `GPOS.Doc:` antes de relectura; prueba estática o con `sys.dm_tran_locks` [I] | Evita el interbloqueo que la partición podría crear |

Control negativo: la misma prueba con el doble que **devuelve OK** debe dar 1 fila; así se demuestra que «0 filas» viene del fallo y no de que el registro esté roto.

## 3. Adaptación de los 10 archivos de `tests/GPOS.Tests`

Todos [V BP 10.2] usan tipos que se borran. Para cada uno: qué usa (según BP; **no leí cada archivo** salvo donde lo indico, D-4), a qué pasa y cómo verificar que no perdió cobertura.

Regla común: antes de tocar, registrar **n° de pruebas y de aserciones** del archivo (`dotnet test --list-tests` cuenta nombres; las aserciones con `git grep -c "Assert\."`); después, el mismo n° o una justificación escrita. Una adaptación que baja el n° sin explicación es el riesgo principal («pasa porque no prueba»).

| # | Archivo | Qué usa y se borra [V BP] | Pasa a | Nivel | Riesgo y verificación |
|---|---|---|---|---|---|
| 1 | `Arquitectura/ValoresDeTercerosTests.cs` | Rutas de `ConvertidorPdf.cs` en la lista de excepciones (`:82-84`) | Quitar las 3 rutas de la lista; si la prueba existe para vigilar valores de terceros (Chromium, rutas), **mover** esa vigilancia a `GPOS.Reportes.Api` donde el archivo vive ahora | U | Que la prueba no pase por haber **perdido** el archivo vigilado: mutación M-T20 (reintroducir el literal de tercero en `GPOS.Reportes.Api/.../ConvertidorPdf.cs` debe poner rojo, o debe documentarse que solo se vigila `GPOS.Api`) |
| 2 | `CierresCajaTests.cs` | `FormatoCierre` (QuestPDF) para el PDF del cierre | Para el modelo/cifras: sin cambios. Para el PDF: `CierreAsync` por el doble (permisos, turno propio) y, para el contenido del PDF, el anfitrión (A) | D y A | El cierre sin `CuadreCaja` (turno propio) no debe llegar a pedir el PDF con montos: el doble debe recibir `SolicitudRenderCierre` con el recorte (ADR-109/C-2′ solo en T4-11; **hoy** el cierre completo viaja, D-5). Verificar que el doble **no** se llama si el permiso falla |
| 3 | `Impresion/MedicionRender.cs` | 9 referencias a tipos de la principal | Reescribir para medir por `ClienteRender` («después»), sección 5 | M | Sigue omitida por `GPOST_B9`; verificar que **compila** y que, activada, produce los mismos escenarios (C3-04) |
| 4 | `Impresion/RenderTrasladoTests.cs` | Compara salida de la principal contra dorados; `:15-22` y `:39` regenera | Compara salida de `ServicioRender` (API de reportes) contra dorados; regeneración bajo la guarda del #156 | A | Que los dorados no cambien (C2-03) y que la guarda siga activa (C2-05) |
| 5 | `ImpresionDocumentosTests.cs` | Genera PDF por las rutas y usa `new FormatoTicket(...)` | Rutas: anfitrión (A) y doble (D) según lo que verifiquen; `new Formato*` → tipos de `GPOS.Reportes.Api.Impresion` | A, D | Dividir en lo que verifica **permisos y selección de formato** (D) y lo que verifica el **PDF** (A): ver la columna «Qué verifica» en el ensayo del archivo; ~15 clases en total lo hacen [V BP 6.1] |
| 6 | `ImpresionNumeroLegibleTests.cs` | `LetraNumero`/`MonedaEnLetras` de `FormatoDocumento.cs:250` | Contra `GPOS.Contracts/Documentos/NumeroALetras` (H-T402-03) | U | Mantener **todas** las filas de la teoría; mutación M-T21 (cambiar una palabra) debe fallar. Añadir una fila que compare `NumeroALetras` contra `FormatoDocumento.MonedaEnLetras` si el segundo delega |
| 7 | `ModeloNg/ReglasReimpresionTests.cs` | `ServicioImpresion.MarcarCopia` y, según P170-07, el `Regex("<body[^>]*>")` (`:79-101`) | `ServicioRender.MarcarCopia` en `GPOS.Reportes.Api.Impresion` (BP 10.1) | U | **Coordinación con P170-07:** si T4-02 construye la marca en Chromium, `MarcarCopia` desaparece y este archivo se reescribe con las opciones del PDF. Ver el plan de la tabla adversaria. Hasta que se decida el orden, el archivo se adapta a `ServicioRender.MarcarCopia` y se marca para reescribir |
| 8 | `NumeracionQa2OtrosTests.cs` | Uso de tipos de render | Según el uso exacto (no leí el archivo): si genera PDF, anfitrión o doble | D | Verificar que la prueba de numeración **no depende** del PDF; si depende, separarla |
| 9 | `ReportesTests.cs` | El PDF de `ExportadorReporte` (`:152`) | `ExportadorReporte.ExportarAsync` con `pdf` por `ResultadoAsync` (D con el doble que devuelve un PDF mínimo); los demás formatos (CSV, XLSX, DOCX, JSON, XML) por el `Exportar` síncrono | D | Dos cosas: el `Exportar` síncrono **lanza** si le piden `pdf` (BP 6.3) → prueba N; y que `ResultadoAsync` respeta el tope de 10.000 filas (BP 5.1) |
| 10 | `SeguridadPc3Tests.cs` | PDF de `ExportadorReporte` | El BP dice que `SeguridadPc3Tests` (CSV y XLSX) **no cambia** [V BP 6.3] | U/D | Verificar que realmente no necesita cambiar; si usa `GeneratePdf`, cambiarlo |

Las 6 clases que ya nombra el BP 10.1 (`ImpresionDocumentosTests`, `ModeloNg/ReimpresionTests`, `ModeloNg/ReglasReimpresionTests`, `NumeracionPc3EjemploTests`, `SeguridadPc3Tests`, `Mvp/FlujosMvpTests`) se solapan con los 10 en tres (5, 7, 10); las otras tres (`ReimpresionTests`, `NumeracionPc3EjemploTests`, `FlujosMvpTests`) **no están en la lista de diez** y también generan PDF por las rutas: **dudas D-4**: hay 13 archivos, no 10, a adaptar si la lectura es literal.

### 3.1 Casos nuevos por la adaptación

| Caso | Qué | Esperado |
|---|---|---|
| AD-01 | Todas las pruebas de permisos usan el **doble**: el doble cuenta llamadas | Permiso denegado → 0 llamadas al doble (nunca se pide el PDF a quien no puede imprimir) |
| AD-02 | El doble recibe `autorizar` | El `Authorization` del doble es el de la petición original; nunca uno inventado (BP 6.1: «Nunca se copia una credencial que no venga de la sesión o del emisor de T4-04») |
| AD-03 | Una prueba por ruta de la tabla 5.2 | Cada ruta llama exactamente al verbo que dice el BP (`documento`, `cierre`, `conduce`, `resultado`) |
| AD-04 | El doble y el anfitrión producen **el mismo PDF mínimo** para el mismo modelo en el caso trivial | Evita que el doble oculte diferencias; solo para 1 modelo |
| AD-05 | Aislamiento entre empresas: dos empresas, el doble recibe el modelo de la empresa de la sesión | El `EmpresaInfo` del modelo es el de la sesión; una petición con el `X-Empresa` de otra → 403 antes del doble (BP 5.2 «Aislamiento») |
| AD-06 | Los costos no se cuelan al canal (R-T402-05): modelo con `vercostos` negado | El filtro de costos de `JsonOptions` (`Program.cs:347-350`) **no** aplica en `ClienteRender` (opciones propias): verificar que el modelo que el doble recibe ya viene sin costos porque `FabricaModelo` no los puso, no porque lo filtró el serializador |

AD-06 es sutil: si algún día `FabricaModelo` pone costos y confía en el filtro del serializador, el canal los lleva. Prueba N (nivel U sobre el JSON que serializa `ClienteRender`).

## 4. Prueba transitiva «la principal ya no trae motores»

BP 10.1: `ArquitecturaReportesTests.GPOS_Api_no_referencia_motores_de_render`, con la comprobación transitiva por método a elegir por el desarrollador [I]. Propongo **dos comprobaciones complementarias**, ambas U:

| Método | Qué lee | Pros | Contras |
|---|---|---|---|
| (1) `GPOS.Api.deps.json` (en la salida de compilación de pruebas) | Lista de `libraries` y `targets` con todas las dependencias NuGet resueltas, directas y transitivas | Es **lo que realmente se despliega**; atrapa un motor que llega por un paquete nuevo | Depende de que `GPOS.Api.deps.json` esté en la carpeta de salida de las pruebas (lo está si `GPOS.Tests` referencia `GPOS.Api`; **confirmar**, D-6); las rutas pueden variar por RID |
| (2) Grafo de `ProjectReference` + `PackageReference` leyendo los `.csproj` y `obj/project.assets.json` | Transitividad completa también para proyectos de la solución | Independiente de la salida | `obj/project.assets.json` puede faltar o estar obsoleto |
| (3) `AppDomain`/`Assembly` cargado: `Assembly.Load("GPOS.Api").GetReferencedAssemblies()` recursivo | Referencias reales de ensamblados | Atrapa referencias vía código | Solo ve lo que el código **usa**; un paquete sin uso no aparece. Insuficiente solo |

**Recomendación:** (1) como prueba principal y (3) como segunda, para atrapar el caso «paquete restaurado pero sin uso» y el «uso de tipo sin paquete directo». (2) no.

Lista negra [V BP]: `PuppeteerSharp`, `QuestPDF`, `Microsoft.AspNetCore.Mvc.Razor.RuntimeCompilation`. Ampliar [I]: `Microsoft.AspNetCore.Razor.Language`, `Microsoft.CodeAnalysis.Razor`, `Microsoft.CodeAnalysis.CSharp` (viene con RuntimeCompilation), `SkiaSharp` (lo trae QuestPDF), `HarfBuzzSharp`. **Cuidado con los falsos positivos:** `Microsoft.CodeAnalysis.CSharp` y `Microsoft.AspNetCore.Razor.Language` pueden llegar por otros paquetes legítimos (por ejemplo, un analizador). Decidir con B la lista exacta tras ver el `deps.json` real **antes** de escribir la prueba (D-6).

| Caso | Qué | Esperado | Mutación |
|---|---|---|---|
| TR-01 | `GPOS.Api.deps.json` no contiene `PuppeteerSharp`, `QuestPDF`, `Microsoft.AspNetCore.Mvc.Razor.RuntimeCompilation` | Verde | M-T11 |
| TR-02 | Idem para los transitivos de la lista ampliada (decidida) | Verde | M-T11 |
| TR-03 | `GPOS.Api.csproj` no tiene `PackageReference` a esos tres ni el `ItemGroup` de la fuente (`:31-36`) | Verde | M-T18 |
| TR-04 | `GPOS.Contracts` y `GPOS.Core` tampoco los traen (si no, entrarían por la puerta de atrás) | Verde. **Hoy** puede ser falso: `GeneradorRazor` está en `GPOS.Contracts` y no es un motor [V BP 1.4], pero verificar que no arrastra Razor | M-T22 |
| TR-05 | `GPOS.Reportes.Api` **sí** los trae (control positivo) | Verde: la prueba no es vacua | M-T23 |
| TR-06 | Control de la propia prueba: el método de lectura funciona con un `deps.json` sintético que contiene `QuestPDF` | La función devuelve «contiene» | M-T24 |
| TR-07 | `GPOS.Web` y `GPOS.UI.MAUI` no referencian motores (A-3) | Informativa; **no** mover el alcance de la hoja: confirmar con B si queda fuera | — |
| TR-08 | `estado.json` (lista de pruebas de ADR-109 cl. 1) apunta al nombre nuevo de la prueba | Archivo actualizado (BP 10.1) | — (revisión) |

Quitar `motoresPendientesDeMover` (`AuditoriaAdr109Tests.cs:110`): caso TR-09, prueba estática: `git grep motoresPendientesDeMover` = 0 resultados. Mutación: reintroducir el nombre.

## 5. Medición «después» de `MedicionRender`

BP 10.2: «mide por la principal con `ClienteRender` (el “después”) contra la línea base de C-3.» Objetivo: **+50 ms en el p95** [I] (A-7, R-T402-08). Yo no la corro; defino el protocolo.

| Elemento | Definición |
|---|---|
| Escenarios | Exactamente los de C3-04: por tipo de documento (ticket 80 mm, factura carta con Razor/Chromium, factura con QuestPDF, cierre, conduce, resultado de 1.000 y 10.000 filas) |
| Condiciones | Suite sola, `GPOST_B9` activo, misma máquina, mismo servidor SQL; **caliente y frío por separado** (Chromium precalentado `Precalentar = true` y sin precalentar) |
| Muestras | n ≥ 30 por escenario después de 5 de calentamiento [I]; tres corridas; se archivan las tres |
| Qué se mide | Latencia de extremo a extremo de la **petición a la principal** (no del render solo); además, por separado, el tiempo de `ClienteRender` (serializar + canalización + introspección + render + lectura) |
| Qué se compara | p50, p95 y p99 «después» menos «antes», por escenario |
| Criterio | p95 «después» ≤ p95 «antes» + 50 ms por escenario. Si no se cumple, **no bloquea sola**: A-7 pide una explicación; se informa como observación con la causa (introspección con caché de 15 s en frío, Chromium en frío) |
| Casos | ME-01 a ME-06 abajo |

| Caso | Qué | Esperado |
|---|---|---|
| ME-01 | La clase compila sin tipos de la principal | Compila; sigue **omitida** sin `GPOST_B9` |
| ME-02 | Con `GPOST_B9`, escenarios idénticos a la línea base | Lista coincide con el archivo de C-3 |
| ME-03 | Archivo `…-medicion-despues.md` con commit, máquina, versiones y las tres corridas | Existe y cita la línea base |
| ME-04 | El «después» corre con **el anfitrión real**, no con el doble | El doble haría el «después» ≈ 0 y aprobaría siempre. Condición verificable: el accesorio es `AnfitrionReportesEnProceso` |
| ME-05 | Caso frío: la primera impresión tras arrancar el anfitrión | Se informa aparte; no entra en el p95 caliente |
| ME-06 | La introspección de la caché de 15 s: una petición con la caché vencida | Informar la diferencia; debería ser el pico del p99 [I] |

**Qué no se puede concluir:** una medición en proceso (anfitrión de pruebas en la misma máquina, canalización local) subestima el costo real en un servidor con servicio aparte y cuenta virtual. El número es una **cota inferior**. Decirlo en el archivo.

## 6. Mutaciones (cada una con el caso que la mata)

Las que dicen «no la mata nada hoy» son los huecos a cerrar.

| ID | Mutación | La mata | Estado |
|---|---|---|---|
| M-T01 | `ImprimirFiscal`: invertir el orden y registrar la copia **antes** del PDF | R429-01, R429-04, R429-05 (1 fila donde se espera 0) | Mata |
| M-T02 | `RegistrarAsync` se ejecuta también en la rama de excepción del render (`finally`) | R429-01 | Mata |
| M-T03 | `ClienteRender` reintenta una vez ante 429/503 | S503-10 (2 conexiones en vez de 1); R429-07 (conteo de PDF) | Mata |
| M-T04 | Capturar `RenderRechazadoException` en el endpoint y responder 200 con PDF vacío | R429-01 (HTTP) y S503-01 | Mata |
| M-T05 | Quitar la guarda del #156 (regenerar sin motivo) | C2-02, C2-05 | Mata |
| M-T06 | Regenerar los dorados con la salida de `GPOS.Reportes.Api` sin motivo | C2-03 (diff de dorados no vacío) | Mata, solo como revisión del PR (no automatizada) |
| M-T07 | Reponer `ConvertidorPdf.cs` en `GPOS.Api` | TR-01, `Los_archivos_borrados_no_existen` | Mata |
| M-T08 | Borrar el archivo de línea base | `Existe_la_linea_base_de_MedicionRender` | Mata solo si se escribe la guarda automática |
| M-T09 | Agregar `PuppeteerSharp` a `GPOS.Api.csproj` | TR-01, TR-03 | Mata |
| M-T10 | Perfil de Chromium ausente: la API de reportes responde 200 con PDF de QuestPDF para un formato Razor (degradación silenciosa) | C4-02 (personalizado debe dar 503) | Mata |
| M-T11 | Agregar un paquete que arrastre Razor RuntimeCompilation transitivamente | TR-02 | Mata (según la lista) |
| M-T12 | Unir T4-02b sin T4-06: el camino local P-2 sigue generando PDF en Release | C6-02 | Mata (si C6-02 se escribe) |
| M-T13 | `ReportesEndpoints.cs:67` conserva `GeneratePdf` | C6-02, `GPOS_Api_no_referencia…` | Mata |
| M-T14 | T4-02b modifica `AuditoriaAdr109Tests` más allá del método de motores | C6-03 | Solo revisión del diff |
| M-T15 | Usar `BaseDatosFixture` vieja en las pruebas nuevas | C7-02 (`git grep`) | Solo revisión |
| M-T16 | Tocar `Seguridad.cs` en T4-02b | C7-03 | Solo revisión del diff |
| M-T17 | `IClienteRender` no se registra en `Program.cs` | `FlujosMvpTests` (cualquier ruta de impresión) | Mata |
| M-T18 | Dejar el `ItemGroup` de la fuente (`CascadiaMono-Bold.ttf`) en `GPOS.Api.csproj` | TR-03, `Los_archivos_borrados_no_existen` | Mata |
| M-T19 | Quitar ClosedXML por exceso de limpieza | `GPOS_Api_conserva_ClosedXML`, `ReportesTests`, `SeguridadPc3Tests` | Mata |
| M-T20 | Reintroducir un literal de tercero en `GPOS.Reportes.Api/.../ConvertidorPdf.cs` | `ValoresDeTercerosTests` | Mata solo si la prueba vigila `GPOS.Reportes.Api`; si no, **no la mata nada** |
| M-T21 | Cambiar una palabra de `NumeroALetras` | `ImpresionNumeroLegibleTests` | Mata |
| M-T22 | `GPOS.Contracts` agrega Razor | TR-04 | Mata |
| M-T23 | Quitar un motor de `GPOS.Reportes.Api` (cambio ajeno) | TR-05 | Mata (control positivo) |
| M-T24 | La función lectora de `deps.json` siempre devuelve «no contiene» | TR-06 | Mata |
| M-T25 | `ClienteRender` serializa con las opciones de `JsonOptions` de la principal (filtro de costos) | `Los_modelos_dorados_viajan_sin_perdida` (T4-02a) y AD-06 | Mata |
| M-T26 | `ClienteRender` copia el token a una respuesta 401 sin comprobar que viene de la sesión | AD-02 | Mata |
| M-T27 | `NumeroALetras` en `GPOS.Contracts` diverge de `FormatoDocumento.MonedaEnLetras` (si éste delega, bien; si queda duplicado, divergen) | Fila de comparación nueva de #6 | Mata solo con la fila nueva |
| M-T28 | El doble de `IClienteRender` devuelve OK aunque `autorizar` no se llame | AD-01, AD-02 | Mata |
| M-T29 | Retry-After: `RenderRechazadoException` sin `ReintentarEn` | `Los_codigos_del_render_llegan_al_puesto` (429) y R429-01 | Mata |
| M-T30 | El texto del 503 de impresión es el de «reportes» (`ReenvioReportes.cs:357`) en vez del de impresión | S503-01 | Mata |

## 7. Orden de trabajo y esfuerzo [I]

| Tanda | Contenido | dp |
|---|---|---|
| T0 | Lista de verificación de condiciones (sección 1), guardas U (1.6) y prueba transitiva (sección 4). No requiere Chromium | 0,75 |
| T1 | Las dos pruebas nombradas (sección 2) con doble y, para S503, anfitrión apagado | 1,0 |
| T2 | Adaptación de los 10 (o 13) archivos y AD-01 a AD-06 | 1,25 |
| T3 | Medición «después» (protocolo y escenarios; la ejecución es de B con LFMB) | 0,5 |
| Total | | **3,5** (±50 %) |

Orden de escritura: T0 antes de que B borre nada, porque la prueba transitiva es **roja** hasta que B quita los paquetes (sirve de lista de tareas). T1 puede escribirse con el doble desde ya. T2 se hace al final, tras T1-5 (C-7).

Suite: `--filter "Transicion!=Ola5&Transicion!=Defecto"`, sola; el 11-16 y el 11-17 sin suites. Máximo 3 compilaciones a la vez.

## 8. Dudas abiertas

| # | Duda | Quién |
|---|---|---|
| D-1 | C-2 depende del #156, que ahora es mío y espera revisión humana de dorados; el plan lo da por unido | Propietario / A |
| D-2 | C-3: ¿dónde se archiva la línea base y con qué formato? Propongo `docs/calidad/AAAA-MM-DD-linea-base-medicion-render.md` en la rama | B |
| D-3 | C4-02: ¿503 `REPORTES_NO_DISPONIBLE` o `NAVEGADOR_NO_DISPONIBLE` cuando falta la carpeta del perfil? Y el nombre exacto de la opción del perfil del #170 | B |
| D-4 | La lista de «10 archivos» del BP omite `ReimpresionTests`, `NumeracionPc3EjemploTests` y `FlujosMvpTests`, que el BP 10.1 también dice que generan PDF. ¿Son 13? | B |
| D-5 | El cierre viaja **completo** hoy por `SolicitudRenderCierre` (C-2′ y recorte solo en T4-11); AD-01 solo comprueba que el permiso precede | B / A |
| D-6 | Lista exacta de la prueba transitiva: ver el `deps.json` real antes de fijar los transitivos; ¿se incluye `GPOS.Web` y `GPOS.UI.MAUI`? | B |
| D-7 | R429-06: la regla exacta del reintento libre en `ReimpresionService` (no la leí) | B |
| D-8 | P170-07 cambia `MarcarCopia`: `ReglasReimpresionTests` (#7) se reescribe o se adapta; ver el plan de la tabla adversaria. ¿Qué entra primero en T4-02? | B |
| D-9 | Si P170-07 (b) se construye en T4-02, el modelo (`ModeloImpresion.Copia`) sigue viajando; la marca la pone el `ConvertidorPdf` de la API de reportes: no cambia el contrato (versión 1). Confirmar | B |

### Cierre
- Estado: Completado (plan; sin ejecutar)
- Artefactos: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\C\2026-10-23-plan-pruebas-t4-02b.md`
- Supuestos: el BP en `fc68c7f6` es la versión vigente; no leí los 10 archivos de pruebas, solo su descripción en el BP
- Decisiones candidatas a ADR: Ninguna
- Entregas a otros agentes: B → responder D-1 a D-9; devops → ninguna
- Próximo paso recomendado: B decide D-2, D-3 y D-4 antes del 16-nov
