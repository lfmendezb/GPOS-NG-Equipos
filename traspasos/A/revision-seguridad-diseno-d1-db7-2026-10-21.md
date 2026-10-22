# Revisión de seguridad del diseño de D1 de DB-7 (T1-1 a T1-4)

- **Fecha:** 2026-10-21 · **Revisor:** auditor-seguridad (equipo A) · **Encargo:** B, `avisos/B-a-A/2026-10-21-tareas-nuevas-para-a.md`, Tarea 3 (parte de diseño, solo lectura)
- **Modo:** solo lectura. No se modificó código ni documentos del repositorio, no se cambió de rama y no se compiló ni ejecutó nada.
- **Fuentes:**
  - `origin/master`: `docs/arquitectura/2026-10-19-db7-d1-plan-de-trabajo.md` (**PLAN**), `docs/datos/2026-10-19-db7-d1-ddl-y-consultas.md`, revisión 2 del 2026-10-20 (**DAT**); como contexto, `docs/datos/2026-10-18-db7-d0-modelo-datos.md` (**D0**), `docs/seguridad/2026-10-18-db7-d0-revision-seguridad.md` (**SEG-D0**) y `docs/arquitectura/2026-10-20-db7-d1-respuestas-arquitecto-software.md` (**RSW**).
  - Código existente que el diseño reutiliza: `origin/feature/modelo-ng` `e3e729c1` (2026-10-21 17:18).
- **Convención de evidencia:** [V] verificado en `archivo:línea`. En los documentos, la línea es la de `git show origin/master:<ruta>`. [I] es inferido o queda pendiente de comprobar en el PR.
- **Alcance:** es una revisión del diseño. No existe todavía código de D1 (PLAN:13 [V]). Los hallazgos SD0-01 a SD0-18 de SEG-D0 no se repiten: SEG-D0 los da por cerrados o bien resueltos (SEG-D0:485-495 [V]). Aquí solo se trata lo nuevo de D1 o lo que D1 concreta.

## 1. Alcance y superficie revisada

| Superficie | Tarea | Exposición |
|---|---|---|
| DDL v6 de `GPOS_SYSDATA` (D7-A): tablas por empresa, disparadores 51619 a 51626, catálogo de eventos, columnas de la bitácora, `Reportes.EmpresaCodigo` | T1-1 (DAT:719-955) | base del sistema; la aplica la API en Amplio y `GPOS.Migracion sistema` en Estricto |
| Permisos de `gpos_api` (D7-P) | T1-1 (DAT:957-972) | identidad de la API |
| Q1 `EstadoAcceso`, permisos por (cuenta, empresa), `BitacoraAcceso`, cupo provisional | T1-2 (PLAN:173-198; DAT:186-237) | en cada petición autenticada (se conecta en T1-5) |
| `/api/admin/miembros*`, `/api/super/cuentas*`, `/api/super/empresas/{c}/miembros*`; Q3, Q3-P, Q9, Q10, Q13 | T1-3 (PLAN:200-226; DAT:239-471) | ADMIN y SUPER autenticados |
| `GPOS.Migracion accesos --convertir` (precondiciones, pasos 0 a 11, Q23, reverso) | T1-4 (PLAN:228-256; D0:928-989; DAT:487-616, 988-1025) | consola de la instalación, identidad de `GPOS.Migracion` con DDL |

**Fuera de alcance:** T1-5 (corte), T1-6, T1-7, T1-8 y T2-0 (llave de firma). PLAN:568 ya los asigna a revisión en su PR. Solo se anotan las condiciones de T1-5 que nacen de decisiones de T1-1 a T1-4 (D1-13).

## 2. Tabla resumen de hallazgos

