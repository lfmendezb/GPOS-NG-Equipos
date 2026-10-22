```
Para: B        De: C        Fecha: 2026-10-22
Tipo: Entrega (tarea 4 del aviso 2026-10-22: actualizar el plan de pruebas de D1 con las condiciones de la revisión de A)
Prioridad: Media
Repositorio y rama: GPOS-NG `feature/modelo-ng` (D1 de DB-7); fuentes en `master` y en `origin/b/plan-d1-condiciones-a` (PR #154)
Estado: Abierto (plan, sin código; adelantado respecto de la fecha 2-nov)
```

# Plan de pruebas de DB-7 D1, versión 2 (condiciones D1-01 a D1-06, CS-P2 y `--caso`)

Esta versión **no reemplaza** mi plan del 20-oct (`traspasos/C/2026-10-20-plan-pruebas-db7-d1.md`, en adelante **P20**): lo **complementa**. Los números de prueba que cito como «P20 T1-1 #33» son los de las tablas de P20.

**Fuentes leídas:**
- P20 completo, salvo las líneas 202-204 (pruebas 22-24 de T1-1; no las necesito).
- `git diff origin/master...origin/b/plan-d1-condiciones-a` (PR #154): solo cambia `docs/arquitectura/2026-10-19-db7-d1-plan-de-trabajo.md` (+29/-1). **Leí el diff, no el archivo entero.**
- `traspasos/A/revision-seguridad-diseno-d1-db7-2026-10-21.md` completo (D1-01 a D1-15).
- `docs/decisiones/2026-10-22-hoja-firma-adr92-precisiones.md` en `origin/master` (F-1 a F-9, sección 3 con CS-P2) y las líneas de `docs/adr/ADR-092.md` que citan CS-P2 (grep).

**Nada se compiló, se ejecutó ni se programó.** Lo que depende del comportamiento de SQL Server o de .NET y nadie ejecutó está marcado *(inferido)*.

**Clave de las tablas.**
- **Tipo:** SQL = necesita una base `GPOS_TEST_*`. HTTP = API en proceso (con base). TX = unidad o texto, sin base ni red. ARQ = prueba de arquitectura sobre fuentes o ensamblados.
- **Falla si…** = la mutación mental: el sabotaje concreto que debe ponerla en rojo. Una prueba que no se pone en rojo con su mutante no demuestra nada.
- **Dep.** = de qué depende para existir (tarea, pregunta o decisión pendiente). **P-D1-06** = la opción (a) o (b) de la marca de conversión, aún sin firma.
- Nombres de método: los que da A o el PLAN de #154 van en negrita de origen «PLAN»; los demás son propuesta mía.

---

## 1. Lo que cambia en una mirada

1. **Seis condiciones de A, ninguna Alta.** Cada una es condición para unir un PR (D1-01 a D1-06). Ninguna de las seis tenía prueba en P20, salvo parcialmente D1-06 (T1-1 #33) y la lectura de NULL de D1-05 (T1-2 #10).
2. **Cuatro consecuencias que el PLAN de #154 no dice** y que el desarrollador va a encontrar:
   - **D1-01 rompe todas las pruebas HTTP de T1-3** si no siembran la marca `Accesos.Modelo` en su base. Es un cambio de la fixture, no de cada prueba (sección 2.3).
   - **CS-P2 rompe la prueba P20 T1-1 #25** («ningún otro índice nuevo») y obliga a reescribir la #55 (`INGRESO_SUPER` ahora lleva caso). Cuadro de la sección 8.
   - **D1-06 cambia la semántica** del disparador 51619: `IF UPDATE(...)` rechaza `SET EmpresaCodigo = EmpresaCodigo` (mismo valor) y, *(inferido)*, también un `UPDATE ... WHERE 1=0` que mencione la clave. Pruebas D1-06.2 y D1-06.3.
   - **Un `--caso` de 31 caracteres que viaja en un `SqlParameter` con `Size = 30` se trunca en silencio** *(inferido; es el comportamiento documentado de ADO.NET)* y quedaría guardado como un caso de 30 caracteres que el operador nunca tecleó. Por eso el validador de C# debe rechazar antes (CP2-03 y CP2-17).
3. **Un hallazgo propio nuevo, H-13 (Media):** el alfabeto `[A-Z0-9-]` admite un caso formado solo por guiones (`------`) y un valor `--MOTIVO` (otra opción de la línea de comandos tomada como valor de `--caso`). Ver la sección 10 (H-13), CASO-02 y la pregunta Q-V2-09.
4. **Cuántas pruebas:** unas **70 nuevas** (±5, una teoría cuenta una vez) y **19 cambios en pruebas de P20** (sección 8). Esfuerzo inferido: 1,5 a 2,2 días-persona de pruebas, ±40 % (sección 10).
5. **`En_D1_la_marca_indica_sin_sello` es un centinela:** en D3 cambia de sentido (sección 4). Propongo un rasgo `[Trait("Centinela","D3")]` en todas las pruebas que D3 debe invertir.

---

## 2. Reglas comunes de esta versión

### 2.1 Convenciones heredadas de P20 (siguen vigentes)
- Un solo `[Trait("Esquema","NG")]` por archivo; carpetas `tests/GPOS.Tests/Acceso/` y `Arquitectura/`; bases `GPOS_TEST_SIS_ACC_*` con `BasesTemporales.EliminarAsync` en `finally`; protocolo «rojo primero» (P20 2.2); sin suite completa en la PC de C.
- Datos: DB-N, DB-L y DB-5 (P20 2.4). **Nuevo:** **DB-6r2**, una DB-N a la que la prueba le deja el estado de una base creada con la revisión 2 de la DDL de D1 (sin `NumeroCaso`/`Urgencia` y con la `CK_BitacoraSeguridad_IngresoSuper` anterior). Solo la usa CP2-12.

### 2.2 Rasgo nuevo
`[Trait("Centinela","D3")]` en las pruebas que D3 invierte (sección 4). Permite a quien construya D3 listarlas con `--filter "Centinela=D3"`.

### 2.3 Cambio de fixture por D1-01 (afecta a todo T1-3)
- `ApiMvpFactory` (Amplio) para `MiembrosHttpTests` y `SuperCuentasHttpTests` debe sembrar `Configuracion('Accesos.Modelo') = 'MEMBRESIA.v1'` (o el valor que decida P-D1-06) **antes de arrancar**. Sin eso las 22 pruebas HTTP de P20 7.3 darían 503.
- Las pruebas nuevas D1-01.1 a D1-01.5 usan una variante **sin** marca; por eso la fixture debe exponer `ConMarca(bool)` y no depender de un valor fijo.
- Lo mismo vale para las pruebas de servicio que pasen por el pipeline de la API; las de SQL directo no lo necesitan.

### 2.4 Cambio de ayudante por `--caso`
- `ConversionAccesosTests` ejecuta el verbo con un ayudante `EjecutarVerboAsync(args)`. Debe añadir por omisión `--caso TEST-0001` (y `--motivo` válido cuando el modo lo pida), con un parámetro `sinCaso: true` para las pruebas negativas. Si no, las 30 pruebas de P20 T1-4 fallan por la causa equivocada.

---

## 3. Pruebas nuevas por condición

### 3.1 D1-01 · Rutas de membresías antes del convertir (T1-3 y T1-4; Media)

Condición de A: las rutas de T1-3 responden 503 `ACCESOS_NO_CONVERTIDOS` mientras falte la marca `Accesos.Modelo`; precondición 10 del verbo; etiqueta `db7-antes-del-corte` sobre la punta anterior a T1-1 (P-D1-05).

| ID | Prueba | Tipo | Falla si… | Dep. |
|---|---|---|---|---|
| D1-01.1 | `MiembrosHttpTests.Sin_marca_todas_las_rutas_de_miembros_responden_503_ACCESOS_NO_CONVERTIDOS` (**PLAN**: `Sin_convertir_las_rutas_de_miembros_responden_503`). Teoría **generada**: recorre el `EndpointDataSource` de la API, toma toda ruta que coincida con `/api/admin/miembros*`, `/api/super/cuentas*` o `/api/super/empresas/{c}/miembros*` (cada verbo HTTP) y la llama autenticada con el nivel que exige. Esperado: 503, código `ACCESOS_NO_CONVERTIDOS`, y **nada cambia** en la base (`CHECKSUM_AGG` de las tablas nuevas y de `BitacoraSeguridad`). Como las rutas salen del `EndpointDataSource`, **una ruta nueva sin compuerta rompe la prueba sin tocarla** (cubre la «ruta olvidada») | HTTP | una ruta de T1-3 no lleva la compuerta (basta una); o la compuerta responde 200/404 y no 503; o deja una fila en la bitácora | T1-3; fixture 2.3 |
| D1-01.2 | `MiembrosHttpTests.Con_la_marca_las_rutas_de_miembros_ya_no_responden_503` (par obligatorio de la anterior). Misma teoría con la marca `MEMBRESIA.v1` y, si rige P-D1-06 (a), también con `MEMBRESIA.v1-sin-sello`: ninguna da 503 `ACCESOS_NO_CONVERTIDOS` | HTTP | la compuerta responde 503 siempre (D1.1 pasaría en vacío); o no reconoce el valor `v1-sin-sello` (D1 quedaría inutilizable) | D1-01.1; P-D1-06 |
| D1-01.3 | `MiembrosHttpTests.Sin_autenticar_o_sin_nivel_el_503_no_se_adelanta_al_401_y_al_403` | HTTP | la compuerta corre antes de la autenticación y un anónimo averigua si la instalación está convertida (oráculo de estado) | Q-V2-04 |
| D1-01.4 | `MiembrosHttpTests.Si_falla_la_lectura_de_la_marca_responde_503_y_no_2xx` (doble de la lectura que lanza `SqlException` no relacionada con interbloqueo, y otra con `TimeoutException`) | HTTP | la compuerta captura la excepción y deja pasar (falla abierta), o responde 500 | T1-3 |
| D1-01.5 | `MiembrosHttpTests.La_compuerta_ve_la_marca_recien_escrita` (primero 503; se escribe la marca por SQL; la siguiente llamada ya no da 503 sin reiniciar la API) | HTTP | la marca se cachea sin vencimiento. **Condicional a Q-V2-05** (si B decide cachear N segundos, la prueba espera N s con un reloj falso) | Q-V2-05 |
| D1-01.6 | `ConversionAccesosTests.Con_membresias_previas_se_detiene_con_51622` (**PLAN**). Teoría de tres escenas: (i) una fila en `UsuariosEmpresas`; (ii) una en `EmpresasPerfiles`; (iii) ambas. Esperado: 51622 con mensaje que nombra la tabla (no las filas), código de salida distinto de 0, `CHECKSUM_AGG` de todas las tablas globales y nuevas **igual** que antes y **sin** marca `Accesos.Modelo` | SQL | la precondición mira una sola tabla; o el verbo avanza hasta el paso 3 y falla por la PK (mensaje que no explica la causa, el riesgo que describe A); o deja la marca | T1-4 |
| D1-01.7 | `ConversionAccesosTests.Con_las_tablas_nuevas_vacias_la_precondicion_10_no_estorba` (par: la escena ESC-DEMO normal convierte hasta el final, y una base con las dos tablas vacías **pero con sus hijas vacías también** convierte) | SQL | la precondición responde 51622 siempre o cuenta filas de otra tabla | D1-01.6 |
| D1-01.8 | `ConversionAccesosTests.La_precondicion_10_se_evalua_antes_que_cualquier_escritura_y_despues_de_la_1` (con la marca puesta **y** una membresía: gana el «ya convertido», código 0, sin 51622; sin marca y con membresía: 51622; el `TABLOCKX` del paso 1 no se toma antes de decidir) | SQL | se invierte el orden: una base ya convertida respondería 51622 en vez de «ya convertido» (rompe P20 T1-4 #6) | P20 T1-4 #6 |

Proceso, no prueba xUnit: la etiqueta `db7-antes-del-corte` va sobre la punta anterior a T1-1. Verificación de la lista de cierre del PR de T1-1: `git merge-base --is-ancestor db7-antes-del-corte <primer commit de T1-1>^` debe salir con 0, y `git rev-list db7-antes-del-corte..<punta>` debe contener los commits de T1-1. Lo anoto aquí para que quede en la lista de cierre, no en `GPOS.Tests`.

### 3.2 D1-02 · Marca de la conversión sin sello (T1-4; Media)

Depende de **P-D1-06 (pendiente de firma)**. Escribo las dos ramas; **solo se construye una**.

**Rama (a): marca `MEMBRESIA.v1-sin-sello` y padrón v1 guardado** (recomendada por B y por A).

| ID | Prueba | Tipo | Falla si… | Dep. |
|---|---|---|---|---|
| D1-02.1 | `ConversionAccesosTests.En_D1_la_marca_indica_sin_sello` (**PLAN**, `[Trait("Centinela","D3")]`). Tras convertir ESC-DEMO: `Configuracion('Accesos.Modelo') = 'MEMBRESIA.v1-sin-sello'` (comparación ordinal exacta); **todas** las filas de `UsuariosEmpresas` con `SelloMembresia IS NULL`; la marca se escribe **la última** (después del paso 9, P20 T1-4 #29) | SQL | el verbo escribe `MEMBRESIA.v1`; o escribe la marca antes del final; o sella alguna fila | (a) |
| D1-02.2 | `ConversionAccesosTests.El_padron_v1_se_guarda_en_la_conversion_y_es_el_de_ese_momento` | SQL | no se guarda; o se guarda el padrón de **después** de un cambio posterior (se compara con el resumen del padrón tomado antes del paso 1); o se guarda fuera de la transacción y una reversión (51621) deja un padrón huérfano | (a); Q-V2-03 (¿dónde?) |
| D1-02.3 | `ConversionAccesosTests.Un_fallo_despues_de_guardar_el_padron_deja_la_base_igual` (se agrega a la teoría de pasos de P20 T1-4 #5 el paso «guardar padrón v1») | SQL | el padrón sobrevive a la reversión | D1-02.2 |
| D1-02.4 | `AccesoArquitecturaTests.Solo_D3_escribe_la_marca_MEMBRESIA_v1` (búsqueda del literal `'MEMBRESIA.v1'` sin sufijo en `src/`: en D1 **ninguna** coincidencia fuera de la constante que lee la compuerta) | ARQ | alguien reutiliza el literal sin sufijo y D1 sella «a mano» | (a) |
| D1-02.5 | `ConversionAccesosTests.En_D1_el_verbo_no_ejecuta_los_pasos_6_y_7` (sin padrón v2, sin sellos, el cupo no se toma del padrón) | SQL | el verbo sella en D1 (rompe el principio de ADR-83, punto 2, que A cita) | (a) |
| D1-02.6 | `ConversionAccesosTests.Segunda_ejecucion_con_marca_sin_sello_informa_ya_convertido_con_codigo_0` (ajusta P20 T1-4 #6) | SQL | la precondición 1 solo reconoce `MEMBRESIA.v1`: el verbo reconvertiría, chocaría con D1-01.6 y saldría con 51622 en lugar de 0 | (a); D1-01.8 |
| D1-02.7 | `EsquemaAccesoTests.El_reverso_se_detiene_con_51622_con_la_marca_sin_sello` (ajusta P20 T1-1 #75, que solo cita «la marca `Accesos.Modelo`») | SQL | el reverso compara con el valor exacto `MEMBRESIA.v1` y borra tablas con datos convertidos | (a) |
| D1-02.8 | `EstadoAccesoTests.Con_marca_sin_sello_el_sello_no_aplica_y_no_se_exige` (refina P20 T1-2 #8) | SQL | el evaluador de D1 trata una base «sin sello» como «con sello inválido» (todos sin acceso) o como «sellada» | (a); T1-2 |

**Rama (b): `--solo-pruebas` y rechazo con licencia.**

| ID | Prueba | Tipo | Falla si… | Dep. |
|---|---|---|---|---|
| D1-02.9 | `ConversionAccesosTests.Sin_solo_pruebas_se_detiene_con_51622` | SQL | el verbo convierte sin la bandera | (b) |
| D1-02.10 | `ConversionAccesosTests.Con_solo_pruebas_y_licencia_se_detiene_con_51622` (teoría: Producción, Beta, Desarrollo, Demostración; igual criterio que D1-03.1) | SQL | solo rechaza Producción y deja pasar Beta | (b) |
| D1-02.11 | `ConversionAccesosTests.Con_solo_pruebas_y_sin_licencia_convierte` y `AccesoArquitecturaTests.La_bandera_solo_pruebas_no_se_activa_por_variable_de_entorno_ni_configuracion` (ARQ: la bandera es un argumento de la línea de comandos, no se lee de `IConfiguration`) | SQL + ARQ | la bandera viaja por una variable de entorno que un instalador deja puesta | (b) |
| D1-02.12 | `EstadoAccesoTests.D1_una_base_convertida_en_modo_pruebas_se_reconvierte_en_D3` (ver sección 4, rama (b)) | SQL | D3 hereda una base sin sello | (b) |

Tabla de decisión: si B firma (a), se construyen D1-02.1 a .8 (8 pruebas); si firma (b), D1-02.9 a .12 (4 pruebas). **No** se construyen las dos.

### 3.3 D1-03 · `--instalacion-demo` sin guarda técnica (T1-4; Media)

Condición de A: rechazo con 51622 si la licencia vigente es Producción o Beta; vista previa por empresa con el número de ADMIN que se crearán; confirmación reescribiendo el número de empresas o `DEMO`.

| ID | Prueba | Tipo | Falla si… | Dep. |
|---|---|---|---|---|
| D1-03.1 | `ConversionAccesosTests.Modo_DEMO_con_licencia_de_produccion_o_beta_se_detiene_con_51622` (**PLAN**, teoría: Producción, Beta). Esperado: 51622, mensaje que dice qué licencia y qué hacer, `CHECKSUM_AGG` igual, sin marca, **sin haber tomado el `TABLOCKX`** (la comprobación va antes del paso 1) | SQL | la comprobación se hace después de alguna escritura; o solo valida Producción | T1-4; fixture de licencia |
| D1-03.2 | `ConversionAccesosTests.Modo_DEMO_con_licencia_de_desarrollo_o_demostracion_procede` (teoría; par de la anterior) | SQL | el rechazo es incondicional (la prueba D1-03.1 pasaría en vacío) | D1-03.1 |
| D1-03.3 | `ConversionAccesosTests.Modo_DEMO_con_licencia_ausente_o_ilegible_falla_cerrado` (sin archivo; archivo con firma inválida; vigencia vencida) | SQL | la ausencia se interpreta como «no es Producción» y deja pasar | **Q-V2-06** (¿qué es «sin licencia» en una base de ensayo?) |
| D1-03.4 | `ConversionAccesosTests.La_vista_previa_muestra_por_empresa_cuantos_ADMIN_se_crearan` (ESC-DEMO: 3 empresas, una inhabilitada; 2 ADMIN y 1 SUPER). Esperado: por cada empresa **habilitada**, el número de ADMIN y de USER que recibirá; la inhabilitada no aparece con ADMIN; el SUPER no cuenta. El número se compara con un cálculo **independiente** hecho en la prueba sobre las tablas globales | SQL | el total global sustituye al desglose; o cuenta la empresa inhabilitada; o cuenta al SUPER | T1-4 |
| D1-03.5 | `ConversionAccesosTests.La_confirmacion_exige_el_numero_de_empresas_o_DEMO` (teoría con entrada simulada). Correctas: `DEMO` y el número. Incorrectas: número equivocado, **el total de empresas (3) cuando las habilitadas son 2** (o al revés, según Q-V2-07), vacío, espacios, fin de la entrada (EOF), `demo` en minúsculas (según Q-V2-07). Esperado en las incorrectas: salida distinta de 0 y la base **igual** | SQL | acepta cualquier cadena no vacía; o acepta el total en vez de las habilitadas | Q-V2-07 |
| D1-03.6 | `ConversionAccesosTests.Sin_consola_interactiva_no_hay_confirmacion_implicita` (entrada redirigida y cerrada) | SQL | el modo no interactivo salta la confirmación | **Q-V2-08** (¿hay un argumento para automatizar, p. ej. `--confirmar DEMO`?) |
| D1-03.7 | `ConversionAccesosTests.El_modo_minimo_no_pide_confirmacion_ni_comprueba_la_licencia` (guardia) | SQL | la guarda de DEMO se contagia al modo mínimo (rompe P20 T1-4 #9) | D1-03.1 |
| D1-03.8 | `AccesoArquitecturaTests.El_verbo_y_la_API_usan_el_mismo_criterio_de_licencia_de_produccion` (el verbo llama a la misma función que `Program.cs:441-442` que cita A, no una copia) | ARQ | se duplica la condición y las dos derivan | T1-4 |

### 3.4 D1-04 · La versión de privilegios depende de cada camino (T1-1 y T1-2; Media)

Condición de A: todo DML sobre `UsuariosEmpresasPerfiles`, `UsuariosEmpresasPermisos`, `EmpresasPerfilesPermisos` y `EmpresasPerfiles.Inhabilitado` pasa por **un solo método** que sube la versión de los afectados en la misma transacción; una prueba de arquitectura vigila; el disparador en las hijas queda descartado.

| ID | Prueba | Tipo | Falla si… | Dep. |
|---|---|---|---|---|
| D1-04.1 | `AccesoArquitecturaTests.Todo_DML_sobre_las_cuatro_tablas_de_privilegios_pasa_por_un_solo_metodo` (**PLAN**). Recorre `src/` (todas las carpetas, incluida `GPOS.Migracion`) buscando `INSERT`, `UPDATE`, `DELETE`, `MERGE`, `TRUNCATE` y `ExecuteSql*` que nombren esas tablas (con o sin `dbo.` y corchetes), y los `DbSet`/`Add`/`Remove`/`ExecuteUpdate` equivalentes. Lista de permitidos **explícita y mínima**: el método único y, si B lo decide, el paso 3 de la conversión y la DDL de siembra | ARQ | aparece un `UPDATE dbo.EmpresasPerfiles SET Inhabilitado = 1` en otro tipo | Q-V2-10 (lista de permitidos) |
| D1-04.2 | `AccesoArquitecturaTests.El_escaner_de_D1_04_1_detecta_lo_que_debe_y_no_lo_que_no` («prueba de la prueba»). Alimenta al escáner con textos fijos: positivos (`UPDATE dbo.EmpresasPerfiles`, `update [dbo].[UsuariosEmpresasPermisos]`, `INSERT INTO dbo.UsuariosEmpresasPerfiles`, `DELETE`, `MERGE`, en dos líneas, con comentario entre medias) y negativos (`SELECT ... FROM dbo.EmpresasPerfiles`, la palabra en un comentario `--`, una cadena de lectura) | TX | el escáner no distingue mayúsculas, o se rompe con saltos de línea, y D1-04.1 pasa en vacío | D1-04.1 |
| D1-04.3 | `PermisosEmpresaTests.Cada_camino_que_cambia_privilegios_sube_la_version_solo_de_los_afectados_y_una_vez` (teoría por camino): (1) asignar un perfil; (2) quitar un perfil; (3) editar los permisos de un perfil (Q6); (4) inhabilitar y volver a habilitar un perfil; (5) guardar excepciones (Q13); (6) eliminar un reporte (sale `rpt:{id}` de excepciones y de perfiles); (7) siembra por empresa; (8) pasos únicos de `PermisosService`. Esperado en cada uno: la `VersionPrivilegios` de **cada** afectado sube **exactamente 1**, la de los demás (otro perfil, otra empresa, `BAJA`) no cambia | SQL | un camino olvida el aumento (la brecha que describe A); o sube 2 (disparador oculto); o sube a toda la empresa | T1-2; la lista de caminos la cierra B (Q-V2-10) |
| D1-04.4 | `PermisosEmpresaTests.Un_fallo_en_el_camino_deja_version_e_hijas_como_estaban` (misma teoría; se inyecta un fallo **después** del DML y antes del `COMMIT`) | SQL | la subida de versión va en una transacción distinta de la del cambio (queda el privilegio nuevo con la versión vieja, o al revés) | D1-04.3 |
| D1-04.5 | `EsquemaAccesoTests.Las_cuatro_tablas_de_privilegios_no_tienen_disparadores` (`sys.triggers` por tabla = vacío) | SQL | alguien implementa la alternativa descartada: el disparador de las hijas vuelve a disparar 51619 sobre el padre y Q13 devuelve `versionLeida + 2` | T1-1 |
| D1-04.6 | `PermisosEmpresaTests.Eliminar_un_reporte_quita_rpt_id_de_excepciones_y_perfiles_y_sube_la_version_de_los_portadores` (la ruta que A señala con `DAT:180`) | SQL | el borrado deja `rpt:{id}` huérfano o no sube la versión; el portador conserva el permiso hasta que venza la caché | **Q-V2-11** (¿esa ruta existe hoy en el código? no la verifiqué) |

### 3.5 D1-05 · Q1 y el evaluador: «sin fila = sin acceso» (T1-2; Media)

Condición de A: el evaluador de `EstadoAcceso` es una lista blanca; empresa inexistente, SUPER con empresa inexistente o inhabilitada, valores desconocidos y lectura fallida (503, nunca 401).

| ID | Prueba | Tipo | Falla si… | Dep. |
|---|---|---|---|---|
| D1-05.1 | `EstadoAccesoTests.El_evaluador_da_acceso_solo_con_la_combinacion_exacta` (**matriz** sobre la función pura del evaluador, con filas fabricadas, sin base). Ejes: nivel de la cuenta {USER, ADMIN, SUPER} × cuenta {habilitada, inhabilitada} × empresa {inexistente (`Codigo` NULL), inhabilitada, habilitada} × membresía {sin fila, `HABILITADA`, `SUSPENDIDA`, `BAJA`}. Tabla de verdad **escrita dentro de la prueba**. Hay acceso solo si: cuenta habilitada, empresa existente y habilitada, y (membresía `HABILITADA` o cuenta SUPER). Los casos «SUPER × empresa inhabilitada» salen de ADR-35 (**sin leer**): la prueba trae las dos expectativas y la activa la respuesta de B | TX | cualquier evaluación del tipo «si es SUPER, concede» **antes** de comprobar que la empresa existe (el caso que describe A); o `LEFT JOIN` con `ue.*` NULL tratado como `HABILITADA` | T1-2; Q-V2-12 (ADR-35) |
| D1-05.2 | `EstadoAccesoTests.Un_valor_desconocido_da_sin_acceso` (propiedad con entradas fabricadas: `Estado` ∈ {`X`, ``, NULL, `habilitada`, `HABILITADA `}; `Nivel` ∈ {`GOD`, NULL, `admin`, `SUPER `}; empresa con `Inhabilitado` NULL). Esperado: ninguno concede | TX | el evaluador usa una lista negra («si no es SUSPENDIDA...») o compara sin distinguir mayúsculas | Q-V2-12 (minúsculas: H-12 de P20) |
| D1-05.3 | `EstadoAccesoTests.Q1_empresa_inexistente_da_sin_acceso` (**PLAN**, teoría USER, ADMIN y SUPER, con la Q1 real y el evaluador real) | SQL | cualquiera de los tres recibe sesión en una empresa que no existe | T1-2 |
| D1-05.4 | `EstadoAccesoTests.Q1_SUPER_con_empresa_inhabilitada` (**PLAN**; el resultado esperado lo fija ADR-35) | SQL | el SUPER entra donde ADR-35 dice que no (o al revés) | Q-V2-12 |
| D1-05.5 | `EstadoAccesoTests.El_lector_de_Q1_tolera_NULL_en_todas_las_columnas_de_Empresas_y_UsuariosEmpresas` (empresa inexistente: `e.*` NULL; sin membresía: `ue.*` NULL). Esperado: no lanza `InvalidCastException` ni `NullReferenceException`; devuelve «sin acceso» | SQL | el lector hace `GetBoolean` o `GetString` sobre una columna NULL y la petición muere con 500 (sería un acceso denegado por accidente, y 500 en vez de 403/503) | T1-2; amplía P20 T1-2 #10 |
| D1-05.6 | `EstadoAccesoServiceTests.Una_lectura_fallida_da_ACCESO_NO_DISPONIBLE_y_nunca_acceso_denegado_401` (doble con `SqlException` genérica, timeout y cancelación). 1205 sigue en la #16 de P20 | TX | la excepción se traduce a 401 (cierra la sesión de todos ante una caída de la base) o a «acceso concedido» | T1-2. El mapeo HTTP final es de T1-5: queda en **Entregas** |

### 3.6 D1-06 · Disparador 51619 e intercambio de claves (T1-1; Baja)

Condición de A: `IF UPDATE(UsuarioCodigo) OR UPDATE(EmpresaCodigo) THROW 51619`. Prueba nombrada por A: `RestriccionesMembresiaTests.E51619_actualizar_la_clave_se_rechaza_siempre`.

| ID | Prueba | Tipo | Falla si… | Dep. |
|---|---|---|---|---|
| D1-06.1 | `RestriccionesMembresiaTests.E51619_actualizar_la_clave_se_rechaza_siempre` (**A/PLAN**, teoría). Escenas: (i) cambiar `EmpresaCodigo` de una fila; (ii) cambiar `UsuarioCodigo` de una fila; (iii) **intercambiar** `EmpresaCodigo` entre las dos membresías de una misma cuenta en una sola sentencia (`CASE`); (iv) intercambiar `UsuarioCodigo` entre dos cuentas de la misma empresa; (v) cada una de las anteriores **subiendo también la versión** (+1). Esperado: 51619, y las filas intactas | SQL | el disparador conserva la comparación `inserted`/`deleted`: (iii) y (iv) pasan (el hallazgo de A); o (v) cuela porque la versión subió | T1-1 |
| D1-06.2 | `RestriccionesMembresiaTests.E51619_aunque_el_valor_no_cambie_mencionar_la_clave_se_rechaza` (`SET EmpresaCodigo = EmpresaCodigo`) | SQL | el disparador compara valores en vez de usar `UPDATE()`. Es **un cambio de semántica respecto de P20 #33/#35** y lo dejo explícito: quien escriba SQL que reasigne la clave a sí misma recibirá 51619 | T1-1 |
| D1-06.3 | `RestriccionesMembresiaTests.Un_UPDATE_de_cero_filas_que_menciona_la_clave_no_da_error` (`SET EmpresaCodigo = N'X' WHERE 1 = 0`). *(Inferido: un disparador `AFTER` se dispara aunque se afecten 0 filas y `UPDATE()` es verdadero si la columna está en el `SET`.)* | SQL | falta `IF NOT EXISTS (SELECT 1 FROM inserted) RETURN`: un `UPDATE ... WHERE` que no encuentra filas lanza 51619 (rompe P20 #37) | T1-1 |
| D1-06.4 | `AccesoArquitecturaTests.Ninguna_sentencia_de_src_asigna_la_clave_de_UsuariosEmpresas` (ninguna constante SQL de `src/` contiene `SET ... EmpresaCodigo =` ni `UsuarioCodigo =` dentro de un `UPDATE dbo.UsuariosEmpresas`). Con `UPDATE()` basta **mencionar** la columna para fallar | ARQ | Q13, Q27 (`UltimoAcceso`) o un camino de baja/reactivación incluye la clave en el `SET` por comodidad y falla en producción, no en el desarrollo | T1-1/T1-2 |
| D1-06.5 | `RestriccionesMembresiaTests.Con_hijas_cambiar_la_clave_da_547_o_51619_y_no_cambia_nada` (membresía con perfil y excepción; `EmpresaCodigo` a otra empresa existente) | SQL | una de las dos barreras desaparece y la fila se mueve con sus hijas apuntando a la empresa vieja. Se acepta **cualquiera** de los dos errores (la FK compuesta se evalúa antes que el disparador `AFTER`, *inferido*) | T1-1 |

---

## 4. Qué prueba se invierte en D3

### 4.1 `ConversionAccesosTests.En_D1_la_marca_indica_sin_sello`

**Por qué existe.** A pide (D1-02) que una base convertida en D1 no pueda confundirse con una convertida y sellada: la marca `MEMBRESIA.v1-sin-sello` es la señal. La prueba **fija un estado transitorio**: «en D1 la conversión termina sin sellos y lo dice la marca». Es un **centinela**: su función es romperse el día que el comportamiento deba cambiar, para que alguien lea por qué.

**Por qué cambia de sentido en D3.** En D3 el verbo ejecuta los pasos 6 y 7 (sellos y cupo derivados del padrón). El estado correcto deja de ser «sin sello»:
- una conversión nueva escribe `MEMBRESIA.v1` y **todas** las membresías con `SelloMembresia` no nulo;
- una base convertida en D1 pasa por `accesos --completar-sellos`, que ejecuta **solo** los pasos 6 y 7 **derivados del padrón v1 guardado**, nunca de las filas (ADR-83, punto 2).

La prueba D1 afirma lo contrario («marca sin sello, sellos nulos»), así que en D3 **debe fallar**, y la forma correcta de arreglarla es **invertirla**, no borrarla ni relajarla.

**Qué la sustituye en D3** (rama (a)):

| ID (D3) | Prueba | Tipo | Falla si… |
|---|---|---|---|
| D3-S.1 | `ConversionAccesosTests.En_D3_la_conversion_deja_la_marca_MEMBRESIA_v1_y_cada_membresia_con_sello` (la inversa literal) | SQL | el verbo D3 sigue escribiendo `v1-sin-sello` o deja una fila sin sello |
| D3-S.2 | `CompletarSellosTests.Completar_sellos_deriva_del_padron_v1_guardado_y_no_de_las_filas` (se altera el nivel de una membresía por SQL antes de completar: el sello no puede reflejar la alteración, y debe rechazarse o ignorar la fila) | SQL | el sello se calcula de las filas (el sobreacceso se legitima) |
| D3-S.3 | `CompletarSellosTests.Completar_cambia_la_marca_a_MEMBRESIA_v1_al_final_y_es_idempotente` | SQL | la marca se escribe antes de sellar la última fila |
| D3-S.4 | `EstadoAccesoTests.Una_base_sin_sello_en_D3_da_MEMBRESIA_SIN_SELLO_antes_de_completar` (D3 invierte también `D1_el_sello_de_membresia_aun_no_se_exige`, P20 T1-2 #8) | SQL | D3 deja pasar membresías sin sello |
| D3-S.5 | `CompletarSellosTests.Si_el_padron_guardado_falta_o_no_coincide_se_detiene_con_51622_y_no_sella` | SQL | sella igual y legitima en masa |
| D3-S.6 | `AccesoArquitecturaTests.Solo_D3_escribe_la_marca_MEMBRESIA_v1` (D1-02.4: la lista de permitidos pasa de vacía a «verbo D3 y completar») | ARQ | otro tipo escribe la marca |

**Si rige la rama (b)** (`--solo-pruebas`): la prueba D1 equivalente es D1-02.9 (`Sin_solo_pruebas_se_detiene`). En D3 **se elimina** (el verbo ya no necesita la bandera) y se sustituye por D1-02.12: «una base convertida en modo pruebas se reconvierte en D3»; esa reconversión exige un reverso o una base nueva (por eso A la llama «más barata»: traslada el costo a cada base de ensayo).

### 4.2 Otros centinelas de D3 que ya están en P20 (para el rasgo `Centinela=D3`)

| Prueba de P20 | Qué fija en D1 | En D3 |
|---|---|---|
| T1-2 #8 `D1_el_sello_de_membresia_aun_no_se_exige` | `SelloMembresia` → «no aplica» | se invierte (D3-S.4) |
| T1-3 #37 `Q9P_el_dominio_sale_de_las_filas_en_D1` | dominio calculado de las filas | se invierte: el dominio sale de los sellos |
| T1-3 #39 `D1_una_fila_de_A_insertada_por_SQL_basta_para_desbloquear` | R-D1D-08 | se invierte: una fila sin sello no basta |
| T1-3 #41 `El_punto_de_extension_MembresiasSelladasPermiten_devuelve_true_en_D1` | punto de extensión en `true` | se invierte |
| T1-4 #30 (`Skip` hasta T1-5) | `sistema` no resucita las globales | se activa en T1-5, no en D3 |
| D1-02.1 | la marca | sección 4.1 |

---

## 5. CS-P2: `NumeroCaso`, `Urgencia` y `CK_BitacoraSeguridad_Caso`

**Diseño (de la hoja de F-2 y del PLAN de #154, no leí la DDL, que será la revisión 3).**
- `NumeroCaso varchar(30) COLLATE Latin1_General_BIN2 NULL`, `Urgencia bit NULL`.
- `CK_BitacoraSeguridad_Caso`: de 6 a 30 caracteres con `DATALENGTH` y alfabeto `[A-Z0-9-]` en `BIN2`.
- `CK_BitacoraSeguridad_IngresoSuper` ampliada con el mismo nombre.
- Índice filtrado `IX_BitacoraSeguridad_Caso (NumeroCaso, Id) WHERE NumeroCaso IS NOT NULL`.
- Comprobación de `definition` para la idempotencia, con su reverso.
- La API pasa el caso a mayúsculas y recorta espacios antes de validarlo.

**Evento de prueba.** Para aislar `CK_Caso` de las demás reglas uso un evento sin otras restricciones: `DERIVA_RELOJ` (`FACTOR`, `Severidad='I'`, `Canal='SISTEMA'`). La restricción es de columna y vale para cualquier evento. `INGRESO_SUPER` solo se usa donde digo.

### 5.1 Casos del alfabeto y los límites

Todas son **SQL** (una base DB-N, fixture compartida), `RestriccionesCasoTests`, dependen de T1-1 (bloque 5 b). «Falla si…» común a las filas de esta tabla: la `CK` no existe, o su patrón o su colación son otros.

| ID | Caso (valor del `INSERT`) | Esperado | Mutación que lo pone en rojo |
|---|---|---|---|
| CP2-01 | **Válidos** (teoría): `ABC123` (6, límite inferior); `AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA` (30, límite superior); `GSF-2026-0001`; `123456`; `A-----` | la fila se guarda | `CK` con `>= 7` o `<= 29`; alfabeto sin dígitos o sin guion |
| CP2-02 | **Cortos** (teoría): `` (vacío, longitud 0), `A`, `ABCDE` (5) | 547 `CK_BitacoraSeguridad_Caso`; sin fila | `CK` con `>= 5` (el 5 pasaría); vacío tratado como NULL |
| CP2-03 | **Largos** (teoría): 31 caracteres, 100 caracteres | **error 2628** (truncamiento de la columna `varchar(30)`) y no 547: la `CK` ni se llega a evaluar; sin fila. *(Inferido: con `ANSI_WARNINGS ON`, que es el valor de SqlClient.)* La prueba acepta 2628 o 547 y exige que **no quede fila** | columna `varchar(31)` con `CK <= 31`: el caso de 31 se guardaría |
| CP2-04 | **Minúsculas y mezcla** (teoría): `abc123`, `Abc123`, `ABC12a`, `gsf-001` | 547 | columna o `CK` sin `COLLATE Latin1_General_BIN2` (con la intercalación CI de las instalaciones `[A-Z]` acepta minúsculas) |
| CP2-05 | **Unicode** (teoría; el literal va como `N'…'` a una columna `varchar`): `N'ÁBC123'`, `N'ABC123Ñ'`, `N'АВС123'` (cirílico А, В, С), `N'中文中文中文'`, `N'ABC😀12'`, `N'ＡＢＣ１２３'` (ancho completo) | no queda ninguna fila cuyo valor almacenado incumpla `^[A-Z0-9-]{6,30}$`. Los que no tienen equivalente en la página de códigos dan 547 (se convierten en `?`). *(Inferido: el ancho completo puede convertirse a ASCII por «best fit» y guardarse como `ABC123`; la prueba lo permite y comprueba el valor almacenado. No es un fallo de la base: lo detiene el validador de C#, CP2-17.)* | `CK` con alfabeto `[A-Za-z0-9-]` o sin la colación |
| CP2-06 | **Nulo.** (a) `NumeroCaso` NULL con `DERIVA_RELOJ` → se guarda. (b) `NumeroCaso` NULL con `INGRESO_SUPER` (motivo válido) → 547 de `CK_IngresoSuper`. (c) `Urgencia = 1` con `NumeroCaso` NULL | (a) sí; (b) 547; (c) **se guarda hoy** (no hay `CK` que las relacione): documenta el diseño y se invierte si B responde Q-V2-01 | `CK_IngresoSuper` sin exigir caso; `CK_Caso` que rechaza NULL (rompería todo evento sin caso) |
| CP2-07 | **Espacios, control y comodines** (teoría): `ABC 123`, ` ABC123`, `ABC123 ` (espacio final), tabulador, `CHAR(13)`, `CHAR(10)`, `CHAR(0)` *(inferido)*, `AB%123`, `AB_123`, `AB[1]23`, `AB^123`, `AB'123`, `AB;123`, `AB\123` | 547 en todos (el alfabeto es una lista cerrada y los comodines de `LIKE` se tratan como datos) | patrón que deja pasar `%` o `_`; `RTRIM` previo que oculta el espacio final |
| CP2-08 | **Equivalente, no se prueba:** cambiar `DATALENGTH` por `LEN` en la `CK`. Con el alfabeto activo no hay valor que los distinga (un espacio final no pasa el alfabeto). Lo anoto para que nadie escriba una prueba que no puede fallar | — | mutante equivalente |

Nota sobre el borde de guiones: `------` (6 guiones) y `--MOTIVO` (8) son válidos para la `CK`. Ver Q-V2-09 y CASO-02.

### 5.2 Idempotencia de `CK_BitacoraSeguridad_Caso` (aplicar dos veces el guion de esquema)

`EsquemaAccesoTests` (amplía P20 T1-1 #14, cuya huella no incluye la definición textual de las `CK` ni el identificador del objeto).

| ID | Prueba | Tipo | Falla si… | Dep. |
|---|---|---|---|---|
| CP2-09 | `Reaplicar_no_cambia_la_definicion_de_CK_Caso` (**PLAN**). Aplicar `AccesoDdl` completo **dos veces más** (tres en total). Se toma antes y después: `object_id` y `definition` (resumen) de `CK_BitacoraSeguridad_Caso` y de `CK_BitacoraSeguridad_IngresoSuper`, `is_disabled`, `is_not_trusted`, y `index_id`/`filter_definition` del índice. Todo igual | SQL | el guion borra y vuelve a crear la restricción en cada pasada (`object_id` nuevo; además, lento y con bloqueo sobre `BitacoraSeguridad`, la tabla más grande); o duplica la `CK` con otro nombre | T1-1 |
| CP2-10 | `Una_CK_Caso_alterada_se_restituye_al_reaplicar`. Se reemplaza por una versión débil con el **mismo nombre** (`>= 1`, sin colación) y se reaplica: la definición vuelve a la original. Variante: se elimina la `CK` y se reaplica: reaparece, `is_not_trusted = 0` | SQL | la idempotencia es solo `IF NOT EXISTS (nombre)` y no compara la definición (para eso existe la «comprobación de `definition`» que pide el PLAN); o la restituye `WITH NOCHECK` | CP2-09 |
| CP2-11 | `Una_base_en_la_version_5_sube_con_caso_y_urgencia_en_NULL` (DB-5 con historia, como P20 T1-1 #15). Ninguna fila perdida; `NumeroCaso` y `Urgencia` **NULL en todas** (no `0`); `CK_Caso` de confianza (`is_not_trusted = 0`); la purga sigue igual | SQL | `Urgencia bit NOT NULL DEFAULT 0` (cambia el significado de «no aplica»); `CK` agregada `WITH NOCHECK` | T1-1 |
| CP2-12 | `Una_base_de_la_revision_2_sube_a_la_3_aunque_tenga_INGRESO_SUPER_sin_caso`. En **DB-6r2** se inserta un `INGRESO_SUPER` con motivo y sin caso (válido con la `CK` anterior) y se aplica la revisión 3. **Qué pasa con esa fila es decisión de B (Q-V2-02)**: (a) la `CK` ampliada se agrega `WITH NOCHECK` y la fila queda (la `CK` queda `is_not_trusted = 1`); (b) el guion rellena un valor reservado; (c) el guion falla con un mensaje claro. La prueba se escribe contra la respuesta | SQL | el guion falla con 547 sin mensaje (la ampliación con la misma denominación obliga a borrar y recrear la `CK`, y la recreación con `WITH CHECK` choca con la fila vieja) | Q-V2-02. Hoy **no existe** ninguna base así si T1-1 no se unió; es condicional a que alguien haya armado un DEMO desde la rama |
| CP2-13 | `El_indice_filtrado_es_el_del_diseno_y_es_idempotente` (`IX_BitacoraSeguridad_Caso`, claves `(NumeroCaso, Id)`, `filter_definition` = `([NumeroCaso] IS NOT NULL)`; tres pasadas, mismo `index_id`) | SQL | índice sin filtro (crece con todas las filas); `Id` primero; recreado en cada pasada | T1-1 |
| CP2-14 | `La_busqueda_por_caso_con_parametro_varchar_usa_el_indice_y_con_nvarchar_se_documenta` (`SET STATISTICS XML ON`: con `@caso varchar(30)`, `Index Seek` sobre `IX_BitacoraSeguridad_Caso`; con `nvarchar` se **caracteriza** lo que ocurre, *inferido*: conversión implícita de la columna y recorrido) | SQL | el índice no se usa; o la consulta de CS-05 usará `nvarchar` por costumbre (ADR-50) | T1-1; la consulta real es de CS-05 |
| CP2-15 | `Los_modulos_que_escriben_en_la_bitacora_tienen_QUOTED_IDENTIFIER_ON` (`sys.sql_modules.uses_quoted_identifier = 1` para `PurgarBitacoraSeguridad` y los disparadores de la bitácora y de las membresías). *(Inferido: un índice filtrado exige `QUOTED_IDENTIFIER ON` en toda sentencia que escriba la tabla; un módulo creado con `OFF`, por ejemplo aplicando el guion con `sqlcmd` sin `-I`, daría el error 1934 en la purga.)* | SQL | alguien aplica el guion a mano con `sqlcmd` y la purga nocturna falla con 1934 | T1-1 |
| CP2-16 | `El_reverso_quita_CK_Caso_e_indice_y_reaplicar_los_restituye` (ciclo aplicar, reverso, aplicar). Qué hace el reverso con **las columnas** lo decide B (Q-V2-02b); P20 T1-1 #74 las conservaba. La prueba afirma lo que B responda | SQL | el reverso deja la `CK` y la v5 de la API escribe sin saberlo (no la puede violar: no conoce la columna); o el reverso borra las columnas y pierde los casos de bitácora | T1-1; Q-V2-02b |

### 5.3 Validador de C# (normalización) y paridad con la `CK`

Dependen de dónde viva el validador (Q-V2-13). Supongo un tipo `Caso` en `GPOS.Contracts` con `TryParse(string?, out string normalizado)`; el nombre lo fija quien lo escriba.

| ID | Prueba | Tipo | Falla si… |
|---|---|---|---|
| CP2-17 | `CasoTests.Normaliza_y_valida` (teoría). Normalización: ` gsf-123 ` → `GSF-123` (recorta, mayúsculas); `gsf 123` (espacio interno) → rechazo. Longitud **después** de normalizar: 5 → no; 6 → sí; 30 → sí; 31 → **no (no se trunca)**. Entradas nulas: `null`, ``, `   ` → no. **Solo ASCII**: `١٢٣٤٥٦` (dígitos arábigo-índicos, que `\d` y `char.IsDigit` aceptan), `ＡＢＣ１２３`, `АВС123`, `ÁBC123`, `ABC123\u0301` (acento combinado) → no. Con `CurrentCulture = tr-TR`: `info-123` → `INFO-123` (no `İNFO-123`). `ı` (i sin punto) y `ß` → rechazo. 10 000 caracteres → rechazo en tiempo acotado. Caracteres de control incluidos `\u001b` → no | TX | se usa `\d` o `char.IsLetterOrDigit` (acepta Unicode); `ToUpper()` sin cultura invariante; se valida **después** de truncar a 30 (el 31 pasaría); la expresión regular es vulnerable a retroceso. Dependencia: ICU con `tr-TR` disponible en el equipo de pruebas *(no verificado)* |
| CP2-18 | `CasoTests.El_alfabeto_de_C_sharp_y_el_de_la_CK_coinciden` (**diferencial**): para cada carácter `c` de `U+0000` a `U+00FF` se arma `"AAAAA" + c` ya normalizado; se compara «lo acepta el validador» con «lo acepta el `INSERT` en la base». Deben coincidir en los 256. Un segundo bucle con las longitudes 0 a 40 de `A` | SQL + TX | alguien cambia el alfabeto en un solo sitio (la causa más probable de un error de producción tardío) |
| CP2-19 | `CasoTests.Los_parametros_de_caso_viajan_como_varchar_30_y_bit` (`ComandosSql` con `Size`; P20 2.3): `@caso varchar(30)`, `@urgencia bit` en `RegistrarEvento` | SQL | el parámetro es `nvarchar` (conversión implícita, ADR-50) o tiene `Size` mayor |
| CP2-20 | **Traspaso a CS-1, no es de D1:** `LoginSuperHttpTests.Un_caso_de_31_caracteres_responde_400_y_no_se_guarda_truncado`. Lo anoto porque el `SqlParameter` con `Size = 30` truncaría en silencio. Lo escribe B con CS-1 | HTTP | el validador queda detrás del truncamiento |

---

## 6. `--caso` en `GPOS.Migracion accesos --convertir`

**Lo que dice el PLAN de #154 (F-2, firmada el 2026-10-22):** `accesos --convertir` **exige** `--caso`, con `--urgencia` opcional; igual que `aprovisionar --llave-firma --sin-tpm` en T2-0. Prueba de A y de B: `ConversionAccesosTests.Sin_caso_se_detiene`. Lo demás (formato, normalización, dónde queda) no lo dice el PLAN: lo deduzco de CS-P2 y de F-1/F-2 y lo pregunto.

| ID | Prueba | Tipo | Falla si… | Dep. |
|---|---|---|---|---|
| CASO-01 | `ConversionAccesosTests.Sin_caso_se_detiene` (**PLAN**). Sin `--caso`: salida distinta de 0, el mensaje nombra `--caso`, **ninguna conexión a la base** (interceptor), `CHECKSUM_AGG` igual, sin marca. Se repite con `--instalacion-demo` y con el modo mínimo | SQL | `--caso` es opcional, o se pide tras abrir la conexión y tomar el `TABLOCKX` | T1-4; Q-V2-14 (código de salida) |
| CASO-02 | `ConversionAccesosTests.Un_caso_con_formato_invalido_se_rechaza_antes_de_conectar` (teoría): 5 y 31 caracteres, vacío, solo espacios, `ABC 123`, unicode, `abc123` (según Q-V2-15, ver CASO-03), `--caso=ABC123` (sintaxis con `=` válida si el analizador la admite), `--caso` repetido con dos valores, **`--caso --motivo texto` (falta el valor: el analizador no debe tomar `--motivo` como valor)**, `--caso` como último argumento | TX | el analizador toma el siguiente token sin mirar si es otra opción: `--MOTIVO` pasa el alfabeto (guiones) y el motivo queda sin valor (**H-13**); o se valida después de abrir la base | T1-4; Q-V2-09 |
| CASO-03 | `ConversionAccesosTests.El_caso_se_normaliza_igual_que_en_la_API` (` gsf-123 ` → `GSF-123`). **Condicional a Q-V2-15**: si B decide que la herramienta solo acepta mayúsculas, la prueba pasa a «`gsf-123` se rechaza» | TX | la CLI y la API normalizan distinto (la misma frase da dos casos distintos en la bitácora) | Q-V2-15 |
| CASO-04 | `ConversionAccesosTests.El_verbo_usa_el_mismo_validador_que_la_API` (ARQ: el patrón `[A-Z0-9-]` y los límites 6 y 30 aparecen **una vez** en `src/` fuera de la DDL; la CLI y la API llaman a ese tipo) | ARQ | se copia la expresión regular (diverge con el tiempo) | CP2-17 |
| CASO-05 | `ConversionAccesosTests.El_caso_queda_en_BitacoraSeguridad` (con `--caso gsf-0042`): el evento global `ACCESOS_CONVERTIDOS_INSTALACION` (`SISTEMA`) lleva `NumeroCaso = 'GSF-0042'`; **los eventos por empresa `ACCESOS_CONVERTIDOS` (`MEMBRESIA`) también** (supuesto, Q-V2-16); en la misma transacción: si se fuerza 51621, no quedan filas de éxito ni de caso | SQL | el caso se guarda en `Detalle` en vez de en su columna; solo en el evento global; o fuera de la transacción | CP2-01; Q-V2-16 |
| CASO-06 | `ConversionAccesosTests.Urgencia_se_guarda_como_1_con_la_bandera_y_como_0_sin_ella` (y `--urgencia` sin `--caso` → error). Valor de `Urgencia` sin la bandera: `0` o NULL según Q-V2-17 | SQL | `Urgencia` queda NULL cuando B espera 0 (o al revés); `--urgencia` solo se acepta con `--caso`, pero la prueba no lo exige | Q-V2-17 |
| CASO-07 | `ConversionAccesosTests.Una_conversion_que_falla_deja_traza_con_el_caso_fuera_de_la_transaccion` (SD0-07: «rutas de fallo sin reversión»). Se fuerza 51621: el evento de fallo, escrito aparte, lleva el mismo caso | SQL | el intento fallido no se puede ligar al caso del técnico. **Condicional a Q-V2-16** (¿existe evento de fallo para este verbo?) | Q-V2-16 |
| CASO-08 | `ConversionAccesosTests.La_salida_de_consola_no_contiene_datos_sensibles_ni_ecos_peligrosos`. Se captura `stdout`, `stderr` y el `ILogger` en: éxito, 51621, 51622 y caso inválido. (i) Ninguna de las salidas contiene centinelas: un hash de contraseña sembrado, `Password=`, la cadena de conexión, un token, la clave temporal de un ADMIN convertido. (ii) El caso aparece como mucho en el resumen final. (iii) El valor inválido de `--caso` y de `--motivo` **no se repite sin escapar**: una entrada con `\u001b[31m` o con salto de línea no produce `\u001b` ni una línea falsa en la salida | SQL + TX | el mensaje de error repite la entrada tal cual (falsificación de líneas en el registro); algún camino imprime el objeto de la fila con `ToString()` (el patrón TN-09 que A cita en D1-11) | T1-4; sigue el centinela de D1-11 |
| CASO-09 | `ConversionAccesosTests.El_registro_va_por_ILogger_con_el_caso_como_propiedad_y_no_por_EventLog` (el `EventId` `ConversionAccesos` lleva `Caso` y `Urgencia` como propiedades del estado; ya existe la regla de no usar `EventLog.WriteEntry` directo, ADR-129 B.4, P20 T1-4 #29) | TX | el caso se concatena en el texto y no se puede filtrar | T1-4 |
| CASO-10 | `MigracionArquitecturaTests.Todo_verbo_que_pide_motivo_exige_caso` (ARQ, **F-2 completo**): enumera los verbos de `GPOS.Migracion` y falla si alguno declara `--motivo` y no `--caso`. Hoy B nombra `sistema --confirmar-sellado`, `sellos --legitimar/--purgar/--resellar`, `empresa --cambiar-rnc`, `anillo --*`, `restablecer-factor`, `accesos --convertir` y `aprovisionar ... --sin-tpm` | ARQ | un verbo nuevo (o uno de la lista) pide motivo y se olvida del caso. La lista cerrada de F-1 tiene su prueba hermana para la API; ésta es la de la herramienta | T1-4 para su verbo; el resto de los verbos son de CS-1 y T2-0 |
| CASO-11 | `ConversionAccesosTests.Los_modos_auxiliares_piden_caso_segun_la_decision` (`--solo-reglas`, la vista previa, `--completar-sellos` en D3) | SQL | se exige el caso donde B no quiere (frena la reparación de una empresa pendiente) o se omite donde sí | Q-V2-14b |

---

## 7. Pruebas de P20 que dejan de ser válidas o cambian

(El cuadro completo con IDs está en la sección 8; aquí el porqué de las tres más peligrosas.)

1. **P20 T1-1 #25** afirma «ningún otro índice nuevo». Con `IX_BitacoraSeguridad_Caso` **falla por una causa correcta** pero una lectura apresurada la «arreglaría» quitando la aserción. Debe pasar a una lista cerrada que incluya el índice nuevo y su `filter_definition`.
2. **P20 T1-1 #55** (teoría de `CHECK` de la bitácora) fija «`INGRESO_SUPER` con 10 caracteres de motivo → válido». Con la `CK` ampliada ese caso exige además un caso válido; si no se cambia, falla por 547 y parece un defecto de producción.
3. **P20 T1-4** completa: sin el ayudante de la sección 2.4 las 30 pruebas fallan al invocar el verbo sin `--caso`; sin la confirmación de DEMO (D1-03) fallan todas las de ESC-DEMO en modo DEMO. No son defectos: son consecuencias de F-2 y de D1-03.

---

## 8. Cuadro: mi plan del 20-oct → qué cambia

| ID en P20 | Qué decía | Qué cambia | Por qué | Pruebas nuevas relacionadas |
|---|---|---|---|---|
| T1-1 #14 `Reaplicar_la_version_6_no_cambia_nada` | huella de tablas, disparadores, permisos | la huella agrega `definition`, `object_id`, `is_not_trusted` e `index_id/filter_definition` de las dos `CK` y del índice de caso | CS-P2; la huella de P20 no veía la definición textual | CP2-09, CP2-10, CP2-13 |
| T1-1 #15 `Una_base_en_la_version_5_sube_a_la_6` | historia con eventos fuera del catálogo | agrega `NumeroCaso` y `Urgencia` en NULL (no `0`) en las filas existentes | CS-P2 | CP2-11 |
| T1-1 #21 matriz de tipos (Anexo A) | columnas nuevas de `BitacoraSeguridad` | suma `NumeroCaso varchar(30) NULL` con colación `BIN2` y `Urgencia bit NULL` | CS-P2 | CP2-19 |
| T1-1 #25 índices | «ningún otro índice nuevo» | lista cerrada + `IX_BitacoraSeguridad_Caso` filtrado | CS-P2 | CP2-13 |
| T1-1 #26 `CHECK` y `DEFAULT` | nombres y definiciones | suma `CK_BitacoraSeguridad_Caso` y la nueva definición de `CK_BitacoraSeguridad_IngresoSuper`; `Urgencia` sin `DEFAULT` | CS-P2 | CP2-01 a CP2-07 |
| T1-1 #30 a #33 (51619) | clave, versión, estado, origen | **#33** se reduce a `Origen`, `FechaAlta`, `UsuarioAlta`; la clave pasa a D1-06.1. #30 a #32 sin cambio | D1-06 | D1-06.1 a D1-06.5 |
| T1-1 #35 `Un_UPDATE_sin_cambio_de_valor_no_da_error` | `SET Nivel = Nivel` sin error | **sin cambio** para las columnas que no son clave. Excepción documentada: `SET EmpresaCodigo = EmpresaCodigo` **sí** da 51619 | D1-06 (`UPDATE()` mira el `SET`, no los valores) | D1-06.2 |
| T1-1 #36 atomicidad multi-fila | una fila inválida no cambia ninguna | sin cambio; D1-06.1 (iii) y (iv) son la versión multi-fila de la clave | D1-06 | D1-06.1 |
| T1-1 #37 `UPDATE` de cero filas | `WHERE 1=0` en las cinco tablas | agrega `SET EmpresaCodigo = ... WHERE 1=0` en `UsuariosEmpresas` | D1-06 | D1-06.3 |
| T1-1 #55 `CHECK` de bitácora | `INGRESO_SUPER` con 10 caracteres de motivo → válido | exige también caso válido; agregar casos «sin caso → 547» | CS-P2 | CP2-06 |
| T1-1 #74 reverso | quita tablas, disparadores, `CK` e índice; conserva columnas | quita también `CK_Caso` e `IX_Caso`; destino de las columnas por Q-V2-02b | CS-P2 («con su reverso») | CP2-16 |
| T1-1 #75 reverso se detiene con 51622 | con membresías o `Accesos.Modelo` | el valor de la marca puede ser `MEMBRESIA.v1-sin-sello` | D1-02 (a) | D1-02.7 |
| T1-1 Anexo B (mutantes) | M1 a M14 | **nuevos M15 a M20**, sección 9 | las condiciones | — |
| T1-2 #8 `D1_el_sello_de_membresia_aun_no_se_exige` | sello «no aplica» | se marca `Centinela=D3`; refinada para la marca sin sello | D1-02 | D1-02.8, D3-S.4 |
| T1-2 #10 teoría Q1 (cuenta o empresa inexistente) | fila con `Empresa` NULL | agrega «el lector tolera NULL en todas las columnas» y los tres niveles | D1-05 | D1-05.3, D1-05.5 |
| T1-2 #16 reintento ante 1205 | segundo 1205 → `ACCESO_NO_DISPONIBLE` | sin cambio; D1-05.6 agrega las demás excepciones | D1-05 | D1-05.6 |
| T1-2 #20 a #26 (`PermisosEmpresaTests`) | versión por perfil, siembra, concurrencia | #21 y #22 pasan a ser **dos de los ocho caminos** de D1-04.3; la #26 (dos hilos) aplica a cada camino | D1-04 | D1-04.1 a D1-04.6 |
| T1-2 #27 a #34 (`BitacoraAccesoTests`) | eventos y reglas de datos | #33 agrega «`INGRESO_SUPER` sin caso → regla de C#, no 547»; #34 agrega `@caso varchar(30)` y `@urgencia bit` | CS-P2 | CP2-19 |
| T1-3 (22 pruebas HTTP de 7.3 y las de `SuperCuentasHttpTests`) | `ApiMvpFactory` sin marca | la fixture siembra `Accesos.Modelo`; ninguna prueba se escribe de nuevo | D1-01 (503 sin marca) | D1-01.1 a D1-01.5; sección 2.3 |
| T1-3 #53 `Guardar_privilegios_sobre_una_membresia_en_BAJA...` | condicional a P-2 | sin cambio. Con D1-01, además, la ruta responde 503 si no hay marca; el orden 503/404 lo fija Q-V2-04 | D1-01 | D1-01.3 |
| T1-3 #37, #39, #41 | `D1_*` | `Centinela=D3` | D1-02 | sección 4.2 |
| T1-4 todas | invocar el verbo | el ayudante añade `--caso` por omisión; el modo DEMO añade la confirmación y la licencia de ensayo | F-2, D1-03 | sección 2.4 |
| T1-4 #2 `Q23_sin_diferencias_en_el_DEMO` | modos `D` y `M` | el modo `D` necesita licencia de Desarrollo o Demostración y la confirmación | D1-03 | D1-03.1 a D1-03.6 |
| T1-4 #6 `Una_segunda_ejecucion_informa_ya_convertido` | marca `MEMBRESIA.v1` | acepta también `MEMBRESIA.v1-sin-sello` (rama (a)) y gana sobre la precondición 10 | D1-02, D1-01 | D1-02.6, D1-01.8 |
| T1-4 #8 precondiciones 3, 4, 6, 7 | cuatro precondiciones | suma la 10 (membresías previas) | D1-01 | D1-01.6 |
| T1-4 #5 fallos por paso | pasos 2, 3, 3 b, 5, 8, 9 | suma «guardar padrón v1» (rama (a)) | D1-02 | D1-02.3 |
| T1-4 #29 `Registra_ACCESOS_CONVERTIDOS...` | `Empresa`, retención 5, marca al final | suma `NumeroCaso` y `Urgencia`; el valor de la marca | F-2, D1-02 | CASO-05, D1-02.1 |
| T1-4 #30 `Skip` hasta T1-5 | sin cambio | sin cambio | — | — |
| P20 sección 9 (orden) | por tarea | suma pasos (sección 9 de este documento) | — | — |
| P20 sección 12 (preguntas P-1 a P-9) | nueve preguntas | **siguen abiertas**: no recibí respuestas; las nuevas son Q-V2-01 a Q-V2-17 | — | — |

**Totales.** 19 filas del cuadro cambian una prueba de P20 (las filas con «sin cambio» no cuentan). P20 pasa de 205 a unas 275 pruebas nuevas (+ unas 70) y de 13 a unas 32 pruebas existentes adaptadas (+ 19).

---

## 9. Orden de construcción (por PR), esfuerzo y mutantes

### 9.1 Orden

El orden de P20 se mantiene; esta versión **inserta** lo siguiente.

| PR | Antes de construir (en rojo) | Después |
|---|---|---|
| **T1-1** | 1. Pruebas sin base: CP2-17 (validador; si el tipo vive en `GPOS.Contracts`, sale en segundos). 2. D1-04.2 (escáner, «prueba de la prueba») y D1-06.4 (ARQ). 3. **D1-06.1, .3, .5** contra el texto viejo del disparador: deben fallar (.1 (iii), (iv) y (v), .2). 4. CP2-01 a CP2-07 con la `CK` aún sin escribir (V5). 5. Después de construir: CP2-09, CP2-10, CP2-13 a CP2-16, CP2-11, CP2-18, D1-04.5. | CP2-12 solo si B responde Q-V2-02 y existe una base de la revisión 2 |
| **T1-2** | D1-05.1 y .2 (matriz pura) **primero**: no necesitan base y fijan la lista blanca antes de escribir el evaluador. Luego D1-05.3 a .6, D1-04.3 a .6 y D1-04.1 (ARQ al final, cuando todos los caminos ya existen) | — |
| **T1-3** | Fixture 2.3 y D1-01.1 a D1-01.5 **antes de escribir cualquier ruta** (la compuerta nace con la primera) | las HTTP de P20 7.3 una vez sembrada la marca |
| **T1-4** | Ayudante 2.4; D1-01.6 a .8; D1-03.1 a .8 (primero 3.1 y 3.2, el par); CASO-01 a CASO-04 (analizador, sin base); D1-02.x según P-D1-06; CASO-05 a CASO-11 | D3-S.x (sección 4.1) quedan como lista de trabajo de D3 |

### 9.2 Mutantes nuevos (se agregan al Anexo B de P20)

| M | Sabotaje | Lo debe romper |
|---|---|---|
| M15 | Disparador 51619 con la comparación `inserted`/`deleted` en lugar de `UPDATE()` | D1-06.1 (iii), (iv), D1-06.2 |
| M16 | `CK_BitacoraSeguridad_Caso` sin `COLLATE Latin1_General_BIN2` | CP2-04, CP2-18 |
| M17 | Guion de esquema que borra y recrea `CK_Caso` en cada pasada | CP2-09 (`object_id`) |
| M18 | Guion de esquema con `IF NOT EXISTS (nombre)` sin comparar la definición | CP2-10 |
| M19 | Evaluador con `if (nivel == SUPER) return true` antes de mirar la empresa | D1-05.1, D1-05.3 |
| M20 | Una ruta de T1-3 sin compuerta; compuerta que cachea la marca | D1-01.1 (ruta generada), D1-01.5 |

### 9.3 Esfuerzo (inferido, ±40 %)

| Bloque | Pruebas | Días-persona |
|---|---|---|
| D1-01 | 8 | 0,35 |
| D1-02 (una rama) | 8 (a) o 4 (b) | 0,25 |
| D1-03 | 8 | 0,3 |
| D1-04 | 6 | 0,35 (el escáner y los 8 caminos pesan más que el resto) |
| D1-05 | 6 | 0,2 |
| D1-06 | 5 | 0,15 |
| CS-P2 (SQL, índice, idempotencia, validador, diferencial) | 20 (CP2-08 no cuenta; CP2-20 es de CS-1) | 0,6 |
| `--caso` | 11 | 0,3 |
| Adaptar las pruebas existentes (sección 8) | 19 | 0,25 |
| **Total** | ≈ 70 nuevas | **≈ 2,0 dp (1,5 a 2,8)** |

Es esfuerzo de **pruebas** y se suma al de P20; no incluye la construcción de la condición. A estima la construcción de las seis condiciones en unos 1,8 dp; en conjunto, las pruebas cuestan algo más que el código que vigilan, y es razonable porque cuatro de las seis son de seguridad (escribir en vacío sale caro). Sin costo de infraestructura.

---

## 10. Hallazgo nuevo de QA (H-13)

| # | Sev. | Hallazgo | Evidencia | Qué hace este plan |
|---|---|---|---|---|
| H-13 | Media | El alfabeto `[A-Z0-9-]` acepta casos sin ningún carácter alfanumérico (`------`) y cualquier opción de la línea de comandos (`--MOTIVO`, `--URGENCIA`) escrita en mayúsculas o minúsculas. Un analizador que toma «el siguiente token» como valor de `--caso` guardaría `--MOTIVO` como número de caso y dejaría `--motivo` sin valor. El caso es el campo con el que se rastrea una orden del soporte: un caso vacío de contenido anula su función | hoja de firma, CS-P2 (alfabeto) y el patrón de la `CK`; el analizador de `GPOS.Migracion` **no lo leí** | CASO-02 (rechazo del valor-opción) y Q-V2-09 (¿exigir al menos una letra o un dígito y que no empiece por guion?). Hoy la `CK` los admite y CP2-01 documenta `A-----` como válido |

---

## 11. Preguntas para B

Las que detienen una prueba concreta. «Supuesto» = lo que este plan asume si B no contesta.

| # | Pregunta | Detiene | Supuesto |
|---|---|---|---|
| Q-V2-01 | CS-P2: ¿hay `CK` que relacione `Urgencia` y `NumeroCaso` (p. ej. `Urgencia IS NOT NULL → NumeroCaso IS NOT NULL`)? ¿Qué eventos exigen caso en SQL: solo `INGRESO_SUPER` o también los de `CAMBIO_RNC`, `CUENTA_RESTABLECIDA`, etc.? | CP2-06 | `INGRESO_SUPER` exige caso; ninguna `CK` relaciona las dos columnas |
| Q-V2-02 | Al ampliar `CK_BitacoraSeguridad_IngresoSuper` con el mismo nombre en una base de la revisión 2 con filas `INGRESO_SUPER` sin caso: ¿`NOCHECK`, relleno o fallo? Y (b): ¿qué hace el reverso con las columnas `NumeroCaso`/`Urgencia`? | CP2-12, CP2-16 | solo existen bases de rev. 2 si alguien armó un DEMO; el reverso conserva las columnas |
| Q-V2-03 | D1-02 (a): ¿dónde se guarda el padrón v1 de la conversión (tabla nueva, archivo, `Configuracion`)? ¿lo puede escribir `gpos_api`? | D1-02.2, D1-02.3 | tabla del sistema que `gpos_api` no puede escribir |
| Q-V2-04 | D1-01: ¿el 503 va **después** de la autenticación y la autorización (un anónimo recibe 401)? | D1-01.3 | sí |
| Q-V2-05 | D1-01: ¿la marca `Accesos.Modelo` se lee en cada petición o se cachea (cuántos segundos)? | D1-01.5 | cada petición |
| Q-V2-06 | D1-03: ¿qué hace el verbo con una base sin licencia o con licencia ilegible (bases de ensayo)? Falla cerrado, o se permite en `Debug` | D1-03.3 | falla cerrado salvo Desarrollo/Demostración explícitos |
| Q-V2-07 | D1-03: la confirmación «el número de empresas»: ¿las **habilitadas** o todas? ¿`demo` en minúsculas vale? | D1-03.5 | habilitadas; sin distinguir mayúsculas |
| Q-V2-08 | D1-03: ¿hay un argumento para automatizar la confirmación en un script (p. ej. `--confirmar DEMO`)? Sin él, ninguna prueba de DEMO de T1-4 puede ejecutarse desde `dotnet test` salvo con entrada simulada | D1-03.6 y todas las pruebas de T1-4 en modo DEMO | entrada estándar simulada; sin argumento |
| Q-V2-09 | H-13: ¿el caso debe contener al menos un carácter alfanumérico y no empezar por guion? | CP2-01, CASO-02 | sí; ajusta la `CK` y el validador |
| Q-V2-10 | D1-04: ¿cuál es la lista de permitidos del escritor único (método, paso 3 de la conversión, siembra) y cuáles son los caminos reales? | D1-04.1, D1-04.3 | los ocho de D1-04.3; permitidos: el método único y el paso 3 |
| Q-V2-11 | D1-04.6: ¿existe hoy una ruta que elimine un reporte y deba limpiar `rpt:{id}`? | D1-04.6 | no la verifiqué; se omite si no existe |
| Q-V2-12 | D1-05: ADR-35 (no lo leí): ¿el SUPER entra a una empresa **inhabilitada**? ¿Distingue mayúsculas el evaluador (`admin`)? | D1-05.1, D1-05.2, D1-05.4 | el SUPER no entra a empresa inexistente; inhabilitada, a confirmar; comparación ordinal exacta |
| Q-V2-13 | ¿Dónde vive el validador del caso (`GPOS.Contracts`)? Si vive en `GPOS.Migracion`, la API no puede usarlo | CP2-17, CASO-04 | `GPOS.Contracts`, un solo tipo |
| Q-V2-14 | `--caso`: ¿el código de salida de un `--caso` ausente o inválido es distinto del de las precondiciones (51622)? (b) ¿`--solo-reglas`, la vista previa y `--completar-sellos` piden caso? | CASO-01, CASO-11 | argumento inválido ≠ 51622; el caso solo en las que modifican |
| Q-V2-15 | La CLI: ¿acepta minúsculas y las pasa a mayúsculas (como la API), o exige mayúsculas? | CASO-03 | normaliza igual que la API |
| Q-V2-16 | ¿El caso va en el evento global y en **los de cada empresa**? ¿Existe un evento de fallo escrito fuera de la transacción? | CASO-05, CASO-07 | en todos los eventos del verbo |
| Q-V2-17 | `Urgencia` sin la bandera: ¿`0` o NULL? | CASO-06 | `0` en los eventos que exigen caso; NULL en los demás |

**Aún abiertas desde P20:** P-1 a P-9 (reverso, `ULTIMO_ADMIN` en la ruta del SUPER, 4733 en Release, reintento ante 1205, `BIN2` en los `CHECK` de nivel, lista de eventos, gancho de pruebas del verbo, guardar sin cambios). No las repito.

**D1-07 a D1-15 de A no están en este plan.** El PLAN de #154 solo incorpora D1-01 a D1-06; D1-07 a D1-10 son condiciones de T1-3 («Baja») y D1-11, D1-12 y D1-15 de T1-2/T1-4. Si B quiere que las cubra, serían una versión 3 de unas 25 pruebas.

---

## 12. Qué no verifiqué

- **No se compiló, no se ejecutó nada y no se programó.** Ninguna afirmación «falla hoy» se comprobó.
- **No leí el PLAN de #154 completo**, solo el diff (29 líneas añadidas). Tampoco leí comentarios ni revisiones del PR en GitHub.
- **No leí la DDL de D1** (`docs/datos/2026-10-19-db7-d1-ddl-y-consultas.md`): la revisión 3 con el bloque 5 b aún no existe. El diseño de CS-P2 lo tomé de la hoja de firma y del PLAN. **No sé** el texto exacto de `CK_BitacoraSeguridad_Caso` ni de la `CK_IngresoSuper` ampliada.
- **No leí el código de `feature/modelo-ng`.** Las citas de código de P20 (20-oct) no se revisaron contra el HEAD de hoy. No sé cómo analiza los argumentos `GPOS.Migracion` (si usa `System.CommandLine` u otro), ni cómo lee la licencia el verbo, ni si hay una ruta que elimine un reporte.
- **No leí ADR-35, ADR-83 ni RSW-D1**; las referencias a ellos son las de A y de P20.
- Del ADR-92 solo leí las líneas que citan CS-P2 (por búsqueda) y la hoja de firma hasta F-5; **no leí F-6 a F-9 completas más allá de la tabla** ni los «Puntos abiertos» fuera de lo que cito.
- **Comportamientos de SQL Server y .NET inferidos, no ejecutados:** error 2628 al insertar 31 caracteres en `varchar(30)`; truncamiento silencioso de un `SqlParameter` con `Size`; `UPDATE()` verdadero cuando la columna está en el `SET` aunque el valor no cambie; disparador `AFTER` que se ejecuta con cero filas; el error 1934 por `QUOTED_IDENTIFIER OFF` en módulos que escriben una tabla con índice filtrado; «best fit» de `nvarchar` a `varchar` para caracteres de ancho completo; `ToUpperInvariant` y la cultura `tr-TR` (y si el equipo de pruebas tiene ICU); si la FK compuesta se evalúa antes que el disparador `AFTER`.
- **No verifiqué** que el equipo de pruebas tenga la intercalación CI (`SQL_Latin1_General_CP1_CI_AS`) que presupongo en CP2-04.
- D1-07 a D1-15 y las revisiones de la semana (#152, deuda ADR-90) no entran aquí.

---

### Cierre
- Estado: Completado
- Artefactos: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\C\2026-10-22-plan-pruebas-db7-d1-v2.md`
- Supuestos: (1) la rama (a) de P-D1-06 es la que se construye; la (b) queda escrita aparte; (2) el validador del caso es un tipo único compartido por API y herramienta; (3) los premisas de SQL Server y .NET de la sección 12 son inferidas; (4) el PLAN de #154 incorpora D1-01 a D1-06 como dice su diff; (5) las preguntas Q-V2-01 a Q-V2-17 tienen el «supuesto» indicado hasta que B responda.
- Decisiones candidatas a ADR: Ninguna. (H-13 y Q-V2-09 son una precisión de CS-P2 a firmar, no un ADR nuevo.)
- Entregas a otros agentes: B → responder Q-V2-01 a Q-V2-17 (Q-V2-02, Q-V2-03, Q-V2-08 y Q-V2-09 antes de escribir la DDL rev. 3); B → decidir P-D1-06 para saber qué rama de D1-02 se construye; arquitecto-datos → H-13/Q-V2-09 (¿al menos una letra o un dígito?) y el destino de las columnas en el reverso; desarrollador-backend (T1-5) → el mapeo HTTP del 503 y la compuerta quedan fuera de D1-05.6 y D1-01.x; B (CS-1) → CP2-20; A → revisar CP2-05 y CASO-08 por si falta algún caso de seguridad.
- Próximo paso recomendado: que B conteste Q-V2-02, 03, 08 y 09 y P-D1-06 antes del 2-nov, y que el desarrollador de T1-1 empiece por las pruebas sin base (CP2-17, D1-04.2, D1-06.1 a .3) para verlas en rojo.
