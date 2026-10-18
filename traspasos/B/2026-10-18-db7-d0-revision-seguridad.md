[Informe de Seguridad] Revisión del diseño D0 de DB-7 (acceso multiempresa v1)

- **Fecha:** 2026-10-18 · **Autor:** auditor de seguridad (equipo B) · **Tipo:** revisión de diseño contra el código (no hay código de DB-7 que auditar).
- **Documentos revisados (completos):**
  - blueprint v3: `docs/arquitectura/2026-10-18-db7-blueprint-v3.md` (árbol de `master`, sin commit), al que llamo **BP3**;
  - modelo de datos: `traspasos/B/2026-10-18-db7-d0-modelo-datos.md`, al que llamo **DAT-D0**.
- **Contexto leído:** la decisión `docs/decisiones/2026-10-18-decision-db7-calendario.md` (DB7-01 a DB7-07), el estándar v2.3 (**EST**), la auditoría de origen (`docs/propuestas/auditoria-aislamiento-multiempresa.md`), ADR-41 y ADR-53 (C49-1 v2) y `CLAUDE.md`.
- **Código (solo lectura):** el árbol `GPOS-B-integracion`. Otro agente lo movió mientras leía: empezó en `55365806` (`b/une-58-74`) y terminó en `a960cfac` (`b/une-62-70`). Los dos contienen `886dde70` (el #57 unido), y lo que se unió entre medias son pruebas y documentos. **Las líneas que cito son de `a960cfac`.** Algunas no coinciden con las que cita BP3, que usa `4e094323`. Por ejemplo, `ValidarAutorizanteAsync` está hoy en `UsuariosService.cs:320`, no en la `:217-229`. No cambié de rama, no edité nada y no compilé ni ejecuté nada.
- **Convención:** **[V]** = verificado leyendo el código o el documento; **[I]** = inferido. No hay pasos de explotación (C10).

---

## 1. Alcance y superficie revisada

| Superficie | Qué revisé |
|---|---|
| Rutas anónimas | `/api/auth/*` (`AuthEndpoints.cs:32-44`, `:112`; `AuthEndpoints.SegundoFactor.cs:45`, `:90`), la recuperación del factor (`RecuperacionFactorEndpoints.cs:62`, `:85`, `:134`), el canje y el token de los dispositivos (`RestauranteDispositivosEndpoints.cs:34`, `:54`) y `/api/salud` en las dos API |
| Rutas autenticadas de la principal | El esquema selector, el de usuario y el de dispositivo (`Program.cs:59-118`), y las políticas (`Seguridad.cs:200-292`) |
| Rutas `/api/admin` que tocan `GPOS_SYSDATA` | Usuarios, perfiles, reportes, RNC, dispositivos, notificaciones y restauración (`AdminEndpoints.cs:16-315`; `ReportesEndpoints.cs:75-101`; `RncDgiiEndpoints.cs:21`) |
| API de reportes | La introspección (`ValidadorTokenPrincipal.cs:26-51`), su cliente (`VerificadorIntrospeccion.cs:29-30`), `AutenticacionIntrospeccion.cs:77` y `:105-116`, y `ProveedorContexto.cs:73` |
| Tareas en segundo plano | `TrabajoNotificaciones` (`:102-190`) y la lista de servicios en segundo plano (`Program.cs:215-281`) |
| Autorizante de supervisor | `PosEndpoints.cs:50-80`, `AutorizadorSupervisor.cs:26-41` y `UsuariosService.cs:320-333` |
| Sellos, padrón y cupo | BP3 8.4; DAT-D0 3.1 a 3.7; `SellosHabilitacion.cs:15-37`; `RevocacionSesiones.cs:175-178`; `EstadoLicenciaService.cs:186-197` |
| Token y llaves | BP3 8.2; `Seguridad.cs:22-25`, `:146`, `:310-360`; `AutenticacionDispositivo.cs:53-128`; `GPOS.Comun/Sobres/LlaveSitio.cs` |
| Conversión, bitácora, formatos y contraseñas | DAT-D0 5 y 7; `GeneradorRazor.cs:96-100` y `:138`; `PoliticaClaves.cs:38-57`; `UsuariosService.cs:483` y `:773` |

---

## 2. Tabla resumen de hallazgos

| ID | Severidad | Título | ¿Corregir antes de la firma? |
|---|---|---|---|
| SD0-01 | **Alta** | H-06 sigue abierto en los reportes: las definiciones y su SQL son globales y el ADMIN de cualquier empresa las modifica | **Sí** |
| SD0-02 | **Alta** | R-12 (P-D0-03) no puede quedar como opción: con el ADMIN por empresa, el escape del modo gráfico anula el aislamiento de DB-7 | **Sí** |
| SD0-03 | Media | El sello de membresía no exige de forma explícita la entrada del padrón: reponer un sello antiguo después de una `BAJA` (DX-5) | **Sí** (es solo texto) |
| SD0-04 | Media | La política de contraseñas sigue leyendo el nivel de la cuenta: tras IDN-03, el ADMIN de una empresa puede elegir 10 caracteres | **Sí** (es solo texto) |
| SD0-05 | Media | Notificaciones y reportes programados se ejecutan con un ADMIN sintético; Q7 solo decide si la regla corre | **Sí** (es solo texto) |
| SD0-06 | Media | El autorizante de supervisor tiene dos caminos, y «Q1» no es la validación correcta para él | **Sí** (es solo texto) |
| SD0-07 | Media | La FK del catálogo de eventos puede revertir el cambio que registra, incluidas las denegaciones y los bloqueos | Recomendado |
| SD0-08 | Media | La API de reportes decide con los claims del token (`nivel`, `cambiar_clave`) y lee la restricción por fuera de la introspección | Recomendado |
| SD0-09 | Media | La vía sin TPM no baja a requisitos las condiciones de C49-1 v2 | Recomendado |
| SD0-10 | Media | `accesos --convertir` puede sellar como legítimo el sobreacceso de hoy (H-01 y H-02) fuera del DEMO | Recomendado |
| SD0-11 | Baja | Cambios de privilegios que no suben `VersionPrivilegios` (perfil inhabilitado, siembras de `sistema`) | No |
| SD0-12 | Baja | Token de dispositivo: no se comprueba que la empresa siga habilitada, y su validez se guarda 15 s | No |
| SD0-13 | Baja | La memoria del resultado criptográfico (5 min) sobrevive a la revocación de una llave del anillo | No |
| SD0-14 | Baja | Columnas sin sello que se pueden cambiar por SQL: el residual no está documentado en DAT-D0 3.5 | No |
| SD0-15 | Baja | Detalles de ES256 y de las políticas: `TryAllIssuerSigningKeys`, llave activa en `KidsValidos` y `HasClaim` sobre todas las identidades | No |
| SD0-16 | Baja | Q1 en `READ COMMITTED` puede esperar detrás de las transacciones de administración y responder 503 | No |
| SD0-17 | Baja | P-D0-04: «debe cambiar la clave» es global (efecto entre empresas) | No |
| SD0-18 | Baja | Reversión y preautorización: clave HS256 nueva al revertir; `jti` consumidos solo en memoria | No |

No hay hallazgos **Críticos**. El diseño cierra H-01, H-02 y H-07 en las rutas de usuario de la principal (sección 4.1).

---

## 3. Checklist OWASP Top 10 (2021), aplicado al diseño

| Categoría | Estado | Nota |
|---|---|---|
| A01 Control de acceso roto | **Hallazgos** | Cierra H-01, H-02 y H-07 en la principal. Quedan SD0-01, SD0-05, SD0-06 y SD0-08 |
| A02 Fallas criptográficas | Observaciones | ES256 en el TPM, sin HS256, y sellos con Data Protection: correcto. Ver SD0-09, SD0-13 y SD0-15 |
| A03 Inyección | **Hallazgo** | SD0-02 (inyección de plantilla Razor, R-12). El SQL de DAT-D0 está parametrizado, con tipos y largos |
| A04 Diseño inseguro | **Hallazgos** | SD0-03, SD0-04 y SD0-10 |
| A05 Configuración de seguridad incorrecta | Observaciones | La API no arranca en Release si falta la llave o si existe `Jwt:Clave`: correcto. Ver SD0-09 |
| A06 Componentes vulnerables o desactualizados | No aplica | El diseño no agrega paquetes. No ejecuté herramientas de dependencias: es una revisión de diseño |
| A07 Fallas de identificación y autenticación | Observaciones | Dos pasos, hash ficticio, bloqueo por (cuenta, IP) y global, sesión única con empresa: correcto. Ver SD0-04, SD0-17 y SD0-18 |
| A08 Fallas de integridad de software y datos | **Hallazgos** | Sello en dos niveles y padrón v2: correcto en lo esencial. Ver SD0-03, SD0-10 y SD0-14 |
| A09 Fallas de registro y monitoreo | **Hallazgo** | SD0-07. TRZ-07 y TRZ-10 pasan a la fase 2 (P-D0-05): lo acepto, con la nota de la sección 4.5 |
| A10 SSRF | No aplica | DB-7 no agrega llamadas salientes. La canalización de la introspección es local, y su dueño se verifica |

---

## 4. Hallazgos

### 4.1 Cierre de H-01, H-02 y H-07, ruta por ruta (resumen de lo verificado)

| Camino | ¿Valida la membresía en el servidor con el diseño D0? | Evidencia |
|---|---|---|
| Petición de usuario a la principal | **Sí.** Toda petición con portador pasa por el esquema predeterminado (selector → usuario) y por `OnTokenValidated`. `ValidacionAcceso` lee Q1 sin caché, con los pasos a a h | `Program.cs:59-60` y `:70-118` [V]; BP3 6.1 |
| Políticas `admin`, `super`, `perm:` y `algun:` | **Sí**, si se leen de `nivel_efectivo`. Hoy leen el claim (`Seguridad.cs:216`, `:236-246`) [V]. BP3 lo cambia y lo vigila con una prueba de arquitectura (2.2) | BP3 6.1, paso 6 |
| Rutas anónimas | `GET /empresas` pasa a 410. Las sucursales piden la preautorización. `identificar` y `login` aplican Q1 y Q2. **H-07 queda cerrado** | `AuthEndpoints.cs:32-44` [V]; BP3 5.2 |
| `POST /empresa` (cambio de empresa) | **Sí:** la membresía de destino y el motivo del SUPER. El token anterior de la misma `sid` deja de valer por el control del último `jti` (CS-2), que ya existe | BP3 5.2; `Program.cs:105` [V] |
| API de reportes | **Sí:** la introspección v2 llama a la misma `ValidacionAcceso`, sin caché. Ver SD0-08 | BP3 5.5; `VerificadorIntrospeccion.cs:29-30` [V] |
| Token de dispositivo (ADR-121) | **No aplica la membresía**: un dispositivo no es una persona. Su empresa sale del registro y el ADMIN gestiona solo los de la empresa de su sesión (`ServicioDispositivos.cs:45-74`) [V]. Ver SD0-12 | `AutenticacionDispositivo.cs:53-128` [V] |
| Autorizante de supervisor | **Parcial:** ver SD0-06 | `PosEndpoints.cs:64-76`; `AutorizadorSupervisor.cs:35-40` [V] |
| `TrabajoNotificaciones` | **Parcial:** ver SD0-05 | `TrabajoNotificaciones.cs:151` y `:180-189` [V] |
| Otras tareas en segundo plano (licencia, RNC, reloj, respaldos, vigilancia, purga) | No actúan por cuenta de una persona: no aplica la membresía [I, por sus nombres y constructores] | `Program.cs:215-281` [V] |
| Definiciones de reportes en `GPOS_SYSDATA` | **No:** ver SD0-01 | `ReportesService.cs:105-149` [V] |

---

### SD0-01 · Alta · H-06 sigue abierto en los reportes

**Riesgo.** Las definiciones de reportes, con su SQL, están en la tabla global `dbo.Reportes` de `GPOS_SYSDATA`, sin empresa. `/api/admin/reportes` (`RequiereAdmin`) permite modificarlas, incluidos los reportes del sistema, y borrar las que no son del sistema. Con DB-7 el ADMIN pasa a ser de una sola empresa, pero en los reportes seguiría actuando sobre todas.

Consecuencia: el ADMIN de la empresa A podría cambiar la consulta de un reporte que los usuarios de B ejecutan en la base de B. Por ejemplo, para ocultar o alterar cifras de ventas, caja o inventario de un tercero (fraude o encubrimiento). También podría borrar los reportes personalizados de B.

Esto es H-06 (Alta) de la auditoría de origen, que nombra los reportes junto con los perfiles, la licencia y el padrón RNC. BP3 cierra los tres últimos (D1, D3 y AIS-09), pero **no los reportes**.

**Evidencia.**
- `src/GPOS.Core/Data/Sistema/SistemaDbContext.cs:226-259`: `Reporte` sin empresa [V].
- `src/GPOS.Core/Servicios/ReportesService.cs:105-125` (guarda cualquier `Id`) y `:144-149` (borra cualquiera que no sea del sistema) [V].
- `src/GPOS.Api/Endpoints/ReportesEndpoints.cs:83-85` (`RequiereAdmin`) [V].
- Auditoría de origen, H-06, y punto 5 de su remediación: «agregarles `EmpresaCodigo`; los del sistema solo los modifica el SUPER».
- EST 5.7 («Visibilidad»: adopta DAT §2.3, con la edición de los reportes del sistema solo por la semilla o el SUPER).
- DAT-0929 tenía `Reportes.EmpresaCodigo` (`docs/datos/2026-09-29-modelo-acceso-multiempresa.md:234` y `:1218-1226`). **DAT-D0 no lo incluye** (2.1 no cambia `Reportes`), y BP3 tampoco: no está en 11.1 ni en la tabla 1.2. PRV-07 está como «Entra (D5)», pero solo como visibilidad y `rptsis.PermisoEfectivo`.

**Remediación en el diseño (antes de la firma).** Dos opciones; recomiendo la (a) para la v1:
- **(a)** `dbo.Reportes.EmpresaCodigo nvarchar(30) NULL` (NULL = del sistema), con FK a `Empresas`.
  - `ListarAsync`, `ObtenerAsync`, `GuardarAsync` y `EliminarAsync` filtran por la empresa del token. Un `Id` de otra empresa responde 404 sin distinguir (PRV-07, QA-20).
  - Los reportes del sistema y los de `EmpresaCodigo` NULL solo los modifican el SUPER o la semilla. El ADMIN los **duplica** en su empresa.
  - Los permisos `rpt:{id}` valen solo en la empresa del reporte.
  - Hay que agregarlo a DAT-D0 2.1 y 7.2, a BP3 1.2, 4.3 y 11.1, y a la conversión: los reportes personalizados de hoy se copian a cada empresa, como los perfiles.
  - Costo *inferido*: de 0,3 a 0,5 sp entre D1 y D5.
- **(b)** Mínima: `POST` y `DELETE /api/admin/reportes` pasan a `RequiereSuper` hasta la fase 2. Unas 0,05 sp. **Qué rompe:** el ADMIN deja de diseñar reportes, así que se debe presentar como pregunta nueva **P-D0-08** (cambia lo que el usuario hace).

---

### SD0-02 · Alta · R-12 (P-D0-03) no puede quedar como opción

**Riesgo.** En el modo gráfico, el valor de la imagen se codifica para HTML pero no se escapa la arroba de Razor. El texto fijo sí se escapa. La plantilla resultante se compila y ejecuta dentro del proceso de la API, que guarda las cadenas de conexión de **todas** las empresas (G-1).

Con DB-7, el ADMIN de una empresa sería quien diseña en modo gráfico. Si R-12 sigue abierta, un ADMIN de A tiene un camino para ejecutar código en la API y leer datos de B. Eso anula lo que DB-7 cierra. La alternativa de P-D0-03 («dejarla en ADR-110 y aceptar el riesgo por escrito») es incompatible con el objetivo firmado de DB-7: un usuario de una empresa no entra a otra.

Verificado leyendo el código; no lo ejecuté ni lo probé.

**Evidencia.**
- `src/GPOS.Contracts/Impresion/GeneradorRazor.cs:99-100`: solo se exige el prefijo `data:image/` y se aplica `HtmlEncode` [V].
- `:138`: `Texto()` sí escapa la arroba [V].
- `:96-97`: el logo usa una expresión del modelo, sin texto del cliente [V].
- BP3 2.1 (fila «Formatos») y P-D0-03.

**Remediación en el diseño.**
- P-D0-03 pasa de pregunta a **requisito de D1**. Se mantiene la pregunta solo para el costo.
- Regla: **todo** texto del diseño que llegue a la plantilla pasa por `Texto()` o por un filtro de lista blanca.
- Para la imagen, una validación estricta: solo `data:image/(png|jpeg|gif|webp);base64,` seguido del alfabeto base64, con un tope de tamaño. Se rechaza `svg+xml` y todo lo que no sea base64. Además, se escapa la arroba (defensa en profundidad).
- Una prueba de arquitectura recorre todas las propiedades de texto de `DisenoVisual` y sus elementos con un valor centinela, y comprueba que no queda ninguna arroba sin escapar.
- D6 la audita (EST, «Para Seguridad», ya lo pide).

---

### SD0-03 · Media · El sello de membresía no exige de forma explícita la entrada del padrón

**Riesgo.** DX-5 justifica que la `BAJA` salga del padrón con este argumento: «un `UPDATE` de `BAJA` a `HABILITADA` no verifica (el sello dice `BAJA`)». Falta el caso de **reponer** en la fila el sello y las columnas guardados de antes de la baja, cuando la membresía estaba `HABILITADA` (incluso como ADMIN). Ese sello sí descifra y coincide con la fila repuesta. Lo único que lo rechaza es que el padrón ya no tiene `m(c,E)`.

BP3 6.1 (paso g) dice «el sello de membresía verifica y su estado sellado es `HABILITADA`», y 3.6 habla de la «comparación con el padrón». Pero ninguno de los dos documentos dice que **la ausencia de `m(c,E)` es un rechazo**. El caso 5 de DAT-D0 3.5 (reponer un par antiguo) solo trata la cuenta. Si se implementa al pie de la letra de DX-5, quedaría una forma de reactivar o elevar una membresía con un `UPDATE`, sin rehacer ningún MAC (la clase SEG-L2-01).

**Evidencia.** DAT-D0 3.3 (DX-5) y 3.5; BP3 6.1 (paso g), 8.4 («`BAJA`: sale del padrón») y 14 (DX-5). Hoy la cuenta solo acepta `Valido` (`RevocacionSesiones.cs:175`), y `FueraDePadron` existe como resultado (`SellosHabilitacion.cs:26-27`) [V]. El mismo criterio debe aplicarse a la membresía.

**Remediación en el diseño (es solo texto).** Definir `ResultadoSello.Valido` de la membresía como la conjunción de estas condiciones:
- el sello descifra con el subpropósito;
- `c`, `e`, `n`, `st`, `r` y `s` son iguales a la fila;
- `m(c,E)` existe en el padrón verificado, con `h` igual a la huella del sello, `n` igual y `st = H`;
- `a(c)` existe y no es SUPER.

Cualquier otro caso da `FueraDePadron` o `SelloInvalido`, y la respuesta es 401 `credenciales`.

Además, agregar el **caso 9** a la tabla de DAT-D0 3.5 («reponer la fila y el sello anteriores a una baja o a un cambio de nivel») y su prueba en D3. Q2 debe aplicar la misma definición.

---

### SD0-04 · Media · La política de contraseñas sigue leyendo el nivel de la cuenta

**Riesgo.** `PoliticaClaves.Problema(clave, nivel)` exige 12 caracteres solo si `nivel` es ADMIN o SUPER. Hoy se llama con el nivel de la **cuenta**. Con IDN-03, `Usuarios.Nivel` solo vale `SUPER` o `USER`. Por lo tanto, en el siguiente cambio de contraseña, una persona que es ADMIN en una o varias empresas podría elegir 10 caracteres.

P-D0-04 fuerza el cambio al otorgar el nivel, pero no impide que la persona baje a 10 en el cambio siguiente. SES-16 y H-15 quedarían incumplidos en silencio.

**Evidencia.** `src/GPOS.Core/Sistema/PoliticaClaves.cs:38-41` y `:57`; llamadas en `UsuariosService.cs:483` (`dto.Nivel`) y `:773` (`u.Nivel`) [V]. BP3 4.7 (SES-16) y P-D0-04.

**Remediación en el diseño.**
- El nivel que se pasa a la política es «SUPER, o ADMIN si la cuenta tiene **alguna** membresía no dada de baja con nivel ADMIN». Se lee del padrón, con el bloqueo de la transacción del cambio de contraseña.
- Esto aplica en `POST /api/auth/clave`, en el restablecimiento del SUPER y en el alta de una persona con `Privilegios.Nivel = ADMIN`.
- Una prueba de D1 cubre el caso de una persona que es ADMIN en A y USER en B y cambia su contraseña desde una sesión en B.

---

### SD0-05 · Media · Notificaciones y reportes programados con un ADMIN sintético

**Riesgo.** `TrabajoNotificaciones` arma para cada regla un `HttpContext` con el claim `nivel = ADMIN` y el código del autor, y con él ejecuta, entre otras cosas, el **reporte programado**. BP3 8.3 dice que corre «con la identidad `SISTEMA` y, por cada regla, con el estado real del autor (Q7)». Pero Q7 solo **decide si la regla corre**. No define con qué privilegios se ejecuta.

Consecuencias:
- Si se conserva el principal sintético, un USER con permiso de notificaciones recibe por correo reportes o columnas que solo ve el ADMIN (por ejemplo, costos). Es H-12.
- Con DB-7, `SesionHttp.EsAdmin` leerá `nivel_efectivo` de la identidad `gpos-permisos`, que el contexto sintético no tiene (`TransformacionPermisos` solo corre en el pipeline HTTP). La ejecución quedaría con privilegios indefinidos [I]. Puede fallar cerrado o, si alguien agrega un atajo, abrirse.

**Evidencia.** `src/GPOS.Api/Servicios/TrabajoNotificaciones.cs:151` y `:180-189`; `:30`, `:42-46` (reporte programado) [V]. BP3 6.2 y 8.3; EST 4.4.3 («`EjecutarAsync` con el alcance del autor (AIS-06)»).

**Remediación en el diseño.**
- El principal de cada regla se construye con `EstadoAccesoService.ObtenerAsync(autor, empresa)` y `CachePermisos[(autor, empresa, versión)]`, con la misma identidad `gpos-permisos` y el `nivel_efectivo` real del autor. **Nunca** con un ADMIN fijo.
- La cola y los reintentos van con `SISTEMA`, sin nivel ADMIN y sin acceso a reportes.
- Una prueba de D5: un autor USER sin «Ver costos» programa un reporte con costos, y el archivo enviado no los trae.
- Agregar este punto a la tabla 6.2.

---

### SD0-06 · Media · El autorizante de supervisor tiene dos caminos, y «Q1» no es la validación correcta para él

**Riesgo.**
- BP3 6.2 y R-DB7-09 solo nombran `POST /api/pos/autorizar`. Hay un **segundo camino**: `AutorizadorSupervisor.ValidarAsync`, que usan los servicios de documentos para la forma A de ADR-68. Los dos llaman `PermisosService.EfectivosAsync(u.Codigo)` **sin empresa**, y `mapa.EsAdmin` concede la autorización.
- «Q1 con el autorizante» incluye los pasos de sesión (d y e: `sid`, inactividad, revocación por `iat`), que no aplican a un autorizante sin sesión abierta. Implementar literalmente «Q1» rechazaría a todo supervisor. Un atajo para evitarlo podría saltarse la membresía [I].

**Evidencia.** `src/GPOS.Api/Endpoints/PosEndpoints.cs:64` y `:76`; `src/GPOS.Core/Sistema/AutorizadorSupervisor.cs:35` y `:39-40`; `src/GPOS.Core/Sistema/UsuariosService.cs:320-333` [V]. BP3 6.2 y 13.1 (R-DB7-09).

**Remediación en el diseño.**
- Definir un evaluador propio, `EstadoAcceso.EvaluarAutorizante(cuenta, empresaSesion)`, que exija:
  - cuenta habilitada, no SUPER, con su sello y su `a(c)`;
  - membresía `HABILITADA` en la empresa **de la sesión que pide**, con su sello válido (definición de SD0-03);
  - `DebeCambiarClave = 0`.

  No aplica los pasos de sesión.
- El privilegio sale de `EfectivosAsync(cuenta, empresa)`, y el `EsAdmin` del nivel efectivo de esa membresía.
- Las **dos** rutas lo usan. La prueba de aislamiento de D6 cubre «un ADMIN de B no autoriza en A» en los dos caminos.

---

### SD0-07 · Media · La FK del catálogo de eventos puede revertir el cambio que registra

**Riesgo.** `BitacoraAcceso` escribe en la **misma transacción** que el cambio (BP3 6.4), y `FK_BitacoraSeguridad_Evento` rechaza todo evento que no esté en `CatalogoEventosSeguridad` (DAT-D0 4.1 y 7.2; R-1).

Basta un desfase entre la lista de C# y la tabla para que la operación entera se revierta. Ocurre, por ejemplo, si una rama agrega un evento y en modo Estricto no se corrió `GPOS.Migracion sistema`, o si un procedimiento o verbo de otra pieza escribe un nombre nuevo. Lo grave es dónde ocurre:
- en las rutas de **fallo** (`CUENTA_BLOQUEADA`, `ACCESO_EMPRESA_DENEGADO`, `VINCULO_NO_ENCONTRADO`), la reversión puede deshacer el aumento de `FallosVentana` (el bloqueo global) junto con la fila de la bitácora [I, según cómo se escriba D2];
- se pierde el registro;
- la respuesta pasa de 401 o 404 a 500, lo que además distingue los casos (un oráculo).

Un evento desconocido **no se pierde en silencio**, como pide la consigna, pero **sí bloquea la operación**, y en la ruta de bloqueo eso debilita un control.

**Evidencia.** DAT-D0 4.1, 5.2 («si falta un evento, la transacción falla de forma visible»), 7.2 (FK `WITH NOCHECK`) y 10 (R-1); BP3 6.4 y 4.9 (TRZ-01 a 03).

**Remediación en el diseño.**
1. **Comprobación al arrancar:** en Release, la API no arranca si algún evento de `GPOS.Contracts.EventosSeguridad` falta en la tabla (EventId propio, por ejemplo el 4733). `verificar` (V-7) ya lo compara, pero no protege el arranque.
2. **Las rutas de fallo y de bloqueo:** los contadores (`FallosVentana*`, `BloqueadoHasta`) se confirman en su propia sentencia. El evento se escribe después, en otra sentencia y con un respaldo: si el `INSERT` falla, va al registro de la aplicación con un EventId y la respuesta no cambia. La regla de «misma transacción» queda para los **cambios** de administración (altas, privilegios, estados), donde revertir es lo correcto.
3. Una prueba de D5: con un evento retirado de la tabla, el bloqueo se aplica igual y la respuesta es la misma.

La FK sigue siendo útil (ADR-37 pide un catálogo validado por el motor). No recomiendo quitarla.

---

### SD0-08 · Media · La API de reportes decide con los claims del token

**Riesgo.** Hoy la API de reportes:
- arma la identidad con los claims del token y usa `nivel` como tipo de rol;
- decide el factor exigido al SUPER por el claim `nivel`, y el cambio de contraseña pendiente por el claim `cambiar_clave`;
- calcula `EsAdmin` como el menor entre el claim y `rptsis.SesionUsuario.Nivel`.

Con DB-7 el claim `nivel` es solo informativo, y `DebeCambiarClave` puede cambiar sin un token nuevo (P-D0-04). Si D5 no cambia esos puntos, la API de reportes aceptaría a una persona con el cambio de contraseña pendiente, o decidiría el nivel con un dato que ya no autoriza. El sentido del error es incierto [I].

Por otro lado, la respuesta v2 (BP3 5.5) no trae la sucursal ni la restricción. E-SW-11 (BP3 14) dice que `GPOS.Reportes` las leerá de `rptsis.Membresia`, y eso contradice «`GPOS.Reportes.Api` no lee `UsuariosEmpresas` (DB7-04 (b))» de BP3 2.2.

**Evidencia.** `src/GPOS.Reportes.Api/Seguridad/AutenticacionIntrospeccion.cs:77`, `:105-107` y `:113-116`; `src/GPOS.Reportes/Contexto/ProveedorContexto.cs:73`; `ContextoReportes.cs:13` y `:43` [V]. BP3 2.2, 5.5 y 14 (E-SW-11).

**Remediación en el diseño.**
- La respuesta v2 suma `EsSuper`, `DebeCambiarClave`, `SucursalDefault` y `RestringirSucursal`, tomados de `EstadoAcceso`.
- La principal rechaza `cambio_clave` con el **estado**, no con el claim.
- La API de reportes arma su identidad sin los claims `nivel`, `cambiar_clave` ni `permiso` del token, y decide `EsAdmin`, `PuedeDisenar`, el factor y la restricción **solo** con la respuesta.
- `rptsis.Membresia` queda solo para las vistas de datos, si se necesita, y nunca para autorizar.
- Prueba: con la membresía restringida a S1, la API de reportes no devuelve filas de S2.

---

### SD0-09 · Media · La vía sin TPM no baja a requisitos las condiciones de C49-1 v2

**Riesgo.** BP3 8.2 dice «Sin TPM: el Software KSP, con las condiciones de C49-1 v2», y R-DB7-04 dice «`aprovisionar` informa qué proveedor quedó». Pero C49-1 v2 (ADR-53) exige, entre otras cosas:
- el riesgo aceptado por escrito por el propietario para ese equipo;
- BitLocker con contraseña de arranque;
- tokens de 8 h, y de 1 h para el SUPER;
- rotación de la llave de firma cada 30 días;
- el equipo marcado «sin TPM».

BP3 no traduce ninguna de esas condiciones a configuración, ni a comprobaciones de arranque o de `verificar`. Si `aprovisionar` cae solo al Software KSP, la llave de la central (con la que se firma también el SUPER con `amr = otp`) queda protegida por DPAPI de la máquina. Un administrador local podría extraerla [I, por el comportamiento conocido del KSP de software]. Además, la vigencia seguiría en 12 h.

**Evidencia.** BP3 8.2 y 13.1 (R-DB7-04); `docs/adr/ADR-053.md:54` (C49-1 v2); `docs/adr/ADR-041.md:27` y `:35`.

**Remediación en el diseño.**
- `aprovisionar --llave-firma` **no cae solo** al KSP de software. Exige `--sin-tpm --motivo <...>` y deja la marca `Jwt:Firma:SinTpm` con la fecha de la aceptación.
- En Release, con esa marca, la API:
  - limita `Jwt:HorasVigencia` a 8 h, y a 1 h para el SUPER;
  - avisa si la llave activa tiene más de 30 días;
  - registra un evento `SISTEMA` en cada arranque.
- `verificar` informa el proveedor y la antigüedad de la llave.
- BitLocker queda como condición del procedimiento de devops (no se puede verificar desde la API con privilegio mínimo [I]).
- Costo *inferido*: 0,1 sp en D2.

---

### SD0-10 · Media · `accesos --convertir` puede sellar como legítimo el sobreacceso de hoy

**Riesgo.** La conversión da, a toda cuenta sin restricción, una membresía en **todas** las empresas habilitadas, con su nivel actual. El ADMIN global pasa a ser ADMIN de cada empresa. Q23 garantiza que **no amplía** nada respecto de hoy, y eso lo confirmo (sección 5). Pero «hoy» es justamente el estado de H-01 y H-02, y la conversión lo deja **sellado** y con origen `CONVERSION`, indistinguible de un acceso concedido a propósito.

DB7-02 la limita al DEMO, pero el verbo no lo comprueba. Si se ejecuta en otra instalación anterior a DB-7, por ejemplo un piloto o una copia de un cliente, el aislamiento nace roto y con apariencia legítima. `--aceptar-exceso` tiene el mismo problema con el cupo.

**Evidencia.** DAT-D0 7.3 (pasos 3, 6 y 7); BP3 P-D0-07 y P-D0-D04; la decisión DB-7, DB7-02 («conversión del DEMO»).

**Remediación en el diseño.**
- El verbo exige la confirmación explícita `--instalacion-demo` y lo registra en `ACCESOS_CONVERTIDOS_INSTALACION`. Cuando exista la clasificación de empresas (Desarrollo, Beta, Producción, Demostración), solo corre si **todas** son Desarrollo o Demostración.
- En cualquier otro caso, crea membresías solo en `EmpresaDefault` (mínimo privilegio) y deja una lista para que el SUPER complete desde «Cuentas».
- `--aceptar-exceso` exige un motivo y queda en la misma fila.
- El paso 10 (escribir el archivo `padron` después del `COMMIT`) necesita su caso de fallo: si no se pudo escribir, el verbo termina con un código distinto de 0, y `verificar` y el arranque informan `PadronDiscoAusente` hasta que se repita.

**Atomicidad y reversión (consigna).**
- La transacción única `SERIALIZABLE` con `XACT_ABORT`, con Q23 antes de borrar y la API detenida, es correcta.
- El reverso por restauración del respaldo más la copia del `padron` (DAT-D0 7.4) también es correcto. Falta lo de SD0-18.

---

### SD0-11 · Baja · Cambios de privilegios que no suben `VersionPrivilegios`

**Riesgo.** La caché de permisos no tiene ventana mientras **todo** cambio suba la versión. Hay dos casos que no se nombran:
- **habilitar o inhabilitar un perfil** (`EmpresasPerfiles.Inhabilitado`, que Q1 filtra) y editar `EmpresasPerfilesPermisos`, salvo que Q6 los cubra de forma explícita;
- las **siembras o concesiones** de permisos que E-SW-7 traslada a `GPOS.Migracion sistema`.

Si no suben la versión, el mapa viejo dura hasta 5 minutos.

**Evidencia.** BP3 6.3 y 6.4 (Q6) y E-SW-7; DAT-D0 4.2 (Q1, conjunto 3, `p.Inhabilitado = 0`).

**Remediación.** Q6 abarca toda escritura en `EmpresasPerfiles*`. Todo paso de `sistema` que cambie permisos de perfiles sube la versión de los miembros afectados, o exige reiniciar la API. Una prueba de D1 cubre «inhabilitar un perfil revoca en la petición siguiente».

### SD0-12 · Baja · Token de dispositivo

**Riesgo.**
- La validez por petición solo mira el estado del dispositivo, con 15 s de caché.
- Ni ella ni la emisión del token comprueban que la **empresa** siga habilitada, y la emisión tampoco comprueba que el módulo siga activo. El módulo solo se exige en el alta y en la confirmación.
- Una empresa inhabilitada conserva sus pantallas de cocina y sus comanderas operativas sobre sus propios datos. No hay cruce entre empresas.
- Firmar con la misma llave del sitio (P-D0-02 (a)) es aceptable: la separación la imponen `typ` y `aud` en los dos esquemas.

**Evidencia.** `AutenticacionDispositivo.cs:86-102`; `ServicioDispositivos.cs:401-449` y `:151-155`; `Seguridad.cs:355-360` [V].

**Remediación.** En D2, al retirar `Jwt:Clave`: la emisión exige la empresa habilitada y el módulo activo, y `QuitarEmpresa` al inhabilitar una empresa también limpia la caché de sus dispositivos. El esquema de dispositivo usa el mismo `ProveedorLlavesFirma`, con ES256 y solo por `kid`.

### SD0-13 · Baja · La memoria criptográfica sobrevive a la revocación de una llave del anillo

**Riesgo.** La llave de la memoria es (huella del sello, versión del padrón). Revocar de urgencia una llave del anillo sin cambiar la versión del padrón deja aceptados durante 5 minutos los sellos protegidos con esa llave.

**Remediación.** Incluir en la llave de la memoria un contador de «época del anillo», que sube con toda revocación o reprotección (ADR-79). O vaciarla con un aviso desde esos verbos.

### SD0-14 · Baja · Columnas sin sello que se pueden cambiar por SQL

**Riesgo.** Quien tenga escritura en `GPOS_SYSDATA` puede cambiar sin rehacer un MAC:
- `DebeCambiarClave` (evita el cambio forzado);
- `SesionesRevocadas` de la cuenta y de la membresía (revive tokens robados que se habían revocado);
- `BloqueadoHasta` y `FallosVentana*` (ayudan a probar contraseñas);
- `AdministradaPorSuper`;
- los perfiles y las excepciones (SEG-L2-04, ya aceptado).

Nada de esto amplía el cupo, sube el nivel ni da una membresía. Los ocho casos de DAT-D0 3.5 están bien razonados, salvo el que agrega SD0-03.

**Remediación.** Agregar a DAT-D0 3.5 una tabla de «residual sin sello» con estas columnas, para que la firma las acepte de forma expresa. Opcional: `verificar` informa las revocaciones que bajaron (una `SesionesRevocadas` menor que la última registrada en la bitácora).

### SD0-15 · Baja · Detalles de ES256 y de las políticas

- Fijar `TryAllIssuerSigningKeys = false` y exigir `kid` (sin él, 401).
- Al arrancar, comprobar que el `kid` de la llave activa está en `Jwt:KidsValidos` y que la lista no está vacía.
- `HasClaim(Claims.Permiso, …)` en `ProveedorPoliticas` (`Seguridad.cs:240-246`) busca en **todas** las identidades del principal. Las políticas deben leer solo la identidad `gpos-permisos` (BP3 6.1, paso 5, «se ignoran»). Hoy el token está firmado, así que es defensa en profundidad.

### SD0-16 · Baja · Q1 puede esperar detrás de las transacciones de administración

**Riesgo.** Q1 corre en `READ COMMITTED` con un `CommandTimeout` de 2 s. Las transacciones de administración `SERIALIZABLE` toman `UPDLOCK` en `Usuarios` y escriben `UsuariosEmpresas` mientras rehacen sellos y un padrón de hasta 0,7 MB. Las peticiones de esas personas pueden esperar y recibir 503 [I]. Afecta la disponibilidad (R-DB7-02), no el aislamiento: falla cerrado.

**Remediación.** Medirlo en D1. Evaluar `READ_COMMITTED_SNAPSHOT` en `GPOS_SYSDATA`: no cambia la decisión, porque la fila confirmada anterior también tiene su sello. O calcular los `Protect` antes de tomar los bloqueos.

### SD0-17 · Baja · P-D0-04 tiene un efecto entre empresas

«Debe cambiar la clave» es de la cuenta: el ADMIN de A que asciende a una persona la obliga a cambiar su contraseña también en B. Es aceptable.

Una alternativa (c) más precisa y barata: guardar en la cuenta un bit `ClaveCumpleAdmin`, que se fija cada vez que se elige una contraseña (en ese momento se conoce su largo). Se fuerza el cambio solo si el bit es 0. Así se evitan cambios innecesarios, por ejemplo a quien ya tiene 12 o más caracteres. Costo *inferido*: 0,05 sp más.

### SD0-18 · Baja · Reversión y preautorización

- **Reversión a la versión anterior (HS256):** el procedimiento de devops debe generar una `Jwt:Clave` **nueva** y aleatoria, nunca reponer la anterior, que pudo haber quedado expuesta en la configuración.
- **Preautorización:** el registro de `jti` consumidos vive en memoria. Tras un reinicio, una preautorización robada vale hasta su vencimiento (5 min). El riesgo es bajo, porque se rechaza igual si cambia `SelloSeguridad`. Basta documentarlo, y fijar que la preautorización nunca se escriba en el registro.

---

## 5. Controles que están bien diseñados

- **Validación del acceso en cada petición sin caché del estado**, en un solo punto (`ValidacionAcceso`) que comparte la introspección, con 503 cerrado y nunca 401 ni una entrada vencida (BP3 6.1).
- **Las cachés no tienen ventana de privilegio tras revocar**, salvo SD0-11 y SD0-13:
  - permisos con llave (cuenta, empresa, versión): una versión nueva es otra llave;
  - `RevocacionSesiones` pasa a 0 s;
  - se quitan los 15 s de la introspección;
  - la memoria criptográfica no guarda nada que dependa de la fila (BP3 6.3).
- **Sello en dos niveles y padrón v2:**
  - el consumo se calcula **desde el padrón**, nunca con las filas;
  - hay entrada `a` para toda cuenta habilitada (P-D0-D01 (a), necesaria contra SH-5);
  - la cuenta queda como el elemento que habilita;
  - el subpropósito por (cuenta, empresa) impide copiar sellos;
  - el cupo se serializa con la fila del padrón, sin un segundo orden de bloqueos (DAT-D0 3.3 a 3.5).
- **ES256 en el TPM:**
  - solo `alg = ES256` y llave por `kid`;
  - se rechazan `jwk`, `jku`, `x5u` y `x5c`;
  - la API no arranca con una llave exportable ni con `Jwt:Clave` presente;
  - `iss` y `aud` son obligatorios.
- **Rutas anónimas mínimas:** 410 en `GET /empresas`, hash ficticio en todo fallo, 401 y 404 uniformes, 409 de sesión en uso después de la membresía, y el orden autorización → ámbito → cupo (QA-94).
- **El SUPER sale de Q1, nunca del token** (`ActorAcceso`), con motivo y factor obligatorios. `ACCION_SOBRE_SI_MISMO` y el último ADMIN quedan como reglas del servidor.
- **Integridad de las membresías en el motor:** versión monótona, sin borrado (disparador y `DENY`), y sin membresías del SUPER (51619 a 51625).
- **Conversión:** transacción única, equivalencia Q23 antes de borrar, idempotencia por marca, API detenida, y respaldo y copia del `padron`. La recomendación (a) de P-D0-07 es **más restrictiva** que hoy: lo confirmo con la corrección de DX-2.
- **Bitácora:** el ADMIN no ve la empresa que actúa (TRZ-06), la empresa de las denegaciones no se registra (TRZ-04), y los eventos de enumeración van a `CUENTA`, que solo ve el SUPER. **Confirmo DX-9.**

---

## 6. Preguntas P-D0-*: ¿la recomendación es segura?

| # | Recomendación | Dictamen de seguridad |
|---|---|---|
| P-D0-01 | (a) Llave CNG en el TPM, sin certificado | **De acuerdo.** El certificado no agrega valor sin una validación de cadena. Con las condiciones de SD0-09 para la vía sin TPM y de SD0-15 |
| P-D0-02 | (a) ES256 con la llave del sitio para los dispositivos | **De acuerdo.** `typ` y `aud` separan los dos tokens en la validación. Una segunda llave no reduce el riesgo, porque las dos tendrían la misma custodia. Agregar SD0-12 |
| P-D0-03 | Corregir R-12 en D1 | **De acuerdo, pero como requisito, no como opción** (SD0-02). La alternativa de aceptar el riesgo es incompatible con DB-7. Agregar la validación estricta de la imagen |
| P-D0-04 | (b) «Debe cambiar la clave» al otorgar el ADMIN | **De acuerdo**, con SD0-04 (sin él no basta). Considerar la (c) de SD0-17 |
| P-D0-05 | Pasar a la fase 2 IDN-05, TRZ-07, TRZ-10 y SES-13 (d) | **De acuerdo.** Ninguna cierra H-01, H-02 ni H-07. El residual: sin alertas al SUPER, los ataques sostenidos de contraseña solo se ven en la bitácora. Lo mitigan el bloqueo por (cuenta, IP) y el global |
| P-D0-06 | Sin validación local en la API de reportes | **De acuerdo.** Con la introspección obligatoria y sin caché, la validación local no agrega seguridad y duplica la rotación de llaves. Agregar SD0-08 |
| P-D0-07 | (a) Restricción solo en `EmpresaDefault` | **De acuerdo:** es la opción más restrictiva. Agregar la guarda de SD0-10 |
| P-D0-D01 | (a) Entrada `a` para toda cuenta habilitada | **De acuerdo, y necesaria.** La (b) reabre SH-5 (Alta) |
| P-D0-D02 | (a) El ADMIN ve `ACCESO` y `MEMBRESIA` | **De acuerdo.** Mantener el criterio de QA-28 (ningún texto que nombre otra empresa en `Detalle`, `ValorAnterior` ni `ValorNuevo`) |
| P-D0-D03 | (a) 5 años para `CUENTA` y `ACCESO` | **De acuerdo**, condicionado al dictamen legal pendiente (Ley 172-13). Se guardan códigos de usuario e IP: datos personales con una finalidad de seguridad declarada |
| P-D0-D04 | (a) Detenerse; convertir con `--aceptar-exceso` | **De acuerdo**, con motivo y con la guarda de SD0-10 |
| P-D0-D05 | (a) «Super Usuario» sin el código | **De acuerdo.** La trazabilidad completa queda en la vista del SUPER. Se pierde poder distinguir entre varios SUPER desde la vista del ADMIN, y eso es aceptable |

**Pregunta nueva que propongo:** **P-D0-08**, sobre los reportes por empresa (SD0-01): (a) `Reportes.EmpresaCodigo`, o (b) el diseñador solo para el SUPER en la v1.

---

## 7. Remediaciones priorizadas

**Antes de la firma** (cambios de texto en BP3 y DAT-D0; *inferido*, menos de medio día):
1. **SD0-01:** incluir los reportes por empresa en el alcance, con la DDL, las consultas y la tabla 1.2, o presentar P-D0-08.
2. **SD0-02:** P-D0-03 pasa a requisito de D1, con la validación estricta de la imagen y la prueba sobre todos los campos.
3. **SD0-03:** definir `Valido` de la membresía con `m(c,E)` presente, huella igual y `st = H`, y agregar el caso 9 a DAT-D0 3.5.
4. **SD0-04:** el nivel de la política de contraseñas sale de las membresías.
5. **SD0-05:** el principal de las reglas es el del autor, con su nivel efectivo y sus permisos, nunca un ADMIN fijo.
6. **SD0-06:** el evaluador propio del autorizante, en los dos caminos.

**En el diseño, recomendado antes de D1 y D2:** SD0-07 (comprobación del catálogo al arrancar y separación de las rutas de fallo), SD0-08 (introspección v2 sin claims para autorizar), SD0-09 (vía sin TPM explícita) y SD0-10 (guarda de la conversión).

**Durante la construcción (D1 a D6):** SD0-11 a SD0-18.

---

## 8. Recomendación

**Rechazado para pasar a la firma tal como está.** Hay dos hallazgos **Altos** (SD0-01 y SD0-02) que dejan abiertos caminos entre empresas que DB-7 promete cerrar. Los dos se corrigen **en el diseño**, sin cambiar la arquitectura ni el calendario (unas 0,4 a 0,6 sp más en total, *inferido*).

Con las seis correcciones de la sección 7 («Antes de la firma») aplicadas en BP3 y DAT-D0, mi recomendación pasa a **«Aprobado con observaciones»** para la firma del propietario. Las observaciones serían SD0-07 a SD0-18.

La decisión es del propietario. Esta es una recomendación técnica (C2).

---

## Supuestos

1. El código revisado es el de `a960cfac` (contiene `886dde70`). El árbol se movió durante la lectura (de `55365806` a `a960cfac`) por la actividad de otro agente; lo que cambió son pruebas y documentos.
2. Las afirmaciones sobre el comportamiento futuro son inferencias del diseño: no hay código de DB-7.
3. Sobre R-12: verifiqué el código leyéndolo. No probé ni construí una plantilla (C10).
4. El comportamiento de las llaves del KSP de software frente a un administrador local es *inferido* de su modelo de protección (DPAPI de la máquina).

## Entregas a otros agentes

- **arquitecto-software:** SD0-01 (alcance de los reportes y P-D0-08), SD0-02, SD0-05, SD0-06, SD0-08, SD0-09 y SD0-15, en BP3.
- **arquitecto-datos:** SD0-01 (`Reportes.EmpresaCodigo`, consultas y conversión), SD0-03 (caso 9 y definición de `Valido` en 3.5), SD0-07 (comprobación del catálogo), SD0-11 (Q6) y SD0-14 (residual), en DAT-D0.
- **arquitecto-maestro:** P-D0-08 en la hoja; P-D0-03 como requisito; las correcciones de la sección 7 como condición para presentar la hoja.
- **devops:** la vía sin TPM (SD0-09), la clave HS256 nueva al revertir (SD0-18) y el caso de fallo del archivo `padron` (SD0-10).
- **qa-automatizado:** las pruebas que piden SD0-01 a SD0-08 y SD0-11.

### Cierre
- Estado: Rechazado (para la firma tal como está; pasa a «Aprobado con observaciones» con las seis correcciones de la sección 7)
- Artefactos: `C:\Users\lfmen\source\repos\GPOS-NG-Equipos\traspasos\B\2026-10-18-db7-d0-revision-seguridad.md`
- Supuestos: los cuatro de la sección «Supuestos»
- Decisiones candidatas a ADR: los reportes por empresa con `EmpresaCodigo` y edición de los reportes del sistema solo por el SUPER (precisión de ADR-38 y ADR-40; alternativa descartada: el diseñador solo para el SUPER, por el costo de uso para el ADMIN); la vía sin TPM con marca explícita y las condiciones de C49-1 v2 aplicadas a la central (precisión de ADR-41)
- Entregas a otros agentes: las de la sección «Entregas a otros agentes»
- Próximo paso recomendado: el arquitecto de software y el de datos aplican las seis correcciones de la sección 7 en BP3 y DAT-D0, y el auditor las confirma antes de que el Maestro presente la hoja (objetivo: 10-29)

---

## Relectura (2026-10-18)

- **Qué releí:**
  - BP3, sección 15, y las secciones que cita: 4.3 (PRV-07), 4.4 (AIS-14), 5.1, 5.5, 6.1 (paso g), 6.2, 6.3, 6.4, 8.1, 8.2, 10.1, 10.3 (RQ-R12), 12.2 (P-D0-04 y P-D0-08), 12.4 y 13.1 (R-DB7-09 y R-DB7-11 a R-DB7-15);
  - DAT-D0: la sección «Respuesta a la revisión de seguridad» y lo que cita: 2.6, 3.5 (el caso 9 y el residual), 3.6 (`Valido`), 5.6, 7.3 (la precondición 9 y los pasos 3 b, 8 h, 10 y 11) y 7.5.
- **Código:** `GPOS-B-integracion` en `a960cfac`, sin cambios respecto de la revisión. Las líneas citadas en los dos documentos coinciden con las que verifiqué.
- No edité los documentos revisados.

### Estado de cada hallazgo

| ID | Sev. | Estado | Comprobación |
|---|---|---|---|
| SD0-01 | Alta | **Cerrado (con P-D0-08 (a))** | BP3 P-D0-08 y DAT-D0 2.6 coinciden: `Reportes.EmpresaCodigo` (NULL = del sistema), `CK_Reportes_Ambito`, lectura y escritura con la empresa del token y 404 sin distinguir, el sistema solo para la semilla o el SUPER (el ADMIN duplica), `rpt:{id}` por empresa, `rptsis.Reporte` v2 y la conversión (paso 3 b). Si el propietario elige (b), también queda cerrado (`RequiereSuper`). **Condición:** la v1 se publica con D5 unido; entre D1 y D5 la definición sigue siendo global |
| SD0-02 | Alta | **Cerrado** | RQ-R12 es requisito de D1 (BP3 10.3) y condición de publicación (AIS-14). Incluye la lista blanca de la imagen, el rechazo de `svg+xml`, el escape de la arroba y la prueba por reflexión sobre todos los campos. Sale de las preguntas (12.4) |
| SD0-03 | Media | **Cerrado** | BP3 6.1 (paso g) y DAT-D0 3.6 dan la misma definición: `m(c,E)` obligatoria, con la misma huella, el mismo nivel y `st = H`, más `a(c)`. Se aplica en Q1, Q2, el autorizante, Q9 y Q10. El caso 9 está en 3.5, con su prueba en D3 |
| SD0-04 | Media | **Cerrado** | El nivel de la política es SUPER, o ADMIN si hay alguna membresía no dada de baja con nivel ADMIN, leído del padrón (BP3 8.1; DAT-D0, `m.n = A` con `st` H o S). Sustituye `UsuariosService.cs:483` y `:773` y tiene su prueba |
| SD0-05 | Media | **Cerrado** | Se retira el principal sintético (`TrabajoNotificaciones.cs:180-189`). Cada regla se ejecuta con `gpos-permisos`, el nivel efectivo y `CachePermisos` del autor. La cola va con `SISTEMA`, sin acceso a reportes. Prueba de los costos (BP3 6.2) |
| SD0-06 | Media | **Cerrado** | `EvaluarAutorizante(cuenta, empresaSesion)` se usa en los dos caminos (`PosEndpoints.cs:64` y `:76`; `AutorizadorSupervisor.cs:35-40`), sin los pasos de sesión. Usa `EfectivosAsync(cuenta, empresa)` y el sello `Valido`. La prueba de D6 cubre los dos caminos |
| SD0-07 | Media | **Bien resuelto** | Comprobación al arrancar en Release (EventId 4733) y contadores en su propia sentencia, con el evento después y un respaldo en el EventId 4734 (BP3 6.4; DAT-D0 5.6). La FK se mantiene. Ver N-3 |
| SD0-08 | Media | **Bien resuelto** | La respuesta v2 suma `EsSuper`, `DebeCambiarClave`, `SucursalDefault` y `RestringirSucursal`. La API de reportes deja de decidir con los claims del token, y `rptsis.*` nunca autoriza. Se corrigió la contradicción de E-SW-11 (BP3 5.5 y 14) |
| SD0-09 | Media | **Bien resuelto** | `--sin-tpm --motivo`, sin caída automática. Con la marca: 8 h, 1 h para el SUPER y aviso a los 30 días, con el EventId 4735; `verificar` informa el proveedor; BitLocker y la aceptación escrita quedan en el procedimiento de devops (BP3 8.2) |
| SD0-10 | Media | **Bien resuelto** | Precondición 9: `--instalacion-demo`, o modo mínimo (solo `EmpresaDefault`, como USER, sin ADMIN y con la lista de pendientes para el SUPER); el motivo del exceso; el fallo del archivo `padron` en el paso 10 (R-DB7-15). Ver N-4 |
| SD0-11 a SD0-18 | Baja | Atendidos | BP3 15 y DAT-D0 los reflejan (R-DB7-11 a R-DB7-15, P-D0-04 (c) y 3.7). SD0-13 queda con una contradicción de texto (N-2) |

### Hallazgos nuevos de la relectura (todos Baja: contradicciones de texto entre los dos documentos)

| ID | Sev. | Contradicción | Corrección |
|---|---|---|---|
| N-1 | Baja | BP3 5.1 sigue listando solo los EventId 4724 a 4729 y dice «si hacen falta más, se usan los 4733 a 4739». La sección 15 ya usa 4733 a 4735, con el siguiente libre en el 4736 | Agregar a la tabla de 5.1 el 4733 `CatalogoEventosIncompleto`, el 4734 `EventoSeguridadNoRegistrado` y el 4735 `FirmaSinTpm`, con el siguiente libre en el 4736 |
| N-2 | Baja | DAT-D0 3.6 conserva la llave de la memoria criptográfica `(huella, versión del padrón)`. BP3 6.3 le agrega la época del anillo (SD0-13) | Alinear DAT-D0 3.6 con BP3 6.3 |
| N-3 | Baja | Las listas de eventos de las rutas de fallo no coinciden. BP3 6.4 suma «los fallidos de `identificar`»; DAT-D0 5.6 suma `USUARIO_SIN_SELLO` y `MEMBRESIA_SIN_SELLO` | Usar la unión de las dos listas en ambos documentos |
| N-4 | Baja | BP3 15 (SD0-10) dice «solo en `EmpresaDefault`», sin «como USER», y «`--aceptar-exceso` exige motivo». DAT-D0 7.3 dice «como USER» y nombra la opción `--motivo-exceso`. Además, el «Uso» de 7.3 no muestra `--instalacion-demo` ni `--motivo-exceso` | Llevar a BP3 la regla de DAT-D0 («como USER», que es más restrictiva) y el nombre de la opción, y completar la línea «Uso» |
| N-5 | Baja | DAT-D0 4.1 se titula «franja reservada por BP3: 51619 a 51638» y dice «libres 51626 a 51638». BP3 5.1 dice que la reserva se redujo a 51619 a 51625 (DX-10). Los números de error en uso (51619 a 51625) coinciden en los dos | Corregir el título y la nota de DAT-D0 4.1: el siguiente libre es el 51626, sin reserva hasta el 51638 |
| N-6 | Baja | DAT-D0 2.6 y el paso 11: si el paso 11 no termina y la API arranca, Q7 suspende las reglas que apuntan al `Id` original (`Activa = 0`, falla cerrado). Reasignarlas después no las reactiva | El paso 11 (o `--solo-reglas`) reactiva las reglas que suspendió Q7 por esta causa, o la API no ejecuta Q7 sobre los `ReporteId` que siguen en `ConversionReportes` sin `ReglasActualizadasUtc` |
| N-7 | Baja | DAT-D0 3.5: hay una línea en blanco antes de la fila del caso 9, que se muestra fuera de la tabla | Quitar la línea en blanco (es de forma) |

No encontré contradicciones en los nombres de columnas ni en las reglas de fondo:
- `EmpresaCodigo`, `SelloMembresia`, `VersionPrivilegios`, `AdministradaPorSuper`, `ClaveCumpleAdmin`, `FallosVentana*` y `BloqueadoHasta` se llaman igual en los dos documentos;
- `Valido`, el nivel de la política, el autorizante y el catálogo se definen igual en los dos;
- los errores 51619 a 51625 tienen el mismo uso en BP3 5.1 y en DAT-D0 4.1 y 7.2.

### Dictamen final para pasar a la firma

**Aprobado con observaciones.**
- SD0-01 a SD0-06 quedan cerrados en el diseño. El cierre de SD0-01 depende de la respuesta a P-D0-08, y las dos opciones lo cierran.
- SD0-07 a SD0-10 están bien resueltos.
- Las observaciones son N-1 a N-7, todas Bajas y de texto, y no impiden presentar la hoja. Conviene corregir N-1, N-3 y N-4 antes de imprimirla, porque son contratos (EventId, eventos de las rutas de fallo y opciones del verbo).
- Condiciones que se mantienen: RQ-R12 y SD0-01 se verifican en la auditoría del código de D6, y la v1 se publica solo con D1 a D5 unidos.
- La decisión es del propietario (C2).

### Cierre de la relectura
- Estado: Aprobado con observaciones
- Artefactos: este informe, con la sección «Relectura (2026-10-18)» agregada
- Supuestos: los cuatro del informe; el árbol sigue en `a960cfac`
- Decisiones candidatas a ADR: sin cambios
- Entregas a otros agentes:
  - arquitecto-software → N-1 y N-4 en BP3;
  - arquitecto-datos → N-2, N-5, N-6 y N-7 en DAT-D0;
  - los dos → N-3;
  - arquitecto-maestro → presentar la hoja con P-D0-08.
- Próximo paso recomendado: aplicar N-1, N-3 y N-4 y llevar la hoja del diseño a la firma del propietario.