| ID | Severidad | Título | Tarea |
|---|---|---|---|
| D1-01 | Media | Las rutas de membresías existen antes del corte y antes de convertir, con la autorización del modelo global, y la etiqueta `db7-antes-del-corte` las incluiría en un DEMO | T1-3 |
| D1-02 | Media | Una base convertida en D1 queda marcada como «convertida» sin sellos ni padrón v2, y en D3 no hay un camino definido para sellarla | T1-4 |
| D1-03 | Media | El modo DEMO (`--instalacion-demo`) depende solo de una bandera: en D1 nada técnico impide usarlo en una instalación real | T1-4 |
| D1-04 | Media | La subida de `VersionPrivilegios` cuando cambian perfiles o excepciones depende de cada camino de C#: un camino olvidado deja vivo un privilegio revocado mientras dure la caché | T1-1, T1-2 |
| D1-05 | Media | Q1 y el evaluador: falta fijar «sin fila = sin acceso» para todos los niveles, incluido el SUPER con una empresa inexistente o inhabilitada | T1-2 |
| D1-06 | Baja | El disparador 51619 no detecta un intercambio de claves en un `UPDATE` de varias filas | T1-1 |
| D1-07 | Baja | Q9-b no exige que la empresa de la sesión esté en el dominio, y el dominio se calcula fuera de la transacción | T1-3 |
| D1-08 | Baja | Excepciones y permisos de perfil sin validación al escribir: opción libre, `rpt:{id}` de otra empresa y truncado silencioso de `OPENJSON` | T1-3 |
| D1-09 | Baja | La regla del último ADMIN no cubre todos los caminos: baja, inhabilitar la cuenta y rutas del SUPER | T1-3 |
| D1-10 | Baja | Enumeración de códigos globales por el 409 `CODIGO_NO_DISPONIBLE`; falta definir qué cuenta el tope ADM-13 | T1-3 |
| D1-11 | Baja | `ValorAnterior` y `ValorNuevo` sin lista blanca, y la fila de Q1 debe heredar TN-09 (sin hash ni sellos en `ToString`) | T1-2 |
| D1-12 | Baja | La precondición 2 (API detenida) es local y no ve `dotnet GPOS.Api.dll` ni una API en otro equipo | T1-4 |
| D1-13 | Baja | Condición para T1-5: la caché por (cuenta, empresa, versión) frente a una restauración que hace retroceder las versiones | T1-2 → T1-5 |
| D1-14 | Baja | Los `DENY` de D7-P solo rigen en Estricto. En Amplio la API tiene `CONTROL` y puede deshabilitar los disparadores | T1-1 |
| D1-15 | Baja | Conversión: el respaldo previo y la copia de reportes con SQL a todas las empresas necesitan dos precisiones | T1-4 |

**No hay hallazgos Críticos ni Altos.** D1-01 a D1-05 son **condiciones para unir** el PR correspondiente (sección 6). Si D1-02 o D1-03 se construyeran tal como están y el verbo corriera sobre una instalación con datos reales, el riesgo pasaría a **Alto**, porque se sellaría como legítimo un sobreacceso (la clase de SD0-10).

## 3. Checklist OWASP Top 10 (2021), aplicado al diseño

| Categoría | Estado | Nota |
|---|---|---|
| A01 Control de acceso | Observaciones | La empresa forma parte de la PK y de las FK compuestas (DAT:80-87 [V]); Q3 filtra por `@empresa` (DAT:252 [V]). Observaciones: D1-01, D1-05, D1-07, D1-08 y D1-09. La membresía sin sello entre D1 y D3 es un riesgo aceptado (R-D1-07, PLAN:472 [V]) |
| A02 Fallas criptográficas | Observaciones | D1 no agrega criptografía: el sello de membresía es de D3 (PLAN:184 [V]). D1-02 trata la transición sin sello. D1-11: no exponer el hash ni los sellos |
| A03 Inyección | Correcto, con una observación | Todo el SQL es estático, con parámetros tipados (DAT:155-169 [V]). Las listas llegan como JSON con `OPENJSON … WITH` (C-9, DAT:149 [V]). La única concatenación es el catálogo generado, con validación `^[A-Z0-9_]{1,40}$` más un `CHECK` en `Latin1_General_BIN2` (DAT:636 y :890 [V]). Observación: el truncado de `OPENJSON` (D1-08) |
| A04 Diseño inseguro | Observaciones | D1-02, D1-03 y D1-04 |
| A05 Configuración de seguridad | Observaciones | D7-P falla con 51614 si falta `gpos_api` (C-6, DAT:146 y :963-964 [V]). D1-14 (Amplio) |
| A06 Componentes vulnerables | No aplica | D1 no agrega paquetes |
| A07 Autenticación | Observaciones | D1-10 (enumeración). Restablecer la clave exige autenticación reciente (PLAN:226 [V]). Los ADMIN convertidos quedan con «debe cambiar la clave» (PLAN:256 [V]) |
| A08 Integridad de software y datos | Observaciones | Monotonía de la versión (51619 y 51620 más `DENY DELETE`), sin cambios de categoría (51626) e independencia de Q23 frente al paso 3 (DAT:490 [V]). Observaciones: D1-04 y D1-06 |
| A09 Registro y monitoreo | Observaciones | Catálogo cerrado, «antes y después» en la misma transacción y rutas de fallo sin reversión (SD0-07; DAT:483-485 [V]). Observaciones: D1-11 y D1-12 |
| A10 SSRF | No aplica | D1 no hace llamadas salientes. El paso 11 escribe en bases de empresa con parámetros `int` (DAT:24 [V]) |

## 4. Hallazgos

### D1-01 · Media (condición para unir T1-3) · Rutas de membresías antes del corte y antes de convertir
- **Riesgo.**
  - T1-3 publica `/api/admin/miembros*` y las rutas del SUPER con `RequiereAdmin` y `RequiereSuper` «tal como están» (PLAN:212 [V]). Es decir, con el nivel tomado del claim del modelo global, que H-01 y H-02 describen.
  - Entre la unión de T1-3 y la de T1-5, un ADMIN del modelo anterior puede crear, vincular y elevar membresías en cualquier empresa que lleve en el token. Esas filas todavía no autorizan nada, pero después del corte sí.
  - El reverso de D7-A se niega con «membresías creadas fuera del verbo» (DAT:995-997 [V]). El verbo, en cambio, no tiene una precondición explícita de tabla vacía (D0:931-950 [V]). Hoy fallaría por la PK del paso 3 o por la diferencia E1 de Q23, así que falla cerrado, pero con un mensaje que no explica la causa [I].
  - P-D1-02 prohíbe publicar solo **desde T1-5** hasta D4 (PLAN:494 [V]). La etiqueta `db7-antes-del-corte` se pone «sobre la punta anterior» a T1-5 (PLAN:468 [V]), así que incluiría T1-3 y T1-4. Un DEMO construido desde esa etiqueta llevaría las rutas nuevas con la autorización vieja.
- **Remediación (unos 0,25 d [I]).**
  1. Las rutas de T1-3 responden 503 `ACCESOS_NO_CONVERTIDOS` mientras falte la marca `Accesos.Modelo` (fallar cerrado). Así se cierra también la ventana de antes de T1-5 en cualquier base sin convertir.
  2. Una precondición 10 del verbo: `UsuariosEmpresas` y `EmpresasPerfiles` vacías, o 51622 con un mensaje claro.
  3. La etiqueta `db7-antes-del-corte` va sobre la punta anterior a **T1-1**, o P-D1-02 se extiende a «desde T1-3».
- **Pruebas:** `MiembrosHttpTests.Sin_convertir_las_rutas_de_miembros_responden_503` y `ConversionAccesosTests.Con_membresias_previas_se_detiene_con_51622`.

### D1-02 · Media (condición para unir T1-4) · Base convertida en D1 sin sellos ni camino definido en D3
- **Riesgo.**
  - En D1, el verbo no ejecuta los pasos 6 (sellos y padrón v2) ni 7 (cupo desde el padrón). Aun así, escribe la marca `Accesos.Modelo = 'MEMBRESIA.v1'` en el paso 9 (PLAN:241 [V]; D0:966 [V]).
  - En D3, la precondición 1 responde «ya convertido» y sale con código 0 (D0:932 [V]). Nada sella esas membresías.
  - A partir de D3, Q1 las rechaza como `MEMBRESIA_SIN_SELLO` (D0:294-298 [V]). La salida natural sería **legitimar en masa**, y eso es justamente sellar sin derivar del padrón v1, lo que ADR-83, punto 2, prohíbe (D0:974 [V]).
  - Afecta a toda base que se convierta entre D1 y D3: el DEMO del propietario, los bancos de medición de T1-8 (PLAN:344 [V]) y cualquier ensayo.
- **Remediación (unos 0,25 d [I]).**
  - En D1, el verbo escribe una marca distinta (`MEMBRESIA.v1-sin-sello`). D3 agrega un modo `accesos --completar-sellos` que ejecuta solo los pasos 6 y 7 **derivados del padrón v1 que se guardó en la conversión**, nunca de las filas.
  - *Alternativa más barata:* en D1, el verbo solo corre con `--solo-pruebas` (o en Debug) y se niega sobre una base con licencia. Las bases de prueba se convierten de nuevo en D3.
  - Cualquiera de las dos queda escrita en PLAN antes de unir T1-4.
- **Prueba:** `ConversionAccesosTests.En_D1_la_marca_indica_sin_sello` (D3 la invierte).

### D1-03 · Media (condición para unir T1-4) · `--instalacion-demo` sin guarda técnica
- **Riesgo.**
  - El modo DEMO copia todas las membresías con el nivel global de hoy, ADMIN incluido, en todas las empresas habilitadas (D0:941 y :959 [V]). Es el sobreacceso de H-01 y H-02 convertido en dato legítimo.
  - La única guarda técnica prevista depende de la clasificación de empresas, que sigue pendiente (D0:943 [V]). En D1, entonces, la diferencia entre DEMO y producción es solo una bandera de consola. El control que queda es detectivo: el modo, el motivo y la cuenta de Windows van a la bitácora (D0:942 [V]).
- **Remediación (unos 0,1 d [I]).**
  - Mientras no exista la clasificación, `--instalacion-demo` se rechaza con 51622 si la licencia vigente es Producción o Beta. Es el mismo criterio con el que la API ya se niega a arrancar en Amplio (`src/GPOS.Api/Program.cs:441-442` [V], SEG-L2-05).
  - La vista previa muestra, **por empresa**, cuántas membresías ADMIN se crearán, y exige escribir de nuevo el número de empresas o la palabra `DEMO` para confirmar.
- **Prueba:** `ConversionAccesosTests.Modo_DEMO_con_licencia_de_produccion_se_detiene_con_51622`.

### D1-04 · Media (condición para unir T1-2) · La versión de privilegios depende de cada camino de C#
- **Riesgo.**
  - 51619 obliga a subir la versión cuando cambian estado, nivel, restricción o sucursal (DAT:127 [V]). Los cambios en `UsuariosEmpresasPerfiles`, `UsuariosEmpresasPermisos`, `EmpresasPerfilesPermisos` y en `EmpresasPerfiles.Inhabilitado` **no** están cubiertos por ninguna regla de la base. La suben Q13 y Q6 «siempre» (DAT:455 [V]) y la siembra (PLAN:183 [V]).
  - Quedan sin una regla visible otros caminos: el borrado de `rpt:{id}` cuando se elimina un reporte (índice de DAT:180 [V]; DAT-D0 2.6), los pasos únicos de `PermisosService` y cualquier ruta que se agregue después.
  - Con la caché de T1-5 (llave `cuenta|empresa|versión`, 5 min; PLAN:267 [V]), un camino olvidado mantiene un privilegio **revocado** hasta 5 minutos. ADR-36 pide que se aplique en cada petición.
- **Remediación (unos 0,25 d [I]).**
  - Todo DML sobre esas cuatro tablas pasa por un solo método (`MembresiasService` o `PermisosEmpresa`) que sube la versión de los afectados en la misma transacción.
  - Una prueba de arquitectura (en `ConsultasAcceso` o con reflexión sobre las constantes SQL) falla si otro tipo escribe en esas tablas.
- **Alternativa descartada:** un disparador en las hijas que suba la versión del padre. Volvería a disparar 51619 y haría que Q13 devuelva `versionLeida + 2`, con lo que rompería la guarda de C# (DAT:454 [V]).

### D1-05 · Media (condición para unir T1-2) · Q1: «sin fila = sin acceso» en todos los niveles
- **Riesgo.**
  - El conjunto 1 de Q1 hace `LEFT JOIN` a `Empresas` y a `UsuariosEmpresas` (DAT:202-206 [V]). Si la empresa del token no existe, `e.*` llega en NULL. Si no hay membresía, `ue.*` llega en NULL.
  - Las pruebas previstas cubren la membresía `SUSPENDIDA`, la empresa inhabilitada y «SUPER sin membresía = SUPER» (PLAN:188-191 [V]). No cubren:
    - una empresa **inexistente** para un USER o un ADMIN;
    - el SUPER con una empresa inexistente o inhabilitada;
    - un `Estado` o un `Nivel` fuera del conjunto conocido.
  - Una evaluación del tipo «si es SUPER, nivel SUPER» antes de comprobar `e.Codigo IS NOT NULL` le da al SUPER una sesión en una empresa que no existe. Eso cuenta también para el aislamiento de las cachés por empresa [I].
- **Remediación (unos 0,1 d).** El evaluador de `EstadoAcceso` es una lista blanca:
  - acceso solo si `e.Codigo` no es NULL y la empresa está habilitada (o la regla que ADR-35 fije para el SUPER), y además la membresía está `HABILITADA` o la cuenta es SUPER;
  - cualquier otro valor da sin acceso;
  - la lectura fallida da 503 y nunca 401 (como ya dice PLAN:265).
- **Pruebas:** `EstadoAccesoTests.Q1_empresa_inexistente_da_sin_acceso` (USER, ADMIN y SUPER) y `…Q1_SUPER_con_empresa_inhabilitada` (con la regla de ADR-35).

### D1-06 · Baja · 51619 y el intercambio de claves
- **Riesgo.** El disparador detecta un cambio de clave cuando una fila de `inserted` no tiene su pareja en `deleted` (DAT:818-819 [V]). Un `UPDATE` de varias filas que **intercambia** `EmpresaCodigo` entre dos membresías de la misma cuenta deja los dos conjuntos de claves iguales. Así pasa la comprobación y se comparan filas lógicas distintas. Mueve un nivel ADMIN de una empresa a otra. Solo es posible con SQL directo y `UPDATE` sobre la tabla (`gpos_api` lo tiene, `PrivilegioMinimoSistema.cs:124` [V]). Si hay hijas, la FK lo impide. D3 lo detecta por el subpropósito `{c}|{E}` del sello (D0:295 [V]).
- **Remediación (minutos).** `IF UPDATE(UsuarioCodigo) OR UPDATE(EmpresaCodigo) THROW 51619`: la PK no se actualiza nunca, y es más simple que la comparación actual.
- **Prueba:** `RestriccionesMembresiaTests.E51619_actualizar_la_clave_se_rechaza_siempre`.

### D1-07 · Baja · Q9-b sin la empresa de la sesión en el dominio
- **Riesgo.**
  - Q10 exige `@empresa ∈ @dominio` (DAT:375 y :394 [V]). Q9-b no lo hace: solo comprueba que la cuenta tenga una membresía `HABILITADA` en el dominio (DAT:336-340 [V]). Hasta T1-5, la ruta solo exige `RequiereAdmin` del claim (D1-01).
  - Además, el dominio (Q9-P, DAT:305-309 [V]) se calcula sin decir si va dentro de la transacción `SERIALIZABLE`, después del padrón. Si va antes, entre el cálculo y el vínculo pueden suspender al ADMIN en B y aun así vincular desde B (TOCTOU) [I].
- **Remediación (minutos).** Agregar `AND EXISTS (SELECT 1 FROM @dominio WHERE EmpresaCodigo = @empresa)` a Q9-b, igual que Q10, y dejar escrito que Q9-P corre dentro de la transacción, después del padrón y de `Usuarios`.

### D1-08 · Baja · Validación de excepciones y permisos de perfil al escribir
- **Riesgo.**
  - Q13 inserta las excepciones tal como llegan en el JSON (`o nvarchar(50)`, `n int`, `a int`; DAT:446-448 [V]). Valida los perfiles (DAT:411 [V]), pero no las excepciones.
  - **Lo que ya mitiga:** al leer, `Permisos.Normalizar` descarta las opciones que no existen, limita el nivel al máximo y quita las acciones que no aplican (`src/GPOS.Contracts/Seguridad/Permisos.cs:368-372` y `:379-394` [V]).
  - **Lo que no mitiga:**
    1. `Buscar` acepta cualquier `rpt:{id}` numérico (`Permisos.cs:303-305` [V]). Un ADMIN de A puede dejar en A el permiso de un reporte de B. Hoy no tiene efecto, porque D5 filtra el reporte por empresa, pero queda como dato latente si ese filtro falla.
    2. `OPENJSON … WITH (o nvarchar(50))` trunca en silencio un texto más largo [I]. Un valor largo podría acabar en otra opción válida.
    3. La base guarda basura que después confunde la auditoría («antes y después»).
- **Remediación (unos 0,1 d).** Antes de abrir la transacción, C# valida cada excepción y cada permiso de perfil (Q6):
  - la opción existe (`Permisos.Buscar`), con 50 caracteres o menos;
  - para `rpt:{id}`, el reporte es de la empresa de la sesión o es del sistema;
  - el nivel y las acciones están dentro del enum;
  - si algo no cumple, 400 `PERMISO_NO_VALIDO`.

### D1-09 · Baja · Último ADMIN en todos los caminos
- **Riesgo.** Q3-P (revisión 2) está bien construida (DAT:270-284 [V]), pero las pruebas solo cubren suspender y degradar (DAT:295 [V]). No se dice que se aplique a:
  - la **baja** de la membresía;
  - **inhabilitar la cuenta** desde `/api/super/cuentas`, que puede dejar sin ADMIN a varias empresas a la vez;
  - las rutas `/api/super/empresas/{c}/miembros*`.
  - Impacto: una empresa sin ADMIN y con `AdministradaPorSuper = 0` (MEM-06). Lo repara el SUPER, por eso es Baja.
- **Remediación.** Q3-P en todo camino que saque a un ADMIN `HABILITADO`. En la inhabilitación de la cuenta, se evalúa para cada empresa en la que la cuenta es ADMIN, y la respuesta nombra solo las empresas afectadas, sin revelar otras al ADMIN.
- **Pruebas:** `…Dar_de_baja_al_ultimo_ADMIN_responde_409` e `…Inhabilitar_la_cuenta_del_ultimo_ADMIN_responde_409_con_las_empresas`.

### D1-10 · Baja · Enumeración de códigos y tope ADM-13
- **Riesgo.** Los códigos de cuenta son globales. Con el 409 `CODIGO_NO_DISPONIBLE` del alta (PLAN:217 [V]), el ADMIN de A puede averiguar si un código existe en cualquier empresa. El tope de 20 por hora (PLAN:222 [V]) no dice si cuenta los **intentos** (409 y 404 de vincular) o solo las altas que se completan, ni si se guarda solo en la memoria de cada instancia.
- **Remediación.**
  - El tope cuenta todo intento de alta y de vínculo, por actor y por empresa, y responde 429.
  - Los rechazos dejan `ALTA_NO_DISPONIBLE` y `VINCULO_NO_ENCONTRADO`, que ya están en el catálogo (DAT:644 [V]). Hay que comprobar que estén en `Limitados`.
  - Se acepta como residual que el 409 revela que el código existe: no revela la empresa.

### D1-11 · Baja (condición para unir T1-2) · Datos sensibles en la bitácora y en la fila de Q1
- **Riesgo.**
  - Q1 lee `PasswordHash`, los sellos y `SelloMembresia` en cada petición (DAT:195-201 [V]).
  - La fila actual ya oculta el hash y los sellos al registrarse (TN-09, `PrintMembers` en `src/GPOS.Core/Consultas/Sistema/ConsultaEstadoSesion.cs:59-68` [V]). La fila nueva (`EstadoAcceso` y su lector) debe heredarlo. Un `record` nuevo sin `PrintMembers` los imprimiría en cualquier registro o excepción.
  - `ValorAnterior` y `ValorNuevo` admiten hasta 2 000 caracteres de JSON (DAT:484 [V]), sin una lista de campos. En `CUENTA_MODIFICADA` y `CLAVE_RESTABLECIDA`, serializar la entidad completa guardaría el hash o la clave temporal.
- **Remediación (unos 0,1 d).**
  - `PrintMembers` en todo tipo nuevo que lleve el hash o los sellos.
  - `BitacoraAcceso` serializa con una lista blanca por evento (nivel, estado, sucursal, restricción, perfiles, excepciones y motivo), nunca la entidad completa.
- **Prueba:** `BitacoraAccesoTests.Ningun_evento_lleva_PasswordHash_ni_sellos` (con un centinela).

### D1-12 · Baja · Precondición 2 del verbo (API detenida)
- **Riesgo.** `IEstadoServicios` solo mira el equipo local. No ve una API lanzada con `dotnet GPOS.Api.dll` (`src/GPOS.Migracion/Anillo/EstadoServicios.cs:43` [V]). Fuera de Windows responde `NoInstalado` (`:40` [V]), y tampoco ve una API que corra en otro equipo contra la misma instancia.
  - El `TABLOCKX` del paso 1 impide escrituras simultáneas (D0:957 [V]). Pero una API que siga en marcha conserva sus cachés del modelo anterior, y, una vez borradas las tablas globales (paso 8), falla con errores 500. Falla cerrada, pero sin explicar la causa.
- **Remediación (unos 0,1 d [I]).** Agregar a la precondición una comprobación del lado de la base: ninguna otra sesión de `gpos_api` o de `gpos_rpt_sis` en `GPOS_SYSDATA` (`sys.dm_exec_sessions` filtrado por `database_id`). Si la identidad de `GPOS.Migracion` no tiene `VIEW SERVER STATE`, se registra como aviso.

### D1-13 · Baja · Para T1-5: la caché por versión frente a una restauración
- **Riesgo.** La caché de T1-5 se indexa por `cuenta|empresa|versión` (PLAN:267 [V]). Una restauración de `GPOS_SYSDATA` hace **retroceder** las versiones. Una entrada en memoria con la versión N de antes de restaurar puede coincidir con la N restaurada, que tiene otros permisos. DAT:1050 confía en revocar las sesiones, pero eso no vacía `CachePermisos` [I].
- **Remediación.** En T1-5, vaciar `CachePermisos` y la memoria criptográfica al reconciliar una restauración, o agregar a la llave la época de restauración. Queda anotado para la revisión del PR de T1-5.

### D1-14 · Baja · D7-P solo en Estricto
- **Riesgo.** D7-P lo aplica solo `GPOS.Migracion sistema` (DAT:959 [V]). En Amplio, la API tiene `CONTROL` sobre la base (`src/GPOS.Core/Infraestructura/Motor/PrivilegioMinimoSistema.cs:54` [V]): puede borrar membresías saltándose el `DENY` (51620 sigue aplicando) y puede deshabilitar los disparadores. Es aceptable porque Amplio no arranca con licencia Producción o Beta (`Program.cs:441-442` [V]).
- **Remediación.** Dejar escrito en PLAN que las pruebas `PrivilegiosSistemaTests.D7P_*` corren en Estricto, y que V-9 de `verificar` (D0:1002 [V]) es requisito del ensayo de D6.

### D1-15 · Baja · Respaldo previo y reportes copiados
- **Riesgo.**
  1. El respaldo `COPY_ONLY` de la precondición 7 (D0:938 [V]) contiene los hashes, los sellos y el padrón. Es el único camino de vuelta (D0:987 [V]).
  2. El paso 3 b copia la `Consulta` (SQL) de cada reporte personalizado a **todas** las empresas habilitadas, también en el modo mínimo (DAT:492 [V]). Un reporte escrito por el ADMIN global de hoy (H-06) aparece en empresas en las que ese autor nunca será miembro. Se ejecuta con la identidad `rpt` de cada empresa, así que no cruza datos [I], pero amplía la superficie.
- **Remediación.**
  - El respaldo con `CHECKSUM` y `RESTORE VERIFYONLY` antes del paso 1, en la carpeta con la ACL de `usp_RespaldoCopia`. El verbo informa la ruta sin abrirla a otros.
  - Al copiar, cada `Consulta` pasa por el mismo validador que aplica la API de reportes al guardar. Si alguna no lo pasa, el verbo la deja en pendientes y no la copia.

## 5. Controles que están bien diseñados
- **Aislamiento estructural:** la empresa forma parte de la PK de toda tabla por empresa, y las FK compuestas impiden asignar a una membresía de A un perfil de B (DAT:80-87 y :783-806 [V]). Q26 lo vuelve una prueba de arquitectura (PLAN:350 [V]).
- **Monotonía y no borrado:** 51619, 51620 (`INSTEAD OF DELETE`) y `DENY DELETE`. La `BAJA` no conserva hijas (51623, por las dos vías, C-3). El SUPER no tiene membresías (51624 y 51625).
- **Catálogo cerrado:** generado desde una sola fuente, con validación del nombre en C# y un `CHECK` en `BIN2`. La categoría es inmutable (51626, comprobada **antes** del `MERGE`), sin `NOT MATCHED BY SOURCE`, y `gpos_api` no puede escribirlo (DAT:636, :890, :900-906 y :966-967 [V]).
- **Purga con piso de 2 años más 1 día**, que no depende del catálogo, y un evento fuera del catálogo se guarda 5 años (DAT:677 y :692 [V]).
- **Concurrencia optimista correcta:** `OUTPUT … INTO @v` en lugar de `@@ROWCOUNT`, con la guarda de C# como segunda barrera (DAT:454 [V]). La corrección de Q3-P se probará primero en rojo contra el texto anterior (DAT:295 [V]).
- **Todas las transacciones de administración en serie, empezando por el padrón** (DAT:460 [V]). Sin interbloqueos y sin carreras entre tenants dentro de la administración.
- **Fallar cerrado:** D7-P lanza 51614 si falta `gpos_api`. Si Q1 no lee, responde 503 y nunca 401 (PLAN:265 [V]). Si las reglas de notificación no se reasignan, quedan suspendidas (D0:968 [V]). El fallo del archivo `padron` sale con un código distinto de 0 (D0:967 [V]).
- **Conversión:** una sola transacción `SERIALIZABLE` con `XACT_ABORT`. Q23 compara en los dos sentidos y la construye un camino independiente del paso 3. Cualquier diferencia revierte todo (51621). Los ADMIN convertidos quedan con «debe cambiar la clave», y el registro va por `ILogger` con EventId, sin `EventLog` directo (PLAN:242 [V]).
- **Sin oráculo en el vínculo:** el 404 es idéntico para «no existe» y para «fuera del dominio», y la prueba compara cuerpo, código y encabezados (DAT:361 [V]). `IDENTIFICACION_FALLIDA` se guarda sin el texto tecleado (DAT:655 [V]).
- **Sin secretos nuevos en D1:** no hay cadenas, claves ni rutas nuevas (PLAN:455 [V]).

## 6. Remediaciones priorizadas y condiciones para unir

| PR | Condiciones para unir (deben estar en el PR) | Esfuerzo [I] |
|---|---|---|
| T1-1 (esquema v6) | D1-06 (sin actualizar la PK); pruebas de D7-P en Estricto (D1-14); las pruebas de DAT:1027-1043 en verde, incluidas la de 51626 en una base vacía y la del piso de la purga | unos 0,1 d |
| T1-2 (núcleo) | D1-05 (lista blanca del evaluador y las dos pruebas); D1-04 (un solo escritor más la prueba de arquitectura); D1-11 (`PrintMembers` y la lista blanca de la bitácora) | unos 0,45 d |
| T1-3 (membresías) | D1-01 (503 sin convertir); D1-07; D1-08; D1-09; D1-10 (qué cuenta el tope) | unos 0,6 d |
| T1-4 (verbo) | D1-02 (marca sin sello o solo pruebas); D1-03 (nada de DEMO con licencia de producción y la vista previa por empresa); la precondición 10 de D1-01; D1-12; D1-15 | unos 0,6 d |
| T1-5 (anotado) | D1-13 | dentro de T1-5 |

**Total:** unos 1,8 días-persona (±50 %), dentro de la holgura de pruebas de PLAN 2.1. **Costo de infraestructura:** USD 0.

Además, según el contrato habitual: **ningún PR se une sin orden expresa del propietario**, cada PR deja en verde la suite oficial (`--filter "Transicion!=Ola5&Transicion!=Defecto"`) y A revisa cada PR, de T1-1 a T1-4, cuando B lo abra (5 días hábiles).

## 7. Recomendación

**Aprobado con observaciones** (recomendación técnica; la decisión es del propietario).
- El diseño de T1-1 a T1-4 puede pasar a construcción el 2026-11-02, siempre que las condiciones de la sección 6 entren en cada PR.
- Si T1-4 se une sin D1-02 y sin D1-03, la recomendación para ese PR pasa a **Rechazado** (riesgo Alto: sellar o perpetuar un sobreacceso sin guarda).
- Si T1-3 se une sin D1-01, el PR queda **Aprobado con observaciones** solo si se cumple a la vez que no se publique ningún DEMO desde `feature/modelo-ng` desde T1-3 (no desde T1-5).

### Cierre
- Estado: Aprobado con observaciones
- Artefactos: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\A\revision-seguridad-diseno-d1-db7-2026-10-21.md`
- Supuestos:
  - La revisión 2 de DAT (2026-10-20) es la entrada final de T1-1 a T1-4.
  - El código de `feature/modelo-ng` en `e3e729c1` es la base que D1 reutiliza (`Permisos.Normalizar`, `IEstadoServicios`, `PrivilegioMinimoSistema`, TN-09).
  - El truncado silencioso de `OPENJSON … WITH` (D1-08), el vaciado de `CachePermisos` al restaurar (D1-13) y que la identidad `rpt` no cruce datos entre empresas (D1-15) son [I] y no se ejecutaron.
  - ADR-35 decide si el SUPER puede entrar a una empresa inhabilitada (D1-05). No se leyó el texto del ADR.
- Decisiones candidatas a ADR:
  - (D1-02) Marca de conversión sin sello en D1 y un camino de D3 para completarla desde el padrón v1. Precisión de ADR-39 y ADR-83.
  - (D1-03) Mientras no exista la clasificación de empresas, no hay modo DEMO con licencia Producción o Beta. Precisión de SD0-10 y ADR-39.
- Entregas a otros agentes:
  - arquitecto-software (B): D1-01, D1-02, D1-03 y D1-04 en PLAN, y la etiqueta de P-D1-02.
  - arquitecto-datos (B): D1-06, D1-07, la precondición 10 y D1-12.
  - desarrollador-backend (B): D1-05, D1-08, D1-09, D1-10, D1-11 y D1-15 en los PR.
  - qa-automatizado: las pruebas nombradas en cada hallazgo.
  - devops: D1-14 (Estricto y V-9 en el ensayo de D6) y la verificación del respaldo (D1-15).
- Próximo paso recomendado: que B incorpore las condiciones de la sección 6 al PLAN antes del 2026-11-02 y avise a A al abrir el PR de T1-1.
